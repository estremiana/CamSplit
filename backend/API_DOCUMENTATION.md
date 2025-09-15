# CamSplit API Documentation

## Overview

The CamSplit API is a RESTful service for managing expense sharing and settlements between group members. It supports multiple split types (equal, custom, percentage), item-level assignments, and automated settlement calculations.

**Base URL:** `http://localhost:5000/api`  
**Version:** 1.0.0  
**Last Updated:** 2025-08-02

## Authentication

All protected endpoints require authentication using JWT tokens.

### Authentication Flow

1. **Register/Login** to get a JWT token
2. **Include token** in the `Authorization` header: `Bearer <token>`
3. **Token verification** is automatic for protected routes

### Headers

```
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

## Response Format

All API responses follow a consistent format:

### Success Response
```json
{
  "success": true,
  "message": "Operation completed successfully",
  "data": { ... }
}
```

### Error Response
```json
{
  "success": false,
  "message": "Error description",
  "errors": [ ... ] // Optional validation errors
}
```

## Endpoints

### Authentication & Users

#### Register User
```http
POST /api/users/register
```

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securepassword",
  "first_name": "John",
  "last_name": "Doe",
  "phone": "+1234567890" // Optional
}
```

**Response:**
```json
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "id": 1,
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "is_email_verified": false,
    "created_at": "2025-08-01T21:00:00.000Z"
  }
}
```

#### Login User
```http
POST /api/users/login
```

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securepassword"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": 1,
      "email": "user@example.com",
      "first_name": "John",
      "last_name": "Doe"
    }
  }
}
```

#### Verify Token
```http
POST /api/users/verify-token
```

**Request Body:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "valid": true,
    "user": {
      "id": 1,
      "email": "user@example.com",
      "first_name": "John",
      "last_name": "Doe"
    }
  }
}
```

#### Get User Profile
```http
GET /api/users/profile
```

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "phone": "+1234567890",
    "avatar": "https://example.com/avatar.jpg",
    "is_email_verified": true,
    "created_at": "2025-08-01T21:00:00.000Z"
  }
}
```

#### Update User Profile
```http
PUT /api/users/profile
```

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "first_name": "John",
  "last_name": "Smith",
  "phone": "+1234567890",
  "avatar": "https://example.com/new-avatar.jpg"
}
```

#### Update User Password
```http
PUT /api/users/password
```

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "current_password": "oldpassword",
  "new_password": "newpassword"
}
```

#### Get User Dashboard
```http
GET /api/users/dashboard
```

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 1,
      "email": "user@example.com",
      "first_name": "John",
      "last_name": "Doe",
      "phone": "+1234567890",
      "bio": "User bio",
      "birthdate": "1990-01-01",
      "avatar": "https://example.com/avatar.jpg",
      "is_email_verified": true,
      "timezone": "UTC",
      "preferences": {},
      "member_since": "2025-08-01T21:00:00.000Z",
      "created_at": "2025-08-01T21:00:00.000Z",
      "updated_at": "2025-08-01T21:00:00.000Z"
    },
    "groups": [
      {
        "id": 1,
        "name": "Roommates",
        "description": "Monthly apartment expenses",
        "currency": "EUR",
        "member_count": 3,
        "total_expenses": 1500.00,
        "created_at": "2025-08-01T21:00:00.000Z"
      }
    ],
    "recent_expenses": [
      {
        "id": 1,
        "title": "Grocery Shopping",
        "total_amount": 100.00,
        "currency": "EUR",
        "date": "2025-08-01",
        "category": "Food & Dining",
        "split_type": "equal",
        "created_by": 1,
        "group_name": "Roommates",
        "payer_nickname": "John",
        "amount_owed": 25.00
      }
    ],
    "payment_summary": {
      "total_to_pay": 75.00,
      "total_to_get_paid": 150.00,
      "balance": 75.00
    }
  }
}
```

