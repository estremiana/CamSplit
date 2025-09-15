require('dotenv').config({ path: '.env.test' });

const request = require('supertest');
const app = require('../src/app');
const TestHelpers = require('./helpers/testHelpers');

describe('User Registration', () => {
  afterEach(async () => {
    await TestHelpers.cleanupTestData();
  });

  it('should register a new user', async () => {
    const res = await request(app)
      .post('/api/users/register')
      .send({
        email: 'testuser1@example.com',
        password: 'Test@1234',
        first_name: 'Test',
        last_name: 'User 1',
        birthdate: '2000-01-01'
      });
    expect(res.statusCode).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveProperty('user');
    expect(res.body.data).toHaveProperty('token');
    expect(res.body.data.user).toHaveProperty('email', 'testuser1@example.com');
    expect(res.body.data.user).toHaveProperty('first_name', 'Test');
    expect(res.body.data.user).toHaveProperty('last_name', 'User 1');
  });

  it('should not register with missing email', async () => {
    const res = await request(app)
      .post('/api/users/register')
      .send({
        password: 'Test@1234',
        first_name: 'Test',
        last_name: 'User 2',
        birthdate: '2000-01-01'
      });
    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toMatch(/Email, password, first name, and last name are required/);
  });

  it('should not register with missing password', async () => {
    const res = await request(app)
      .post('/api/users/register')
      .send({
        email: 'testuser2@example.com',
        first_name: 'Test',
        last_name: 'User 2',
        birthdate: '2000-01-01'
      });
    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toMatch(/Email, password, first name, and last name are required/);
  });

  it('should not register with missing first name', async () => {
    const res = await request(app)
      .post('/api/users/register')
      .send({
        email: 'testuser3@example.com',
        password: 'Test@1234',
        last_name: 'User 3',
        birthdate: '2000-01-01'
      });
    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toMatch(/Email, password, first name, and last name are required/);
  });

  it('should not register with missing last name', async () => {
    const res = await request(app)
      .post('/api/users/register')
      .send({
        email: 'testuser4@example.com',
        password: 'Test@1234',
        first_name: 'Test',
        birthdate: '2000-01-01'
      });
    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toMatch(/Email, password, first name, and last name are required/);
  });

  it('should not register with a weak password', async () => {
    const res = await request(app)
      .post('/api/users/register')
      .send({
        email: 'testuser6@example.com',
        password: 'weakpass',
        first_name: 'Test',
        last_name: 'User 6',
        birthdate: '2000-01-01'
      });
    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toMatch(/Password must be at least 8 characters/);
  });

  it('should not register with a duplicate email', async () => {
    // First registration
    await request(app)
      .post('/api/users/register')
      .send({
        email: 'testuser7@example.com',
        password: 'Test@1234',
        first_name: 'Test',
        last_name: 'User 7',
        birthdate: '2000-01-01'
      });
    
    // Attempt duplicate registration
    const res = await request(app)
      .post('/api/users/register')
      .send({
        email: 'testuser7@example.com',
        password: 'Test@1234',
        first_name: 'Test',
        last_name: 'User 7',
        birthdate: '2000-01-01'
      });
    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toMatch(/already exists/);
  });
});

describe('User Login', () => {
  beforeEach(async () => {
    // Register a user for login tests
    await request(app)
      .post('/api/users/register')
      .send({
        email: 'loginuser@example.com',
        password: 'Test@1234',
        first_name: 'Login',
        last_name: 'User',
        birthdate: '2000-01-01'
      });
  });

  afterEach(async () => {
    await TestHelpers.cleanupTestData();
  });

  it('should login with correct credentials', async () => {
    const res = await request(app)
      .post('/api/users/login')
      .send({
        email: 'loginuser@example.com',
        password: 'Test@1234'
      });
    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveProperty('user');
    expect(res.body.data).toHaveProperty('token');
    expect(res.body.data.user).toHaveProperty('email', 'loginuser@example.com');
    expect(TestHelpers.isValidJWT(res.body.data.token)).toBe(true);
  });

  it('should not login with incorrect password', async () => {
    const res = await request(app)
      .post('/api/users/login')
      .send({
        email: 'loginuser@example.com',
        password: 'WrongPassword1'
      });
    expect(res.statusCode).toBe(401);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toMatch(/Invalid email or password/);
  });

  it('should not login with non-existent email', async () => {
    const res = await request(app)
      .post('/api/users/login')
      .send({
        email: 'nonexistent@example.com',
        password: 'Test@1234'
      });
    expect(res.statusCode).toBe(401);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toMatch(/Invalid email or password/);
  });
});

describe('User Profile', () => {
  let userToken;
  let userId;

  beforeEach(async () => {
    const { user, token } = await TestHelpers.createTestUser({
      email: 'profileuser@example.com',
      first_name: 'Profile',
      last_name: 'User'
    });
    userToken = token;
    userId = user.id;
  });

  afterEach(async () => {
    await TestHelpers.cleanupTestData();
  });

  it('should get user profile with valid token', async () => {
    const res = await request(app)
      .get('/api/users/profile')
      .set('Authorization', `Bearer ${userToken}`);
    
    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveProperty('id', userId);
    expect(res.body.data).toHaveProperty('email', 'profileuser@example.com');
    expect(res.body.data).toHaveProperty('first_name', 'Profile');
    expect(res.body.data).toHaveProperty('last_name', 'User');
  });

  it('should not get profile without token', async () => {
    const res = await request(app)
      .get('/api/users/profile');
    
    expect(res.statusCode).toBe(401);
    expect(res.body.success).toBe(false);
  });

  it('should update user profile', async () => {
    const res = await request(app)
      .put('/api/users/profile')
      .set('Authorization', `Bearer ${userToken}`)
      .send({
        first_name: 'Updated',
        last_name: 'Name',
        bio: 'Updated bio'
      });
    
    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveProperty('first_name', 'Updated');
    expect(res.body.data).toHaveProperty('last_name', 'Name');
    expect(res.body.data).toHaveProperty('bio', 'Updated bio');
  });
});

afterAll(async () => {
  const pool = require('../src/config/db');
  await pool.end();
}); 