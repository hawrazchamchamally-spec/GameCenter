import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shift_provider.dart';

/// Modal dialog for reviewing shift/work revenue and closing the current session
class CloseShiftDialog extends StatefulWidget {
  const CloseShiftDialog({super.key});

  @override
  State<CloseShiftDialog> createState() => _CloseShiftDialogState();
}

class _CloseShiftDialogState extends State<CloseShiftDialog> {
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shiftProvider = Provider.of<ShiftProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentShift = shiftProvider.currentShift;

    if (currentShift == null) {
      return AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('لا توجد جلسة نشطة حالياً'),
        content: const Text('يمكنك بدء جلسة جديدة في أي وقت لبدء احتساب الجلسات والمبيعات.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              shiftProvider.startShift(
                staffId: authProvider.currentUser?.uid ?? 'staff_1',
                staffName: authProvider.currentUser?.name ?? 'موظف الصالة',
              );
              Navigator.pop(context);
            },
            child: const Text('بدء جلسة جديدة الآن'),
          ),
        ],
      );
    }

    final duration = currentShift.duration;
    final gamingRevenue = currentShift.totalGamingRevenue;
    final marketRevenue = currentShift.totalMarketRevenue;
    final totalCash = currentShift.totalCashExpected;
    final sessionsCount = currentShift.totalSessionsCount;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.occupied.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.point_of_sale, color: AppColors.occupied, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'إغلاق الجلسة وتسليم الكاش',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'الموظف: ${currentShift.staffName} • (${AppFormatters.formatDurationArabic(duration)})',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 10),

              // Shift Timing Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('وقت بدء الجلسة:', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          Text(
                            AppFormatters.formatDateTime(currentShift.startTime),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('الجلسات المنجزة:', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        Text(
                          '$sessionsCount جلسة',
                          style: const TextStyle(color: AppColors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Cash Breakdown Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text('مبيعات ساعات اللعب (Gaming):', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ),
                        Text(
                          AppFormatters.formatCurrency(gamingRevenue),
                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text('مبيعات الماركيت النقدية:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ),
                        Text(
                          AppFormatters.formatCurrency(marketRevenue),
                          style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'المبلغ النقدي الكلي الواجب تسليمه:',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          AppFormatters.formatCurrency(totalCash),
                          style: const TextStyle(
                            color: AppColors.available,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Notes Input
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات الجلسة (اختياري)',
                  hintText: 'أي تفاصيل بخصوص مبالغ الكاش أو المصاريف النثرية...',
                  prefixIcon: Icon(Icons.note_alt_outlined, size: 20),
                ),
              ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting
                          ? null
                          : () async {
                              setState(() => _isSubmitting = true);
                              final closedShift = await shiftProvider.closeCurrentShift(
                                notes: _notesController.text.trim(),
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppColors.available,
                                    content: Text(
                                      'تم إغلاق الجلسة بنجاح وتسليم ${AppFormatters.formatCurrency(closedShift?.totalCashExpected ?? 0)}',
                                    ),
                                  ),
                                );
                              }
                            },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('تأكيد الإغلاق وتسليم الكاش'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.occupied,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
