const db = require('../../database/connection');

class Group {
  constructor(data) {
    this.id = data.id;
    this.name = data.name;
    this.description = data.description;
    this.image_url = data.image_url;
    this.created_by = data.created_by;
    this.currency = data.currency;
    this.created_at = data.created_at;
    this.updated_at = data.updated_at;
    // Include member_count if provided (from getGroupsForUser query)
    this.member_count = data.member_count;
  }

  // Create a new group
  static async create(groupData, creatorId) {
    const { name, description, image_url, currency } = groupData;

    // Validate input
    const validation = Group.validate(groupData);
    if (!validation.isValid) {
      throw new Error(`Validation failed: ${validation.errors.join(', ')}`);
    }

    try {
      // Start transaction
      const client = await db.pool.connect();
      await client.query('BEGIN');

      try {
        // Create group
        const groupQuery = `
          INSERT INTO groups (name, description, image_url, created_by, currency, created_at, updated_at)
          VALUES ($1, $2, $3, $4, $5, NOW(), NOW())
          RETURNING *
        `;
        
        const groupValues = [name, description, image_url, creatorId, currency || 'EUR'];
        const groupResult = await client.query(groupQuery, groupValues);
        const group = new Group(groupResult.rows[0]);

        // Add creator as admin member
        const memberQuery = `
          INSERT INTO group_members (group_id, user_id, nickname, email, role, is_registered_user, joined_at)
          VALUES ($1, $2, $3, $4, $5, $6, NOW())
          RETURNING *
        `;

        // Get creator's info
        const userQuery = 'SELECT first_name, last_name, email FROM users WHERE id = $1';
        const userResult = await client.query(userQuery, [creatorId]);
        const creator = userResult.rows[0];
        creator.name = `${creator.first_name} ${creator.last_name}`.trim();

        const memberValues = [
          group.id,
          creatorId,
          creator.name,
          creator.email,
          'admin',
          true
        ];

        await client.query(memberQuery, memberValues);
        await client.query('COMMIT');

        return group;
      } catch (error) {
        await client.query('ROLLBACK');
        throw error;
      } finally {
        client.release();
      }
    } catch (error) {
      throw new Error(`Failed to create group: ${error.message}`);
    }
  }

  // Find group by ID
  static async findById(id) {
    try {
      const query = 'SELECT * FROM groups WHERE id = $1';
      const result = await db.query(query, [id]);
      if (result.rows.length === 0) {
        return null;
      }
      return new Group(result.rows[0]);
    } catch (error) {
      throw new Error(`Failed to find group: ${error.message}`);
    }
  }

  // Get group with members
  static async findByIdWithMembers(id) {
    try {
      const groupQuery = 'SELECT * FROM groups WHERE id = $1';
      const groupResult = await db.query(groupQuery, [id]);
      
      if (groupResult.rows.length === 0) {
        return null;
      }
      
      const group = new Group(groupResult.rows[0]);
      const members = await group.getMembers();
      
      return {
        ...group.toJSON(),
        members
      };
    } catch (error) {
      throw new Error(`Failed to find group with members: ${error.message}`);
    }
  }

  // Get groups for a user
  static async getGroupsForUser(userId) {
    try {
      const query = `
        SELECT 
          g.*,
          gm.role,
          gm.joined_at,
          COALESCE(member_counts.member_count, 0) as member_count
        FROM groups g
        JOIN group_members gm ON g.id = gm.group_id
        LEFT JOIN (
          SELECT group_id, COUNT(*) as member_count
          FROM group_members 
          GROUP BY group_id
        ) member_counts ON g.id = member_counts.group_id
        WHERE gm.user_id = $1
        ORDER BY g.updated_at DESC
      `;
      
      const result = await db.query(query, [userId]);
      return result.rows.map(row => new Group(row));
    } catch (error) {
      throw new Error(`Failed to get groups for user: ${error.message}`);
    }
  }