#### Get User Payment Summary
```http
GET /api/users/payment-summary
```

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "success": true,
  "data": {
    "total_to_pay": 75.00,
    "total_to_get_paid": 150.00,
    "balance": 75.00
  }
}
```

#### Get User Statistics
```http
GET /api/users/stats
```

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "success": true,
  "data": {
    "total_groups": 3,
    "total_expenses": 15,
    "total_to_pay": 75.00,
    "total_to_get_paid": 150.00,
    "balance": 75.00,
    "average_expense": 25.00,
    "most_active_group": {
      "id": 1,
      "name": "Roommates",
      "description": "Monthly apartment expenses",
      "currency": "EUR",
      "created_at": "2025-08-01T21:00:00.000Z"
    }
  }
}
```

#### Get User Groups
```http
GET /api/users/groups
```

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Roommates",
      "description": "Monthly apartment expenses",
      "currency": "EUR",
      "member_count": 3,
      "total_expenses": 1500.00,
      "created_at": "2025-08-01T21:00:00.000Z"
    }
  ]
}
```

#### Get User Expenses
```http
GET /api/users/expenses
```

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
- `limit` (optional): Number of expenses to return (default: 10)
- `offset` (optional): Number of expenses to skip (default: 0)

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "title": "Grocery Shopping",
      "total_amount": 100.00,
      "currency": "EUR",
      "date": "2025-08-01",
      "category": "Food & Dining",
      "split_type": "equal",
      "created_by": 1
    }
  ]
}
```

#### Search Users
```http
GET /api/users/search?q=john&limit=10
```

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
- `q` (required): Search query (email or name)
- `limit` (optional): Number of results to return (default: 10)

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "email": "john@example.com",
      "first_name": "John",
      "last_name": "Doe",
      "name": "John Doe",
      "avatar": "https://example.com/avatar.jpg",
      "created_at": "2025-08-01T21:00:00.000Z"
    }
  ]
}
```

#### Check User Exists
```http
GET /api/users/exists?email=user@example.com
```

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
- `email` (required): Email address to check

**Response:**
```json
{
  "success": true,
  "data": {
    "exists": true
  }
}
```

#### Delete User Account
```http
DELETE /api/users/account
```

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "password": "currentpassword"
}
```

### Groups

#### Create Group
```http
POST /api/groups
```

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "name": "Roommates",
  "description": "Monthly apartment expenses",
  "currency": "EUR",
  "image_url": "https://example.com/group-image.jpg" // Optional
}
```

**Response:**
```json
{
  "success": true,
  "message": "Group created successfully",
  "data": {
    "id": 1,
    "name": "Roommates",
    "description": "Monthly apartment expenses",
    "currency": "EUR",
    "created_by": 1,
    "created_at": "2025-08-01T21:00:00.000Z"
  }
}
```

#### Get User Groups
```http
GET /api/groups
```

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Roommates",
      "description": "Monthly apartment expenses",
      "currency": "EUR",
      "member_count": 3,
      "total_expenses": 1500.00,
      "created_at": "2025-08-01T21:00:00.000Z"
    }
  ]
}
```

#### Search Groups
```http
GET /api/groups/search?q=roommates
```

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
- `q` (required): Search query
- `limit` (optional): Number of results to return (default: 10)

#### Get Invitable Groups
```http
GET /api/groups/invitable
```

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Roommates",
      "description": "Monthly apartment expenses",
      "currency": "EUR",
      "member_count": 3,
      "created_at": "2025-08-01T21:00:00.000Z"
    }
  ]
}
```

#### Get Group Details
```http
GET /api/groups/{groupId}
```

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Roommates",
    "description": "Monthly apartment expenses",
    "currency": "EUR",
    "created_by": 1,
    "created_at": "2025-08-01T21:00:00.000Z"
  }
}
```

