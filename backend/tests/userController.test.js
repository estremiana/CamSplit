const request = require('supertest');
const app = require('../src/app');
const UserService = require('../src/services/userService');
const path = require('path');

describe('UserController - Profile Image Upload', () => {
  let authToken;
  let testUserId;

  beforeAll(async () => {
    // Create a test user and get auth token
    const testUser = {
      first_name: 'Test',
      last_name: 'User',
      email: 'testuser@example.com',
      password: 'Test@1234'
    };

    const user = await UserService.register(testUser);
    testUserId = user.id;
    
    // Login to get auth token
    const loginResult = await UserService.login(testUser.email, testUser.password);
    authToken = loginResult.token;
  });

  afterAll(async () => {
    // Clean up test user
    try {
      await UserService.deleteAccount(testUserId, 'Test@1234');
    } catch (error) {
      console.warn('Failed to clean up test user:', error.message);
    }
  });

  describe('POST /users/profile/avatar', () => {
    it('should upload profile image successfully', async () => {
      const testImagePath = path.join(__dirname, 'fixtures', 'test-profile.jpg');
      
      const response = await request(app)
        .post('/users/profile/avatar')
        .set('Authorization', `Bearer ${authToken}`)
        .attach('avatar', testImagePath);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('avatar_url');
      expect(response.body.data).toHaveProperty('public_id');
      expect(response.body.message).toBe('Profile image uploaded successfully');
    });

    it('should reject request without image file', async () => {
      const response = await request(app)
        .post('/users/profile/avatar')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
      expect(response.body.message).toBe('No image file provided');
    });

    it('should reject invalid file types', async () => {
      const testTextPath = path.join(__dirname, 'fixtures', 'test.txt');
      
      const response = await request(app)
        .post('/users/profile/avatar')
        .set('Authorization', `Bearer ${authToken}`)
        .attach('avatar', testTextPath);

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Invalid file type');
    });

    it('should reject oversized files', async () => {
      // Create a large test file (6MB)
      const largeImagePath = path.join(__dirname, 'fixtures', 'large-image.jpg');
      
      const response = await request(app)
        .post('/users/profile/avatar')
        .set('Authorization', `Bearer ${authToken}`)
        .attach('avatar', largeImagePath);

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('File size too large');
    });

    it('should require authentication', async () => {
      const testImagePath = path.join(__dirname, 'fixtures', 'test-profile.jpg');
      
      const response = await request(app)
        .post('/users/profile/avatar')
        .attach('avatar', testImagePath);

      expect(response.status).toBe(401);
    });
  });

  describe('Profile image update flow', () => {
    it('should update user profile with new avatar URL', async () => {
      // First upload an image
      const testImagePath = path.join(__dirname, 'fixtures', 'test-profile.jpg');
      
      const uploadResponse = await request(app)
        .post('/users/profile/avatar')
        .set('Authorization', `Bearer ${authToken}`)
        .attach('avatar', testImagePath);

      expect(uploadResponse.status).toBe(200);
      const avatarUrl = uploadResponse.body.data.avatar_url;

      // Then verify the profile has been updated
      const profileResponse = await request(app)
        .get('/users/profile')
        .set('Authorization', `Bearer ${authToken}`);

      expect(profileResponse.status).toBe(200);
      expect(profileResponse.body.data.avatar).toBe(avatarUrl);
    });
  });
}); 