  // Update group
  async update(updateData) {
    const { name, description, image_url, currency } = updateData;
    
    // Validate input
    const validation = Group.validate(updateData);
    if (!validation.isValid) {
      throw new Error(`Validation failed: ${validation.errors.join(', ')}`);
    }

    try {
      const query = `
        UPDATE groups 
        SET name = COALESCE($1, name),
            description = COALESCE($2, description),
            image_url = COALESCE($3, image_url),
            currency = COALESCE($4, currency),
            updated_at = NOW()
        WHERE id = $5
        RETURNING *
      `;
      
      const values = [name, description, image_url, currency, this.id];
      const result = await db.query(query, values);
      
      if (result.rows.length === 0) {
        throw new Error('Group not found');
      }
      
      // Update current instance
      Object.assign(this, result.rows[0]);
      return this;
    } catch (error) {
      throw new Error(`Failed to update group: ${error.message}`);
    }
  }

  // Delete group
  async delete() {
    try {
      const query = 'DELETE FROM groups WHERE id = $1 RETURNING *';
      const result = await db.query(query, [this.id]);
      
      if (result.rows.length === 0) {
        throw new Error('Group not found');
      }
      
      return true;
    } catch (error) {
      throw new Error(`Failed to delete group: ${error.message}`);
    }
  }

  // Delete group with cascading deletes
  async deleteWithCascade() {
    try {
      console.log(`Group.deleteWithCascade: Starting deletion for group ${this.id}`);
      
      // Validate that group ID exists
      if (!this.id) {
        throw new Error('Group ID is required for deletion');
      }
      
      // Start transaction
      const client = await db.pool.connect();
      await client.query('BEGIN');

      try {
        console.log(`Group.deleteWithCascade: Deleting related data for group ${this.id}`);
        
        // Delete all related data in the correct order due to foreign key constraints
        
        // 1. Delete settlements (references group_members and expenses)
        await client.query('DELETE FROM settlements WHERE group_id = $1', [this.id]);
        
        // 2. Delete expense assignments (references group_members)
        await client.query('DELETE FROM assignment_users WHERE assignment_id IN (SELECT id FROM assignments WHERE expense_id IN (SELECT id FROM expenses WHERE group_id = $1))', [this.id]);
        
        // 3. Delete assignments (references expenses)
        await client.query('DELETE FROM assignments WHERE expense_id IN (SELECT id FROM expenses WHERE group_id = $1)', [this.id]);
        
        // 4. Delete expense splits (references group_members)
        await client.query('DELETE FROM expense_splits WHERE group_member_id IN (SELECT id FROM group_members WHERE group_id = $1)', [this.id]);
        
        // 5. Delete expense payers (references group_members)
        await client.query('DELETE FROM expense_payers WHERE group_member_id IN (SELECT id FROM group_members WHERE group_id = $1)', [this.id]);
        
        // 6. Delete items (references expenses)
        await client.query('DELETE FROM items WHERE expense_id IN (SELECT id FROM expenses WHERE group_id = $1)', [this.id]);
        
        // 7. Delete expenses (references group)
        await client.query('DELETE FROM expenses WHERE group_id = $1', [this.id]);
        
        // 8. Delete group members (references group)
        await client.query('DELETE FROM group_members WHERE group_id = $1', [this.id]);
        
        // 9. Finally delete the group itself
        const result = await client.query('DELETE FROM groups WHERE id = $1 RETURNING *', [this.id]);
        
        await client.query('COMMIT');
        
        console.log(`Group.deleteWithCascade: Successfully deleted group ${this.id}`);
        
        if (result.rows.length === 0) {
          throw new Error('Group not found');
        }
        
        return true;
      } catch (error) {
        console.error(`Group.deleteWithCascade: Error during deletion:`, error);
        await client.query('ROLLBACK');
        throw error;
      } finally {
        client.release();
      }
    } catch (error) {
      console.error(`Group.deleteWithCascade: Final error:`, error);
      throw new Error(`Failed to delete group with cascade: ${error.message}`);
    }
  }

