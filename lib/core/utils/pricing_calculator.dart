import '../constants/app_constants.dart';
import '../../data/models/game_session_model.dart';
import '../../data/models/rate_change_history.dart';
import '../../data/models/order_item_model.dart';

/// Calculation engine for Gaming Lounge pricing and session breakdowns
class PricingCalculator {
  /// Calculates gaming cost for a specific duration in minutes and player count
  static double calculateCostForDuration({
    required int playerCount,
    required Duration duration,
  }) {
    final ratePerHour = AppConstants.getRateForPlayers(playerCount);
    final hours = duration.inSeconds / 3600.0;
    return hours * ratePerHour;
  }

  /// Calculates gaming cost across a list of rate change history segments
  static double calculateTotalGamingCost({
    required List<RateChangeHistory> history,
    DateTime? currentTime,
  }) {
    final now = currentTime ?? DateTime.now();
    double totalCost = 0.0;

    for (final segment in history) {
      totalCost += segment.calculateCost(atTime: now);
    }

    return totalCost;
  }

  /// Calculates total cost of market orders
  static double calculateOrdersTotal(List<OrderItem> orders) {
    return orders.fold<double>(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );
  }

  /// Calculates comprehensive session bill breakdown
  static SessionBillBreakdown calculateSessionBill(
    GameSessionModel session, {
    DateTime? atTime,
  }) {
    final effectiveTime = atTime ?? session.endTime ?? DateTime.now();
    final gamingCost = session.calculateRealTimeGamingCost(atTime: effectiveTime);
    final marketCost = session.calculateTotalMarketCost();
    final totalDuration = session.getElapsedDuration(atTime: effectiveTime);

    return SessionBillBreakdown(
      totalDuration: totalDuration,
      gamingCost: gamingCost,
      marketCost: marketCost,
      totalAmount: gamingCost + marketCost,
      segments: session.rateHistory,
      orders: session.orders,
    );
  }
}

/// Detailed breakdown of a session bill
class SessionBillBreakdown {
  final Duration totalDuration;
  final double gamingCost;
  final double marketCost;
  final double totalAmount;
  final List<RateChangeHistory> segments;
  final List<OrderItem> orders;

  const SessionBillBreakdown({
    required this.totalDuration,
    required this.gamingCost,
    required this.marketCost,
    required this.totalAmount,
    required this.segments,
    required this.orders,
  });
}
