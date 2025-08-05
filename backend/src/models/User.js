const bcrypt = require('bcrypt');
const db = require('../../database/connection');

class User {
  constructor(data) {
    this.id = data.id;
    this.email = data.email;
    this.password = data.password;
    this.first_name = data.first_name;
    this.last_name = data.last_name;
    this.phone = data.phone;
    this.bio = data.bio;
    this.birthdate = data.birthdate;
    this.avatar = data.avatar;
    this.is_email_verified = data.is_email_verified;
    this.timezone = data.timezone;
    this.created_at = data.created_at;
    this.updated_at = data.updated_at;
    this.preferences = data.preferences; // Will be loaded separately
  }

  // Create a new user
  static async create(userData) {
    const { email, password, first_name, last_name, phone, bio, birthdate, avatar, timezone } = userData;

    // Validate input
    const validation = User.validate(userData);
    if (!validation.isValid) {
      throw new Error(`Validation failed: ${validation.errors.join(', ')}`);
    }

    // Check if user already exists
    const existingUser = await User.findByEmail(email);
    if (existingUser) {
      throw new Error('User with this email already exists');
    }

    // Hash password
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    const client = await db.pool.connect();
    try {
      await client.query('BEGIN');

      // Create user
      const userQuery = `
        INSERT INTO users (email, password, first_name, last_name, phone, bio, birthdate, avatar, timezone, created_at, updated_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW(), NOW())
        RETURNING *
      `;

      const userValues = [email, hashedPassword, first_name, last_name, phone, bio, birthdate, avatar, timezone];
      const userResult = await client.query(userQuery, userValues);
      const user = userResult.rows[0];

      // Create default preferences
      const prefsQuery = `
        INSERT INTO user_preferences (user_id, currency, language, notifications, email_notifications, dark_mode, biometric_auth, auto_sync)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        RETURNING *
      `;

      const prefsValues = [user.id, 'USD', 'en', true, true, false, false, true];
      const prefsResult = await client.query(prefsQuery, prefsValues);

      await client.query('COMMIT');

      const userInstance = new User(user);
      userInstance.preferences = prefsResult.rows[0];
      return userInstance.toPublicJSON();
    } catch (error) {
      await client.query('ROLLBACK');
      throw new Error(`Failed to create user: ${error.message}`);
    } finally {
      client.release();
    }
  }

  // Find user by ID with preferences
  static async findById(id) {
    try {
      const query = `
        SELECT u.*, up.currency, up.language, up.notifications, up.email_notifications, 
               up.dark_mode, up.biometric_auth, up.auto_sync
        FROM users u
        LEFT JOIN user_preferences up ON u.id = up.user_id
        WHERE u.id = $1
      `;
      const result = await db.query(query, [id]);

      if (result.rows.length === 0) {
        return null;
      }

      const userData = result.rows[0];
      const user = new User(userData);

      // Extract preferences
      user.preferences = {
        currency: userData.currency || 'USD',
        language: userData.language || 'en',
        notifications: userData.notifications !== null ? userData.notifications : true,
        email_notifications: userData.email_notifications !== null ? userData.email_notifications : true,
        dark_mode: userData.dark_mode !== null ? userData.dark_mode : false,
        biometric_auth: userData.biometric_auth !== null ? userData.biometric_auth : false,
        auto_sync: userData.auto_sync !== null ? userData.auto_sync : true
      };

      return user;
    } catch (error) {
      throw new Error(`Failed to find user: ${error.message}`);
    }
  }

  // Find user by email
  static async findByEmail(email) {
    try {
      const query = 'SELECT * FROM users WHERE email = $1';
      const result = await db.query(query, [email]);

      if (result.rows.length === 0) {
        return null;
      }

      return new User(result.rows[0]);
    } catch (error) {
      throw new Error(`Failed to find user by email: ${error.message}`);
    }
  }

  // Authenticate user
  static async authenticate(email, password) {
    try {
      const user = await User.findByEmail(email);
      if (!user) {
        return null;
      }

      const isPasswordValid = await bcrypt.compare(password, user.password);
      if (!isPasswordValid) {
        return null;
      }

      return user.toPublicJSON();
    } catch (error) {
      throw new Error(`Authentication failed: ${error.message}`);
    }
  }