  // Exit group (set user_id to null for a member)
  async exitGroup(userId) {
    try {
      // Check if user is a member of this group
      const memberQuery = 'SELECT id, role FROM group_members WHERE group_id = $1 AND user_id = $2';
      const memberResult = await db.query(memberQuery, [this.id, userId]);
      
      if (memberResult.rows.length === 0) {
        throw new Error('User is not a member of this group');
      }
      
      const member = memberResult.rows[0];
      
      // Start transaction
      const client = await db.pool.connect();
      await client.query('BEGIN');

      try {
        // Check if this is the last registered user in the group
        const remainingMembersQuery = `
          SELECT COUNT(*) as registered_count 
          FROM group_members 
          WHERE group_id = $1 AND user_id IS NOT NULL
        `;
        const remainingResult = await client.query(remainingMembersQuery, [this.id]);
        const registeredCount = parseInt(remainingResult.rows[0].registered_count);
        
        // If this is the last registered user, delete the entire group
        if (registeredCount === 1) {
          // Delete all related data in the correct order
          await client.query('DELETE FROM settlements WHERE group_id = $1', [this.id]);
          await client.query('DELETE FROM assignment_users WHERE assignment_id IN (SELECT id FROM assignments WHERE expense_id IN (SELECT id FROM expenses WHERE group_id = $1))', [this.id]);
          await client.query('DELETE FROM assignments WHERE expense_id IN (SELECT id FROM expenses WHERE group_id = $1)', [this.id]);
          await client.query('DELETE FROM expense_splits WHERE group_member_id IN (SELECT id FROM group_members WHERE group_id = $1)', [this.id]);
          await client.query('DELETE FROM expense_payers WHERE group_member_id IN (SELECT id FROM group_members WHERE group_id = $1)', [this.id]);
          await client.query('DELETE FROM items WHERE expense_id IN (SELECT id FROM expenses WHERE group_id = $1)', [this.id]);
          await client.query('DELETE FROM expenses WHERE group_id = $1', [this.id]);
          await client.query('DELETE FROM group_members WHERE group_id = $1', [this.id]);
          await client.query('DELETE FROM groups WHERE id = $1', [this.id]);
          
          await client.query('COMMIT');
          return { action: 'group_deleted', message: 'Group deleted as no registered users remain' };
        }
        
        // If not the last user, check if they're the last admin (only if there are other registered users)
        if (member.role === 'admin' && registeredCount > 1) {
          const adminCountQuery = `
            SELECT COUNT(*) as admin_count 
            FROM group_members 
            WHERE group_id = $1 AND role = 'admin' AND user_id IS NOT NULL
          `;
          const adminResult = await client.query(adminCountQuery, [this.id]);
          const adminCount = parseInt(adminResult.rows[0].admin_count);
          
          if (adminCount === 1) {
            throw new Error('Cannot exit group as you are the only admin. Please transfer admin role or delete the group instead.');
          }
        }
        
        // Set user_id to null for this member
        await client.query(
          'UPDATE group_members SET user_id = NULL, is_registered_user = false WHERE id = $1',
          [member.id]
        );
        
        await client.query('COMMIT');
        return { action: 'user_exited', message: 'Successfully exited the group' };
      } catch (error) {
        await client.query('ROLLBACK');
        throw error;
      } finally {
        client.release();
      }
    } catch (error) {
      throw new Error(`Failed to exit group: ${error.message}`);
    }
  }

  // Check if group should be auto-deleted (no registered users)
  async shouldAutoDelete() {
    try {
      const query = `
        SELECT COUNT(*) as registered_count 
        FROM group_members 
        WHERE group_id = $1 AND user_id IS NOT NULL
      `;
      const result = await db.query(query, [this.id]);
      return parseInt(result.rows[0].registered_count) === 0;
    } catch (error) {
      throw new Error(`Failed to check auto-delete status: ${error.message}`);
    }
  }

  // Get group members
  async getMembers() {
    try {
      const query = `
        SELECT 
          gm.id,
          gm.nickname,
          gm.email,
          gm.role,
          gm.is_registered_user,
          gm.joined_at,
          u.id as user_id,
          CONCAT(u.first_name, ' ', u.last_name) as user_name,
          u.avatar as user_avatar
        FROM group_members gm
        LEFT JOIN users u ON gm.user_id = u.id
        WHERE gm.group_id = $1
        ORDER BY gm.joined_at ASC
      `;
      
      const result = await db.query(query, [this.id]);
      return result.rows;
    } catch (error) {
      throw new Error(`Failed to get group members: ${error.message}`);
    }
  }

