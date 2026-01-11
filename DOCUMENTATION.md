# Parakk ERP MVP - Comprehensive Documentation

## Table of Contents
1. [Project Overview](#project-overview)
2. [Architecture & Technology Stack](#architecture--technology-stack)
3. [Project Structure](#project-structure)
4. [Application Workflow](#application-workflow)
5. [Data Models](#data-models)
6. [Services Layer](#services-layer)
7. [Screens & Navigation](#screens--navigation)
8. [Key Features](#key-features)
9. [Firebase Configuration](#firebase-configuration)
10. [Development Guidelines](#development-guidelines)
11. [Getting Started](#getting-started)

---

## Project Overview

**Parakk ERP** is a comprehensive Educational Resource Planning (ERP) system built with Flutter. It serves as a centralized platform for managing school operations, facilitating communication between students, teachers, and parents, and providing tools for academic management, attendance tracking, homework management, and more.

### Key Objectives
- **Multi-role Support**: Student, Teacher, and Parent dashboards with role-specific features
- **Real-time Data**: Firebase Firestore integration for real-time updates
- **Academic Management**: Comprehensive tools for managing classes, subjects, attendance, homework, and exams
- **Communication Hub**: Built-in messaging and notice board system
- **Learning Resources**: Video lessons, practice tests, notes, and library resources
- **Analytics & Reporting**: Performance tracking and academic reports

---

## Architecture & Technology Stack

### Technology Stack
- **Framework**: Flutter (Dart SDK ^3.10.3)
- **Backend**: Firebase
  - **Authentication**: Firebase Auth
  - **Database**: Cloud Firestore
- **State Management**: StatefulWidget (State-based)
- **UI Framework**: Material Design 3

### Architecture Pattern
The application follows a **layered architecture**:

```
┌─────────────────────────────────────┐
│         Presentation Layer          │
│    (Screens, Widgets, UI Logic)     │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│          Services Layer             │
│  (Auth, Onboarding, Business Logic) │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│          Models Layer               │
│    (Data Models, DTOs, Enums)      │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│         Firebase Layer              │
│   (Firestore, Authentication)      │
└─────────────────────────────────────┘
```

---

## Project Structure

```
lib/
├── main.dart                    # Application entry point
├── firebase_options.dart        # Firebase configuration
│
├── models/                      # Data models
│   ├── models.dart             # Model exports
│   ├── user_model.dart         # Base user model
│   ├── student_model.dart      # Student-specific model
│   ├── teacher_model.dart      # Teacher-specific model
│   ├── class_model.dart        # Class/grade model
│   ├── subject_model.dart      # Subject model
│   ├── attendance_model.dart   # Attendance records
│   ├── homework_model.dart     # Homework assignments
│   ├── exam_model.dart         # Exam/test model
│   ├── marks_model.dart        # Marks/grades model
│   └── ... (20+ models)
│
├── screens/                     # UI screens
│   ├── auth_wrapper.dart       # Authentication routing
│   ├── role_selection_screen.dart
│   ├── login_screen.dart
│   ├── signup_screen.dart
│   ├── student_dashboard.dart  # Student main screen
│   ├── teacher_dashboard.dart  # Teacher main screen
│   ├── parent_dashboard.dart  # Parent main screen
│   ├── student_onboarding_screen.dart
│   ├── teacher_onboarding_screen.dart
│   │
│   ├── student_features/       # Student-specific screens
│   │   ├── attendance_screen.dart
│   │   ├── timetable_screen.dart
│   │   ├── results_screen.dart
│   │   ├── notes_screen.dart
│   │   ├── video_lessons_screen.dart
│   │   ├── practice_tests_screen.dart
│   │   ├── teacher_chat_screen.dart
│   │   └── ... (22 screens)
│   │
│   └── teacher_features/       # Teacher-specific screens
│       ├── attendance_screen.dart
│       ├── homework_screen.dart
│       ├── marks_entry_screen.dart
│       ├── student_directory_screen.dart
│       ├── behaviour_log_screen.dart
│       └── ... (20 screens)
│
└── services/                    # Business logic services
    ├── auth_service.dart       # Authentication service
    ├── onboarding_service.dart # Onboarding flow service
    ├── attendance_service.dart # Attendance management
    ├── homework_service.dart   # Homework management
    └── timetable_service.dart  # Timetable management
```

---

## Application Workflow

### 1. Application Initialization Flow

```
main.dart
  ↓
Firebase.initializeApp()
  ↓
ParakkApp (MaterialApp)
  ↓
AuthWrapper (Root Widget)
```

### 2. Authentication Flow

```
┌─────────────────────────────────────────┐
│      RoleSelectionScreen                │
│  (Student / Teacher / Parent)          │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│         SignupScreen                     │
│  (Email, Password, Name, Role)          │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│      AuthService.signUp()               │
│  - Create Firebase Auth User            │
│  - Create UserModel in Firestore        │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│      Onboarding Check                   │
│  (Student/Teacher Onboarding)           │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│      Role-Specific Dashboard             │
│  (Student/Teacher/Parent)               │
└─────────────────────────────────────────┘
```

### 3. Onboarding Flow

#### Student Onboarding
1. User selects "Student" role and signs up
2. Redirected to `StudentOnboardingScreen`
3. Required fields:
   - Roll Number
   - Class Selection (from existing classes)
   - Section
4. Optional fields:
   - Phone Number
   - Address
   - Date of Birth
   - Blood Group
   - Emergency Contact
   - Parent Information
5. Data saved via `OnboardingService.completeStudentOnboarding()`
6. User document updated with `StudentModel` data
7. Redirected to `StudentDashboard`

#### Teacher Onboarding
1. User selects "Teacher" role and signs up
2. Redirected to `TeacherOnboardingScreen`
3. Required fields:
   - Employee ID
   - Subjects (multiple selection)
   - Classes (multiple selection)
4. Optional fields:
   - Class Teacher Assignment (one class)
   - Phone Number
   - Address
   - Department
   - Qualification
   - Years of Experience
   - Joining Date
   - Specialization
5. Data saved via `OnboardingService.completeTeacherOnboarding()`
6. User document updated with `TeacherModel` data
7. If class teacher assigned, class document updated
8. Redirected to `TeacherDashboard`

### 4. Dashboard Navigation Flow

#### Student Dashboard
```
StudentDashboard (4 Tabs)
├── Tab 0: Dashboard (Home)
│   ├── Upcoming Class Alert
│   ├── Focus Mode Card (Study Timer)
│   ├── Quick Actions (Homework, Timetable, Results, Notices)
│   └── Student Hub Grid (9 features)
│
├── Tab 1: Learn
│   ├── Video Lessons
│   ├── Practice Tests
│   ├── AI Doubt Solver
│   └── Saved Resources
│
├── Tab 2: Connect
│   ├── AI Tutor Chat
│   ├── Teacher Chat
│   └── Recent Messages
│
└── Tab 3: Profile
    ├── My Account
    ├── Academic Reports
    ├── App Settings
    ├── Help Center
    └── Logout
```

#### Teacher Dashboard
```
TeacherDashboard (4 Tabs)
├── Tab 0: Home
│   ├── Upcoming Class Alert
│   ├── Class Stats Card
│   ├── Quick Actions (Attendance, Homework, Timetable, Marks)
│   ├── Management Console (6 features)
│   └── Study Hub Access (4 features)
│
├── Tab 1: My Class
│   ├── Student Directory
│   ├── Attendance History
│   ├── Leave Requests
│   ├── Lesson Planner
│   └── Incident Reports
│
├── Tab 2: Chat
│   ├── School Notices
│   └── Parent Messages
│
└── Tab 3: Profile
    ├── Edit Profile
    ├── Class Settings
    ├── Help & Support
    └── Logout
```

### 5. Authentication State Management

The app uses Firebase Auth's `authStateChanges` stream to monitor authentication state:

```dart
AuthWrapper
  ↓
StreamBuilder<User?> (authStateChanges)
  ↓
If authenticated:
  ↓
  FutureBuilder<UserModel?> (getCurrentUserWithData)
    ↓
    FutureBuilder<bool> (isOnboardingComplete)
      ↓
      If onboarding incomplete → OnboardingScreen
      If onboarding complete → Dashboard
```

---

## Data Models

### Core User Models

#### UserModel (Base Model)
- **Purpose**: Base user model with common fields
- **Fields**:
  - `uid`: String (Firebase Auth UID)
  - `name`: String
  - `email`: String
  - `role`: UserRole enum (Student/Teacher/Parent)
  - `createdAt`: Timestamp

#### StudentModel
- **Extends**: UserModel
- **Key Fields**:
  - `studentId`: String
  - `rollNumber`: String
  - `classId`: String
  - `className`: String
  - `section`: String
  - `parentId`: String? (optional)
  - `phoneNumber`: String?
  - `dateOfBirth`: DateTime?
  - `bloodGroup`: String?
  - `emergencyContact`: String?

#### TeacherModel
- **Extends**: UserModel
- **Key Fields**:
  - `teacherId`: String
  - `employeeId`: String
  - `subjects`: List<String> (subject IDs)
  - `classIds`: List<String> (class IDs)
  - `classTeacherClassId`: String? (if class teacher)
  - `department`: String?
  - `qualification`: String?
  - `yearsOfExperience`: int?

### Academic Models

#### ClassModel
- **Fields**: `classId`, `className`, `section`, `classTeacherId`, `subjectIds[]`

#### SubjectModel
- **Fields**: `subjectId`, `subjectName`, `teacherId`, `classIds[]`

#### AttendanceModel
- **Fields**: `attendanceId`, `studentId`, `classId`, `date`, `status` (Present/Absent/Late)
- **Relationships**: Links to StudentModel and ClassModel

#### HomeworkModel
- **Fields**: `homeworkId`, `classId`, `subjectId`, `teacherId`, `title`, `description`, `dueDate`
- **Relationships**: Links to ClassModel, SubjectModel, TeacherModel

#### HomeworkSubmissionModel
- **Fields**: `submissionId`, `homeworkId`, `studentId`, `status`, `submittedAt`
- **Relationships**: Links to HomeworkModel and StudentModel

#### ExamModel
- **Fields**: `examId`, `examType`, `classId`, `subjectId`, `examDate`, `maxMarks`
- **Relationships**: Links to ClassModel, SubjectModel

#### MarksModel
- **Fields**: `marksId`, `examId`, `studentId`, `marksObtained`, `maxMarks`, `grade`
- **Relationships**: Links to ExamModel and StudentModel

### Communication Models

#### NoticeModel
- **Fields**: `noticeId`, `noticeType`, `title`, `message`, `targetAudience`, `createdAt`

#### EventModel
- **Fields**: `eventId`, `eventName`, `eventDate`, `category`, `targetAudience[]`

#### ChatMessageModel
- **Fields**: `messageId`, `senderId`, `receiverId`, `message`, `timestamp`, `isRead`

### Administrative Models

#### FeeModel
- **Fields**: `feeId`, `studentId`, `feeType`, `amount`, `dueDate`, `status`

#### FeeTransactionModel
- **Fields**: `transactionId`, `feeId`, `amount`, `paymentMethod`, `paymentDate`

#### BehaviourLogModel
- **Fields**: `logId`, `studentId`, `teacherId`, `behaviourType`, `remark`, `date`

#### IncidentLogModel
- **Fields**: `incidentId`, `studentId`, `severity`, `description`, `status`, `date`

#### LeaveRequestModel
- **Fields**: `leaveId`, `studentId`, `leaveType`, `startDate`, `endDate`, `status`, `approvedBy`

### Planning Models

#### TimetableModel
- **Fields**: `timetableId`, `classId`, `day`, `periodNumber`, `subjectId`, `teacherId`, `room`

#### LessonPlanModel
- **Fields**: `planId`, `subjectId`, `classId`, `teacherId`, `topic`, `plannedDate`, `status`

#### SyllabusTrackerModel
- **Fields**: `trackerId`, `subjectId`, `classId`, `chapterName`, `isCompleted`, `completionDate`

### Model Design Principles

1. **Denormalization**: Frequently accessed data (e.g., `studentName`, `className`) is stored alongside IDs for performance
2. **Reference IDs**: All relationships use reference IDs (not nested objects)
3. **Timestamp Tracking**: All models include `createdAt` and `updatedAt`
4. **Status Enums**: Status fields use enums for type safety
5. **Computed Properties**: Models include computed properties (e.g., `percentage`, `isOverdue`)

---

## Services Layer

### AuthService

**Location**: `lib/services/auth_service.dart`

**Responsibilities**:
- User registration (sign up)
- User authentication (login)
- User logout
- Current user retrieval
- Auth state monitoring
- Input validation (email, password, name)

**Key Methods**:
```dart
Future<UserModel?> signUp({email, password, name, role})
Future<UserModel?> login({email, password})
Future<void> logout()
Future<UserModel?> getCurrentUserWithData()
Stream<User?> get authStateChanges
static String? validateEmail(String? value)
static String? validatePassword(String? value)
static String? validateName(String? value)
```

**Error Handling**:
- Converts Firebase Auth exceptions to user-friendly messages
- Handles cases like "email-already-in-use", "user-not-found", "wrong-password"

### OnboardingService

**Location**: `lib/services/onboarding_service.dart`

**Responsibilities**:
- Check onboarding completion status
- Complete student onboarding
- Complete teacher onboarding
- Fetch available classes and subjects

**Key Methods**:
```dart
Future<bool> isOnboardingComplete(String uid, String role)
Future<void> completeStudentOnboarding({...})
Future<void> completeTeacherOnboarding({...})
Future<List<ClassOption>> fetchClasses()
Future<List<SubjectOption>> fetchSubjects()
```

**Onboarding Logic**:
- **Student**: Checks for `classId` and `rollNumber`
- **Teacher**: Checks for `employeeId` and non-empty `subjects` list
- Updates user document with role-specific data
- For teachers assigned as class teachers, updates class document

### AttendanceService

**Location**: `lib/services/attendance_service.dart`

**Responsibilities**:
- Mark attendance for students
- Fetch attendance records
- Calculate attendance statistics

### HomeworkService

**Location**: `lib/services/homework_service.dart`

**Responsibilities**:
- Create homework assignments
- Fetch homework for students/classes
- Track homework submissions

### TimetableService

**Location**: `lib/services/timetable_service.dart`

**Responsibilities**:
- Fetch timetable for classes/teachers
- Manage class schedules

---

## Screens & Navigation

### Authentication Screens

#### RoleSelectionScreen
- **Purpose**: Initial screen for role selection
- **Navigation**: Routes to `SignupScreen` with selected role
- **UI**: Three cards (Student, Teacher, Parent)

#### SignupScreen
- **Purpose**: User registration
- **Fields**: Email, Password, Name, Role (pre-selected)
- **Validation**: Email format, password strength (min 6 chars), name (min 2 chars)
- **Navigation**: On success → Onboarding or Dashboard

#### LoginScreen
- **Purpose**: User authentication
- **Fields**: Email, Password
- **Navigation**: On success → Dashboard

### Core Screens

#### AuthWrapper
- **Purpose**: Root widget that handles authentication routing
- **Logic**:
  1. Monitors auth state via `authStateChanges` stream
  2. If authenticated, fetches user data
  3. Checks onboarding completion
  4. Routes to appropriate screen (Onboarding or Dashboard)

#### StudentDashboard
- **Purpose**: Main student interface
- **Tabs**: Dashboard, Learn, Connect, Profile
- **Features**: 22+ student-specific screens accessible via navigation

#### TeacherDashboard
- **Purpose**: Main teacher interface
- **Tabs**: Home, My Class, Chat, Profile
- **Features**: 20+ teacher-specific screens accessible via navigation

#### ParentDashboard
- **Purpose**: Main parent interface
- **Features**: View child's progress, attendance, fees, etc.

### Student Features (22 Screens)

1. **AttendanceScreen** - View attendance records
2. **TimetableScreen** - View class schedule
3. **ResultsScreen** - View exam results and grades
4. **NotesScreen** - Access study notes
5. **NoticeBoardScreen** - View school announcements
6. **BehaviourScreen** - View behavior logs
7. **LibraryScreen** - Browse library resources
8. **BusTrackingScreen** - Track school bus
9. **FeesScreen** - View and pay fees
10. **EventsScreen** - View school events
11. **AnalyticsScreen** - View performance analytics
12. **SupportScreen** - Contact support
13. **VideoLessonsScreen** - Watch video lessons
14. **PracticeTestsScreen** - Take practice tests
15. **DoubtSolverScreen** - AI-powered doubt solving
16. **SavedResourcesScreen** - Access saved resources
17. **TeacherChatScreen** - Chat with teachers
18. **MyAccountScreen** - Manage account
19. **AcademicReportsScreen** - View academic reports
20. **AppSettingsScreen** - App configuration
21. **HelpCenterScreen** - Help and FAQs
22. **HomeworkSubmissionScreen** - Submit homework

### Teacher Features (20 Screens)

1. **AttendanceScreen** - Mark attendance
2. **AttendanceHistoryScreen** - View attendance history
3. **HomeworkScreen** - Create and manage homework
4. **CreateHomeworkScreen** - Create new homework
5. **MarksEntryScreen** - Enter exam marks
6. **TeacherTimetableScreen** - View teaching schedule
7. **UploadNotesScreen** - Upload study materials
8. **BehaviourLogScreen** - Log student behavior
9. **ClassAnalyticsScreen** - View class performance
10. **SyllabusTrackerScreen** - Track syllabus completion
11. **ClassReportsScreen** - Generate class reports
12. **StudentDirectoryScreen** - View student directory
13. **LeaveRequestsScreen** - Approve/reject leave requests
14. **LessonPlanScreen** - Create lesson plans
15. **IncidentLogScreen** - Log disciplinary incidents
16. **ParentChatScreen** - Chat with parents
17. **SchoolNoticesScreen** - Create school notices
18. **EditProfileScreen** - Edit teacher profile
19. **ClassSettingsScreen** - Configure class settings
20. **HelpSupportScreen** - Help and support

### Navigation Pattern

The app uses Flutter's `Navigator` for screen navigation:

```dart
// Push new screen
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => TargetScreen())
);

// Replace current screen (for logout)
Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (context) => TargetScreen())
);
```

---

## Key Features

### 1. Multi-Role Authentication
- Role-based access control (Student, Teacher, Parent)
- Separate dashboards for each role
- Role-specific onboarding flows

### 2. Academic Management
- **Attendance Tracking**: Daily attendance marking and history
- **Homework Management**: Create assignments, track submissions
- **Exam Management**: Create exams, enter marks, generate results
- **Timetable**: Class and teacher schedules
- **Syllabus Tracking**: Track syllabus completion

### 3. Communication
- **Notice Board**: School-wide and class-specific announcements
- **Chat System**: Direct messaging between users
- **Events**: School event management and notifications

### 4. Learning Resources
- **Video Lessons**: Recorded lectures and tutorials
- **Practice Tests**: Mock exams and quizzes
- **Study Notes**: Uploaded notes and materials
- **Library Resources**: Digital library access
- **AI Doubt Solver**: AI-powered academic assistance

### 5. Administrative Features
- **Fee Management**: Fee structure and payment tracking
- **Behavior Logging**: Track student behavior
- **Incident Reports**: Disciplinary incident management
- **Leave Requests**: Student leave application system

### 6. Analytics & Reporting
- **Academic Reports**: Performance analysis
- **Class Analytics**: Class-wide performance metrics
- **Attendance Statistics**: Attendance trends and patterns

### 7. Study Tools
- **Study Timer**: Focus mode and productivity tracking
- **Saved Resources**: Offline access to materials
- **Progress Tracking**: Academic progress monitoring

---

## Firebase Configuration

### Firebase Setup

1. **Firebase Project Setup**
   - Create Firebase project at [Firebase Console](https://console.firebase.google.com)
   - Enable Authentication (Email/Password)
   - Create Firestore database
   - Configure security rules

2. **Firebase Configuration Files**
   - `lib/firebase_options.dart` - Generated Firebase config
   - `android/app/google-services.json` - Android config
   - `ios/Runner/GoogleService-Info.plist` - iOS config (if applicable)
   - `web/firebase-config.js` - Web config

3. **Firestore Collections Structure**
   ```
   /users              # User documents (students, teachers, parents)
   /classes            # Class/grade documents
   /subjects           # Subject documents
   /attendance         # Attendance records
   /homework           # Homework assignments
   /homework_submissions # Student submissions
   /exams              # Exam definitions
   /marks              # Exam marks
   /notices            # School notices
   /events             # School events
   /chat_messages      # Chat messages
   /fees               # Fee records
   /fee_transactions   # Payment transactions
   /behaviour_logs     # Behavior logs
   /incident_logs      # Incident reports
   /leave_requests     # Leave applications
   /timetables         # Class schedules
   /lesson_plans       # Lesson plans
   /syllabus_trackers  # Syllabus progress
   /notes              # Study notes
   /video_lessons      # Video lessons
   /library_resources  # Library resources
   /practice_tests     # Practice tests
   ```

4. **Firestore Security Rules** (Example)
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       // Users can read/write their own data
       match /users/{userId} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
       
       // Students can read their class data
       match /classes/{classId} {
         allow read: if request.auth != null;
         allow write: if request.auth != null && 
           get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'Teacher';
       }
       
       // Add more rules as needed
     }
   }
   ```

5. **Firestore Indexes**
   - Configure composite indexes for complex queries
   - Index file: `firestore.indexes.json`

---

## Development Guidelines

### Code Organization

1. **Models**
   - One model per file
   - Export all models via `models.dart`
   - Use factory constructors for Firestore deserialization
   - Include `toMap()` for Firestore serialization

2. **Services**
   - One service per domain (Auth, Onboarding, Attendance, etc.)
   - Services handle all Firebase interactions
   - Services return typed models, not raw Firestore documents

3. **Screens**
   - Group related screens in feature folders
   - Use descriptive screen names ending with `_screen.dart`
   - Keep screens focused on UI, delegate logic to services

4. **Widgets**
   - Extract reusable widgets into separate files
   - Use const constructors where possible
   - Follow Material Design 3 guidelines

### Naming Conventions

- **Files**: `snake_case.dart` (e.g., `student_dashboard.dart`)
- **Classes**: `PascalCase` (e.g., `StudentDashboard`)
- **Variables**: `camelCase` (e.g., `selectedIndex`)
- **Constants**: `camelCase` with `k` prefix (e.g., `kPrimaryColor`)
- **Models**: `PascalCase` with `Model` suffix (e.g., `StudentModel`)

### State Management

- Use `StatefulWidget` for screens with dynamic state
- Use `StreamBuilder` for real-time Firebase data
- Use `FutureBuilder` for one-time async operations
- Avoid global state; pass data via constructor or Navigator

### Error Handling

- Wrap Firebase operations in try-catch blocks
- Display user-friendly error messages
- Log errors for debugging (use `print` or logging package)

### Performance Best Practices

1. **Firestore Queries**
   - Use indexes for complex queries
   - Limit query results with `limit()`
   - Use pagination for large datasets

2. **Widget Optimization**
   - Use `const` widgets where possible
   - Avoid rebuilding entire trees unnecessarily
   - Use `ListView.builder` for long lists

3. **Image Loading**
   - Use cached network images
   - Implement image placeholders

### Testing

- Unit tests for services and models
- Widget tests for UI components
- Integration tests for critical user flows

---

## Getting Started

### Prerequisites

1. **Flutter SDK** (^3.10.3)
   ```bash
   flutter --version
   ```

2. **Firebase Account**
   - Create project at [Firebase Console](https://console.firebase.google.com)
   - Enable Authentication and Firestore

3. **Development Tools**
   - Android Studio / VS Code
   - Flutter plugins
   - Firebase CLI (optional)

### Setup Instructions

1. **Clone Repository**
   ```bash
   git clone <repository-url>
   cd parakk-erp-mvp
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**
   - Download `google-services.json` for Android
   - Place in `android/app/`
   - Configure iOS if needed
   - Update `lib/firebase_options.dart` with your Firebase config

4. **Run Application**
   ```bash
   flutter run
   ```

### Environment Setup

1. **Android**
   - Minimum SDK: 21
   - Target SDK: 33+
   - Configure in `android/app/build.gradle.kts`

2. **iOS** (if applicable)
   - Minimum iOS: 12.0
   - Configure in `ios/Podfile`

3. **Web** (if applicable)
   - Configure in `web/index.html`

### Building for Production

1. **Android APK**
   ```bash
   flutter build apk --release
   ```

2. **Android App Bundle**
   ```bash
   flutter build appbundle --release
   ```

3. **iOS** (requires macOS and Xcode)
   ```bash
   flutter build ios --release
   ```

---

## Additional Resources

### Documentation Files
- `lib/models/README.md` - Detailed model documentation
- `README.md` - Project overview

### Firebase Resources
- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev)

### Flutter Resources
- [Flutter Documentation](https://docs.flutter.dev)
- [Material Design 3](https://m3.material.io)

---

## Support & Contribution

For issues, feature requests, or contributions, please refer to the project repository.

---

**Last Updated**: 2026
**Version**: 1.0.0
**Maintained By**: Amritesh & Parakk ERP Development Team
