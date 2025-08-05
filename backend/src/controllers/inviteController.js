const InviteService = require('../services/inviteService');

class InviteController {
  // Generate invite link for a group
  static async generateInviteLink(req, res) {
    try {
      const { groupId } = req.params;
      const userId = req.user.id;
      const { expiresAt, maxUses } = req.body;

      const options = {};
      if (expiresAt) options.expiresAt = new Date(expiresAt);
      if (maxUses) options.maxUses = parseInt(maxUses);

      const result = await InviteService.generateInviteLink(groupId, userId, options);

      res.status(201).json({
        success: true,
        message: 'Invite link generated successfully',
        data: {
          invite: result.invite,
          inviteUrl: result.inviteUrl,
          expiresAt: result.expiresAt
        }
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Get invite details (public endpoint - no auth required)
  static async getInviteDetails(req, res) {
    try {
      const { inviteCode } = req.params;

      const result = await InviteService.getInviteDetails(inviteCode);

      res.status(200).json({
        success: true,
        data: {
          invite: result.invite,
          isValid: result.isValid,
          groupName: result.groupName,
          groupDescription: result.groupDescription
        }
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Get available members for claiming (public endpoint - no auth required)
  static async getAvailableMembers(req, res) {
    try {
      const { inviteCode } = req.params;

      const members = await InviteService.getAvailableMembers(inviteCode);

      res.status(200).json({
        success: true,
        data: {
          members
        }
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Join group by claiming existing member
  static async joinByClaimingMember(req, res) {
    try {
      const { inviteCode } = req.params;
      const userId = req.user.id;
      const { memberId } = req.body;

      if (!memberId) {
        return res.status(400).json({
          success: false,
          message: 'Member ID is required'
        });
      }

      const result = await InviteService.joinByClaimingMember(inviteCode, userId, memberId);

      res.status(200).json({
        success: true,
        message: result.message,
        data: {
          member: result.member
        }
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Join group by creating new member
  static async joinByCreatingMember(req, res) {
    try {
      const { inviteCode } = req.params;
      const userId = req.user.id;
      const { nickname, email } = req.body;

      if (!nickname) {
        return res.status(400).json({
          success: false,
          message: 'Nickname is required'
        });
      }

      const memberData = { nickname, email };

      const result = await InviteService.joinByCreatingMember(inviteCode, userId, memberData);

      res.status(200).json({
        success: true,
        message: result.message,
        data: {
          member: result.member
        }
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Get all invites for a group
  static async getGroupInvites(req, res) {
    try {
      const { groupId } = req.params;
      const userId = req.user.id;

      const invites = await InviteService.getGroupInvites(groupId, userId);

      res.status(200).json({
        success: true,
        data: {
          invites
        }
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Deactivate invite
  static async deactivateInvite(req, res) {
    try {
      const { inviteId } = req.params;
      const userId = req.user.id;

      const invite = await InviteService.deactivateInvite(inviteId, userId);

      res.status(200).json({
        success: true,
        message: 'Invite deactivated successfully',
        data: {
          invite
        }
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }
}

module.exports = InviteController; 