#### Get Group with Members
```http
GET /api/groups/{groupId}/with-members
```

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Roommates",
    "description": "Monthly apartment expenses",
    "currency": "EUR",
    "members": [
      {
        "id": 1,
        "nickname": "John Doe",
        "email": "john@example.com",
        "role": "admin",
        "is_registered_user": true,
        "user_name": "John Doe",
        "user_avatar": "https://example.com/avatar.jpg"
      }
    ]
  }
}
```

#### Update Group
```http
PUT /api/groups/{groupId}
```

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "name": "Updated Roommates",
  "description": "Updated description",
  "currency": "USD",
  "image_url": "https://example.com/new-image.jpg"
}
```

#### Upload Group Image
```http
PUT /api/groups/{groupId}/image
```

**Headers:** `Authorization: Bearer <token>`

**Request Body:** `multipart/form-data`
- `image`: Image file (JPEG, PNG, WebP, max 5MB)

**Response:**
```json
{
  "success": true,
  "message": "Group image uploaded successfully",
  "data": {
    "group": {
      "id": 1,
      "name": "Roommates",
      "description": "Monthly expenses",
      "image_url": "https://res.cloudinary.com/example/image/upload/v1234567890/groups/group_123.jpg",
      "currency": "USD",
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-01T00:00:00Z"
    },
    "image_url": "https://res.cloudinary.com/example/image/upload/v1234567890/groups/group_123.jpg",
    "public_id": "groups/group_123"
  }
}
```

#### Delete Group
```http
DELETE /api/groups/{groupId}
```

**Headers:** `Authorization: Bearer <token>`

#### Delete Group with Cascade
```http
DELETE /api/groups/{groupId}/cascade
```

**Headers:** `Authorization: Bearer <token>`

**Description:** Deletes the group and all related data (expenses, settlements, members, etc.) in the correct order to handle foreign key constraints.

**Response:**
```json
{
  "success": true,
  "message": "Group and all related data deleted successfully"
}
```

#### Exit Group
```http
POST /api/groups/{groupId}/exit
```

**Headers:** `Authorization: Bearer <token>`

**Description:** Allows a user to exit a group. If they are the last registered user, the group will be automatically deleted.

**Response:**
```json
{
  "success": true,
  "message": "Successfully exited the group",
  "data": {
    "action": "user_exited"
  }
}
```

**Or if group is deleted:**
```json
{
  "success": true,
  "message": "Group deleted as no registered users remain",
  "data": {
    "action": "group_deleted"
  }
}
```

#### Check Group Auto-Delete Status
```http
GET /api/groups/{groupId}/auto-delete-status
```

**Headers:** `Authorization: Bearer <token>`

**Description:** Checks if a group should be auto-deleted (no registered users remain).

**Response:**
```json
{
  "success": true,
  "data": {
    "shouldAutoDelete": false
  }
}
```

#### Get Group Members
```http
GET /api/groups/{groupId}/members
```

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "nickname": "John Doe",
      "email": "john@example.com",
      "role": "admin",
      "is_registered_user": true,
      "user_name": "John Doe",
      "user_avatar": "https://example.com/avatar.jpg"
    }
  ]
}
```

#### Add Member to Group
```http
POST /api/groups/{groupId}/members
```

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "email": "newmember@example.com",
  "nickname": "New Member",
  "role": "member" // Optional, defaults to "member"
}
```

#### Remove Member from Group
```http
DELETE /api/groups/{groupId}/members/{memberId}
```

**Headers:** `Authorization: Bearer <token>`

#### Claim Member (Link to User Account)
```http
PUT /api/groups/{groupId}/members/{memberId}/claim
```

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "email": "member@example.com",
  "password": "password"
}
```

#### Invite User to Group
```http
POST /api/groups/{groupId}/invite
```

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "email": "invite@example.com",
  "message": "Join our expense group!" // Optional
}
```

#### Get Group Expenses
```http
GET /api/groups/{groupId}/expenses
```

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
- `limit` (optional): Number of expenses to return (default: 50)
- `offset` (optional): Number of expenses to skip (default: 0)
- `category` (optional): Filter by category
- `from_date` (optional): Filter expenses from this date
- `to_date` (optional): Filter expenses to this date

