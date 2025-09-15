const GroupService = require('../services/groupService');
const UserService = require('../services/userService');

class GroupController {
  // Create a new group
  static async createGroup(req, res) {
    try {
      const userId = req.user.id;
      const { name, description, image_url, currency } = req.body;

      // Validate required fields
      if (!name) {
        return res.status(400).json({
          success: false,
          message: 'Group name is required'
        });
      }

      const result = await GroupService.createGroup({
        name,
        description,
        image_url,
        currency
      }, userId);

      res.status(201).json({
        success: true,
        message: result.message,
        data: result.group
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Get group by ID
  static async getGroup(req, res) {
    try {
      const { groupId } = req.params;
      const group = await GroupService.getGroup(groupId);

      res.status(200).json({
        success: true,
        data: group
      });
    } catch (error) {
      res.status(404).json({
        success: false,
        message: error.message
      });
    }
  }

  // Get group with members
  static async getGroupWithMembers(req, res) {
    try {
      const { groupId } = req.params;
      const groupWithMembers = await GroupService.getGroupWithMembers(groupId);

      res.status(200).json({
        success: true,
        data: groupWithMembers
      });
    } catch (error) {
      res.status(404).json({
        success: false,
        message: error.message
      });
    }
  }

  // Get user's groups
  static async getUserGroups(req, res) {
    try {
      const userId = req.user.id;
      const groups = await GroupService.getUserGroups(userId);

      res.status(200).json({
        success: true,
        data: groups
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  // Update group
  static async updateGroup(req, res) {
    try {
      const { groupId } = req.params;
      const userId = req.user.id;
      const { name, description, image_url, currency } = req.body;

      const updatedGroup = await GroupService.updateGroup(groupId, {
        name,
        description,
        image_url,
        currency
      }, userId);

      res.status(200).json({
        success: true,
        message: 'Group updated successfully',
        data: updatedGroup
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Delete group
  static async deleteGroup(req, res) {
    try {
      const { groupId } = req.params;
      const userId = req.user.id;

      const result = await GroupService.deleteGroup(groupId, userId);

      res.status(200).json({
        success: true,
        message: result.message
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Add member to group
  static async addMember(req, res) {
    try {
      const { groupId } = req.params;
      const userId = req.user.id;
      const { user_id, nickname, email, role } = req.body;

      // Validate required fields
      if (!nickname) {
        return res.status(400).json({
          success: false,
          message: 'Nickname is required'
        });
      }

      const result = await GroupService.addMember(groupId, {
        user_id,
        nickname,
        email,
        role
      }, userId);

      res.status(201).json({
        success: true,
        message: result.message,
        data: result.member
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Remove member from group
  static async removeMember(req, res) {
    try {
      const { groupId, memberId } = req.params;
      const userId = req.user.id;

      const result = await GroupService.removeMember(groupId, memberId, userId);

      res.status(200).json({
        success: true,
        message: result.message,
        data: result.member
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Claim member (link non-user member to user account)
  static async claimMember(req, res) {
    try {
      const { groupId, memberId } = req.params;
      const userId = req.user.id;

      const result = await GroupService.claimMember(groupId, memberId, userId);

      res.status(200).json({
        success: true,
        message: result.message,
        data: result.member
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Get group members
  static async getGroupMembers(req, res) {
    try {
      const { groupId } = req.params;
      const userId = req.user.id;

      const members = await GroupService.getGroupMembers(groupId, userId);

      res.status(200).json({
        success: true,
        data: members
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  // Get group expenses
  static async getGroupExpenses(req, res) {
    try {
      const { groupId } = req.params;
      const userId = req.user.id;
      const { limit = 10, offset = 0 } = req.query;

      const expenses = await GroupService.getGroupExpenses(groupId, userId, parseInt(limit), parseInt(offset));

      res.status(200).json({
        success: true,
        data: expenses
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  // Get group payment summary
  static async getGroupPaymentSummary(req, res) {
    try {
      const { groupId } = req.params;
      const userId = req.user.id;

      const paymentSummary = await GroupService.getGroupPaymentSummary(groupId, userId);

      res.status(200).json({
        success: true,
        data: paymentSummary
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  // Get user balance for a specific group
  static async getUserBalanceForGroup(req, res) {
    try {
      const { groupId } = req.params;
      const userId = req.user.id;

      const userBalance = await GroupService.getUserBalanceForGroup(groupId, userId);

      res.status(200).json({
        success: true,
        data: userBalance
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  // Search groups
  static async searchGroups(req, res) {
    try {
      const userId = req.user.id;
      const { q, limit = 10 } = req.query;

      if (!q) {
        return res.status(400).json({
          success: false,
          message: 'Search query is required'
        });
      }

      const groups = await GroupService.searchGroups(q, userId, parseInt(limit));

      res.status(200).json({
        success: true,
        data: groups
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  // Get group statistics
  static async getGroupStats(req, res) {
    try {
      const { groupId } = req.params;
      const userId = req.user.id;

      const stats = await GroupService.getGroupStats(groupId, userId);

      res.status(200).json({
        success: true,
        data: stats
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  // Invite user to group
  static async inviteUserToGroup(req, res) {
    try {
      const { groupId } = req.params;
      const userId = req.user.id;
      const { email, nickname } = req.body;

      // Validate required fields
      if (!nickname) {
        return res.status(400).json({
          success: false,
          message: 'Nickname is required'
        });
      }

      const result = await GroupService.inviteUserToGroup(groupId, email, nickname, userId);

      res.status(201).json({
        success: true,
        message: result.message,
        data: {
          member: result.member,
          is_registered_user: result.is_registered_user
        }
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Get invitable groups
  static async getInvitableGroups(req, res) {
    try {
      const userId = req.user.id;

      const groups = await GroupService.getInvitableGroups(userId);

      res.status(200).json({
        success: true,
        data: groups
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  // Check group permission
  static async checkGroupPermission(req, res) {
    try {
      const { groupId } = req.params;
      const userId = req.user.id;
      const { action } = req.query;

      if (!action) {
        return res.status(400).json({
          success: false,
          message: 'Action is required'
        });
      }

      const permission = await GroupService.checkGroupPermission(groupId, userId, action);

      res.status(200).json({
        success: true,
        data: permission
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  // Delete group with cascading deletes
  static async deleteGroupWithCascade(req, res) {
    try {
      const { groupId } = req.params;
      const userId = req.user.id;

      console.log(`DeleteGroupWithCascade: groupId=${groupId}, userId=${userId}`);

      const result = await GroupService.deleteGroupWithCascade(groupId, userId);

      res.status(200).json({
        success: true,
        message: result.message
      });
    } catch (error) {
      console.error('DeleteGroupWithCascade error:', error);
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Exit group (for regular members)
  static async exitGroup(req, res) {
    try {
      const { groupId } = req.params;
      const userId = req.user.id;

      const result = await GroupService.exitGroup(groupId, userId);

      res.status(200).json({
        success: true,
        message: result.message,
        data: {
          action: result.action
        }
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Check group auto-delete status
  static async checkGroupAutoDelete(req, res) {
    try {
      const { groupId } = req.params;
      const userId = req.user.id;

      // Verify user is a member of the group
      const group = await GroupService.getGroup(groupId);
      if (!group) {
        return res.status(404).json({
          success: false,
          message: 'Group not found'
        });
      }

      const shouldAutoDelete = await GroupService.checkGroupAutoDelete(groupId);

      res.status(200).json({
        success: true,
        data: {
          shouldAutoDelete
        }
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  // Upload group image
  static async uploadGroupImage(req, res) {
    try {
      const { groupId } = req.params;
      const userId = req.user.id;
      
      if (!req.file) {
        return res.status(400).json({
          success: false,
          message: 'No image file provided'
        });
      }

      // Validate file type
      const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
      if (!allowedTypes.includes(req.file.mimetype)) {
        return res.status(400).json({
          success: false,
          message: 'Invalid file type. Only JPEG, PNG, and WebP images are allowed'
        });
      }

      // Validate file size (max 5MB)
      const maxSize = 5 * 1024 * 1024; // 5MB
      if (req.file.size > maxSize) {
        return res.status(400).json({
          success: false,
          message: 'File size too large. Maximum size is 5MB'
        });
      }

      // Upload image using the same service as profile images
      const result = await UserService.uploadProfileImage(userId, req.file);

      // Update group with new image URL
      const updatedGroup = await GroupService.updateGroup(groupId, {
        image_url: result.avatar_url
      }, userId);

      res.status(200).json({
        success: true,
        message: 'Group image uploaded successfully',
        data: {
          group: updatedGroup,
          image_url: result.avatar_url,
          public_id: result.public_id
        }
      });
    } catch (error) {
      console.error('Group image upload error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to upload group image'
      });
    }
  }
}

module.exports = GroupController; 