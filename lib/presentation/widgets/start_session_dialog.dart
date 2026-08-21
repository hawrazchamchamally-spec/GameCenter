import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../data/services/firestore_service.dart';

/// Dialog to select player count and start a new gaming session (Open or Budget-based)
class StartSessionDialog extends StatefulWidget {
  final int screenNumber;
  final Function(int playerCount, String? notes)? onConfirm;
  final Function(
    int playerCount,
    String? notes,
    bool isBudgetBased,
    double? targetBudget,
    int? targetDurationMinutes,
  )? onConfirmWithBudget;

  const StartSessionDialog({
    super.key,
    required this.screenNumber,
    this.onConfirm,
    this.onConfirmWithBudget,
  });

  @override
  State<StartSessionDialog> createState() => _StartSessionDialogState();
}

class _StartSessionDialogState extends State<StartSessionDialog> {
  int _selectedPlayers = 2;
  bool _isBudgetBased = false;
  final TextEditingController _budgetController = TextEditingController(text: '5000');
  final TextEditingController _notesController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  final List<double> _quickBudgetPresets = [3000, 5000, 6000, 10000, 15000];

  @override
  void dispose() {
    _budgetController.dispose();
    _notesController.dispose();
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
        padding: const EdgeInsets.all(22),
        constraints: const BoxConstraints(maxWidth: 460),
        child: StreamBuilder<PricingSettingsModel>(
          stream: _firestoreService.getPricingSettingsStream(),
          builder: (context, snapshot) {
            final pricing = snapshot.data ?? const PricingSettingsModel();
            final currentRate = pricing.getRateForPlayers(_selectedPlayers);
            final double enteredBudget = double.tryParse(_budgetController.text.replaceAll(',', '')) ?? 0.0;
            final int calculatedMinutes = currentRate > 0 ? ((enteredBudget / currentRate) * 60).round() : 0;
            final Duration calculatedDuration = Duration(minutes: calculatedMinutes);

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryNeon.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.sports_esports, color: AppColors.primaryLight, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'بدء جلسة - شاشة ${widget.screenNumber}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Text(
                              'اختر نوع الجلسة وعدد اللاعبين لحساب التعرفة',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Session Type Switcher (Open vs Budget-based)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTypeTab(
                            title: 'جلسة مفتوحة (وقت حر)',
                            icon: Icons.timer_outlined,
                            isSelected: !_isBudgetBased,
                            onTap: () => setState(() => _isBudgetBased = false),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildTypeTab(
                            title: 'محددة بمبلغ مالي',
                            icon: Icons.monetization_on_outlined,
                            isSelected: _isBudgetBased,
                            onTap: () => setState(() => _isBudgetBased = true),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Player Options
                  const Text(
                    'عدد اللاعبين والتسعيرة:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  _buildPlayerOption(
                    players: 2,
                    title: '2 لاعبين (ثنائي)',
                    rate: pricing.rate2Players,
                  ),
                  const SizedBox(height: 6),

                  _buildPlayerOption(
                    players: 3,
                    title: '3 لاعبين (ثلاثي)',
                    rate: pricing.rate3Players,
                  ),
                  const SizedBox(height: 6),

                  _buildPlayerOption(
                    players: 4,
                    title: '4 لاعبين (رباعي)',
                    rate: pricing.rate4Players,
                  ),

                  // Budget-based configuration section
                  if (_isBudgetBased) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.cyanAccent.withAlpha(15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cyanAccent.withAlpha(90)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.hourglass_top, color: AppColors.cyanAccent, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'تحديد المبلغ والمؤقت التنازلي:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.cyanAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Quick Preset Chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _quickBudgetPresets.map((amount) {
                                final isSelected = enteredBudget == amount;
                                return Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: ChoiceChip(
                                    label: Text(
                                      AppFormatters.formatCurrency(amount),
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? Colors.black : Colors.white,
                                      ),
                                    ),
                                    selected: isSelected,
                                    selectedColor: AppColors.cyanAccent,
                                    backgroundColor: AppColors.surfaceLight,
                                    onSelected: (_) {
                                      setState(() {
                                        _budgetController.text = amount.toInt().toString();
                                      });
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Custom Amount Input
                          TextField(
                            controller: _budgetController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'المبلغ المطلوب (د.ع)',
                              hintText: '5000',
                              prefixIcon: Icon(Icons.payments_outlined, color: AppColors.cyanAccent),
                              suffixText: 'د.ع',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),

                          const SizedBox(height: 12),

                          // Calculated Duration Card
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.cyanAccent.withAlpha(60)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.timer, color: AppColors.available, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'الوقت المخصص للعب:',
                                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                      ),
                                      Text(
                                        calculatedMinutes > 0
                                            ? '${AppFormatters.formatDurationArabic(calculatedDuration)} ($calculatedMinutes دقيقة)'
                                            : '0 دقيقة (أدخل مبلغ صالح)',
                                        style: const TextStyle(
                                          color: AppColors.available,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Notes input
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات (اختياري)',
                      hintText: 'اسم الزبون أو طلب خاص...',
                      prefixIcon: Icon(Icons.notes, color: AppColors.textSecondary),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Buttons
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
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final notes = _notesController.text.trim();
                            final noteVal = notes.isNotEmpty ? notes : null;

                            if (widget.onConfirmWithBudget != null) {
                              widget.onConfirmWithBudget!(
                                _selectedPlayers,
                                noteVal,
                                _isBudgetBased,
                                _isBudgetBased ? enteredBudget : null,
                                _isBudgetBased ? calculatedMinutes : null,
                              );
                            } else if (widget.onConfirm != null) {
                              widget.onConfirm!(
                                _selectedPlayers,
                                noteVal,
                              );
                            }
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('بدء الجلسة'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTypeTab({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNeon.withAlpha(40) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primaryNeon : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerOption({
    required int players,
    required String title,
    required double rate,
  }) {
    final isSelected = _selectedPlayers == players;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPlayers = players;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryNeon.withAlpha(30)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primaryNeon : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primaryNeon : AppColors.textMuted,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13.5,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${AppFormatters.formatCurrency(rate)} / ساعة',
                style: TextStyle(
                  color: isSelected ? AppColors.cyanAccent : AppColors.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
