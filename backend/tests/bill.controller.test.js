require('dotenv').config({ path: '.env.test' });

const request = require('supertest');
const app = require('../src/app');
const pool = require('../src/config/db');
const fs = require('fs');
const path = require('path');
const cloudinary = require('../src/config/cloudinary');
const Bill = require('../src/models/Bill');

describe('Bill Upload and Retrieval', () => {
  let userId;
  let uploadedPublicIds = [];

  beforeEach(async () => {
    // Create a user for bill upload
    const res = await pool.query(
      `INSERT INTO users (email, password, name, birthdate) VALUES ('billtestuser@example.com', 'hash', 'Bill Test', '2000-01-01') RETURNING id`
    );
    userId = res.rows[0].id;
  });

  afterEach(async () => {
    for (const publicId of uploadedPublicIds) {
      await cloudinary.uploader.destroy(publicId, { resource_type: 'image' });
    }
    uploadedPublicIds = [];
    await pool.query('DELETE FROM participants');
    // Use Bill model to delete all bills
    const bills = await pool.query('SELECT id FROM bills');
    for (const bill of bills.rows) {
      await Bill.delete(bill.id);
    }
    await pool.query('DELETE FROM users');
  });

  afterAll(async () => {
    await pool.end();
  });

  it('should upload a bill image and return bill data', async () => {
    
    const res = await request(app)
      .post('/api/bills/upload')
      .attach('image', path.join(__dirname, 'test.jpg'))
      .field('user_id', userId);
    expect(res.statusCode).toBe(201);
    expect(res.body.bill).toHaveProperty('image_url');
    const publicId = res.body.bill.image_url.match(/bills\/([^\.\/]+)/)[1];
    uploadedPublicIds.push(`bills/${publicId}`);
  });

  it('should retrieve a bill by id', async () => {
    // First, upload a bill
    const uploadRes = await request(app)
      .post('/api/bills/upload')
      .attach('image', path.join(__dirname, 'test.jpg'))
      .field('user_id', userId);
    const billId = uploadRes.body.bill.id;
    const publicId = uploadRes.body.bill.image_url.match(/bills\/([^\.\/]+)/)[1];
    uploadedPublicIds.push(`bills/${publicId}`);

    // Now, retrieve it
    const getRes = await request(app)
      .get(`/api/bills/${billId}`);
    expect(getRes.statusCode).toBe(200);
    expect(getRes.body.bill).toHaveProperty('id', billId);
    expect(getRes.body.bill).toHaveProperty('user_id', userId);
    expect(getRes.body.bill).toHaveProperty('image_url');
  });

  it('should return 404 for non-existent bill', async () => {
    const res = await request(app)
      .get('/api/bills/999999');
    expect(res.statusCode).toBe(404);
    expect(res.body.message).toMatch(/not found/i);
  });
}); 