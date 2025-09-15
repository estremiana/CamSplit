const User = require('../../src/models/User');
const pool = require('../../src/config/db');

describe('User Model', () => {
  let userId;
  const testUser = { 
    email: 'modeluser@example.com', 
    password: 'Test@1234', 
    first_name: 'Model', 
    last_name: 'User', 
    birthdate: '2000-01-01' 
  };

  afterEach(async () => {
    // Clean up in proper order to avoid foreign key constraints
    await pool.query('DELETE FROM user_preferences');
    await pool.query('DELETE FROM users');
  });

  afterAll(async () => {
    await pool.end();
  });

  it('should create a user', async () => {
    const user = await User.create(testUser);
    expect(user).toHaveProperty('id');
    expect(user).toHaveProperty('email', testUser.email);
    expect(user).toHaveProperty('first_name', testUser.first_name);
    expect(user).toHaveProperty('last_name', testUser.last_name);
    expect(user).toHaveProperty('preferences');
    userId = user.id;
  });

  it('should find a user by id', async () => {
    const created = await User.create(testUser);
    const found = await User.findById(created.id);
    expect(found).toHaveProperty('id', created.id);
    expect(found).toHaveProperty('email', testUser.email);
    expect(found).toHaveProperty('first_name', testUser.first_name);
    expect(found).toHaveProperty('preferences');
  });

  it('should find a user by email', async () => {
    const created = await User.create(testUser);
    const found = await User.findByEmail(testUser.email);
    expect(found).toHaveProperty('id', created.id);
    expect(found).toHaveProperty('email', testUser.email);
    expect(found).toHaveProperty('first_name', testUser.first_name);
  });

  it('should update a user', async () => {
    const created = await User.create(testUser);
    const user = await User.findById(created.id);
    const updated = await user.update({ first_name: 'Updated', last_name: 'Name' });
    expect(updated).toHaveProperty('first_name', 'Updated');
    expect(updated).toHaveProperty('last_name', 'Name');
  });

  it('should update a user password', async () => {
    const created = await User.create(testUser);
    const user = await User.findById(created.id);
    const result = await user.updatePassword('NewPass@123');
    expect(result).toBe(true);
  });

  it('should validate password', async () => {
    const created = await User.create(testUser);
    const authenticated = await User.authenticate(testUser.email, testUser.password);
    expect(authenticated).toHaveProperty('id', created.id);
    
    const notAuthenticated = await User.authenticate(testUser.email, 'WrongPass');
    expect(notAuthenticated).toBeNull();
  });

  it('should delete a user', async () => {
    // Note: User model doesn't have a delete method in the current implementation
    // This test would need to be implemented if delete functionality is added
    const created = await User.create(testUser);
    
    // Manual deletion for test cleanup
    await pool.query('DELETE FROM user_preferences WHERE user_id = $1', [created.id]);
    const result = await pool.query('DELETE FROM users WHERE id = $1 RETURNING *', [created.id]);
    expect(result.rows).toHaveLength(1);
    
    const found = await User.findById(created.id);
    expect(found).toBeNull();
  });
}); 