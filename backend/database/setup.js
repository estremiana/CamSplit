#!/usr/bin/env node

/**
 * Database Setup Script for CamSplit Backend
 * 
 * This script:
 * 1. Tests database connection
 * 2. Runs the initial migration
 * 3. Seeds the database with sample data
 * 4. Displays database statistics
 * 
 * Usage: node database/setup.js
 */

const db = require('./connection');

async function setupDatabase() {
  console.log('🚀 Starting CamSplit Database Setup...\n');

  try {
    // Step 1: Test database connection
    console.log('1️⃣ Testing database connection...');
    const connectionTest = await db.testConnection();
    if (!connectionTest) {
      throw new Error('Database connection failed');
    }
    console.log('✅ Database connection successful\n');

    // Step 2: Run initial migration
            console.log('2️⃣ Running all migrations...');
        await db.runAllMigrations();
    console.log('✅ Migration completed successfully\n');

    // Step 3: Seed database with sample data
    console.log('3️⃣ Seeding database with sample data...');
    await db.seedDatabase();
    console.log('✅ Database seeded successfully\n');

    // Step 4: Display database statistics
    console.log('4️⃣ Database Statistics:');
    const stats = await db.getDatabaseStats();
    
    console.log('\n📊 Database Summary:');
    console.log('─'.repeat(40));
    Object.entries(stats).forEach(([table, count]) => {
      console.log(`${table.padEnd(20)} | ${count.toString().padStart(5)} records`);
    });
    console.log('─'.repeat(40));

    // Step 5: Display sample data overview
    console.log('\n📋 Sample Data Overview:');
    console.log('─'.repeat(50));
    console.log('👥 Users: John Doe, Jane Smith, Bob Wilson, Alice Johnson');
    console.log('🏠 Groups: Roommates, Weekend Getaway, Office Lunch');
    console.log('💰 Expenses: Rent, Electricity, Groceries, Hotel, Restaurant, Team Lunch');
    console.log('💳 Multiple Payers: Rent (John + Jane), others single payer');
    console.log('📊 Splits: Equal splits and custom splits demonstrated');
    console.log('💸 Payments: Pending and completed settlements');
    console.log('📷 Receipts: Sample OCR data for grocery and restaurant receipts');

    console.log('\n🎉 Database setup completed successfully!');
    console.log('\nNext steps:');
    console.log('1. Start the backend server: npm start');
    console.log('2. Test API endpoints with the sample data');
    console.log('3. Proceed to Phase 2: Core Models and Services');

  } catch (error) {
    console.error('\n❌ Database setup failed:', error.message);
    console.error('\nTroubleshooting:');
    console.error('1. Check your .env file has correct database credentials');
    console.error('2. Ensure PostgreSQL is running');
    console.error('3. Verify the database "camsplitdb" exists');
    console.error('4. Check database user permissions');
    
    process.exit(1);
  } finally {
    // Close the database pool
    await db.pool.end();
  }
}

// Run setup if this file is executed directly
if (require.main === module) {
  setupDatabase();
}

module.exports = setupDatabase; 