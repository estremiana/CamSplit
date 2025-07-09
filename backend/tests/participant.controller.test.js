require('dotenv').config({ path: '.env.test' });

const request = require('supertest');
const app = require('../src/app');
const pool = require('../src/config/db');
const Participant = require('../src/models/Participant');
const Bill = require('../src/models/Bill');
const Item = require('../src/models/Item');

describe('Participants', () => {
  let billId;

  beforeEach(async () => {
    // Create a user and a bill
    const userRes = await pool.query(
      `INSERT INTO users (email, password, name, birthdate) VALUES ('participanttestuser@example.com', 'hash', 'Participant Test', '2000-01-01') RETURNING id`
    );
    const userId = userRes.rows[0].id;
    const billRes = await pool.query(
      `INSERT INTO bills (user_id, image_url) VALUES ($1, 'testurl') RETURNING id`, [userId]
    );
    billId = billRes.rows[0].id;
  });

  afterEach(async () => {
    // Use Participant model to delete all participants
    const participants = await pool.query('SELECT id FROM participants');
    for (const participant of participants.rows) {
      await Participant.delete(participant.id);
    }
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

  it('should create a participant for a bill', async () => {
    const res = await request(app)
      .post(`/api/bills/${billId}/participants`)
      .send({ name: 'Alice' });
    expect(res.statusCode).toBe(201);
    expect(res.body.participant).toHaveProperty('id');
    expect(res.body.participant).toHaveProperty('name', 'Alice');
    expect(res.body.participant).toHaveProperty('bill_id', billId);
  });

  it('should not create a participant with missing name', async () => {
    const res = await request(app)
      .post(`/api/bills/${billId}/participants`)
      .send({});
    expect(res.statusCode).toBe(400);
  });

  it('should fetch all participants for a bill', async () => {
    await request(app)
      .post(`/api/bills/${billId}/participants`)
      .send({ name: 'Alice' });
    await request(app)
      .post(`/api/bills/${billId}/participants`)
      .send({ name: 'Bob' });
    const res = await request(app)
      .get(`/api/bills/${billId}/participants`);
    expect(res.statusCode).toBe(200);
    expect(res.body.participants.length).toBe(2);
    expect(res.body.participants.map(p => p.name)).toEqual(expect.arrayContaining(['Alice', 'Bob']));
  });
});


describe('Payments and Settlement', () => {
  let billId, participantId1, participantId2, itemId;

  beforeEach(async () => {
    // Create a user, bill, participants, and an item
    const userRes = await pool.query(
      `INSERT INTO users (email, password, name, birthdate) VALUES ('participanttestuser@example.com', 'hash', 'Participant Test', '2000-01-01') RETURNING id`
    );
    const userId = userRes.rows[0].id;
    const billRes = await pool.query(
      `INSERT INTO bills (user_id, image_url) VALUES ($1, 'testurl') RETURNING id`, [userId]
    );
    billId = billRes.rows[0].id;
    const partRes1 = await pool.query(
      `INSERT INTO participants (bill_id, name) VALUES ($1, 'Alice') RETURNING id`, [billId]
    );
    participantId1 = partRes1.rows[0].id;
    const partRes2 = await pool.query(
      `INSERT INTO participants (bill_id, name) VALUES ($1, 'Bob') RETURNING id`, [billId]
    );
    participantId2 = partRes2.rows[0].id;
    const itemRes = await pool.query(
      `INSERT INTO items (bill_id, name, unit_price, total_price, quantity, quantity_left) VALUES ($1, 'Pizza', 20, 20, 1, 1) RETURNING id`, [billId]
    );
    itemId = itemRes.rows[0].id;
    // Assign pizza to both participants (split cost)
    await pool.query(
      `INSERT INTO assignments (item_id, participant_id, quantity, cost_per_person) VALUES ($1, $2, 1, 10), ($1, $3, 1, 10)`,
      [itemId, participantId1, participantId2]
    );
  });

  afterEach(async () => {
    await pool.query('DELETE FROM assignments');
    await pool.query('DELETE FROM participants');
    await pool.query('DELETE FROM items');
    await pool.query('DELETE FROM bills');
    await pool.query('DELETE FROM users');
  });

  it('should set payments for a bill', async () => {
    const res = await request(app)
      .post(`/api/bills/${billId}/payments`)
      .send({
        payments: [
          { participantId: participantId1, amount_paid: 15 },
          { participantId: participantId2, amount_paid: 5 }
        ]
      });
    expect(res.statusCode).toBe(200);
    expect(res.body.message).toMatch(/Payments updated/);
    // Check DB
    const check = await pool.query('SELECT * FROM participants WHERE bill_id = $1', [billId]);
    const alice = check.rows.find(p => p.id === participantId1);
    const bob = check.rows.find(p => p.id === participantId2);
    expect(Number(alice.amount_paid)).toBe(15);
    expect(Number(bob.amount_paid)).toBe(5);
  });

  it('should not set payments with missing fields', async () => {
    const res = await request(app)
      .post(`/api/bills/${billId}/payments`)
      .send({ payments: [{ participantId: participantId1 }] });
    expect(res.statusCode).toBe(400);
  });
});

describe('Payments Table and SettleBill Payments', () => {
  let billId, aliceId, bobId, carolId, itemId;

  beforeEach(async () => {
    // Create a user, bill, participants, and an item
    const userRes = await pool.query(
      `INSERT INTO users (email, password, name, birthdate) VALUES ('participanttestuser@example.com', 'hash', 'Participant Test', '2000-01-01') RETURNING id`
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
    const carolRes = await pool.query(
      `INSERT INTO participants (bill_id, name) VALUES ($1, 'Carol') RETURNING id`, [billId]
    );
    carolId = carolRes.rows[0].id;
    itemId = (await pool.query(
      `INSERT INTO items (bill_id, name, unit_price, total_price, quantity, quantity_left) VALUES ($1, 'Pizza', 100, 100, 1, 1) RETURNING id`, [billId]
    )).rows[0].id;
  });

  afterEach(async () => {
    await pool.query('DELETE FROM payments');
    await pool.query('DELETE FROM assignments');
    await pool.query('DELETE FROM participants');
    await pool.query('DELETE FROM items');
    await pool.query('DELETE FROM bills');
    await pool.query('DELETE FROM users');
  });

  it('should generate payments where one person is owed by multiple people', async () => {
    // Alice paid 100, owes 40 (net +60)
    // Bob paid 0, owes 30 (net -30)
    // Carol paid 0, owes 30 (net -30)
    await pool.query('UPDATE participants SET amount_paid = 100 WHERE id = $1', [aliceId]);
    await pool.query('UPDATE participants SET amount_paid = 0 WHERE id = $1', [bobId]);
    await pool.query('UPDATE participants SET amount_paid = 0 WHERE id = $1', [carolId]);
    // Assignments: Alice owes 40, Bob owes 30, Carol owes 30
    await pool.query('INSERT INTO assignments (bill_id, item_id, participant_id, quantity, cost_per_person) VALUES ($1, $2, $3, 1, 40), ($1, $2, $4, 1, 30), ($1, $2, $5, 1, 30)', [billId, itemId, aliceId, bobId, carolId]);
    // Call settle
    const res = await request(app).get(`/api/bills/${billId}/settle`);
    expect(res.statusCode).toBe(200);
    // Alice should be owed by Bob and Carol
    const payments = res.body.payments;
    expect(payments.length).toBe(2);
    const bobToAlice = payments.find(p => p.from === bobId && p.to === aliceId);
    const carolToAlice = payments.find(p => p.from === carolId && p.to === aliceId);
    expect(Number(bobToAlice.amount)).toBe(30);
    expect(Number(carolToAlice.amount)).toBe(30);
  });

  it('should generate payments where one person owes to more than one person', async () => {
    // Alice paid 60, owes 40 (net +20)
    // Bob paid 40, owes 30 (net +10)
    // Carol paid 0, owes 30 (net -30)
    await pool.query('UPDATE participants SET amount_paid = 60 WHERE id = $1', [aliceId]);
    await pool.query('UPDATE participants SET amount_paid = 40 WHERE id = $1', [bobId]);
    await pool.query('UPDATE participants SET amount_paid = 0 WHERE id = $1', [carolId]);
    // Assignments: Alice owes 40, Bob owes 30, Carol owes 30
    await pool.query('INSERT INTO assignments (bill_id, item_id, participant_id, quantity, cost_per_person) VALUES ($1, $2, $3, 1, 40), ($1, $2, $4, 1, 30), ($1, $2, $5, 1, 30)', [billId, itemId, aliceId, bobId, carolId]);
    // Call settle
    const res = await request(app).get(`/api/bills/${billId}/settle`);
    expect(res.statusCode).toBe(200);
    // Carol should owe Alice 20 and Bob 10
    const payments = res.body.payments;
    expect(payments.length).toBe(2);
    const carolToAlice = payments.find(p => p.from === carolId && p.to === aliceId);
    const carolToBob = payments.find(p => p.from === carolId && p.to === bobId);
    expect(Number(carolToAlice.amount)).toBe(20);
    expect(Number(carolToBob.amount)).toBe(10);
  });
});

afterAll(async () => {
    await pool.end();
});