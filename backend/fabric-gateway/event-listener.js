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

async function persistEventToDb(eventName, payload, txId) {
  try {
    await pool.query('INSERT INTO events(event_name, payload, tx_id) VALUES($1, $2, $3)', [eventName, payload, txId]);
  } catch (e) {
    console.error('Failed to write event to DB', e);
    useDb = false;
    await persistEventToFile(eventName, payload, txId);
  }
}

function persistEventToFile(eventName, payload, txId) {
  return new Promise((resolve, reject) => {
    const row = { event_name: eventName, payload: payload, tx_id: txId, created_at: new Date().toISOString() };
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
      console.log('Contract event', event.eventName, payload);
      if (useDb) {
        await persistEventToDb(event.eventName, payload, event.transactionId);
      } else {
        await persistEventToFile(event.eventName, payload, event.transactionId);
      }
    } catch (e) {
      console.error('Error handling event', e);
    }
  });

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