  // Update user profile
  async update(updateData) {
    const { first_name, last_name, phone, bio, birthdate, avatar, timezone, preferences } = updateData;

    // Validate input
    const validation = User.validateProfile(updateData);
    if (!validation.isValid) {
      throw new Error(`Validation failed: ${validation.errors.join(', ')}`);
    }

    const client = await db.pool.connect();
    try {
      await client.query('BEGIN');

      // Update user profile
      const userQuery = `
        UPDATE users 
        SET first_name = COALESCE($1, first_name),
            last_name = COALESCE($2, last_name),
            phone = COALESCE($3, phone),
            bio = COALESCE($4, bio),
            birthdate = COALESCE($5, birthdate),
            avatar = COALESCE($6, avatar),
            timezone = COALESCE($7, timezone),
            updated_at = NOW()
        WHERE id = $8
        RETURNING *
      `;

      const userValues = [first_name, last_name, phone, bio, birthdate, avatar, timezone, this.id];
      const userResult = await client.query(userQuery, userValues);

      if (userResult.rows.length === 0) {
        throw new Error('User not found');
      }

      // Update preferences if provided
      if (preferences) {
        const prefsQuery = `
          UPDATE user_preferences 
          SET currency = COALESCE($1, currency),
              language = COALESCE($2, language),
              notifications = COALESCE($3, notifications),
              email_notifications = COALESCE($4, email_notifications),
              dark_mode = COALESCE($5, dark_mode),
              biometric_auth = COALESCE($6, biometric_auth),
              auto_sync = COALESCE($7, auto_sync),
              updated_at = NOW()
          WHERE user_id = $8
          RETURNING *
        `;

        const prefsValues = [
          preferences.currency,
          preferences.language,
          preferences.notifications,
          preferences.email_notifications,
          preferences.dark_mode,
          preferences.biometric_auth,
          preferences.auto_sync,
          this.id
        ];

        const prefsResult = await client.query(prefsQuery, prefsValues);
        this.preferences = prefsResult.rows[0];
      }

      await client.query('COMMIT');

      // Update current instance
      Object.assign(this, userResult.rows[0]);
      return this.toPublicJSON();
    } catch (error) {
      await client.query('ROLLBACK');
      throw new Error(`Failed to update user: ${error.message}`);
    } finally {
      client.release();
    }
  }

  // Update user password
  async updatePassword(newPassword) {
    // Validate password
    const validation = User.validatePassword(newPassword);
    if (!validation.isValid) {
      throw new Error(`Password validation failed: ${validation.errors.join(', ')}`);
    }

    try {
      // Hash new password
      const saltRounds = 10;
      const hashedPassword = await bcrypt.hash(newPassword, saltRounds);

      const query = `
        UPDATE users 
        SET password = $1, updated_at = NOW()
        WHERE id = $2
        RETURNING *
      `;

      const result = await db.query(query, [hashedPassword, this.id]);

      if (result.rows.length === 0) {
        throw new Error('User not found');
      }

      // Update current instance
      this.password = hashedPassword;
      this.updated_at = result.rows[0].updated_at;

      return true;
    } catch (error) {
      throw new Error(`Failed to update password: ${error.message}`);
    }
  }

  // Get user's groups
  async getGroups() {
    try {
      const query = `
        SELECT g.*, gm.role, gm.joined_at
        FROM groups g
        JOIN group_members gm ON g.id = gm.group_id
        WHERE gm.user_id = $1
        ORDER BY g.updated_at DESC
      `;

      const result = await db.query(query, [this.id]);
      return result.rows;
    } catch (error) {
      throw new Error(`Failed to get user groups: ${error.message}`);
    }
  }

  // Get user's expenses
  async getExpenses(limit = 10, offset = 0) {
    try {
      const query = `
        SELECT 
          e.*,
          g.name as group_name,
          COALESCE(payer_gm.nickname, CONCAT(u.first_name, ' ', u.last_name)) as payer_nickname,
          COALESCE(es.amount_owed, 0) as amount_owed
        FROM expenses e
        JOIN groups g ON e.group_id = g.id
        JOIN group_members gm ON g.id = gm.group_id
        LEFT JOIN expense_payers ep ON e.id = ep.expense_id
        LEFT JOIN group_members payer_gm ON ep.group_member_id = payer_gm.id
        LEFT JOIN users u ON payer_gm.user_id = u.id
        LEFT JOIN expense_splits es ON e.id = es.expense_id AND es.group_member_id = gm.id
        WHERE gm.user_id = $1
        ORDER BY e.created_at DESC
        LIMIT $2 OFFSET $3
      `;

      const result = await db.query(query, [this.id, limit, offset]);
      return result.rows;
    } catch (error) {
      throw new Error(`Failed to get user expenses: ${error.message}`);
    }
  }

