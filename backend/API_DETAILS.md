# CamSplit Backend API – Detailed Endpoint & Model Documentation

## Table of Contents
- [User](#user)
- [Bill](#bill)
- [Item](#item)
- [Assignment](#assignment)
- [Participant](#participant)
- [Payment](#payment)
- [OCR](#ocr)

---

## User

### Model Fields
- `id`: integer
- `email`: string
- `password`: string (hashed, not returned in API)
- `name`: string
- `birthdate`: string (YYYY-MM-DD)
- `created_at`: string (ISO timestamp)

### Register (POST `/api/users/register`)
**Request:**
```json
{
  "email": "user@example.com",
  "password": "Password123",
  "name": "John Doe",
  "birthdate": "1990-01-01"
}
```
**Response:**
```json
{
  "message": "User registered successfully."
}
```

### Login (POST `/api/users/login`)
**Request:**
```json
{
  "email": "user@example.com",
  "password": "Password123"
}
```
**Response:**
```json
{
  "message": "Login successful.",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "name": "John Doe",
    "birthdate": "1990-01-01",
    "created_at": "2024-07-02T00:00:00.000Z"
  },
  "token": "JWT_TOKEN"
}
```

---

## Bill

### Model Fields
- `id`: integer
- `user_id`: integer (creator)
- `image_url`: string
- `created_at`: string (ISO timestamp)

### Upload Bill (POST `/api/bills/upload`)
**Request:** (multipart/form-data)
- `image`: file
- `user_id`: integer

**Response:**
```json
{
  "bill": {
    "id": 123,
    "user_id": 1,
    "image_url": "https://.../bill.jpg",
    "created_at": "2024-07-02T00:00:00.000Z"
  }
}
```

### Get Bill (GET `/api/bills/:id`)
**Response:**
```json
{
  "bill": {
    "id": 123,
    "user_id": 1,
    "image_url": "https://.../bill.jpg",
    "created_at": "2024-07-02T00:00:00.000Z"
  },
  "total": 45.67
}
```

### Settle Bill (GET `/api/bills/:id/settle`)
**Response:**
```json
{
  "participants": [
    {
      "id": 1,
      "name": "John Doe",
      "user_id": 1,
      "amount_owed": 15.00,
      "amount_paid": 10.00
    }
    // ...
  ],
  "payments": [
    {
      "id": 1,
      "from_participant_id": 2,
      "to_participant_id": 1,
      "amount": 5.00,
      "is_paid": false
    }
    // ...
  ]
}
```

---

## Item

### Model Fields
- `id`: integer
- `bill_id`: integer
- `name`: string
- `unit_price`: number
- `total_price`: number
- `quantity`: integer
- `quantity_left`: integer

### Add Items (POST `/api/bills/:billId/items`)
**Request:**
```json
{
  "items": [
    {
      "name": "Pizza",
      "quantity": 2,
      "unit_price": 10.00,
      "total_price": 20.00,
      "quantity_left": 2
    }
    // ...
  ]
}
```
**Response:**
```json
{
  "message": "Items added successfully.",
  "items": [
    {
      "id": 1,
      "bill_id": 123,
      "name": "Pizza",
      "quantity": 2,
      "unit_price": 10.00,
      "total_price": 20.00,
      "quantity_left": 2
    }
    // ...
  ]
}
```

### Get Items (GET `/api/bills/:billId/items`)
**Response:**
```json
{
  "items": [
    {
      "id": 1,
      "bill_id": 123,
      "name": "Pizza",
      "quantity": 2,
      "unit_price": 10.00,
      "total_price": 20.00,
      "quantity_left": 2
    }
    // ...
  ]
}
```

---

## Assignment

### Model Fields
- `id`: integer
- `bill_id`: integer
- `item_id`: integer
- `participant_id`: integer
- `quantity`: integer
- `cost_per_person`: number

### Assign Items (POST `/api/assignments`)
**Request:**
```json
{
  "items": [
    { "itemId": 1, "quantity": 1 }
    // ...
  ],
  "participantIds": [1, 2]
}
```
**Response:**
```json
{
  "message": "Assignments created successfully.",
  "assignments": [
    {
      "id": 1,
      "bill_id": 123,
      "item_id": 1,
      "participant_id": 1,
      "quantity": 1,
      "cost_per_person": 10.00
    }
    // ...
  ]
}
```

### Get Assignments (GET `/api/assignments/bill/:billId`)
**Response:**
```json
{
  "assignments": [
    {
      "id": 1,
      "bill_id": 123,
      "item_id": 1,
      "participant_id": 1,
      "quantity": 1,
      "cost_per_person": 10.00
    }
    // ...
  ]
}
```

---

## Participant

### Model Fields
- `id`: integer
- `bill_id`: integer
- `name`: string
- `user_id`: integer (nullable)
- `amount_paid`: number
- `amount_owed`: number

### Add Participant (POST `/api/bills/:billId/participants`)
**Request:**
```json
{
  "name": "Jane Smith",
  "user_id": 2
}
```
**Response:**
```json
{
  "participant": {
    "id": 2,
    "bill_id": 123,
    "name": "Jane Smith",
    "user_id": 2,
    "amount_paid": 0,
    "amount_owed": 0
  }
}
```

### Get Participants (GET `/api/bills/:billId/participants`)
**Response:**
```json
{
  "participants": [
    {
      "id": 1,
      "bill_id": 123,
      "name": "John Doe",
      "user_id": 1,
      "amount_paid": 10.00,
      "amount_owed": 15.00
    },
    {
      "id": 2,
      "bill_id": 123,
      "name": "Jane Smith",
      "user_id": 2,
      "amount_paid": 20.00,
      "amount_owed": 15.00
    }
    // ...
  ]
}
```

### Set Payments (POST `/api/bills/:billId/payments`)
**Request:**
```json
{
  "payments": [
    { "participantId": 1, "amount_paid": 10.00 },
    { "participantId": 2, "amount_paid": 20.00 }
  ]
}
```
**Response:**
```json
{
  "message": "Payments updated successfully."
}
```

---

## Payment

### Model Fields
- `id`: integer
- `bill_id`: integer
- `from_participant_id`: integer
- `to_participant_id`: integer
- `amount`: number
- `is_paid`: boolean

### Mark Payment as Paid (POST `/api/payments/:paymentId/pay`)
**Response:**
```json
{
  "message": "Payment marked as paid.",
  "payment": {
    "id": 1,
    "bill_id": 123,
    "from_participant_id": 2,
    "to_participant_id": 1,
    "amount": 5.00,
    "is_paid": true
  }
}
```

---

## OCR

### Extract Items (POST `/api/ocr/extract`)
**Request:**
```json
{
  "imageUrl": "https://.../bill.jpg"
}
```
**Response:**
```json
{
  "message": "Items extracted successfully.",
  "items": [
    {
      "name": "Pizza",
      "quantity": 2,
      "unit_price": 10.00,
      "total_price": 20.00
    }
    // ...
  ],
  "count": 3,
  "total": 45.67
}
```

---

**Note:** All endpoints return error messages in the form `{ "message": "..." }` with appropriate HTTP status codes. 