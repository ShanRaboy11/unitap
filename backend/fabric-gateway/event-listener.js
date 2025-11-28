const connectToFabric = require('./connect');
const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const DATABASE_URL = process.env.DATABASE_URL || '';
const pool = DATABASE_URL ? new Pool({ connectionString: DATABASE_URL }) : new Pool();
const fallbackFile = path.join(__dirname, 'events.jsonl');
let useDb = true;

async function checkDb() {
  if (!DATABASE_URL || DATABASE_URL.startsWith('http')) {
    useDb = false;
    console.warn('DATABASE_URL looks invalid or missing; using file fallback:', fallbackFile);
    return;
  }
  try {
    const client = await pool.connect();
    client.release();
    useDb = true;
    console.log('DB connection ok');
  } catch (e) {
    useDb = false;
    console.warn('DB connection failed; falling back to file:', e.message);
  }
}

async function persistEventToDb(eventName, payload, txId, blockNumber, blockHash, createdAt) {
  try {
    const sql = `INSERT INTO events(event_name, payload, tx_id, block_number, block_hash, created_at)
                 VALUES($1, $2, $3, $4, $5, $6)
                 ON CONFLICT (tx_id) DO NOTHING`;
    await pool.query(sql, [eventName, payload, txId, blockNumber, blockHash, createdAt]);
  } catch (e) {
    console.error('Failed to write event to DB', e);
    useDb = false;
    await persistEventToFile(eventName, payload, txId, blockNumber, blockHash, createdAt);
  }
}

function persistEventToFile(eventName, payload, txId, blockNumber, blockHash, createdAt) {
  return new Promise((resolve, reject) => {
    const row = {
      event_name: eventName,
      payload: payload,
      tx_id: txId,
      block_number: blockNumber || null,
      block_hash: blockHash || null,
      created_at: createdAt || new Date().toISOString()
    };
    fs.appendFile(fallbackFile, JSON.stringify(row) + '\n', (err) => {
      if (err) {
        console.error('Failed to write event to file fallback', err);
        return reject(err);
      }
      return resolve();
    });
  });
}

async function main() {
  const { gateway, contract } = await connectToFabric();

  console.log('Event listener: connected to contract');

  await checkDb();

  contract.addContractListener(async (event) => {
    try {
      const payload = event.payload && event.payload.length ? JSON.parse(event.payload.toString()) : null;
      console.log('Contract event', event.eventName, payload, 'txId', event.transactionId);

      // Attempt to fetch the block containing this transaction to capture block info
      let blockNumber = null;
      let blockHash = null;
      // Derive a Fabric tx id if available from the event API, otherwise fall back to payload id
      const fabricTxId = (typeof event.getTransactionId === 'function') ? event.getTransactionId() : (event.transactionId || (payload && payload.id));
      try {
        const networkObj = (gateway && typeof gateway.getNetwork === 'function') ? gateway.getNetwork(process.env.CHANNEL || 'mychannel') : null;
        if (networkObj && typeof networkObj.getChannel === 'function' && fabricTxId) {
          const channel = networkObj.getChannel();
          const block = await channel.queryBlockByTxID(fabricTxId);
          if (block && block.header) {
            // header.number may be a Long
            blockNumber = (block.header.number && typeof block.header.number === 'object' && typeof block.header.number.toNumber === 'function')
              ? block.header.number.toNumber()
              : block.header.number;
            // data_hash is a Buffer
            if (block.header.data_hash) {
              blockHash = Buffer.isBuffer(block.header.data_hash) ? block.header.data_hash.toString('hex') : block.header.data_hash.toString();
            }
          }
        } else {
          console.warn('Channel query not available on gateway or no tx id available; skipping block lookup for tx', fabricTxId);
        }
      } catch (err) {
        console.warn('Could not fetch block for tx', fabricTxId, err.message || err);
      }

      function manilaTimestampIso() {
        // produce an ISO-like timestamp with +08:00 offset acceptable to Postgres
        const s = new Date().toLocaleString('sv', { timeZone: 'Asia/Manila' }); // YYYY-MM-DD HH:MM:SS
        return s.replace(' ', 'T') + '+08:00';
      }
      const createdAt = manilaTimestampIso();
      const txToStore = fabricTxId || (payload && payload.id) || null;
      if (useDb) {
        await persistEventToDb(event.eventName, JSON.stringify(payload), txToStore, blockNumber, blockHash, createdAt);
      } else {
        await persistEventToFile(event.eventName, payload, txToStore, blockNumber, blockHash, createdAt);
      }
    } catch (e) {
      console.error('Error handling event', e);
    }
  });

  // Add a block listener to log every committed block and update events with block info
  try {
    const network = gateway.getNetwork(process.env.CHANNEL || 'mychannel');
    if (network && typeof network.addBlockListener === 'function') {
      network.addBlockListener(async (blockEvent) => {
        try {
          // blockEvent may contain the raw block object depending on SDK version
          const header = blockEvent.header || (blockEvent.block && blockEvent.block.header) || (blockEvent && blockEvent.block && blockEvent.block.header);
          const dataHashBuf = header && header.data_hash ? header.data_hash : (header && header.data_hash ? header.data_hash : null);
          const blockNumberObj = header && header.number ? header.number : (blockEvent && blockEvent.block && blockEvent.block.header && blockEvent.block.header.number);
          const blockNumber = (blockNumberObj && typeof blockNumberObj === 'object' && typeof blockNumberObj.toNumber === 'function') ? blockNumberObj.toNumber() : blockNumberObj;
          const blockHash = dataHashBuf ? (Buffer.isBuffer(dataHashBuf) ? dataHashBuf.toString('hex') : dataHashBuf.toString()) : null;

          console.log('Block committed:', { blockNumber, blockHash });

          // Try to extract transaction IDs from the block and update DB rows
          const blockObj = blockEvent.block || blockEvent;
          const txEnvelopes = (blockObj && blockObj.data && blockObj.data.data) ? blockObj.data.data : [];
          for (const env of txEnvelopes) {
            try {
              // channel_header is typically at payload.header.channel_header
              const header = env && env.payload && env.payload.header && env.payload.header.channel_header;
              const txId = header && header.tx_id ? header.tx_id : null;
              if (txId) {
                const res = await pool.query('UPDATE events SET block_number=$1, block_hash=$2 WHERE tx_id=$3 RETURNING tx_id', [blockNumber, blockHash, txId]);
                if (res && res.rowCount) {
                  console.log('Updated event with block info for tx', txId, 'block', blockNumber);
                }
              }
            } catch (e) {
              console.warn('Failed to update DB for envelope', e.message || e);
            }
          }
        } catch (e) {
          console.warn('Block listener error', e.message || e);
        }
      });
      console.log('Block listener registered');
    } else {
      console.warn('Network.addBlockListener not available; block listener not registered');
    }
  } catch (e) {
    console.warn('Failed to register block listener', e.message || e);
  }

  process.on('SIGINT', async () => {
    console.log('Shutting down listener...');
    await gateway.disconnect();
    try { await pool.end(); } catch (e) {}
    process.exit(0);
  });
}

main().catch(e => {
  console.error('Event listener failed', e);
  process.exit(1);
});
