const { Pool } = require('pg');
require('dotenv').config();

// Database configuration
const dbConfig = {
  // Use individual environment variables for local/test, connection string for production
  ...(process.env.DB_URL && process.env.NODE_ENV === 'production'
    ? { connectionString: process.env.DB_URL }
    : {
      user: process.env.DB_USER || 'postgres',
      host: process.env.DB_HOST || 'localhost',
      database: process.env.DB_NAME || 'camsplit',
      password: process.env.DB_PASSWORD || 'password',
      port: process.env.DB_PORT || 5432,
    }
  ),
  // Connection pool settings
  max: 20, // Maximum number of clients in the pool
  idleTimeoutMillis: 30000, // Close idle clients after 30 seconds
  connectionTimeoutMillis: 2000, // Return an error after 2 seconds if connection could not be established
};

// Create connection pool
const pool = new Pool(dbConfig);

// Test database connection
pool.on('connect', () => {
  console.log('Connected to PostgreSQL database');
});

pool.on('error', (err) => {
  console.error('Unexpected error on idle client', err);
  process.exit(-1);
});

// Helper function to test connection
async function testConnection() {
  try {
    const client = await pool.connect();
    const result = await client.query('SELECT NOW()');
    client.release();
    console.log('Database connection test successful:', result.rows[0]);
    return true;
  } catch (error) {
    console.error('Database connection test failed:', error);
    return false;
  }
}

// Helper function to run migrations
async function runMigration(migrationFile) {
  const fs = require('fs');
  const path = require('path');

  try {
    const migrationPath = path.join(__dirname, 'migrations', migrationFile);
    const migrationSQL = fs.readFileSync(migrationPath, 'utf8');

    const client = await pool.connect();
    await client.query('BEGIN');

    try {
      await client.query(migrationSQL);
      await client.query('COMMIT');
      console.log(`Migration ${migrationFile} completed successfully`);
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  } catch (error) {
    console.error(`Migration ${migrationFile} failed:`, error);
    throw error;
  }
}

// Helper function to run all migrations in order
async function runAllMigrations() {
  try {
    console.log('Running all migrations...');

    // Run migrations in order
    const migrations = [
      //'001_initial_schema.sql',
      '002_items_assignments.sql'
    ];

    for (const migration of migrations) {
      await runMigration(migration);
    }

    console.log('✅ All migrations completed successfully');
  } catch (error) {
    console.error('❌ Migration process failed:', error.message);
    throw error;
  }
}

// Helper function to seed database
async function seedDatabase() {
  const fs = require('fs');
  const path = require('path');

  try {
    const seedPath = path.join(__dirname, 'seed_data.sql');
    const seedSQL = fs.readFileSync(seedPath, 'utf8');

    const client = await pool.connect();
    await client.query('BEGIN');

    try {
      await client.query(seedSQL);
      await client.query('COMMIT');
      console.log('Database seeded successfully');
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  } catch (error) {
    console.error('Database seeding failed:', error);
    throw error;
  }
}

// Helper function to reset database (for testing)
async function resetDatabase() {
  try {
    const client = await pool.connect();
    await client.query('BEGIN');

    try {
      // Drop all tables in correct order (respecting foreign key constraints)
      await client.query(`
        DROP TABLE IF EXISTS 
          assignment_users,
          assignments,
          items,
          receipt_images, 
          payments, 
          expense_splits, 
          expense_payers, 
          expenses, 
          group_members, 
          groups, 
          users 
        CASCADE
      `);

      await client.query('COMMIT');
      console.log('Database reset successfully');
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  } catch (error) {
    console.error('Database reset failed:', error);
    throw error;
  }
}

// Helper function to get database statistics
async function getDatabaseStats() {
  try {
    const client = await pool.connect();

    const stats = {};

    // Get table counts
    const tables = ['users', 'groups', 'group_members', 'expenses', 'expense_payers', 'expense_splits', 'payments', 'receipt_images'];

    for (const table of tables) {
      const result = await client.query(`SELECT COUNT(*) as count FROM ${table}`);
      stats[table] = parseInt(result.rows[0].count);
    }

    client.release();
    return stats;
  } catch (error) {
    console.error('Failed to get database stats:', error);
    throw error;
  }
}

module.exports = {
  pool,
  query: (text, params) => pool.query(text, params),
  testConnection,
  runMigration,
  runAllMigrations,
  seedDatabase,
  resetDatabase,
  getDatabaseStats
}; 