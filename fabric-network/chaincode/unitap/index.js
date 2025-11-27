'use strict';

const { Contract } = require('fabric-contract-api');

class UniTapContract extends Contract {

  async initLedger(ctx) {
    console.info('UniTapContract: Ledger initialized');
  }

  async logTransaction(ctx, txId, userId, amount, action) {

    const entry = {
      txId,
      userId,
      amount: parseFloat(amount),
      action,
      timestamp: this._getTxTimestampISO(ctx)
    };

    await ctx.stub.putState(txId, Buffer.from(JSON.stringify(entry)));

    return entry;
  }

  // ----------------------------
  // Helpers & Validation
  // ----------------------------
  async _exists(ctx, key) {
    const data = await ctx.stub.getState(key);
    return data && data.length > 0;
  }

  _safeFloat(v) {
    if (v === undefined || v === null || v === '') return 0.0;
    const n = parseFloat(v);
    if (Number.isNaN(n)) return 0.0;
    return n;
  }

  _getTxTimestampDate(ctx) {
    const ts = ctx.stub.getTxTimestamp();
    if (!ts) return new Date();
    let seconds = ts.seconds;
    const nanos = ts.nanos || 0;
    if (typeof seconds === 'object' && seconds !== null) {
      // protobuf Long (low/high) representation
      if (seconds.low !== undefined) {
        seconds = seconds.low;
      } else if (seconds.toNumber) {
        seconds = seconds.toNumber();
      }
    }
    const ms = (Number(seconds) * 1000) + Math.floor(nanos / 1e6);
    return new Date(ms);
  }

  _getTxTimestampISO(ctx) {
    return this._getTxTimestampDate(ctx).toISOString();
  }

  _ensureArg(name, val) {
    if (val === undefined || val === null || String(val).trim() === '') {
      throw new Error(`Missing or empty argument: ${name}`);
    }
  }

  // Create a canonical transaction record on the ledger
  async createTransaction(ctx, txId, userId, recipientId, amount, currencyCode, feeAmount, type, description, ecoPoints) {
    // Basic validation
    this._ensureArg('userId', userId);
    this._ensureArg('amount', amount);
    this._ensureArg('type', type);

    // Use chaincode-generated tx id if none provided
    const finalTxId = txId && String(txId).trim() !== '' ? txId : ctx.stub.getTxID();
    const txKey = `tx-${finalTxId}`;

    if (await this._exists(ctx, txKey)) {
      throw new Error(`Transaction ${finalTxId} already exists`);
    }

    const entry = {
      id: finalTxId,
      userId,
      recipientId: recipientId || null,
      amount: this._safeFloat(amount),
      currencyCode: currencyCode || 'PHP',
      feeAmount: this._safeFloat(feeAmount),
      type: type,
      status: 'verified',
      description: description || '',
      ecoPointsEarned: this._safeFloat(ecoPoints),
      ledgerTimestamp: this._getTxTimestampISO(ctx)
    };

    await ctx.stub.putState(txKey, Buffer.from(JSON.stringify(entry)));

    // Emit event so off-chain listeners can persist to Postgres or trigger actions
    try {
      ctx.stub.setEvent('TransactionCreated', Buffer.from(JSON.stringify(entry)));
    } catch (e) {
      // non-fatal
      console.warn('Failed to set event TransactionCreated', e);
    }

    return entry;
  }

  // Query a transaction by id
  async queryTransaction(ctx, txId) {
    const txKey = `tx-${txId}`;
    const data = await ctx.stub.getState(txKey);
    if (!data || data.length === 0) {
      throw new Error(`Transaction ${txId} does not exist`);
    }
    return JSON.parse(data.toString());
  }

