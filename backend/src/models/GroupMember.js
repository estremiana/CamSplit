const db = require('../../database/connection');

class GroupMember {
  constructor(data) {
    this.id = data.id;
    this.group_id = data.group_id;
    this.user_id = data.user_id;
    this.nickname = data.nickname;
    this.email = data.email;
    this.role = data.role;
    this.is_registered_user = data.is_registered_user;
    this.joined_at = data.joined_at;
  }

  // Create a new group member
  static async create(memberData) {
    const { group_id, user_id, nickname, email, role = 'member', is_registered_user = false } = memberData;

    // Validate input
    const validation = GroupMember.validate(memberData);
    if (!validation.isValid) {
      throw new Error(`Validation failed: ${validation.errors.join(', ')}`);
    }

    try {
      const query = `
        INSERT INTO group_members (group_id, user_id, nickname, email, role, is_registered_user, joined_at)
        VALUES ($1, $2, $3, $4, $5, $6, NOW())
        RETURNING *
      `;

      const values = [group_id, user_id, nickname, email, role, is_registered_user];
      const result = await db.query(query, values);

      return new GroupMember(result.rows[0]);
    } catch (error) {
      if (error.code === '23505') { // Unique constraint violation
        if (error.constraint === 'group_members_group_id_user_id_key') {
          throw new Error('User is already a member of this group');
        }
        if (error.constraint === 'group_members_group_id_nickname_key') {
          throw new Error('Nickname is already taken in this group');
        }
      }
      throw new Error(`Failed to create group member: ${error.message}`);
    }
  }

  // Find group member by ID
  static async findById(id) {
    try {
      const query = `
        SELECT gm.*, u.first_name, u.last_name, u.avatar, u.email as user_email
        FROM group_members gm
        LEFT JOIN users u ON gm.user_id = u.id
        WHERE gm.id = $1
      `;
      const result = await db.query(query, [id]);

      if (result.rows.length === 0) {
        return null;
      }

      const memberData = result.rows[0];
      const member = new GroupMember(memberData);
      
      // Add user info if available
      if (memberData.first_name) {
        member.user_name = `${memberData.first_name} ${memberData.last_name}`;
        member.user_avatar = memberData.avatar;
        member.user_email = memberData.user_email;
      }

      return member;
    } catch (error) {
      throw new Error(`Failed to find group member: ${error.message}`);
    }
  }

  // Find all members of a group
  static async findByGroupId(groupId) {
    try {
      const query = `
        SELECT gm.*, u.first_name, u.last_name, u.avatar, u.email as user_email
        FROM group_members gm
        LEFT JOIN users u ON gm.user_id = u.id
        WHERE gm.group_id = $1
        ORDER BY gm.joined_at ASC
      `;
      const result = await db.query(query, [groupId]);

      return result.rows.map(memberData => {
        const member = new GroupMember(memberData);
        
        // Add user info if available
        if (memberData.first_name) {
          member.user_name = `${memberData.first_name} ${memberData.last_name}`;
          member.user_avatar = memberData.avatar;
          member.user_email = memberData.user_email;
        }

        return member;
      });
    } catch (error) {
      throw new Error(`Failed to find group members: ${error.message}`);
    }
  }

  // Find member by user ID and group ID
  static async findByUserAndGroup(userId, groupId) {
    try {
      const query = `
        SELECT gm.*, u.first_name, u.last_name, u.avatar, u.email as user_email
        FROM group_members gm
        LEFT JOIN users u ON gm.user_id = u.id
        WHERE gm.user_id = $1 AND gm.group_id = $2
      `;
      const result = await db.query(query, [userId, groupId]);

      if (result.rows.length === 0) {
        return null;
      }

      const memberData = result.rows[0];
      const member = new GroupMember(memberData);
      
      // Add user info if available
      if (memberData.first_name) {
        member.user_name = `${memberData.first_name} ${memberData.last_name}`;
        member.user_avatar = memberData.avatar;
        member.user_email = memberData.user_email;
      }

      return member;
    } catch (error) {
      throw new Error(`Failed to find group member: ${error.message}`);
    }
  }

