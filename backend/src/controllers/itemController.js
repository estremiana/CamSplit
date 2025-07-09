const Item = require('../models/Item');

exports.addItemsToBill = async (req, res) => {
  try {
    const billId = req.params.billId;
    const { items } = req.body;
    if (!Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ message: 'Items array is required.' });
    }
    const insertedItems = [];
    for (const item of items) {
      const { description, quantity, unit_price, total_price } = item;
      if (!description || !quantity || !unit_price || !total_price) {
        return res.status(400).json({ message: 'Each item must have description, quantity, unit_price, and total_price.' });
      }
      const newItem = await Item.create({
        bill_id: billId,
        name: description,
        unit_price,
        total_price,
        quantity,
        quantity_left: quantity
      });
      insertedItems.push(newItem);
    }
    res.status(201).json({ message: 'Items added successfully.', items: insertedItems });
  } catch (err) {
    console.error('Add items to bill error:', err);
    res.status(500).json({ message: 'Server error while adding items.' });
  }
};

exports.getItemsForBill = async (req, res) => {
  try {
    const billId = req.params.billId;
    const items = await Item.findByBillId(billId);
    res.status(200).json({ items });
  } catch (err) {
    console.error('Get items for bill error:', err);
    res.status(500).json({ message: 'Server error while fetching items.' });
  }
}; 