  // Add member to group
  async addMember(memberData) {
    const { user_id, nickname, email, role } = memberData;

    // Validate input
    const validation = Group.validateMember(memberData);
    if (!validation.isValid) {
      throw new Error(`Validation failed: ${validation.errors.join(', ')}`);
    }

    try {
      // Check if member already exists
      const existingQuery = `
        SELECT id FROM group_members 
        WHERE group_id = $1 AND (user_id = $2 OR nickname = $3)
      `;
      const existingResult = await db.query(existingQuery, [this.id, user_id, nickname]);
      
      if (existingResult.rows.length > 0) {
        throw new Error('Member already exists in this group');
      }

      const query = `
        INSERT INTO group_members (group_id, user_id, nickname, email, role, is_registered_user, joined_at)
        VALUES ($1, $2, $3, $4, $5, $6, NOW())
        RETURNING *
      `;
      
      const isRegisteredUser = !!user_id;
      const values = [this.id, user_id, nickname, email, role || 'member', isRegisteredUser];
      const result = await db.query(query, values);
      
      return result.rows[0];
    } catch (error) {
      throw new Error(`Failed to add member: ${error.message}`);
    }
  }

  // Remove member from group
  async removeMember(memberId) {
    try {
      const query = 'DELETE FROM group_members WHERE id = $1 AND group_id = $2 RETURNING *';
      const result = await db.query(query, [memberId, this.id]);
      
      if (result.rows.length === 0) {
        throw new Error('Member not found in this group');
      }
      
      return result.rows[0];
    } catch (error) {
      throw new Error(`Failed to remove member: ${error.message}`);
    }
  }

  // Claim member (link non-user member to user account)
  async claimMember(memberId, userId) {
    try {
      // Get user info
      const userQuery = 'SELECT first_name, last_name, email FROM users WHERE id = $1';
      const userResult = await db.query(userQuery, [userId]);
      if (userResult.rows[0]) {
        userResult.rows[0].name = `${userResult.rows[0].first_name} ${userResult.rows[0].last_name}`.trim();
      }
      
      if (userResult.rows.length === 0) {
        throw new Error('User not found');
      }
      
      const user = userResult.rows[0];

      // Update member
      const query = `
        UPDATE group_members 
        SET user_id = $1, 
            nickname = $2, 
            email = $3, 
            is_registered_user = true,
            updated_at = NOW()
        WHERE id = $4 AND group_id = $5
        RETURNING *
      `;
      
      const values = [userId, user.name, user.email, memberId, this.id];
      const result = await db.query(query, values);
      
      if (result.rows.length === 0) {
        throw new Error('Member not found in this group');
      }
      
      return result.rows[0];
    } catch (error) {
      throw new Error(`Failed to claim member: ${error.message}`);
    }
  }

  // Get group expenses
  async getExpenses(limit = 10, offset = 0) {
    try {
      const query = `
        SELECT 
          e.*,
          gm.nickname as created_by_name
        FROM expenses e
        JOIN group_members gm ON e.created_by = gm.user_id AND e.group_id = gm.group_id
        WHERE e.group_id = $1
        ORDER BY e.created_at DESC
        LIMIT $2 OFFSET $3
      `;
      
      const result = await db.query(query, [this.id, limit, offset]);
      return result.rows;
    } catch (error) {
      throw new Error(`Failed to get group expenses: ${error.message}`);
    }
  }

  // Get group payment summary
  async getPaymentSummary() {
    try {
      const query = `
        SELECT 
          gm.id as member_id,
          gm.nickname,
          gm.user_id,
          COALESCE(SUM(ep.amount_paid), 0) as total_paid,
          COALESCE(SUM(es.amount_owed), 0) as total_owed,
          COALESCE(SUM(ep.amount_paid), 0) - COALESCE(SUM(es.amount_owed), 0) as balance
        FROM group_members gm
        LEFT JOIN expense_payers ep ON gm.id = ep.group_member_id
        LEFT JOIN expense_splits es ON gm.id = es.group_member_id
        WHERE gm.group_id = $1
        GROUP BY gm.id, gm.nickname, gm.user_id
        ORDER BY gm.nickname
      `;
      
      const result = await db.query(query, [this.id]);
      return result.rows;
    } catch (error) {
      throw new Error(`Failed to get payment summary: ${error.message}`);
    }
  }

