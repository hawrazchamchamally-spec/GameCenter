import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../data/services/firestore_service.dart';

/// Dialog to dynamically change player tier during an active session
class ChangePlayerTierDialog extends StatefulWidget {
  final GameSessionModel session;
  final ValueChanged<int> onConfirmChange;

  const ChangePlayerTierDialog({
    super.key,
    required this.session,
    required this.onConfirmChange,
  });

  @override
  State<ChangePlayerTierDialog> createState() => _ChangePlayerTierDialogState();
}

class _ChangePlayerTierDialogState extends State<ChangePlayerTierDialog> {
  late int _selectedPlayers;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _selectedPlayers = widget.session.playerCount;
  }

  @override
  Widget build(BuildContext context) {
    final currentPlayers = widget.session.playerCount;
    final currentDuration = widget.session.getElapsedDuration();
    final currentCost = widget.session.calculateRealTimeGamingCost();

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 440),
        child: StreamBuilder<PricingSettingsModel>(
          stream: _firestoreService.getPricingSettingsStream(),
          builder: (context, snapshot) {
            final pricing = snapshot.data ?? const PricingSettingsModel();

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                        child: const Icon(Icons.swap_horiz, color: AppColors.primaryLight, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تغيير عدد اللاعبين - شاشة ${widget.session.screenNumber}',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Text(
                              'حفظ الفترة السابقة وتطبيق السعر الجديد من الآن',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Current Session Snapshot Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'الفئة الحالية:',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                              ),
                              Text(
                                '$currentPlayers لاعبين (${AppFormatters.formatCurrency(widget.session.pricingRate)}/س)',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'الوقت المستغرق حتى الآن:',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                              ),
                              Text(
                                '${AppFormatters.formatDuration(currentDuration)} • ${AppFormatters.formatCurrency(currentCost)}',
                                style: const TextStyle(
                                  color: AppColors.cyanAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  const Text(
                    'اختر الفئة الجديدة للوقت المتبقي:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Tier Options
                  _buildTierOption(
                    players: 2,
                    title: '2 لاعبين (ثنائي)',
                    rate: pricing.rate2Players,
                  ),
                  const SizedBox(height: 6),

                  _buildTierOption(
                    players: 3,
                    title: '3 لاعبين (ثلاثي)',
                    rate: pricing.rate3Players,
                  ),
                  const SizedBox(height: 6),

                  _buildTierOption(
                    players: 4,
                    title: '4 لاعبين (رباعي)',
                    rate: pricing.rate4Players,
                  ),

                  const SizedBox(height: 16),

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
                          onPressed: _selectedPlayers == currentPlayers
                              ? null
                              : () {
                                  widget.onConfirmChange(_selectedPlayers);
                                  Navigator.pop(context);
                                },
                          icon: const Icon(Icons.check),
                          label: const Text('تأكيد تغيير الفئة'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryNeon,
                          ),
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

  Widget _buildTierOption({
    required int players,
    required String title,
    required double rate,
  }) {
    final isSelected = _selectedPlayers == players;
    final isCurrent = widget.session.playerCount == players;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPlayers = players;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryNeon.withAlpha(30)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryNeon : AppColors.cardBorder,
            width: isSelected ? 1.8 : 1,
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
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 4,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.warning),
                      ),
                      child: const Text(
                        'الفئة الحالية',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${AppFormatters.formatCurrency(rate)} / س',
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
