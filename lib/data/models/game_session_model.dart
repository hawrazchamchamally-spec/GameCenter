import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import 'order_item_model.dart';
import 'rate_change_history.dart';

/// Represents an active or completed gaming session on a screen
class GameSessionModel {
  final String sessionId;
  final String screenId;
  final int screenNumber;
  final int playerCount; // 2, 3, or 4 players
  final DateTime startTime;
  final DateTime? endTime;
  final double pricingRate; // Current hourly rate: 3000, 4000, or 5000 IQD
  final double totalGamingCost;
  final double totalMarketCost;
  final double totalAmount;
  final bool isPaid;
  final List<OrderItem> orders;
  final List<RateChangeHistory> rateHistory;
  final String? notes;
  final String? createdBy;

  // Budget-based session properties
  final bool isBudgetBased;
  final double? targetBudget;
  final int? targetDurationMinutes;
  final DateTime? allocatedEndTime;

  const GameSessionModel({
    required this.sessionId,
    required this.screenId,
    required this.screenNumber,
    required this.playerCount,
    required this.startTime,
    this.endTime,
    required this.pricingRate,
    this.totalGamingCost = 0.0,
    this.totalMarketCost = 0.0,
    this.totalAmount = 0.0,
    this.isPaid = false,
    this.orders = const [],
    this.rateHistory = const [],
    this.notes,
    this.createdBy,
    this.isBudgetBased = false,
    this.targetBudget,
    this.targetDurationMinutes,
    this.allocatedEndTime,
  });

  /// Check if session is currently ongoing
  bool get isActive => endTime == null;

  /// Factory to start a brand new session
  factory GameSessionModel.startNew({
    required String sessionId,
    required String screenId,
    required int screenNumber,
    required int playerCount,
    DateTime? startTime,
    String? createdBy,
    String? notes,
    bool isBudgetBased = false,
    double? targetBudget,
    int? targetDurationMinutes,
    DateTime? allocatedEndTime,
  }) {
    final start = startTime ?? DateTime.now();
    final rate = AppConstants.getRateForPlayers(playerCount);

    final initialHistory = RateChangeHistory(
      playerCount: playerCount,
      ratePerHour: rate,
      startedAt: start,
      endedAt: null,
      costForDuration: null,
    );

    // If targetDurationMinutes is set but allocatedEndTime is not, compute it
    final calculatedEndTime = allocatedEndTime ??
        (targetDurationMinutes != null
            ? start.add(Duration(minutes: targetDurationMinutes))
            : null);

    return GameSessionModel(
      sessionId: sessionId,
      screenId: screenId,
      screenNumber: screenNumber,
      playerCount: playerCount,
      startTime: start,
      endTime: null,
      pricingRate: rate,
      totalGamingCost: 0.0,
      totalMarketCost: 0.0,
      totalAmount: 0.0,
      isPaid: false,
      orders: const [],
      rateHistory: [initialHistory],
      createdBy: createdBy,
      notes: notes,
      isBudgetBased: isBudgetBased,
      targetBudget: targetBudget,
      targetDurationMinutes: targetDurationMinutes,
      allocatedEndTime: calculatedEndTime,
    );
  }

