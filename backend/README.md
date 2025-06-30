# Backend

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