const { Gateway, Wallets } = require("fabric-network");
const path = require("path");
const fs = require("fs");

async function connectToFabric() {
  const ccpPath = path.resolve(
    __dirname,
    "../../fabric-network/test-network/organizations/peerOrganizations/org1.example.com/connection-org1.json"
  );

  if (!fs.existsSync(ccpPath)) {
    throw new Error(
      `Connection profile not found at ${ccpPath}. Run the test-network and generate connection profile before connecting.`
    );
  }

  const ccp = JSON.parse(fs.readFileSync(ccpPath, "utf8"));

  const walletPath = path.join(process.cwd(), "wallet");
  const wallet = await Wallets.newFileSystemWallet(walletPath);

  const identityExists = await wallet.get("admin");
  if (!identityExists) {
    throw new Error(
      `Admin identity not found in wallet at ${walletPath}. Run populateWallet.js to import the admin identity before connecting.`
    );
  }

  const gateway = new Gateway();

  await gateway.connect(ccp, {
    wallet,
    identity: "admin",
    discovery: { enabled: true, asLocalhost: true }
  });

  const network = await gateway.getNetwork("unitapchannel");
  const contract = network.getContract("unitapcc");

  return contract;
}

module.exports = connectToFabric;
