import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/session_timer_service.dart';
import '../../core/utils/thermal_printer_service.dart';
import '../../data/models/models.dart';
import '../../providers/auth_provider.dart';

/// Checkout and Invoice Modal for closing a gaming session with custom discount support
class SessionCheckoutModal extends StatefulWidget {
  final ScreenModel screen;
  final GameSessionModel session;
  final VoidCallback? onConfirmPayment;
  final Function(double finalPaidAmount)? onConfirmPaymentWithAmount;

  const SessionCheckoutModal({
    super.key,
    required this.screen,
    required this.session,
    this.onConfirmPayment,
    this.onConfirmPaymentWithAmount,
  });

  @override
  State<SessionCheckoutModal> createState() => _SessionCheckoutModalState();
}

class _SessionCheckoutModalState extends State<SessionCheckoutModal> {
  final TextEditingController _customAmountController = TextEditingController();
  final DateTime _checkoutTime = DateTime.now();

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final calculation = SessionTimerService.calculateSession(session: widget.session, atTime: _checkoutTime);

    final customInput = _customAmountController.text.trim();
    final customVal = double.tryParse(customInput);
    final effectiveGrandTotal = (customVal != null && customVal >= 0) ? customVal : calculation.grandTotal;
    final manualDiscount = calculation.grandTotal - effectiveGrandTotal;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Invoice Header
            _buildInvoiceHeader(_checkoutTime, calculation.totalDuration),
            const SizedBox(height: 16),
            const Divider(),

