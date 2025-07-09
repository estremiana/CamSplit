const Payment = require('../models/Payment');

exports.markPaymentAsPaid = async (req, res) => {
  try {
    const paymentId = req.params.paymentId;
    const payment = await Payment.markAsPaid(paymentId);
    res.status(200).json({ message: 'Payment marked as paid.', payment });
  } catch (err) {
    console.error('Mark payment as paid error:', err);
    res.status(500).json({ message: 'Server error while marking payment as paid.' });
  }
};

exports.getPaymentsForBill = async (req, res) => {
  try {
    const billId = req.params.billId;
    const payments = await Payment.findByBillId(billId);
    res.status(200).json({ payments });
  } catch (err) {
    console.error('Get payments for bill error:', err);
    res.status(500).json({ message: 'Server error while fetching payments.' });
  }
}; 