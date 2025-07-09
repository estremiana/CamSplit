const Assignment = require('../../src/models/Assignment');
const Bill = require('../../src/models/Bill');
const Item = require('../../src/models/Item');
const Participant = require('../../src/models/Participant');
const pool = require('../../src/config/db');

describe('Assignment Model', () => {
  let billId, itemId, participantId;
  beforeAll(async () => {
    const res = await pool.query(`INSERT INTO users (email, password, name, birthdate) VALUES ('assignmodeluser@example.com', 'hash', 'Assign Model', '2000-01-01') RETURNING id`);
    const userId = res.rows[0].id;
    const bill = await Bill.create({ user_id: userId, image_url: 'testurl' });
    billId = bill.id;
    const item = await Item.create({ bill_id: billId, name: 'Pizza', unit_price: 10, total_price: 20, quantity: 2, quantity_left: 2 });
    itemId = item.id;
    const participant = await Participant.create({ bill_id: billId, name: 'Alice' });
    participantId = participant.id;
  });

  afterEach(async () => {
    await pool.query('DELETE FROM assignments');
  });

  afterAll(async () => {
    await pool.query('DELETE FROM participants');
    await pool.query('DELETE FROM items');
    await pool.query('DELETE FROM bills');
    await pool.query('DELETE FROM users');
    await pool.end();
  });

  it('should create an assignment', async () => {
    const assignment = await Assignment.create({ bill_id: billId, item_id: itemId, participant_id: participantId, quantity: 1, cost_per_person: 10 });
    expect(assignment).toHaveProperty('id');
    expect(assignment).toHaveProperty('bill_id', billId);
    expect(assignment).toHaveProperty('item_id', itemId);
    expect(assignment).toHaveProperty('participant_id', participantId);
  });

  it('should find an assignment by id', async () => {
    const created = await Assignment.create({ bill_id: billId, item_id: itemId, participant_id: participantId, quantity: 1, cost_per_person: 10 });
    const found = await Assignment.findById(created.id);
    expect(found).toHaveProperty('id', created.id);
  });

  it('should find assignments by bill id', async () => {
    await Assignment.create({ bill_id: billId, item_id: itemId, participant_id: participantId, quantity: 1, cost_per_person: 10 });
    const assignments = await Assignment.findByBillId(billId);
    expect(Array.isArray(assignments)).toBe(true);
    expect(assignments.length).toBeGreaterThanOrEqual(1);
  });

  it('should find assignments by item id', async () => {
    await Assignment.create({ bill_id: billId, item_id: itemId, participant_id: participantId, quantity: 1, cost_per_person: 10 });
    const assignments = await Assignment.findByItemId(itemId);
    expect(Array.isArray(assignments)).toBe(true);
    expect(assignments.length).toBeGreaterThanOrEqual(1);
  });

  it('should update an assignment', async () => {
    const created = await Assignment.create({ bill_id: billId, item_id: itemId, participant_id: participantId, quantity: 1, cost_per_person: 10 });
    const updated = await Assignment.update(created.id, { quantity: 2, cost_per_person: 20 });
    expect(updated).toHaveProperty('quantity', 2);
    expect(Number(updated.cost_per_person)).toBe(20);
  });

  it('should upsert an assignment', async () => {
    const upserted = await Assignment.upsert({ bill_id: billId, item_id: itemId, participant_id: participantId, quantity: 1, cost_per_person: 10 });
    expect(upserted).toHaveProperty('bill_id', billId);
    expect(upserted).toHaveProperty('item_id', itemId);
    expect(upserted).toHaveProperty('participant_id', participantId);
  });

  it('should bulk upsert assignments', async () => {
    const assignments = [
      { bill_id: billId, item_id: itemId, participant_id: participantId, quantity: 1, cost_per_person: 10 },
      { bill_id: billId, item_id: itemId, participant_id: participantId, quantity: 2, cost_per_person: 20 }
    ];
    const results = await Assignment.bulkUpsert(assignments);
    expect(Array.isArray(results)).toBe(true);
    expect(results.length).toBe(assignments.length);
  });

  it('should get assignment summary', async () => {
    await Assignment.create({ bill_id: billId, item_id: itemId, participant_id: participantId, quantity: 1, cost_per_person: 10 });
    const summary = await Assignment.getAssignmentSummary(billId);
    expect(Array.isArray(summary)).toBe(true);
  });

  it('should delete an assignment', async () => {
    const created = await Assignment.create({ bill_id: billId, item_id: itemId, participant_id: participantId, quantity: 1, cost_per_person: 10 });
    const deleted = await Assignment.delete(created.id);
    expect(deleted).toHaveProperty('id', created.id);
    const found = await Assignment.findById(created.id);
    expect(found).toBeNull();
  });

  it('should delete assignments by bill id', async () => {
    await Assignment.create({ bill_id: billId, item_id: itemId, participant_id: participantId, quantity: 1, cost_per_person: 10 });
    const deleted = await Assignment.deleteByBillId(billId);
    expect(Array.isArray(deleted)).toBe(true);
  });
}); 