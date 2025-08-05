const Payment = require('../models/Payment');
const Group = require('../models/Group');
const User = require('../models/User');

class PaymentService {
  // Create a new payment
  static async createPayment(paymentData, userId) {
    try {
      // Verify user exists
      const user = await User.findById(userId);
      if (!user) {
        throw new Error('User not found');
      }

      // Verify group exists and user is member
      const group = await Group.findById(paymentData.group_id);
      if (!group) {
        throw new Error('Group not found');
      }

      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to create payments');
      }

      // Create payment
      const payment = await Payment.create(paymentData);

      return {
        payment: payment.toJSON(),
        message: 'Payment created successfully'
      };
    } catch (error) {
      throw new Error(`Failed to create payment: ${error.message}`);
    }
  }

  // Get payment by ID
  static async getPayment(paymentId, userId) {
    try {
      const payment = await Payment.findById(paymentId);
      
      if (!payment) {
        throw new Error('Payment not found');
      }

      // Check if user is member of the group
      const group = await Group.findById(payment.group_id);
      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to view this payment');
      }

      return payment.toJSON();
    } catch (error) {
      throw new Error(`Failed to get payment: ${error.message}`);
    }
  }

  // Get payment with member details
  static async getPaymentWithDetails(paymentId, userId) {
    try {
      const payment = await Payment.findById(paymentId);
      
      if (!payment) {
        throw new Error('Payment not found');
      }

      // Check if user is member of the group
      const group = await Group.findById(payment.group_id);
      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to view this payment');
      }

      const paymentWithDetails = await Payment.findByIdWithDetails(paymentId);
      return paymentWithDetails;
    } catch (error) {
      throw new Error(`Failed to get payment details: ${error.message}`);
    }
  }

  // Get payments for a group
  static async getGroupPayments(groupId, userId, limit = 10, offset = 0) {
    try {
      // Verify group exists and user is member
      const group = await Group.findById(groupId);
      if (!group) {
        throw new Error('Group not found');
      }

      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to view payments');
      }

      return await Payment.getPaymentsForGroup(groupId, limit, offset);
    } catch (error) {
      throw new Error(`Failed to get group payments: ${error.message}`);
    }
  }

  // Get payments for a user
  static async getUserPayments(userId, limit = 10, offset = 0) {
    try {
      // Verify user exists
      const user = await User.findById(userId);
      if (!user) {
        throw new Error('User not found');
      }

      return await Payment.getPaymentsForUser(userId, limit, offset);
    } catch (error) {
      throw new Error(`Failed to get user payments: ${error.message}`);
    }
  }

  // Get pending payments for a group
  static async getPendingPayments(groupId, userId) {
    try {
      // Verify group exists and user is member
      const group = await Group.findById(groupId);
      if (!group) {
        throw new Error('Group not found');
      }

      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to view payments');
      }

      return await Payment.getPendingPaymentsForGroup(groupId);
    } catch (error) {
      throw new Error(`Failed to get pending payments: ${error.message}`);
    }
  }

  // Update payment status
  static async updatePaymentStatus(paymentId, status, userId) {
    try {
      const payment = await Payment.findById(paymentId);
      
      if (!payment) {
        throw new Error('Payment not found');
      }

      // Check if user is member of the group
      const group = await Group.findById(payment.group_id);
      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to update this payment');
      }

      // Check if user is involved in the payment (from or to)
      const isInvolved = await Payment.isUserInvolvedInPayment(paymentId, userId);
      if (!isInvolved) {
        throw new Error('You can only update payments you are involved in');
      }

      const updatedPayment = await payment.updateStatus(status);
      return updatedPayment.toJSON();
    } catch (error) {
      throw new Error(`Failed to update payment status: ${error.message}`);
    }
  }

  // Update payment details
  static async updatePayment(paymentId, updateData, userId) {
    try {
      const payment = await Payment.findById(paymentId);
      
      if (!payment) {
        throw new Error('Payment not found');
      }

      // Check if user is member of the group
      const group = await Group.findById(payment.group_id);
      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to update this payment');
      }

      // Check if user is involved in the payment (from or to)
      const isInvolved = await Payment.isUserInvolvedInPayment(paymentId, userId);
      if (!isInvolved) {
        throw new Error('You can only update payments you are involved in');
      }

      const updatedPayment = await payment.update(updateData);
      return updatedPayment.toJSON();
    } catch (error) {
      throw new Error(`Failed to update payment: ${error.message}`);
    }
  }

  // Delete payment
  static async deletePayment(paymentId, userId) {
    try {
      const payment = await Payment.findById(paymentId);
      
      if (!payment) {
        throw new Error('Payment not found');
      }

      // Check if user is member of the group
      const group = await Group.findById(payment.group_id);
      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to delete this payment');
      }

      // Check if user is involved in the payment (from or to)
      const isInvolved = await Payment.isUserInvolvedInPayment(paymentId, userId);
      if (!isInvolved) {
        throw new Error('You can only delete payments you are involved in');
      }

      await payment.delete();
      
      return {
        message: 'Payment deleted successfully'
      };
    } catch (error) {
      throw new Error(`Failed to delete payment: ${error.message}`);
    }
  }

  // Get payment summary for a group
  static async getGroupPaymentSummary(groupId, userId) {
    try {
      // Verify group exists and user is member
      const group = await Group.findById(groupId);
      if (!group) {
        throw new Error('Group not found');
      }

      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to view payment summary');
      }

      return await Payment.getPaymentSummaryForGroup(groupId);
    } catch (error) {
      throw new Error(`Failed to get payment summary: ${error.message}`);
    }
  }

  // Get debt relationships for a group
  static async getGroupDebtRelationships(groupId, userId) {
    try {
      // Verify group exists and user is member
      const group = await Group.findById(groupId);
      if (!group) {
        throw new Error('Group not found');
      }

      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to view debt relationships');
      }

      return await Payment.getDebtRelationships(groupId);
    } catch (error) {
      throw new Error(`Failed to get debt relationships: ${error.message}`);
    }
  }

  // Create settlement payments for a group
  static async createSettlementPayments(groupId, userId) {
    try {
      // Verify group exists and user is member
      const group = await Group.findById(groupId);
      if (!group) {
        throw new Error('Group not found');
      }

      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to create settlement payments');
      }

      // Check if user is admin
      const isAdmin = await group.isUserAdmin(userId);
      if (!isAdmin) {
        throw new Error('Only group admins can create settlement payments');
      }

      const payments = await Payment.createSettlementPayments(groupId);
      
      return {
        payments: payments.map(p => p.toJSON()),
        message: `${payments.length} settlement payments created successfully`
      };
    } catch (error) {
      throw new Error(`Failed to create settlement payments: ${error.message}`);
    }
  }

  // Mark payment as completed
  static async markPaymentCompleted(paymentId, userId) {
    try {
      const payment = await Payment.findById(paymentId);
      
      if (!payment) {
        throw new Error('Payment not found');
      }

      // Check if user is member of the group
      const group = await Group.findById(payment.group_id);
      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to update this payment');
      }

      // Check if user is involved in the payment (from or to)
      const isInvolved = await Payment.isUserInvolvedInPayment(paymentId, userId);
      if (!isInvolved) {
        throw new Error('You can only update payments you are involved in');
      }

      const updatedPayment = await payment.markCompleted();
      return updatedPayment.toJSON();
    } catch (error) {
      throw new Error(`Failed to mark payment as completed: ${error.message}`);
    }
  }

  // Mark payment as cancelled
  static async markPaymentCancelled(paymentId, userId) {
    try {
      const payment = await Payment.findById(paymentId);
      
      if (!payment) {
        throw new Error('Payment not found');
      }

      // Check if user is member of the group
      const group = await Group.findById(payment.group_id);
      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to update this payment');
      }

      // Check if user is involved in the payment (from or to)
      const isInvolved = await Payment.isUserInvolvedInPayment(paymentId, userId);
      if (!isInvolved) {
        throw new Error('You can only update payments you are involved in');
      }

      const updatedPayment = await payment.markCancelled();
      return updatedPayment.toJSON();
    } catch (error) {
      throw new Error(`Failed to mark payment as cancelled: ${error.message}`);
    }
  }
}

module.exports = PaymentService; 