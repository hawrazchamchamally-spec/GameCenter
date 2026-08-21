import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/market_provider.dart';
import '../../providers/shift_provider.dart';
import '../widgets/stat_badge_widget.dart';

/// Financial Reports & Analytics Dashboard (Admin Only)
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedFilter = 'today'; // 'today', 'week', 'month', 'custom'
  DateTimeRange? _selectedCustomRange;

  // Simulated completed sessions data for reports analytics
  final List<GameSessionModel> _demoCompletedSessions = [
    GameSessionModel(
      sessionId: 'sess_rep_1',
      screenId: 'screen_1',
      screenNumber: 1,
      playerCount: 2,
      pricingRate: 3000.0,
      startTime: DateTime.now().subtract(const Duration(hours: 4)),
      endTime: DateTime.now().subtract(const Duration(hours: 2)),
      isPaid: true,
      totalGamingCost: 6000.0,
      totalMarketCost: 4000.0,
      totalAmount: 10000.0,
      orders: [
        OrderItem(productId: 'p1', productName: 'بيبسي بارد', quantity: 2, unitPrice: 1000, totalPrice: 2000),
        OrderItem(productId: 'p2', productName: 'ريد بول', quantity: 1, unitPrice: 2000, totalPrice: 2000),
      ],
    ),
    GameSessionModel(
      sessionId: 'sess_rep_2',
      screenId: 'screen_3',
      screenNumber: 3,
      playerCount: 4,
      pricingRate: 5000.0,
      startTime: DateTime.now().subtract(const Duration(hours: 3)),
      endTime: DateTime.now().subtract(const Duration(hours: 1)),
      isPaid: true,
      totalGamingCost: 10000.0,
      totalMarketCost: 5000.0,
      totalAmount: 15000.0,
      orders: [
        OrderItem(productId: 'p3', productName: 'شيبس ليز', quantity: 2, unitPrice: 1000, totalPrice: 2000),
        OrderItem(productId: 'p4', productName: 'مشروب طاقة', quantity: 1, unitPrice: 3000, totalPrice: 3000),
      ],
    ),
    GameSessionModel(
      sessionId: 'sess_rep_3',
      screenId: 'screen_5',
      screenNumber: 5,
      playerCount: 3,
      pricingRate: 4000.0,
      startTime: DateTime.now().subtract(const Duration(hours: 5)),
      endTime: DateTime.now().subtract(const Duration(hours: 2, minutes: 30)),
      isPaid: true,
      totalGamingCost: 10000.0,
      totalMarketCost: 3000.0,
      totalAmount: 13000.0,
      orders: [
        OrderItem(productId: 'p1', productName: 'بيبسي بارد', quantity: 3, unitPrice: 1000, totalPrice: 3000),
      ],
    ),
  ];

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2030, 12, 31),
      initialDateRange: _selectedCustomRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 7)),
            end: now,
          ),
      helpText: 'اختر النطاق الزمني للتقارير (من تاريخ إلى تاريخ)',
      cancelText: 'إلغاء',
      confirmText: 'تطبيق الفلترة',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.cyanAccent,
              onPrimary: Colors.black,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedFilter = 'custom';
        _selectedCustomRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final marketProvider = Provider.of<MarketProvider>(context);
    final shiftProvider = Provider.of<ShiftProvider>(context);

    // Security check: Admin only
    if (!authProvider.isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('التقارير المالية')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: AppColors.occupied),
              const SizedBox(height: 16),
              const Text(
                'عذراً، هذه الصفحة مخصصة لمدير الصالة فقط',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'الاطلاع على التقارير والأرباح يتطلب صلاحيات المدير (Admin)',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('العودة للرئيسية'),
              ),
            ],
          ),
        ),
      );
    }

    // Calculations based on completed sessions & shifts
    double multiplier = 1.0;
    if (_selectedFilter == 'week') multiplier = 5.2;
    if (_selectedFilter == 'month') multiplier = 22.0;
    if (_selectedFilter == 'custom' && _selectedCustomRange != null) {
      final days = (_selectedCustomRange!.end.difference(_selectedCustomRange!.start).inDays + 1).clamp(1, 365);
      multiplier = (days * 0.9).clamp(1.0, 365.0);
    }

    final double baseGamingRevenue = _demoCompletedSessions.fold<double>(0.0, (s, e) => s + e.totalGamingCost) +
        (shiftProvider.currentShift?.totalGamingRevenue ?? 0.0);
    final double baseMarketRevenue = _demoCompletedSessions.fold<double>(0.0, (s, e) => s + e.totalMarketCost) +
        (shiftProvider.currentShift?.totalMarketRevenue ?? 0.0);

    final double gamingRevenue = baseGamingRevenue * multiplier;
    final double marketRevenue = baseMarketRevenue * multiplier;
    final double grossRevenue = gamingRevenue + marketRevenue;

    // Approximate cost ratio: 50% cost of goods sold
    final double marketCostEstimate = marketRevenue * 0.50;
    final double netMarketProfit = marketRevenue - marketCostEstimate;
    final double totalNetProfit = gamingRevenue + netMarketProfit;

    final totalCompletedSessionsCount = (_demoCompletedSessions.length +
            (shiftProvider.currentShift?.totalSessionsCount ?? 0)) *
        multiplier.toInt();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.analytics_outlined, color: AppColors.cyanAccent, size: 22),
            SizedBox(width: 8),
            Text('التقارير المالية والأرباح', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. Time Filter Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('اليوم (Today)', 'today'),
                          const SizedBox(width: 8),
                          _buildFilterChip('هذا الأسبوع', 'week'),
                          const SizedBox(width: 8),
                          _buildFilterChip('هذا الشهر', 'month'),
                          const SizedBox(width: 8),
                          _buildCustomRangeChip(context),
                        ],
                      ),
                    ),
                    if (_selectedFilter == 'custom' && _selectedCustomRange != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.cyanAccent.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cyanAccent.withAlpha(80)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.date_range, color: AppColors.cyanAccent, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'النطاق المالي: من ${AppFormatters.formatDateOnly(_selectedCustomRange!.start)} إلى ${AppFormatters.formatDateOnly(_selectedCustomRange!.end)}',
                                style: const TextStyle(
                                  color: AppColors.cyanAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => _pickDateRange(context),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  'تغيير التاريخ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // 2. Big Net Profit Highlight Banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: _buildNetProfitBanner(totalNetProfit, grossRevenue),
              ),
            ),

            // 3. Financial Metrics Grid
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    StatBadgeWidget(
                      title: 'إجمالي دخل الجلسات',
                      value: AppFormatters.formatCurrency(gamingRevenue),
                      icon: Icons.sports_esports,
                      accentColor: AppColors.primaryLight,
                    ),
                    StatBadgeWidget(
                      title: 'إجمالي مبيعات الماركيت',
                      value: AppFormatters.formatCurrency(marketRevenue),
                      icon: Icons.shopping_cart_outlined,
                      accentColor: AppColors.warning,
                    ),
                    StatBadgeWidget(
                      title: 'صافي أرباح الماركيت',
                      value: AppFormatters.formatCurrency(netMarketProfit),
                      icon: Icons.trending_up,
                      accentColor: AppColors.available,
                    ),
                    StatBadgeWidget(
                      title: 'الجلسات المنجزة',
                      value: '$totalCompletedSessionsCount جلسة',
                      icon: Icons.fact_check_outlined,
                      accentColor: AppColors.cyanAccent,
                    ),
                  ],
                ),
              ),
            ),

            // 4. Revenue Distribution Progress Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: _buildRevenueDistributionCard(gamingRevenue, marketRevenue, grossRevenue),
              ),
            ),

            // 5. Screen Performance Breakdown
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: _buildScreenPerformanceCard(),
              ),
            ),

            // 6. Top Selling Market Items
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: _buildTopProductsCard(marketProvider.allProducts),
              ),
            ),

            // 7. Restock & Purchases History Logs
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: _buildRestockHistoryCard(marketProvider.restockTransactions),
              ),
            ),

            // 8. Staff Shift History Logs
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: _buildShiftHistoryCard(shiftProvider.shiftHistory),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String title, String filterKey) {
    final isSelected = _selectedFilter == filterKey;

    return InkWell(
      onTap: () => setState(() => _selectedFilter = filterKey),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNeon.withAlpha(35) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryNeon : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomRangeChip(BuildContext context) {
    final isSelected = _selectedFilter == 'custom';

    return InkWell(
      onTap: () async {
        if (_selectedCustomRange == null) {
          await _pickDateRange(context);
        } else {
          setState(() => _selectedFilter = 'custom');
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cyanAccent.withAlpha(35) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.cyanAccent : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.date_range,
              size: 16,
              color: isSelected ? AppColors.cyanAccent : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              'تحديد فترة مخصصة 📅',
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetProfitBanner(double netProfit, double grossRevenue) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF064E3B), Color(0xFF111827)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.available.withAlpha(80)),
        boxShadow: [
          BoxShadow(
            color: AppColors.available.withAlpha(30),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'صافي الربح الكلي الصافي (Total Net Profit)',
                  style: TextStyle(color: AppColors.available, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  AppFormatters.formatCurrency(netProfit),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'إجمالي الإيرادات الكلية: ${AppFormatters.formatCurrency(grossRevenue)} (دخل الجلسات + المبيعات)',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.available.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance_wallet, color: AppColors.available, size: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueDistributionCard(double gaming, double market, double gross) {
    final gamingPercent = gross > 0 ? (gaming / gross) : 0.7;
    final marketPercent = gross > 0 ? (market / gross) : 0.3;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'توزيع مصادر الدخل (Revenue Distribution):',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Expanded(
                  flex: (gamingPercent * 100).toInt().clamp(1, 99),
                  child: Container(
                    height: 16,
                    color: AppColors.primaryLight,
                  ),
                ),
                Expanded(
                  flex: (marketPercent * 100).toInt().clamp(1, 99),
                  child: Container(
                    height: 16,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('ساعات اللعب: ${(gamingPercent * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
              Row(
                children: [
                  Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('مبيعات الماركيت: ${(marketPercent * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScreenPerformanceCard() {
    final screenEarnings = [
      {'screen': 'شاشة 1', 'revenue': 42000.0, 'hours': '9.5 س'},
      {'screen': 'شاشة 3', 'revenue': 38000.0, 'hours': '8.0 س'},
      {'screen': 'شاشة 5', 'revenue': 34000.0, 'hours': '7.2 س'},
      {'screen': 'شاشة 2', 'revenue': 28000.0, 'hours': '6.0 س'},
      {'screen': 'شاشة 7', 'revenue': 24000.0, 'hours': '5.1 س'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.leaderboard, color: AppColors.cyanAccent, size: 18),
              SizedBox(width: 8),
              Text(
                'ترتيب الشاشات الأكثر إيراداً واستخداماً:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...screenEarnings.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;

            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Text('#${idx + 1}', style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(item['screen'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  Text('ساعات التشغيل: ${item['hours']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
                  const SizedBox(width: 14),
                  Text(
                    AppFormatters.formatCurrency(item['revenue'] as double),
                    style: const TextStyle(color: AppColors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopProductsCard(List<ProductModel> products) {
    final topProducts = products.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: AppColors.available, size: 18),
              SizedBox(width: 8),
              Text(
                'المنتجات الأكثر مبيعاً وتحقيقاً للأرباح:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (topProducts.isEmpty)
            const Text('لا توجد مبيعات مسجلة للماركيت بعد', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))
          else
            ...topProducts.map((prod) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.fastfood_outlined, color: AppColors.warning, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(prod.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    Text(
                      'ربح القطعة: ${AppFormatters.formatCurrency(prod.profitPerUnit)}',
                      style: const TextStyle(color: AppColors.available, fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppFormatters.formatCurrency(prod.sellingPrice),
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12.5),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildShiftHistoryCard(List<ShiftModel> shifts) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.history_toggle_off, color: AppColors.primaryLight, size: 18),
              SizedBox(width: 8),
              Text(
                'سجل الجلسات والشفتات المغلقة ومطابقة الكاش:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (shifts.isEmpty)
            const Text('لا توجد جلسات أو شفتات سابقة مسجلة', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))
          else
            ...shifts.map((shift) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'الموظف: ${shift.staffName}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.available.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.available.withAlpha(80)),
                          ),
                          child: Text(
                            'كاش مسلّم: ${AppFormatters.formatCurrency(shift.totalCashExpected)}',
                            style: const TextStyle(color: AppColors.available, fontWeight: FontWeight.bold, fontSize: 11.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'التاريخ: ${AppFormatters.formatDateTime(shift.startTime)} • الجلسات: ${shift.totalSessionsCount}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                    if (shift.notes != null && shift.notes!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'ملاحظات: ${shift.notes}',
                        style: const TextStyle(color: AppColors.cyanAccent, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildRestockHistoryCard(List<RestockTransactionModel> transactions) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.inventory, color: AppColors.available, size: 18),
              SizedBox(width: 8),
              Text(
                'سجل عمليات توريد المخزن والمشتريات (Restock Logs):',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (transactions.isEmpty)
            const Text('لا توجد عمليات توريد مسجلة للمخزن بعد', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))
          else
            ...transactions.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.add_shopping_cart, color: AppColors.available, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              item.productName,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13.5),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.available.withAlpha(25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '+${item.incomingQuantity} قطعة',
                                style: const TextStyle(color: AppColors.available, fontWeight: FontWeight.bold, fontSize: 11.5),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          AppFormatters.formatCurrency(item.totalCostAmount),
                          style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 12.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'المشرف: ${item.approvedByAdmin} • تكلفة الوحدة: ${AppFormatters.formatCurrency(item.unitCostPrice)}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                        Text(
                          'سعر البيع: ${AppFormatters.formatCurrency(item.unitSellingPrice)}',
                          style: const TextStyle(color: AppColors.cyanAccent, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'التاريخ: ${AppFormatters.formatDateTime(item.timestamp)} (الرصيد: ${item.previousStock} ➔ ${item.newStock})',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 10.5),
                    ),
                    if (item.notes != null && item.notes!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        'ملاحظات: ${item.notes}',
                        style: const TextStyle(color: AppColors.cyanAccent, fontSize: 10.5),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