#### Get Group Payment Summary
```http
GET /api/groups/{groupId}/payment-summary
```

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "member_id": 1,
      "nickname": "John Doe",
      "user_id": 1,
      "total_paid": 100.00,
      "total_to_pay": 50.00,
      "total_to_get_paid": 25.00,
      "balance": -25.00
    },
    {
      "member_id": 2,
      "nickname": "Jane Smith",
      "user_id": 2,
      "total_paid": 75.00,
      "total_to_pay": 25.00,
      "total_to_get_paid": 50.00,
      "balance": 25.00
    }
  ]
}
```

#### Get Group Statistics
```http
GET /api/groups/{groupId}/stats
```

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "success": true,
  "data": {
    "total_members": 3,
    "registered_members": 2,
    "non_registered_members": 1,
    "total_expenses": 15,
    "total_amount": 1500.00,
    "average_expense": 100.00,
    "total_paid": 175.00,
    "total_to_pay": 75.00,
    "total_to_get_paid": 75.00,
    "net_balance": 0.00
  }
}
```

#### Check Group Permission
```http
GET /api/groups/{groupId}/permissions
```

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "success": true,
  "data": {
    "is_member": true,
    "is_admin": false,
    "can_invite": true,
    "can_add_expenses": true,
    "can_edit_expenses": false,
    "can_delete_expenses": false,
    "can_manage_members": false
  }
}
```

### Expenses

#### Create Expense
```http
POST /api/expenses
```

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "title": "Grocery Shopping",
  "total_amount": 100.00,
  "currency": "EUR",
  "date": "2025-08-01",
  "category": "Food & Dining",
  "notes": "Weekly groceries",
  "group_id": 1,
  "split_type": "equal", // "equal", "custom", "percentage"
  "receipt_image_url": "https://example.com/receipt.jpg", // Optional
  "payers": [
    {
      "group_member_id": 1,
      "amount_paid": 100.00,
      "payment_method": "cash"
    }
  ],
  "participant_amounts": [
    {
      "group_member_id": 1,
      "amount": 50.00,
      "percentage": 50.0 // Only for percentage splits
    },
    {
      "group_member_id": 2,
      "amount": 50.00,
      "percentage": 50.0
    }
  ]
}
```

**Response:**
```json
{
  "success": true,
  "message": "Expense created successfully",
  "data": {
    "id": 1,
    "title": "Grocery Shopping",
    "total_amount": 100.00,
    "currency": "EUR",
    "date": "2025-08-01",
    "category": "Food & Dining",
    "group_id": 1,
    "split_type": "equal",
    "created_by": 1,
    "created_at": "2025-08-01T21:00:00.000Z"
  }
}
```

#### Get User Expenses
```http
GET /api/expenses
```

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
- `limit` (optional): Number of expenses to return (default: 10)
- `offset` (optional): Number of expenses to skip (default: 0)

#### Search Expenses
```http
GET /api/expenses/search?q=grocery
```

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
- `q` (required): Search query
- `limit` (optional): Number of results to return (default: 10)

#### Get Expense Details
```http
GET /api/expenses/{expenseId}
```

**Headers:** `Authorization: Bearer <token>`

#### Get Expense with Details
```http
GET /api/expenses/{expenseId}/details
```

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "title": "Grocery Shopping",
    "total_amount": 100.00,
    "currency": "EUR",
    "date": "2025-08-01",
    "category": "Food & Dining",
    "group_id": 1,
    "split_type": "equal",
    "created_by": 1,
    "payers": [
      {
        "id": 1,
        "group_member_id": 1,
        "amount_paid": 100.00,
        "payment_method": "cash"
      }
    ],
    "participant_amounts": [
      {
        "id": 1,
        "group_member_id": 1,
        "amount": 50.00,
        "split_type": "equal",
        "percentage": null
      },
      {
        "id": 2,
        "group_member_id": 2,
        "amount": 50.00,
        "split_type": "equal",
        "percentage": null
      }
    ]
  }
}
```

#### Update Expense
```http
PUT /api/expenses/{expenseId}
```

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "title": "Updated Grocery Shopping",
  "total_amount": 120.00,
  "split_type": "percentage",
  "participant_amounts": [
    {
      "group_member_id": 1,
      "amount": 72.00,
      "percentage": 60.0
    },
    {
      "group_member_id": 2,
      "amount": 48.00,
      "percentage": 40.0
    }
  ]
}
```

