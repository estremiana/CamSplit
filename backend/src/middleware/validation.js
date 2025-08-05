/**
 * Simple validation middleware for request parameters, query, and body
 */

const validateParams = (schema) => {
  return (req, res, next) => {
    try {
      const errors = [];

      for (const [key, rules] of Object.entries(schema)) {
        const value = req.params[key];

        // Check if required field is missing
        if (rules.required && (value === undefined || value === null || value === '')) {
          errors.push(`Parameter '${key}' is required`);
          continue;
        }

        // Skip validation if field is optional and not provided
        if (!rules.required && (value === undefined || value === null || value === '')) {
          continue;
        }

        // Type validation
        if (rules.type === 'integer') {
          const numValue = parseInt(value, 10);
          if (isNaN(numValue)) {
            errors.push(`Parameter '${key}' must be a valid integer`);
            continue;
          }

          // Range validation
          if (rules.minimum !== undefined && numValue < rules.minimum) {
            errors.push(`Parameter '${key}' must be at least ${rules.minimum}`);
          }
          if (rules.maximum !== undefined && numValue > rules.maximum) {
            errors.push(`Parameter '${key}' must be at most ${rules.maximum}`);
          }

          // Update the parameter with parsed value
          req.params[key] = numValue;
        }

        if (rules.type === 'string') {
          if (typeof value !== 'string') {
            errors.push(`Parameter '${key}' must be a string`);
            continue;
          }

          // Length validation
          if (rules.minLength !== undefined && value.length < rules.minLength) {
            errors.push(`Parameter '${key}' must be at least ${rules.minLength} characters long`);
          }
          if (rules.maxLength !== undefined && value.length > rules.maxLength) {
            errors.push(`Parameter '${key}' must be at most ${rules.maxLength} characters long`);
          }
        }
      }

      if (errors.length > 0) {
        return res.status(400).json({
          error: true,
          message: 'Validation failed',
          details: errors
        });
      }

      next();
    } catch (error) {
      return res.status(500).json({
        error: true,
        message: 'Validation error',
        details: error.message
      });
    }
  };
};

const validateQuery = (schema) => {
  return (req, res, next) => {
    try {
      const errors = [];

      for (const [key, rules] of Object.entries(schema)) {
        let value = req.query[key];

        // Apply default value if not provided
        if ((value === undefined || value === null || value === '') && rules.default !== undefined) {
          value = rules.default;
          req.query[key] = value;
        }

        // Check if required field is missing
        if (rules.required && (value === undefined || value === null || value === '')) {
          errors.push(`Query parameter '${key}' is required`);
          continue;
        }

        // Skip validation if field is optional and not provided
        if (rules.optional && (value === undefined || value === null || value === '')) {
          continue;
        }

        // Type validation
        if (rules.type === 'integer') {
          const numValue = parseInt(value, 10);
          if (isNaN(numValue)) {
            errors.push(`Query parameter '${key}' must be a valid integer`);
            continue;
          }

          // Range validation
          if (rules.minimum !== undefined && numValue < rules.minimum) {
            errors.push(`Query parameter '${key}' must be at least ${rules.minimum}`);
          }
          if (rules.maximum !== undefined && numValue > rules.maximum) {
            errors.push(`Query parameter '${key}' must be at most ${rules.maximum}`);
          }

          // Update the query parameter with parsed value
          req.query[key] = numValue;
        }

        if (rules.type === 'string') {
          if (typeof value !== 'string') {
            errors.push(`Query parameter '${key}' must be a string`);
            continue;
          }

          // Format validation
          if (rules.format === 'date') {
            const dateValue = new Date(value);
            if (isNaN(dateValue.getTime())) {
              errors.push(`Query parameter '${key}' must be a valid date`);
            }
          }
        }
      }

      if (errors.length > 0) {
        return res.status(400).json({
          error: true,
          message: 'Validation failed',
          details: errors
        });
      }

      next();
    } catch (error) {
      return res.status(500).json({
        error: true,
        message: 'Validation error',
        details: error.message
      });
    }
  };
};