            // Scrollable Invoice Body
            Expanded(
              child: ListView(
                children: [
                  const SizedBox(height: 8),

                  // 1. Time Segments Log
                  _buildSectionTitle(
                    title: 'تفاصيل فترات اللعب (التسعير الذكي)',
                    icon: Icons.timer,
                  ),
                  const SizedBox(height: 8),
                  _buildTimeSegmentsTable(calculation.segments),

                  const SizedBox(height: 16),

                  // 2. Market Orders (if any)
                  _buildSectionTitle(
                    title: 'طلبات الماركيت (${widget.session.orders.length})',
                    icon: Icons.local_mall_outlined,
                  ),
                  const SizedBox(height: 8),
                  _buildOrdersTable(widget.session.orders),

                  const SizedBox(height: 18),

                  // 3. Financial Summary Card
                  _buildGrandTotalCard(calculation, customVal, manualDiscount, effectiveGrandTotal),

                  const SizedBox(height: 16),

                  // 4. Custom Discount / Received Amount Input Field
                  _buildCustomDiscountField(calculation.grandTotal),
                ],
              ),
            ),

            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 10),

            // Thermal Receipt Printing Action
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  final staffName = authProvider.currentUser?.name ?? 'موظف الصالة';
                  final printerService = ThermalPrinterService();
                  
                  final sessionForPrint = widget.session.copyWith(
                    totalAmount: effectiveGrandTotal,
                  );

                  await printerService.printSessionReceipt(
                    session: sessionForPrint,
                    staffName: staffName,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.cyanAccent,
                        content: Text('تم إرسال الفاتورة إلى طابعة البلوتوث الحرارية بنجاح!'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.print, color: AppColors.cyanAccent, size: 20),
                label: const Text(
                  'طباعة الفاتورة حرارياً (Thermal Receipt)',
                  style: TextStyle(color: AppColors.cyanAccent, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.cyanAccent),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('رجوع'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      if (widget.onConfirmPaymentWithAmount != null) {
                        widget.onConfirmPaymentWithAmount!(effectiveGrandTotal);
                      } else if (widget.onConfirmPayment != null) {
                        widget.onConfirmPayment!();
                      }
                    },
                    icon: const Icon(Icons.check_circle, color: Colors.white),
                    label: Text(
                      'تأكيد الدفع (${AppFormatters.formatCurrency(effectiveGrandTotal)})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.available,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
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

  Widget _buildCustomDiscountField(double originalTotal) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.discount_outlined, color: AppColors.warning, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'الخصم المباشر / المبلغ المقبوض فعلياً (اختياري)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'إذا رغبت في منح خصم إضافي، اكتب المبلغ الصافي المقبوض من الزبون وسيتم اعتماده كحساب نهائي:',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _customAmountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'مثال: ${(originalTotal * 0.9 / 250).round() * 250}',
              suffixText: 'د.ع',
              suffixIcon: _customAmountController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        setState(() {
                          _customAmountController.clear();
                        });
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceHeader(DateTime endTime, Duration totalDuration) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryNeon.withAlpha(30),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryNeon.withAlpha(80)),
          ),
          child: const Icon(Icons.receipt_long, color: AppColors.primaryLight, size: 30),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'فاتورة تصفية شاشة ${widget.screen.screenNumber}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: const Text(
                      'صالة الألعاب',
                      style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'البداية: ${AppFormatters.formatTimeOnly(widget.session.startTime)} • النهاية: ${AppFormatters.formatTimeOnly(endTime)} • (${AppFormatters.formatDuration(totalDuration)})',
                style: const TextStyle(fontSize: 11.5, color: AppColors.cyanAccent),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle({required String title, required IconData icon}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primaryLight),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSegmentsTable(List<RateSegmentDetail> segments) {
    if (segments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: segments.map((seg) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: seg.index == segments.length ? Colors.transparent : AppColors.cardBorder,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceLight,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${seg.index}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${seg.playerCount} لاعبين (${AppFormatters.formatCurrency(seg.ratePerHour)}/ساعة)',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'من ${AppFormatters.formatTimeOnly(seg.startedAt)} إلى ${AppFormatters.formatTimeOnly(seg.endedAt)} (${AppFormatters.formatDurationArabic(seg.duration)})',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Text(
                  AppFormatters.formatCurrency(seg.cost),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cyanAccent,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrdersTable(List<OrderItem> orders) {
    if (orders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Center(
          child: Text(
            'لا توجد طلبات ماركت لهذه الجلسة',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: orders.map((order) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.fastfood_outlined, size: 16, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.productName,
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
                  ),
                ),
                Text(
                  '${order.quantity} × ${AppFormatters.formatCurrency(order.unitPrice)} = ',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                Text(
                  AppFormatters.formatCurrency(order.totalPrice),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGrandTotalCard(
    LiveSessionCalculation calculation,
    double? customVal,
    double manualDiscount,
    double effectiveGrandTotal,
  ) {
    final hasRoundingDiscount = calculation.roundingDiscount > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyanAccent.withAlpha(60)),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyanAccent.withAlpha(20),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('إجمالي تكلفة اللعب:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              Text(
                AppFormatters.formatCurrency(calculation.totalGamingCost),
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (calculation.totalMarketCost > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('إجمالي طلبات الماركت:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                Text(
                  AppFormatters.formatCurrency(calculation.totalMarketCost),
                  style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
          if (hasRoundingDiscount) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('المبلغ الأصلي قبل التقريب:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                Text(
                  AppFormatters.formatCurrency(calculation.rawGrandTotal),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('خصم التقريب التلقائي (لأقرب 250 د.ع):', style: TextStyle(color: AppColors.cyanAccent, fontSize: 12.5, fontWeight: FontWeight.w500)),
                Text(
                  '- ${AppFormatters.formatCurrency(calculation.roundingDiscount)}',
                  style: const TextStyle(color: AppColors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ],
          if (customVal != null && manualDiscount != 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  manualDiscount > 0 ? 'الخصم اليدوي المباشر الممنوح:' : 'المبلغ الإضافي اليدوي:',
                  style: const TextStyle(color: AppColors.warning, fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
                Text(
                  manualDiscount > 0
                      ? '- ${AppFormatters.formatCurrency(manualDiscount)}'
                      : '+ ${AppFormatters.formatCurrency(-manualDiscount)}',
                  style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ],
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'المبلغ الإجمالي الكلي المطلوب:',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                AppFormatters.formatCurrency(effectiveGrandTotal),
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
    );
  }
}
