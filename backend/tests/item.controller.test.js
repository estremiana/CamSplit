require('dotenv').config({ path: '.env.test' });

const request = require('supertest');
const app = require('../src/app');
const pool = require('../src/config/db');
const Item = require('../src/models/Item');
const Bill = require('../src/models/Bill');

describe('Items', () => {
  let billId;

  beforeEach(async () => {
    // Create a user and a bill
    const userRes = await pool.query(
      `INSERT INTO users (email, password, name, birthdate) VALUES ('itemuser@example.com', 'hash', 'Item User', '2000-01-01') RETURNING id`
    );
    const userId = userRes.rows[0].id;
    const billRes = await pool.query(
      `INSERT INTO bills (user_id, image_url) VALUES ($1, 'testurl') RETURNING id`, [userId]
    );
    billId = billRes.rows[0].id;
  });

  afterEach(async () => {
    // Use Item model to delete all items
    const items = await pool.query('SELECT id FROM items');
    for (const item of items.rows) {
      await Item.delete(item.id);
    }
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

  it('should add items to a bill', async () => {
    const res = await request(app)
      .post(`/api/bills/${billId}/items`)
      .send({
        items: [
          { description: 'Pizza', quantity: 2, unit_price: 10, total_price: 20 },
          { description: 'Beer', quantity: 3, unit_price: 5, total_price: 15 }
        ]
      });
    expect(res.statusCode).toBe(201);
    expect(res.body.items.length).toBe(2);
    expect(res.body.items[0]).toHaveProperty('name', 'Pizza');
    expect(res.body.items[1]).toHaveProperty('name', 'Beer');
  });

  it('should not add items with missing fields', async () => {
    const res = await request(app)
      .post(`/api/bills/${billId}/items`)
      .send({ items: [{ description: 'Pizza' }] });
    expect(res.statusCode).toBe(400);
  });

  it('should fetch all items for a bill', async () => {
    await request(app)
      .post(`/api/bills/${billId}/items`)
      .send({
        items: [
          { description: 'Pizza', quantity: 2, unit_price: 10, total_price: 20 },
          { description: 'Beer', quantity: 3, unit_price: 5, total_price: 15 }
        ]
      });
    const res = await request(app)
      .get(`/api/bills/${billId}/items`);
    expect(res.statusCode).toBe(200);
    expect(res.body.items.length).toBe(2);
    expect(res.body.items.map(i => i.name)).toEqual(expect.arrayContaining(['Pizza', 'Beer']));
  });
}); 