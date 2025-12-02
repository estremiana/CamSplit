const Item = require('../models/Item');
const Expense = require('../models/Expense');
const Group = require('../models/Group');
const User = require('../models/User');
const db = require('../../database/connection');
const Assignment = require('../models/Assignment');
const UserService = require('./userService');

class ItemService {
  // Create item for an expense
  static async createItem(itemData, userId) {
    try {
      // Verify user exists
      const user = await User.findById(userId);
      if (!user) {
        throw new Error('User not found');
      }

      // Verify expense exists and user has access
      const expense = await Expense.findById(itemData.expense_id);
      if (!expense) {
        throw new Error('Expense not found');
      }

      // Check if user is member of the expense's group
      const group = await Group.findById(expense.group_id);
      if (!group) {
        throw new Error('Group not found');
      }

      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to add items');
      }

      // Create the item
      const item = await Item.create(itemData);

      return {
        item: item.toJSON(),
        message: 'Item created successfully'
      };
    } catch (error) {
      throw new Error(`Failed to create item: ${error.message}`);
    }
  }

  // Get items for an expense
  static async getExpenseItems(expenseId, userId) {
    try {
      // Verify user exists
      const user = await UserService.getUserById(userId);
      if (!user) {
        throw new Error('User not found');
      }

      // Get expense and verify it exists
      const expense = await Expense.findById(expenseId);
      if (!expense) {
        throw new Error('Expense not found');
      }

      // Verify user is member of the group
      const group = await Group.findById(expense.group_id);
      if (!group) {
        throw new Error('Group not found');
      }

      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('User is not a member of this group');
      }

      // Get items for the expense
      const items = await Item.findByExpenseId(expenseId);
      
      // For each item, get its assignments
      const itemsWithAssignments = await Promise.all(
        items.map(async (item) => {
          const assignments = await Assignment.findByItemId(item.id);
          return {
            ...item.toJSON(),
            assignments: assignments  // Already includes assigned_users, don't call toJSON()
          };
        })
      );

      return {
        expense: expense.toJSON(),
        items: itemsWithAssignments
      };
    } catch (error) {
      throw new Error(`Failed to get expense items: ${error.message}`);
    }
  }

  // Get specific item
  static async getItem(itemId, userId) {
    try {
      // Verify user exists
      const user = await User.findById(userId);
      if (!user) {
        throw new Error('User not found');
      }

      // Get item
      const item = await Item.findById(itemId);
      if (!item) {
        throw new Error('Item not found');
      }

      // Verify expense exists and user has access
      const expense = await Expense.findById(item.expense_id);
      if (!expense) {
        throw new Error('Expense not found');
      }

      // Check if user is member of the expense's group
      const group = await Group.findById(expense.group_id);
      if (!group) {
        throw new Error('Group not found');
      }

      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to view this item');
      }

      // Get assignments for this item
      const assignments = await item.getAssignments();
      const remainingQuantity = await item.getRemainingQuantity();

      return {
        item: {
          ...item.toJSON(),
          assignments,
          remaining_quantity: remainingQuantity
        },
        message: 'Item retrieved successfully'
      };
    } catch (error) {
      throw new Error(`Failed to get item: ${error.message}`);
    }
  }

  // Update item
  static async updateItem(itemId, updateData, userId) {
    try {
      // Verify user exists
      const user = await User.findById(userId);
      if (!user) {
        throw new Error('User not found');
      }

      // Get item
      const item = await Item.findById(itemId);
      if (!item) {
        throw new Error('Item not found');
      }

      // Verify expense exists and user has access
      const expense = await Expense.findById(item.expense_id);
      if (!expense) {
        throw new Error('Expense not found');
      }

      // Check if user is member of the expense's group
      const group = await Group.findById(expense.group_id);
      if (!group) {
        throw new Error('Group not found');
      }

      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to update items');
      }

      // Check if item has assignments that would be affected by quantity changes
      if (updateData.max_quantity !== undefined) {
        const assignments = await item.getAssignments();
        const totalAssignedQuantity = assignments.reduce((sum, assignment) => sum + parseFloat(assignment.quantity), 0);
        
        if (updateData.max_quantity < totalAssignedQuantity) {
          throw new Error(`Cannot reduce max quantity below ${totalAssignedQuantity} (already assigned)`);
        }
      }

      // Update the item
      const updatedItem = await item.update(updateData);

      return {
        item: updatedItem.toJSON(),
        message: 'Item updated successfully'
      };
    } catch (error) {
      throw new Error(`Failed to update item: ${error.message}`);
    }
  }

  // Delete item
  static async deleteItem(itemId, userId) {
    try {
      // Verify user exists
      const user = await User.findById(userId);
      if (!user) {
        throw new Error('User not found');
      }

      // Get item
      const item = await Item.findById(itemId);
      if (!item) {
        throw new Error('Item not found');
      }

      // Verify expense exists and user has access
      const expense = await Expense.findById(item.expense_id);
      if (!expense) {
        throw new Error('Expense not found');
      }

      // Check if user is member of the expense's group
      const group = await Group.findById(expense.group_id);
      if (!group) {
        throw new Error('Group not found');
      }

      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to delete items');
      }

      // Check if item has assignments
      const assignments = await item.getAssignments();
      if (assignments.length > 0) {
        throw new Error('Cannot delete item with existing assignments. Please remove assignments first.');
      }

      // Delete the item
      await item.delete();

      return {
        message: 'Item deleted successfully'
      };
    } catch (error) {
      throw new Error(`Failed to delete item: ${error.message}`);
    }
  }

  // Create items from OCR data
  static async createItemsFromOCR(expenseId, ocrItems, userId) {
    try {
      // Verify user exists
      const user = await User.findById(userId);
      if (!user) {
        throw new Error('User not found');
      }

      // Verify expense exists and user has access
      const expense = await Expense.findById(expenseId);
      if (!expense) {
        throw new Error('Expense not found');
      }

      // Check if user is member of the expense's group
      const group = await Group.findById(expense.group_id);
      if (!group) {
        throw new Error('Group not found');
      }

      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to add items');
      }

      // Create items from OCR data
      const createdItems = [];
      for (const ocrItem of ocrItems) {
        const itemData = {
          expense_id: expenseId,
          name: ocrItem.name,
          description: ocrItem.description,
          unit_price: ocrItem.unit_price,
          max_quantity: ocrItem.quantity || 1,
          category: ocrItem.category || 'Other'
        };

        const item = await Item.create(itemData);
        createdItems.push(item.toJSON());
      }

      return {
        items: createdItems,
        message: `${createdItems.length} items created from OCR data`
      };
    } catch (error) {
      throw new Error(`Failed to create items from OCR: ${error.message}`);
    }
  }

  // Get item statistics for an expense
  static async getItemStats(expenseId, userId) {
    try {
      // Verify user exists
      const user = await User.findById(userId);
      if (!user) {
        throw new Error('User not found');
      }

      // Verify expense exists and user has access
      const expense = await Expense.findById(expenseId);
      if (!expense) {
        throw new Error('Expense not found');
      }

      // Check if user is member of the expense's group
      const group = await Group.findById(expense.group_id);
      if (!group) {
        throw new Error('Group not found');
      }

      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to view item statistics');
      }

      // Get items with assignments
      const items = await Item.findByExpenseIdWithAssignments(expenseId);

      // Calculate statistics
      const stats = {
        total_items: items.length,
        total_assigned_items: 0,
        total_unassigned_items: 0,
        total_assigned_quantity: 0,
        total_available_quantity: 0,
        categories: {}
      };

      for (const item of items) {
        const itemInstance = new Item(item);
        const remainingQuantity = await itemInstance.getRemainingQuantity();
        
        stats.total_available_quantity += item.max_quantity;
        stats.total_assigned_quantity += (item.max_quantity - remainingQuantity);
        
        if (item.assignments && item.assignments.length > 0) {
          stats.total_assigned_items++;
        } else {
          stats.total_unassigned_items++;
        }

        // Count categories
        const category = item.category || 'Other';
        stats.categories[category] = (stats.categories[category] || 0) + 1;
      }

      return {
        stats,
        message: 'Item statistics retrieved successfully'
      };
    } catch (error) {
      throw new Error(`Failed to get item statistics: ${error.message}`);
    }
  }

  // Search items by name
  static async searchItems(expenseId, searchTerm, userId) {
    try {
      // Verify user exists
      const user = await User.findById(userId);
      if (!user) {
        throw new Error('User not found');
      }

      // Verify expense exists and user has access
      const expense = await Expense.findById(expenseId);
      if (!expense) {
        throw new Error('Expense not found');
      }

      // Check if user is member of the expense's group
      const group = await Group.findById(expense.group_id);
      if (!group) {
        throw new Error('Group not found');
      }

      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to search items');
      }

      // Search items
      const query = `
        SELECT * FROM items 
        WHERE expense_id = $1 AND name ILIKE $2
        ORDER BY name ASC
      `;
      
      const result = await db.query(query, [expenseId, `%${searchTerm}%`]);
      const items = result.rows.map(row => new Item(row));

      return {
        items: items.map(item => item.toJSON()),
        message: `Found ${items.length} items matching "${searchTerm}"`
      };
    } catch (error) {
      throw new Error(`Failed to search items: ${error.message}`);
    }
  }
}

module.exports = ItemService; 