**Note:** This endpoint automatically recalculates settlements after updating the expense.

#### Delete Expense
```http
DELETE /api/expenses/{expenseId}
```

**Headers:** `Authorization: Bearer <token>`

**Note:** This endpoint automatically recalculates settlements after deleting the expense.

#### Get Expense Settlement
```http
GET /api/expenses/{expenseId}/settlement
```

**Headers:** `Authorization: Bearer <token>`

#### Add Payer to Expense
```http
POST /api/expenses/{expenseId}/payers
```

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "group_member_id": 1,
  "amount_paid": 50.00,
  "payment_method": "cash"
}
```

#### Remove Payer from Expense
```http
DELETE /api/expenses/{expenseId}/payers/{payerId}
```

**Headers:** `Authorization: Bearer <token>`

#### Add Split to Expense
```http
POST /api/expenses/{expenseId}/splits
```

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "group_member_id": 1,
  "amount": 50.00,
  "percentage": 50.0 // Only for percentage splits
}
```

#### Remove Split from Expense
```http
DELETE /api/expenses/{expenseId}/splits/{splitId}
```

**Headers:** `Authorization: Bearer <token>`

#### Get Group Expenses
```http
GET /api/expenses/group/{groupId}
```

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
- `limit` (optional): Number of expenses to return (default: 50)
- `offset` (optional): Number of expenses to skip (default: 0)
- `category` (optional): Filter by category
- `from_date` (optional): Filter expenses from this date
- `to_date` (optional): Filter expenses to this date

**Response:**
```json
{
  "success": true,
  "data": {
    "expenses": [
      {
        "id": 1,
        "title": "Grocery Shopping",
        "total_amount": 100.00,
        "currency": "EUR",
        "date": "2025-08-01",
        "category": "Food & Dining",
        "split_type": "equal",
        "created_by": 1
      }
    ],
    "total_count": 1,
    "total_amount": 100.00
  }
}
```

#### Get Group Expense Statistics
```http
GET /api/expenses/group/{groupId}/stats
```

**Headers:** `Authorization: Bearer <token>`

### Settlements

#### Get Group Settlements
```http
GET /api/groups/{groupId}/settlements
```

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "success": true,
  "data": {
    "settlements": [
      {
        "id": 1,
        "from_group_member_id": 1,
        "to_group_member_id": 2,
        "amount": 25.00,
        "currency": "EUR",
        "status": "active",
        "from_member": {
          "id": 1,
          "nickname": "John Doe"
        },
        "to_member": {
          "id": 2,
          "nickname": "Jane Smith"
        }
      }
    ],
    "metadata": {
      "calculation_timestamp": "2025-08-01T21:00:00.000Z",
      "total_amount": 25.00,
      "settlement_count": 1,
      "members_involved": 2
    }
  }
}
```

#### Get Settlement History
```http
GET /api/groups/{groupId}/settlements/history
```

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
- `limit` (optional): Number of settlements to return (default: 50)
- `offset` (optional): Number of settlements to skip (default: 0)
- `from_date` (optional): Filter settlements from this date
- `to_date` (optional): Filter settlements to this date

#### Recalculate Settlements
```http
POST /api/groups/{groupId}/settlements/recalculate
```

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "cleanup_obsolete": true,
  "cleanup_days": 7
}
```

**Response:**
```json
{
  "success": true,
  "message": "Settlements recalculated successfully",
  "data": {
    "settlements": [ ... ],
    "balances": [ ... ],
    "summary": {
      "total_settlements": 1,
      "total_amount": 25.00,
      "members_involved": 2,
      "cleaned_up_settlements": 0
    }
  }
}
```

