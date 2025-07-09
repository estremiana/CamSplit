require('dotenv').config({ path: '.env.test' });

const request = require('supertest');
const app = require('../src/app');
const pool = require('../src/config/db');
const Assignment = require('../src/models/Assignment');
const Item = require('../src/models/Item');
const Bill = require('../src/models/Bill');
const Participant = require('../src/models/Participant');

describe('Assignments', () => {
  let billId, itemId1, itemId2, participantId1, participantId2;

  beforeEach(async () => {
    // Create a user, bill, items, and participants
    const userRes = await pool.query(
      `INSERT INTO users (email, password, name, birthdate) VALUES ('assignuser@example.com', 'hash', 'Assign User', '2000-01-01') RETURNING id`
    );
    const userId = userRes.rows[0].id;
    const billRes = await pool.query(
      `INSERT INTO bills (user_id, image_url) VALUES ($1, 'testurl') RETURNING id`, [userId]
    );
    billId = billRes.rows[0].id;
    const itemRes1 = await pool.query(
      `INSERT INTO items (bill_id, name, unit_price, total_price, quantity, quantity_left) VALUES ($1, 'Pizza', 10, 20, 2, 2) RETURNING id`, [billId]
    );
    itemId1 = itemRes1.rows[0].id;
    const itemRes2 = await pool.query(
      `INSERT INTO items (bill_id, name, unit_price, total_price, quantity, quantity_left) VALUES ($1, 'Beer', 5, 15, 3, 3) RETURNING id`, [billId]
    );
    itemId2 = itemRes2.rows[0].id;
    const partRes1 = await pool.query(
      `INSERT INTO participants (bill_id, name) VALUES ($1, 'Alice') RETURNING id`, [billId]
    );
    participantId1 = partRes1.rows[0].id;
    const partRes2 = await pool.query(
      `INSERT INTO participants (bill_id, name) VALUES ($1, 'Bob') RETURNING id`, [billId]
    );
    participantId2 = partRes2.rows[0].id;
  });

  afterEach(async () => {
    await pool.query('DELETE FROM assignments');
    await pool.query('DELETE FROM participants');
    await pool.query('DELETE FROM items');
    await pool.query('DELETE FROM bills');
    await pool.query('DELETE FROM users');
  });

  afterAll(async () => {
    await pool.end();
  });

  it('should assign multiple items to multiple participants and split cost', async () => {
    const res = await request(app)
      .post('/api/assignments')
      .send({
        items: [
          { itemId: itemId1, quantity: 2 },
          { itemId: itemId2, quantity: 2 }
        ],
        participantIds: [participantId1, participantId2]
      });
    expect(res.statusCode).toBe(201);
    expect(res.body.assignments.length).toBe(4); // 2 items x 2 participants
    // Each assignment should have correct cost
    const pizzaAssignments = res.body.assignments.filter(a => a.item_id === itemId1);
    pizzaAssignments.forEach(a => expect(Number(a.cost_per_person)).toBe(10)); // (10*2)/2 = 10
    const beerAssignments = res.body.assignments.filter(a => a.item_id === itemId2);
    beerAssignments.forEach(a => expect(Number(a.cost_per_person)).toBe(5)); // (5*2)/2 = 5
  });

  it('should not assign if not enough quantity left', async () => {
    // Assign all pizza first
    await request(app)
      .post('/api/assignments')
      .send({
        items: [{ itemId: itemId1, quantity: 2 }],
        participantIds: [participantId1, participantId2]
      });
    // Try to assign more pizza
    const res = await request(app)
      .post('/api/assignments')
      .send({
        items: [{ itemId: itemId1, quantity: 1 }],
        participantIds: [participantId1]
      });
    expect(res.statusCode).toBe(400);
    expect(res.body.message).toMatch(/Not enough quantity left/);
  });

  it('should not assign with invalid item or participant', async () => {
    const res = await request(app)
      .post('/api/assignments')
      .send({
        items: [{ itemId: 9999, quantity: 1 }],
        participantIds: [participantId1]
      });
    expect(res.statusCode).toBe(404);
    expect(res.body.message).toMatch(/Item with id 9999 not found/);
  });

  it('should fetch all assignments for a bill', async () => {
    // Assign some items
    await request(app)
      .post('/api/assignments')
      .send({
        items: [
          { itemId: itemId1, quantity: 2 },
          { itemId: itemId2, quantity: 2 }
        ],
        participantIds: [participantId1, participantId2]
      });
    const res = await request(app)
      .get(`/api/assignments/bill/${billId}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.assignments.length).toBe(4); // 2 items x 2 participants
    const assignment = res.body.assignments[0];
    expect(assignment).toHaveProperty('item_id');
    expect(assignment).toHaveProperty('participant_id');
    expect(assignment).toHaveProperty('quantity');
    expect(assignment).toHaveProperty('cost_per_person');
    expect(assignment).toHaveProperty('item_name');
    expect(assignment).toHaveProperty('participant_name');
  });

  it('should return empty array if no assignments for bill', async () => {
    const res = await request(app)
      .get(`/api/assignments/bill/${billId}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.assignments).toEqual([]);
  });

  // it('should increment assignment for the same item and participant', async () => {
  //   // Assign 1 pizza to Alice
  //   await request(app)
  //     .post('/api/assignments')
  //     .send({
  //       items: [{ itemId: itemId1, quantity: 1 }],
  //       participantIds: [participantId1]
  //     });
  //   // Assign 1 more pizza to Alice
  //   await request(app)
  //     .post('/api/assignments')
  //     .send({
  //       items: [{ itemId: itemId1, quantity: 1 }],
  //       participantIds: [participantId1]
  //     });
  //   // Fetch assignments for the bill
  //   const res = await request(app)
  //     .get(`/api/assignments/bill/${billId}`);
  //   expect(res.statusCode).toBe(200);
  //   // There should be only one assignment for Alice and pizza
  //   const alicePizza = res.body.assignments.find(a => a.item_id === itemId1 && a.participant_id === participantId1);
  //   expect(alicePizza).toBeDefined();
  //   expect(alicePizza.quantity).toBe(1);
  //   expect(Number(alicePizza.cost_per_person)).toBe(20); // 10 per pizza, 2 pizzas
  // });
}); 