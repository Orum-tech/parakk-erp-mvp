# Parakk ERP - Application Workflow Diagrams

This document provides visual representations of the application workflows and user journeys.

## Table of Contents
1. [Authentication & Onboarding Flow](#authentication--onboarding-flow)
2. [Student User Journey](#student-user-journey)
3. [Teacher User Journey](#teacher-user-journey)
4. [Data Flow Diagrams](#data-flow-diagrams)
5. [Screen Navigation Maps](#screen-navigation-maps)

---

## Authentication & Onboarding Flow

### Complete Authentication Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Application Start                         │
│                    (main.dart)                              │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│              Firebase.initializeApp()                      │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│                  ParakkApp (MaterialApp)                     │
│                  home: AuthWrapper                           │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│              AuthWrapper                                     │
│              StreamBuilder<User?> (authStateChanges)         │
└─────────────────────────────────────────────────────────────┘
                          ↓
                    ┌─────┴─────┐
                    │           │
            Not Authenticated   Authenticated
                    │           │
                    ↓           ↓
        ┌───────────────────┐   ┌──────────────────────────┐
        │ RoleSelectionScreen│   │ FutureBuilder<UserModel?> │
        │                    │   │ (getCurrentUserWithData)  │
        │ - Student          │   └──────────────────────────┘
        │ - Teacher          │              ↓
        │ - Parent           │   ┌──────────────────────────┐
        └───────────────────┘   │ FutureBuilder<bool>       │
                ↓                │ (isOnboardingComplete)    │
        ┌───────────────────┐   └──────────────────────────┘
        │   SignupScreen     │              ↓
        │                    │      ┌───────┴────────┐
        │ - Email            │      │                 │
        │ - Password         │  Incomplete      Complete
        │ - Name             │      │                 │
        │ - Role (pre-set)   │      ↓                 ↓
        └───────────────────┘   ┌──────────┐    ┌──────────────┐
                ↓                │Student   │    │   Dashboard  │
        ┌───────────────────┐   │Onboarding│    │  (Role-based)│
        │ AuthService       │   │Screen    │    │              │
        │ .signUp()         │   └──────────┘    └──────────────┘
        │                    │      ↓
        │ - Create Auth User │   ┌──────────┐
        │ - Create UserModel │   │Teacher   │
        │   in Firestore      │   │Onboarding│
        └───────────────────┘   │Screen    │
                ↓                └──────────┘
        ┌───────────────────┐         ↓
        │   Onboarding       │   ┌──────────────┐
        │   Check            │   │Onboarding    │
        └───────────────────┘   │Service       │
                                │.complete...()│
                                └──────────────┘
                                        ↓
                                ┌──────────────┐
                                │   Dashboard  │
                                └──────────────┘
```

### Student Onboarding Flow

```
┌─────────────────────────────────────────────────────────────┐
│              StudentOnboardingScreen                          │
└─────────────────────────────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  Required Fields:                    │
        │  - Roll Number                       │
        │  - Class Selection (dropdown)        │
        │  - Section                           │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  Optional Fields:                   │
        │  - Phone Number                      │
        │  - Address                           │
        │  - Date of Birth                     │
        │  - Blood Group                       │
        │  - Emergency Contact                 │
        │  - Parent Information                │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  OnboardingService                  │
        │  .completeStudentOnboarding()       │
        │                                     │
        │  - Fetch current user doc            │
        │  - Create StudentModel               │
        │  - Update user document              │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  Firestore Update                   │
        │  /users/{uid}                       │
        │  - Add studentId, rollNumber,       │
        │    classId, className, section, etc.│
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  Redirect to StudentDashboard        │
        └─────────────────────────────────────┘
```

### Teacher Onboarding Flow

```
┌─────────────────────────────────────────────────────────────┐
│              TeacherOnboardingScreen                          │
└─────────────────────────────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  Required Fields:                    │
        │  - Employee ID                       │
        │  - Subjects (multi-select)           │
        │  - Classes (multi-select)           │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  Optional Fields:                   │
        │  - Class Teacher Assignment          │
        │  - Phone Number                      │
        │  - Address                           │
        │  - Department                        │
        │  - Qualification                     │
        │  - Years of Experience               │
        │  - Joining Date                      │
        │  - Specialization                    │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  OnboardingService                  │
        │  .completeTeacherOnboarding()       │
        │                                     │
        │  - Fetch current user doc            │
        │  - Create TeacherModel               │
        │  - Update user document              │
        │  - If class teacher:                 │
        │    * Update class document           │
        │    * Clear previous assignments      │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  Firestore Updates                  │
        │  /users/{uid}                       │
        │  - Add teacherId, employeeId,        │
        │    subjects[], classIds[], etc.      │
        │                                     │
        │  /classes/{classId} (if class teacher)│
        │  - Set classTeacherId                │
        │  - Set classTeacherName              │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  Redirect to TeacherDashboard       │
        └─────────────────────────────────────┘
```

---

## Student User Journey

### Student Dashboard Navigation

```
┌─────────────────────────────────────────────────────────────┐
│                    StudentDashboard                           │
│                    (4-Tab Navigation)                        │
└─────────────────────────────────────────────────────────────┘
                          ↓
        ┌─────────────────┴─────────────────┐
        │                                   │
        ↓                                   ↓
┌───────────────────┐              ┌───────────────────┐
│  Tab 0: Dashboard │              │  Tab 1: Learn     │
│  (Home)           │              │                   │
└───────────────────┘              └───────────────────┘
        │                                   │
        ↓                                   ↓
┌───────────────────┐              ┌───────────────────┐
│  Tab 2: Connect  │              │  Tab 3: Profile   │
│                   │              │                   │
└───────────────────┘              └───────────────────┘
```

### Student Dashboard Tab 0: Home

```
┌─────────────────────────────────────────────────────────────┐
│                    Dashboard (Home Tab)                      │
└─────────────────────────────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  1. Upcoming Class Alert            │
        │     - Next class info                │
        │     - Time remaining                 │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  2. Focus Mode Card                 │
        │     → StudyTimerScreen               │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  3. Quick Actions (Horizontal)      │
        │     - Homework → HomeworkScreen      │
        │     - Timetable → TimetableScreen   │
        │     - Results → ResultsScreen        │
        │     - Notices → NoticeBoardScreen    │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  4. Student Hub Grid (3x3)          │
        │     - Attendance                    │
        │     - Notes                         │
        │     - Behaviour                     │
        │     - Library                       │
        │     - Bus Track                     │
        │     - Pay Fees                      │
        │     - Events                        │
        │     - Analytics                     │
        │     - Support                       │
        └─────────────────────────────────────┘
```

### Student Dashboard Tab 1: Learn

```
┌─────────────────────────────────────────────────────────────┐
│                    Learn Tab                                 │
└─────────────────────────────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  Video Lessons                      │
        │  → VideoLessonsScreen               │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  Practice Tests                     │
        │  → PracticeTestsScreen              │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  AI Doubt Solver                    │
        │  → DoubtSolverScreen                │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  Saved Resources                    │
        │  → SavedResourcesScreen             │
        └─────────────────────────────────────┘
```

### Student Dashboard Tab 2: Connect

```
┌─────────────────────────────────────────────────────────────┐
│                    Connect Tab                               │
└─────────────────────────────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  AI Tutor Card                      │
        │  (Future: AI-powered assistance)    │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  Talk to Teachers                   │
        │  → TeacherChatScreen                 │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  Recent Messages                    │
        │  - Class Teacher                    │
        │  - School Admin                     │
        └─────────────────────────────────────┘
```

### Student Dashboard Tab 3: Profile

```
┌─────────────────────────────────────────────────────────────┐
│                    Profile Tab                               │
└─────────────────────────────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  Profile Card                       │
        │  - Name, Class, Roll Number         │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  My Account                         │
        │  → MyAccountScreen                  │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  Academic Reports                   │
        │  → AcademicReportsScreen            │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  App Settings                      │
        │  → AppSettingsScreen                │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  Help Center                        │
        │  → HelpCenterScreen                 │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  Logout                            │
        │  → RoleSelectionScreen              │
        └─────────────────────────────────────┘
```

---

## Teacher User Journey

### Teacher Dashboard Navigation

```
┌─────────────────────────────────────────────────────────────┐
│                    TeacherDashboard                           │
│                    (4-Tab Navigation)                        │
└─────────────────────────────────────────────────────────────┘
                          ↓
        ┌─────────────────┴─────────────────┐
        │                                   │
        ↓                                   ↓
┌───────────────────┐              ┌───────────────────┐
│  Tab 0: Home      │              │  Tab 1: My Class  │
│                   │              │                   │
└───────────────────┘              └───────────────────┘
        │                                   │
        ↓                                   ↓
┌───────────────────┐              ┌───────────────────┐
│  Tab 2: Chat      │              │  Tab 3: Profile  │
│                   │              │                   │
└───────────────────┘              └───────────────────┘
```

### Teacher Dashboard Tab 0: Home

```
┌─────────────────────────────────────────────────────────────┐
│                    Home Tab                                   │
└─────────────────────────────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  1. Upcoming Class Alert            │
        │     - Next class info                │
        │     - Room number                    │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  2. Class Stats Card                │
        │     - Total Students                 │
        │     - Present Count                  │
        │     - Absent Count                   │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  3. Quick Actions (Horizontal)      │
        │     - Attendance → AttendanceScreen  │
        │     - Homework → HomeworkScreen     │
        │     - Timetable → TeacherTimetable │
        │     - Marks → MarksEntryScreen      │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  4. Management Console (3x2 Grid)   │
        │     - Upload Notes                  │
        │     - Behaviour Log                 │
        │     - Parent Chat                   │
        │     - Analytics                     │
        │     - Syllabus                      │
        │     - Reports                       │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  5. Study Hub Access (2x2 Grid)    │
        │     - Video Lessons                 │
        │     - Practice Tests                │
        │     - Doubt Solver                  │
        │     - Resources                     │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  Floating Action Button (+)         │
        │  - Create Announcement              │
        │  - Create Homework                  │
        └─────────────────────────────────────┘
```

### Teacher Dashboard Tab 1: My Class

```
┌─────────────────────────────────────────────────────────────┐
│                    My Class Tab                              │
└─────────────────────────────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  Student Directory                   │
        │  → StudentDirectoryScreen           │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  Attendance History                  │
        │  → AttendanceHistoryScreen           │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  Leave Requests                     │
        │  → LeaveRequestsScreen              │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  Lesson Planner                     │
        │  → LessonPlanScreen                 │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  Incident Reports                    │
        │  → IncidentLogScreen                │
        └─────────────────────────────────────┘
```

### Teacher Dashboard Tab 2: Chat

```
┌─────────────────────────────────────────────────────────────┐
│                    Chat Tab                                  │
└─────────────────────────────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  School Notices                      │
        │  → SchoolNoticesScreen               │
        │  - Create announcements              │
        │  - Broadcast to classes              │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  Parent Messages                    │
        │  → ParentChatScreen                 │
        │  - Direct chat with parents          │
        └─────────────────────────────────────┘
```

### Teacher Dashboard Tab 3: Profile

```
┌─────────────────────────────────────────────────────────────┐
│                    Profile Tab                               │
└─────────────────────────────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  Profile Card                       │
        │  - Name, Employee ID                │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  Edit Profile                       │
        │  → EditProfileScreen                │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  Class Settings                    │
        │  → ClassSettingsScreen              │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  Help & Support                     │
        │  → HelpSupportScreen                │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │  Logout                            │
        │  → RoleSelectionScreen              │
        └─────────────────────────────────────┘
```

---

## Data Flow Diagrams

### User Registration Data Flow

```
┌──────────────┐
│  SignupScreen│
└──────┬───────┘
       │
       │ User Input (email, password, name, role)
       ↓
┌──────────────────┐
│  AuthService     │
│  .signUp()       │
└──────┬───────────┘
       │
       ├─────────────────┐
       │                 │
       ↓                 ↓
┌──────────────┐  ┌──────────────┐
│ Firebase Auth│  │  Firestore   │
│              │  │              │
│ Create User  │  │ Create User  │
│ (Auth)       │  │ Document     │
│              │  │ /users/{uid} │
└──────────────┘  └──────────────┘
       │                 │
       └────────┬────────┘
                ↓
        ┌──────────────┐
        │  UserModel   │
        │  (returned)  │
        └──────────────┘
```

### Attendance Marking Data Flow

```
┌──────────────────┐
│ AttendanceScreen │
│  (Teacher)       │
└────────┬─────────┘
         │
         │ User selects students and marks attendance
         ↓
┌──────────────────┐
│ AttendanceService│
│ .markAttendance()│
└────────┬─────────┘
         │
         │ Create AttendanceModel
         ↓
┌──────────────────┐
│   Firestore      │
│                  │
│ /attendance      │
│ {                │
│   studentId,     │
│   classId,       │
│   date,          │
│   status         │
│ }                │
└──────────────────┘
         │
         │ Real-time update
         ↓
┌──────────────────┐
│ AttendanceScreen │
│  (Student)       │
│  (StreamBuilder) │
└──────────────────┘
```

### Homework Creation Data Flow

```
┌──────────────────┐
│ HomeworkScreen   │
│  (Teacher)       │
└────────┬─────────┘
         │
         │ Teacher creates homework
         ↓
┌──────────────────┐
│ HomeworkService  │
│ .createHomework()│
└────────┬─────────┘
         │
         │ Create HomeworkModel
         ↓
┌──────────────────┐
│   Firestore      │
│                  │
│ /homework        │
│ {                │
│   homeworkId,    │
│   classId,       │
│   subjectId,     │
│   teacherId,     │
│   title,         │
│   dueDate        │
│ }                │
└──────────────────┘
         │
         │ Query by classId
         ↓
┌──────────────────┐
│ HomeworkScreen   │
│  (Student)       │
│  (StreamBuilder) │
└──────────────────┘
```

---

## Screen Navigation Maps

### Student Navigation Map

```
StudentDashboard
│
├── Tab 0: Dashboard
│   ├── StudyTimerScreen
│   ├── HomeworkScreen
│   ├── TimetableScreen
│   ├── ResultsScreen
│   ├── NoticeBoardScreen
│   ├── AttendanceScreen
│   ├── NotesScreen
│   ├── BehaviourScreen
│   ├── LibraryScreen
│   ├── BusTrackingScreen
│   ├── FeesScreen
│   ├── EventsScreen
│   ├── AnalyticsScreen
│   └── SupportScreen
│
├── Tab 1: Learn
│   ├── VideoLessonsScreen
│   ├── PracticeTestsScreen
│   ├── DoubtSolverScreen
│   └── SavedResourcesScreen
│
├── Tab 2: Connect
│   └── TeacherChatScreen
│
└── Tab 3: Profile
    ├── MyAccountScreen
    ├── AcademicReportsScreen
    ├── AppSettingsScreen
    └── HelpCenterScreen
```

### Teacher Navigation Map

```
TeacherDashboard
│
├── Tab 0: Home
│   ├── AttendanceScreen
│   ├── HomeworkScreen
│   ├── TeacherTimetableScreen
│   ├── MarksEntryScreen
│   ├── UploadNotesScreen
│   ├── BehaviourLogScreen
│   ├── ParentChatScreen
│   ├── ClassAnalyticsScreen
│   ├── SyllabusTrackerScreen
│   ├── ClassReportsScreen
│   ├── VideoLessonsScreen
│   ├── PracticeTestsScreen
│   ├── DoubtSolverScreen
│   └── SavedResourcesScreen
│
├── Tab 1: My Class
│   ├── StudentDirectoryScreen
│   ├── AttendanceHistoryScreen
│   ├── LeaveRequestsScreen
│   ├── LessonPlanScreen
│   └── IncidentLogScreen
│
├── Tab 2: Chat
│   ├── SchoolNoticesScreen
│   └── ParentChatScreen
│
└── Tab 3: Profile
    ├── EditProfileScreen
    ├── ClassSettingsScreen
    └── HelpSupportScreen
```

---

## State Management Flow

### Authentication State

```
AuthWrapper
│
├── StreamBuilder<User?> (authStateChanges)
│   │
│   ├── ConnectionState.waiting
│   │   └── CircularProgressIndicator
│   │
│   ├── snapshot.hasData (authenticated)
│   │   └── FutureBuilder<UserModel?>
│   │       │
│   │       ├── ConnectionState.waiting
│   │       │   └── CircularProgressIndicator
│   │       │
│   │       ├── hasData
│   │       │   └── FutureBuilder<bool> (isOnboardingComplete)
│   │       │       │
│   │       │       ├── !isOnboardingComplete
│   │       │       │   ├── Student → StudentOnboardingScreen
│   │       │       │   └── Teacher → TeacherOnboardingScreen
│   │       │       │
│   │       │       └── isOnboardingComplete
│   │       │           └── _getDashboard(role)
│   │       │               ├── Student → StudentDashboard
│   │       │               ├── Teacher → TeacherDashboard
│   │       │               └── Parent → ParentDashboard
│   │       │
│   │       └── !hasData
│   │           └── RoleSelectionScreen
│   │
│   └── !snapshot.hasData (not authenticated)
│       └── RoleSelectionScreen
```

---

**Last Updated**: 2026
**Version**: 1.0.0
