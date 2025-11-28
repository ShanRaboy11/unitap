const express = require('express');
const bodyParser = require('body-parser');
const connectToFabric = require('./connect');
require('dotenv').config();
const cors = require('cors');

const app = express();
app.use(cors());
app.use(bodyParser.json());

// DB pool for storing auxiliary metadata (e.g., location)
const { Pool } = require('pg');
const pool = process.env.DATABASE_URL ? new Pool({ connectionString: process.env.DATABASE_URL }) : new Pool();

function manilaTimestampIso() {
  const s = new Date().toLocaleString('sv', { timeZone: 'Asia/Manila' });
  return s.replace(' ', 'T') + '+08:00';
}

// Optional simple API key protection: set API_KEY in .env to enable
const API_KEY = process.env.API_KEY || '';
function requireApiKey(req, res, next) {
  if (!API_KEY) return next();
  const key = req.header('x-api-key') || req.query.api_key;
  if (key === API_KEY) return next();
  return res.status(401).json({ error: 'Unauthorized' });
}

let gateway = null;
let contract = null;

async function ensureConnected() {
  if (gateway && contract) return { gateway, contract };
  const res = await connectToFabric();
  gateway = res.gateway;
  contract = res.contract;
  return { gateway, contract };
}

// Helper to normalize incoming request fields (accept PascalCase, snake_case, etc.)
function pickField(body, ...candidates) {
  if (!body || typeof body !== 'object') return undefined;
  for (const name of candidates) {
    if (Object.prototype.hasOwnProperty.call(body, name) && body[name] !== undefined) return body[name];
    const lower = name.toLowerCase();
    // check common variants
    if (Object.prototype.hasOwnProperty.call(body, lower) && body[lower] !== undefined) return body[lower];
    const pascal = name.charAt(0).toUpperCase() + name.slice(1);
    if (Object.prototype.hasOwnProperty.call(body, pascal) && body[pascal] !== undefined) return body[pascal];
    const snake = name.replace(/[A-Z]/g, m => '_' + m.toLowerCase());
    if (Object.prototype.hasOwnProperty.call(body, snake) && body[snake] !== undefined) return body[snake];
  }
  return undefined;
}

app.get('/health', requireApiKey, async (req, res) => {
  try {
    // try to ensure connection
    await ensureConnected();
    return res.json({ ok: true, fabricConnected: true });
  } catch (e) {
    return res.status(503).json({ ok: false, fabricConnected: false, error: e.message });
  }
});

app.get('/metadata', requireApiKey, (req, res) => {
  return res.json({ channel: process.env.CHANNEL || 'mychannel', chaincode: process.env.CHAINCODE_NAME || 'unitapcc' });
});

// Friendly root route so visiting the public URL shows useful info
app.get('/', (req, res) => {
  return res.send('Unitap Fabric Gateway — use /health or API endpoints (see README)');
});

// Support POST to root for clients that mistakenly POST to the base URL (ngrok root)
// If the payload looks like a transaction, forward to createTransaction; otherwise return guidance.
app.post('/', requireApiKey, async (req, res) => {
  try {
    const body = req.body || {};
    const txId = pickField(body, 'txId', 'tx_id', 'id');
    const userId = pickField(body, 'userId', 'UserId', 'user_id', 'userid');
    const recipientId = pickField(body, 'recipientId', 'recipient_id', 'toAccount', 'ToAccount');
    const amount = pickField(body, 'amount', 'Amount');
    const currencyCode = pickField(body, 'currencyCode', 'currency_code', 'CurrencyCode');
    const feeAmount = pickField(body, 'feeAmount', 'fee_amount', 'FeeAmount');
    const type = pickField(body, 'type', 'transactionType', 'TransactionType');
    const description = pickField(body, 'description', 'details', 'Details');
    const ecoPoints = pickField(body, 'ecoPoints', 'eco_points');
    const location = pickField(body, 'location', 'Location');
    // If the payload contains transaction-like fields, attempt to create a transaction
    if (txId || userId || amount) {
      if (!userId) return res.status(400).json({ error: 'userId is required' });
      const { contract } = await ensureConnected();
      let args = [txId || '', userId, recipientId || '', amount === undefined || amount === null ? '0' : amount, currencyCode || 'PHP', feeAmount === undefined || feeAmount === null ? '0' : feeAmount, type || 'transfer', description || '', ecoPoints === undefined || ecoPoints === null ? '0' : ecoPoints];
      args = args.map(a => (a === undefined || a === null) ? '' : String(a));
      try {
        const response = await contract.submitTransaction('createTransaction', ...args);
        const respObj = JSON.parse(response.toString());
        // Persist optional location metadata to tx_meta table as in /tx/create
        try {
          const txToStore = respObj && respObj.id ? respObj.id : (txId || '');
          if (txToStore && location) {
            const createdAt = manilaTimestampIso();
            await pool.query(
              'INSERT INTO tx_meta(tx_id, location, created_at) VALUES($1, $2, $3) ON CONFLICT (tx_id) DO UPDATE SET location = EXCLUDED.location, created_at = EXCLUDED.created_at',
              [txToStore, JSON.stringify(location), createdAt]
            );
          }
        } catch (e) {
          console.warn('Failed to persist tx_meta', e.message || e);
        }
        return res.json(respObj);
      } catch (err) {
        console.error('root createTransaction error', err, { args });
        return res.status(500).json({ error: 'createTransaction failed', detail: err.message });
      }
    }

    return res.status(400).json({
      error: 'No actionable payload at root. Use POST /tx/create for transactions or POST /qr/create for QR tokens.',
      availableEndpoints: ['/tx/create', '/qr/create', '/qr/:signature/verify']
    });
  } catch (err) {
    console.error('root POST error', err);
    return res.status(500).json({ error: err.message });
  }
});

