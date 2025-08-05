# CamSplit API Testing with Postman

This directory contains all the necessary files to test the CamSplit API using Postman.

## 📁 Files Overview

### `CamSplit_API_Collection.json`
- **Complete API collection** with all endpoints organized by functionality
- **Organized into folders**: Authentication, Users, Groups, Expenses, Items, Assignments, Payments, OCR
- **Pre-configured requests** with proper headers and body examples
- **Environment variables** for dynamic data (IDs, tokens, etc.)

### `CamSplit_Environment.json`
- **Postman environment** with all necessary variables
- **Base URL** configuration for different environments
- **Dynamic variables** for storing IDs and tokens during testing
- **Secret variables** for sensitive data like auth tokens

### `API_Testing_Guide.md`
- **Step-by-step testing instructions** in the correct order
- **Expected responses** for each endpoint
- **Troubleshooting guide** for common issues
- **Success criteria** and performance indicators

### `Test_Data_Setup.sql`
- **Sample data** for comprehensive testing
- **Multiple scenarios**: simple expenses, complex expenses with items
- **Realistic data** that covers all API features
- **Database state** after running all tests

## 🚀 Quick Start

### 1. Import Files
1. Open Postman
2. Click "Import" button
3. Import `CamSplit_API_Collection.json`
4. Import `CamSplit_Environment.json`

### 2. Select Environment
1. In Postman, select "CamSplit Test Environment" from the environment dropdown
2. Verify the `base_url` is set to `http://localhost:5000`

### 3. Start Testing
1. Follow the `API_Testing_Guide.md` for step-by-step instructions
2. Use the collection folders to organize your testing
3. Update environment variables as you progress through tests

## 🔧 Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `base_url` | API base URL | `http://localhost:5000` |
| `auth_token` | JWT authentication token | `eyJhbGciOiJIUzI1NiIs...` |
| `user_id` | Current user ID | `1` |
| `group_id` | Current group ID | `1` |
| `expense_id` | Current expense ID | `1` |
| `item_id` | Current item ID | `1` |
| `assignment_id` | Current assignment ID | `1` |
| `payment_id` | Current payment ID | `1` |
| `creator_member_id` | Group creator member ID | `1` |
| `member_id` | Regular member ID | `2` |
| `receipt_image_id` | Receipt image ID | `1` |

## 📋 Collection Structure

### 🔐 Authentication
- Register User
- Login User
- Verify Token

### 👤 Users
- Get Profile
- Update Profile
- Get Dashboard
- Get User Groups
- Search Users

### 👥 Groups
- Create Group
- Get User Groups
- Get Group Details
- Get Group with Members
- Add Member (Registered)
- Add Member (Non-Registered)
- Get Group Members
- Claim Member

### 💰 Expenses
- Create Simple Expense
- Create Complex Expense with Items
- Get Expense (Smart)
- Get Expense with Details
- Get Group Expenses
- Get User Expenses
- Get Expense Settlement

### 🛒 Items
- Get Items for Expense
- Create Item
- Get Specific Item
- Update Item
- Create Items from OCR
- Get Item Statistics
- Search Items

### 👥 Assignments
- Get Assignments for Expense
- Create Assignment
- Get Specific Assignment
- Update Assignment
- Add Users to Assignment
- Get Assignment Summary

### 💳 Payments
- Create Payment
- Get Group Payments
- Get Payment Summary
- Get Debt Relationships
- Mark Payment Completed

### 📷 OCR
- Process Receipt from URL
- Get OCR Statistics
- Validate OCR Configuration

## 🎯 Testing Scenarios

### Scenario 1: Basic User Flow
1. Register user
2. Create group
3. Add members
4. Create simple expense
5. View expenses and settlements

### Scenario 2: Complex Expense Flow
1. Create expense with items
2. Add assignments
3. Test smart GET endpoints
4. Verify data relationships

### Scenario 3: Payment Flow
1. Create payments
2. Test settlement calculations
3. Update payment status
4. View debt relationships

### Scenario 4: Item Management
1. Create items manually
2. Create items from OCR
3. Update items
4. Search items
5. View statistics

## 🔍 Validation Checklist

### Authentication
- [ ] User registration works
- [ ] Login returns valid token
- [ ] Token verification works
- [ ] Protected endpoints require authentication

### Groups
- [ ] Group creation works
- [ ] Member addition works (both registered and non-registered)
- [ ] Group retrieval works
- [ ] Member claiming works

### Expenses
- [ ] Simple expense creation works
- [ ] Complex expense with items works
- [ ] Smart GET endpoints work
- [ ] Settlement calculations are correct

### Items
- [ ] Item creation works
- [ ] Item updates work
- [ ] OCR item creation works
- [ ] Item search works
- [ ] Statistics are accurate

### Assignments
- [ ] Assignment creation works
- [ ] User assignment works
- [ ] Assignment updates work
- [ ] Summary calculations are correct

### Payments
- [ ] Payment creation works
- [ ] Payment status updates work
- [ ] Debt calculations are correct
- [ ] Settlement suggestions work

## 🚨 Common Issues

### Authentication Issues
- **Problem**: 401 Unauthorized
- **Solution**: Check `auth_token` is set and valid

### Permission Issues
- **Problem**: 403 Forbidden
- **Solution**: Ensure user is group member

### Not Found Issues
- **Problem**: 404 Not Found
- **Solution**: Check IDs are correctly set in environment

### Validation Issues
- **Problem**: 400 Bad Request
- **Solution**: Check request body format and required fields

## 📊 Performance Testing

### Response Time Targets
- Simple operations: < 500ms
- Complex operations: < 1000ms
- Database queries: < 200ms

### Load Testing
- Test with multiple concurrent requests
- Verify no memory leaks
- Check database connection pooling

## 🔒 Security Testing

### Authentication
- Test with invalid tokens
- Test with expired tokens
- Test with malformed tokens

### Authorization
- Test access to other users' data
- Test access to other groups' data
- Test admin-only operations

### Input Validation
- Test with malformed JSON
- Test with SQL injection attempts
- Test with XSS attempts

## 📈 Monitoring

### Success Metrics
- All endpoints return expected status codes
- Response times within acceptable limits
- No security vulnerabilities
- Data integrity maintained

### Error Tracking
- Monitor for 4xx and 5xx errors
- Track authentication failures
- Monitor database connection issues

## 🎉 Success Criteria

The API is ready for production when:
- [ ] All test scenarios pass
- [ ] Performance targets are met
- [ ] Security tests pass
- [ ] Error handling works correctly
- [ ] Data integrity is maintained
- [ ] Documentation is complete and accurate

## 📞 Support

For issues during testing:
1. Check server logs for detailed error messages
2. Verify database state
3. Review API documentation
4. Check environment configuration
5. Ensure all dependencies are running 