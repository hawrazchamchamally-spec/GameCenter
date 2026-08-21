import 'package:flutter/material.dart';
import '../../core/services/session_alert_service.dart';
import '../../core/theme/app_colors.dart';

/// In-App Alert Banner Widget for real-time notifications (Hourly milestones & Budget expiration)
class InAppAlertBanner extends StatelessWidget {
  final VoidCallback? onAlertTap;

  const InAppAlertBanner({
    super.key,
    this.onAlertTap,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<SessionAlert>>(
      valueListenable: SessionAlertService().activeAlerts,
      builder: (context, alerts, _) {
        if (alerts.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: alerts.map((alert) => _buildAlertItem(context, alert)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildAlertItem(BuildContext context, SessionAlert alert) {
    final isBudgetExpired = alert.type == SessionAlertType.budgetExpired;

    final primaryColor = isBudgetExpired ? AppColors.occupied : AppColors.cyanAccent;
    final bgGradient = isBudgetExpired
        ? const LinearGradient(
            colors: [Color(0xFF7F1D1D), Color(0xFF1E1B2E)],
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
          )
        : const LinearGradient(
            colors: [Color(0xFF0C4A6E), Color(0xFF111827)],
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
          );

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        gradient: bgGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryColor.withAlpha(120), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withAlpha(40),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            onAlertTap?.call();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withAlpha(35),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isBudgetExpired ? Icons.alarm_off : Icons.access_time_filled,
                    color: primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        alert.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Dismiss Button
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                  tooltip: 'إغلاق التنبيه',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    SessionAlertService().dismissAlert(alert.id);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
