const pool = require('../config/db');

class Payment {
  static async findById(id) {
    try {
      const result = await pool.query('SELECT * FROM payments WHERE id = $1', [id]);
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error finding payment by ID:', error);
      throw error;
    }
  }

  static async findByBillId(billId) {
    try {
      const result = await pool.query('SELECT * FROM payments WHERE bill_id = $1', [billId]);
      return result.rows;
    } catch (error) {
      console.error('Error finding payments by bill ID:', error);
      throw error;
    }
  }

  static async create(paymentData) {
    try {
      const { bill_id, from_participant_id, to_participant_id, amount, is_paid = false } = paymentData;
      const result = await pool.query(
        'INSERT INTO payments (bill_id, from_participant_id, to_participant_id, amount, is_paid) VALUES ($1, $2, $3, $4, $5) RETURNING *',
        [bill_id, from_participant_id, to_participant_id, amount, is_paid]
      );
      return result.rows[0];
    } catch (error) {
      console.error('Error creating payment:', error);
      throw error;
    }
  }

  static async update(id, updateData) {
    try {
      const { amount, is_paid } = updateData;
      const result = await pool.query(
        'UPDATE payments SET amount = $1, is_paid = $2 WHERE id = $3 RETURNING *',
        [amount, is_paid, id]
      );
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error updating payment:', error);
      throw error;
    }
  }

  static async markAsPaid(id) {
    try {
      const result = await pool.query('UPDATE payments SET is_paid = TRUE WHERE id = $1 RETURNING *', [id]);
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error marking payment as paid:', error);
      throw error;
    }
  }

  static async delete(id) {
    try {
      const result = await pool.query('DELETE FROM payments WHERE id = $1 RETURNING *', [id]);
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error deleting payment:', error);
      throw error;
    }
  }
}

module.exports = Payment; 