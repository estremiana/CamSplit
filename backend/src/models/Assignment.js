const db = require('../../database/connection');

class Assignment {
  constructor(data) {
    this.id = data.id;
    this.expense_id = data.expense_id;
    this.item_id = data.item_id;
    this.quantity = parseFloat(data.quantity);
    this.unit_price = parseFloat(data.unit_price);
    this.total_price = parseFloat(data.total_price);
    this.people_count = parseInt(data.people_count);
    this.price_per_person = parseFloat(data.price_per_person);
    this.notes = data.notes;
    this.created_at = data.created_at;
    this.updated_at = data.updated_at;
  }

  // Create a new assignment
  static async create(assignmentData) {
    try {
      // Validate input data
      const validation = Assignment.validate(assignmentData);
      if (!validation.isValid) {
        throw new Error(validation.errors.join(', '));
      }

      // Calculate total_price if not provided
      if (!assignmentData.total_price) {
        assignmentData.total_price = assignmentData.quantity * assignmentData.unit_price;
      }

      const query = `
        INSERT INTO assignments (expense_id, item_id, quantity, unit_price, total_price, people_count, price_per_person, notes)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        RETURNING *
      `;

      const values = [
        assignmentData.expense_id,
        assignmentData.item_id,
        assignmentData.quantity,
        assignmentData.unit_price,
        assignmentData.total_price,
        assignmentData.people_count,
        assignmentData.price_per_person,
        assignmentData.notes
      ];

      const result = await db.query(query, values);
      const assignment = new Assignment(result.rows[0]);

      // Add users to assignment if provided
      if (assignmentData.user_ids && assignmentData.user_ids.length > 0) {
        await assignment.addUsers(assignmentData.user_ids);
      }

      return assignment;
    } catch (error) {
      throw new Error(`Failed to create assignment: ${error.message}`);
    }
  }

  // Find assignment by ID
  static async findById(id) {
    try {
      const query = 'SELECT * FROM assignments WHERE id = $1';
      const result = await db.query(query, [id]);
      
      if (result.rows.length === 0) {
        return null;
      }
      
      return new Assignment(result.rows[0]);
    } catch (error) {
      throw new Error(`Failed to find assignment: ${error.message}`);
    }
  }

  // Find assignment by ID with users
  static async findByIdWithUsers(id) {
    try {
      const query = `
        SELECT 
          a.*,
          json_agg(
            json_build_object(
              'group_member_id', au.group_member_id,
              'nickname', gm.nickname,
              'is_registered_user', gm.is_registered_user,
              'email', gm.email
            )
          ) FILTER (WHERE au.group_member_id IS NOT NULL) as assigned_users
        FROM assignments a
        LEFT JOIN assignment_users au ON a.id = au.assignment_id
        LEFT JOIN group_members gm ON au.group_member_id = gm.id
        WHERE a.id = $1
        GROUP BY a.id
      `;
      
      const result = await db.query(query, [id]);
      
      if (result.rows.length === 0) {
        return null;
      }
      
      const assignment = new Assignment(result.rows[0]);
      return {
        ...assignment.toJSON(),
        assigned_users: result.rows[0].assigned_users || []
      };
    } catch (error) {
      throw new Error(`Failed to find assignment with users: ${error.message}`);
    }
  }

  // Find assignments by expense ID
  static async findByExpenseId(expenseId) {
    try {
      const query = `
        SELECT 
          a.*,
          json_agg(
            json_build_object(
              'group_member_id', au.group_member_id,
              'nickname', gm.nickname,
              'is_registered_user', gm.is_registered_user
            )
          ) FILTER (WHERE au.group_member_id IS NOT NULL) as assigned_users
        FROM assignments a
        LEFT JOIN assignment_users au ON a.id = au.assignment_id
        LEFT JOIN group_members gm ON au.group_member_id = gm.id
        WHERE a.expense_id = $1
        GROUP BY a.id
        ORDER BY a.created_at ASC
      `;
      
      const result = await db.query(query, [expenseId]);
      
      return result.rows.map(row => ({
        ...new Assignment(row).toJSON(),
        assigned_users: row.assigned_users || []
      }));
    } catch (error) {
      throw new Error(`Failed to find assignments by expense: ${error.message}`);
    }
  }

  // Find assignments by item ID
  static async findByItemId(itemId) {
    try {
      const query = `
        SELECT 
          a.*,
          json_agg(
            json_build_object(
              'group_member_id', au.group_member_id,
              'nickname', gm.nickname,
              'is_registered_user', gm.is_registered_user
            )
          ) FILTER (WHERE au.group_member_id IS NOT NULL) as assigned_users
        FROM assignments a
        LEFT JOIN assignment_users au ON a.id = au.assignment_id
        LEFT JOIN group_members gm ON au.group_member_id = gm.id
        WHERE a.item_id = $1
        GROUP BY a.id
        ORDER BY a.created_at ASC
      `;
      
      const result = await db.query(query, [itemId]);
      
      return result.rows.map(row => ({
        ...new Assignment(row).toJSON(),
        assigned_users: row.assigned_users || []
      }));
    } catch (error) {
      throw new Error(`Failed to find assignments by item: ${error.message}`);
    }
  }

