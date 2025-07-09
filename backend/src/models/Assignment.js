const pool = require('../config/db');

// Assignment model stub
class Assignment {
  static async findById(id) {
    try {
      const result = await pool.query('SELECT * FROM assignments WHERE id = $1', [id]);
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error finding assignment by ID:', error);
      throw error;
    }
  }

  static async findByBillId(billId) {
    try {
      const result = await pool.query(
        `SELECT a.*, i.name as item_name, i.total_price as item_price, p.name as participant_name
         FROM assignments a
         JOIN items i ON a.item_id = i.id
         JOIN participants p ON a.participant_id = p.id
         WHERE a.bill_id = $1
         ORDER BY i.name, p.name`,
        [billId]
      );
      return result.rows;
    } catch (error) {
      console.error('Error finding assignments by bill ID:', error);
      throw error;
    }
  }

  static async findByItemId(itemId) {
    try {
      const result = await pool.query(
        `SELECT a.*, p.name as participant_name
         FROM assignments a
         JOIN participants p ON a.participant_id = p.id
         WHERE a.item_id = $1`,
        [itemId]
      );
      return result.rows;
    } catch (error) {
      console.error('Error finding assignments by item ID:', error);
      throw error;
    }
  }

  static async create(assignmentData) {
    try {
      const { bill_id, item_id, participant_id, quantity, cost_per_person } = assignmentData;
      const result = await pool.query(
        'INSERT INTO assignments (bill_id, item_id, participant_id, quantity, cost_per_person) VALUES ($1, $2, $3, $4, $5) RETURNING *',
        [bill_id, item_id, participant_id, quantity, cost_per_person]
      );
      return result.rows[0];
    } catch (error) {
      console.error('Error creating assignment:', error);
      throw error;
    }
  }

  static async update(id, updateData) {
    try {
      const { quantity, cost_per_person } = updateData;
      const result = await pool.query(
        'UPDATE assignments SET quantity = $1, cost_per_person = $2 WHERE id = $3 RETURNING *',
        [quantity, cost_per_person, id]
      );
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error updating assignment:', error);
      throw error;
    }
  }

  static async delete(id) {
    try {
      const result = await pool.query('DELETE FROM assignments WHERE id = $1 RETURNING *', [id]);
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error deleting assignment:', error);
      throw error;
    }
  }

  static async deleteByBillId(billId) {
    try {
      const result = await pool.query('DELETE FROM assignments WHERE bill_id = $1 RETURNING *', [billId]);
      return result.rows;
    } catch (error) {
      console.error('Error deleting assignments by bill ID:', error);
      throw error;
    }
  }

  static async upsert(assignmentData) {
    try {
      const { bill_id, item_id, participant_id, quantity, cost_per_person } = assignmentData;
      
      const result = await pool.query(
        `INSERT INTO assignments (bill_id, item_id, participant_id, quantity, cost_per_person)
         VALUES ($1, $2, $3, $4, $5)
         ON CONFLICT (bill_id, item_id, participant_id)
         DO UPDATE SET
           quantity = assignments.quantity + EXCLUDED.quantity,
           cost_per_person = assignments.cost_per_person + EXCLUDED.cost_per_person
         RETURNING *`,
        [bill_id, item_id, participant_id, quantity, cost_per_person]
      );
      
      return result.rows[0];
    } catch (error) {
      console.error('Error upserting assignment:', error);
      throw error;
    }
  }

  static async bulkUpsert(assignments) {
    try {
      const client = await pool.connect();
      
      try {
        await client.query('BEGIN');
        
        const results = [];
        for (const assignment of assignments) {
          const result = await this.upsert(assignment);
          results.push(result);
        }
        
        await client.query('COMMIT');
        return results;
      } catch (error) {
        await client.query('ROLLBACK');
        throw error;
      } finally {
        client.release();
      }
    } catch (error) {
      console.error('Error bulk upserting assignments:', error);
      throw error;
    }
  }

  static async getAssignmentSummary(billId) {
    try {
      const result = await pool.query(
        `SELECT 
           p.id as participant_id,
           p.name as participant_name,
           COUNT(a.id) as items_assigned,
           SUM(a.cost_per_person) as total_cost
         FROM participants p
         LEFT JOIN assignments a ON p.id = a.participant_id AND a.bill_id = $1
         WHERE p.bill_id = $1
         GROUP BY p.id, p.name
         ORDER BY p.name`,
        [billId]
      );
      return result.rows;
    } catch (error) {
      console.error('Error getting assignment summary:', error);
      throw error;
    }
  }
}

module.exports = Assignment; 