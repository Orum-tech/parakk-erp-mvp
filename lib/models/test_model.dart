import 'package:cloud_firestore/cloud_firestore.dart';

enum TestType {
  quiz,
  mockTest,
  assignment,
  practice,
}

class TestQuestion {
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final int marks;
  final String? explanation;

  TestQuestion({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    this.marks = 1,
    this.explanation,
  });

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'marks': marks,
      'explanation': explanation,
    };
  }

  factory TestQuestion.fromMap(Map<String, dynamic> map) {
    return TestQuestion(
      question: map['question'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswerIndex: map['correctAnswerIndex'] ?? 0,
      marks: map['marks'] ?? 1,
      explanation: map['explanation'],
    );
  }
}

class TestModel {
  final String testId;
  final String title;
  final String description;
  final String subject;
  final String? chapter;
  final String? topic;
  final TestType testType;
  final String teacherId;
  final String teacherName;
  final List<String>? classIds;
  final List<String>? targetAudience;
  final List<TestQuestion> questions;
  final int totalMarks;
  final int duration; // Duration in minutes
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  TestModel({
    required this.testId,
    required this.title,
    required this.description,
    required this.subject,
    this.chapter,
    this.topic,
    required this.testType,
    required this.teacherId,
    required this.teacherName,
    this.classIds,
    this.targetAudience,
    required this.questions,
    required this.totalMarks,
    required this.duration,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory TestModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final questionsData = data['questions'] as List<dynamic>? ?? [];
    final questions = questionsData.map((q) => TestQuestion.fromMap(q as Map<String, dynamic>)).toList();
    
    return TestModel(
      testId: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      subject: data['subject'] ?? '',
      chapter: data['chapter'],
      topic: data['topic'],
      testType: TestType.values.firstWhere(
        (e) => e.toString().split('.').last == data['testType'],
        orElse: () => TestType.quiz,
      ),
      teacherId: data['teacherId'] ?? '',
      teacherName: data['teacherName'] ?? '',
      classIds: List<String>.from(data['classIds'] ?? []),
      targetAudience: List<String>.from(data['targetAudience'] ?? []),
      questions: questions,
      totalMarks: data['totalMarks'] ?? 0,
      duration: data['duration'] ?? 30,
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'subject': subject,
      'chapter': chapter,
      'topic': topic,
      'testType': testType.toString().split('.').last,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'classIds': classIds,
      'targetAudience': targetAudience,
      'questions': questions.map((q) => q.toMap()).toList(),
      'totalMarks': totalMarks,
      'duration': duration,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  int get questionCount => questions.length;
}
