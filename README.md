# CamSplit 📱💰

**Smart Receipt Scanning & Expense Splitting App**

CamSplit is a comprehensive expense-sharing application that revolutionizes how groups split bills by combining traditional expense tracking with AI-powered receipt scanning. Built with Flutter and Node.js, it solves the real-world problem of fairly splitting restaurant bills and shared expenses.

## 🌟 Key Features

### 📸 AI-Powered Receipt Scanning
- **Dual OCR Integration**: Azure Form Recognizer + Google Cloud Vision fallback
- **Intelligent Parsing**: Automatically extracts items, quantities, prices, and merchant info
- **Confidence Scoring**: Shows accuracy levels for extracted data
- **Manual Editing**: Review and correct AI-extracted information

### 💳 Flexible Expense Splitting
- **Item-Level Assignment**: Assign specific items to specific people
- **Multiple Split Types**: Equal split, custom amounts, percentage-based
- **Group Management**: Create and manage expense groups
- **Real-time Calculations**: Instant settlement calculations

### 🎯 Smart Features
- **Camera Integration**: Native camera capture with receipt detection
- **Cross-Platform**: Flutter app for iOS and Android
- **Offline Support**: Works without internet for basic features
- **Payment Tracking**: Track who paid what and settlement status
- **Visual Analytics**: Charts and graphs for expense insights

## 🏗️ Technology Stack

### Frontend (Flutter)
- **Framework**: Flutter 3.6+ with Dart
- **State Management**: Provider pattern with custom controllers
- **UI Components**: Material Design with custom theming
- **Charts**: fl_chart for data visualization
- **Camera**: Native camera integration with image processing

### Backend (Node.js/Express)
- **API**: RESTful API with JWT authentication
- **Database**: PostgreSQL with comprehensive schema
- **AI Services**: Azure Form Recognizer + Google Cloud Vision
- **File Storage**: Cloudinary for image hosting
- **Testing**: Jest with comprehensive test coverage

### Key Technologies
```
Frontend: Flutter, Dart, Provider, fl_chart, camera, image_picker
Backend: Node.js, Express.js, PostgreSQL, JWT, bcrypt
AI/ML: Azure Form Recognizer, Google Cloud Vision
Storage: Cloudinary, PostgreSQL
Testing: Jest, Flutter Test, Integration Tests
```

## 🗂️ Project Structure

```
CamSplit/
├── backend/                 # Node.js API server
│   ├── src/
│   │   ├── ai/             # OCR and AI services
│   │   ├── controllers/    # Route controllers
│   │   ├── models/         # Database models
│   │   ├── routes/         # Express routes
│   │   ├── services/       # Business logic
│   │   └── middleware/     # Auth, validation, etc.
│   ├── database/           # Database setup and migrations
│   ├── tests/              # Backend tests
│   └── postman/            # API testing collections
├── camsplit/               # Flutter mobile app
│   ├── lib/
│   │   ├── presentation/   # UI screens and widgets
│   │   ├── services/       # API and business services
│   │   ├── models/         # Data models
│   │   ├── controllers/    # State management
│   │   └── utils/          # Helper functions
│   ├── test/               # Flutter tests
│   └── integration_test/   # Integration tests
└── database/               # Database schema and setup
```

## 📊 API Documentation

Comprehensive API documentation is available in:
- [`backend/API_DOCUMENTATION.md`](backend/API_DOCUMENTATION.md)
- [`backend/API_QUICK_REFERENCE.md`](backend/API_QUICK_REFERENCE.md)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Azure Form Recognizer** for receipt OCR capabilities
- **Google Cloud Vision** for fallback OCR processing
- **Flutter Team** for the amazing cross-platform framework
- **Open Source Community** for various packages and tools

---

**Built with ❤️ for students, travelers, and anyone who's ever struggled with splitting bills fairly.**
