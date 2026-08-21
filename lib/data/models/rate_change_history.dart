import 'package:cloud_firestore/cloud_firestore.dart';

/// Tracks player count and rate changes during a single gaming session
class RateChangeHistory {
  final int playerCount; // 2, 3, or 4 players
  final double ratePerHour; // 3000, 4000, 5000 IQD
  final DateTime startedAt;
  final DateTime? endedAt;
  final double? costForDuration;

  const RateChangeHistory({
    required this.playerCount,
    required this.ratePerHour,
    required this.startedAt,
    this.endedAt,
    this.costForDuration,
  });

  /// Duration for this specific rate period
  Duration getDuration({DateTime? atTime}) {
    final effectiveEnd = endedAt ?? atTime ?? DateTime.now();
    if (effectiveEnd.isBefore(startedAt)) {
      return Duration.zero;
    }
    return effectiveEnd.difference(startedAt);
  }

  /// Calculates the cost for this rate segment based on exact elapsed seconds/minutes
  double calculateCost({DateTime? atTime}) {
    if (costForDuration != null && endedAt != null) {
      return costForDuration!;
    }
    final duration = getDuration(atTime: atTime);
    final hours = duration.inSeconds / 3600.0;
    return (hours * ratePerHour);
  }

  /// Converts to Map JSON for Firestore
  Map<String, dynamic> toMap() {
    return {
      'playerCount': playerCount,
      'ratePerHour': ratePerHour,
      'startedAt': Timestamp.fromDate(startedAt),
      'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
      'costForDuration': costForDuration,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  /// Factory constructor from Map JSON
  factory RateChangeHistory.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value, DateTime fallback) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? fallback;
      return fallback;
    }

    DateTime? parseNullableDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return RateChangeHistory(
      playerCount: (map['playerCount'] as num?)?.toInt() ?? 2,
      ratePerHour: (map['ratePerHour'] as num?)?.toDouble() ?? 3000.0,
      startedAt: parseDate(map['startedAt'], DateTime.now()),
      endedAt: parseNullableDate(map['endedAt']),
      costForDuration: (map['costForDuration'] as num?)?.toDouble(),
    );
  }

  factory RateChangeHistory.fromJson(Map<String, dynamic> json) =>
      RateChangeHistory.fromMap(json);

  /// Closes this history interval with an end time and calculated cost
  RateChangeHistory closeWithEndTime(DateTime endTime) {
    final duration = endTime.difference(startedAt);
    final hours = duration.inSeconds / 3600.0;
    final cost = (hours * ratePerHour);

    return RateChangeHistory(
      playerCount: playerCount,
      ratePerHour: ratePerHour,
      startedAt: startedAt,
      endedAt: endTime,
      costForDuration: cost,
    );
  }

  RateChangeHistory copyWith({
    int? playerCount,
    double? ratePerHour,
    DateTime? startedAt,
    DateTime? endedAt,
    double? costForDuration,
  }) {
    return RateChangeHistory(
      playerCount: playerCount ?? this.playerCount,
      ratePerHour: ratePerHour ?? this.ratePerHour,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      costForDuration: costForDuration ?? this.costForDuration,
    );
  }
}
