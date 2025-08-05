const Group = require('../models/Group');
const User = require('../models/User');

class GroupService {
  // Create a new group
  static async createGroup(groupData, creatorId) {
    try {
      // Verify creator exists
      const creator = await User.findById(creatorId);
      if (!creator) {
        throw new Error('Creator not found');
      }
      
      // Create group (this will also add creator as admin member)
      const group = await Group.create(groupData, creatorId);
      
      return {
        group: group.toJSON(),
        message: 'Group created successfully'
      };
    } catch (error) {
      throw new Error(`Failed to create group: ${error.message}`);
    }
  }

  // Get group by ID
  static async getGroup(groupId) {
    try {
      const group = await Group.findById(groupId);
      
      if (!group) {
        throw new Error('Group not found');
      }
      
      return group.toJSON();
    } catch (error) {
      throw new Error(`Failed to get group: ${error.message}`);
    }
  }

  // Get group with members
  static async getGroupWithMembers(groupId) {
    try {
      const groupWithMembers = await Group.findByIdWithMembers(groupId);
      
      if (!groupWithMembers) {
        throw new Error('Group not found');
      }
      
      return groupWithMembers;
    } catch (error) {
      throw new Error(`Failed to get group with members: ${error.message}`);
    }
  }

  // Get groups for a user
  static async getUserGroups(userId) {
    try {
      // Verify user exists
      const user = await User.findById(userId);
      if (!user) {
        throw new Error('User not found');
      }
      
      const groups = await Group.getGroupsForUser(userId);
      return groups.map(group => group.toJSON());
    } catch (error) {
      throw new Error(`Failed to get user groups: ${error.message}`);
    }
  }

  // Update group
  static async updateGroup(groupId, updateData, userId) {
    try {
      const group = await Group.findById(groupId);
      
      if (!group) {
        throw new Error('Group not found');
      }
      
      // Check if user is admin of the group
      const isAdmin = await group.isUserAdmin(userId);
      if (!isAdmin) {
        throw new Error('Only group admins can update group details');
      }
      
      const updatedGroup = await group.update(updateData);
      return updatedGroup.toJSON();
    } catch (error) {
      throw new Error(`Failed to update group: ${error.message}`);
    }
  }

  // Delete group
  static async deleteGroup(groupId, userId) {
    try {
      const group = await Group.findById(groupId);
      
      if (!group) {
        throw new Error('Group not found');
      }
      
      // Check if user is admin of the group
      const isAdmin = await group.isUserAdmin(userId);
      if (!isAdmin) {
        throw new Error('Only group admins can delete the group');
      }
      
      await group.delete();
      
      return {
        message: 'Group deleted successfully'
      };
    } catch (error) {
      throw new Error(`Failed to delete group: ${error.message}`);
    }
  }

