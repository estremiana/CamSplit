const express = require('express');
const cors = require('cors');
require('dotenv').config();

const userRoutes = require('./routes/userRoutes');
const billRoutes = require('./routes/billRoutes');
const assignmentRoutes = require('./routes/assignmentRoutes');
const ocrRoutes = require('./routes/ocrRoutes');
const itemRoutes = require('./routes/itemRoutes');
const participantRoutes = require('./routes/participantRoutes');
const paymentsRoutes = require('./routes/paymentsRoutes');

const app = express();
app.use(cors());
app.use(express.json());

app.use('/api/users', userRoutes);
app.use('/api/bills', billRoutes);
app.use('/api/assignments', assignmentRoutes);
app.use('/api/ocr', ocrRoutes);
app.use('/api', itemRoutes);
app.use('/api', participantRoutes);
app.use('/api', paymentsRoutes);

module.exports = app; // Export the app for testing

// Only start the server if this file is run directly
if (require.main === module) {
  const PORT = process.env.PORT || 5000;
  app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
  });
} 