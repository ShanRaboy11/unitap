# Fabric Gateway - quick dev README

This folder contains helper scripts to connect to the local Hyperledger Fabric test network and a small test script that demonstrates creating QR tokens and transactions on the `unitapcc` contract.

Prerequisites
- Docker Desktop (or Podman) installed and running.
- Git Bash or WSL/WSL2 on Windows (the `test-network` scripts are bash-based).
- Node.js (v16+ recommended) and `npm`.

Quick steps to run the test script

1. Start the Fabric test network and create the channel

Open a Git Bash or WSL shell and run (from repo root):

```bash
cd fabric-network/test-network
# bring up the network and create the channel (script may require -bft flag in this repo, see README)
./network.sh up
# create the channel (if network.sh requires explicit create)
./network.sh createChannel
```

2. Populate the Node.js wallet with the Admin identity

Switch back to Windows PowerShell or run in the same Bash session. From the repo root run:

```powershell
node .\backend\fabric-gateway\populateWallet.js
```

That script reads the generated crypto material from `fabric-network/test-network/organizations/...` and writes an `admin` identity into a local `wallet/` folder.

3. Run the test script

From PowerShell (repo root):

```powershell
node .\backend\fabric-gateway\test-tx.js
```

Troubleshooting: "Connection profile not found"

If you see the error: `Connection profile not found at ... connection-org1.json`, it means the Fabric test network has not been run (or connection profiles were not generated). To fix:
- Make sure you ran the `network.sh` script from `fabric-network/test-network` in a Bash environment.
- After the network is started, the connection profiles are created under `fabric-network/test-network/organizations/peerOrganizations/org1.example.com/connection-org1.json`.
- Then run `node backend/fabric-gateway/populateWallet.js` to create the wallet entries.

Notes
- `connect.js` expects a filesystem wallet in the repo root at `./wallet` and an `admin` identity inside it.
- The `test-tx.js` script uses `unitapchannel` and contract `unitapcc` (see `connect.js`). If your channel or contract name differs, update `connect.js` or the test script accordingly.

Next recommended steps
- Add event listeners in the backend to persist `TransactionCreated`, `QrTokenCreated`, and `QrTokenVerified` events into your Postgres schema.
- Add tests or CI steps that automate starting the test network and running the Node.js script (requires Docker-in-Docker or an integration runner).

If you'd like, I can also update `connect.js` to return the `gateway` object (so scripts can `gateway.disconnect()` cleanly) and update the test script to disconnect after running.
