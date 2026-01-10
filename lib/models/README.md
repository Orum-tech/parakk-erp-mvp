# Database Models Documentation

This document describes the comprehensive database model structure for the Parakk ERP MVP application. All models are designed to synchronize efficiently with each other and scale well.

## Model Architecture

### Core User Models

#### UserModel (Base Model)
- **Purpose**: Base user model with common fields
- **Fields**: uid, name, email, role, createdAt
- **Roles**: Student, Teacher, Parent

#### StudentModel
- **Extends**: UserModel
- **Key Fields**: studentId, rollNumber, classId, parentId, academicInfo
- **Relationships**: 
  - Links to ClassModel via classId
  - Links to Parent via parentId
  - Has many AttendanceModel, MarksModel, HomeworkSubmissionModel

#### TeacherModel
- **Extends**: UserModel
- **Key Fields**: teacherId, employeeId, subjects[], classIds[]
- **Relationships**:
  - Links to multiple ClassModel via classIds
  - Links to SubjectModel via subjects
  - Creates HomeworkModel, ExamModel, NoteModel

### Academic Models

#### ClassModel
- **Purpose**: Represents a class/section
- **Key Fields**: classId, className, section, classTeacherId
- **Relationships**:
  - Has many StudentModel
  - Has many SubjectModel via subjectIds
  - Has one TeacherModel (class teacher)

#### SubjectModel
- **Purpose**: Represents a subject
- **Key Fields**: subjectId, subjectName, teacherId, classIds[]
- **Relationships**:
  - Links to TeacherModel via teacherId
  - Links to multiple ClassModel via classIds
  - Used by ExamModel, HomeworkModel, NoteModel

#### AttendanceModel
- **Purpose**: Daily attendance records
- **Key Fields**: studentId, classId, date, status
- **Relationships**:
  - Links to StudentModel via studentId
  - Links to ClassModel via classId
  - Optional link to SubjectModel for subject-specific attendance

#### HomeworkModel
- **Purpose**: Homework assignments
- **Key Fields**: homeworkId, classId, subjectId, teacherId, dueDate
- **Relationships**:
  - Links to ClassModel, SubjectModel, TeacherModel
  - Has many HomeworkSubmissionModel

#### HomeworkSubmissionModel
- **Purpose**: Student submissions
- **Key Fields**: homeworkId, studentId, status, submittedAt
- **Relationships**:
  - Links to HomeworkModel via homeworkId
  - Links to StudentModel via studentId

#### ExamModel
- **Purpose**: Exam/test definitions
- **Key Fields**: examId, examType, classId, subjectId, examDate
- **Relationships**:
  - Links to ClassModel, SubjectModel, TeacherModel
  - Has many MarksModel

#### MarksModel
- **Purpose**: Student exam marks
- **Key Fields**: examId, studentId, marksObtained, maxMarks, grade
- **Relationships**:
  - Links to ExamModel via examId
  - Links to StudentModel via studentId
  - Auto-calculates grade and percentage

### Content Models

#### NoteModel
- **Purpose**: Study notes/materials
- **Key Fields**: noteId, subjectId, teacherId, attachmentUrls[]
- **Relationships**:
  - Links to SubjectModel, TeacherModel
  - Optional link to ClassModel

#### VideoLessonModel
- **Purpose**: Video lessons
- **Key Fields**: videoId, subjectId, videoUrl, chapterName
- **Relationships**:
  - Links to SubjectModel
  - Optional links to TeacherModel, ClassModel

#### LibraryResourceModel
- **Purpose**: Library books/resources
- **Key Fields**: resourceId, category, fileUrl, totalCopies
- **Relationships**:
  - Optional links to ClassModel, SubjectModel

#### PracticeTestModel
- **Purpose**: Practice quizzes/tests
- **Key Fields**: testId, subjectId, duration, totalQuestions
- **Relationships**:
  - Links to SubjectModel
  - Optional links to ClassModel

### Communication Models

#### NoticeModel
- **Purpose**: School announcements
- **Key Fields**: noticeId, noticeType, targetAudience
- **Relationships**:
  - Can target all users or specific classes

#### EventModel
- **Purpose**: School events
- **Key Fields**: eventId, category, eventDate, targetAudience[]
- **Relationships**:
  - Can target multiple classes via targetAudience

#### ChatMessageModel
- **Purpose**: Chat messages between users
- **Key Fields**: messageId, senderId, receiverId, message
- **Relationships**:
  - Links to UserModel (sender/receiver)

### Administrative Models

