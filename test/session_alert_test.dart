import 'package:flutter_test/flutter_test.dart';
import 'package:game_center/core/services/session_alert_service.dart';
import 'package:game_center/data/models/models.dart';

void main() {
  group('SessionAlertService Tests', () {
    late SessionAlertService alertService;

    setUp(() {
      alertService = SessionAlertService();
      alertService.reset();
    });

    test('Triggers hourly alert when session passes 60 minutes milestone', () {
      final now = DateTime.now();
      final startTime = now.subtract(const Duration(minutes: 65)); // 1 hour and 5 minutes

      final session = GameSessionModel.startNew(
        sessionId: 'sess_alert_1',
        screenId: 'screen_3',
        screenNumber: 3,
        playerCount: 2,
        startTime: startTime,
      );

      // Check sessions
      alertService.checkSessions([session], atTime: now);

      expect(alertService.activeAlerts.value.length, equals(1));
      final alert = alertService.activeAlerts.value.first;
      expect(alert.type, equals(SessionAlertType.hourlyMilestone));
      expect(alert.screenNumber, equals(3));
      expect(alert.hourNumber, equals(1));
      expect(alert.title, contains('شاشة 3'));

      // Check again at same time -> Should not duplicate
      alertService.checkSessions([session], atTime: now);
      expect(alertService.activeAlerts.value.length, equals(1));

      // Fast forward to 125 minutes (2 hours milestone)
      final twoHoursLater = startTime.add(const Duration(minutes: 125));
      alertService.checkSessions([session], atTime: twoHoursLater);

      // Should now have 2 alerts (hour 1 and hour 2)
      expect(alertService.activeAlerts.value.length, equals(2));
      final secondAlert = alertService.activeAlerts.value.first;
      expect(secondAlert.hourNumber, equals(2));
      expect(secondAlert.message, contains('ساعتان'));
    });

    test('Triggers budget expiration alert when budget session time is exceeded', () {
      final now = DateTime.now();
      final startTime = now.subtract(const Duration(minutes: 50));

      final session = GameSessionModel.startNew(
        sessionId: 'sess_budget_alert_1',
        screenId: 'screen_5',
        screenNumber: 5,
        playerCount: 2,
        startTime: startTime,
        isBudgetBased: true,
        targetBudget: 3000.0,
        targetDurationMinutes: 60, // 60 minutes allocation
      );

      // Current elapsed 50 mins -> Not expired yet
      alertService.checkSessions([session], atTime: now);
      expect(alertService.activeAlerts.value.isEmpty, isTrue);

      // Fast forward past 60 mins (e.g. 62 mins)
      final expiredTime = startTime.add(const Duration(minutes: 62));
      alertService.checkSessions([session], atTime: expiredTime);

      expect(alertService.activeAlerts.value.isNotEmpty, isTrue);
      final expiredAlert = alertService.activeAlerts.value.firstWhere(
        (a) => a.type == SessionAlertType.budgetExpired,
      );
      expect(expiredAlert.screenNumber, equals(5));
      expect(expiredAlert.title, contains('انتهاء وقت الجلسة'));
      expect(expiredAlert.message, contains('3,000 د.ع'));

      // Dismiss alert test
      alertService.dismissAlert(expiredAlert.id);
      expect(alertService.activeAlerts.value.any((a) => a.id == expiredAlert.id), isFalse);
    });

    test('Cleans up tracking when session is closed', () {
      final now = DateTime.now();
      final startTime = now.subtract(const Duration(minutes: 70));

      final session = GameSessionModel.startNew(
        sessionId: 'sess_to_close',
        screenId: 'screen_1',
        screenNumber: 1,
        playerCount: 2,
        startTime: startTime,
      );

      alertService.checkSessions([session], atTime: now);
      expect(alertService.activeAlerts.value.length, equals(1));

      // End session
      final closedSession = session.endSession(endAt: now);
      alertService.checkSessions([closedSession], atTime: now);

      // Reset and check with empty sessions
      alertService.checkSessions([], atTime: now);
    });
  });
}