  // Update assignment
  async update(updateData) {
    try {
      // Validate update data
      const validation = Assignment.validateUpdate(updateData);
      if (!validation.isValid) {
        throw new Error(validation.errors.join(', '));
      }

      // Calculate total_price if quantity or unit_price changed
      if (updateData.quantity || updateData.unit_price) {
        const newQuantity = updateData.quantity || this.quantity;
        const newUnitPrice = updateData.unit_price || this.unit_price;
        updateData.total_price = newQuantity * newUnitPrice;
      }

      const query = `
        UPDATE assignments 
        SET quantity = COALESCE($1, quantity),
            unit_price = COALESCE($2, unit_price),
            total_price = COALESCE($3, total_price),
            people_count = COALESCE($4, people_count),
            price_per_person = COALESCE($5, price_per_person),
            notes = COALESCE($6, notes),
            updated_at = NOW()
        WHERE id = $7
        RETURNING *
      `;

      const values = [
        updateData.quantity,
        updateData.unit_price,
        updateData.total_price,
        updateData.people_count,
        updateData.price_per_person,
        updateData.notes,
        this.id
      ];

      const result = await db.query(query, values);
      
      if (result.rows.length === 0) {
        throw new Error('Assignment not found');
      }

      // Update current instance
      Object.assign(this, new Assignment(result.rows[0]));
      return this;
    } catch (error) {
      throw new Error(`Failed to update assignment: ${error.message}`);
    }
  }

  // Delete assignment
  async delete() {
    try {
      const query = 'DELETE FROM assignments WHERE id = $1 RETURNING *';
      const result = await db.query(query, [this.id]);
      
      if (result.rows.length === 0) {
        throw new Error('Assignment not found');
      }
      
      return true;
    } catch (error) {
      throw new Error(`Failed to delete assignment: ${error.message}`);
    }
  }

  // Add users to assignment
  async addUsers(userIds) {
    try {
      if (!userIds || userIds.length === 0) {
        return;
      }

      const values = userIds.map((userId, index) => `($1, $${index + 2})`).join(', ');
      const query = `
        INSERT INTO assignment_users (assignment_id, group_member_id)
        VALUES ${values}
        ON CONFLICT (assignment_id, group_member_id) DO NOTHING
      `;

      await db.query(query, [this.id, ...userIds]);
    } catch (error) {
      throw new Error(`Failed to add users to assignment: ${error.message}`);
    }
  }

  // Remove user from assignment
  async removeUser(userId) {
    try {
      const query = 'DELETE FROM assignment_users WHERE assignment_id = $1 AND group_member_id = $2';
      const result = await db.query(query, [this.id, userId]);
      
      return result.rowCount > 0;
    } catch (error) {
      throw new Error(`Failed to remove user from assignment: ${error.message}`);
    }
  }

  // Get assigned users
  async getAssignedUsers() {
    try {
      const query = `
        SELECT gm.id, gm.nickname, gm.is_registered_user, gm.email
        FROM assignment_users au
        JOIN group_members gm ON au.group_member_id = gm.id
        WHERE au.assignment_id = $1
        ORDER BY gm.nickname
      `;
      
      const result = await db.query(query, [this.id]);
      return result.rows;
    } catch (error) {
      throw new Error(`Failed to get assigned users: ${error.message}`);
    }
  }

  // Check if user is assigned to this assignment
  async isUserAssigned(userId) {
    try {
      const query = 'SELECT 1 FROM assignment_users WHERE assignment_id = $1 AND group_member_id = $2';
      const result = await db.query(query, [this.id, userId]);
      
      return result.rows.length > 0;
    } catch (error) {
      throw new Error(`Failed to check user assignment: ${error.message}`);
    }
  }

  // Get assignment summary
  async getSummary() {
    try {
      const assignedUsers = await this.getAssignedUsers();
      
      return {
        id: this.id,
        quantity: this.quantity,
        unit_price: this.unit_price,
        total_price: this.total_price,
        people_count: this.people_count,
        price_per_person: this.price_per_person,
        assigned_users: assignedUsers,
        notes: this.notes
      };
    } catch (error) {
      throw new Error(`Failed to get assignment summary: ${error.message}`);
    }
  }

  // Convert to JSON
  toJSON() {
    return {
      id: this.id,
      expense_id: this.expense_id,
      item_id: this.item_id,
      quantity: this.quantity,
      unit_price: this.unit_price,
      total_price: this.total_price,
      people_count: this.people_count,
      price_per_person: this.price_per_person,
      notes: this.notes,
      created_at: this.created_at,
      updated_at: this.updated_at
    };
  }

  // Static validation methods
  static validate(assignmentData) {
    const errors = [];

    if (!assignmentData.expense_id) {
      errors.push('Expense ID is required');
    }

    if (!assignmentData.item_id) {
      errors.push('Item ID is required');
    }

    if (!assignmentData.quantity || assignmentData.quantity <= 0) {
      errors.push('Quantity must be greater than 0');
    }

    if (!assignmentData.unit_price || assignmentData.unit_price <= 0) {
      errors.push('Unit price must be greater than 0');
    }

    if (!assignmentData.people_count || assignmentData.people_count <= 0) {
      errors.push('People count must be greater than 0');
    }

    if (!assignmentData.price_per_person || assignmentData.price_per_person <= 0) {
      errors.push('Price per person must be greater than 0');
    }

    // Validate that quantity doesn't exceed item's max_quantity
    if (assignmentData.quantity && assignmentData.item_id) {
      // This would need to be checked at the service level with a database query
      // For now, we'll just validate the basic constraints
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }

  static validateUpdate(updateData) {
    const errors = [];

    if (updateData.quantity !== undefined && updateData.quantity <= 0) {
      errors.push('Quantity must be greater than 0');
    }

    if (updateData.unit_price !== undefined && updateData.unit_price <= 0) {
      errors.push('Unit price must be greater than 0');
    }

    if (updateData.people_count !== undefined && updateData.people_count <= 0) {
      errors.push('People count must be greater than 0');
    }

    if (updateData.price_per_person !== undefined && updateData.price_per_person <= 0) {
      errors.push('Price per person must be greater than 0');
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }
}

module.exports = Assignment; 