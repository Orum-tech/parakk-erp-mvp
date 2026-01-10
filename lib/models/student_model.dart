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
    required super.createdAt,
    this.studentId,
    this.rollNumber,
    this.classId,
    this.className,
    this.section,
    this.parentId,
    this.parentName,
    this.phoneNumber,
    this.address,
    this.dateOfBirth,
    this.bloodGroup,
    this.emergencyContact,
    this.academicInfo,
  }) : super(role: UserRole.student);

  factory StudentModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StudentModel(
      uid: data['uid'] ?? doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      studentId: data['studentId'] ?? doc.id,
      rollNumber: data['rollNumber'],
      classId: data['classId'],
      className: data['className'],
      section: data['section'],
      parentId: data['parentId'],
      parentName: data['parentName'],
      phoneNumber: data['phoneNumber'],
      address: data['address'],
      dateOfBirth: (data['dateOfBirth'] as Timestamp?)?.toDate(),
      bloodGroup: data['bloodGroup'],
      emergencyContact: data['emergencyContact'],
      academicInfo: data['academicInfo'],
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
    Timestamp? createdAt,
    String? studentId,
    String? rollNumber,
    String? classId,
    String? className,
    String? section,
    String? parentId,
    String? parentName,
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
      createdAt: createdAt ?? this.createdAt,
      studentId: studentId ?? this.studentId,
      rollNumber: rollNumber ?? this.rollNumber,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      section: section ?? this.section,
      parentId: parentId ?? this.parentId,
      parentName: parentName ?? this.parentName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      academicInfo: academicInfo ?? this.academicInfo,
    );
  }
}
