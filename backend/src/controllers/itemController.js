const ItemService = require('../services/itemService');

class ItemController {
  // Create item for an expense
  static async createItem(req, res) {
    try {
      const { expenseId } = req.params;
      const itemData = {
        ...req.body,
        expense_id: parseInt(expenseId)
      };

      const result = await ItemService.createItem(itemData, req.user.id);

      res.status(201).json({
        success: true,
        message: result.message,
        data: result.item
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Get items for an expense
  static async getExpenseItems(req, res) {
    try {
      const { expenseId } = req.params;
      const result = await ItemService.getExpenseItems(parseInt(expenseId), req.user.id);
      
      res.json({
        success: true,
        data: result
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Get specific item
  static async getItem(req, res) {
    try {
      const { itemId } = req.params;
      const result = await ItemService.getItem(parseInt(itemId), req.user.id);

      res.status(200).json({
        success: true,
        message: result.message,
        data: result.item
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Update item
  static async updateItem(req, res) {
    try {
      const { itemId } = req.params;
      const updateData = req.body;

      const result = await ItemService.updateItem(parseInt(itemId), updateData, req.user.id);

      res.status(200).json({
        success: true,
        message: result.message,
        data: result.item
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Delete item
  static async deleteItem(req, res) {
    try {
      const { itemId } = req.params;
      const result = await ItemService.deleteItem(parseInt(itemId), req.user.id);

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

  // Create items from OCR data
  static async createItemsFromOCR(req, res) {
    try {
      const { expenseId } = req.params;
      const { items: ocrItems } = req.body;

      if (!ocrItems || !Array.isArray(ocrItems)) {
        return res.status(400).json({
          success: false,
          message: 'OCR items array is required'
        });
      }

      const result = await ItemService.createItemsFromOCR(parseInt(expenseId), ocrItems, req.user.id);

      res.status(201).json({
        success: true,
        message: result.message,
        data: result.items
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Get item statistics for an expense
  static async getItemStats(req, res) {
    try {
      const { expenseId } = req.params;
      const result = await ItemService.getItemStats(parseInt(expenseId), req.user.id);

      res.status(200).json({
        success: true,
        message: result.message,
        data: result.stats
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Search items by name
  static async searchItems(req, res) {
    try {
      const { expenseId } = req.params;
      const { q: searchTerm } = req.query;

      if (!searchTerm || searchTerm.trim().length === 0) {
        return res.status(400).json({
          success: false,
          message: 'Search term is required'
        });
      }

      const result = await ItemService.searchItems(parseInt(expenseId), searchTerm.trim(), req.user.id);

      res.status(200).json({
        success: true,
        message: result.message,
        data: result.items
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }
}

module.exports = ItemController; 