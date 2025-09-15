const request = require('supertest');
const app = require('../src/app');
const db = require('../database/connection');
const Group = require('../src/models/Group');
const User = require('../src/models/User');

describe('Group Management API', () => {
  let testUser, testGroup, authToken;

  beforeAll(async () => {
    // Create test user
    testUser = await User.create({
      first_name: 'Test',
      last_name: 'User',
      email: 'test@example.com',
      password: 'Test@1234'
    });

    // Create test group
    testGroup = await Group.create({
      name: 'Test Group',
      description: 'Test group for management',
      currency: 'EUR'
    }, testUser.id);

    // Get auth token
    const loginResponse = await request(app)
      .post('/api/auth/login')
      .send({
        email: 'test@example.com',
        password: 'Test@1234'
      });

    authToken = loginResponse.body.data.token;
  });

  afterAll(async () => {
    // Clean up test data
    await db.query('DELETE FROM group_members WHERE group_id = $1', [testGroup.id]);
    await db.query('DELETE FROM groups WHERE id = $1', [testGroup.id]);
    await db.query('DELETE FROM users WHERE id = $1', [testUser.id]);
    await db.end();
  });

  describe('DELETE /api/groups/:groupId/cascade', () => {
    it('should delete group with all related data', async () => {
      const response = await request(app)
        .delete(`/api/groups/${testGroup.id}/cascade`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.message).toContain('deleted successfully');

      // Verify group is actually deleted
      const groupCheck = await Group.findById(testGroup.id);
      expect(groupCheck).toBeNull();
    });

    it('should return 403 if user is not admin', async () => {
      // Create another user who is not admin
      const otherUser = await User.create({
        first_name: 'Other',
        last_name: 'User',
        email: 'other@example.com',
        password: 'Test@1234'
      });

      const otherLoginResponse = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'other@example.com',
          password: 'Test@1234'
        });

      const otherAuthToken = otherLoginResponse.body.data.token;

      const response = await request(app)
        .delete(`/api/groups/${testGroup.id}/cascade`)
        .set('Authorization', `Bearer ${otherAuthToken}`);

      expect(response.status).toBe(403);
      expect(response.body.success).toBe(false);

      // Clean up
      await db.query('DELETE FROM users WHERE id = $1', [otherUser.id]);
    });
  });

  describe('POST /api/groups/:groupId/exit', () => {
    it('should allow user to exit group', async () => {
      // Create a new group for exit testing
      const exitTestGroup = await Group.create({
        name: 'Exit Test Group',
        description: 'Test group for exit functionality',
        currency: 'EUR'
      }, testUser.id);

      const response = await request(app)
        .post(`/api/groups/${exitTestGroup.id}/exit`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.action).toBe('group_deleted');

      // Verify group is deleted since user was the only member
      const groupCheck = await Group.findById(exitTestGroup.id);
      expect(groupCheck).toBeNull();
    });

    it('should delete group when last user exits (even if admin)', async () => {
      // Create a group with only one member (who is admin)
      const lastUserGroup = await Group.create({
        name: 'Last User Group',
        description: 'Test group for last user exit',
        currency: 'EUR'
      }, testUser.id);

      const response = await request(app)
        .post(`/api/groups/${lastUserGroup.id}/exit`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.action).toBe('group_deleted');

      // Verify group is deleted
      const groupCheck = await Group.findById(lastUserGroup.id);
      expect(groupCheck).toBeNull();
    });

    it('should prevent last admin from exiting when other users exist', async () => {
      // Create a group with multiple users
      const multiUserGroup = await Group.create({
        name: 'Multi User Group',
        description: 'Test group with multiple users',
        currency: 'EUR'
      }, testUser.id);

      // Add another user to the group
      const otherUser = await User.create({
        first_name: 'Other',
        last_name: 'User',
        email: 'other2@example.com',
        password: 'Test@1234'
      });

      await multiUserGroup.addMember({
        user_id: otherUser.id,
        nickname: 'Other User',
        email: 'other2@example.com',
        role: 'member'
      });

      // Try to exit as admin (should fail)
      const response = await request(app)
        .post(`/api/groups/${multiUserGroup.id}/exit`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('only admin');

      // Clean up
      await db.query('DELETE FROM group_members WHERE group_id = $1', [multiUserGroup.id]);
      await db.query('DELETE FROM groups WHERE id = $1', [multiUserGroup.id]);
      await db.query('DELETE FROM users WHERE id = $1', [otherUser.id]);
    });

    it('should return proper response structure for exit group', async () => {
      // Create a group with multiple users
      const multiUserGroup = await Group.create({
        name: 'Multi User Group Response Test',
        description: 'Test group for response structure',
        currency: 'EUR'
      }, testUser.id);

      // Add another user to the group
      const otherUser = await User.create({
        first_name: 'Other',
        last_name: 'User',
        email: 'other3@example.com',
        password: 'Test@1234'
      });

      await multiUserGroup.addMember({
        user_id: otherUser.id,
        nickname: 'Other User',
        email: 'other3@example.com',
        role: 'member'
      });

      // Exit as regular member (should succeed)
      const response = await request(app)
        .post(`/api/groups/${multiUserGroup.id}/exit`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.message).toBe('Successfully exited the group');
      expect(response.body.data.action).toBe('user_exited');

      // Clean up
      await db.query('DELETE FROM group_members WHERE group_id = $1', [multiUserGroup.id]);
      await db.query('DELETE FROM groups WHERE id = $1', [multiUserGroup.id]);
      await db.query('DELETE FROM users WHERE id = $1', [otherUser.id]);
    });
  });

  describe('GET /api/groups/:groupId/auto-delete-status', () => {
    it('should return auto-delete status', async () => {
      // Create a test group
      const autoDeleteGroup = await Group.create({
        name: 'Auto Delete Test Group',
        description: 'Test group for auto-delete status',
        currency: 'EUR'
      }, testUser.id);

      const response = await request(app)
        .get(`/api/groups/${autoDeleteGroup.id}/auto-delete-status`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.shouldAutoDelete).toBe(false);

      // Clean up
      await db.query('DELETE FROM group_members WHERE group_id = $1', [autoDeleteGroup.id]);
      await db.query('DELETE FROM groups WHERE id = $1', [autoDeleteGroup.id]);
    });
  });
}); 