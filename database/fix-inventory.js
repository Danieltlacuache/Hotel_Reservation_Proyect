const { Pool } = require('pg');
const Redis = require('ioredis');

const connStr = process.env.DATABASE_URL.replace('?sslmode=no-verify', '');
const redisUrl = process.env.REDIS_URL;

const pool = new Pool({
  connectionString: connStr,
  ssl: { rejectUnauthorized: false }
});

async function main() {
  try {
    // 1. Verify DB has data
    const count = await pool.query('SELECT COUNT(*) as total FROM room_inventory WHERE available > 0');
    console.log('DB inventory rows with availability:', count.rows[0].total);

    const rooms = await pool.query('SELECT COUNT(*) as total FROM rooms');
    console.log('DB rooms:', rooms.rows[0].total);

    // 2. Flush Redis cache
    if (redisUrl) {
      console.log('Connecting to Redis:', redisUrl.substring(0, 20) + '...');
      const redis = new Redis(redisUrl, {
        tls: redisUrl.startsWith('rediss://') ? { rejectUnauthorized: false } : undefined,
        maxRetriesPerRequest: 3,
        connectTimeout: 10000
      });
      
      await redis.flushall();
      console.log('Redis FLUSHALL complete - cache cleared');
      await redis.quit();
    } else {
      console.log('No REDIS_URL found, skipping cache flush');
    }

    console.log('=== FIX COMPLETE ===');
  } catch (err) {
    console.error('Error:', err.message);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

main();
