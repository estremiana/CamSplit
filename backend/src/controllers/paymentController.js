const PaymentService = require('../services/paymentService');

class PaymentController {
  // Create a new payment
  static async createPayment(req, res) {
    try {
      const userId = req.user.id;
      const { 
        group_id, from_group_member_id, to_group_member_id, amount, 
        currency, payment_method, notes 
      } = req.body;

      // Validate required fields
      if (!group_id || !from_group_member_id || !to_group_member_id || !amount) {
        return res.status(400).json({
          success: false,
          message: 'Group ID, from member ID, to member ID, and amount are required'
        });
      }

      const result = await PaymentService.createPayment({
        group_id,
        from_group_member_id,
        to_group_member_id,
        amount,
        currency,
        payment_method,
        notes
      }, userId);

      res.status(201).json({
        success: true,
        message: result.message,
        data: result.payment
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Get payment by ID
  static async getPayment(req, res) {
    try {
      const { paymentId } = req.params;
      const userId = req.user.id;

      const payment = await PaymentService.getPayment(paymentId, userId);

      res.status(200).json({
        success: true,
        data: payment
      });
    } catch (error) {
      res.status(404).json({
        success: false,
        message: error.message
      });
    }
  }

  // Get payment with member details
  static async getPaymentWithDetails(req, res) {
    try {
      const { paymentId } = req.params;
      const userId = req.user.id;

      const paymentWithDetails = await PaymentService.getPaymentWithDetails(paymentId, userId);

      res.status(200).json({
        success: true,
        data: paymentWithDetails
      });
    } catch (error) {
      res.status(404).json({
        success: false,
        message: error.message
      });
    }
  }

  // Get payments for a group
  static async getGroupPayments(req, res) {
    try {
      const { groupId } = req.params;
      const userId = req.user.id;
      const { limit = 10, offset = 0 } = req.query;

      const payments = await PaymentService.getGroupPayments(groupId, userId, parseInt(limit), parseInt(offset));

      res.status(200).json({
        success: true,
        data: payments
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  // Get payments for a user
  static async getUserPayments(req, res) {
    try {
      const userId = req.user.id;
      const { limit = 10, offset = 0 } = req.query;

      const payments = await PaymentService.getUserPayments(userId, parseInt(limit), parseInt(offset));

      res.status(200).json({
        success: true,
        data: payments
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  // Get pending payments for a group
  static async getPendingPayments(req, res) {
    try {
      const { groupId } = req.params;
      const userId = req.user.id;

      const payments = await PaymentService.getPendingPayments(groupId, userId);

      res.status(200).json({
        success: true,
        data: payments
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  // Update payment status
  static async updatePaymentStatus(req, res) {
    try {
      const { paymentId } = req.params;
      const userId = req.user.id;
      const { status } = req.body;

      if (!status) {
        return res.status(400).json({
          success: false,
          message: 'Status is required'
        });
      }

      const updatedPayment = await PaymentService.updatePaymentStatus(paymentId, status, userId);

      res.status(200).json({
        success: true,
        message: 'Payment status updated successfully',
        data: updatedPayment
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Update payment details
  static async updatePayment(req, res) {
    try {
      const { paymentId } = req.params;
      const userId = req.user.id;
      const { amount, currency, payment_method, notes } = req.body;

      const updatedPayment = await PaymentService.updatePayment(paymentId, {
        amount,
        currency,
        payment_method,
        notes
      }, userId);

      res.status(200).json({
        success: true,
        message: 'Payment updated successfully',
        data: updatedPayment
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Delete payment
  static async deletePayment(req, res) {
    try {
      const { paymentId } = req.params;
      const userId = req.user.id;

      const result = await PaymentService.deletePayment(paymentId, userId);

      res.status(200).json({
        success: true,
        message: result.message
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Get payment summary for a group
  static async getGroupPaymentSummary(req, res) {
    try {
      const { groupId } = req.params;
      const userId = req.user.id;

      const summary = await PaymentService.getGroupPaymentSummary(groupId, userId);

      res.status(200).json({
        success: true,
        data: summary
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  // Get debt relationships for a group
  static async getGroupDebtRelationships(req, res) {
    try {
      const { groupId } = req.params;
      const userId = req.user.id;

      const relationships = await PaymentService.getGroupDebtRelationships(groupId, userId);

      res.status(200).json({
        success: true,
        data: relationships
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  // Create settlement payments for a group
  static async createSettlementPayments(req, res) {
    try {
      const { groupId } = req.params;
      const userId = req.user.id;

      const result = await PaymentService.createSettlementPayments(groupId, userId);

      res.status(201).json({
        success: true,
        message: result.message,
        data: result.payments
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Mark payment as completed
  static async markPaymentCompleted(req, res) {
    try {
      const { paymentId } = req.params;
      const userId = req.user.id;

      const updatedPayment = await PaymentService.markPaymentCompleted(paymentId, userId);

      res.status(200).json({
        success: true,
        message: 'Payment marked as completed',
        data: updatedPayment
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Mark payment as cancelled
  static async markPaymentCancelled(req, res) {
    try {
      const { paymentId } = req.params;
      const userId = req.user.id;

      const updatedPayment = await PaymentService.markPaymentCancelled(paymentId, userId);

      res.status(200).json({
        success: true,
        message: 'Payment marked as cancelled',
        data: updatedPayment
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }
}

module.exports = PaymentController; 