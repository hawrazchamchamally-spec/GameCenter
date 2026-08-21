import 'package:flutter_test/flutter_test.dart';
import 'package:game_center/core/utils/session_timer_service.dart';
import 'package:game_center/data/models/models.dart';

void main() {
  group('SessionTimerService Calculations & Dynamic Switching Tests', () {
    test('Calculates precise minute-based pricing formula (minutes / 60) * ratePerHour', () {
      // 45 minutes at 3000 IQD/hr -> (45/60) * 3000 = 2250 IQD
      final cost45m = SessionTimerService.calculateCost(
        duration: const Duration(minutes: 45),
        ratePerHour: 3000.0,
      );
      expect(cost45m, equals(2250.0));

      // 90 minutes at 4000 IQD/hr -> (90/60) * 4000 = 6000 IQD
      final cost90m = SessionTimerService.calculateCost(
        duration: const Duration(minutes: 90),
        ratePerHour: 4000.0,
      );
      expect(cost90m, equals(6000.0));

      // 15 minutes at 5000 IQD/hr -> (15/60) * 5000 = 1250 IQD
      final cost15m = SessionTimerService.calculateCost(
        duration: const Duration(minutes: 15),
        ratePerHour: 5000.0,
      );
      expect(cost15m, equals(1250.0));
    });

    test('Performs dynamic in-game rate switching across multiple intervals accurately', () {
      final start = DateTime(2026, 8, 18, 10, 0, 0);
      final switch1 = DateTime(2026, 8, 18, 10, 40, 0); // After 40 min with 2 players
      final switch2 = DateTime(2026, 8, 18, 11, 10, 0); // After 30 min with 4 players
      final finish = DateTime(2026, 8, 18, 11, 40, 0); // After 30 min with 3 players

      // 1. Start Session with 2 players (3,000 IQD/hr)
      var session = GameSessionModel.startNew(
        sessionId: 'multi_sess_1',
        screenId: 'screen_1',
        screenNumber: 1,
        playerCount: 2,
        startTime: start,
      );

      // 2. Switch to 4 players (5,000 IQD/hr) at 10:40
      session = SessionTimerService.applyPlayerCountChange(
        session: session,
        newPlayerCount: 4,
        switchTime: switch1,
      );

      // 3. Switch to 3 players (4,000 IQD/hr) at 11:10
      session = SessionTimerService.applyPlayerCountChange(
        session: session,
        newPlayerCount: 3,
        switchTime: switch2,
      );

      // 4. Calculate at finish (11:40)
      final calc = SessionTimerService.calculateSession(session: session, atTime: finish);

      expect(calc.segments.length, equals(3));

      // Segment 1: 40 min @ 3000 = 2000 IQD
      expect(calc.segments[0].playerCount, equals(2));
      expect(calc.segments[0].cost, equals(2000.0));

      // Segment 2: 30 min @ 5000 = 2500 IQD
      expect(calc.segments[1].playerCount, equals(4));
      expect(calc.segments[1].cost, equals(2500.0));

      // Segment 3: 30 min @ 4000 = 2000 IQD
      expect(calc.segments[2].playerCount, equals(3));
      expect(calc.segments[2].cost, equals(2000.0));

      // Total Gaming Cost = 2000 + 2500 + 2000 = 6500 IQD
      expect(calc.totalGamingCost, equals(6500.0));
      expect(calc.totalDuration, equals(const Duration(minutes: 100)));
    });

    test('Combines gaming intervals and market orders into complete grand total', () {
      final start = DateTime(2026, 8, 18, 12, 0, 0);
      final finish = DateTime(2026, 8, 18, 13, 0, 0); // 1 hour

      var session = GameSessionModel.startNew(
        sessionId: 'invoice_sess_1',
        screenId: 'screen_3',
        screenNumber: 3,
        playerCount: 2, // 3000 IQD / hr
        startTime: start,
      );

      // Add Market items: 2 Indomie (2000 each) + 1 Pepsi (1000) = 5000 IQD
      session = session.addOrder(OrderItem.create(
        productId: 'indomie_1',
        productName: 'Indomie',
        quantity: 2,
        unitPrice: 2000.0,
      ));

      session = session.addOrder(OrderItem.create(
        productId: 'pepsi_1',
        productName: 'Pepsi',
        quantity: 1,
        unitPrice: 1000.0,
      ));

      final calc = SessionTimerService.calculateSession(session: session, atTime: finish);

      // Gaming: 1 hr * 3000 = 3000 IQD
      // Market: 5000 IQD
      // Grand Total: 8000 IQD
      expect(calc.totalGamingCost, equals(3000.0));
      expect(calc.totalMarketCost, equals(5000.0));
      expect(calc.grandTotal, equals(8000.0));
    });

    test('Applies floor rounding to nearest 250 IQD (Discount / Floor Rounding)', () {
      // 1,605 IQD -> 1,500 IQD
      expect(SessionTimerService.calculateRoundedTotal(1605.0), equals(1500.0));

      // 1,650 IQD -> 1,500 IQD (floor rounding, not ceiling)
      expect(SessionTimerService.calculateRoundedTotal(1650.0), equals(1500.0));

      // 3,800 IQD -> 3,750 IQD
      expect(SessionTimerService.calculateRoundedTotal(3800.0), equals(3750.0));

      // Exact multiples: 250, 500, 750, 1000
      expect(SessionTimerService.calculateRoundedTotal(250.0), equals(250.0));
      expect(SessionTimerService.calculateRoundedTotal(500.0), equals(500.0));
      expect(SessionTimerService.calculateRoundedTotal(750.0), equals(750.0));
      expect(SessionTimerService.calculateRoundedTotal(1000.0), equals(1000.0));

      // Session calculation with odd minutes
      // 33 minutes at 3000 IQD/hr = (33/60)*3000 = 1650 IQD -> rounded = 1500 IQD
      final start = DateTime(2026, 8, 18, 14, 0, 0);
      final finish = DateTime(2026, 8, 18, 14, 33, 0);
      final session = GameSessionModel.startNew(
        sessionId: 'round_sess_1',
        screenId: 'screen_1',
        screenNumber: 1,
        playerCount: 2,
        startTime: start,
      );

      final calc = SessionTimerService.calculateSession(session: session, atTime: finish);
      expect(calc.rawGrandTotal, equals(1650.0));
      expect(calc.grandTotal, equals(1500.0));
      expect(calc.roundingDiscount, equals(150.0));
    });
  });
}
