const pool = require('../config/db');

class Participant {
  static async findById(id) {
    try {
      const result = await pool.query('SELECT * FROM participants WHERE id = $1', [id]);
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error finding participant by ID:', error);
      throw error;
    }
  }

  static async findByBillId(billId) {
    try {
      const result = await pool.query('SELECT * FROM participants WHERE bill_id = $1', [billId]);
      return result.rows;
    } catch (error) {
      console.error('Error finding participants by bill ID:', error);
      throw error;
    }
  }

  static async create(participantData) {
    try {
      const { bill_id, name, user_id, amount_paid = 0, amount_owed = 0 } = participantData;
      const result = await pool.query(
        'INSERT INTO participants (bill_id, name, user_id, amount_paid, amount_owed) VALUES ($1, $2, $3, $4, $5) RETURNING *',
        [bill_id, name, user_id, amount_paid, amount_owed]
      );
      return result.rows[0];
    } catch (error) {
      console.error('Error creating participant:', error);
      throw error;
    }
  }

  static async update(id, updateData) {
    try {
      const { name, user_id } = updateData;
      const result = await pool.query(
        'UPDATE participants SET name = $1, user_id = $2 WHERE id = $3 RETURNING *',
        [name, user_id, id]
      );
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error updating participant:', error);
      throw error;
    }
  }

  static async delete(id) {
    try {
      const result = await pool.query('DELETE FROM participants WHERE id = $1 RETURNING *', [id]);
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error deleting participant:', error);
      throw error;
    }
  }

  static async setamount_paid(id, amount_paid) {
    try {
      const result = await pool.query('UPDATE participants SET amount_paid = $1 WHERE id = $2 RETURNING *', [amount_paid, id]);
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error setting amount_paid:', error);
      throw error;
    }
  }

  static async setamount_owed(id, amount_owed) {
    try {
      const result = await pool.query('UPDATE participants SET amount_owed = $1 WHERE id = $2 RETURNING *', [amount_owed, id]);
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error setting amount_owed:', error);
      throw error;
    }
  }
}

module.exports = Participant; 