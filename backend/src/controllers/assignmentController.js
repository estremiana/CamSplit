const Assignment = require('../models/Assignment');
const Item = require('../models/Item');

exports.getAssignmentsForBill = async (req, res) => {
  try {
    const billId = req.params.billId;
    const assignments = await Assignment.findByBillId(billId);
    res.status(200).json({ assignments });
  } catch (err) {
    console.error('Get assignments for bill error:', err);
    res.status(500).json({ message: 'Server error while fetching assignments.' });
  }
};

exports.assignItemsToParticipants = async (req, res) => {
  try {
    const { items, participantIds } = req.body;
    if (!Array.isArray(items) || items.length === 0 || !Array.isArray(participantIds) || participantIds.length === 0) {
      return res.status(400).json({ message: 'items and participantIds are required.' });
    }
    const assignments = [];
    for (const itemObj of items) {
      const { itemId, quantity } = itemObj;
      if (!itemId || !quantity) {
        return res.status(400).json({ message: 'Each item must have itemId and quantity.' });
      }
      // Get item info
      const item = await Item.findById(itemId);
      if (!item) {
        return res.status(404).json({ message: `Item with id ${itemId} not found.` });
      }
      if (item.quantity_left < quantity) {
        return res.status(400).json({ message: `Not enough quantity left for item ${itemId}.` });
      }
      // Calculate cost per participant
      const costPerParticipant = (item.unit_price * quantity) / participantIds.length;
      // Upsert assignments for each participant
      for (const participantId of participantIds) {
        const assignment = await Assignment.upsert({
          bill_id: item.bill_id,
          item_id: itemId,
          participant_id: participantId,
          quantity,
          cost_per_person: costPerParticipant
        });
        assignments.push(assignment);
      }
      // Update quantity_left in items
      await Item.update(itemId, { ...item, quantity_left: item.quantity_left - quantity });
    }
    res.status(201).json({ message: 'Assignments created successfully.', assignments });
  } catch (err) {
    console.error('Assign items to participants error:', err);
    res.status(500).json({ message: 'Server error while assigning items.' });
  }
}; 