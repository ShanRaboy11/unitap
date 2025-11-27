const express = require('express');
const bodyParser = require('body-parser');
const connectToFabric = require('./connect');
require('dotenv').config();
const cors = require('cors');

const app = express();
app.use(cors());
app.use(bodyParser.json());

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
    const { txId, userId, recipientId, amount, currencyCode, feeAmount, type, description, ecoPoints } = req.body;
    const { contract } = await ensureConnected();
    const args = [txId || '', userId, recipientId || '', String(amount || 0), currencyCode || 'PHP', String(feeAmount || 0), type || 'transfer', description || '', String(ecoPoints || 0)];
    const response = await contract.submitTransaction('createTransaction', ...args);
    return res.json(JSON.parse(response.toString()));
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
