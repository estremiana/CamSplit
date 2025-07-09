const pool = require('../config/db');
const bcrypt = require('bcrypt');

// User model stub
class User {
  static async findById(id) {
    try {
      const result = await pool.query('SELECT id, email, name, created_at FROM users WHERE id = $1', [id]);
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error finding user by ID:', error);
      throw error;
    }
  }

  static async findByEmail(email) {
    try {
      const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error finding user by email:', error);
      throw error;
    }
  }

  static async create(userData) {
    try {
      const { email, password, name, birthdate } = userData;
      
      // Hash password
      const saltRounds = 10;
      const hashedPassword = await bcrypt.hash(password, saltRounds);
      
      const result = await pool.query(
        'INSERT INTO users (email, password, name, birthdate) VALUES ($1, $2, $3, $4) RETURNING id, email, name, created_at',
        [email, hashedPassword, name, birthdate]
      );
      return result.rows[0];
    } catch (error) {
      console.error('Error creating user:', error);
      throw error;
    }
  }

  static async update(id, updateData) {
    try {
      const { email, name } = updateData;
      const result = await pool.query(
        'UPDATE users SET email = $1, name = $2 WHERE id = $3 RETURNING id, email, name, created_at',
        [email, name, id]
      );
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error updating user:', error);
      throw error;
    }
  }

  static async updatePassword(id, newPassword) {
    try {
      const saltRounds = 10;
      const hashedPassword = await bcrypt.hash(newPassword, saltRounds);
      
      const result = await pool.query(
        'UPDATE users SET password = $1 WHERE id = $2 RETURNING id, email, name, created_at',
        [hashedPassword, id]
      );
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error updating password:', error);
      throw error;
    }
  }

  static async delete(id) {
    try {
      const result = await pool.query('DELETE FROM users WHERE id = $1 RETURNING id, email, name, created_at', [id]);
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error deleting user:', error);
      throw error;
    }
  }

  static async validatePassword(user, password) {
    try {
      return await bcrypt.compare(password, user.password);
    } catch (error) {
      console.error('Error validating password:', error);
      throw error;
    }
  }
}

module.exports = User; 