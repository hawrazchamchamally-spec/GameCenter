import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';

/// Represents an authorized user/employee in the lounge system
class UserModel {
  final String uid;
  final String name;
  final String? username;
  final String role; // 'admin' or 'staff'
  final String? email;
  final String? password;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  const UserModel({
    required this.uid,
    required this.name,
    this.username,
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

  /// Display username or fallback
  String get displayUsername =>
      username ?? (email != null && email!.contains('@') ? email!.split('@').first : uid);

  /// Converts UserModel to Firestore JSON Map
  Map<String, dynamic> toJson() {
    final effectiveUsername = username ?? (email != null && email!.contains('@') ? email!.split('@').first : uid);
    return {
      'name': name,
      'username': effectiveUsername,
      'role': role,
      'email': email ?? '$effectiveUsername@gamecenter.local',
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

    final rawUsername = json['username'] as String?;
    final rawEmail = json['email'] as String?;
    final effectiveUid = uid.isNotEmpty ? uid : (json['uid'] as String? ?? (rawUsername ?? ''));

    return UserModel(
      uid: effectiveUid,
      name: json['name'] as String? ?? '',
      username: rawUsername ?? (rawEmail != null && rawEmail.contains('@') ? rawEmail.split('@').first : effectiveUid),
      role: json['role'] as String? ?? AppConstants.roleStaff,
      email: rawEmail ?? (rawUsername != null ? '$rawUsername@gamecenter.local' : null),
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
    String? username,
    String? role,
    String? email,
    String? password,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      username: username ?? this.username,
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
