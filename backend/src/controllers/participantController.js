const Participant = require('../models/Participant');

exports.addParticipant = async (req, res) => {
  try {
    const billId = req.params.billId;
    const { name, user_id } = req.body;
    if (!name) {
      return res.status(400).json({ message: 'Name is required.' });
    }
    const participant = await Participant.create({ bill_id: billId, name, user_id });
    res.status(201).json({ participant });
  } catch (err) {
    console.error('Add participant error:', err);
    res.status(500).json({ message: 'Server error while adding participant.' });
  }
};

exports.getParticipants = async (req, res) => {
  try {
    const billId = req.params.billId;
    const participants = await Participant.findByBillId(billId);
    res.status(200).json({ participants });
  } catch (err) {
    console.error('Get participants error:', err);
    res.status(500).json({ message: 'Server error while fetching participants.' });
  }
};

exports.setPaymentsForBill = async (req, res) => {
  try {
    const billId = req.params.billId;
    const { payments } = req.body;
    if (!Array.isArray(payments) || payments.length === 0) {
      return res.status(400).json({ message: 'payments array is required.' });
    }
    for (const payment of payments) {
      const { participantId, amount_paid } = payment;
      if (!participantId || amount_paid === undefined) {
        return res.status(400).json({ message: 'Each payment must have participantId and amount_paid.' });
      }
      await Participant.setamount_paid(participantId, amount_paid);
    }
    res.status(200).json({ message: 'Payments updated successfully.' });
  } catch (err) {
    console.error('Set payments for bill error:', err);
    res.status(500).json({ message: 'Server error while setting payments.' });
  }
}; 