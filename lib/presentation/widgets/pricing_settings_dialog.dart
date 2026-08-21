import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../data/services/firestore_service.dart';

/// Modal dialog for Admins to customize hourly gaming rates for each player tier
class PricingSettingsDialog extends StatefulWidget {
  const PricingSettingsDialog({super.key});

  @override
  State<PricingSettingsDialog> createState() => _PricingSettingsDialogState();
}

class _PricingSettingsDialogState extends State<PricingSettingsDialog> {
  final FirestoreService _firestoreService = FirestoreService();

  final TextEditingController _rate2Controller = TextEditingController();
  final TextEditingController _rate3Controller = TextEditingController();
  final TextEditingController _rate4Controller = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPricingSettings();
  }

  Future<void> _loadPricingSettings() async {
    try {
      final settings = await _firestoreService.getPricingSettings();
      _rate2Controller.text = settings.rate2Players.round().toString();
      _rate3Controller.text = settings.rate3Players.round().toString();
      _rate4Controller.text = settings.rate4Players.round().toString();
    } catch (_) {
      _rate2Controller.text = '3000';
      _rate3Controller.text = '4000';
      _rate4Controller.text = '5000';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _savePricingSettings() async {
    final rate2 = double.tryParse(_rate2Controller.text.trim()) ?? 3000.0;
    final rate3 = double.tryParse(_rate3Controller.text.trim()) ?? 4000.0;
    final rate4 = double.tryParse(_rate4Controller.text.trim()) ?? 5000.0;

    setState(() => _isSaving = true);
    try {
      final settings = PricingSettingsModel(
        rate2Players: rate2,
        rate3Players: rate3,
        rate4Players: rate4,
      );

      await _firestoreService.savePricingSettings(settings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.available,
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('تم حفظ وتحديث أسعار ساعات اللعب في السحابة بنجاح!'),
              ],
            ),
          ),
        );
        Navigator.pop(context, settings);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.occupied,
            content: Text('خطأ أثناء حفظ الأسعار: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _rate2Controller.dispose();
    _rate3Controller.dispose();
    _rate4Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryNeon.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.price_change_outlined, color: AppColors.primaryLight, size: 26),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تعديل أسعار ساعات اللعب (Rates)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'تحديد سعر الساعة حسب عدد اللاعبين (2، 3، 4 لاعبين)',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryNeon.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primaryNeon.withAlpha(60)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, color: AppColors.primaryLight, size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'الأسعار المدخلة هنا ستعتمد تلقائياً للجلسات الجديدة وتغيير الفئات في الصالة.',
                                  style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Tier 2: 2 Players
                        _buildTierInputCard(
                          title: 'سعر ساعة اللعب (2 لاعبين)',
                          subtitle: 'الفئة الأساسية (لاعب أو لاعبين)',
                          icon: Icons.people_outline,
                          iconColor: AppColors.cyanAccent,
                          controller: _rate2Controller,
                          defaultRate: 3000,
                        ),

                        const SizedBox(height: 14),

                        // Tier 3: 3 Players
                        _buildTierInputCard(
                          title: 'سعر ساعة اللعب (3 لاعبين)',
                          subtitle: 'فئة اللعب الثلاثي',
                          icon: Icons.groups_outlined,
                          iconColor: AppColors.warning,
                          controller: _rate3Controller,
                          defaultRate: 4000,
                        ),

                        const SizedBox(height: 14),

                        // Tier 4: 4 Players
                        _buildTierInputCard(
                          title: 'سعر ساعة اللعب (4 لاعبين فما فوق)',
                          subtitle: 'فئة اللعب الرباعي والمجموعات',
                          icon: Icons.group_work_outlined,
                          iconColor: AppColors.primaryNeon,
                          controller: _rate4Controller,
                          defaultRate: 5000,
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 14),
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
                    onPressed: _isSaving ? null : _savePricingSettings,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Icon(Icons.check_circle),
                    label: const Text('حفظ واعتماد الأسعار'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierInputCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required TextEditingController controller,
    required double defaultRate,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'الافتراضي: ${AppFormatters.formatCurrency(defaultRate)}',
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            decoration: const InputDecoration(
              hintText: 'أدخل سعر الساعة...',
              suffixText: 'د.ع / ساعة',
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}
