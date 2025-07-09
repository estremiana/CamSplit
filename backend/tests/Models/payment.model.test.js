const Payment = require('../../src/models/Payment');
const Bill = require('../../src/models/Bill');
const Participant = require('../../src/models/Participant');
const pool = require('../../src/config/db');

describe('Payment Model', () => {
  let billId, fromId, toId;
  beforeAll(async () => {
    const res = await pool.query(`INSERT INTO users (email, password, name, birthdate) VALUES ('paymodeluser@example.com', 'hash', 'Pay Model', '2000-01-01') RETURNING id`);
    const userId = res.rows[0].id;
    const bill = await Bill.create({ user_id: userId, image_url: 'testurl' });
    billId = bill.id;
    const from = await Participant.create({ bill_id: billId, name: 'Alice' });
    fromId = from.id;
    const to = await Participant.create({ bill_id: billId, name: 'Bob' });
    toId = to.id;
  });
  afterAll(async () => {
    await pool.query('DELETE FROM payments');
    await pool.query('DELETE FROM participants');
    await pool.query('DELETE FROM bills');
    await pool.query('DELETE FROM users');
    await pool.end();
  });

  it('should create a payment', async () => {
    const payment = await Payment.create({ bill_id: billId, from_participant_id: fromId, to_participant_id: toId, amount: 50 });
    expect(payment).toHaveProperty('id');
    expect(payment).toHaveProperty('bill_id', billId);
    expect(payment).toHaveProperty('from_participant_id', fromId);
    expect(payment).toHaveProperty('to_participant_id', toId);
    expect(Number(payment.amount)).toBe(50);
  });

  it('should find a payment by id', async () => {
    const created = await Payment.create({ bill_id: billId, from_participant_id: fromId, to_participant_id: toId, amount: 50 });
    const found = await Payment.findById(created.id);
    expect(found).toHaveProperty('id', created.id);
  });

  it('should find payments by bill id', async () => {
    await Payment.create({ bill_id: billId, from_participant_id: fromId, to_participant_id: toId, amount: 50 });
    const payments = await Payment.findByBillId(billId);
    expect(Array.isArray(payments)).toBe(true);
    expect(payments.length).toBeGreaterThanOrEqual(1);
  });

  it('should update a payment', async () => {
    const created = await Payment.create({ bill_id: billId, from_participant_id: fromId, to_participant_id: toId, amount: 50 });
    const updated = await Payment.update(created.id, { amount: 75, is_paid: true });
    expect(Number(updated.amount)).toBe(75);
    expect(updated.is_paid).toBe(true);
  });

  it('should mark a payment as paid', async () => {
    const created = await Payment.create({ bill_id: billId, from_participant_id: fromId, to_participant_id: toId, amount: 50 });
    const paid = await Payment.markAsPaid(created.id);
    expect(paid.is_paid).toBe(true);
  });

  it('should delete a payment', async () => {
    const created = await Payment.create({ bill_id: billId, from_participant_id: fromId, to_participant_id: toId, amount: 50 });
    const deleted = await Payment.delete(created.id);
    expect(deleted).toHaveProperty('id', created.id);
    const found = await Payment.findById(created.id);
    expect(found).toBeNull();
  });
}); 