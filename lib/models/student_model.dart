import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

class StudentModel extends UserModel {
  final String? studentId;
  final String? rollNumber;
  final String? classId;
  final String? className;
  final String? section;
  final String? parentId;
  final String? parentName;
  final String? parentEmail;
  final String? phoneNumber;
  final String? address;
  final DateTime? dateOfBirth;
  final String? bloodGroup;
  final String? emergencyContact;
  final Map<String, dynamic>? academicInfo;

  StudentModel({
    required super.uid,
    required super.name,
    required super.email,
    required super.schoolId,
    required super.createdAt,
    this.studentId,
    this.rollNumber,
    this.classId,
    this.className,
    this.section,
    this.parentId,
    this.parentName,
    this.parentEmail,
    this.phoneNumber,
    this.address,
    this.dateOfBirth,
    this.bloodGroup,
    this.emergencyContact,
    this.academicInfo,
    super.isActive,
  }) : super(role: UserRole.student);

  factory StudentModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StudentModel(
      uid: data['uid'] ?? doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      schoolId: data['schoolId'] ?? '', // Will be required after migration
      createdAt: data['createdAt'] ?? Timestamp.now(),
      studentId: data['studentId'] ?? doc.id,
      rollNumber: data['rollNumber'],
      classId: data['classId'],
      className: data['className'],
      section: data['section'],
      parentId: data['parentId'],
      parentName: data['parentName'],
      parentEmail: data['parentEmail'],
      phoneNumber: data['phoneNumber'],
      address: data['address'],
      dateOfBirth: (data['dateOfBirth'] as Timestamp?)?.toDate(),
      bloodGroup: data['bloodGroup'],
      emergencyContact: data['emergencyContact'],
      academicInfo: data['academicInfo'],
      isActive: data['isActive'] ?? true,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'studentId': studentId ?? uid,
      'rollNumber': rollNumber,
      'classId': classId,
      'className': className,
      'section': section,
      'parentId': parentId,
      'parentName': parentName,
      'parentEmail': parentEmail,
      'phoneNumber': phoneNumber,
      'address': address,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'bloodGroup': bloodGroup,
      'emergencyContact': emergencyContact,
      'academicInfo': academicInfo,
    });
    return map;
  }

  StudentModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? schoolId,
    bool? isActive,
    Timestamp? createdAt,
    String? studentId,
    String? rollNumber,
    String? classId,
    String? className,
    String? section,
    String? parentId,
    String? parentName,
    String? parentEmail,
    String? phoneNumber,
    String? address,
    DateTime? dateOfBirth,
    String? bloodGroup,
    String? emergencyContact,
    Map<String, dynamic>? academicInfo,
  }) {
    return StudentModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      schoolId: schoolId ?? this.schoolId,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      studentId: studentId ?? this.studentId,
      rollNumber: rollNumber ?? this.rollNumber,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      section: section ?? this.section,
      parentId: parentId ?? this.parentId,
      parentName: parentName ?? this.parentName,
      parentEmail: parentEmail ?? this.parentEmail,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      academicInfo: academicInfo ?? this.academicInfo,
    );
  }
}
