require('dotenv').config({ path: '.env.test' });

const request = require('supertest');
const app = require('../src/app');
const pool = require('../src/config/db');
const Payment = require('../src/models/Payment');
const Participant = require('../src/models/Participant');
const Bill = require('../src/models/Bill');

describe('Payments Controller', () => {
  let billId, aliceId, bobId, paymentId;

  beforeEach(async () => {
    // Create a user, bill, participants
    const userRes = await pool.query(
      `INSERT INTO users (email, password, name, birthdate) VALUES ('payuser3@example.com', 'hash', 'Pay User', '2000-01-01') RETURNING id`
    );
    const userId = userRes.rows[0].id;
    const billRes = await pool.query(
      `INSERT INTO bills (user_id, image_url) VALUES ($1, 'testurl') RETURNING id`, [userId]
    );
    billId = billRes.rows[0].id;
    const aliceRes = await pool.query(
      `INSERT INTO participants (bill_id, name) VALUES ($1, 'Alice') RETURNING id`, [billId]
    );
    aliceId = aliceRes.rows[0].id;
    const bobRes = await pool.query(
      `INSERT INTO participants (bill_id, name) VALUES ($1, 'Bob') RETURNING id`, [billId]
    );
    bobId = bobRes.rows[0].id;
    // Create a payment from Bob to Alice
    const paymentRes = await pool.query(
      `INSERT INTO payments (bill_id, from_participant_id, to_participant_id, amount, is_paid) VALUES ($1, $2, $3, 50, FALSE) RETURNING id`,
      [billId, bobId, aliceId]
    );
    paymentId = paymentRes.rows[0].id;
  });

  afterEach(async () => {
    // Use Payment model to delete all payments
    const payments = await pool.query('SELECT id FROM payments');
    for (const payment of payments.rows) {
      await Payment.delete(payment.id);
    }
    // Use Participant model to delete all participants
    const participants = await pool.query('SELECT id FROM participants');
    for (const participant of participants.rows) {
      await Participant.delete(participant.id);
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

  it('should mark a payment as paid', async () => {
    const res = await request(app)
      .post(`/api/payments/${paymentId}/pay`);
    expect(res.statusCode).toBe(200);
    expect(res.body.message).toMatch(/marked as paid/);
    // Check DB
    const check = await pool.query('SELECT * FROM payments WHERE id = $1', [paymentId]);
    expect(check.rows[0].is_paid).toBe(true);
  });

  it('should be idempotent if payment is already paid', async () => {
    // Mark as paid once
    await request(app).post(`/api/payments/${paymentId}/pay`);
    // Mark as paid again
    const res = await request(app).post(`/api/payments/${paymentId}/pay`);
    expect(res.statusCode).toBe(200);
    expect(res.body.message).toMatch(/marked as paid/);
    // Still paid
    const check = await pool.query('SELECT * FROM payments WHERE id = $1', [paymentId]);
    expect(check.rows[0].is_paid).toBe(true);
  });

  it('should return 200 even for invalid payment id (no error leak)', async () => {
    const res = await request(app).post(`/api/payments/999999/pay`);
    // Should not throw, but should not update anything
    expect(res.statusCode).toBe(200);
    expect(res.body.message).toMatch(/marked as paid/);
  });
}); 