  /// Remaining duration if budget-based session
  Duration getRemainingDuration({DateTime? atTime}) {
    if (!isBudgetBased || allocatedEndTime == null) {
      return Duration.zero;
    }
    final effectiveNow = atTime ?? DateTime.now();
    final remaining = allocatedEndTime!.difference(effectiveNow);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Whether the allocated budget time has expired
  bool isTimeExpired({DateTime? atTime}) {
    if (!isBudgetBased || allocatedEndTime == null) return false;
    final effectiveNow = atTime ?? DateTime.now();
    return effectiveNow.isAfter(allocatedEndTime!);
  }

  /// Progress percentage of time spent (from 0.0 to 1.0)
  double getBudgetProgressPercentage({DateTime? atTime}) {
    if (!isBudgetBased || targetDurationMinutes == null || targetDurationMinutes! <= 0) {
      return 0.0;
    }
    final totalSeconds = targetDurationMinutes! * 60.0;
    final elapsedSeconds = getElapsedDuration(atTime: atTime).inSeconds.toDouble();
    return (elapsedSeconds / totalSeconds).clamp(0.0, 1.0);
  }

  /// Calculates real-time gaming cost based on rateHistory segments
  double calculateRealTimeGamingCost({DateTime? atTime}) {
    if (!isActive && totalGamingCost > 0) {
      return totalGamingCost;
    }

    if (rateHistory.isEmpty) {
      final effectiveEnd = endTime ?? atTime ?? DateTime.now();
      final duration = effectiveEnd.difference(startTime);
      final hours = duration.inSeconds / 3600.0;
      return hours * pricingRate;
    }

    double total = 0.0;
    for (final segment in rateHistory) {
      total += segment.calculateCost(atTime: atTime);
    }
    return total;
  }

  /// Calculates total cost of all market orders
  double calculateTotalMarketCost() {
    return orders.fold<double>(
      0.0,
      (total, item) => total + item.totalPrice,
    );
  }

  /// Calculates total bill amount (Gaming + Market)
  double calculateTotalAmount({DateTime? atTime}) {
    final gaming = calculateRealTimeGamingCost(atTime: atTime);
    final market = calculateTotalMarketCost();
    return gaming + market;
  }

  /// Total elapsed duration for the session
  Duration getElapsedDuration({DateTime? atTime}) {
    final effectiveEnd = endTime ?? atTime ?? DateTime.now();
    if (effectiveEnd.isBefore(startTime)) {
      return Duration.zero;
    }
    return effectiveEnd.difference(startTime);
  }

  /// Changes the player count and updates rateHistory accurately
  GameSessionModel changePlayerCount(int newPlayerCount, {DateTime? changeTime}) {
    if (newPlayerCount == playerCount) return this;

    final now = changeTime ?? DateTime.now();
    final newRate = AppConstants.getRateForPlayers(newPlayerCount);

    final updatedHistory = <RateChangeHistory>[];

    // Close the current active rate history segment
    for (int i = 0; i < rateHistory.length; i++) {
      final segment = rateHistory[i];
      if (segment.endedAt == null) {
        updatedHistory.add(segment.closeWithEndTime(now));
      } else {
        updatedHistory.add(segment);
      }
    }

    // Add new rate segment
    updatedHistory.add(RateChangeHistory(
      playerCount: newPlayerCount,
      ratePerHour: newRate,
      startedAt: now,
      endedAt: null,
      costForDuration: null,
    ));

    final currentGamingCost = _calculateHistoryCost(updatedHistory, atTime: now);
    final currentMarketCost = calculateTotalMarketCost();

    return copyWith(
      playerCount: newPlayerCount,
      pricingRate: newRate,
      rateHistory: updatedHistory,
      totalGamingCost: currentGamingCost,
      totalMarketCost: currentMarketCost,
      totalAmount: currentGamingCost + currentMarketCost,
    );
  }

  /// Helper to calculate history cost
  static double _calculateHistoryCost(List<RateChangeHistory> history, {DateTime? atTime}) {
    double total = 0.0;
    for (final seg in history) {
      total += seg.calculateCost(atTime: atTime);
    }
    return total;
  }

  /// Adds a market order to the session and recalculates totals
  GameSessionModel addOrder(OrderItem item) {
    final updatedOrders = List<OrderItem>.from(orders);

    final existingIndex = updatedOrders.indexWhere(
      (o) => o.productId == item.productId && o.unitPrice == item.unitPrice,
    );

    if (existingIndex >= 0) {
      final existing = updatedOrders[existingIndex];
      updatedOrders[existingIndex] = existing.copyWith(
        quantity: existing.quantity + item.quantity,
        totalPrice: (existing.quantity + item.quantity) * existing.unitPrice,
      );
    } else {
      updatedOrders.add(item);
    }

    final newMarketCost = updatedOrders.fold<double>(
      0.0,
      (total, o) => total + o.totalPrice,
    );
    final gamingCost = calculateRealTimeGamingCost();

    return copyWith(
      orders: updatedOrders,
      totalMarketCost: newMarketCost,
      totalAmount: gamingCost + newMarketCost,
    );
  }

  /// Removes an order item from the session
  GameSessionModel removeOrder(String productId) {
    final updatedOrders = orders.where((o) => o.productId != productId).toList();
    final newMarketCost = updatedOrders.fold<double>(
      0.0,
      (total, o) => total + o.totalPrice,
    );
    final gamingCost = calculateRealTimeGamingCost();

    return copyWith(
      orders: updatedOrders,
      totalMarketCost: newMarketCost,
      totalAmount: gamingCost + newMarketCost,
    );
  }

  /// Ends the session, closes rate history and sets final costs (with optional custom received amount)
  GameSessionModel endSession({
    DateTime? endAt,
    bool isPaid = true,
    double? customTotalAmount,
  }) {
    final finalEndTime = endAt ?? DateTime.now();
    final updatedHistory = <RateChangeHistory>[];

    for (final segment in rateHistory) {
      if (segment.endedAt == null) {
        updatedHistory.add(segment.closeWithEndTime(finalEndTime));
      } else {
        updatedHistory.add(segment);
      }
    }

    final finalGamingCost = _calculateHistoryCost(updatedHistory, atTime: finalEndTime);
    final finalMarketCost = calculateTotalMarketCost();
    final calculatedTotal = finalGamingCost + finalMarketCost;
    final finalTotal = customTotalAmount ?? calculatedTotal;

    return copyWith(
      endTime: finalEndTime,
      isPaid: isPaid,
      rateHistory: updatedHistory,
      totalGamingCost: finalGamingCost,
      totalMarketCost: finalMarketCost,
      totalAmount: finalTotal,
    );
  }

  /// Converts to Firestore JSON Map
  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'screenId': screenId,
      'screenNumber': screenNumber,
      'playerCount': playerCount,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'pricingRate': pricingRate,
      'totalGamingCost': totalGamingCost,
      'totalMarketCost': totalMarketCost,
      'totalAmount': totalAmount,
      'isPaid': isPaid,
      'orders': orders.map((o) => o.toMap()).toList(),
      'rateHistory': rateHistory.map((r) => r.toMap()).toList(),
      'notes': notes,
      'createdBy': createdBy,
      'isBudgetBased': isBudgetBased,
      'targetBudget': targetBudget,
      'targetDurationMinutes': targetDurationMinutes,
      'allocatedEndTime': allocatedEndTime != null ? Timestamp.fromDate(allocatedEndTime!) : null,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  /// Factory constructor from Map JSON
  factory GameSessionModel.fromMap(Map<String, dynamic> map, {String id = ''}) {
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

    final rawOrders = map['orders'] as List<dynamic>?;
    final parsedOrders = rawOrders != null
        ? rawOrders
            .where((x) => x != null)
            .map((x) {
              if (x is OrderItem) return x;
              if (x is Map) {
                return OrderItem.fromMap(Map<String, dynamic>.from(x));
              }
              return null;
            })
            .whereType<OrderItem>()
            .toList()
        : <OrderItem>[];

    final rawHistory = map['rateHistory'] as List<dynamic>?;
    final parsedHistory = rawHistory != null
        ? rawHistory
            .where((r) => r != null)
            .map((r) {
              if (r is RateChangeHistory) return r;
              if (r is Map) {
                return RateChangeHistory.fromMap(Map<String, dynamic>.from(r));
              }
              return null;
            })
            .whereType<RateChangeHistory>()
            .toList()
        : <RateChangeHistory>[];

    return GameSessionModel(
      sessionId: id.isNotEmpty ? id : (map['sessionId'] as String? ?? ''),
      screenId: map['screenId'] as String? ?? '',
      screenNumber: (map['screenNumber'] as num?)?.toInt() ?? 1,
      playerCount: (map['playerCount'] as num?)?.toInt() ?? 2,
      startTime: parseDate(map['startTime'], DateTime.now()),
      endTime: parseNullableDate(map['endTime']),
      pricingRate: (map['pricingRate'] as num?)?.toDouble() ?? 3000.0,
      totalGamingCost: (map['totalGamingCost'] as num?)?.toDouble() ?? 0.0,
      totalMarketCost: (map['totalMarketCost'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      isPaid: map['isPaid'] as bool? ?? false,
      orders: parsedOrders,
      rateHistory: parsedHistory,
      notes: map['notes'] as String?,
      createdBy: map['createdBy'] as String?,
      isBudgetBased: map['isBudgetBased'] as bool? ?? false,
      targetBudget: (map['targetBudget'] as num?)?.toDouble(),
      targetDurationMinutes: (map['targetDurationMinutes'] as num?)?.toInt(),
      allocatedEndTime: parseNullableDate(map['allocatedEndTime']),
    );
  }

  factory GameSessionModel.fromJson(Map<String, dynamic> json, {String id = ''}) =>
      GameSessionModel.fromMap(json, id: id);

  /// Factory constructor from Firestore DocumentSnapshot
  factory GameSessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return GameSessionModel.fromMap(data, id: doc.id);
  }

  GameSessionModel copyWith({
    String? sessionId,
    String? screenId,
    int? screenNumber,
    int? playerCount,
    DateTime? startTime,
    DateTime? endTime,
    double? pricingRate,
    double? totalGamingCost,
    double? totalMarketCost,
    double? totalAmount,
    bool? isPaid,
    List<OrderItem>? orders,
    List<RateChangeHistory>? rateHistory,
    String? notes,
    String? createdBy,
    bool? isBudgetBased,
    double? targetBudget,
    int? targetDurationMinutes,
    DateTime? allocatedEndTime,
  }) {
    return GameSessionModel(
      sessionId: sessionId ?? this.sessionId,
      screenId: screenId ?? this.screenId,
      screenNumber: screenNumber ?? this.screenNumber,
      playerCount: playerCount ?? this.playerCount,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      pricingRate: pricingRate ?? this.pricingRate,
      totalGamingCost: totalGamingCost ?? this.totalGamingCost,
      totalMarketCost: totalMarketCost ?? this.totalMarketCost,
      totalAmount: totalAmount ?? this.totalAmount,
      isPaid: isPaid ?? this.isPaid,
      orders: orders ?? this.orders,
      rateHistory: rateHistory ?? this.rateHistory,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      isBudgetBased: isBudgetBased ?? this.isBudgetBased,
      targetBudget: targetBudget ?? this.targetBudget,
      targetDurationMinutes: targetDurationMinutes ?? this.targetDurationMinutes,
      allocatedEndTime: allocatedEndTime ?? this.allocatedEndTime,
    );
  }
}
