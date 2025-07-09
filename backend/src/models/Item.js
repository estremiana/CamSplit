const pool = require('../config/db');

class Item {
  static async findById(id) {
    try {
      const result = await pool.query('SELECT * FROM items WHERE id = $1', [id]);
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error finding item by ID:', error);
      throw error;
    }
  }

  static async findByBillId(billId) {
    try {
      const result = await pool.query('SELECT * FROM items WHERE bill_id = $1', [billId]);
      return result.rows;
    } catch (error) {
      console.error('Error finding items by bill ID:', error);
      throw error;
    }
  }

  static async create(itemData) {
    try {
      const { bill_id, name, unit_price, total_price, quantity, quantity_left } = itemData;
      const result = await pool.query(
        'INSERT INTO items (bill_id, name, unit_price, total_price, quantity, quantity_left) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *',
        [bill_id, name, unit_price, total_price, quantity, quantity_left]
      );
      return result.rows[0];
    } catch (error) {
      console.error('Error creating item:', error);
      throw error;
    }
  }

  static async update(id, updateData) {
    try {
      const { name, unit_price, total_price, quantity, quantity_left } = updateData;
      const result = await pool.query(
        'UPDATE items SET name = $1, unit_price = $2, total_price = $3, quantity = $4, quantity_left = $5 WHERE id = $6 RETURNING *',
        [name, unit_price, total_price, quantity, quantity_left, id]
      );
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error updating item:', error);
      throw error;
    }
  }

  static async delete(id) {
    try {
      const result = await pool.query('DELETE FROM items WHERE id = $1 RETURNING *', [id]);
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error deleting item:', error);
      throw error;
    }
  }
}

module.exports = Item; 