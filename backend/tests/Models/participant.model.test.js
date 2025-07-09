const Participant = require('../../src/models/Participant');
const Bill = require('../../src/models/Bill');
const pool = require('../../src/config/db');

describe('Participant Model', () => {
  let billId;
  beforeAll(async () => {
    const res = await pool.query(`INSERT INTO users (email, password, name, birthdate) VALUES ('partmodeluser@example.com', 'hash', 'Part Model', '2000-01-01') RETURNING id`);
    const userId = res.rows[0].id;
    const bill = await Bill.create({ user_id: userId, image_url: 'testurl' });
    billId = bill.id;
  });
  afterAll(async () => {
    await pool.query('DELETE FROM participants');
    await pool.query('DELETE FROM bills');
    await pool.query('DELETE FROM users');
    await pool.end();
  });

  it('should create a participant', async () => {
    const participant = await Participant.create({ bill_id: billId, name: 'Alice' });
    expect(participant).toHaveProperty('id');
    expect(participant).toHaveProperty('bill_id', billId);
    expect(participant).toHaveProperty('name', 'Alice');
  });

  it('should find a participant by id', async () => {
    const created = await Participant.create({ bill_id: billId, name: 'Alice' });
    const found = await Participant.findById(created.id);
    expect(found).toHaveProperty('id', created.id);
  });

  it('should find participants by bill id', async () => {
    await Participant.create({ bill_id: billId, name: 'Alice' });
    await Participant.create({ bill_id: billId, name: 'Bob' });
    const participants = await Participant.findByBillId(billId);
    expect(Array.isArray(participants)).toBe(true);
    expect(participants.length).toBeGreaterThanOrEqual(2);
  });

  it('should update a participant', async () => {
    const created = await Participant.create({ bill_id: billId, name: 'Alice' });
    const updated = await Participant.update(created.id, { name: 'Alicia', user_id: null });
    expect(updated).toHaveProperty('name', 'Alicia');
  });

  it('should set amount_paid and amount_owed', async () => {
    const created = await Participant.create({ bill_id: billId, name: 'Alice' });
    const paid = await Participant.setamount_paid(created.id, 50);
    expect(Number(paid.amount_paid)).toBe(50);
    const owed = await Participant.setamount_owed(created.id, 30);
    expect(Number(owed.amount_owed)).toBe(30);
  });

  it('should delete a participant', async () => {
    const created = await Participant.create({ bill_id: billId, name: 'Alice' });
    const deleted = await Participant.delete(created.id);
    expect(deleted).toHaveProperty('id', created.id);
    const found = await Participant.findById(created.id);
    expect(found).toBeNull();
  });
}); 