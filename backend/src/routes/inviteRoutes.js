const express = require('express');
const router = express.Router();
const InviteController = require('../controllers/inviteController');
const { authenticateToken } = require('../middleware/auth');

// Public routes (no authentication required)
router.get('/:inviteCode', InviteController.getInviteDetails);
router.get('/:inviteCode/members', InviteController.getAvailableMembers);

// Authenticated routes
router.use(authenticateToken);

// Generate invite link for a group
router.post('/groups/:groupId/generate', InviteController.generateInviteLink);

// Join group via invite
router.post('/:inviteCode/join/claim', InviteController.joinByClaimingMember);
router.post('/:inviteCode/join/create', InviteController.joinByCreatingMember);

// Manage invites
router.get('/groups/:groupId/invites', InviteController.getGroupInvites);
router.put('/invites/:inviteId/deactivate', InviteController.deactivateInvite);

module.exports = router; 