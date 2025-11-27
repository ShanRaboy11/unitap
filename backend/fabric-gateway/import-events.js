require('dotenv').config();
const fs = require('fs');
const readline = require('readline');
const { Pool } = require('pg');
const path = require('path');

const pool = process.env.DATABASE_URL ? new Pool({ connectionString: process.env.DATABASE_URL }) : new Pool();
const filePath = path.join(__dirname, 'events.jsonl');

async function importEvents() {
  if (!fs.existsSync(filePath)) {
    console.error('No events.jsonl found at', filePath);
    process.exit(1);
  }

  const rl = readline.createInterface({
    input: fs.createReadStream(filePath),
    crlfDelay: Infinity
  });

  const client = await pool.connect();
  try {
    let count = 0;
    for await (const line of rl) {
      if (!line || !line.trim()) continue;
      let row;
      try {
        row = JSON.parse(line);
      } catch (e) {
        console.warn('Skipping invalid JSON line:', e.message);
        continue;
      }
      const { event_name, payload, tx_id, created_at } = row;
      try {
        await client.query(
          'INSERT INTO events(event_name, payload, tx_id, created_at) VALUES($1, $2, $3, $4) ON CONFLICT DO NOTHING',
          [event_name, JSON.stringify(payload), tx_id, created_at]
        );
        count++;
      } catch (e) {
        console.error('Failed to insert event', e.message || e);
      }
    }
    console.log('Imported', count, 'events');
  } finally {
    client.release();
    await pool.end();
  }
}

importEvents().catch(e => {
  console.error('Import failed', e.message || e);
  process.exit(1);
});
