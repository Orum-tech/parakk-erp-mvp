# Parakk ERP MVP

A next-generation Educational Resource Planning (ERP) system built with **Flutter** and **Firebase**. Parakk ERP delivers a high-performance, secure, and scalable platform for managing modern school operations, connecting Students, Teachers, Parents, and Administrators in real-time.

---

## 🚀 Key Features

### 🎓 For Students
- **Smart Learning**: Access video lessons, AI notes, and practice tests.
- **Academic Tracking**: View attendance, exam results, and timetable.
- **Connect**: Chat with teachers and clear doubts instantly.
- **Focus Mode**: Built-in study timer and productivity tools.

### 👨‍🏫 For Teachers
- **Classroom Management**: Digital attendance marking and student behavior tracking.
- **Academic Ops**: Create exams, assignments, and enter marks effortlessly.
- **Communication**: Direct messaging with students and parents.
- **Reports**: Automated report card generation and performance analytics.

### 👪 For Parents
- **Child Monitoring**: Real-time tracking of attendance, homework, and grades.
- **Fee Management**: View dues and payment history.
- **School Connect**: Direct access to notifications, events, and teacher contacts.

### 🛡️ For Administrators
- **User Management**: Creating and managing students, teachers, and staff.
- **School settings**: Configuring academic years, classes, and subjects.
- **Oversight**: Global view of school operations.

---

## ⚡ System Highlights (v1.1.0)

This system has been optimized for high scalability and security:

*   **Robust Authentication**: Transaction-based user creation prevents "zombie" accounts.
*   **Scalable Queries**: Optimized Firestore indexing and targeted queries (using `whereIn` and `array-contains`) ensure fast performance even with thousands of users.
*   **Parallel Processing**: Marks entry and complex data fetching operations are parallelized for UI responsiveness.
*   **Security First**: removed potentially dangerous "fetch-all" fallbacks to ensure strict data isolation.

---

## 🛠️ Technology Stack

*   **Frontend**: Flutter (Mobile & Web) - Material 3 Design
*   **Backend**: Firebase (Serverless)
    *   **Auth**: Secure Identity Platform
    *   **Firestore**: NoSQL Real-time Database
    *   **Storage**: Asset management
*   **State Management**: Provider / Stream-based architecture

---

## � Project Structure

```bash
lib/
├── main.dart                 # App Entry Point
├── models/                   # Type-safe Data Models
├── services/                 # Business Logic & API Layer
├── widgets/                  # Reusable UI Components
└── screens/                  # Application Screens
    ├── auth/                 # Login & Registration
    ├── student_features/     # Student Dashboard & Features
    ├── teacher_features/     # Teacher Dashboard & Features
    ├── parent_features/      # Parent Dashboard & Features
    └── school_admin/         # Admin Controls
```

---

## 🚀 Getting Started

### Prerequisites
*   Flutter SDK (^3.10.3)
*   Dart SDK
*   Firebase Project Credentials

### Installation

1.  **Clone the repository**
    ```bash
    git clone https://github.com/your-org/parakk-erp-mvp.git
    cd parakk-erp-mvp
    ```

2.  **Install dependencies**
    ```bash
    flutter pub get
    ```

3.  **Firebase Setup**
    *   Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS).
    *   Configure `lib/firebase_options.dart`.

4.  **Run the App**
    ```bash
    flutter run
    ```

---

## 📚 Documentation

Detailed documentation is available for developers:

*   **[DOCUMENTATION.md](./DOCUMENTATION.md)**: Full architectural overview, data schema, and workflow details.
*   **[WORKFLOW.md](./WORKFLOW.md)**: Visual guides for user journeys (Auth, Attendance, Marks).

---

## 📄 License

Proprietary Software. © 2026 Parakk ERP Team. All Rights Reserved.

**Maintained by:** Amritesh & Parakk ERP Development Team.