app.post('/qr/create', requireApiKey, async (req, res) => {
  try {
    const { tokenSignature, userId, transactionType, amountLocked, expiresAtIso } = req.body;
    const { contract } = await ensureConnected();
    const response = await contract.submitTransaction('createQrToken', tokenSignature, userId, transactionType || 'withdraw', String(amountLocked || 0), expiresAtIso || '');
    return res.json(JSON.parse(response.toString()));
  } catch (err) {
    console.error('createQrToken error', err);
    return res.status(500).json({ error: err.message });
  }
});

app.get('/qr/:signature', requireApiKey, async (req, res) => {
  try {
    const { signature } = req.params;
    const { contract } = await ensureConnected();
    const response = await contract.evaluateTransaction('getQrToken', signature);
    return res.json(JSON.parse(response.toString()));
  } catch (err) {
    console.error('getQrToken error', err);
    return res.status(500).json({ error: err.message });
  }
});

app.post('/qr/:signature/verify', requireApiKey, async (req, res) => {
  try {
    const { signature } = req.params;
    const { scannerId } = req.body;
    const { contract } = await ensureConnected();
    const response = await contract.submitTransaction('verifyQrToken', signature, scannerId || '');
    return res.json(JSON.parse(response.toString()));
  } catch (err) {
    console.error('verifyQrToken error', err);
    return res.status(500).json({ error: err.message });
  }
});

app.post('/tx/create', requireApiKey, async (req, res) => {
  try {
    const body = req.body || {};
    const txId = pickField(body, 'txId', 'tx_id', 'id');
    const userId = pickField(body, 'userId', 'UserId', 'user_id', 'userid');
    const recipientId = pickField(body, 'recipientId', 'recipient_id', 'toAccount', 'ToAccount');
    const amount = pickField(body, 'amount', 'Amount');
    const currencyCode = pickField(body, 'currencyCode', 'currency_code', 'CurrencyCode');
    const feeAmount = pickField(body, 'feeAmount', 'fee_amount', 'FeeAmount');
    const type = pickField(body, 'type', 'transactionType', 'TransactionType');
    const description = pickField(body, 'description', 'details', 'Details');
    const ecoPoints = pickField(body, 'ecoPoints', 'eco_points');
    const location = pickField(body, 'location', 'Location');
    const { contract } = await ensureConnected();
    // Defensive: coerce all args to strings and replace undefined/null with empty string
    let args = [txId || '', userId, recipientId || '', amount === undefined || amount === null ? '0' : amount, currencyCode || 'PHP', feeAmount === undefined || feeAmount === null ? '0' : feeAmount, type || 'transfer', description || '', ecoPoints === undefined || ecoPoints === null ? '0' : ecoPoints];
    args = args.map(a => (a === undefined || a === null) ? '' : String(a));
    try {
      const response = await contract.submitTransaction('createTransaction', ...args);
      const respObj = JSON.parse(response.toString());

      // Persist optional location metadata to tx_meta table (local or remote DB)
      try {
        const txToStore = respObj && respObj.id ? respObj.id : (txId || '');
        if (txToStore && location) {
          const createdAt = manilaTimestampIso();
          await pool.query(
            'INSERT INTO tx_meta(tx_id, location, created_at) VALUES($1, $2, $3) ON CONFLICT (tx_id) DO UPDATE SET location = EXCLUDED.location, created_at = EXCLUDED.created_at',
            [txToStore, JSON.stringify(location), createdAt]
          );
        }
      } catch (e) {
        console.warn('Failed to persist tx_meta', e.message || e);
      }

      return res.json(respObj);
    } catch (err) {
      console.error('createTransaction error', err, { args });
      return res.status(500).json({ error: 'createTransaction failed', detail: err.message });
    }
  } catch (err) {
    console.error('createTransaction error', err);
    return res.status(500).json({ error: err.message });
  }
});

app.get('/tx/:id', requireApiKey, async (req, res) => {
  try {
    const { id } = req.params;
    const { contract } = await ensureConnected();
    const response = await contract.evaluateTransaction('queryTransaction', id);
    return res.json(JSON.parse(response.toString()));
  } catch (err) {
    console.error('queryTransaction error', err);
    return res.status(500).json({ error: err.message });
  }
});

app.get('/txs/user/:userId', requireApiKey, async (req, res) => {
  try {
    const { userId } = req.params;
    const { contract } = await ensureConnected();
    const response = await contract.evaluateTransaction('getTransactionsByUser', userId);
    return res.json(JSON.parse(response.toString()));
  } catch (err) {
    console.error('getTransactionsByUser error', err);
    return res.status(500).json({ error: err.message });
  }
});

const port = process.env.PORT || 3000;
const server = app.listen(port, () => {
  console.log(`REST API listening on port ${port}`);
});

process.on('SIGINT', async () => {
  console.log('Shutting down...');
  server.close();
  if (gateway) await gateway.disconnect();
  process.exit(0);
});
