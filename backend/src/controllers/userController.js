const UserService = require('../services/userService');

class UserController {
  // Register a new user
  static async register(req, res) {
    try {
      const { email, password, first_name, last_name, phone, bio, birthdate, avatar, timezone } = req.body;

      // Validate required fields
      if (!email || !password || !first_name || !last_name) {
        return res.status(400).json({
          success: false,
          message: 'Email, password, first name, and last name are required'
        });
      }

      const result = await UserService.register({
        email,
        password,
        first_name,
        last_name,
        phone,
        bio,
        birthdate,
        avatar,
        timezone
      });

      res.status(201).json({
        success: true,
        message: result.message,
        data: {
          user: result.user,
          token: result.token
        }
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Login user
  static async login(req, res) {
    try {
      const { email, password } = req.body;

      // Validate required fields
      if (!email || !password) {
        return res.status(400).json({
          success: false,
          message: 'Email and password are required'
        });
      }

      const result = await UserService.login(email, password);

      res.status(200).json({
        success: true,
        message: result.message,
        data: {
          user: result.user,
          token: result.token
        }
      });
    } catch (error) {
      res.status(401).json({
        success: false,
        message: error.message
      });
    }
  }

  // Get user profile
  static async getProfile(req, res) {
    try {
      const userId = req.user.id;
      const profile = await UserService.getProfile(userId);

      res.status(200).json({
        success: true,
        data: profile
      });
    } catch (error) {
      res.status(404).json({
        success: false,
        message: error.message
      });
    }
  }

  // Get user by ID (public info only)
  static async getUserById(req, res) {
    try {
      const { userId } = req.params;
      const user = await UserService.getUserById(userId);

      res.status(200).json({
        success: true,
        data: user
      });
    } catch (error) {
      res.status(404).json({
        success: false,
        message: error.message
      });
    }
  }

  // Update user profile
  static async updateProfile(req, res) {
    try {
      const userId = req.user.id;
      const { first_name, last_name, phone, bio, birthdate, avatar, timezone, preferences } = req.body;

      const updatedProfile = await UserService.updateProfile(userId, {
        first_name,
        last_name,
        phone,
        bio,
        birthdate,
        avatar,
        timezone,
        preferences
      });

      res.status(200).json({
        success: true,
        message: 'Profile updated successfully',
        data: updatedProfile
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Update user password
  static async updatePassword(req, res) {
    try {
      const userId = req.user.id;
      const { currentPassword, newPassword } = req.body;

      // Validate required fields
      if (!currentPassword || !newPassword) {
        return res.status(400).json({
          success: false,
          message: 'Current password and new password are required'
        });
      }

      const result = await UserService.updatePassword(userId, currentPassword, newPassword);

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

  // Get user dashboard
  static async getDashboard(req, res) {
    try {
      const userId = req.user.id;
      const dashboard = await UserService.getDashboard(userId);

      res.status(200).json({
        success: true,
        data: dashboard
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  // Get user's groups
  static async getUserGroups(req, res) {
    try {
      const userId = req.user.id;
      const groups = await UserService.getUserGroups(userId);

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

  // Get user's expenses
  static async getUserExpenses(req, res) {
    try {
      const userId = req.user.id;
      const { limit = 10, offset = 0 } = req.query;

      const expenses = await UserService.getUserExpenses(userId, parseInt(limit), parseInt(offset));

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

  // Get user's payment summary
  static async getUserPaymentSummary(req, res) {
    try {
      const userId = req.user.id;
      const paymentSummary = await UserService.getUserPaymentSummary(userId);

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

  // Search users
  static async searchUsers(req, res) {
    try {
      const { q, limit = 10 } = req.query;

      if (!q) {
        return res.status(400).json({
          success: false,
          message: 'Search query is required'
        });
      }

      const users = await UserService.searchUsers(q, parseInt(limit));

      res.status(200).json({
        success: true,
        data: users
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  // Check if user exists
  static async checkUserExists(req, res) {
    try {
      const { email } = req.query;

      if (!email) {
        return res.status(400).json({
          success: false,
          message: 'Email is required'
        });
      }

      const exists = await UserService.userExists(email);

      res.status(200).json({
        success: true,
        data: { exists }
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  // Get user statistics
  static async getUserStats(req, res) {
    try {
      const userId = req.user.id;
      const stats = await UserService.getUserStats(userId);

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

  // Delete user account
  static async deleteAccount(req, res) {
    try {
      const userId = req.user.id;
      const { password } = req.body;

      if (!password) {
        return res.status(400).json({
          success: false,
          message: 'Password is required to delete account'
        });
      }

      const result = await UserService.deleteAccount(userId, password);

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

  // Verify token (for testing/validation)
  static async verifyToken(req, res) {
    try {
      const { token } = req.body;

      if (!token) {
        return res.status(400).json({
          success: false,
          message: 'Token is required'
        });
      }

      const user = await UserService.verifyToken(token);

      res.status(200).json({
        success: true,
        data: user
      });
    } catch (error) {
      res.status(401).json({
        success: false,
        message: error.message
      });
    }
  }

  // Upload profile image
  static async uploadProfileImage(req, res) {
    try {
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

      const result = await UserService.uploadProfileImage(userId, req.file);

      res.status(200).json({
        success: true,
        message: 'Profile image uploaded successfully',
        data: {
          avatar_url: result.avatar_url,
          public_id: result.public_id
        }
      });
    } catch (error) {
      console.error('Profile image upload error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to upload profile image'
      });
    }
  }
}

module.exports = UserController; 