import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../data/services/firestore_service.dart';
import 'add_order_dialog.dart';

/// Modal displaying detailed session breakdown, rate history timeline, and market orders
class SessionDetailsModal extends StatefulWidget {
  final GameSessionModel session;
  final Function(int newPlayerCount) onChangePlayers;
  final Function(OrderItem item) onAddOrder;
  final Function(List<OrderItem> items)? onAddMultipleOrders;
  final Function(String productId) onRemoveOrder;
  final VoidCallback onEndSession;

  const SessionDetailsModal({
    super.key,
    required this.session,
    required this.onChangePlayers,
    required this.onAddOrder,
    this.onAddMultipleOrders,
    required this.onRemoveOrder,
    required this.onEndSession,
  });

  @override
  State<SessionDetailsModal> createState() => _SessionDetailsModalState();
}

class _SessionDetailsModalState extends State<SessionDetailsModal> {
  Timer? _liveTicker;
  late GameSessionModel _currentSession;

  @override
  void initState() {
    super.initState();
    _currentSession = widget.session;
    if (_currentSession.isActive) {
      _liveTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _liveTicker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GameSessionModel?>(
      stream: FirestoreService().getSessionStream(widget.session.sessionId),
      initialData: _currentSession,
      builder: (context, snapshot) {
        final session = snapshot.data ?? _currentSession;
        _currentSession = session;
        final elapsed = session.getElapsedDuration();
        final gamingCost = session.calculateRealTimeGamingCost();
        final marketCost = session.calculateTotalMarketCost();
        final totalAmount = gamingCost + marketCost;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryNeon.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.tv, color: AppColors.primaryLight, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تفاصيل شاشة ${session.screenNumber}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'بدأت في: ${AppFormatters.formatTimeOnly(session.startTime)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Live Timer Pill (Elapsed or Countdown)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: session.isTimeExpired() ? AppColors.occupied.withAlpha(35) : AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: session.isTimeExpired()
                        ? AppColors.occupied
                        : (session.isBudgetBased ? AppColors.warning : AppColors.cyanAccent.withAlpha(80)),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      session.isTimeExpired()
                          ? Icons.alarm_off
                          : (session.isBudgetBased ? Icons.hourglass_bottom : Icons.timer_outlined),
                      color: session.isTimeExpired()
                          ? AppColors.occupied
                          : (session.isBudgetBased ? AppColors.warning : AppColors.cyanAccent),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      session.isBudgetBased
                          ? (session.isTimeExpired()
                              ? 'انتهى الوقت!'
                              : '⏳ ${AppFormatters.formatDuration(session.getRemainingDuration())}')
                          : AppFormatters.formatDuration(elapsed),
                      style: TextStyle(
                        color: session.isTimeExpired()
                            ? AppColors.occupied
                            : (session.isBudgetBased ? AppColors.warning : AppColors.cyanAccent),
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(),

          // Scrollable Content
          Expanded(
            child: ListView(
              children: [
                // Budget Session Info Banner if applicable
                if (session.isBudgetBased) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cyanAccent.withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cyanAccent.withAlpha(80)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.monetization_on, color: AppColors.cyanAccent, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'جلسة محددة مسبقاً (${AppFormatters.formatCurrency(session.targetBudget ?? 0)})',
                                  style: const TextStyle(
                                    color: AppColors.cyanAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${session.targetDurationMinutes ?? 0} دقيقة مخصصة',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: session.getBudgetProgressPercentage(),
                            minHeight: 5,
                            backgroundColor: AppColors.surfaceLight,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              session.isTimeExpired()
                                  ? AppColors.occupied
                                  : (session.getBudgetProgressPercentage() > 0.85
                                      ? AppColors.warning
                                      : AppColors.cyanAccent),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // 1. Player Count & Pricing Tier Quick Switcher
                _buildSectionHeader(
                  title: 'فئة وعدد اللاعبين الحاليين',
                  icon: Icons.group,
                ),
                const SizedBox(height: 8),
                _buildPlayerCountSwitcher(session),

                const SizedBox(height: 16),

                // Rate History Timeline
                _buildSectionHeader(
                  title: 'سجل التسعير والتحويلات الزمنية',
                  icon: Icons.history,
                ),
                const SizedBox(height: 8),
                _buildRateHistoryTimeline(session),

                const SizedBox(height: 20),

                // 2. Market Orders Section
                _buildSectionHeader(
                  title: 'طلبات الماركيت الملحقة (${session.orders.length})',
                  icon: Icons.local_mall_outlined,
                ),
                const SizedBox(height: 8),

                // Prominent Add Market Order Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddProductDialog(context),
                    icon: const Icon(Icons.add_shopping_cart, size: 20),
                    label: const Text(
                      'إضافة مشروبات وسناكات من الماركيت (+)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cyanAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildOrdersList(session),

                const SizedBox(height: 20),

                // 3. Final Summary Card
                _buildTotalBreakdownCard(gamingCost, marketCost, totalAmount),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Actions Bottom Bar
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إغلاق'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onEndSession();
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text('إنهاء وحساب (${AppFormatters.formatCurrency(totalAmount)})'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.occupied,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    Widget? trailing,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primaryLight, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        ?trailing,
      ],
    );
  }

  Widget _buildPlayerCountSwitcher(GameSessionModel session) {
    final currentTier = session.playerCount;
    final tiers = [
      {'count': 2, 'label': '2 لاعبين', 'rate': 3000.0},
      {'count': 3, 'label': '3 لاعبين', 'rate': 4000.0},
      {'count': 4, 'label': '4 لاعبين', 'rate': 5000.0},
    ];

    return Row(
      children: tiers.map((tier) {
        final count = tier['count'] as int;
        final label = tier['label'] as String;
        final rate = tier['rate'] as double;
        final isSelected = currentTier == count;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: isSelected
                  ? null
                  : () {
                      setState(() {
                        _currentSession = _currentSession.changePlayerCount(count);
                      });
                      widget.onChangePlayers(count);
                    },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryNeon.withAlpha(35)
                      : AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryNeon : AppColors.cardBorder,
                    width: isSelected ? 2.0 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primaryNeon.withAlpha(50),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSelected ? Icons.check_circle : Icons.sports_esports,
                          size: 15,
                          color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(rate / 1000).toStringAsFixed(0)}k/ساعة',
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? AppColors.cyanAccent : AppColors.textMuted,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRateHistoryTimeline(GameSessionModel session) {
    final historyList = session.rateHistory;
    if (historyList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'لا توجد تحويلات سابقة للفئات',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ),
      );
    }

    return Column(
      children: historyList.asMap().entries.map((entry) {
        final index = entry.key;
        final history = entry.value;
        final isCurrent = history.endedAt == null;
        final segDuration = history.getDuration();
        final segCost = history.calculateCost();

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isCurrent ? AppColors.primaryNeon.withAlpha(20) : AppColors.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isCurrent ? AppColors.primaryNeon.withAlpha(80) : AppColors.cardBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCurrent ? AppColors.primaryNeon : AppColors.surfaceLight,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isCurrent ? Colors.black : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${history.playerCount} لاعبين (${AppFormatters.formatCurrency(history.ratePerHour)}/ساعة)',
                      style: TextStyle(
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                        color: isCurrent ? Colors.white : AppColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'المدة: ${AppFormatters.formatDurationArabic(segDuration)} (${AppFormatters.formatDuration(segDuration)})',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                AppFormatters.formatCurrency(segCost),
                style: TextStyle(
                  color: isCurrent ? AppColors.cyanAccent : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOrdersList(GameSessionModel session) {
    if (session.orders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'لا توجد طلبات ماركت مضافة لهذه الجلسة بعد',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ),
      );
    }

    return Column(
      children: session.orders.map((order) {
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${order.quantity} × ${AppFormatters.formatCurrency(order.unitPrice)}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                AppFormatters.formatCurrency(order.totalPrice),
                style: const TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.occupied, size: 18),
                onPressed: () {
                  setState(() {
                    _currentSession = _currentSession.removeOrder(order.productId);
                  });
                  widget.onRemoveOrder(order.productId);
                },
                tooltip: 'حذف الطلب',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTotalBreakdownCard(double gamingCost, double marketCost, double totalAmount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyanAccent.withAlpha(50)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('إجمالي تكلفة اللعب:', style: TextStyle(color: AppColors.textSecondary)),
              Text(AppFormatters.formatCurrency(gamingCost),
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('إجمالي طلبات الماركت:', style: TextStyle(color: AppColors.textSecondary)),
              Text(AppFormatters.formatCurrency(marketCost),
                  style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'المبلغ الإجمالي النهائي:',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                AppFormatters.formatCurrency(totalAmount),
                style: const TextStyle(
                  color: AppColors.cyanAccent,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AddOrderToSessionDialog(
        screenNumber: _currentSession.screenNumber,
        onAddProduct: (product) {
          final orderItem = OrderItem.create(
            productId: product.id,
            productName: product.name,
            quantity: 1,
            unitPrice: product.sellingPrice,
          );
          setState(() {
            _currentSession = _currentSession.addOrder(orderItem);
          });
          widget.onAddOrder(orderItem);
        },
        onAddMultipleProducts: (items) {
          setState(() {
            for (final item in items) {
              _currentSession = _currentSession.addOrder(item);
            }
          });
          if (widget.onAddMultipleOrders != null) {
            widget.onAddMultipleOrders!(items);
          } else {
            for (final item in items) {
              widget.onAddOrder(item);
            }
          }
        },
      ),
    );
  }
}