#### FeeModel
- **Purpose**: Fee structure
- **Key Fields**: feeId, studentId, feeType, amount, dueDate
- **Relationships**:
  - Links to StudentModel
  - Has many FeeTransactionModel

#### FeeTransactionModel
- **Purpose**: Payment transactions
- **Key Fields**: transactionId, feeId, amount, paymentMethod
- **Relationships**:
  - Links to FeeModel via feeId

#### BehaviourLogModel
- **Purpose**: Student behavior tracking
- **Key Fields**: logId, studentId, behaviourType, remark
- **Relationships**:
  - Links to StudentModel, TeacherModel

#### IncidentLogModel
- **Purpose**: Disciplinary incidents
- **Key Fields**: incidentId, studentId, severity, status
- **Relationships**:
  - Links to StudentModel

#### LeaveRequestModel
- **Purpose**: Student leave applications
- **Key Fields**: leaveId, studentId, leaveType, status
- **Relationships**:
  - Links to StudentModel
  - Approved/rejected by TeacherModel

### Planning Models

#### TimetableModel
- **Purpose**: Class schedules
- **Key Fields**: timetableId, classId, day, periodNumber, subjectId
- **Relationships**:
  - Links to ClassModel, SubjectModel, TeacherModel

#### LessonPlanModel
- **Purpose**: Teacher lesson plans
- **Key Fields**: planId, subjectId, classId, topic, plannedDate
- **Relationships**:
  - Links to SubjectModel, ClassModel, TeacherModel

#### SyllabusTrackerModel
- **Purpose**: Syllabus completion tracking
- **Key Fields**: trackerId, subjectId, chapterName, isCompleted
- **Relationships**:
  - Links to SubjectModel, ClassModel, TeacherModel

## Data Synchronization Strategy

### 1. Denormalization for Performance
- Models store frequently accessed related data (e.g., studentName, className) to avoid multiple queries
- Example: AttendanceModel stores both studentId and studentName

### 2. Reference IDs for Relationships
- All models use reference IDs (studentId, classId, etc.) for relationships
- Enables efficient querying and filtering

### 3. Timestamp Tracking
- All models include createdAt and updatedAt timestamps
- Enables efficient sorting and change tracking

### 4. Status Enums
- Models use enums for status fields (AttendanceStatus, PaymentStatus, etc.)
- Ensures data consistency and type safety

### 5. Computed Properties
- Models include computed properties (e.g., percentage, isOverdue)
- Reduces redundant calculations in application code

## Usage Examples

### Creating Related Records

```dart
// Create attendance record
final attendance = AttendanceModel(
  attendanceId: 'att_001',
  studentId: student.studentId,
  studentName: student.name, // Denormalized for performance
  classId: student.classId,
  className: student.className, // Denormalized
  date: DateTime.now(),
  status: AttendanceStatus.present,
  createdAt: Timestamp.now(),
);

// Create homework with class reference
final homework = HomeworkModel(
  homeworkId: 'hw_001',
  title: 'Algebra Exercise',
  classId: classModel.classId,
  className: classModel.fullClassName, // Denormalized
  subjectId: subject.subjectId,
  subjectName: subject.subjectName, // Denormalized
  teacherId: teacher.teacherId,
  teacherName: teacher.name, // Denormalized
  dueDate: DateTime.now().add(Duration(days: 7)),
  createdAt: Timestamp.now(),
);
```

### Querying Related Data

```dart
// Get all homework for a student's class
final homeworkQuery = FirebaseFirestore.instance
  .collection('homework')
  .where('classId', isEqualTo: student.classId)
  .orderBy('dueDate', descending: false);

// Get all marks for a student
final marksQuery = FirebaseFirestore.instance
  .collection('marks')
  .where('studentId', isEqualTo: student.studentId)
  .orderBy('examDate', descending: true);
```

## Best Practices

1. **Always use reference IDs**: Store IDs for relationships, not full objects
2. **Denormalize frequently accessed data**: Store names alongside IDs for performance
3. **Update denormalized fields**: When updating a name, update all related records
4. **Use enums for status**: Ensures type safety and consistency
5. **Include timestamps**: Always track createdAt and updatedAt
6. **Validate relationships**: Ensure referenced IDs exist before creating records

## Scalability Considerations

1. **Indexed Fields**: All query fields (studentId, classId, date, etc.) should be indexed in Firestore
2. **Pagination**: Use limit() and startAfter() for large collections
3. **Composite Queries**: Use composite indexes for multi-field queries
4. **Caching**: Consider caching frequently accessed data (classes, subjects)
5. **Batch Operations**: Use batch writes for related updates
