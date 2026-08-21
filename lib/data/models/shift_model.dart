import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a staff work shift session and cash register reconciliation
class ShiftModel {
  final String id;
  final String staffId;
  final String staffName;
  final DateTime startTime;
  final DateTime? endTime;
  final String status; // 'active' or 'closed'
  final int totalSessionsCount;
  final double totalGamingRevenue;
  final double totalMarketRevenue;
  final double totalCashExpected;
  final String? notes;
  final DateTime createdAt;

  const ShiftModel({
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.startTime,
    this.endTime,
    this.status = 'active',
    this.totalSessionsCount = 0,
    this.totalGamingRevenue = 0.0,
    this.totalMarketRevenue = 0.0,
    this.totalCashExpected = 0.0,
    this.notes,
    required this.createdAt,
  });

  bool get isActive => status == 'active' && endTime == null;
  bool get isClosed => status == 'closed' || endTime != null;

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  /// Create a new active shift
  factory ShiftModel.startNew({
    required String shiftId,
    required String staffId,
    required String staffName,
    DateTime? startTime,
  }) {
    final now = startTime ?? DateTime.now();
    return ShiftModel(
      id: shiftId,
      staffId: staffId,
      staffName: staffName,
      startTime: now,
      status: 'active',
      totalSessionsCount: 0,
      totalGamingRevenue: 0.0,
      totalMarketRevenue: 0.0,
      totalCashExpected: 0.0,
      createdAt: now,
    );
  }

  /// Close shift with finalized metrics
  ShiftModel closeShift({
    required int sessionsCount,
    required double gamingRevenue,
    required double marketRevenue,
    String? notes,
    DateTime? endTime,
  }) {
    final end = endTime ?? DateTime.now();
    final totalCash = gamingRevenue + marketRevenue;

    return copyWith(
      endTime: end,
      status: 'closed',
      totalSessionsCount: sessionsCount,
      totalGamingRevenue: gamingRevenue,
      totalMarketRevenue: marketRevenue,
      totalCashExpected: totalCash,
      notes: notes,
    );
  }

  ShiftModel copyWith({
    String? id,
    String? staffId,
    String? staffName,
    DateTime? startTime,
    DateTime? endTime,
    String? status,
    int? totalSessionsCount,
    double? totalGamingRevenue,
    double? totalMarketRevenue,
    double? totalCashExpected,
    String? notes,
    DateTime? createdAt,
  }) {
    return ShiftModel(
      id: id ?? this.id,
      staffId: staffId ?? this.staffId,
      staffName: staffName ?? this.staffName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      totalSessionsCount: totalSessionsCount ?? this.totalSessionsCount,
      totalGamingRevenue: totalGamingRevenue ?? this.totalGamingRevenue,
      totalMarketRevenue: totalMarketRevenue ?? this.totalMarketRevenue,
      totalCashExpected: totalCashExpected ?? this.totalCashExpected,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'staffId': staffId,
      'staffName': staffName,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'status': status,
      'totalSessionsCount': totalSessionsCount,
      'totalGamingRevenue': totalGamingRevenue,
      'totalMarketRevenue': totalMarketRevenue,
      'totalCashExpected': totalCashExpected,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ShiftModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return ShiftModel.fromMap(data, doc.id);
  }

  factory ShiftModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return ShiftModel(
      id: docId ?? map['id'] ?? '',
      staffId: map['staffId'] ?? '',
      staffName: map['staffName'] ?? 'موظف الصالة',
      startTime: parseDateTime(map['startTime']),
      endTime: map['endTime'] != null ? parseDateTime(map['endTime']) : null,
      status: map['status'] ?? 'active',
      totalSessionsCount: (map['totalSessionsCount'] as num?)?.toInt() ?? 0,
      totalGamingRevenue: (map['totalGamingRevenue'] as num?)?.toDouble() ?? 0.0,
      totalMarketRevenue: (map['totalMarketRevenue'] as num?)?.toDouble() ?? 0.0,
      totalCashExpected: (map['totalCashExpected'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'],
      createdAt: parseDateTime(map['createdAt']),
    );
  }
}