const validateBody = (schema) => {
  return (req, res, next) => {
    try {
      const errors = [];
      const body = req.body || {};

      for (const [key, rules] of Object.entries(schema)) {
        let value = body[key];

        // Apply default value if not provided
        if ((value === undefined || value === null) && rules.default !== undefined) {
          value = rules.default;
          req.body[key] = value;
        }

        // Check if required field is missing
        if (rules.required && (value === undefined || value === null)) {
          errors.push(`Body parameter '${key}' is required`);
          continue;
        }

        // Skip validation if field is optional and not provided
        if (!rules.required && (value === undefined || value === null)) {
          continue;
        }

        // Type validation
        if (rules.type === 'array') {
          if (!Array.isArray(value)) {
            errors.push(`Body parameter '${key}' must be an array`);
            continue;
          }

          // Array length validation
          if (rules.minItems !== undefined && value.length < rules.minItems) {
            errors.push(`Body parameter '${key}' must have at least ${rules.minItems} items`);
          }
          if (rules.maxItems !== undefined && value.length > rules.maxItems) {
            errors.push(`Body parameter '${key}' must have at most ${rules.maxItems} items`);
          }

          // Array item validation
          if (rules.items) {
            for (let i = 0; i < value.length; i++) {
              const item = value[i];
              
              if (rules.items.type === 'integer') {
                const numValue = parseInt(item, 10);
                if (isNaN(numValue)) {
                  errors.push(`Body parameter '${key}[${i}]' must be a valid integer`);
                  continue;
                }

                if (rules.items.minimum !== undefined && numValue < rules.items.minimum) {
                  errors.push(`Body parameter '${key}[${i}]' must be at least ${rules.items.minimum}`);
                }
                if (rules.items.maximum !== undefined && numValue > rules.items.maximum) {
                  errors.push(`Body parameter '${key}[${i}]' must be at most ${rules.items.maximum}`);
                }

                // Update array item with parsed value
                value[i] = numValue;
              }
            }
          }
        }

        if (rules.type === 'integer') {
          const numValue = parseInt(value, 10);
          if (isNaN(numValue)) {
            errors.push(`Body parameter '${key}' must be a valid integer`);
            continue;
          }

          // Range validation
          if (rules.minimum !== undefined && numValue < rules.minimum) {
            errors.push(`Body parameter '${key}' must be at least ${rules.minimum}`);
          }
          if (rules.maximum !== undefined && numValue > rules.maximum) {
            errors.push(`Body parameter '${key}' must be at most ${rules.maximum}`);
          }

          // Update the body parameter with parsed value
          req.body[key] = numValue;
        }

        if (rules.type === 'boolean') {
          if (typeof value !== 'boolean') {
            // Try to parse string boolean values
            if (value === 'true' || value === '1') {
              req.body[key] = true;
            } else if (value === 'false' || value === '0') {
              req.body[key] = false;
            } else {
              errors.push(`Body parameter '${key}' must be a boolean`);
            }
          }
        }

        if (rules.type === 'string') {
          if (typeof value !== 'string') {
            errors.push(`Body parameter '${key}' must be a string`);
            continue;
          }

          // Length validation
          if (rules.minLength !== undefined && value.length < rules.minLength) {
            errors.push(`Body parameter '${key}' must be at least ${rules.minLength} characters long`);
          }
          if (rules.maxLength !== undefined && value.length > rules.maxLength) {
            errors.push(`Body parameter '${key}' must be at most ${rules.maxLength} characters long`);
          }
        }
      }

      if (errors.length > 0) {
        return res.status(400).json({
          error: true,
          message: 'Validation failed',
          details: errors
        });
      }

      next();
    } catch (error) {
      return res.status(500).json({
        error: true,
        message: 'Validation error',
        details: error.message
      });
    }
  };
};

module.exports = {
  validateParams,
  validateQuery,
  validateBody
};