require('dotenv').config({ path: '.env.test' });

const request = require('supertest');
const app = require('../src/app'); // Make sure app.js exports your Express app
const pool = require('../src/config/db'); // Import your pool
const User = require('../src/models/User');

describe('User Registration', () => {
  it('should register a new user', async () => {
    const res = await request(app)
      .post('/api/users/register')
      .send({
        email: 'testuser1@example.com',
        password: 'Test@1234',
        name: 'Test User 1',
        birthdate: '2000-01-01'
      });
    expect(res.statusCode).toBe(201);
    expect(res.body.message).toBe('User registered successfully.');
  });

  it('should not register with missing email', async () => {
    const res = await request(app)
      .post('/api/users/register')
      .send({
        password: 'Test@1234',
        name: 'Test User 2',
        birthdate: '2000-01-01'
      });
    expect(res.statusCode).toBe(400);
    expect(res.body.message).toMatch(/Email, password, name, and birthdate are required/);
  });

  it('should not register with missing password', async () => {
    const res = await request(app)
      .post('/api/users/register')
      .send({
        email: 'testuser2@example.com',
        name: 'Test User 2',
        birthdate: '2000-01-01'
      });
    expect(res.statusCode).toBe(400);
    expect(res.body.message).toMatch(/Email, password, name, and birthdate are required/);
  });

  it('should not register with missing name', async () => {
    const res = await request(app)
      .post('/api/users/register')
      .send({
        email: 'testuser3@example.com',
        password: 'Test@1234',
        birthdate: '2000-01-01'
      });
    expect(res.statusCode).toBe(400);
    expect(res.body.message).toMatch(/Email, password, name, and birthdate are required/);
  });

  it('should not register with missing birthdate', async () => {
    const res = await request(app)
      .post('/api/users/register')
      .send({
        email: 'testuser4@example.com',
        password: 'Test@1234',
        name: 'Test User 4'
      });
    expect(res.statusCode).toBe(400);
    expect(res.body.message).toMatch(/Email, password, name, and birthdate are required/);
  });

  it('should not register an underage user', async () => {
    const res = await request(app)
      .post('/api/users/register')
      .send({
        email: 'testuser5@example.com',
        password: 'Test@1234',
        name: 'Test User 5',
        birthdate: '2010-01-01'
      });
    expect(res.statusCode).toBe(400);
    expect(res.body.message).toMatch(/at least 18/);
  });

  it('should not register with a weak password', async () => {
    const res = await request(app)
      .post('/api/users/register')
      .send({
        email: 'testuser6@example.com',
        password: 'weakpass',
        name: 'Test User 6',
        birthdate: '2000-01-01'
      });
    expect(res.statusCode).toBe(400);
    expect(res.body.message).toMatch(/Password must be at least 8 characters/);
  });

  it('should not register with a duplicate email', async () => {
    // First registration
    await request(app)
      .post('/api/users/register')
      .send({
        email: 'testuser7@example.com',
        password: 'Test@1234',
        name: 'Test User 7',
        birthdate: '2000-01-01'
      });
    // Attempt duplicate registration
    const res = await request(app)
      .post('/api/users/register')
      .send({
        email: 'testuser7@example.com',
        password: 'Test@1234',
        name: 'Test User 7',
        birthdate: '2000-01-01'
      });
    expect(res.statusCode).toBe(409);
    expect(res.body.message).toMatch(/Email already taken/);
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
        name: 'Login User',
        birthdate: '2000-01-01'
      });
  });

  it('should login with correct credentials', async () => {
    const res = await request(app)
      .post('/api/users/login')
      .send({
        email: 'loginuser@example.com',
        password: 'Test@1234'
      });
    expect(res.statusCode).toBe(200);
    expect(res.body.message).toBe('Login successful.');
  });

  it('should not login with incorrect password', async () => {
    const res = await request(app)
      .post('/api/users/login')
      .send({
        email: 'loginuser@example.com',
        password: 'WrongPassword1'
      });
    expect(res.statusCode).toBe(401);
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
    expect(res.body.message).toMatch(/Invalid email or password/);
  });
});

afterEach(async () => {
  // Delete all users using the model
  await pool.query('DELETE FROM users');
});

afterAll(async () => {
  await pool.end(); // This closes the connection pool
}); 