  // Get user balance for this specific group using settlements
  async getUserBalance(userId) {
    try {
      const query = `
        SELECT 
          COALESCE(SUM(CASE WHEN s.from_group_member_id = gm.id THEN s.amount ELSE 0 END), 0) as total_to_pay,
          COALESCE(SUM(CASE WHEN s.to_group_member_id = gm.id THEN s.amount ELSE 0 END), 0) as total_to_get_paid,
          COALESCE(SUM(CASE WHEN s.to_group_member_id = gm.id THEN s.amount ELSE 0 END), 0) - 
          COALESCE(SUM(CASE WHEN s.from_group_member_id = gm.id THEN s.amount ELSE 0 END), 0) as balance
        FROM group_members gm
        LEFT JOIN settlements s ON (s.from_group_member_id = gm.id OR s.to_group_member_id = gm.id) 
          AND s.status = 'active' AND s.group_id = $1
        WHERE gm.user_id = $2 AND gm.group_id = $1
      `;

      const result = await db.query(query, [this.id, userId]);
      return result.rows[0] || { total_to_pay: 0, total_to_get_paid: 0, balance: 0 };
    } catch (error) {
      throw new Error(`Failed to get user balance: ${error.message}`);
    }
  }

  // Update last used timestamp
  async updateLastUsed() {
    try {
      const query = `
        UPDATE groups 
        SET updated_at = NOW()
        WHERE id = $1
        RETURNING *
      `;
      
      const result = await db.query(query, [this.id]);
      
      if (result.rows.length === 0) {
        throw new Error('Group not found');
      }
      
      this.updated_at = result.rows[0].updated_at;
      return this;
    } catch (error) {
      throw new Error(`Failed to update last used: ${error.message}`);
    }
  }

  // Check if user is member of group
  async isUserMember(userId) {
    try {
      const query = 'SELECT id FROM group_members WHERE group_id = $1 AND user_id = $2';
      const result = await db.query(query, [this.id, userId]);
      return result.rows.length > 0;
    } catch (error) {
      throw new Error(`Failed to check membership: ${error.message}`);
    }
  }

  // Check if user is admin of group
  async isUserAdmin(userId) {
    try {
      const query = 'SELECT role FROM group_members WHERE group_id = $1 AND user_id = $2';
      const result = await db.query(query, [this.id, userId]);
      return result.rows.length > 0 && result.rows[0].role === 'admin';
    } catch (error) {
      throw new Error(`Failed to check admin status: ${error.message}`);
    }
  }

  // Convert to JSON
  toJSON() {
    const json = {
      id: this.id,
      name: this.name,
      description: this.description,
      image_url: this.image_url,
      created_by: this.created_by,
      currency: this.currency,
      created_at: this.created_at,
      updated_at: this.updated_at
    };
    
    // Include member_count if available (from getGroupsForUser query)
    if (this.member_count !== undefined) {
      json.member_count = parseInt(this.member_count);
    }
    
    return json;
  }

  // Static validation methods
  static validate(groupData) {
    const errors = [];
    const { name, description, currency } = groupData;

    // Name validation
    if (!name || name.trim().length < 2) {
      errors.push('Group name must be at least 2 characters');
    }

    if (name && name.trim().length > 255) {
      errors.push('Group name must be less than 255 characters');
    }

    // Description validation
    if (description && description.length > 1000) {
      errors.push('Description must be less than 1000 characters');
    }

    // Currency validation
    if (currency && !Group.isValidCurrency(currency)) {
      errors.push('Invalid currency code (use 3-letter ISO code)');
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }

  static validateMember(memberData) {
    const errors = [];
    const { nickname, email } = memberData;

    // Nickname validation
    if (!nickname || nickname.trim().length < 2) {
      errors.push('Nickname must be at least 2 characters');
    }

    if (nickname && nickname.trim().length > 255) {
      errors.push('Nickname must be less than 255 characters');
    }

    // Email validation (optional for non-users)
    if (email && !Group.isValidEmail(email)) {
      errors.push('Invalid email format');
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }

  // Helper validation methods
  static isValidCurrency(currency) {
    const currencyRegex = /^[A-Z]{3}$/;
    return currencyRegex.test(currency);
  }

  static isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }
}

module.exports = Group; 