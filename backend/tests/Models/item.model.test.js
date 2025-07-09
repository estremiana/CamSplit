const Item = require('../../src/models/Item');
const Bill = require('../../src/models/Bill');
const pool = require('../../src/config/db');

describe('Item Model', () => {
  let billId;
  beforeAll(async () => {
    const res = await pool.query(`INSERT INTO users (email, password, name, birthdate) VALUES ('itemmodeluser@example.com', 'hash', 'Item Model', '2000-01-01') RETURNING id`);
    const userId = res.rows[0].id;
    const bill = await Bill.create({ user_id: userId, image_url: 'testurl' });
    billId = bill.id;
  });
  afterAll(async () => {
    await pool.query('DELETE FROM items');
    await pool.query('DELETE FROM bills');
    await pool.query('DELETE FROM users');
    await pool.end();
  });

  it('should create an item', async () => {
    const item = await Item.create({ bill_id: billId, name: 'Pizza', unit_price: 10, total_price: 20, quantity: 2, quantity_left: 2 });
    expect(item).toHaveProperty('id');
    expect(item).toHaveProperty('bill_id', billId);
    expect(item).toHaveProperty('name', 'Pizza');
  });

  it('should find an item by id', async () => {
    const created = await Item.create({ bill_id: billId, name: 'Pizza', unit_price: 10, total_price: 20, quantity: 2, quantity_left: 2 });
    const found = await Item.findById(created.id);
    expect(found).toHaveProperty('id', created.id);
  });

  it('should find items by bill id', async () => {
    await Item.create({ bill_id: billId, name: 'Pizza', unit_price: 10, total_price: 20, quantity: 2, quantity_left: 2 });
    await Item.create({ bill_id: billId, name: 'Beer', unit_price: 5, total_price: 15, quantity: 3, quantity_left: 3 });
    const items = await Item.findByBillId(billId);
    expect(Array.isArray(items)).toBe(true);
    expect(items.length).toBeGreaterThanOrEqual(2);
  });

  it('should update an item', async () => {
    const created = await Item.create({ bill_id: billId, name: 'Pizza', unit_price: 10, total_price: 20, quantity: 2, quantity_left: 2 });
    const updated = await Item.update(created.id, { name: 'Burger', unit_price: 12, total_price: 24, quantity: 2, quantity_left: 2 });
    expect(updated).toHaveProperty('name', 'Burger');
    expect(Number(updated.unit_price)).toBe(12);
  });

  it('should delete an item', async () => {
    const created = await Item.create({ bill_id: billId, name: 'Pizza', unit_price: 10, total_price: 20, quantity: 2, quantity_left: 2 });
    const deleted = await Item.delete(created.id);
    expect(deleted).toHaveProperty('id', created.id);
    const found = await Item.findById(created.id);
    expect(found).toBeNull();
  });
}); 