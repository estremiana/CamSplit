const db = require('../../database/connection');

class GroupInvite {
  // Create a new invite
  static async create(inviteData) {
    const { group_id, invite_code, created_by, expires_at, max_uses = 1 } = inviteData;
    
    const query = `
      INSERT INTO group_invites (group_id, invite_code, created_by, expires_at, max_uses)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING *
    `;
    
    const values = [group_id, invite_code, created_by, expires_at, max_uses];
    const result = await db.query(query, values);
    return result.rows[0];
  }

  // Find invite by code
  static async findByCode(inviteCode) {
    const query = `
      SELECT gi.*, g.name as group_name, g.description as group_description
      FROM group_invites gi
      JOIN groups g ON gi.group_id = g.id
      WHERE gi.invite_code = $1 AND gi.is_active = true
    `;
    
    const result = await db.query(query, [inviteCode]);
    return result.rows[0] || null;
  }

  // Find invite by ID
  static async findById(inviteId) {
    const query = `
      SELECT gi.*, g.name as group_name, g.description as group_description
      FROM group_invites gi
      JOIN groups g ON gi.group_id = g.id
      WHERE gi.id = $1
    `;
    
    const result = await db.query(query, [inviteId]);
    return result.rows[0] || null;
  }

  // Check if invite is valid
  static async isValid(inviteCode) {
    const invite = await this.findByCode(inviteCode);
    if (!invite) return false;

    // Check if expired
    if (invite.expires_at && new Date() > new Date(invite.expires_at)) {
      return false;
    }

    // Check if usage limit exceeded
    if (invite.current_uses >= invite.max_uses) {
      return false;
    }

    return true;
  }

  // Increment usage count
  static async incrementUsage(inviteCode) {
    const query = `
      UPDATE group_invites 
      SET current_uses = current_uses + 1
      WHERE invite_code = $1
      RETURNING *
    `;
    
    const result = await db.query(query, [inviteCode]);
    return result.rows[0];
  }

  // Get all invites for a group
  static async getByGroupId(groupId) {
    const query = `
      SELECT gi.*, u.first_name, u.last_name, u.email as creator_email
      FROM group_invites gi
      JOIN users u ON gi.created_by = u.id
      WHERE gi.group_id = $1
      ORDER BY gi.created_at DESC
    `;
    
    const result = await db.query(query, [groupId]);
    return result.rows;
  }

  // Deactivate invite
  static async deactivate(inviteId) {
    const query = `
      UPDATE group_invites 
      SET is_active = false
      WHERE id = $1
      RETURNING *
    `;
    
    const result = await db.query(query, [inviteId]);
    return result.rows[0];
  }

  // Delete invite
  static async delete(inviteId) {
    const query = 'DELETE FROM group_invites WHERE id = $1 RETURNING *';
    const result = await db.query(query, [inviteId]);
    return result.rows[0];
  }

  // Generate unique invite code
  static generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let result = '';
    for (let i = 0; i < 12; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return result;
  }

  // Get available members for claiming (members without user_id)
  static async getAvailableMembers(groupId) {
    const query = `
      SELECT id, nickname, email, joined_at
      FROM group_members
      WHERE group_id = $1 AND user_id IS NULL
      ORDER BY joined_at ASC
    `;
    
    const result = await db.query(query, [groupId]);
    return result.rows;
  }
}

module.exports = GroupInvite; 