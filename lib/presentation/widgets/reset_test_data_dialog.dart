import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/screen_provider.dart';
import '../../providers/shift_provider.dart';

/// Secure Confirmation Dialog to Purge Test Records and Reset Balances to Zero (Admin Only)
class ResetTestDataDialog extends StatefulWidget {
  const ResetTestDataDialog({super.key});

  @override
  State<ResetTestDataDialog> createState() => _ResetTestDataDialogState();
}

class _ResetTestDataDialogState extends State<ResetTestDataDialog> {
  final TextEditingController _confirmController = TextEditingController();
  bool _isProcessing = false;
  String? _errorMessage;

  bool get _isConfirmed {
    final text = _confirmController.text.trim().toUpperCase();
    return text == 'CONFIRM' || text == 'تأكيد';
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleResetData() async {
    if (!_isConfirmed || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final firestoreService = FirestoreService();
      final screenProvider = Provider.of<ScreenProvider>(context, listen: false);
      final shiftProvider = Provider.of<ShiftProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // 1. Purge data from Firestore
      await firestoreService.clearAllTestData();

      // 2. Reset in-memory provider states
      screenProvider.resetAllScreensState();
      shiftProvider.resetShiftToZero(
        staffName: authProvider.currentUser?.name ?? 'المدير',
        staffId: authProvider.currentUser?.uid ?? 'admin_1',
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.available,
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'تم تصفير كافة السجلات والبيانات المالية بنجاح وتجهيز النظام للافتتاح الرسمي! 🎉',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'حدث خطأ أثناء التصفير: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: AppColors.occupied.withAlpha(160), width: 1.5),
      ),
      elevation: 20,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Warning Header
                Center(
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.occupied.withAlpha(30),
                      border: Border.all(color: AppColors.occupied.withAlpha(150), width: 2),
                    ),
                    child: const Icon(
                      Icons.delete_forever_rounded,
                      color: AppColors.occupied,
                      size: 38,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                const Text(
                  'تصفير السجلات والبيانات المالية',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.occupied,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'تجهيز الصالة للافتتاح الرسمي والتشغيل الفعلي',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 18),

                // What will be wiped
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.occupied.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.occupied.withAlpha(60)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: AppColors.occupied, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'ما سيتم مسحه وتصفيره فوراً:',
                            style: TextStyle(
                              color: AppColors.occupied,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _buildBulletItem('كافة الجلسات المسجلة (المفتوحة والمنتهية).', isDestructive: true),
                      _buildBulletItem('سجلات الدخل، الأرباح، والتقارير المالية.', isDestructive: true),
                      _buildBulletItem('سجل توريد وحركات المخزن التاريخية.', isDestructive: true),
                      _buildBulletItem('تصفير كاش الشفت وإعادة جميع الشاشات إلى حالة شاغرة.', isDestructive: true),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // What will be preserved
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.available.withAlpha(12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.available.withAlpha(50)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.shield_outlined, color: AppColors.available, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'ما سيتم الحفاظ عليه (لن يُحذف):',
                            style: TextStyle(
                              color: AppColors.available,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _buildBulletItem('الشاشات المضافة وأنواع الأجهزة.', isDestructive: false),
                      _buildBulletItem('حسابات الموظفين وكلمات المرور/PIN.', isDestructive: false),
                      _buildBulletItem('أصناف الماركيت وأسعارها والمخزون الحالي.', isDestructive: false),
                      _buildBulletItem('إعدادات الطابعة وتسعيرة ساعات اللعب.', isDestructive: false),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Error Message if any
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.occupied.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.occupied, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Confirmation Input
                const Text(
                  'للتأكيد، يرجى كتابة كلمة "CONFIRM" أو "تأكيد":',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _confirmController,
                  enabled: !_isProcessing,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 1.5,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'اكتب CONFIRM هنا...',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    filled: true,
                    fillColor: AppColors.cardBg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.occupied, width: 2),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 20),

                // Buttons
                ElevatedButton.icon(
                  onPressed: _isConfirmed && !_isProcessing ? _handleResetData : null,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.delete_forever_rounded, size: 20),
                  label: Text(
                    _isProcessing ? 'جاري تصفير البيانات...' : 'تصفير السجلات وتجهيز الصالة للافتتاح',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.occupied,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.surfaceLight,
                    disabledForegroundColor: AppColors.textMuted,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                  ),
                ),
                const SizedBox(height: 8),

                TextButton(
                  onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('إلغاء والعودة', style: TextStyle(fontSize: 12.5)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBulletItem(String text, {required bool isDestructive}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isDestructive ? '• ' : '✓ ',
            style: TextStyle(
              color: isDestructive ? AppColors.occupied : AppColors.available,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
