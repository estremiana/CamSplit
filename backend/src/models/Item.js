const db = require('../../database/connection');

class Item {
  constructor(data) {
    this.id = data.id;
    this.expense_id = data.expense_id;
    this.name = data.name;
    this.description = data.description;
    this.unit_price = parseFloat(data.unit_price);
    this.max_quantity = parseInt(data.max_quantity);
    this.total_price = parseFloat(data.total_price);
    this.category = data.category || 'Other';
    this.created_at = data.created_at;
    this.updated_at = data.updated_at;
  }

  // Create a new item
  static async create(itemData) {
    try {
      // Validate input data
      const validation = Item.validate(itemData);
      if (!validation.isValid) {
        throw new Error(validation.errors.join(', '));
      }

      // Calculate total_price if not provided
      if (!itemData.total_price) {
        itemData.total_price = itemData.unit_price * itemData.max_quantity;
      }

      const query = `
        INSERT INTO items (expense_id, name, description, unit_price, max_quantity, total_price, category)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        RETURNING *
      `;

      const values = [
        itemData.expense_id,
        itemData.name,
        itemData.description,
        itemData.unit_price,
        itemData.max_quantity,
        itemData.total_price,
        itemData.category
      ];

      const result = await db.query(query, values);
      return new Item(result.rows[0]);
    } catch (error) {
      throw new Error(`Failed to create item: ${error.message}`);
    }
  }

  // Find item by ID
  static async findById(id) {
    try {
      const query = 'SELECT * FROM items WHERE id = $1';
      const result = await db.query(query, [id]);
      
      if (result.rows.length === 0) {
        return null;
      }
      
      return new Item(result.rows[0]);
    } catch (error) {
      throw new Error(`Failed to find item: ${error.message}`);
    }
  }

  // Find items by expense ID
  static async findByExpenseId(expenseId) {
    try {
      const query = 'SELECT * FROM items WHERE expense_id = $1 ORDER BY created_at ASC';
      const result = await db.query(query, [expenseId]);
      
      return result.rows.map(row => new Item(row));
    } catch (error) {
      throw new Error(`Failed to find items by expense: ${error.message}`);
    }
  }

  // Find items by expense ID with assignments
  static async findByExpenseIdWithAssignments(expenseId) {
    try {
      const query = `
        SELECT 
          i.*,
          json_agg(
            json_build_object(
              'id', a.id,
              'quantity', a.quantity,
              'unit_price', a.unit_price,
              'total_price', a.total_price,
              'people_count', a.people_count,
              'price_per_person', a.price_per_person,
              'notes', a.notes,
              'created_at', a.created_at,
              'updated_at', a.updated_at,
              'assigned_users', (
                SELECT json_agg(
                  json_build_object(
                    'group_member_id', au.group_member_id,
                    'nickname', gm.nickname,
                    'is_registered_user', gm.is_registered_user
                  )
                )
                FROM assignment_users au
                JOIN group_members gm ON au.group_member_id = gm.id
                WHERE au.assignment_id = a.id
              )
            )
          ) FILTER (WHERE a.id IS NOT NULL) as assignments
        FROM items i
        LEFT JOIN assignments a ON i.id = a.item_id
        WHERE i.expense_id = $1
        GROUP BY i.id
        ORDER BY i.created_at ASC
      `;
      
      const result = await db.query(query, [expenseId]);
      
      return result.rows.map(row => ({
        ...new Item(row).toJSON(),
        assignments: row.assignments || []
      }));
    } catch (error) {
      throw new Error(`Failed to find items with assignments: ${error.message}`);
    }
  }

