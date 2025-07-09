const cloudinary = require('../config/cloudinary');
const fs = require('fs');
const streamifier = require('streamifier');
const Bill = require('../models/Bill');
const Participant = require('../models/Participant');
const Assignment = require('../models/Assignment');
const Payment = require('../models/Payment');

exports.uploadBill = async (req, res) => {
  try {
    const userId = req.body.user_id; // Or get from auth middleware
    const buffer = req.file.buffer;

    // Create a promise to handle the stream upload
    const streamUpload = (buffer) => {
      return new Promise((resolve, reject) => {
        const stream = cloudinary.uploader.upload_stream(
          { folder: 'bills', resource_type: 'auto' },
          (error, result) => {
            if (result) resolve(result);
            else reject(error);
          }
        );
        streamifier.createReadStream(buffer).pipe(stream);
      });
    };

    const result = await streamUpload(buffer);
    // Insert bill into database using model
    const bill = await Bill.create({ user_id: userId, image_url: result.secure_url });
    // Insert the current user as a participant for the new bill, linked to userId
    await Participant.create({ bill_id: bill.id, name: 'You', user_id: userId });
    res.status(201).json({ bill });
  } catch (err) {
    console.error('Bill upload error:', err);
    res.status(500).json({ message: 'Server error during bill upload.' });
  }
};

exports.getBill = async (req, res) => {
  try {
    const billId = req.params.id;
    const bill = await Bill.getBillWithTotal(billId);
    if (!bill) {
      return res.status(404).json({ message: 'Bill not found.' });
    }
    res.status(200).json({ bill, total: bill.total });
  } catch (err) {
    console.error('Get bill error:', err);
    res.status(500).json({ message: 'Server error during bill retrieval.' });
  }
};

exports.settleBill = async (req, res) => {
  try {
    const billId = req.params.id;
    // Get all participants for the bill
    const participants = await Participant.findByBillId(billId);
    // Get all assignments for the bill
    const assignments = await Assignment.findByBillId(billId);
    // Calculate amount_owed for each participant
    const owedMap = {};
    for (const a of assignments) {
      owedMap[a.participant_id] = (owedMap[a.participant_id] || 0) + Number(a.cost_per_person);
    }
    // Prepare net balances
    const balances = participants.map(p => ({
      participantId: p.id,
      name: p.name,
      amount_paid: Number(p.amount_paid) || 0,
      amount_owed: owedMap[p.id] || 0,
      netBalance: (Number(p.amount_paid) || 0) - (owedMap[p.id] || 0)
    }));
    // Remove previous payments for this bill
    const oldPayments = await Payment.findByBillId(billId);
    for (const payment of oldPayments) {
      await Payment.delete(payment.id);
    }
    // Calculate minimal payments (greedy algorithm)
    const creditors = balances.filter(b => b.netBalance > 0).sort((a, b) => b.netBalance - a.netBalance);
    const debtors = balances.filter(b => b.netBalance < 0).sort((a, b) => a.netBalance - b.netBalance);
    const payments = [];
    let i = 0, j = 0;
    while (i < debtors.length && j < creditors.length) {
      const debtor = debtors[i];
      const creditor = creditors[j];
      const amount = Math.min(-debtor.netBalance, creditor.netBalance);
      if (amount > 0) {
        // Insert payment record using model
        const payment = await Payment.create({
          bill_id: billId,
          from_participant_id: debtor.participantId,
          to_participant_id: creditor.participantId,
          amount
        });
        payments.push(payment);
        // Update balances
        debtor.netBalance += amount;
        creditor.netBalance -= amount;
      }
      if (Math.abs(debtor.netBalance) < 1e-6) i++;
      if (Math.abs(creditor.netBalance) < 1e-6) j++;
    }
    res.status(200).json({
      participants: balances,
      payments: payments.map(p => ({
        from: p.from_participant_id,
        to: p.to_participant_id,
        amount: Number(p.amount),
        is_paid: p.is_paid
      }))
    });
  } catch (err) {
    console.error('Settle bill error:', err);
    res.status(500).json({ message: 'Server error while settling bill.' });
  }
};

exports.createBill = async (req, res) => {
  try {
    const { user_id, image_url } = req.body;
    if (!user_id || !image_url) {
      return res.status(400).json({ message: 'user_id and image_url are required.' });
    }
    const bill = await Bill.create({ user_id, image_url });
    res.status(201).json({ bill });
  } catch (err) {
    console.error('Create bill error:', err);
    res.status(500).json({ message: 'Server error during bill creation.' });
  }
};
