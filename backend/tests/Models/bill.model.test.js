const Bill = require('../../src/models/Bill');
const pool = require('../../src/config/db');

describe('Bill Model', () => {
  let userId;
  beforeAll(async () => {
    const res = await pool.query(`INSERT INTO users (email, password, name, birthdate) VALUES ('billmodeluser@example.com', 'hash', 'Bill Model', '2000-01-01') RETURNING id`);
    userId = res.rows[0].id;
  });
  afterAll(async () => {
    await pool.query('DELETE FROM items');
    await pool.query('DELETE FROM bills');
    await pool.query('DELETE FROM users');
    await pool.end();
  });

  it('should create a bill', async () => {
    const bill = await Bill.create({ user_id: userId, image_url: 'testurl' });
    expect(bill).toHaveProperty('id');
    expect(bill).toHaveProperty('user_id', userId);
    expect(bill).toHaveProperty('image_url', 'testurl');
  });

  it('should find a bill by id', async () => {
    const created = await Bill.create({ user_id: userId, image_url: 'testurl' });
    const found = await Bill.findById(created.id);
    expect(found).toHaveProperty('id', created.id);
  });

  it('should update a bill', async () => {
    const created = await Bill.create({ user_id: userId, image_url: 'testurl' });
    const updated = await Bill.update(created.id, { image_url: 'newurl' });
    expect(updated).toHaveProperty('image_url', 'newurl');
  });

  it('should delete a bill', async () => {
    const created = await Bill.create({ user_id: userId, image_url: 'testurl' });
    const deleted = await Bill.delete(created.id);
    expect(deleted).toHaveProperty('id', created.id);
    const found = await Bill.findById(created.id);
    expect(found).toBeNull();
  });

  it('should find bills by user id', async () => {
    await Bill.create({ user_id: userId, image_url: 'testurl1' });
    await Bill.create({ user_id: userId, image_url: 'testurl2' });
    const bills = await Bill.findByUserId(userId);
    expect(Array.isArray(bills)).toBe(true);
    expect(bills.length).toBeGreaterThanOrEqual(2);
  });

  it('should get bill with total', async () => {
    const created = await Bill.create({ user_id: userId, image_url: 'testurl' });
    await pool.query('INSERT INTO items (bill_id, name, unit_price, total_price, quantity, quantity_left) VALUES ($1, $2, $3, $4, $5, $6)', [created.id, 'Pizza', 10, 20, 2, 2]);
    const billWithTotal = await Bill.getBillWithTotal(created.id);
    expect(billWithTotal).toHaveProperty('total');
    expect(billWithTotal.total).toBeGreaterThan(0);
  });
}); 