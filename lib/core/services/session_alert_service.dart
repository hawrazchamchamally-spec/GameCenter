import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/models.dart';
import '../utils/formatters.dart';

/// Types of in-app session alerts
enum SessionAlertType {
  hourlyMilestone,
  budgetExpired,
}

/// An in-app alert notification model
class SessionAlert {
  final String id;
  final String sessionId;
  final int screenNumber;
  final SessionAlertType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final int? hourNumber;
  final double? budget;

  const SessionAlert({
    required this.id,
    required this.sessionId,
    required this.screenNumber,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.hourNumber,
    this.budget,
  });
}

/// Service managing real-time hourly notifications and budget countdown alerts
class SessionAlertService {
  static final SessionAlertService _instance = SessionAlertService._internal();
  factory SessionAlertService() => _instance;
  SessionAlertService._internal();

  /// Map of sessionId -> Set of hour numbers already triggered (e.g. {1, 2})
  final Map<String, Set<int>> _triggeredHourlyAlerts = {};

  /// Set of sessionIds whose budget expiry has already been triggered
  final Set<String> _triggeredBudgetExpiredAlerts = {};

  /// Active visible alerts in the application
  final ValueNotifier<List<SessionAlert>> activeAlerts = ValueNotifier<List<SessionAlert>>([]);

  /// Broadcast stream for real-time sound/toast integrations
  final StreamController<SessionAlert> _alertStreamController = StreamController<SessionAlert>.broadcast();
  Stream<SessionAlert> get onNewAlert => _alertStreamController.stream;

  /// Checks active sessions for hourly milestones and budget expiration
  void checkSessions(List<GameSessionModel> sessions, {DateTime? atTime}) {
    final now = atTime ?? DateTime.now();
    final activeSessionIds = <String>{};

    for (final session in sessions) {
      if (!session.isActive) continue;
      activeSessionIds.add(session.sessionId);

      // 1. Check Hourly Milestones (60 min, 120 min, 180 min, ...)
      _checkHourlyMilestone(session, now);

      // 2. Check Budget / Prepaid Expiration
      _checkBudgetExpiration(session, now);
    }

    // Clean up closed sessions from memory tracking sets
    _triggeredHourlyAlerts.removeWhere((id, _) => !activeSessionIds.contains(id));
    _triggeredBudgetExpiredAlerts.removeWhere((id) => !activeSessionIds.contains(id));
  }

  void _checkHourlyMilestone(GameSessionModel session, DateTime now) {
    final elapsedMinutes = session.getElapsedDuration(atTime: now).inMinutes;
    final currentHour = elapsedMinutes ~/ 60;

    if (currentHour < 1) return;

    final triggered = _triggeredHourlyAlerts.putIfAbsent(session.sessionId, () => <int>{});

    for (int h = 1; h <= currentHour; h++) {
      if (!triggered.contains(h)) {
        triggered.add(h);

        String hourLabel;
        if (h == 1) {
          hourLabel = 'ساعة واحدة';
        } else if (h == 2) {
          hourLabel = 'ساعتان';
        } else if (h >= 3 && h <= 10) {
          hourLabel = '$h ساعات';
        } else {
          hourLabel = '$h ساعة';
        }

        final alert = SessionAlert(
          id: '${session.sessionId}_hour_$h',
          sessionId: session.sessionId,
          screenNumber: session.screenNumber,
          type: SessionAlertType.hourlyMilestone,
          title: '⏰ تنبيه رأس الساعة - شاشة ${session.screenNumber}',
          message: 'أكملت شاشة ${session.screenNumber} ($hourLabel) من وقت اللعب المستمر.',
          timestamp: now,
          hourNumber: h,
        );

        _addAlert(alert);
      }
    }
  }

  void _checkBudgetExpiration(GameSessionModel session, DateTime now) {
    if (!session.isBudgetBased || session.allocatedEndTime == null) return;

    if (now.isAfter(session.allocatedEndTime!)) {
      if (!_triggeredBudgetExpiredAlerts.contains(session.sessionId)) {
        _triggeredBudgetExpiredAlerts.add(session.sessionId);

        final budgetText = session.targetBudget != null
            ? AppFormatters.formatCurrency(session.targetBudget!)
            : '';

        final alert = SessionAlert(
          id: '${session.sessionId}_budget_expired',
          sessionId: session.sessionId,
          screenNumber: session.screenNumber,
          type: SessionAlertType.budgetExpired,
          title: '🚨 انتهاء وقت الجلسة - شاشة ${session.screenNumber}',
          message: 'انتهت مدة اللعب المحددة للمبلغ ($budgetText)! يرجى إبلاغ اللاعبين أو تمديد الجلسة.',
          timestamp: now,
          budget: session.targetBudget,
        );

        _addAlert(alert);
      }
    }
  }

  void _addAlert(SessionAlert alert) {
    final current = List<SessionAlert>.from(activeAlerts.value);
    // Add to beginning of list (newest first), limit to 5 active alerts
    current.insert(0, alert);
    if (current.length > 5) {
      current.removeLast();
    }
    activeAlerts.value = current;
    _alertStreamController.add(alert);
  }

  /// Dismiss an alert by ID
  void dismissAlert(String alertId) {
    final current = List<SessionAlert>.from(activeAlerts.value);
    current.removeWhere((a) => a.id == alertId);
    activeAlerts.value = current;
  }

  /// Clear all active alerts
  void clearAllAlerts() {
    activeAlerts.value = [];
  }

  /// Reset all internal tracking (useful for tests)
  void reset() {
    _triggeredHourlyAlerts.clear();
    _triggeredBudgetExpiredAlerts.clear();
    activeAlerts.value = [];
  }
}
