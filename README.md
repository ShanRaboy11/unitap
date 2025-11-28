# 🪐 UniTap  
### Unified Banking • Blockchain-Secured • Gamified Financial Ecosystem

UniTap is a next-generation omnichannel banking platform built in a **single monorepo** integrating:

- **Flutter mobile app**
- **Node.js backend**
- **Supabase authentication + database**
- **Hyperledger Fabric blockchain** for tamper-proof transaction logs

The platform enables **faster ATM interactions**, **one-time QR transaction tokens**, **gamified eco rewards**, and **AI-powered ATM smart health**—all packaged in a unified, modern financial experience.

This README provides everything needed to set up and run UniTap locally.

---

# 📂 Repository Structure (Monorepo)

```

/unitap/
│
├── app/                        # Flutter mobile app
│   ├── lib/
│   ├── android/
│   ├── ios/
│   ├── pubspec.yaml
│   └── ...
│
├── backend/                    # Node.js backend services
│   └── fabric-gateway/         # Fabric Gateway REST API + event listener
│
├── chaincode/                  # Hyperledger Fabric smart contract
│   └── unitap/
│       └── index.js
│
└── fabric-network/             # Local Fabric test network
└── test-network/

````

---

# 🚀 1. Project Setup Overview

To run UniTap, you will configure:

- **Flutter** (mobile client)
- **Node.js backend** (REST API + blockchain gateway)
- **Supabase** (auth + database)
- **Hyperledger Fabric test network** (local blockchain)
- **Integration** between Flutter → Backend → Fabric

---

# 🧩 2. Prerequisites

### General
- Git  
- VS Code / Android Studio  
- Docker Desktop (or Docker Engine + compose)

### Flutter
- Flutter SDK (latest stable)
- Android Studio (Android SDK)
- Xcode (macOS)

### Node.js
- Node.js **v16+**
- npm

### Windows Users
- **Git Bash or WSL2**  
  (Fabric’s scripts require bash)

---

# 📱 3. Setting Up the Flutter App

### Install Flutter  
https://docs.flutter.dev/get-started/install

### Verify installation
```sh
flutter doctor
````

### Install dependencies

```sh
cd app
flutter pub get
```

### Run the app

```sh
flutter run
```

### Configure `.env` inside `/app`

```
API_BASE_URL=http://127.0.0.1:3000
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_key
```

---

# 🗄 4. Setting Up Supabase (Database)

### Create a Supabase project

[https://supabase.com](https://supabase.com)

### Required tables

* `users`
* `eco_points`
* `recent_transactions`
* `qr_token_history`

### Get your keys

* **SUPABASE_URL**
* **SUPABASE_ANON_KEY**
* **SUPABASE_SERVICE_ROLE_KEY**

Insert into backend `.env`.

---

# ⛓️ 5. Setting Up the Blockchain (Hyperledger Fabric)

UniTap uses a **local Fabric test network** for development.

## Prerequisites

* Docker Desktop
* Git Bash / WSL2 (Windows)
* Node.js 16+

---

## 🧪 Quick Start: Run the network & test blockchain

### 1. Start Fabric network + channel

```sh
cd fabric-network/test-network
./network.sh up
./network.sh createChannel
```

### 2. Populate wallet for Admin identity

Run from repo root:

```sh
node ./backend/fabric-gateway/populateWallet.js
```

### 3. Run blockchain test script

```sh
node ./backend/fabric-gateway/test-tx.js
```

---

## 🔧 Fabric Gateway (Node.js Integration Layer)

### Purpose

The Fabric Gateway exposes REST endpoints for:

* Creating transactions
* Generating one-time QR tokens
* Assigning eco points
* Listening to chaincode events
* Querying ledger history

### Key Files

```
backend/fabric-gateway/rest-api.js
backend/fabric-gateway/event-listener.js
backend/fabric-gateway/connect.js
backend/fabric-gateway/import-events.js
fabric-network/test-network/
```

---

## 🌐 Environment Variables

Create `.env` in `/backend/fabric-gateway/`:

```
CHANNEL=unitapchannel
CHAINCODE_NAME=unitapcc
PORT=3000
DATABASE_URL=
API_KEY=
```

---

## 🛢 Optional: Local Postgres for event storage

Run:

```sh
docker run --name unitap-local-postgres -p 5432:5432 \
  -e POSTGRES_PASSWORD=unitap \
  -e POSTGRES_USER=unitap \
  -e POSTGRES_DB=unitap \
  -d postgres:14
```

Connection string:

```
DATABASE_URL=postgres://unitap:unitap@127.0.0.1:5432/unitap
```

### Schema

```sql
CREATE TABLE IF NOT EXISTS events (
  id serial PRIMARY KEY,
  event_name text,
  payload jsonb,
  tx_id text UNIQUE,
  block_number bigint,
  block_hash text,
  created_at timestamptz DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tx_meta (
  tx_id text PRIMARY KEY,
  location jsonb,
  created_at timestamptz DEFAULT CURRENT_TIMESTAMP
);
```

---

## ▶️ Start Fabric Test Network (Full Flow)

```sh
cd fabric-network/test-network
./network.sh up createChannel -ca
./network.sh deployCC -ccn unitapcc -ccv 1 -ccl javascript -ccp ../../chaincode/unitap
```

## ▶️ Start Fabric Gateway

```sh
cd backend/fabric-gateway
npm install
node event-listener.js
node rest-api.js
```

## ▶️ (Optional) Expose API via ngrok

```sh
ngrok http 3000
```

---

# 📡 6. Connect Flutter to Backend (and Blockchain)

Flutter communicates **only** with the backend, never directly with Fabric.

### Example Dart call

```dart
final res = await http.post(
  Uri.parse('$API_BASE_URL/tx/create'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    "userId": uid,
    "amount": 500,
    "type": "withdraw",
  }),
);
```

---

# 📝 7. Chaincode Location

```
/chaincode/unitap/index.js
```

Define functions:

* `createTransaction()`
* `createQRToken()`
* `assignEcoPoints()`
* `storeMetadata()`
* etc.

---

You should **add these lines in a dedicated section** for the **AI-powered ATM Smart Health module**, since this installation is **not part of Flutter, Node.js, Supabase, or Fabric**.
It belongs to a **separate Python-based subsystem**.

### ✅ Best Placement in Your README

Add it as **Section 9** (or after the Summary) with a title like:

---

## 🧠 8. AI-Powered ATM Smart Health (Python Module)

This module uses computer vision to detect human presence near the ATM.
If no human activity is detected, the ATM can automatically enter **power-saving mode**.

### Install Dependencies

```sh
pip install opencv-python ultralytics numpy
```

### Run the AI Test Script

```sh
python AI/test_gadget.py
```

### Folder Structure Example

```
AI
│── test_gadget.py


# 🏁 9. Summary

UniTap is an all-in-one banking ecosystem featuring:

* **Flutter** mobile interface
* **Node.js** backend gateway
* **Supabase** for auth & database
* **Hyperledger Fabric** for secure, immutable transaction logs
* **One-time QR ATM tokens** for faster banking
* **Gamified Eco Points** (transactions = trees planted)
* **AI-powered ATM smart health**
* **Unified omnichannel payments, transfers, and cash operations**

This README contains the full installation, setup, and integration steps to run UniTap locally in a monorepo structure.