  // Get user's payment summary
  async getPaymentSummary() {
    try {
      const query = `
        SELECT 
          COALESCE(SUM(CASE WHEN s.from_group_member_id = gm.id THEN s.amount ELSE 0 END), 0) as total_to_pay,
          COALESCE(SUM(CASE WHEN s.to_group_member_id = gm.id THEN s.amount ELSE 0 END), 0) as total_to_get_paid,
          COALESCE(SUM(CASE WHEN s.to_group_member_id = gm.id THEN s.amount ELSE 0 END), 0) - 
          COALESCE(SUM(CASE WHEN s.from_group_member_id = gm.id THEN s.amount ELSE 0 END), 0) as balance
        FROM group_members gm
        LEFT JOIN settlements s ON (s.from_group_member_id = gm.id OR s.to_group_member_id = gm.id) 
          AND s.status = 'active'
        WHERE gm.user_id = $1
      `;

      const result = await db.query(query, [this.id]);
      return result.rows[0];
    } catch (error) {
      throw new Error(`Failed to get payment summary: ${error.message}`);
    }
  }

  // Convert to public JSON (without password)
  toPublicJSON() {
    return {
      id: this.id,
      email: this.email,
      first_name: this.first_name,
      last_name: this.last_name,
      phone: this.phone,
      bio: this.bio,
      birthdate: this.birthdate,
      avatar: this.avatar,
      is_email_verified: this.is_email_verified,
      timezone: this.timezone,
      preferences: this.preferences,
      member_since: this.created_at, // Frontend expects this field name
      created_at: this.created_at,
      updated_at: this.updated_at
    };
  }

  // Static validation methods
  static validate(userData) {
    const errors = [];
    const { email, password, first_name, last_name, phone, birthdate } = userData;

    // Email validation
    if (!email || !User.isValidEmail(email)) {
      errors.push('Valid email is required');
    }

    // Password validation
    if (!password || !User.isValidPassword(password)) {
      errors.push('Password must be at least 8 characters with uppercase, lowercase, and number');
    }

    // Name validation
    if (!first_name || first_name.trim().length < 1) {
      errors.push('First name is required');
    }
    if (!last_name || last_name.trim().length < 1) {
      errors.push('Last name is required');
    }

    // Phone validation (optional)
    if (phone && !User.isValidPhone(phone)) {
      errors.push('Invalid phone number format');
    }

    // Birthdate validation
    if (birthdate && !User.isValidDate(birthdate)) {
      errors.push('Invalid birthdate format (YYYY-MM-DD)');
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }

  static validateProfile(profileData) {
    const errors = [];
    const { first_name, last_name, phone, bio, birthdate } = profileData;

    // Name validation
    if (first_name !== undefined && first_name.trim().length < 1) {
      errors.push('First name must be at least 1 character');
    }
    if (last_name !== undefined && last_name.trim().length < 1) {
      errors.push('Last name must be at least 1 character');
    }

    // Phone validation (optional)
    if (phone && !User.isValidPhone(phone)) {
      errors.push('Invalid phone number format');
    }

    // Bio validation
    if (bio && bio.length > 500) {
      errors.push('Bio must be 500 characters or less');
    }

    // Birthdate validation
    if (birthdate && !User.isValidDate(birthdate)) {
      errors.push('Invalid birthdate format (YYYY-MM-DD)');
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }

  static validatePassword(password) {
    const errors = [];

    if (!password || !User.isValidPassword(password)) {
      errors.push('Password must be at least 8 characters with uppercase, lowercase, and number');
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }

  // Helper validation methods
  static isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }

  static isValidPassword(password) {
    // At least 8 characters, 1 uppercase, 1 lowercase, 1 number
    const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$/;
    return passwordRegex.test(password);
  }

  static isValidPhone(phone) {
    // Basic phone validation - allows various formats
    const phoneRegex = /^[\+]?[1-9][\d]{0,15}$/;
    return phoneRegex.test(phone.replace(/[\s\-\(\)]/g, ''));
  }

  static isValidDate(dateString) {
    const date = new Date(dateString);
    return date instanceof Date && !isNaN(date) && dateString.match(/^\d{4}-\d{2}-\d{2}$/);
  }
}

module.exports = User;

module.exports = User; 