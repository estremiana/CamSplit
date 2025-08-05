const Settlement = require('../models/Settlement');

class SettlementUpdateService {
  // Debounce timers for each group
  static debounceTimers = new Map();
  
  // Default debounce delay in milliseconds
  static DEBOUNCE_DELAY = 500;

  /**
   * Trigger settlement recalculation with debouncing
   * @param {number} groupId - Group ID to recalculate settlements for
   * @param {string} changeType - Type of change that triggered recalculation
   * @param {Object} options - Additional options
   */
  static triggerRecalculation(groupId, changeType = 'expense_change', options = {}) {
    const { delay = this.DEBOUNCE_DELAY, immediate = false } = options;

    // If immediate recalculation is requested, clear any pending timer and execute
    if (immediate) {
      if (this.debounceTimers.has(groupId)) {
        clearTimeout(this.debounceTimers.get(groupId));
        this.debounceTimers.delete(groupId);
      }
      return this.executeRecalculation(groupId, changeType);
    }

    // Clear existing timer for this group
    if (this.debounceTimers.has(groupId)) {
      clearTimeout(this.debounceTimers.get(groupId));
    }

    // Set new debounced timer
    const timer = setTimeout(async () => {
      try {
        await this.executeRecalculation(groupId, changeType);
        this.debounceTimers.delete(groupId);
      } catch (error) {
        console.error(`Failed to recalculate settlements for group ${groupId}:`, error);
        this.debounceTimers.delete(groupId);
      }
    }, delay);

    this.debounceTimers.set(groupId, timer);

    return Promise.resolve({
      scheduled: true,
      groupId,
      changeType,
      delay
    });
  }

  /**
   * Execute settlement recalculation
   * @param {number} groupId - Group ID to recalculate settlements for
   * @param {string} changeType - Type of change that triggered recalculation
   */
  static async executeRecalculation(groupId, changeType) {
    try {
      console.log(`Recalculating settlements for group ${groupId} due to ${changeType}`);

      // Recalculate settlements
      const result = await Settlement.recalculateSettlements(groupId, {
        cleanupObsoleteAfterDays: 7 // Clean up old obsolete settlements
      });

      console.log(`Settlement recalculation completed for group ${groupId}:`, {
        settlements_count: result.settlements.length,
        total_amount: result.summary.total_amount,
        members_involved: result.summary.members_involved
      });

      // Broadcast update if needed (for future WebSocket implementation)
      this.broadcastSettlementUpdate(groupId, result.settlements, changeType);

      return result;
    } catch (error) {
      console.error(`Settlement recalculation failed for group ${groupId}:`, error);
      throw error;
    }
  }

  /**
   * Schedule recalculation with custom delay
   * @param {number} groupId - Group ID to recalculate settlements for
   * @param {number} delay - Delay in milliseconds
   * @param {string} changeType - Type of change that triggered recalculation
   */
  static scheduleRecalculation(groupId, delay, changeType = 'scheduled') {
    return this.triggerRecalculation(groupId, changeType, { delay });
  }

  /**
   * Broadcast settlement update (placeholder for future WebSocket implementation)
   * @param {number} groupId - Group ID
   * @param {Array} settlements - Updated settlements
   * @param {string} changeType - Type of change
   */
  static broadcastSettlementUpdate(groupId, settlements, changeType) {
    // Placeholder for WebSocket broadcasting
    // In the future, this could emit real-time updates to connected clients
    console.log(`Broadcasting settlement update for group ${groupId}:`, {
      changeType,
      settlements_count: settlements.length,
      timestamp: new Date().toISOString()
    });

    // For now, we could store this in a cache or queue for polling-based updates
    this.storeUpdateNotification(groupId, {
      type: 'settlement_update',
      changeType,
      settlements_count: settlements.length,
      timestamp: new Date().toISOString()
    });
  }

  /**
   * Store update notification for polling-based updates
   * @param {number} groupId - Group ID
   * @param {Object} notification - Notification data
   */
  static storeUpdateNotification(groupId, notification) {
    // This could be implemented with Redis or in-memory cache
    // For now, it's just a placeholder
    console.log(`Stored update notification for group ${groupId}:`, notification);
  }