  // Update item
  async update(updateData) {
    try {
      // Validate update data
      const validation = Item.validateUpdate(updateData);
      if (!validation.isValid) {
        throw new Error(validation.errors.join(', '));
      }

      // Calculate total_price if unit_price or max_quantity changed
      if (updateData.unit_price || updateData.max_quantity) {
        const newUnitPrice = updateData.unit_price || this.unit_price;
        const newMaxQuantity = updateData.max_quantity || this.max_quantity;
        updateData.total_price = newUnitPrice * newMaxQuantity;
      }

      const query = `
        UPDATE items 
        SET name = COALESCE($1, name),
            description = COALESCE($2, description),
            unit_price = COALESCE($3, unit_price),
            max_quantity = COALESCE($4, max_quantity),
            total_price = COALESCE($5, total_price),
            category = COALESCE($6, category),
            updated_at = NOW()
        WHERE id = $7
        RETURNING *
      `;

      const values = [
        updateData.name,
        updateData.description,
        updateData.unit_price,
        updateData.max_quantity,
        updateData.total_price,
        updateData.category,
        this.id
      ];

      const result = await db.query(query, values);
      
      if (result.rows.length === 0) {
        throw new Error('Item not found');
      }

      // Update current instance
      Object.assign(this, new Item(result.rows[0]));
      return this;
    } catch (error) {
      throw new Error(`Failed to update item: ${error.message}`);
    }
  }

  // Delete item
  async delete() {
    try {
      const query = 'DELETE FROM items WHERE id = $1 RETURNING *';
      const result = await db.query(query, [this.id]);
      
      if (result.rows.length === 0) {
        throw new Error('Item not found');
      }
      
      return true;
    } catch (error) {
      throw new Error(`Failed to delete item: ${error.message}`);
    }
  }

  // Get remaining quantity (max_quantity - sum of all assignments)
  async getRemainingQuantity() {
    try {
      const query = `
        SELECT COALESCE(i.max_quantity - COALESCE(SUM(a.quantity), 0), i.max_quantity) as remaining_quantity
        FROM items i
        LEFT JOIN assignments a ON i.id = a.item_id
        WHERE i.id = $1
        GROUP BY i.id, i.max_quantity
      `;
      
      const result = await db.query(query, [this.id]);
      
      if (result.rows.length === 0) {
        return 0;
      }
      
      return parseFloat(result.rows[0].remaining_quantity);
    } catch (error) {
      throw new Error(`Failed to get remaining quantity: ${error.message}`);
    }
  }

  // Get assignments for this item
  async getAssignments() {
    try {
      const query = `
        SELECT a.*, 
               json_agg(
                 json_build_object(
                   'group_member_id', au.group_member_id,
                   'nickname', gm.nickname,
                   'is_registered_user', gm.is_registered_user
                 )
               ) as assigned_users
        FROM assignments a
        LEFT JOIN assignment_users au ON a.id = au.assignment_id
        LEFT JOIN group_members gm ON au.group_member_id = gm.id
        WHERE a.item_id = $1
        GROUP BY a.id
        ORDER BY a.created_at ASC
      `;
      
      const result = await db.query(query, [this.id]);
      return result.rows;
    } catch (error) {
      throw new Error(`Failed to get assignments: ${error.message}`);
    }
  }

  // Convert to JSON
  toJSON() {
    return {
      id: this.id,
      expense_id: this.expense_id,
      name: this.name,
      description: this.description,
      unit_price: this.unit_price,
      max_quantity: this.max_quantity,
      total_price: this.total_price,
      category: this.category,
      created_at: this.created_at,
      updated_at: this.updated_at
    };
  }

  // Static validation methods
  static validate(itemData) {
    const errors = [];

    if (!itemData.expense_id) {
      errors.push('Expense ID is required');
    }

    if (!itemData.name || itemData.name.trim().length === 0) {
      errors.push('Item name is required');
    }

    if (!itemData.unit_price || itemData.unit_price <= 0) {
      errors.push('Unit price must be greater than 0');
    }

    if (!itemData.max_quantity || itemData.max_quantity <= 0) {
      errors.push('Max quantity must be greater than 0');
    }

    if (itemData.category && itemData.category.length > 100) {
      errors.push('Category must be 100 characters or less');
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }

  static validateUpdate(updateData) {
    const errors = [];

    if (updateData.name !== undefined && (updateData.name.trim().length === 0)) {
      errors.push('Item name cannot be empty');
    }

    if (updateData.unit_price !== undefined && updateData.unit_price <= 0) {
      errors.push('Unit price must be greater than 0');
    }

    if (updateData.max_quantity !== undefined && updateData.max_quantity <= 0) {
      errors.push('Max quantity must be greater than 0');
    }

    if (updateData.category !== undefined && updateData.category.length > 100) {
      errors.push('Category must be 100 characters or less');
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }
}

module.exports = Item; 