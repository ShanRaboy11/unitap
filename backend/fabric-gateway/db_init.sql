-- Minimal DB schema for storing Fabric contract events
CREATE TABLE IF NOT EXISTS events (
  id SERIAL PRIMARY KEY,
  event_name TEXT NOT NULL,
  payload JSONB,
  tx_id TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Optional: a table to mirror transactions for quick queries (denormalized)
CREATE TABLE IF NOT EXISTS transactions (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  recipient_id TEXT,
  amount NUMERIC,
  currency_code TEXT,
  fee_amount NUMERIC,
  type TEXT,
  status TEXT,
  description TEXT,
  eco_points_earned NUMERIC,
  ledger_timestamp TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);
