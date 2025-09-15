const express = require('express');
const multer = require('multer');
const GroupController = require('../controllers/groupController');
const { authenticateToken, requireGroupMember, requireGroupAdmin } = require('../middleware/auth');

// Configure multer for file uploads
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
  },
  fileFilter: (req, file, cb) => {
    const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type. Only JPEG, PNG, and WebP images are allowed'), false);
    }
  }
});

const router = express.Router();

// All group routes require authentication
router.use(authenticateToken);

// Group CRUD operations
router.post('/', GroupController.createGroup);
router.get('/', GroupController.getUserGroups);
router.get('/search', GroupController.searchGroups);
router.get('/invitable', GroupController.getInvitableGroups);

// Group details (requires group membership)
router.get('/:groupId', requireGroupMember, GroupController.getGroup);
router.get('/:groupId/with-members', requireGroupMember, GroupController.getGroupWithMembers);
router.put('/:groupId', requireGroupAdmin, GroupController.updateGroup);
router.put('/:groupId/image', requireGroupAdmin, upload.single('image'), GroupController.uploadGroupImage);
router.delete('/:groupId', requireGroupAdmin, GroupController.deleteGroup);
router.delete('/:groupId/cascade', requireGroupAdmin, GroupController.deleteGroupWithCascade);

// Group exit (requires group membership)
router.post('/:groupId/exit', requireGroupMember, GroupController.exitGroup);

// Group auto-delete check (requires group membership)
router.get('/:groupId/auto-delete-status', requireGroupMember, GroupController.checkGroupAutoDelete);

// Group members (requires group membership)
router.get('/:groupId/members', requireGroupMember, GroupController.getGroupMembers);
router.post('/:groupId/members', requireGroupMember, GroupController.addMember);
router.delete('/:groupId/members/:memberId', requireGroupAdmin, GroupController.removeMember);
router.put('/:groupId/members/:memberId/claim', requireGroupMember, GroupController.claimMember);

// Group invitations (requires group membership)
router.post('/:groupId/invite', requireGroupMember, GroupController.inviteUserToGroup);

// Group expenses (requires group membership)
router.get('/:groupId/expenses', requireGroupMember, GroupController.getGroupExpenses);

// Group payment summary (requires group membership)
router.get('/:groupId/payment-summary', requireGroupMember, GroupController.getGroupPaymentSummary);

// Group user balance (requires group membership)
router.get('/:groupId/user-balance', requireGroupMember, GroupController.getUserBalanceForGroup);

// Group statistics (requires group membership)
router.get('/:groupId/stats', requireGroupMember, GroupController.getGroupStats);

// Group permissions (requires group membership)
router.get('/:groupId/permissions', requireGroupMember, GroupController.checkGroupPermission);

module.exports = router; 