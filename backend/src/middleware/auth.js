const UserService = require('../services/userService');

// Middleware to verify JWT token
const authenticateToken = async (req, res, next) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Access token required'
      });
    }

    // Verify token and get user
    const user = await UserService.verifyToken(token);
    
    // Add user to request object
    req.user = user;
    next();
  } catch (error) {
    return res.status(401).json({
      success: false,
      message: 'Invalid or expired token'
    });
  }
};

// Middleware to check if user is admin of a group
const requireGroupAdmin = async (req, res, next) => {
  try {
    const { groupId } = req.params;
    const userId = req.user.id;

    const GroupService = require('../services/groupService');
    const permission = await GroupService.checkGroupPermission(groupId, userId, 'edit');

    if (!permission.canPerform) {
      return res.status(403).json({
        success: false,
        message: permission.reason || 'Admin access required'
      });
    }

    next();
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error checking group permissions'
    });
  }
};

// Middleware to check if user is member of a group
const requireGroupMember = async (req, res, next) => {
  try {
    const { groupId, expenseId } = req.params;
    const userId = req.user.id;

    let targetGroupId = groupId;

    // If we have an expenseId instead of groupId, look up the expense first
    if (expenseId && !groupId) {
      const Expense = require('../models/Expense');
      const expense = await Expense.findById(expenseId);
      
      if (!expense) {
        return res.status(404).json({
          success: false,
          message: 'Expense not found'
        });
      }
      
      targetGroupId = expense.group_id;
    }

    if (!targetGroupId) {
      return res.status(400).json({
        success: false,
        message: 'Group ID or Expense ID required'
      });
    }

    const GroupService = require('../services/groupService');
    const permission = await GroupService.checkGroupPermission(targetGroupId, userId, 'view');

    if (!permission.canPerform) {
      return res.status(403).json({
        success: false,
        message: permission.reason || 'Group membership required'
      });
    }

    next();
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error checking group membership'
    });
  }
};

// Optional authentication middleware (for public routes that can work with or without auth)
const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (token) {
      try {
        const user = await UserService.verifyToken(token);
        req.user = user;
      } catch (error) {
        // Token is invalid, but we continue without user
        req.user = null;
      }
    } else {
      req.user = null;
    }

    next();
  } catch (error) {
    req.user = null;
    next();
  }
};

module.exports = {
  authenticateToken,
  requireGroupAdmin,
  requireGroupMember,
  optionalAuth
}; 