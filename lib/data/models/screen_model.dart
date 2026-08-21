import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a Gaming Screen / Table in the Lounge
class ScreenModel {
  final String id;
  final int screenNumber;
  final String? name; // e.g. "شاشة VIP 1" or "طاولة 9"
  final String? deviceType; // e.g. "PS5", "PS4", "PC", "Xbox"
  final String? sectionName; // e.g. "الصالة العامة", "غرفة VIP 1"
  final bool isOccupied;
  final String? activeSessionId;
  final DateTime? lastSessionEndedAt;

  const ScreenModel({
    required this.id,
    required this.screenNumber,
    this.name,
    this.deviceType,
    this.sectionName,
    this.isOccupied = false,
    this.activeSessionId,
    this.lastSessionEndedAt,
  });

  /// Screen display name in Arabic
  String get nameArabic => (name != null && name!.trim().isNotEmpty) ? name! : 'شاشة $screenNumber';

  /// Converts ScreenModel to Firestore JSON Map
  Map<String, dynamic> toJson() {
    return {
      'screenNumber': screenNumber,
      'name': name,
      'deviceType': deviceType,
      'sectionName': sectionName,
      'isOccupied': isOccupied,
      'activeSessionId': activeSessionId,
      'lastSessionEndedAt': lastSessionEndedAt != null
          ? Timestamp.fromDate(lastSessionEndedAt!)
          : null,
    };
  }

  /// Factory constructor from Map JSON
  factory ScreenModel.fromJson(Map<String, dynamic> json, {String id = ''}) {
    DateTime? lastEnded;
    if (json['lastSessionEndedAt'] != null) {
      if (json['lastSessionEndedAt'] is Timestamp) {
        lastEnded = (json['lastSessionEndedAt'] as Timestamp).toDate();
      } else if (json['lastSessionEndedAt'] is String) {
        lastEnded = DateTime.tryParse(json['lastSessionEndedAt']);
      }
    }

    return ScreenModel(
      id: id.isNotEmpty ? id : (json['id'] as String? ?? ''),
      screenNumber: json['screenNumber'] as int? ?? 1,
      name: json['name'] as String?,
      deviceType: json['deviceType'] as String?,
      sectionName: json['sectionName'] as String?,
      isOccupied: json['isOccupied'] as bool? ?? false,
      activeSessionId: json['activeSessionId'] as String?,
      lastSessionEndedAt: lastEnded,
    );
  }

  /// Factory constructor from Firestore DocumentSnapshot
  factory ScreenModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ScreenModel.fromJson(data, id: doc.id);
  }

  /// Copy with modifications
  ScreenModel copyWith({
    String? id,
    int? screenNumber,
    String? name,
    String? deviceType,
    String? sectionName,
    bool? isOccupied,
    String? activeSessionId,
    bool clearActiveSession = false,
    DateTime? lastSessionEndedAt,
  }) {
    return ScreenModel(
      id: id ?? this.id,
      screenNumber: screenNumber ?? this.screenNumber,
      name: name ?? this.name,
      deviceType: deviceType ?? this.deviceType,
      sectionName: sectionName ?? this.sectionName,
      isOccupied: isOccupied ?? this.isOccupied,
      activeSessionId: clearActiveSession
          ? null
          : (activeSessionId ?? this.activeSessionId),
      lastSessionEndedAt: lastSessionEndedAt ?? this.lastSessionEndedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScreenModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          screenNumber == other.screenNumber &&
          isOccupied == other.isOccupied &&
          activeSessionId == other.activeSessionId &&
          deviceType == other.deviceType &&
          sectionName == other.sectionName;

  @override
  int get hashCode =>
      id.hashCode ^
      screenNumber.hashCode ^
      isOccupied.hashCode ^
      (activeSessionId?.hashCode ?? 0) ^
      (deviceType?.hashCode ?? 0) ^
      (sectionName?.hashCode ?? 0);
}
