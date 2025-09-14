const User = require('../models/User');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');

class UserService {
  // Register a new user
  static async register(userData) {
    try {
      // Create user
      const user = await User.create(userData);
      
      // Generate JWT token
      const token = UserService.generateToken(user);
      
      return {
        user,
        token,
        message: 'User registered successfully'
      };
    } catch (error) {
      throw new Error(`Registration failed: ${error.message}`);
    }
  }

  // Login user
  static async login(email, password) {
    try {
      // Authenticate user
      const user = await User.authenticate(email, password);
      
      if (!user) {
        throw new Error('Invalid email or password');
      }
      
      // Generate JWT token
      const token = UserService.generateToken(user);
      
      return {
        user,
        token,
        message: 'Login successful'
      };
    } catch (error) {
      throw new Error(`Login failed: ${error.message}`);
    }
  }

  // Get user profile
  static async getProfile(userId) {
    try {
      const user = await User.findById(userId);
      
      if (!user) {
        throw new Error('User not found');
      }
      
      return user.toPublicJSON();
    } catch (error) {
      throw new Error(`Failed to get profile: ${error.message}`);
    }
  }

  // Get user by ID (for fetching other users' public info)
  static async getUserById(userId) {
    try {
      const user = await User.findById(userId);
      
      if (!user) {
        throw new Error('User not found');
      }
      
      // Return only public information for other users
      return {
        id: user.id,
        first_name: user.first_name,
        last_name: user.last_name,
        avatar: user.avatar,
        name: `${user.first_name} ${user.last_name}`.trim()
      };
    } catch (error) {
      throw new Error(`Failed to get user: ${error.message}`);
    }
  }

  // Update user profile
  static async updateProfile(userId, updateData) {
    try {
      const user = await User.findById(userId);
      
      if (!user) {
        throw new Error('User not found');
      }
      
      const updatedUser = await user.update(updateData);
      return updatedUser;
    } catch (error) {
      throw new Error(`Failed to update profile: ${error.message}`);
    }
  }

  // Update user password
  static async updatePassword(userId, currentPassword, newPassword) {
    try {
      const user = await User.findById(userId);
      
      if (!user) {
        throw new Error('User not found');
      }
      
      // Verify current password
      const isCurrentPasswordValid = await bcrypt.compare(currentPassword, user.password);
      if (!isCurrentPasswordValid) {
        throw new Error('Current password is incorrect');
      }
      
      // Update password
      await user.updatePassword(newPassword);
      
      return {
        message: 'Password updated successfully'
      };
    } catch (error) {
      throw new Error(`Failed to update password: ${error.message}`);
    }
  }

  // Get user dashboard data
  static async getDashboard(userId) {
    try {
      const user = await User.findById(userId);
      
      if (!user) {
        throw new Error('User not found');
      }
      
      // Get user's groups
      const groups = await user.getGroups();
      
      // Get user's recent expenses
      const expenses = await user.getExpenses(5, 0); // Last 5 expenses
      
      // Get payment summary
      const paymentSummary = await user.getPaymentSummary();
      
      return {
        user: user.toPublicJSON(),
        groups,
        recent_expenses: expenses,
        payment_summary: paymentSummary
      };
    } catch (error) {
      throw new Error(`Failed to get dashboard: ${error.message}`);
    }
  }

  // Get user's groups
  static async getUserGroups(userId) {
    try {
      const user = await User.findById(userId);
      
      if (!user) {
        throw new Error('User not found');
      }
      
      return await user.getGroups();
    } catch (error) {
      throw new Error(`Failed to get user groups: ${error.message}`);
    }
  }

  // Get user's expenses
  static async getUserExpenses(userId, limit = 10, offset = 0) {
    try {
      const user = await User.findById(userId);
      
      if (!user) {
        throw new Error('User not found');
      }
      
      return await user.getExpenses(limit, offset);
    } catch (error) {
      throw new Error(`Failed to get user expenses: ${error.message}`);
    }
  }

  // Get user's payment summary
  static async getUserPaymentSummary(userId) {
    try {
      const user = await User.findById(userId);
      
      if (!user) {
        throw new Error('User not found');
      }
      
      return await user.getPaymentSummary();
    } catch (error) {
      throw new Error(`Failed to get payment summary: ${error.message}`);
    }
  }

