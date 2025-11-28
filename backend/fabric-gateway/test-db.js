require('dotenv').config();
const { Pool } = require('pg');

// Prefer DATABASE_URL but fall back to PG* env vars (PGUSER/PGPASSWORD/PGHOST/PGPORT/PGDATABASE)
const connectionString = process.env.DATABASE_URL;
const pool = connectionString ? new Pool({ connectionString }) : new Pool();

(async () => {
  try {
    const client = await pool.connect();
    console.log('DB connect OK');
    client.release();
    await pool.end();
    process.exit(0);
  } catch (e) {
    console.error('DB connect failed:', e.message || e);
    process.exit(2);
  }
})();
