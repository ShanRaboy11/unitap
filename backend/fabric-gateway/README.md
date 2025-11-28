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

 # Unitap Fabric Gateway

 This document explains how to set up and run the local Hyperledger Fabric test network used by this project, how the Fabric REST gateway works, how chaincode events are persisted (Postgres or file fallback), and how to expose the API for teammates (ngrok). It assumes you're working in the repository root and that Docker and Node.js are installed on your machine.

 ## Overview
 - The Fabric Gateway connects to a Fabric network (test-network in this repo) and exposes an Express REST API (`rest-api.js`) for creating transactions, QR tokens, and querying ledger state.
 - Chaincode events are captured by `event-listener.js` and persisted to Postgres when available; otherwise they are appended to `events.jsonl` as a safe fallback.
 - Auxiliary metadata (e.g., `location`) is stored in the `tx_meta` table and the API logs persisted records for developer visibility.

 ## Prerequisites
 - Node.js (recommended v16+)
 - npm
 - Docker & Docker Compose
 - PowerShell (Windows) or a POSIX shell
 - (Optional) ngrok if you want to expose the local API publicly

 ## Repository layout (relevant)
 - `backend/fabric-gateway/rest-api.js` — Express REST API
 - `backend/fabric-gateway/event-listener.js` — chaincode event listener + persistence
 - `backend/fabric-gateway/connect.js` — helper to establish Fabric gateway using wallet/admin identity
 - `backend/fabric-gateway/import-events.js` — import `events.jsonl` into Postgres
 - `fabric-network/test-network` — the Fabric test-network scripts and docker-compose for local Fabric

 ## Environment variables
 Copy or create a `.env` in `backend/fabric-gateway` with the following values (examples):

 ```
 CHANNEL=mychannel
 CHAINCODE_NAME=unitapcc
 API_KEY=
 PORT=3000
 DATABASE_URL=
 ```

 If `DATABASE_URL` is empty or unreachable, the event listener will fall back to appending `events.jsonl` in this folder.

 ## Local Postgres fallback (recommended for development)
 If you don't want to use Supabase or remote Postgres, run a local Postgres container:

 PowerShell example:

 ```powershell
 docker run --name unitap-local-postgres -p 5432:5432 -e POSTGRES_PASSWORD=unitap -e POSTGRES_USER=unitap -e POSTGRES_DB=unitap -d postgres:14
 ```

 Connection string for `.env` (example):

 ```
 DATABASE_URL=postgres://unitap:unitap@127.0.0.1:5432/unitap
 ```

 ## Database schema (run inside the Postgres container or via psql)

 ```sql
 -- events table
 CREATE TABLE IF NOT EXISTS events (
	 id serial PRIMARY KEY,
	 event_name text,
	 payload jsonb,
	 tx_id text UNIQUE,
	 block_number bigint,
	 block_hash text,
	 created_at timestamptz DEFAULT CURRENT_TIMESTAMP
 );

 -- tx_meta table for optional metadata like location
 CREATE TABLE IF NOT EXISTS tx_meta (
	 tx_id text PRIMARY KEY,
	 location jsonb,
	 created_at timestamptz DEFAULT CURRENT_TIMESTAMP
 );

 CREATE UNIQUE INDEX IF NOT EXISTS idx_events_tx_id_unique ON events(tx_id);
 ```

 ## How to start the Fabric test-network (short)
 1. From repo root, go to the Fabric test-network folder:

 ```powershell
 cd fabric-network/test-network
 # Follow the test-network README — sample commands:
 ./network.sh up createChannel -ca
 ./network.sh deployCC -ccn unitapcc -ccv 1 -ccl javascript -ccp ../../chaincode/unitap
 ```

 Note: The repo contains patched scripts to avoid no-op anchor updates. If you run into anchor peer errors, check `fabric-network/test-network` scripts and logs.

 ## Starting the Fabric Gateway services
 1. Install dependencies in `backend/fabric-gateway`:

 ```powershell
 cd backend/fabric-gateway
 npm install
 ```

 2. Start the event listener and REST API (PowerShell examples):

 ```powershell
 # Start event listener (keeps running in the foreground)
 node event-listener.js

 # In a separate terminal, start the REST API
 node rest-api.js
 ```

 Or run both in background using PowerShell Start-Process:

 ```powershell
 Start-Process -FilePath 'node' -ArgumentList 'event-listener.js' -WorkingDirectory 'C:\Users\GitHub\unitap\backend\fabric-gateway' -NoNewWindow
 Start-Process -FilePath 'node' -ArgumentList 'rest-api.js' -WorkingDirectory 'C:\Users\GitHub\unitap\backend\fabric-gateway' -NoNewWindow
 ```

 ## Exposing the API to a teammate (ngrok)
 - Install and login to ngrok. Then:

 ```powershell
 ngrok http 3000
 ```

 Copy the public URL (https://...) and share with your teammate. If you enabled `API_KEY`, they must include `x-api-key` header or `?api_key=` query.

 ## REST API endpoints (examples)
 - Health: `GET /health`
 - Metadata: `GET /metadata`
 - Create a transaction: `POST /tx/create`
	 - Body fields: `txId`, `userId`, `recipientId`, `amount`, `currencyCode`, `feeAmount`, `type`, `description`, `ecoPoints`, `location`.
	 - The API accepts PascalCase (`UserId`) and snake_case variants automatically for C# clients.

 PowerShell example POST (PascalCase supported):

 ```powershell
 $body = @{ TxId = 'tx-'+[guid]::NewGuid().ToString(); UserId = '00000000-0000-0000-0000-000000000000'; Amount = 50 } | ConvertTo-Json -Compress
 Invoke-RestMethod -Uri 'http://127.0.0.1:3000/tx/create' -Method POST -Body $body -ContentType 'application/json'
 ```

 ## What is persisted and where
 - Chaincode events: `event-listener.js` listens for contract events and writes rows to the `events` table with fields `event_name`, `payload`, `tx_id`, `block_number`, `block_hash`, `created_at`.
 - When Postgres is not reachable, events are appended to `backend/fabric-gateway/events.jsonl` as JSON Lines.
 - Optional transaction metadata (like `location`) is stored in `tx_meta(tx_id, location, created_at)` by the REST API after a successful submit.
 - The APIs log the persisted records to the terminal for debugging (the listener prints the saved DB row or the JSONL row).

 ## Importing fallback file (`events.jsonl`) into Postgres
 - Use the included `import-events.js` script:

 ```powershell
 cd backend/fabric-gateway
 node import-events.js
 ```

 This reads `events.jsonl` and inserts rows into `events` table (useful for backfilling when you switch from file fallback to DB).

 ## Block hash & block number
 - The listener attempts to fetch block information by querying the channel for the block containing the transaction. In some SDK/runtime environments `network.addBlockListener` or `channel.queryBlockByTxID` may not be available — in that case the listener will still persist events but `block_number`/`block_hash` may be `null`.
 - As a pragmatic fallback, peer container logs contain commit hashes; we used these logs to manually verify commits when the SDK block APIs were not available.

 ## Timestamps & Timezones
 - Events and `tx_meta.created_at` use a Manila timezone timestamp (Asia/Manila, +08:00) to make local testing consistent with the service timezone.

 ## Troubleshooting
 - "Missing or empty argument: userId": ensure your POST body includes a `userId` (or compatible variant like `UserId` or `user_id`). The REST API normalizes common variants but will return 400 when `userId` is missing.
 - DB connection errors / DNS ENOTFOUND: If `DATABASE_URL` points to a remote Supabase instance and you see DNS errors, switch to the local Postgres container for development and update `.env`.
 - No block info in events: Some Fabric SDK builds do not expose block query/listener functions. Check `debug-network.js` (in this folder) to inspect the `network` object returned by the SDK. You can also parse peer logs:

 ```powershell
 # Example to see peer logs (container name may differ)
 docker logs peer0.org1.example.com | Select-String -Pattern "Committed block"
 ```

 - If the REST API returns createTransaction errors, inspect the API process logs (the server prints the submitted args and error stacks).

 ## Next steps & suggestions
 - Add `pm2` or another process manager to keep `event-listener.js` and `rest-api.js` running in the background for development.
 - Add an npm `start:dev` script to concurrently run both services and an optional demo transaction.
 - If you prefer continuous block->db mapping, implement a log-tail sidecar that watches peer logs and updates rows with `block_hash`, or implement a deliver-based listener (more robust but more work).

 If you'd like, I can:
 - Add `npm` scripts to start both processes and run a demo tx.
 - Run the local restart and post a demo transaction now and show the console logs.

 Please tell me which you'd like next or what detail you'd like added to this README (e.g., screenshots, exact `.env` values, or automated scripts).
