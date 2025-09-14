const express = require('express');
const UserController = require('../controllers/userController');
const { authenticateToken } = require('../middleware/auth');
const upload = require('../config/multer');

const router = express.Router();

// Public routes (no authentication required)
router.post('/register', UserController.register);
router.post('/login', UserController.login);
router.post('/verify-token', UserController.verifyToken);

// Protected routes (authentication required)
router.use(authenticateToken); // Apply authentication middleware to all routes below

// User profile routes
router.get('/profile', UserController.getProfile);
router.put('/profile', UserController.updateProfile);
router.put('/password', UserController.updatePassword);

// Profile image upload route
router.post('/profile/avatar', upload.single('avatar'), UserController.uploadProfileImage);

// User dashboard and data routes
router.get('/dashboard', UserController.getDashboard);
router.get('/groups', UserController.getUserGroups);
router.get('/expenses', UserController.getUserExpenses);
router.get('/payment-summary', UserController.getUserPaymentSummary);

// User search and utilities
router.get('/search', UserController.searchUsers);
router.get('/exists', UserController.checkUserExists);
router.get('/stats', UserController.getUserStats);
router.get('/:userId/profile', UserController.getUserById);

// Account management
router.delete('/account', UserController.deleteAccount);

module.exports = router; 