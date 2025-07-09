# Backend

**Detailed API endpoint and model/response documentation has been moved to [`API_DETAILS.md`](./API_DETAILS.md) for clarity and maintainability.**

Node.js/Express API for CamSplit App

## Setup

1. Install dependencies:
   ```bash
   npm install
   ```
2. Copy `.env.example` to `.env` and fill in your values.
3. Start the server:
   ```bash
   npm start
   ```

## Structure
- `src/ai/`: AI integration (OCR, parsing)
- `src/config/`: Configuration files
- `src/controllers/`: Route controllers
- `src/models/`: Data models
- `src/routes/`: Express routes
- `src/services/`: Business logic 

## API Endpoints Documentation

### User Endpoints

#### POST `/api/users/register`
- **Purpose:** Register a new user.
- **Request Body:**
  ```json
  {
    "email": "string",
    "password": "string", // min 8 chars, 1 uppercase, 1 lowercase, 1 number
    "name": "string",
    "birthdate": "YYYY-MM-DD"
  }
  ```
- **Response:**
  - `201 Created` `{ "message": "User registered successfully." }`
  - `400/409` error messages for validation or duplicate email

#### POST `/api/users/login`
- **Purpose:** Log in a user.
- **Request Body:**
  ```json
  {
    "email": "string",
    "password": "string"
  }
  ```
- **Response:**
  - `200 OK` 
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
  - `400/401` error messages for invalid credentials

---

### Bill Endpoints

#### POST `/api/bills/upload`
- **Purpose:** Upload a bill image (multipart/form-data)
- **Request:**
  - Form field `image`: the image file
  - Form field `user_id`: the user uploading
- **Response:**
  - `201 Created` `{ "bill": { ... } }`

#### GET `/api/bills/:id`
- **Purpose:** Get bill details and total
- **Response:**
  - `200 OK` `{ "bill": { ... }, "total": number }`

#### GET `/api/bills/:id/settle`
- **Purpose:** Calculate and return settlement info for a bill
- **Response:**
  - `200 OK` `{ "participants": [ ... ], "payments": [ ... ] }`

---

### Item Endpoints

#### POST `/api/bills/:billId/items`
- **Purpose:** Add items to a bill
- **Request Body:**
  ```json
  {
    "items": [
      {
        "description": "string",
        "quantity": number,
        "unit_price": number,
        "total_price": number
      }
    ]
  }
  ```
- **Response:**
  - `201 Created` `{ "message": "Items added successfully.", "items": [ ... ] }`

#### GET `/api/bills/:billId/items`
- **Purpose:** Get all items for a bill
- **Response:**
  - `200 OK` `{ "items": [ ... ] }`

---

### Assignment Endpoints

#### POST `/api/assignments`
- **Purpose:** Assign items to participants
- **Request Body:**
  ```json
  {
    "items": [ { "itemId": number, "quantity": number } ],
    "participantIds": [ number ]
  }
  ```
- **Response:**
  - `201 Created` `{ "message": "Assignments created successfully.", "assignments": [ ... ] }`

#### GET `/api/assignments/bill/:billId`
- **Purpose:** Get all assignments for a bill
- **Response:**
  - `200 OK` `{ "assignments": [ ... ] }`

---

### Participant Endpoints

#### POST `/api/bills/:billId/participants`
- **Purpose:** Add a participant to a bill
- **Request Body:**
  ```json
  {
    "name": "string",
    "user_id": number // optional if not registered
  }
  ```
- **Response:**
  - `201 Created` `{ "participant": { ... } }`

#### GET `/api/bills/:billId/participants`
- **Purpose:** Get all participants for a bill
- **Response:**
  - `200 OK` `{ "participants": [ ... ] }`

#### POST `/api/bills/:billId/payments`
- **Purpose:** Set how much each participant paid
- **Request Body:**
  ```json
  {
    "payments": [ { "participantId": number, "amount_paid": number } ]
  }
  ```
- **Response:**
  - `200 OK` `{ "message": "Payments updated successfully." }`

---

### Payments Endpoints

#### POST `/api/payments/:paymentId/pay`
- **Purpose:** Mark a payment as paid
- **Response:**
  - `200 OK` `{ "message": "Payment marked as paid.", "payment": { ... } }`

---

### OCR Endpoints

#### POST `/api/ocr/extract`
- **Purpose:** Extract items from a bill image using OCR
- **Request Body:**
  ```json
  {
    "imageUrl": "string"
  }
  ```
- **Response:**
  - `200 OK` `{ "message": "Items extracted successfully.", "items": [ ... ], "count": number, "total": number }`

---

**Note:** All endpoints return error messages in the form `{ "message": "..." }` with appropriate HTTP status codes. 