class ParserService {
  // Parse and validate OCR results for expense creation
  parseReceiptData(ocrData) {
    const parsedData = {
      title: null,
      total_amount: 0,
      date: null,
      merchant: null,
      category: 'Other',
      items: [],
      confidence: ocrData.confidence || 0.5,
      validation: {
        isValid: true,
        warnings: [],
        errors: []
      }
    };

    try {
      // Extract and validate total amount
      if (ocrData.total && ocrData.total > 0) {
        parsedData.total_amount = parseFloat(ocrData.total);
      } else {
        parsedData.validation.errors.push('Total amount not found or invalid');
        parsedData.validation.isValid = false;
      }

      // Extract merchant name
      if (ocrData.merchant) {
        parsedData.merchant = ocrData.merchant.trim();
        parsedData.title = `Receipt from ${parsedData.merchant}`;
      } else {
        parsedData.title = 'Receipt';
        parsedData.validation.warnings.push('Merchant name not found');
      }

      // Extract and validate date
      if (ocrData.date) {
        const parsedDate = this.parseDate(ocrData.date);
        if (parsedDate) {
          parsedData.date = parsedDate;
        } else {
          parsedData.validation.warnings.push('Date format not recognized');
        }
      } else {
        // Use current date if not found
        parsedData.date = new Date().toISOString().split('T')[0];
        parsedData.validation.warnings.push('Date not found, using current date');
      }

      // Extract and validate items
      if (ocrData.items && ocrData.items.length > 0) {
        parsedData.items = this.parseItems(ocrData.items);
        
        // Validate total matches items
        const itemsTotal = parsedData.items.reduce((sum, item) => sum + item.total_price, 0);
        const difference = Math.abs(parsedData.total_amount - itemsTotal);
        
        if (difference > 0.01) { // Allow for small rounding differences
          parsedData.validation.warnings.push(`Items total (${itemsTotal.toFixed(2)}) doesn't match receipt total (${parsedData.total_amount.toFixed(2)})`);
        }
      } else {
        // Create a single item with the total amount
        parsedData.items = [{
          description: 'Receipt total',
          quantity: 1,
          unit_price: parsedData.total_amount,
          total_price: parsedData.total_amount,
          confidence: 0.3 // Low confidence since this is a fallback
        }];
        parsedData.validation.warnings.push('No individual items found, using total as single item');
      }

      // Determine category based on merchant or items
      parsedData.category = this.determineCategory(parsedData.merchant, parsedData.items);

    } catch (error) {
      parsedData.validation.errors.push(`Parsing error: ${error.message}`);
      parsedData.validation.isValid = false;
    }

    return parsedData;
  }

  // Parse individual items from OCR data
  parseItems(items) {
    return items.map(item => {
      const parsedItem = {
        description: item.description || 'Unknown Item',
        quantity: parseInt(item.quantity) || 1,
        unit_price: parseFloat(item.unit_price) || 0,
        total_price: parseFloat(item.total_price) || 0,
        confidence: parseFloat(item.confidence) || 0.5
      };

      // Validate item data
      if (parsedItem.total_price <= 0) {
        parsedItem.total_price = parsedItem.unit_price * parsedItem.quantity;
      }

      if (parsedItem.unit_price <= 0 && parsedItem.total_price > 0) {
        parsedItem.unit_price = parsedItem.total_price / parsedItem.quantity;
      }

      return parsedItem;
    });
  }

  // Parse various date formats
  parseDate(dateString) {
    if (!dateString) return null;

    // If it's already a Date object, convert to string
    if (dateString instanceof Date) {
      return dateString.toISOString().split('T')[0];
    }

    // If it's not a string, try to convert it
    if (typeof dateString !== 'string') {
      try {
        const date = new Date(dateString);
        if (!isNaN(date.getTime())) {
          return date.toISOString().split('T')[0];
        }
      } catch (error) {
        return null;
      }
      return null;
    }

    // Try different date formats
    const dateFormats = [
      /(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})/, // MM/DD/YYYY or MM-DD-YYYY
      /(\d{4})[\/\-](\d{1,2})[\/\-](\d{1,2})/, // YYYY/MM/DD or YYYY-MM-DD
      /(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{2})/, // MM/DD/YY or MM-DD-YY
    ];

    for (const format of dateFormats) {
      const match = dateString.match(format);
      if (match) {
        let year, month, day;
        
        if (match[1].length === 4) {
          // YYYY-MM-DD format
          year = parseInt(match[1]);
          month = parseInt(match[2]) - 1; // Month is 0-indexed
          day = parseInt(match[3]);
        } else {
          // MM-DD-YYYY or MM-DD-YY format
          month = parseInt(match[1]) - 1; // Month is 0-indexed
          day = parseInt(match[2]);
          year = parseInt(match[3]);
          
          // Handle 2-digit years
          if (year < 100) {
            year += year < 50 ? 2000 : 1900;
          }
        }

        const date = new Date(year, month, day);
        if (!isNaN(date.getTime())) {
          return date.toISOString().split('T')[0];
        }
      }
    }

