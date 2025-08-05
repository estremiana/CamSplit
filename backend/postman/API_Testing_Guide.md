# CamSplit API Testing Guide

## 🚀 Setup Instructions

### 1. Import Files into Postman
1. Import `CamSplit_API_Collection.json` as a collection
2. Import `CamSplit_Environment.json` as an environment
3. Select the "CamSplit Test Environment" in Postman

### 2. Database Setup
Make sure your test database is running and empty:
```bash
cd backend
npm run setup
```

### 3. Server Setup
Start the backend server:
```bash
cd backend
npm start
```

---

## 📋 Testing Order & Flow

### **Phase 1: Authentication & User Setup**

#### 1.1 Register User
- **Request**: `POST /api/users/register`
- **Purpose**: Create the first user account
- **Expected Response**: 201 with user data and JWT token
- **Action**: Copy the `token` from response to `auth_token` environment variable

#### 1.2 Login User
- **Request**: `POST /api/users/login`
- **Purpose**: Verify login works and get fresh token
- **Expected Response**: 200 with user data and JWT token
- **Action**: Update `auth_token` if needed

#### 1.3 Verify Token
- **Request**: `POST /api/users/verify-token`
- **Purpose**: Test token validation
- **Expected Response**: 200 with token validity

#### 1.4 Get User Profile
- **Request**: `GET /api/users/profile`
- **Purpose**: Test authenticated user data retrieval
- **Expected Response**: 200 with user profile

#### 1.5 Get User Dashboard
- **Request**: `GET /api/users/dashboard`
- **Purpose**: Test dashboard data (should be empty initially)
- **Expected Response**: 200 with empty dashboard data

---

### **Phase 2: Group Management**

#### 2.1 Create Group
- **Request**: `POST /api/groups`
- **Purpose**: Create the first group
- **Expected Response**: 201 with group data
- **Action**: Copy `group_id` from response to environment variable

#### 2.2 Get User Groups
- **Request**: `GET /api/groups`
- **Purpose**: Verify group appears in user's groups
- **Expected Response**: 200 with array containing the created group

#### 2.3 Get Group Details
- **Request**: `GET /api/groups/{group_id}`
- **Purpose**: Test group retrieval
- **Expected Response**: 200 with group details

#### 2.4 Get Group with Members
- **Request**: `GET /api/groups/{group_id}/with-members`
- **Purpose**: Test group with member details
- **Expected Response**: 200 with group and creator as member
- **Action**: Copy `creator_member_id` from response

#### 2.5 Add Non-Registered Member
- **Request**: `POST /api/groups/{group_id}/members`
- **Purpose**: Add a non-user member
- **Expected Response**: 201 with member data
- **Action**: Copy `member_id` from response

#### 2.6 Get Group Members
- **Request**: `GET /api/groups/{group_id}/members`
- **Purpose**: Verify both members are present
- **Expected Response**: 200 with array of 2 members

---

### **Phase 3: Simple Expense Creation**

#### 3.1 Create Simple Expense
- **Request**: `POST /api/expenses`
- **Purpose**: Create expense without items
- **Expected Response**: 201 with expense data
- **Action**: Copy `expense_id` from response

#### 3.2 Get Expense (Smart)
- **Request**: `GET /api/expenses/{expense_id}`
- **Purpose**: Test smart expense retrieval
- **Expected Response**: 200 with expense (no items)

#### 3.3 Get Expense with Details
- **Request**: `GET /api/expenses/{expense_id}/details`
- **Purpose**: Test detailed expense retrieval
- **Expected Response**: 200 with expense, payers, splits

#### 3.4 Get Group Expenses
- **Request**: `GET /api/expenses/group/{group_id}`
- **Purpose**: Test group expense listing
- **Expected Response**: 200 with array containing the expense

#### 3.5 Get Expense Settlement
- **Request**: `GET /api/expenses/{expense_id}/settlement`
- **Purpose**: Test settlement calculation
- **Expected Response**: 200 with settlement data

---

### **Phase 4: Complex Expense with Items**

#### 4.1 Create Complex Expense
- **Request**: `POST /api/expenses` (with items and assignments)
- **Purpose**: Create expense with items and assignments
- **Expected Response**: 201 with expense, items, and assignments
- **Action**: Copy new `expense_id`, `item_id`, `assignment_id`

#### 4.2 Get Expense (Smart with Items)
- **Request**: `GET /api/expenses/{expense_id}`
- **Purpose**: Test smart detection of items
- **Expected Response**: 200 with expense AND items

#### 4.3 Get Items for Expense
- **Request**: `GET /api/items/expense/{expense_id}`
- **Purpose**: Test item retrieval
- **Expected Response**: 200 with items array

#### 4.4 Get Assignments for Expense
- **Request**: `GET /api/assignments/expense/{expense_id}`
- **Purpose**: Test assignment retrieval
- **Expected Response**: 200 with assignments array

---

### **Phase 5: Item Management**

#### 5.1 Create Additional Item
- **Request**: `POST /api/items/expense/{expense_id}`
- **Purpose**: Add item to existing expense
- **Expected Response**: 201 with item data
- **Action**: Copy new `item_id`

#### 5.2 Get Specific Item
- **Request**: `GET /api/items/{item_id}`
- **Purpose**: Test individual item retrieval
- **Expected Response**: 200 with item details

#### 5.3 Update Item
- **Request**: `PUT /api/items/{item_id}`
- **Purpose**: Test item updates
- **Expected Response**: 200 with updated item

#### 5.4 Create Items from OCR
- **Request**: `POST /api/items/expense/{expense_id}/ocr`
- **Purpose**: Test OCR item creation
- **Expected Response**: 201 with created items