  // Update group member
  async update(updateData) {
    const { nickname, email, role } = updateData;

    // Validate input
    const validation = GroupMember.validateUpdate(updateData);
    if (!validation.isValid) {
      throw new Error(`Validation failed: ${validation.errors.join(', ')}`);
    }

    try {
      const query = `
        UPDATE group_members 
        SET nickname = COALESCE($1, nickname),
            email = COALESCE($2, email),
            role = COALESCE($3, role)
        WHERE id = $4
        RETURNING *
      `;

      const values = [nickname, email, role, this.id];
      const result = await db.query(query, values);

      if (result.rows.length === 0) {
        throw new Error('Group member not found');
      }

      // Update current instance
      Object.assign(this, result.rows[0]);
      return this;
    } catch (error) {
      if (error.code === '23505') { // Unique constraint violation
        if (error.constraint === 'group_members_group_id_nickname_key') {
          throw new Error('Nickname is already taken in this group');
        }
      }
      throw new Error(`Failed to update group member: ${error.message}`);
    }
  }

  // Delete group member
  async delete() {
    try {
      const query = 'DELETE FROM group_members WHERE id = $1 RETURNING *';
      const result = await db.query(query, [this.id]);

      if (result.rows.length === 0) {
        throw new Error('Group member not found');
      }

      return true;
    } catch (error) {
      throw new Error(`Failed to delete group member: ${error.message}`);
    }
  }

  // Check if member is admin
  isAdmin() {
    return this.role === 'admin';
  }

  // Check if member is registered user
  isRegisteredUser() {
    return this.is_registered_user && this.user_id;
  }

  // Get member's balance in the group
  async getBalance() {
    try {
      const query = `
        SELECT 
          COALESCE(SUM(CASE WHEN s.from_group_member_id = $1 THEN -s.amount ELSE 0 END), 0) +
          COALESCE(SUM(CASE WHEN s.to_group_member_id = $1 THEN s.amount ELSE 0 END), 0) as balance
        FROM settlements s
        WHERE (s.from_group_member_id = $1 OR s.to_group_member_id = $1) 
          AND s.status = 'active'
          AND s.group_id = $2
      `;

      const result = await db.query(query, [this.id, this.group_id]);
      return parseFloat(result.rows[0].balance) || 0;
    } catch (error) {
      throw new Error(`Failed to get member balance: ${error.message}`);
    }
  }

  // Get member's expenses in the group
  async getExpenses(limit = 10, offset = 0) {
    try {
      const query = `
        SELECT e.*, 
               COALESCE(ep.amount_paid, 0) as amount_paid,
               COALESCE(es.amount_owed, 0) as amount_owed
        FROM expenses e
        LEFT JOIN expense_payers ep ON e.id = ep.expense_id AND ep.group_member_id = $1
        LEFT JOIN expense_splits es ON e.id = es.expense_id AND es.group_member_id = $1
        WHERE e.group_id = $2
        ORDER BY e.created_at DESC
        LIMIT $3 OFFSET $4
      `;

      const result = await db.query(query, [this.id, this.group_id, limit, offset]);
      return result.rows;
    } catch (error) {
      throw new Error(`Failed to get member expenses: ${error.message}`);
    }
  }

  // Convert to JSON
  toJSON() {
    return {
      id: this.id,
      group_id: this.group_id,
      user_id: this.user_id,
      nickname: this.nickname,
      email: this.email,
      role: this.role,
      is_registered_user: this.is_registered_user,
      joined_at: this.joined_at,
      user_name: this.user_name,
      user_avatar: this.user_avatar,
      user_email: this.user_email
    };
  }

  // Static validation methods
  static validate(memberData) {
    const errors = [];
    const { group_id, nickname, email, role } = memberData;

    // Group ID validation
    if (!group_id || !Number.isInteger(group_id)) {
      errors.push('Valid group ID is required');
    }

    // Nickname validation
    if (!nickname || nickname.trim().length < 1) {
      errors.push('Nickname is required');
    } else if (nickname.length > 255) {
      errors.push('Nickname must be 255 characters or less');
    }

    // Email validation (optional)
    if (email && !GroupMember.isValidEmail(email)) {
      errors.push('Valid email format required');
    }

    // Role validation
    if (role && !['admin', 'member'].includes(role)) {
      errors.push('Role must be either "admin" or "member"');
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }

  static validateUpdate(updateData) {
    const errors = [];
    const { nickname, email, role } = updateData;

    // Nickname validation
    if (nickname !== undefined) {
      if (!nickname || nickname.trim().length < 1) {
        errors.push('Nickname cannot be empty');
      } else if (nickname.length > 255) {
        errors.push('Nickname must be 255 characters or less');
      }
    }

    // Email validation (optional)
    if (email && !GroupMember.isValidEmail(email)) {
      errors.push('Valid email format required');
    }

    // Role validation
    if (role && !['admin', 'member'].includes(role)) {
      errors.push('Role must be either "admin" or "member"');
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }

  // Helper validation methods
  static isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }
}

module.exports = GroupMember;