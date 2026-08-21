import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';

/// Represents an authorized user/employee in the lounge system
class UserModel {
  final String uid;
  final String name;
  final String role; // 'admin' or 'staff'
  final String? email;
  final String? password;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.role,
    this.email,
    this.password,
    this.createdAt,
    this.lastLoginAt,
  });

  /// Check if user is an Admin
  bool get isAdmin => role.toLowerCase() == AppConstants.roleAdmin;

  /// Check if user is Staff
  bool get isStaff => role.toLowerCase() == AppConstants.roleStaff;

  /// Arabic role display name
  String get roleArabic => isAdmin ? 'مدير النظام (Admin)' : 'موظف كاشير (Staff)';

  /// Converts UserModel to Firestore JSON Map
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'role': role,
      'email': email,
      'password': password,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
    };
  }

  /// Factory constructor from Map JSON
  factory UserModel.fromJson(Map<String, dynamic> json, {String uid = ''}) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return UserModel(
      uid: uid.isNotEmpty ? uid : (json['uid'] as String? ?? ''),
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? AppConstants.roleStaff,
      email: json['email'] as String?,
      password: json['password'] as String?,
      createdAt: parseDate(json['createdAt']),
      lastLoginAt: parseDate(json['lastLoginAt']),
    );
  }

  /// Factory constructor from Firestore DocumentSnapshot
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel.fromJson(data, uid: doc.id);
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? role,
    String? email,
    String? password,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      role: role ?? this.role,
      email: email ?? this.email,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          role == other.role;

  @override
  int get hashCode => uid.hashCode ^ role.hashCode;
}
