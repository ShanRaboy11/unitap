'use strict';

const { Contract } = require('fabric-contract-api');

class UniTapContract extends Contract {

  async initLedger(ctx) {
    console.log("Ledger initialized");
  }

  async logTransaction(ctx, txId, userId, amount, action) {

    const entry = {
      txId,
      userId,
      amount,
      action,
      timestamp: new Date().toISOString()
    };

    await ctx.stub.putState(txId, Buffer.from(JSON.stringify(entry)));

    return entry;
  }
}

module.exports = UniTapContract;