    return null;
  }

  // Determine expense category based on merchant and items
  determineCategory(merchant, items) {
    const merchantLower = (merchant || '').toLowerCase();
    const itemDescriptions = items.map(item => item.description.toLowerCase()).join(' ');

    // Food and dining
    if (merchantLower.includes('restaurant') || merchantLower.includes('cafe') || 
        merchantLower.includes('pizza') || merchantLower.includes('burger') ||
        itemDescriptions.includes('food') || itemDescriptions.includes('meal')) {
      return 'Food & Dining';
    }

    // Transportation
    if (merchantLower.includes('uber') || merchantLower.includes('lyft') || 
        merchantLower.includes('taxi') || merchantLower.includes('gas') ||
        itemDescriptions.includes('fuel') || itemDescriptions.includes('transport')) {
      return 'Transportation';
    }

    // Shopping
    if (merchantLower.includes('walmart') || merchantLower.includes('target') || 
        merchantLower.includes('amazon') || merchantLower.includes('store') ||
        itemDescriptions.includes('clothing') || itemDescriptions.includes('electronics')) {
      return 'Shopping';
    }

    // Entertainment
    if (merchantLower.includes('movie') || merchantLower.includes('theater') || 
        merchantLower.includes('concert') || merchantLower.includes('game') ||
        itemDescriptions.includes('ticket') || itemDescriptions.includes('entertainment')) {
      return 'Entertainment';
    }

    // Utilities
    if (merchantLower.includes('electric') || merchantLower.includes('water') || 
        merchantLower.includes('gas') || merchantLower.includes('utility') ||
        itemDescriptions.includes('bill') || itemDescriptions.includes('service')) {
      return 'Utilities';
    }

    // Healthcare
    if (merchantLower.includes('pharmacy') || merchantLower.includes('medical') || 
        merchantLower.includes('doctor') || merchantLower.includes('hospital') ||
        itemDescriptions.includes('medicine') || itemDescriptions.includes('medical')) {
      return 'Healthcare';
    }

    // Default category
    return 'Other';
  }

  // Validate expense data before creation
  validateExpenseData(expenseData) {
    const validation = {
      isValid: true,
      warnings: [],
      errors: []
    };

    // Validate required fields
    if (!expenseData.title || expenseData.title.trim().length === 0) {
      validation.errors.push('Title is required');
      validation.isValid = false;
    }

    if (!expenseData.total_amount || expenseData.total_amount <= 0) {
      validation.errors.push('Total amount must be greater than 0');
      validation.isValid = false;
    }

    if (!expenseData.date) {
      validation.errors.push('Date is required');
      validation.isValid = false;
    }

    if (!expenseData.group_id) {
      validation.errors.push('Group ID is required');
      validation.isValid = false;
    }

    // Validate payers
    if (!expenseData.payers || expenseData.payers.length === 0) {
      validation.errors.push('At least one payer is required');
      validation.isValid = false;
    } else {
      const payersTotal = expenseData.payers.reduce((sum, payer) => sum + parseFloat(payer.amount_paid), 0);
      const difference = Math.abs(expenseData.total_amount - payersTotal);
      
      if (difference > 0.01) {
        validation.warnings.push(`Payers total (${payersTotal.toFixed(2)}) doesn't match expense total (${expenseData.total_amount.toFixed(2)})`);
      }
    }

    // Validate splits
    if (!expenseData.splits || expenseData.splits.length === 0) {
      validation.errors.push('At least one split is required');
      validation.isValid = false;
    } else {
      const splitsTotal = expenseData.splits.reduce((sum, split) => sum + parseFloat(split.amount_owed), 0);
      const difference = Math.abs(expenseData.total_amount - splitsTotal);
      
      if (difference > 0.01) {
        validation.warnings.push(`Splits total (${splitsTotal.toFixed(2)}) doesn't match expense total (${expenseData.total_amount.toFixed(2)})`);
      }
    }

    return validation;
  }

  // Enhance OCR data with additional context
  enhanceOCRData(ocrData, groupMembers) {
    const enhancedData = { ...ocrData };

    // Add suggested payers based on group members
    enhancedData.suggestedPayers = groupMembers.map(member => ({
      group_member_id: member.id,
      nickname: member.nickname,
      amount_paid: 0,
      suggested: false
    }));

    // Add suggested splits (equal split by default)
    const equalAmount = enhancedData.total_amount / groupMembers.length;
    enhancedData.suggestedSplits = groupMembers.map(member => ({
      group_member_id: member.id,
      nickname: member.nickname,
      amount_owed: equalAmount,
      suggested: true
    }));

    return enhancedData;
  }
}

module.exports = new ParserService(); 