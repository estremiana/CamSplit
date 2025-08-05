# CamSplit API Quick Reference

## Base URL
```
http://localhost:5000/api
```

## Authentication
```http
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

## Most Common Endpoints

### 🔐 Authentication
```http
POST /api/users/register
POST /api/users/login
GET /api/users/profile
```

### 👥 Groups
```http
POST /api/groups                    # Create group
GET /api/groups                     # Get user's groups
GET /api/groups/{id}/with-members   # Get group with members
POST /api/groups/{id}/members       # Add member
```

### 💰 Expenses
```http
POST /api/expenses                  # Create expense
GET /api/expenses/{id}/details      # Get expense details
PUT /api/expenses/{id}              # Update expense
DELETE /api/expenses/{id}           # Delete expense
GET /api/expenses/group/{groupId}   # Get group expenses
```

### 📊 Settlements
```http
GET /api/groups/{id}/settlements    # Get group settlements
POST /api/groups/{id}/settlements/recalculate  # Recalculate
POST /api/settlements/{id}/settle   # Mark as settled
```

## Common Request Examples

### Create Expense
```json
{
  "title": "Grocery Shopping",
  "total_amount": 100.00,
  "currency": "EUR",
  "date": "2025-08-01",
  "category": "Food & Dining",
  "group_id": 1,
  "split_type": "equal",
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
      "amount": 50.00
    },
    {
      "group_member_id": 2,
      "amount": 50.00
    }
  ]
}
```

### Update Expense (with percentage split)
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

### Create Group
```json
{
  "name": "Roommates",
  "description": "Monthly apartment expenses",
  "currency": "EUR"
}
```

### Add Member
```json
{
  "email": "newmember@example.com",
  "nickname": "New Member",
  "role": "member"
}
```

## Response Format
```json
{
  "success": true,
  "message": "Operation completed successfully",
  "data": { ... }
}
```

## Error Response
```json
{
  "success": false,
  "message": "Error description"
}
```

## Status Codes
- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `500` - Server Error

## Split Types
- `equal` - Divide equally among selected members
- `custom` - Each member has specific amount
- `percentage` - Divide based on percentages

## Quick Test with curl

### Login
```bash
curl -X POST http://localhost:5000/api/users/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

### Create Expense
```bash
curl -X POST http://localhost:5000/api/expenses \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Expense",
    "total_amount": 100.00,
    "group_id": 1,
    "split_type": "equal"
  }'
```

### Get Settlements
```bash
curl -X GET http://localhost:5000/api/groups/1/settlements \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Health Check
```bash
curl http://localhost:5000/health
``` 