  // Verify JWT token
  static async verifyToken(token) {
    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      
      // Check if user still exists
      const user = await User.findById(decoded.userId);
      if (!user) {
        throw new Error('User not found');
      }
      
      return user.toPublicJSON();
    } catch (error) {
      throw new Error('Invalid or expired token');
    }
  }

  // Generate JWT token
  static generateToken(user) {
    const payload = {
      userId: user.id,
      email: user.email,
      name: user.name
    };
    
    return jwt.sign(payload, process.env.JWT_SECRET, {
      expiresIn: '7d' // Token expires in 7 days
    });
  }

  // Search users by email or name
  static async searchUsers(searchTerm, limit = 10) {
    try {
      const query = `
        SELECT id, email, first_name, last_name, avatar, created_at
        FROM users
        WHERE email ILIKE $1 OR CONCAT(first_name, ' ', last_name) ILIKE $1
        ORDER BY first_name, last_name
        LIMIT $2
      `;
      
      const searchPattern = `%${searchTerm}%`;
      const result = await require('../../database/connection').query(query, [searchPattern, limit]);
      
      // Add formatted name for backward compatibility
      const users = result.rows.map(user => ({
        ...user,
        name: `${user.first_name} ${user.last_name}`.trim()
      }));
      
      return users;
    } catch (error) {
      throw new Error(`Failed to search users: ${error.message}`);
    }
  }

  // Check if user exists by email
  static async userExists(email) {
    try {
      const user = await User.findByEmail(email);
      return !!user;
    } catch (error) {
      throw new Error(`Failed to check user existence: ${error.message}`);
    }
  }

  // Get user statistics
  static async getUserStats(userId) {
    try {
      const user = await User.findById(userId);
      
      if (!user) {
        throw new Error('User not found');
      }
      
      // Get basic stats
      const groups = await user.getGroups();
      const expenses = await user.getExpenses(1000, 0); // Get all expenses for stats
      const paymentSummary = await user.getPaymentSummary();
      
      // Calculate statistics
      const stats = {
        total_groups: groups.length,
        total_expenses: expenses.length,
        total_to_pay: parseFloat(paymentSummary.total_to_pay || 0),
        total_to_get_paid: parseFloat(paymentSummary.total_to_get_paid || 0),
        balance: parseFloat(paymentSummary.balance || 0),
        average_expense: expenses.length > 0 
          ? expenses.reduce((sum, exp) => sum + parseFloat(exp.total_amount), 0) / expenses.length 
          : 0,
        most_active_group: groups.length > 0 ? groups[0] : null
      };
      
      return stats;
    } catch (error) {
      throw new Error(`Failed to get user stats: ${error.message}`);
    }
  }

  // Delete user account
  static async deleteAccount(userId, password) {
    try {
      const user = await User.findById(userId);
      
      if (!user) {
        throw new Error('User not found');
      }
      
      // Verify password
      const isPasswordValid = await bcrypt.compare(password, user.password);
      if (!isPasswordValid) {
        throw new Error('Password is incorrect');
      }
      
      // Note: In a real application, you might want to:
      // 1. Check if user has any active groups as admin
      // 2. Handle pending payments
      // 3. Archive data instead of deleting
      // 4. Send confirmation email
      
      // For now, we'll just delete the user
      // This will cascade to group_members, but you might want to handle this differently
      
      const query = 'DELETE FROM users WHERE id = $1 RETURNING *';
      const result = await require('../../database/connection').query(query, [userId]);
      
      if (result.rows.length === 0) {
        throw new Error('Failed to delete user');
      }
      
      return {
        message: 'Account deleted successfully'
      };
    } catch (error) {
      throw new Error(`Failed to delete account: ${error.message}`);
    }
  }

  // Upload profile image
  static async uploadProfileImage(userId, file) {
    try {
      const user = await User.findById(userId);
      
      if (!user) {
        throw new Error('User not found');
      }

      const cloudinary = require('../config/cloudinary');
      const streamifier = require('streamifier');

      // Delete old avatar if exists
      if (user.avatar && user.avatar.includes('cloudinary')) {
        try {
          const publicId = user.avatar.split('/').pop().split('.')[0];
          await cloudinary.uploader.destroy(publicId);
        } catch (error) {
          console.warn('Failed to delete old avatar:', error.message);
        }
      }

      // Upload new image to Cloudinary
      const uploadPromise = new Promise((resolve, reject) => {
        const uploadStream = cloudinary.uploader.upload_stream(
          {
            folder: 'profile_avatars',
            transformation: [
              { width: 400, height: 400, crop: 'fill', gravity: 'face' },
              { quality: 'auto:good', fetch_format: 'auto' }
            ],
            public_id: `user_${userId}_${Date.now()}`
          },
          (error, result) => {
            if (error) reject(error);
            else resolve(result);
          }
        );

        streamifier.createReadStream(file.buffer).pipe(uploadStream);
      });

      const result = await uploadPromise;

      // Update user avatar in database
      const query = 'UPDATE users SET avatar = $1, updated_at = NOW() WHERE id = $2 RETURNING *';
      const dbResult = await require('../../database/connection').query(query, [result.secure_url, userId]);

      if (dbResult.rows.length === 0) {
        throw new Error('Failed to update user avatar');
      }

      return {
        avatar_url: result.secure_url,
        public_id: result.public_id
      };
    } catch (error) {
      throw new Error(`Failed to upload profile image: ${error.message}`);
    }
  }
}

module.exports = UserService; 