  // Add member to group
  static async addMember(groupId, memberData, userId) {
    try {
      const group = await Group.findById(groupId);
      
      if (!group) {
        throw new Error('Group not found');
      }
      
      // Check if user is member of the group
      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to add new members');
      }
      
      // If adding a registered user, verify they exist
      if (memberData.user_id) {
        const user = await User.findById(memberData.user_id);
        if (!user) {
          throw new Error('User not found');
        }
      }
      
      const member = await group.addMember(memberData);
      
      return {
        member,
        message: 'Member added successfully'
      };
    } catch (error) {
      throw new Error(`Failed to add member: ${error.message}`);
    }
  }

  // Remove member from group
  static async removeMember(groupId, memberId, userId) {
    try {
      const group = await Group.findById(groupId);
      
      if (!group) {
        throw new Error('Group not found');
      }
      
      // Check if user is admin of the group
      const isAdmin = await group.isUserAdmin(userId);
      if (!isAdmin) {
        throw new Error('Only group admins can remove members');
      }
      
      // Get member to check if they're trying to remove themselves
      const members = await group.getMembers();
      const memberToRemove = members.find(m => m.id === memberId);
      
      if (!memberToRemove) {
        throw new Error('Member not found in group');
      }
      
      // Prevent removing the last admin
      if (memberToRemove.role === 'admin') {
        const admins = members.filter(m => m.role === 'admin');
        if (admins.length === 1) {
          throw new Error('Cannot remove the last admin from the group');
        }
      }
      
      const removedMember = await group.removeMember(memberId);
      
      return {
        member: removedMember,
        message: 'Member removed successfully'
      };
    } catch (error) {
      throw new Error(`Failed to remove member: ${error.message}`);
    }
  }

  // Claim member (link non-user member to user account)
  static async claimMember(groupId, memberId, userId) {
    try {
      const group = await Group.findById(groupId);
      
      if (!group) {
        throw new Error('Group not found');
      }
      
      // Verify user exists
      const user = await User.findById(userId);
      if (!user) {
        throw new Error('User not found');
      }
      
      // Check if user is already a member of this group
      const isAlreadyMember = await group.isUserMember(userId);
      if (isAlreadyMember) {
        throw new Error('User is already a member of this group');
      }
      
      const claimedMember = await group.claimMember(memberId, userId);
      
      return {
        member: claimedMember,
        message: 'Member claimed successfully'
      };
    } catch (error) {
      throw new Error(`Failed to claim member: ${error.message}`);
    }
  }

  // Get group members
  static async getGroupMembers(groupId, userId) {
    try {
      const group = await Group.findById(groupId);
      
      if (!group) {
        throw new Error('Group not found');
      }
      
      // Check if user is member of the group
      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to view members');
      }
      
      return await group.getMembers();
    } catch (error) {
      throw new Error(`Failed to get group members: ${error.message}`);
    }
  }

  // Get group expenses
  static async getGroupExpenses(groupId, userId, limit = 10, offset = 0) {
    try {
      const group = await Group.findById(groupId);
      
      if (!group) {
        throw new Error('Group not found');
      }
      
      // Check if user is member of the group
      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to view expenses');
      }
      
      return await group.getExpenses(limit, offset);
    } catch (error) {
      throw new Error(`Failed to get group expenses: ${error.message}`);
    }
  }

  // Get group payment summary
  static async getGroupPaymentSummary(groupId, userId) {
    try {
      const group = await Group.findById(groupId);
      
      if (!group) {
        throw new Error('Group not found');
      }
      
      // Check if user is member of the group
      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to view payment summary');
      }
      
      return await group.getPaymentSummary();
    } catch (error) {
      throw new Error(`Failed to get payment summary: ${error.message}`);
    }
  }

  // Get user balance for a specific group using settlements
  static async getUserBalanceForGroup(groupId, userId) {
    try {
      const group = await Group.findById(groupId);
      
      if (!group) {
        throw new Error('Group not found');
      }
      
      // Check if user is member of the group
      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to view balance');
      }
      
      return await group.getUserBalance(userId);
    } catch (error) {
      throw new Error(`Failed to get user balance: ${error.message}`);
    }
  }

  // Search groups by name
  static async searchGroups(searchTerm, userId, limit = 10) {
    try {
      const query = `
        SELECT DISTINCT 
          g.*, 
          gm.role,
          COALESCE(member_counts.member_count, 0) as member_count
        FROM groups g
        JOIN group_members gm ON g.id = gm.group_id
        LEFT JOIN (
          SELECT group_id, COUNT(*) as member_count
          FROM group_members 
          GROUP BY group_id
        ) member_counts ON g.id = member_counts.group_id
        WHERE gm.user_id = $1 AND g.name ILIKE $2
        ORDER BY g.updated_at DESC
        LIMIT $3
      `;
      
      const searchPattern = `%${searchTerm}%`;
      const result = await require('../../database/connection').query(query, [userId, searchPattern, limit]);
      
      return result.rows.map(row => new Group(row).toJSON());
    } catch (error) {
      throw new Error(`Failed to search groups: ${error.message}`);
    }
  }

  // Get group statistics
  static async getGroupStats(groupId, userId) {
    try {
      const group = await Group.findById(groupId);
      
      if (!group) {
        throw new Error('Group not found');
      }
      
      // Check if user is member of the group
      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to view statistics');
      }
      
      // Get group data
      const members = await group.getMembers();
      const expenses = await group.getExpenses(1000, 0); // Get all expenses for stats
      const paymentSummary = await group.getPaymentSummary();
      
      // Calculate statistics
      const stats = {
        total_members: members.length,
        registered_members: members.filter(m => m.is_registered_user).length,
        non_registered_members: members.filter(m => !m.is_registered_user).length,
        total_expenses: expenses.length,
        total_amount: expenses.reduce((sum, exp) => sum + parseFloat(exp.total_amount), 0),
        average_expense: expenses.length > 0 
          ? expenses.reduce((sum, exp) => sum + parseFloat(exp.total_amount), 0) / expenses.length 
          : 0,
        total_paid: paymentSummary.reduce((sum, member) => sum + parseFloat(member.total_paid || 0), 0),
        total_to_pay: paymentSummary.reduce((sum, member) => sum + parseFloat(member.total_to_pay || 0), 0),
        total_to_get_paid: paymentSummary.reduce((sum, member) => sum + parseFloat(member.total_to_get_paid || 0), 0),
        net_balance: paymentSummary.reduce((sum, member) => sum + parseFloat(member.balance || 0), 0)
      };
      
      return stats;
    } catch (error) {
      throw new Error(`Failed to get group stats: ${error.message}`);
    }
  }

  // Invite user to group (create non-user member with email)
  static async inviteUserToGroup(groupId, email, nickname, userId) {
    try {
      const group = await Group.findById(groupId);
      
      if (!group) {
        throw new Error('Group not found');
      }
      
      // Check if user is member of the group
      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to invite users');
      }
      
      // Check if user with this email already exists
      const existingUser = await User.findByEmail(email);
      
      const memberData = {
        user_id: existingUser ? existingUser.id : null,
        nickname: nickname,
        email: email,
        role: 'member'
      };
      
      const member = await group.addMember(memberData);
      
      return {
        member,
        is_registered_user: !!existingUser,
        message: existingUser 
          ? 'User added to group successfully' 
          : 'Invitation created successfully'
      };
    } catch (error) {
      throw new Error(`Failed to invite user: ${error.message}`);
    }
  }

  // Get groups where user can be invited
  static async getInvitableGroups(userId) {
    try {
      // Get groups where the user is a member (includes member_count)
      const userGroups = await Group.getGroupsForUser(userId);
      
      // Filter groups where user is admin (can invite others)
      const invitableGroups = [];
      
      for (const group of userGroups) {
        const isAdmin = await group.isUserAdmin(userId);
        if (isAdmin) {
          invitableGroups.push(group.toJSON());
        }
      }
      
      return invitableGroups;
    } catch (error) {
      throw new Error(`Failed to get invitable groups: ${error.message}`);
    }
  }

  // Check if user can perform action in group
  static async checkGroupPermission(groupId, userId, action) {
    try {
      const group = await Group.findById(groupId);
      
      if (!group) {
        return { canPerform: false, reason: 'Group not found' };
      }
      
      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        return { canPerform: false, reason: 'Not a member of the group' };
      }
      
      const isAdmin = await group.isUserAdmin(userId);
      
      switch (action) {
        case 'view':
          return { canPerform: true };
        case 'edit':
          return { canPerform: isAdmin, reason: isAdmin ? null : 'Admin access required' };
        case 'delete':
          return { canPerform: isAdmin, reason: isAdmin ? null : 'Admin access required' };
        case 'add_member':
          return { canPerform: true };
        case 'remove_member':
          return { canPerform: isAdmin, reason: isAdmin ? null : 'Admin access required' };
        default:
          return { canPerform: false, reason: 'Unknown action' };
      }
    } catch (error) {
      return { canPerform: false, reason: error.message };
    }
  }

  // Delete group with cascading deletes
  static async deleteGroupWithCascade(groupId, userId) {
    try {
      console.log(`GroupService.deleteGroupWithCascade: groupId=${groupId}, userId=${userId}`);
      
      // Validate inputs
      if (!groupId) {
        throw new Error('Group ID is required');
      }
      
      if (!userId) {
        throw new Error('User ID is required');
      }
      
      const group = await Group.findById(groupId);
      
      if (!group) {
        throw new Error('Group not found');
      }
      
      console.log(`GroupService.deleteGroupWithCascade: Found group ${group.id}`);
      
      // Check if user is admin of the group
      const isAdmin = await group.isUserAdmin(userId);
      if (!isAdmin) {
        throw new Error('Only group admins can delete the group');
      }
      
      console.log(`GroupService.deleteGroupWithCascade: User is admin, proceeding with deletion`);
      
      await group.deleteWithCascade();
      
      return {
        message: 'Group and all related data deleted successfully'
      };
    } catch (error) {
      console.error('GroupService.deleteGroupWithCascade error:', error);
      throw new Error(`Failed to delete group with cascade: ${error.message}`);
    }
  }

  // Exit group (for regular members)
  static async exitGroup(groupId, userId) {
    try {
      const group = await Group.findById(groupId);
      
      if (!group) {
        throw new Error('Group not found');
      }
      
      // Check if user is a member of the group
      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You are not a member of this group');
      }
      
      const result = await group.exitGroup(userId);
      
      return {
        message: result.message,
        action: result.action
      };
    } catch (error) {
      throw new Error(`Failed to exit group: ${error.message}`);
    }
  }

  // Check if group should be auto-deleted
  static async checkGroupAutoDelete(groupId) {
    try {
      const group = await Group.findById(groupId);
      
      if (!group) {
        return false;
      }
      
      return await group.shouldAutoDelete();
    } catch (error) {
      throw new Error(`Failed to check group auto-delete status: ${error.message}`);
    }
  }
}

module.exports = GroupService; 