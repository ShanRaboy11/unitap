'use strict';

const connectToFabric = require('./connect.js');
const crypto = require('crypto');

async function main() {
  try {
    const { gateway, contract } = await connectToFabric();
    console.log('Connected to Fabric contract (gateway active)');

    const tokenSignature = 'test-' + (crypto.randomUUID ? crypto.randomUUID() : `${Date.now()}-${Math.floor(Math.random()*1000)}`);
    const userId = process.env.TEST_USER_ID || '00000000-0000-0000-0000-000000000000';
    const amount = '1500.00';
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000).toISOString(); // 5 minutes from now

    console.log('\n-- Creating QR Token --');
    const createQrRes = await contract.submitTransaction('createQrToken', tokenSignature, userId, 'withdraw', amount, expiresAt);
    console.log('createQrToken response:', createQrRes.toString());

    console.log('\n-- Reading QR Token (read-only) --');
    const getQrRes = await contract.evaluateTransaction('getQrToken', tokenSignature);
    console.log('getQrToken:', getQrRes.toString());

    console.log('\n-- Verifying (consuming) QR Token --');
    const scannerId = 'atm-scanner-1';
    const verifyRes = await contract.submitTransaction('verifyQrToken', tokenSignature, scannerId);
    console.log('verifyQrToken:', verifyRes.toString());

    console.log('\n-- Creating Transaction --');
    const txId = 'tx-' + (crypto.randomUUID ? crypto.randomUUID() : `${Date.now()}-${Math.floor(Math.random()*1000)}`);
    const recipientId = '';
    const currencyCode = 'PHP';
    const feeAmount = '0.00';
    const type = 'withdraw';
    const description = 'ATM cashout test';
    const ecoPoints = '0';

    const createTxRes = await contract.submitTransaction(
      'createTransaction',
      txId,
      userId,
      recipientId,
      amount,
      currencyCode,
      feeAmount,
      type,
      description,
      ecoPoints
    );
    console.log('createTransaction:', createTxRes.toString());

    console.log('\n-- Querying Created Transaction --');
    const queryTx = await contract.evaluateTransaction('queryTransaction', txId);
    console.log('queryTransaction:', queryTx.toString());

    console.log('\n-- Querying Transactions By User --');
    const userTxs = await contract.evaluateTransaction('getTransactionsByUser', userId);
    console.log('getTransactionsByUser:', userTxs.toString());

    console.log('\nTest script completed successfully.');
    try {
      await gateway.disconnect();
    } catch (e) {
      console.warn('Failed to disconnect gateway cleanly', e);
    }
    process.exit(0);
  } catch (err) {
    console.error('Error running test script:', err);
    // Attempt to disconnect if possible
    try { if (err && err.gateway) await err.gateway.disconnect(); } catch(e){}
    process.exit(1);
  }
}

main();
