# V-Serve ARTA Feedback Analytics

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

**A comprehensive Client Satisfaction Survey (CSS) platform for the Anti-Red Tape Authority (ARTA)**

[Features](#-features) • [Installation](#-installation) • [Usage](#-usage) • [Architecture](#-architecture) • [Contributing](#-contributing)

</div>

---

## 📋 Overview

V-Serve ARTA Feedback Analytics is a centralized platform designed to collect, analyze, and report feedback on government service transactions through the **ARTA Client Satisfaction Measurement (CSM)** initiative. Built with Flutter for cross-platform support (Web, Desktop, Mobile), the system enables government agencies to measure service quality and improve citizen experiences.

The platform implements the official ARTA Client Satisfaction Survey methodology, which includes:
- **User Demographics** (Client Profile)
- **Citizen's Charter Awareness** (CC0-CC3 ratings)
- **Service Quality Dimensions** (SQD0-SQD8 ratings)
- **Open Feedback & Suggestions**

---

## ✨ Features

### 📊 Survey Collection
- **Multi-step Survey Flow**: Guided survey experience with progress indicators
- **Responsive Design**: Works seamlessly on web, desktop, and mobile devices
- **Offline Support**: Queue submissions when offline, auto-sync when connected
- **QR Code Generation**: Generate QR codes for easy survey distribution

### 📈 Analytics Dashboard
- **Real-time Analytics**: Live charts and statistics powered by FL Chart
- **Demographic Insights**: Breakdown by age, sex, region, and client type
- **Service Quality Metrics**: Radar charts for SQD dimensions
- **Citizen's Charter Analysis**: Track awareness and effectiveness ratings
- **Trend Analysis**: Monitor satisfaction trends over time

### 👥 Admin Panel
- **Role-Based Access Control**: Admin, Viewer, and custom roles
- **User Management**: Create, edit, and manage admin users
- **Survey Configuration**: Toggle survey sections on/off
- **Customizable Questions**: Edit survey questions via admin interface
- **Audit Logging**: Track all admin actions for compliance

### 📤 Data Export
- **Multiple Formats**: Export data as CSV, JSON, or PDF
- **Advanced Filtering**: Filter by date range, demographics, ratings
- **Bulk Export**: Export selected or all survey responses
- **Print Support**: Generate printable reports

### 🔒 Security
- **Firebase Authentication**: Secure admin authentication
- **Firestore Security Rules**: Row-level security for data access
- **Password Hashing**: BCrypt for secure password storage
- **Audit Trail**: Complete logging of administrative actions

---

## 🚀 Installation

### Prerequisites

- **Flutter SDK**: Version 3.9.2 or higher
- **Node.js**: Version 18+ (for backend/optional)
- **Firebase Project**: With Firestore enabled
- **Git**: For version control

### Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-org/V-Serve-ARTA-Feedback-Analytics.git
   cd V-Serve-ARTA-Feedback-Analytics
   ```

2. **Install Flutter dependencies**
   ```bash
   cd frontend/arta_css
   flutter pub get
   ```
   
   Or use the bundled Flutter SDK (Windows):
   ```powershell
   cd frontend/arta_css
   ..\..\flutter\bin\flutter.bat pub get
   ```

3. **Configure Firebase**
   - Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Enable Firestore Database
   - Add your platform apps (Web, Android, iOS, etc.)
   - Download and place `firebase_options.dart` in `lib/`
   
   Or run:
   ```bash
   flutterfire configure
   ```

4. **Run the application**
   
   **Web:**
   ```bash
   flutter run -d chrome
   ```
   
   **Windows Desktop:**
   ```bash
   flutter run -d windows
   ```
   
   **macOS Desktop:**
   ```bash
   flutter run -d macos
   ```

---

## 📖 Usage

### Survey Flow (Public Users)

1. **Landing Page**: Users access the survey via URL or QR code
2. **User Profile**: Enter demographics (client type, age, sex, region, service)
3. **Citizen's Charter**: Rate awareness and visibility of service standards
4. **Service Quality**: Rate 9 dimensions of service quality (SQD0-SQD8)
5. **Suggestions**: Provide open feedback and optional email
6. **Thank You**: Confirmation and survey completion

### Admin Dashboard

1. **Login**: Access `/admin` route with admin credentials (click Valenzuela logo to return to survey)
2. **Analytics Tab**: View real-time charts and statistics
3. **Feedback Browser**: Search, filter, and view individual responses
4. **Survey Config**: Toggle survey sections and edit questions
5. **User Management**: Manage admin users and roles (Admin only)
6. **Settings**: Configure app preferences and export data

### Survey Questions

| Section | Questions |
|---------|-----------|
| **Citizen's Charter (CC)** | CC0: Awareness, CC1: Visibility, CC2: Posting, CC3: Understanding |
| **Service Quality (SQD)** | SQD0: Time spent, SQD1: Process steps, SQD2: Simplicity, SQD3: Information access, SQD4: Fees reasonability, SQD5: Fee transparency, SQD6: Fee equality, SQD7: Processing time, SQD8: Facility access |

---

## 🏗 Architecture

### Project Structure

```
V-Serve-ARTA-Feedback-Analytics/
├── frontend/arta_css/          # Flutter application (V-Serve)
│   ├── lib/
│   │   ├── main.dart           # App entry point
│   │   ├── models/             # Data models
│   │   │   ├── survey_data.dart
│   │   │   ├── user_model.dart
│   │   │   ├── audit_log_model.dart
│   │   │   └── export_filters.dart
│   │   ├── screens/
│   │   │   ├── admin/          # Admin dashboard screens
│   │   │   └── user_side/      # Survey flow screens
│   │   ├── services/           # Business logic & API
│   │   │   ├── auth_services.dart
│   │   │   ├── feedback_service.dart
│   │   │   ├── export_service.dart
│   │   │   ├── offline_queue.dart
│   │   │   └── ...
│   │   ├── widgets/            # Reusable components
│   │   └── utils/              # Helpers and utilities
│   ├── web/                    # Web-specific assets
│   ├── windows/                # Windows-specific config
│   └── pubspec.yaml            # Dependencies
├── backend/                    # Optional Express.js API
│   ├── src/
│   │   ├── index.js
│   │   └── firestore.js
│   └── scripts/                # Admin scripts
├── docs/                       # Documentation
├── flutter/                    # Bundled Flutter SDK
└── firebase.json               # Firebase hosting config
```

### Technology Stack

| Layer | Technology |
|-------|------------|
| **Frontend** | Flutter 3.9.2, Dart |
| **State Management** | Provider + ChangeNotifier |
| **Backend** | Firebase Firestore |
| **Authentication** | Firebase Auth (custom roles) |
| **Charts** | FL Chart |
| **PDF Generation** | pdf, printing packages |
| **Styling** | Google Fonts (Montserrat, Poppins) |
| **Desktop** | window_manager |
| **Hosting** | Vercel (web), Firebase Hosting |

### State Management Pattern

```dart
// Services extend ChangeNotifier
class FeedbackService extends ChangeNotifier {
  List<SurveyData> _feedbacks = [];
  
  Future<void> loadFeedbacks() async {
    // Fetch from Firestore
    notifyListeners();
  }
}

// Provided via MultiProvider in main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => FeedbackService()),
    ChangeNotifierProvider(create: (_) => AuthService()),
    // ...
  ],
  child: MyApp(),
)

