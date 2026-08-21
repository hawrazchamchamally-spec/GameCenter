import 'package:flutter_test/flutter_test.dart';
import 'package:game_center/core/constants/app_constants.dart';
import 'package:game_center/core/utils/pricing_calculator.dart';
import 'package:game_center/data/models/models.dart';

void main() {
  group('PricingCalculator & Hourly Rates Tests', () {
    test('Hourly rates constants match requirements', () {
      expect(AppConstants.getRateForPlayers(2), equals(3000.0));
      expect(AppConstants.getRateForPlayers(3), equals(4000.0));
      expect(AppConstants.getRateForPlayers(4), equals(5000.0));
    });

    test('Calculates simple 1-hour session cost for 2 players accurately', () {
      final cost = PricingCalculator.calculateCostForDuration(
        playerCount: 2,
        duration: const Duration(hours: 1),
      );
      expect(cost, equals(3000.0));
    });

    test('Calculates 30-minute session cost for 4 players accurately', () {
      final cost = PricingCalculator.calculateCostForDuration(
        playerCount: 4,
        duration: const Duration(minutes: 30),
      );
      expect(cost, equals(2500.0));
    });

    test('Calculates multi-segment session with player count changes (rateHistory)', () {
      final startTime = DateTime(2026, 8, 18, 14, 0, 0);
      final switchTime = DateTime(2026, 8, 18, 14, 30, 0); // After 30 minutes
      final endTime = DateTime(2026, 8, 18, 15, 30, 0); // After 60 minutes with 4 players

      // Start session with 2 players
      var session = GameSessionModel.startNew(
        sessionId: 'test_session_1',
        screenId: 'screen_1',
        screenNumber: 1,
        playerCount: 2,
        startTime: startTime,
      );

      // After 30 minutes, switch to 4 players
      session = session.changePlayerCount(4, changeTime: switchTime);

      // End session at 15:30 (total 1.5 hours: 30m at 3000/hr + 60m at 5000/hr)
      session = session.endSession(endAt: endTime);

      // Expected Gaming Cost: (0.5 * 3000) + (1.0 * 5000) = 1500 + 5000 = 6500 IQD
      final calculatedGamingCost = session.calculateRealTimeGamingCost(atTime: endTime);
      expect(calculatedGamingCost, equals(6500.0));
      expect(session.totalGamingCost, equals(6500.0));
    });

    test('Calculates combined bill with gaming cost and market orders', () {
      final startTime = DateTime(2026, 8, 18, 16, 0, 0);
      final endTime = DateTime(2026, 8, 18, 17, 0, 0); // 1 hour

      var session = GameSessionModel.startNew(
        sessionId: 'test_session_2',
        screenId: 'screen_2',
        screenNumber: 2,
        playerCount: 3, // 4000 IQD / hr
        startTime: startTime,
      );

      // Add Market orders: 2 Pepsi (1000 each) + 1 Red Bull (3000)
      session = session.addOrder(OrderItem.create(
        productId: 'pepsi_1',
        productName: 'Pepsi',
        quantity: 2,
        unitPrice: 1000.0,
      ));

      session = session.addOrder(OrderItem.create(
        productId: 'redbull_1',
        productName: 'Red Bull',
        quantity: 1,
        unitPrice: 3000.0,
      ));

      session = session.endSession(endAt: endTime);

      // Gaming Cost = 1 hour * 4000 = 4000 IQD
      // Market Cost = (2 * 1000) + (1 * 3000) = 5000 IQD
      // Total Amount = 4000 + 5000 = 9000 IQD
      expect(session.totalGamingCost, equals(4000.0));
      expect(session.totalMarketCost, equals(5000.0));
      expect(session.totalAmount, equals(9000.0));
    });
  });
}
