const GroupInvite = require('../models/GroupInvite');
const Group = require('../models/Group');

class InviteService {
  // Generate invite link for a group
  static async generateInviteLink(groupId, userId, options = {}) {
    try {
      // Verify user is member of the group
      const group = await Group.findById(groupId);
      if (!group) {
        throw new Error('Group not found');
      }

      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to generate invite links');
      }

      // Generate unique invite code
      let inviteCode;
      let attempts = 0;
      const maxAttempts = 10;
      let existingInvite;

      do {
        inviteCode = GroupInvite.generateInviteCode();
        existingInvite = await GroupInvite.findByCode(inviteCode);
        attempts++;
        
        if (attempts > maxAttempts) {
          throw new Error('Failed to generate unique invite code');
        }
      } while (existingInvite);

      // Set expiration (default: 7 days)
      const expiresAt = options.expiresAt || new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
      
      // Create invite
      const inviteData = {
        group_id: groupId,
        invite_code: inviteCode,
        created_by: userId,
        expires_at: expiresAt,
        max_uses: options.maxUses || 1
      };

      const invite = await GroupInvite.create(inviteData);

      // Generate invite URL
      const baseUrl = process.env.INVITE_BASE_URL || 'camsplit://join';
      const inviteUrl = `${baseUrl}/${inviteCode}`;

      return {
        invite,
        inviteUrl,
        expiresAt: invite.expires_at
      };
    } catch (error) {
      throw new Error(`Failed to generate invite link: ${error.message}`);
    }
  }

  // Get invite details
  static async getInviteDetails(inviteCode) {
    try {
      const invite = await GroupInvite.findByCode(inviteCode);
      if (!invite) {
        throw new Error('Invite not found or inactive');
      }

      // Check if valid
      const isValid = await GroupInvite.isValid(inviteCode);
      if (!isValid) {
        throw new Error('Invite is expired or has reached usage limit');
      }

      return {
        invite,
        isValid,
        groupName: invite.group_name,
        groupDescription: invite.group_description
      };
    } catch (error) {
      throw new Error(`Failed to get invite details: ${error.message}`);
    }
  }

  // Get available members for claiming
  static async getAvailableMembers(inviteCode) {
    try {
      const invite = await GroupInvite.findByCode(inviteCode);
      if (!invite) {
        throw new Error('Invite not found or inactive');
      }

      const members = await GroupInvite.getAvailableMembers(invite.group_id);
      return members;
    } catch (error) {
      throw new Error(`Failed to get available members: ${error.message}`);
    }
  }

  // Join group by claiming existing member
  static async joinByClaimingMember(inviteCode, userId, memberId) {
    try {
      // Validate invite
      const invite = await GroupInvite.findByCode(inviteCode);
      if (!invite) {
        throw new Error('Invite not found or inactive');
      }

      const isValid = await GroupInvite.isValid(inviteCode);
      if (!isValid) {
        throw new Error('Invite is expired or has reached usage limit');
      }

      // Check if user is already a member of this group
      const group = await Group.findById(invite.group_id);
      const isAlreadyMember = await group.isUserMember(userId);
      if (isAlreadyMember) {
        throw new Error('You are already a member of this group');
      }

      // Verify member exists and is available for claiming
      const availableMembers = await GroupInvite.getAvailableMembers(invite.group_id);
      const targetMember = availableMembers.find(m => m.id === memberId);
      if (!targetMember) {
        throw new Error('Member not found or already claimed');
      }

      // Update member with user_id
      const updatedMember = await group.claimMember(memberId, userId);
      
      // Increment invite usage
      await GroupInvite.incrementUsage(inviteCode);

      return {
        success: true,
        member: updatedMember,
        message: 'Successfully joined group by claiming existing member'
      };
    } catch (error) {
      throw new Error(`Failed to join group: ${error.message}`);
    }
  }

  // Join group by creating new member
  static async joinByCreatingMember(inviteCode, userId, memberData) {
    try {
      // Validate invite
      const invite = await GroupInvite.findByCode(inviteCode);
      if (!invite) {
        throw new Error('Invite not found or inactive');
      }

      const isValid = await GroupInvite.isValid(inviteCode);
      if (!isValid) {
        throw new Error('Invite is expired or has reached usage limit');
      }

      // Check if user is already a member of this group
      const group = await Group.findById(invite.group_id);
      const isAlreadyMember = await group.isUserMember(userId);
      if (isAlreadyMember) {
        throw new Error('You are already a member of this group');
      }

      // Create new member
      const newMemberData = {
        user_id: userId,
        nickname: memberData.nickname,
        email: memberData.email,
        role: 'member'
      };

      const newMember = await group.addMember(newMemberData);
      
      // Increment invite usage
      await GroupInvite.incrementUsage(inviteCode);

      return {
        success: true,
        member: newMember,
        message: 'Successfully joined group as new member'
      };
    } catch (error) {
      throw new Error(`Failed to join group: ${error.message}`);
    }
  }

  // Get all invites for a group
  static async getGroupInvites(groupId, userId) {
    try {
      // Verify user is member of the group
      const group = await Group.findById(groupId);
      if (!group) {
        throw new Error('Group not found');
      }

      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to view invites');
      }

      const invites = await GroupInvite.getByGroupId(groupId);
      
      // Add invite URLs
      const baseUrl = process.env.INVITE_BASE_URL || 'camsplit://join';
      const invitesWithUrls = invites.map(invite => ({
        ...invite,
        inviteUrl: `${baseUrl}/${invite.invite_code}`
      }));

      return invitesWithUrls;
    } catch (error) {
      throw new Error(`Failed to get group invites: ${error.message}`);
    }
  }

  // Deactivate invite
  static async deactivateInvite(inviteId, userId) {
    try {
      const invite = await GroupInvite.findById(inviteId);
      if (!invite) {
        throw new Error('Invite not found');
      }

      // Verify user is member of the group
      const group = await Group.findById(invite.group_id);
      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to manage invites');
      }

      const deactivatedInvite = await GroupInvite.deactivate(inviteId);
      return deactivatedInvite;
    } catch (error) {
      throw new Error(`Failed to deactivate invite: ${error.message}`);
    }
  }
}

module.exports = InviteService; 