#### Batch Settle Settlements
```http
POST /api/groups/{groupId}/settlements/batch-settle
```

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "settlement_ids": [1, 2, 3]
}
```

#### Get Settlement Statistics
```http
GET /api/groups/{groupId}/settlements/statistics
```

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "success": true,
  "data": {
    "total_members": 3,
    "members_with_balance": 2,
    "creditors_count": 1,
    "debtors_count": 1,
    "total_debt": 25.00,
    "total_credit": 25.00,
    "balance_difference": 0.00,
    "max_transactions_without_optimization": 1,
    "theoretical_min_transactions": 1
  }
}
```

#### Get Settlement Analytics
```http
GET /api/groups/{groupId}/settlements/analytics
```

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
- `from_date` (optional): Start date for analytics
- `to_date` (optional): End date for analytics

#### Export Settlement History
```http
GET /api/groups/{groupId}/settlements/export
```

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
- `status` (optional): Filter by status
- `from_date` (optional): Filter from this date
- `to_date` (optional): Filter to this date
- `from_member_id` (optional): Filter by from member
- `to_member_id` (optional): Filter by to member
- `min_amount` (optional): Minimum amount filter
- `max_amount` (optional): Maximum amount filter

#### Get Settlement Details
```http
GET /api/settlements/{settlementId}
```

**Headers:** `Authorization: Bearer <token>`

#### Get Settlement Preview
```http
GET /api/settlements/{settlementId}/preview
```

**Headers:** `Authorization: Bearer <token>`

#### Settle Individual Settlement
```http
POST /api/settlements/{settlementId}/settle
```

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "success": true,
  "message": "Settlement marked as settled",
  "data": {
    "id": 1,
    "status": "settled",
    "settled_at": "2025-08-01T21:00:00.000Z",
    "settled_by": 1
  }
}
```

#### Get Settlement Audit Trail
```http
GET /api/settlements/{settlementId}/audit
```

**Headers:** `Authorization: Bearer <token>`

### Payments

#### Create Payment
```http
POST /api/payments
```

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "group_id": 1,
  "from_group_member_id": 1,
  "to_group_member_id": 2,
  "amount": 25.00,
  "currency": "EUR",
  "payment_method": "bank_transfer",
  "notes": "Settlement payment"
}
```

#### Get User Payments
```http
GET /api/payments
```

**Headers:** `Authorization: Bearer <token>`

#### Get Payment Details
```http
GET /api/payments/{paymentId}
```

**Headers:** `Authorization: Bearer <token>`

#### Get Payment with Details
```http
GET /api/payments/{paymentId}/details
```

**Headers:** `Authorization: Bearer <token>`

#### Update Payment
```http
PUT /api/payments/{paymentId}
```

**Headers:** `Authorization: Bearer <token>`

#### Update Payment Status
```http
PUT /api/payments/{paymentId}/status
```

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "status": "completed"
}
```

#### Delete Payment
```http
DELETE /api/payments/{paymentId}
```

**Headers:** `Authorization: Bearer <token>`

#### Mark Payment as Completed
```http
PUT /api/payments/{paymentId}/complete
```

**Headers:** `Authorization: Bearer <token>`

#### Mark Payment as Cancelled
```http
PUT /api/payments/{paymentId}/cancel
```

**Headers:** `Authorization: Bearer <token>`

#### Get Group Payments
```http
GET /api/payments/group/{groupId}
```

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
- `status` (optional): Filter by status ("pending", "completed", "cancelled")
- `from_date` (optional): Filter payments from this date
- `to_date` (optional): Filter payments to this date

#### Get Pending Payments
```http
GET /api/payments/group/{groupId}/pending
```

**Headers:** `Authorization: Bearer <token>`

#### Get Group Payment Summary
```http
GET /api/payments/group/{groupId}/summary
```

**Headers:** `Authorization: Bearer <token>`

#### Get Group Debt Relationships
```http
GET /api/payments/group/{groupId}/debts
```

**Headers:** `Authorization: Bearer <token>`

#### Create Settlement Payments
```http
POST /api/payments/group/{groupId}/settle
```

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "settlement_ids": [1, 2, 3]
}
```