  // Query transactions for a given userId (simple range scan + filter)
  async getTransactionsByUser(ctx, userId) {
    this._ensureArg('userId', userId);
    const startKey = 'tx-';
    const endKey = 'tx-~';
    const iterator = await ctx.stub.getStateByRange(startKey, endKey);
    const results = [];
    while (true) {
      const res = await iterator.next();
      if (res.value && res.value.value.toString()) {
        const record = JSON.parse(res.value.value.toString('utf8'));
        if (record.userId === userId || record.recipientId === userId) {
          results.push(record);
        }
      }
      if (res.done) {
        await iterator.close();
        break;
      }
    }
    return results;
  }

  // Create an ATM QR token (mobile -> ATM flow)
  async createQrToken(ctx, tokenSignature, userId, transactionType, amountLocked, expiresAtIso) {
    this._ensureArg('tokenSignature', tokenSignature);
    this._ensureArg('userId', userId);

    const key = `qr-${tokenSignature}`;
    if (await this._exists(ctx, key)) {
      throw new Error(`QR token ${tokenSignature} already exists`);
    }

    const token = {
      id: tokenSignature,
      userId,
      tokenSignature,
      transactionType: transactionType || 'withdraw',
      amountLocked: this._safeFloat(amountLocked),
      isScanned: false,
      expiresAt: expiresAtIso,
      createdAt: this._getTxTimestampISO(ctx)
    };

    await ctx.stub.putState(key, Buffer.from(JSON.stringify(token)));

    try {
      ctx.stub.setEvent('QrTokenCreated', Buffer.from(JSON.stringify(token)));
    } catch (e) {
      console.warn('Failed to set event QrTokenCreated', e);
    }

    return token;
  }

  // Verify and consume an ATM QR token (ATM -> backend)
  async verifyQrToken(ctx, tokenSignature, scannerId) {
    const key = `qr-${tokenSignature}`;
    const data = await ctx.stub.getState(key);
    if (!data || data.length === 0) {
      throw new Error(`QR token ${tokenSignature} not found`);
    }

    const token = JSON.parse(data.toString());
    const now = this._getTxTimestampDate(ctx);
    if (token.isScanned) {
      throw new Error(`QR token ${tokenSignature} has already been scanned`);
    }
    if (token.expiresAt && new Date(token.expiresAt) < now) {
      throw new Error(`QR token ${tokenSignature} has expired`);
    }

    token.isScanned = true;
    token.scannedBy = scannerId || null;
    token.scannedAt = now.toISOString();

    await ctx.stub.putState(key, Buffer.from(JSON.stringify(token)));

    try {
      ctx.stub.setEvent('QrTokenVerified', Buffer.from(JSON.stringify(token)));
    } catch (e) {
      console.warn('Failed to set event QrTokenVerified', e);
    }

    return token;
  }

  // Read a QR token without consuming it
  async getQrToken(ctx, tokenSignature) {
    const key = `qr-${tokenSignature}`;
    const data = await ctx.stub.getState(key);
    if (!data || data.length === 0) {
      throw new Error(`QR token ${tokenSignature} not found`);
    }
    return JSON.parse(data.toString());
  }

  // Simple cleanup: delete expired QR tokens (be careful with permissions in production)
  async purgeExpiredQrTokens(ctx, limit) {
    const startKey = 'qr-';
    const endKey = 'qr-~';
    const iterator = await ctx.stub.getStateByRange(startKey, endKey);
    const now = new Date();
    const deleted = [];
    let count = 0;
    const max = limit ? parseInt(limit, 10) : 100;
    while (true) {
      const res = await iterator.next();
      if (res.value && res.value.value.toString()) {
        const token = JSON.parse(res.value.value.toString('utf8'));
        if (token.expiresAt && new Date(token.expiresAt) < now) {
          await ctx.stub.deleteState(res.value.key);
          deleted.push(token.id || res.value.key);
          count++;
          if (count >= max) break;
        }
      }
      if (res.done) {
        await iterator.close();
        break;
      }
    }
    return deleted;
  }
}

module.exports.contracts = [ UniTapContract ];
