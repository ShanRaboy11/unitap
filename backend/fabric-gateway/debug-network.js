require('dotenv').config();
const connectToFabric = require('./connect');
(async () => {
  const { gateway, contract } = await connectToFabric();
  console.log('Gateway type:', typeof gateway);
  const network = gateway.getNetwork(process.env.CHANNEL || 'mychannel');
  console.log('Network keys:', Object.keys(network));
  console.log('Has getChannel:', typeof network.getChannel);
  // try to inspect channel property if available
  if (typeof network.getChannel === 'function') {
    const channel = network.getChannel();
    console.log('Channel type, keys:', typeof channel, Object.keys(channel));
  } else {
    console.log('network.getChannel not a function; trying to inspect internal properties...');
    try {
      console.log('network._network ? keys:', network._network ? Object.keys(network._network) : 'no _network');
      console.log('network._network.getChannel ? ', network._network && typeof network._network.getChannel);
    } catch (e) {
      console.error('inspect failed', e.message);
    }
  }
  await gateway.disconnect();
})();