### Items & Assignments

#### Get Expense Items
```http
GET /api/items/expense/{expenseId}
```

**Headers:** `Authorization: Bearer <token>`

#### Create Item
```http
POST /api/items/expense/{expenseId}
```

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "name": "Milk",
  "price": 2.50,
  "quantity": 2,
  "max_quantity": 4
}
```

#### Get Item Details
```http
GET /api/items/{itemId}
```

**Headers:** `Authorization: Bearer <token>`

#### Update Item
```http
PUT /api/items/{itemId}
```

**Headers:** `Authorization: Bearer <token>`

#### Delete Item
```http
DELETE /api/items/{itemId}
```

**Headers:** `Authorization: Bearer <token>`

#### Create Items from OCR
```http
POST /api/items/expense/{expenseId}/ocr
```

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "items": [
    {
      "name": "Milk",
      "price": 2.50,
      "quantity": 1
    }
  ]
}
```

#### Get Item Statistics
```http
GET /api/items/expense/{expenseId}/stats
```

**Headers:** `Authorization: Bearer <token>`

#### Search Items
```http
GET /api/items/expense/{expenseId}/search?q=milk
```

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
- `q` (required): Search query

#### Get Expense Assignments
```http
GET /api/assignments/expense/{expenseId}
```

**Headers:** `Authorization: Bearer <token>`

#### Create Assignment
```http
POST /api/assignments/expense/{expenseId}
```

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "item_id": 1,
  "quantity": 1,
  "unit_price": 2.50,
  "total_price": 2.50,
  "people_count": 2,
  "price_per_person": 1.25,
  "notes": "Shared between John and Jane",
  "group_member_ids": [1, 2]
}
```

#### Get Assignment Details
```http
GET /api/assignments/{assignmentId}
```

**Headers:** `Authorization: Bearer <token>`

#### Update Assignment
```http
PUT /api/assignments/{assignmentId}
```

**Headers:** `Authorization: Bearer <token>`

#### Delete Assignment
```http
DELETE /api/assignments/{assignmentId}
```

**Headers:** `Authorization: Bearer <token>`

#### Add Users to Assignment
```http
POST /api/assignments/{assignmentId}/users
```

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "group_member_ids": [1, 2]
}
```

#### Remove User from Assignment
```http
DELETE /api/assignments/{assignmentId}/users/{userId}
```

**Headers:** `Authorization: Bearer <token>`

#### Get Assignment Summary
```http
GET /api/assignments/expense/{expenseId}/summary
```

**Headers:** `Authorization: Bearer <token>`

### OCR (Receipt Processing)

#### Process Receipt Image (Simple)
```http
POST /api/ocr/process-simple
```

**Headers:** `Authorization: Bearer <token>`

**Request Body (multipart/form-data):**
```
image: [receipt image file]
```

**Response:**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "name": "Milk",
        "price": 2.50,
        "quantity": 1
      }
    ],
    "total_amount": 25.00,
    "merchant": "Supermarket",
    "date": "2025-08-01"
  }
}
```

#### Process Receipt Image (with Group Context)
```http
POST /api/ocr/process/{groupId}
```

**Headers:** `Authorization: Bearer <token>`

**Request Body (multipart/form-data):**
```
image: [receipt image file]
```

#### Process Receipt from URL
```http
POST /api/ocr/process/{groupId}/url
```

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "image_url": "https://example.com/receipt.jpg"
}
```

#### Get Receipt Images for Expense
```http
GET /api/ocr/expense/{expenseId}/images
```

**Headers:** `Authorization: Bearer <token>`

#### Delete Receipt Image
```http
DELETE /api/ocr/images/{receiptImageId}
```

