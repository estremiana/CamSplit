const User = require('../../src/models/User');
const pool = require('../../src/config/db');

describe('User Model', () => {
  let userId;
  const testUser = { email: 'modeluser@example.com', password: 'Test@1234', name: 'Model User', birthdate: '2000-01-01' };

  afterEach(async () => {
    await pool.query('DELETE FROM users');
  });

  afterAll(async () => {
    await pool.end();
  });

  it('should create a user', async () => {
    const user = await User.create(testUser);
    expect(user).toHaveProperty('id');
    expect(user).toHaveProperty('email', testUser.email);
    expect(user).toHaveProperty('name', testUser.name);
    userId = user.id;
  });

  it('should find a user by id', async () => {
    const created = await User.create(testUser);
    const found = await User.findById(created.id);
    expect(found).toHaveProperty('id', created.id);
    expect(found).toHaveProperty('email', testUser.email);
  });

  it('should find a user by email', async () => {
    const created = await User.create(testUser);
    const found = await User.findByEmail(testUser.email);
    expect(found).toHaveProperty('id', created.id);
    expect(found).toHaveProperty('email', testUser.email);
  });

  it('should update a user', async () => {
    const created = await User.create(testUser);
    const updated = await User.update(created.id, { email: 'new@example.com', name: 'New Name' });
    expect(updated).toHaveProperty('email', 'new@example.com');
    expect(updated).toHaveProperty('name', 'New Name');
  });

  it('should update a user password', async () => {
    const created = await User.create(testUser);
    const updated = await User.updatePassword(created.id, 'NewPass@123');
    expect(updated).toHaveProperty('id', created.id);
  });

  it('should validate password', async () => {
    const created = await User.create(testUser);
    const found = await User.findByEmail(testUser.email);
    const valid = await User.validatePassword(found, testUser.password);
    expect(valid).toBe(true);
    const invalid = await User.validatePassword(found, 'WrongPass');
    expect(invalid).toBe(false);
  });

  it('should delete a user', async () => {
    const created = await User.create(testUser);
    const deleted = await User.delete(created.id);
    expect(deleted).toHaveProperty('id', created.id);
    const found = await User.findById(created.id);
    expect(found).toBeNull();
  });
}); 