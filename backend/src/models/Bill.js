const pool = require('../config/db');

// Bill model stub
class Bill {
  static async findById(id) {
    try {
      const result = await pool.query('SELECT * FROM bills WHERE id = $1', [id]);
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error finding bill by ID:', error);
      throw error;
    }
  }

  static async create(billData) {
    try {
      const { user_id, image_url } = billData;
      const result = await pool.query(
        'INSERT INTO bills (user_id, image_url) VALUES ($1, $2) RETURNING *',
        [user_id, image_url]
      );
      return result.rows[0];
    } catch (error) {
      console.error('Error creating bill:', error);
      throw error;
    }
  }

  static async update(id, updateData) {
    try {
      const { image_url } = updateData;
      const result = await pool.query(
        'UPDATE bills SET image_url = $1 WHERE id = $2 RETURNING *',
        [image_url, id]
      );
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error updating bill:', error);
      throw error;
    }
  }

  static async delete(id) {
    try {
      const result = await pool.query('DELETE FROM bills WHERE id = $1 RETURNING *', [id]);
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error deleting bill:', error);
      throw error;
    }
  }

  static async findByUserId(userId) {
    try {
      const result = await pool.query('SELECT * FROM bills WHERE user_id = $1 ORDER BY created_at DESC', [userId]);
      return result.rows;
    } catch (error) {
      console.error('Error finding bills by user ID:', error);
      throw error;
    }
  }

  static async getBillWithTotal(id) {
    try {
      // Get bill
      const bill = await this.findById(id);
      if (!bill) return null;

      // Calculate total from items
      const totalResult = await pool.query('SELECT SUM(total_price) AS total FROM items WHERE bill_id = $1', [id]);
      const total = totalResult.rows[0].total ? parseFloat(totalResult.rows[0].total) : 0;

      return {
        ...bill,
        total
      };
    } catch (error) {
      console.error('Error getting bill with total:', error);
      throw error;
    }
  }
}

module.exports = Bill; 