**Headers:** `Authorization: Bearer <token>`

#### Re-process OCR for Existing Receipt Image
```http
POST /api/ocr/images/{receiptImageId}/reprocess
```

**Headers:** `Authorization: Bearer <token>`

#### Get OCR Statistics
```http
GET /api/ocr/stats
```

**Headers:** `Authorization: Bearer <token>`

#### Validate OCR Configuration
```http
GET /api/ocr/config
```

**Headers:** `Authorization: Bearer <token>`

#### Extract Items (Legacy)
```http
POST /api/ocr/extract
```

**Headers:** `Authorization: Bearer <token>`

**Request Body (multipart/form-data):**
```
image: [receipt image file]
```

## Error Codes

| Status Code | Description |
|-------------|-------------|
| 200 | Success |
| 201 | Created |
| 400 | Bad Request - Validation error or invalid data |
| 401 | Unauthorized - Invalid or missing authentication token |
| 403 | Forbidden - Insufficient permissions |
| 404 | Not Found - Resource doesn't exist |
| 409 | Conflict - Resource already exists or constraint violation |
| 422 | Unprocessable Entity - Business logic error |
| 429 | Too Many Requests - Rate limit exceeded |
| 500 | Internal Server Error - Server error |

## Rate Limiting

The API implements rate limiting to prevent abuse:

- **General endpoints:** 100 requests per minute
- **Settlement recalculation:** 10 requests per 5 minutes
- **Batch operations:** 20 requests per 5 minutes
- **Export operations:** 5 requests per 5 minutes
- **Settlement analytics:** 20 requests per minute
- **Settlement statistics:** 30 requests per minute

## Payment Summary Fields

The payment summary endpoints return balance information calculated from active settlements:

- **`total_to_pay`**: Total amount the user/group member owes to others (from settlements where they are the debtor)
- **`total_to_get_paid`**: Total amount others owe to the user/group member (from settlements where they are the creditor)
- **`balance`**: Net balance (`total_to_get_paid - total_to_pay`)
  - **Positive balance**: User is owed money (they should receive money)
  - **Negative balance**: User owes money (they should pay money)
  - **Zero balance**: User is settled up

**Note**: These calculations are based on active settlements only, which represent the optimized debt relationships between group members.

## Data Types

### Split Types
- `equal`: Amount divided equally among selected members
- `custom`: Each member has a specific amount assigned
- `percentage`: Amount divided based on percentages

### Payment Methods
- `cash`
- `card`
- `bank_transfer`
- `paypal`
- `venmo`
- `unknown`

### Settlement Status
- `active`: Settlement is pending
- `settled`: Settlement has been completed
- `obsolete`: Settlement is no longer valid

### Payment Status
- `pending`: Payment is pending
- `completed`: Payment has been completed
- `cancelled`: Payment has been cancelled

### Group Member Roles
- `admin`: Group administrator with full permissions
- `member`: Regular group member

## File Upload Limits

- **Maximum file size:** 10MB
- **Supported image formats:** JPEG, JPG, PNG, GIF, WebP
- **OCR processing:** Optimized for receipt images

## Testing

### Health Check
```http
GET /health
```

**Response:**
```json
{
  "success": true,
  "message": "CamSplit API is running",
  "timestamp": "2025-08-01T21:00:00.000Z",
  "version": "1.0.0"
}
```

### Test Environment

For testing purposes, you can use the following test data:

- **Test User:** `test@example.com` / `password123`
- **Test Group:** "Test Group" with ID 1
- **Test Expense:** "Test Expense" with ID 1

## Support

For API support and questions:

- **Documentation:** This file
- **Issues:** GitHub repository issues
- **Email:** support@camsplit.com

## Changelog

### v1.0.0 (2025-08-02)
- Complete API implementation
- User authentication and management
- Group management with member roles
- Expense management with multiple split types
- Settlement calculation system
- Payment tracking
- Item-level assignments
- OCR receipt processing
- Rate limiting and validation
- Comprehensive error handling 