  /**
   * Handle expense creation event
   * @param {Object} expense - Created expense
   */
  static async handleExpenseCreated(expense) {
    if (expense.group_id) {
      await this.triggerRecalculation(expense.group_id, 'expense_created', {
        delay: 1000 // Slightly longer delay for creation to allow for splits/payers to be added
      });
    }
  }

  /**
   * Handle expense update event
   * @param {Object} expense - Updated expense
   * @param {Object} changes - Changes made to the expense
   */
  static async handleExpenseUpdated(expense, changes = {}) {
    if (expense.group_id) {
      // Immediate recalculation if amount or splits changed
      const immediateChanges = ['amount', 'splits', 'payers'];
      const needsImmediate = Object.keys(changes).some(key => immediateChanges.includes(key));

      await this.triggerRecalculation(expense.group_id, 'expense_updated', {
        immediate: needsImmediate,
        delay: needsImmediate ? 0 : 500
      });
    }
  }

  /**
   * Handle expense deletion event
   * @param {Object} expense - Deleted expense
   */
  static async handleExpenseDeleted(expense) {
    if (expense.group_id) {
      await this.triggerRecalculation(expense.group_id, 'expense_deleted', {
        immediate: true // Immediate recalculation for deletions
      });
    }
  }

  /**
   * Handle expense payer changes
   * @param {number} expenseId - Expense ID
   * @param {number} groupId - Group ID
   * @param {Array} changes - Payer changes
   */
  static async handlePayerChanges(expenseId, groupId, changes = []) {
    if (groupId) {
      await this.triggerRecalculation(groupId, 'payer_updated', {
        immediate: changes.length > 0 // Immediate if there are actual changes
      });
    }
  }

  /**
   * Handle expense split changes
   * @param {number} expenseId - Expense ID
   * @param {number} groupId - Group ID
   * @param {Array} changes - Split changes
   */
  static async handleSplitChanges(expenseId, groupId, changes = []) {
    if (groupId) {
      await this.triggerRecalculation(groupId, 'split_updated', {
        immediate: changes.length > 0 // Immediate if there are actual changes
      });
    }
  }

  /**
   * Handle settlement processing event
   * @param {Object} settlement - Processed settlement
   */
  static async handleSettlementProcessed(settlement) {
    if (settlement.group_id) {
      // Immediate recalculation after settlement processing
      await this.triggerRecalculation(settlement.group_id, 'settlement_processed', {
        immediate: true
      });
    }
  }

  /**
   * Get pending recalculations
   * @returns {Array} Array of group IDs with pending recalculations
   */
  static getPendingRecalculations() {
    return Array.from(this.debounceTimers.keys());
  }

  /**
   * Cancel pending recalculation for a group
   * @param {number} groupId - Group ID
   */
  static cancelRecalculation(groupId) {
    if (this.debounceTimers.has(groupId)) {
      clearTimeout(this.debounceTimers.get(groupId));
      this.debounceTimers.delete(groupId);
      return true;
    }
    return false;
  }

  /**
   * Force immediate recalculation for a group
   * @param {number} groupId - Group ID
   * @param {string} reason - Reason for forced recalculation
   */
  static async forceRecalculation(groupId, reason = 'manual') {
    return await this.triggerRecalculation(groupId, reason, { immediate: true });
  }

  /**
   * Get recalculation statistics
   * @returns {Object} Statistics about recalculation service
   */
  static getStatistics() {
    return {
      pending_recalculations: this.debounceTimers.size,
      pending_groups: Array.from(this.debounceTimers.keys()),
      debounce_delay: this.DEBOUNCE_DELAY,
      service_status: 'active'
    };
  }

  /**
   * Cleanup service (for graceful shutdown)
   */
  static cleanup() {
    // Clear all pending timers
    for (const timer of this.debounceTimers.values()) {
      clearTimeout(timer);
    }
    this.debounceTimers.clear();
    console.log('SettlementUpdateService cleanup completed');
  }
}

// Graceful shutdown handling
process.on('SIGTERM', () => {
  SettlementUpdateService.cleanup();
});

process.on('SIGINT', () => {
  SettlementUpdateService.cleanup();
});

module.exports = SettlementUpdateService;