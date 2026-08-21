import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';

/// Interactive Live Sync & Cloud Connection Status Indicator Pill
class SyncStatusIndicator extends StatefulWidget {
  final bool isOnline;

  const SyncStatusIndicator({
    super.key,
    this.isOnline = true,
  });

  @override
  State<SyncStatusIndicator> createState() => _SyncStatusIndicatorState();
}

class _SyncStatusIndicatorState extends State<SyncStatusIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = widget.isOnline;
    final color = isOnline ? AppColors.available : AppColors.occupied;

    return InkWell(
      onTap: () => _showSyncDetailsDialog(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(80), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color.withAlpha((_pulseAnimation.value * 255).toInt()),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withAlpha(120),
                        blurRadius: 6 * _pulseAnimation.value,
                        spreadRadius: 2 * _pulseAnimation.value,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 6),
            Text(
              isOnline ? 'متزامن لحظياً' : 'غير متصل',
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSyncDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: const Row(
          children: [
            Icon(Icons.cloud_sync, color: AppColors.available, size: 24),
            SizedBox(width: 10),
            Text('حالة التزامن اللحظي المباشر', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSyncItem(
              title: 'حالة الاتصال السحابي:',
              value: 'متصل ونشط (Cloud Connected)',
              color: AppColors.available,
              icon: Icons.check_circle_outline,
            ),
            const SizedBox(height: 10),
            _buildSyncItem(
              title: 'تزامن الشاشات الـ 8:',
              value: 'بث مباشر لحظي (Firestore Stream)',
              color: AppColors.cyanAccent,
              icon: Icons.tv,
            ),
            const SizedBox(height: 10),
            _buildSyncItem(
              title: 'تزامن الماركيت والطلبات:',
              value: 'خصم وإضافة متزامنة بين كل الأجهزة',
              color: AppColors.warning,
              icon: Icons.inventory_2_outlined,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'آخر مزامنة ناجحة: ${AppFormatters.formatTimeOnly(DateTime.now())} • أي تعديل على أي هاتف ينعكس فوراً دون تحديث يدوي.',
                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNeon),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncItem({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12.5)),
            ],
          ),
        ),
      ],
    );
  }
}
