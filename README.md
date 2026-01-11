# Parakk ERP MVP

A comprehensive Educational Resource Planning (ERP) system built with Flutter and Firebase. Parakk ERP serves as a centralized platform for managing school operations, facilitating communication between students, teachers, and parents.

## 🚀 Features

- **Multi-Role Support**: Separate dashboards for Students, Teachers, and Parents
- **Real-time Data**: Firebase Firestore integration for live updates
- **Academic Management**: Attendance tracking, homework management, exam results
- **Communication Hub**: Built-in messaging and notice board system
- **Learning Resources**: Video lessons, practice tests, notes, and library resources
- **Analytics & Reporting**: Performance tracking and academic reports

## 📚 Documentation

Comprehensive documentation is available in the following files:

- **[DOCUMENTATION.md](./DOCUMENTATION.md)** - Complete project documentation including:
  - Project overview and architecture
  - Project structure
  - Application workflow
  - Data models
  - Services layer
  - Screens & navigation
  - Key features
  - Firebase configuration
  - Development guidelines
  - Getting started guide

- **[WORKFLOW.md](./WORKFLOW.md)** - Visual workflow diagrams including:
  - Authentication & onboarding flows
  - Student user journey
  - Teacher user journey
  - Data flow diagrams
  - Screen navigation maps

- **[lib/models/README.md](./lib/models/README.md)** - Detailed data model documentation

## 🛠️ Technology Stack

- **Framework**: Flutter (Dart SDK ^3.10.3)
- **Backend**: Firebase
  - Authentication: Firebase Auth
  - Database: Cloud Firestore
- **UI Framework**: Material Design 3

## 📋 Prerequisites

- Flutter SDK (^3.10.3)
- Firebase account and project
- Android Studio / VS Code with Flutter plugins

## 🚀 Quick Start

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd parakk-erp-mvp
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
   - Enable Authentication (Email/Password)
   - Create Firestore database
   - Download `google-services.json` and place in `android/app/`
   - Update `lib/firebase_options.dart` with your Firebase config

4. **Run the application**
   ```bash
   flutter run
   ```

For detailed setup instructions, see [DOCUMENTATION.md](./DOCUMENTATION.md#getting-started).

## 📱 Application Structure

```
lib/
├── main.dart                 # Application entry point
├── models/                   # Data models (20+ models)
├── screens/                  # UI screens
│   ├── student_features/     # Student-specific screens (22 screens)
│   └── teacher_features/    # Teacher-specific screens (20 screens)
└── services/                 # Business logic services
```

## 🎯 User Roles

### Student
- View attendance, timetable, and results
- Submit homework assignments
- Access learning resources (videos, notes, practice tests)
- Chat with teachers
- Track academic progress

### Teacher
- Mark attendance and manage classes
- Create homework assignments and exams
- Enter marks and generate reports
- Communicate with students and parents
- Track syllabus completion

### Parent
- View child's academic progress
- Track attendance and fees
- Communicate with teachers
- Access school notices and events

## 📖 Key Workflows

1. **Authentication Flow**: Role selection → Sign up → Onboarding → Dashboard
2. **Student Flow**: Dashboard → Learn → Connect → Profile
3. **Teacher Flow**: Home → My Class → Chat → Profile

For detailed workflow diagrams, see [WORKFLOW.md](./WORKFLOW.md).

## 🔧 Development

See [DOCUMENTATION.md](./DOCUMENTATION.md#development-guidelines) for:
- Code organization guidelines
- Naming conventions
- State management patterns
- Error handling best practices
- Performance optimization tips

## 📄 License

This project is private and proprietary.

## 👥 Support

For issues, feature requests, or contributions, please refer to the project repository.

---

**Version**: 1.0.0  
**Last Updated**: 2024
