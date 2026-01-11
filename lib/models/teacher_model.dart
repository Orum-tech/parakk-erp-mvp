import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

class TeacherModel extends UserModel {
  final String? teacherId;
  final String? employeeId;
  final String? phoneNumber;
  final String? address;
  final List<String>? subjects;
  final List<String>? classIds;
  final String? classTeacherClassId; // Single class where teacher is class teacher
  final String? department;
  final String? qualification;
  final int? yearsOfExperience;
  final DateTime? joiningDate;
  final String? specialization;

  TeacherModel({
    required super.uid,
    required super.name,
    required super.email,
    required super.createdAt,
    this.teacherId,
    this.employeeId,
    this.phoneNumber,
    this.address,
    this.subjects,
    this.classIds,
    this.classTeacherClassId,
    this.department,
    this.qualification,
    this.yearsOfExperience,
    this.joiningDate,
    this.specialization,
  }) : super(role: UserRole.teacher);

  factory TeacherModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TeacherModel(
      uid: data['uid'] ?? doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      teacherId: data['teacherId'] ?? doc.id,
      employeeId: data['employeeId'],
      phoneNumber: data['phoneNumber'],
      address: data['address'],
      subjects: List<String>.from(data['subjects'] ?? []),
      classIds: List<String>.from(data['classIds'] ?? []),
      classTeacherClassId: data['classTeacherClassId'],
      department: data['department'],
      qualification: data['qualification'],
      yearsOfExperience: data['yearsOfExperience'],
      joiningDate: (data['joiningDate'] as Timestamp?)?.toDate(),
      specialization: data['specialization'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'teacherId': teacherId ?? uid,
      'employeeId': employeeId,
      'phoneNumber': phoneNumber,
      'address': address,
      'subjects': subjects,
      'classIds': classIds,
      'classTeacherClassId': classTeacherClassId,
      'department': department,
      'qualification': qualification,
      'yearsOfExperience': yearsOfExperience,
      'joiningDate': joiningDate != null ? Timestamp.fromDate(joiningDate!) : null,
      'specialization': specialization,
    });
    return map;
  }

  TeacherModel copyWith({
    String? uid,
    String? name,
    String? email,
    Timestamp? createdAt,
    String? teacherId,
    String? employeeId,
    String? phoneNumber,
    String? address,
    List<String>? subjects,
    List<String>? classIds,
    String? classTeacherClassId,
    String? department,
    String? qualification,
    int? yearsOfExperience,
    DateTime? joiningDate,
    String? specialization,
  }) {
    return TeacherModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      teacherId: teacherId ?? this.teacherId,
      employeeId: employeeId ?? this.employeeId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      subjects: subjects ?? this.subjects,
      classIds: classIds ?? this.classIds,
      classTeacherClassId: classTeacherClassId ?? this.classTeacherClassId,
      department: department ?? this.department,
      qualification: qualification ?? this.qualification,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      joiningDate: joiningDate ?? this.joiningDate,
      specialization: specialization ?? this.specialization,
    );
  }
}
