const fs = require("fs");
const path = require("path");
const { Wallets } = require("fabric-network");

async function populateWallet(options = {}) {
  const orgDomain = options.orgDomain || "org1.example.com";
  const identityLabel = options.identityLabel || "admin";

  // Paths relative to repo layout used by test-network
  const orgBase = path.resolve(
    __dirname,
    `../../fabric-network/test-network/organizations/peerOrganizations/${orgDomain}`
  );

  if (!fs.existsSync(orgBase)) {
    throw new Error(`Organization folder not found: ${orgBase}`);
  }

  const certPath = path.join(
    orgBase,
    `users/Admin@${orgDomain}/msp/signcerts`,
    `Admin@${orgDomain}-cert.pem`
  );

  const keyDir = path.join(orgBase, `users/Admin@${orgDomain}/msp/keystore`);

  if (!fs.existsSync(certPath)) {
    throw new Error(`Admin certificate not found at ${certPath}`);
  }

  if (!fs.existsSync(keyDir)) {
    throw new Error(`Admin keystore not found at ${keyDir}`);
  }

  const keyFiles = fs.readdirSync(keyDir).filter((f) => f.endsWith(".pem") || f.endsWith(".key"));
  if (keyFiles.length === 0) {
    throw new Error(`No private key file found in ${keyDir}`);
  }

  const keyPath = path.join(keyDir, keyFiles[0]);

  const certificate = fs.readFileSync(certPath, "utf8");
  const privateKey = fs.readFileSync(keyPath, "utf8");

  // Derive MSP ID for the org (common test-network naming)
  // e.g., org1.example.com -> Org1MSP
  const mspId = (() => {
    const m = orgDomain.match(/^org(\d+)\./i);
    if (m) return `Org${m[1]}MSP`;
    return "Org1MSP";
  })();

  const walletPath = path.join(process.cwd(), "wallet");
  const wallet = await Wallets.newFileSystemWallet(walletPath);

  const identity = {
    credentials: {
      certificate: certificate,
      privateKey: privateKey
    },
    mspId: mspId,
    type: "X.509"
  };

  await wallet.put(identityLabel, identity);

  console.log(`Successfully imported identity '${identityLabel}' into wallet at ${walletPath}`);
  console.log(`- certificate: ${certPath}`);
  console.log(`- private key: ${keyPath}`);
  console.log(`Next: run your code that uses the gateway (e.g. connect.js) which expects identity '${identityLabel}'.`);
}

if (require.main === module) {
  // Allow optional args: node populateWallet.js orgDomain identityLabel
  const orgDomain = process.argv[2] || "org1.example.com";
  const identityLabel = process.argv[3] || "admin";

  populateWallet({ orgDomain, identityLabel }).catch((err) => {
    console.error("Failed to populate wallet:", err);
    process.exit(1);
  });
}

module.exports = populateWallet;