// Consumed in widgets
Consumer<FeedbackService>(
  builder: (context, service, child) => ListView(...),
)
```

---

## 🔧 Development

### Commands

```bash
# Install dependencies
flutter pub get

# Run in debug mode
flutter run -d chrome          # Web
flutter run -d windows         # Windows
flutter run -d macos           # macOS

# Build for production
flutter build web --release
flutter build windows --release

# Run tests
flutter test

# Analyze code (should pass with 0 issues)
flutter analyze

# Format code
dart format lib/
```

### Environment Setup (Backend - Optional)

```bash
cd backend
npm install

# Set up Firebase Admin SDK
# Place serviceAccountKey.json in backend/

# Run development server
npm run dev
```

### Firestore Security Rules

The project includes security rules in `firestore.rules`:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Feedbacks: Anyone can create, only admins can read/update/delete
    match /feedbacks/{feedbackId} {
      allow create: if true;
      allow read, update, delete: if request.auth != null;
    }
    // Admin users: Only authenticated admins
    match /adminUsers/{userId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## 📊 Data Models

### SurveyData

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Firestore document ID |
| `clientType` | String | Type of client (Citizen, Business, Government) |
| `date` | DateTime | Date of service |
| `sex` | String | Gender of respondent |
| `age` | int | Age of respondent |
| `regionOfResidence` | String | Region from Philippines regions list |
| `serviceAvailed` | String | Service type availed |
| `cc0Rating` - `cc3Rating` | int | Citizen's Charter ratings (1-5) |
| `sqd0Rating` - `sqd8Rating` | int | Service Quality ratings (1-5) |
| `suggestions` | String | Open feedback text |
| `email` | String | Optional contact email |
| `submittedAt` | DateTime | Submission timestamp |

### User Roles

| Role | Permissions |
|------|-------------|
| **superadmin** | Full access: all CRUD, user management, config |
| **admin** | Analytics, feedback browser, export, config |
| **viewer** | Analytics, feedback browser (read-only) |

---

## 🤝 Contributing

### Branch Naming Convention

- `feature/<name>` - New features
- `fix/<name>` - Bug fixes
- `chore/<name>` - Maintenance tasks
- `docs/<name>` - Documentation updates

### Pull Request Process

1. Fork the repository
2. Create a feature branch
3. Make changes with proper commits
4. Run `flutter analyze` - ensure 0 issues
5. Submit PR with clear description

### Code Style

- Follow Flutter/Dart conventions
- Use `GoogleFonts.montserrat()` for headings
- Use `GoogleFonts.poppins()` for body text
- Check `mounted` after async operations
- Use `Color(0xFF003366)` as brand blue

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 📞 Support

For questions or support:
- Create an issue in this repository
- Contact the ARTA IT team

---

<div align="center">

**Built with ❤️ for better government services**

*Powered by Flutter & Firebase*

</div>