#### 5.5 Get Item Statistics
- **Request**: `GET /api/items/expense/{expense_id}/stats`
- **Purpose**: Test item statistics
- **Expected Response**: 200 with statistics

#### 5.6 Search Items
- **Request**: `GET /api/items/expense/{expense_id}/search?q=milk`
- **Purpose**: Test item search
- **Expected Response**: 200 with matching items

---

### **Phase 6: Assignment Management**

#### 6.1 Create Assignment
- **Request**: `POST /api/assignments/expense/{expense_id}`
- **Purpose**: Create new assignment
- **Expected Response**: 201 with assignment data
- **Action**: Copy new `assignment_id`

#### 6.2 Get Specific Assignment
- **Request**: `GET /api/assignments/{assignment_id}`
- **Purpose**: Test individual assignment retrieval
- **Expected Response**: 200 with assignment details

#### 6.3 Update Assignment
- **Request**: `PUT /api/assignments/{assignment_id}`
- **Purpose**: Test assignment updates
- **Expected Response**: 200 with updated assignment

#### 6.4 Add Users to Assignment
- **Request**: `POST /api/assignments/{assignment_id}/users`
- **Purpose**: Test adding users to assignment
- **Expected Response**: 200 with updated assignment

#### 6.5 Get Assignment Summary
- **Request**: `GET /api/assignments/expense/{expense_id}/summary`
- **Purpose**: Test assignment summary
- **Expected Response**: 200 with summary data

---

### **Phase 7: Payment Management**

#### 7.1 Create Payment
- **Request**: `POST /api/payments`
- **Purpose**: Create settlement payment
- **Expected Response**: 201 with payment data
- **Action**: Copy `payment_id`

#### 7.2 Get Group Payments
- **Request**: `GET /api/payments/group/{group_id}`
- **Purpose**: Test payment listing
- **Expected Response**: 200 with payments array

#### 7.3 Get Payment Summary
- **Request**: `GET /api/payments/group/{group_id}/summary`
- **Purpose**: Test payment summary
- **Expected Response**: 200 with summary data

#### 7.4 Get Debt Relationships
- **Request**: `GET /api/payments/group/{group_id}/debts`
- **Purpose**: Test debt calculation
- **Expected Response**: 200 with debt relationships

#### 7.5 Mark Payment Completed
- **Request**: `PUT /api/payments/{payment_id}/complete`
- **Purpose**: Test payment status update
- **Expected Response**: 200 with updated payment

---

### **Phase 8: OCR Testing**

#### 8.1 Get OCR Statistics
- **Request**: `GET /api/ocr/stats`
- **Purpose**: Test OCR statistics
- **Expected Response**: 200 with statistics

#### 8.2 Validate OCR Configuration
- **Request**: `GET /api/ocr/config`
- **Purpose**: Test OCR configuration
- **Expected Response**: 200 with configuration status

#### 8.3 Process Receipt from URL (Optional)
- **Request**: `POST /api/ocr/process/{group_id}/url`
- **Purpose**: Test OCR processing
- **Note**: Requires valid image URL

---

## 🔍 Expected Results Summary

### **Database State After Testing**
- **Users**: 1 registered user
- **Groups**: 1 group with 2 members (1 registered, 1 non-registered)
- **Expenses**: 2 expenses (1 simple, 1 complex)
- **Items**: Multiple items across expenses
- **Assignments**: Multiple assignments linking items to members
- **Payments**: 1 payment for settlement

### **Key Features Validated**
✅ User registration and authentication  
✅ Group creation and member management  
✅ Simple expense creation and retrieval  
✅ Complex expense with items and assignments  
✅ Item CRUD operations  
✅ Assignment management  
✅ Payment creation and settlement  
✅ OCR configuration and statistics  
✅ Smart GET endpoints  
✅ Permission-based access control  

---

## 🚨 Common Issues & Solutions

### **Authentication Errors (401)**
- Ensure `auth_token` is set in environment variables
- Check token hasn't expired (24 hours)
- Verify Authorization header format: `Bearer {token}`

### **Permission Errors (403)**
- Ensure user is member of the group
- Check group membership before accessing group resources
- Verify admin permissions for admin-only operations

### **Not Found Errors (404)**
- Check IDs are correctly set in environment variables
- Ensure resources exist before referencing them
- Verify correct endpoint paths

### **Validation Errors (400)**
- Check request body format and required fields
- Ensure monetary amounts are numbers, not strings
- Verify date formats (YYYY-MM-DD)

### **Database Connection Issues**
- Ensure PostgreSQL is running
- Check database credentials in `.env`
- Verify database exists and is accessible

---

## 📊 Success Criteria

### **All Tests Pass When:**
- ✅ No 401/403/404/500 errors
- ✅ All CRUD operations return expected data
- ✅ Relationships between entities are maintained
- ✅ Smart GET endpoints work correctly
- ✅ Environment variables are properly updated
- ✅ Database state is consistent

### **Performance Indicators:**
- Response times < 500ms for simple operations
- Response times < 1000ms for complex operations
- No memory leaks or connection issues
- Consistent data integrity

---

## 🎯 Next Steps After Testing

1. **Frontend Integration**: Use validated endpoints in Flutter app
2. **Production Deployment**: Configure production environment
3. **Advanced Features**: Add bulk operations, templates, etc.
4. **Performance Optimization**: Add caching, pagination, etc.
5. **Security Hardening**: Add rate limiting, input sanitization, etc.

---

## 📞 Support

If you encounter issues during testing:
1. Check the server logs for detailed error messages
2. Verify database state with direct SQL queries
3. Review the API documentation for endpoint details
4. Check environment variable configuration
5. Ensure all dependencies are installed and running 