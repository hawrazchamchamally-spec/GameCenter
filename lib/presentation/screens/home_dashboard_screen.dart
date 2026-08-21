import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/session_alert_service.dart';
import '../../core/services/update_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/session_timer_service.dart';
import '../../data/models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/screen_provider.dart';
import '../../providers/shift_provider.dart';
import '../widgets/add_screen_dialog.dart';
import '../widgets/change_player_tier_dialog.dart';
import '../widgets/close_shift_dialog.dart';
import '../widgets/in_app_alert_banner.dart';
import '../widgets/pricing_settings_dialog.dart';
import '../widgets/printer_settings_dialog.dart';
import '../widgets/reset_test_data_dialog.dart';
import '../widgets/screen_card_widget.dart';
import '../widgets/session_checkout_modal.dart';
import '../widgets/session_details_modal.dart';
import '../widgets/staff_management_dialog.dart';
import '../widgets/start_session_dialog.dart';
import '../widgets/stat_badge_widget.dart';
import '../widgets/sync_status_indicator.dart';
import 'inventory_screen.dart';
import 'login_screen.dart';
import 'reports_screen.dart';

/// Main Dashboard Screen for the Gaming Lounge
class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  Timer? _clockTimer;
  StreamSubscription<SessionAlert>? _alertSubscription;
  DateTime _currentTime = DateTime.now();
  String _selectedFilter = 'all'; // 'all', 'available', 'occupied'
  final Set<String> _autoOpenedSessions = {};

  @override
  void initState() {
    super.initState();
    SessionTimerService().startGlobalTicker();

    // Check for remote app updates on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        UpdateService().checkAndShowPrompt(context);
      }
    });
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
        final screenProvider = Provider.of<ScreenProvider>(context, listen: false);
        final activeList = screenProvider.activeSessions.values.toList();
        SessionAlertService().checkSessions(activeList);
      }
    });

    // Auto-open Checkout Modal when a budget-based session expires
    _alertSubscription = SessionAlertService().onNewAlert.listen((alert) {
      if (!mounted) return;
      if (alert.type == SessionAlertType.budgetExpired) {
        if (!_autoOpenedSessions.contains(alert.sessionId)) {
          _autoOpenedSessions.add(alert.sessionId);
          final screenProvider = Provider.of<ScreenProvider>(context, listen: false);
          final session = screenProvider.activeSessions[alert.sessionId] ??
              screenProvider.activeSessions.values.firstWhere(
                (s) => s.sessionId == alert.sessionId,
                orElse: () => GameSessionModel.startNew(
                  sessionId: alert.sessionId,
                  screenId: 'screen_${alert.screenNumber}',
                  screenNumber: alert.screenNumber,
                  playerCount: 2,
                ),
              );
          final allScreens = screenProvider.screens;
          final screen = allScreens.firstWhere(
            (s) => s.screenNumber == alert.screenNumber,
            orElse: () => ScreenModel(
              id: session.screenId,
              screenNumber: alert.screenNumber,
              isOccupied: true,
            ),
          );
          _openCheckoutModal(context, screen, session);
        }
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _alertSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenProvider = Provider.of<ScreenProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    // Fallback: If screens are not loaded yet or empty, generate placeholder list for screens 1-8
    final allScreens = screenProvider.screens.isNotEmpty
        ? screenProvider.screens
        : List.generate(
            AppConstants.totalScreensCount,
            (index) => ScreenModel(
              id: 'screen_${index + 1}',
              screenNumber: index + 1,
              isOccupied: false,
            ),
          );

    bool isScreenOccupied(ScreenModel s) {
      final hasSession = screenProvider.getActiveSession(s.id, s.activeSessionId) != null;
      return s.isOccupied == true || hasSession || (s.activeSessionId != null && s.activeSessionId!.isNotEmpty);
    }

    final occupiedCount = allScreens.where(isScreenOccupied).length;
    final availableCount = allScreens.where((s) => !isScreenOccupied(s)).length;

    // Filter screens based on selection (All, Available, or Occupied)
    final filteredScreens = allScreens.where((screen) {
      final isOccupied = isScreenOccupied(screen);
      if (_selectedFilter == 'occupied') return isOccupied;
      if (_selectedFilter == 'available') return !isOccupied;
      return true;
    }).toList();

    // Calculate total active players and current live ongoing bill sum
    int totalActivePlayers = 0;
    double ongoingEstimatedRevenue = 0.0;

    for (final screen in allScreens) {
      final session = screenProvider.getActiveSession(screen.id, screen.activeSessionId);
      if (session != null && session.isActive) {
        totalActivePlayers += session.playerCount;
        ongoingEstimatedRevenue += session.calculateTotalAmount();
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, authProvider),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {},
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. Quick Metrics Row (Top of screen without bulky header box)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                  child: _buildStatsRow(
                    occupiedCount: occupiedCount,
                    availableCount: availableCount,
                    totalActivePlayers: totalActivePlayers,
                    ongoingRevenue: ongoingEstimatedRevenue,
                  ),
                ),
              ),

              // In-App Alert Notifications (Hourly & Countdown alerts)
              const SliverToBoxAdapter(
                child: InAppAlertBanner(),
              ),

              // 2. Filter Bar and Section Title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.grid_view_rounded, color: AppColors.primaryLight, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'شاشات الصالة (${filteredScreens.length})',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          // Filter Segmented Buttons (All, Available, and Occupied)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildFilterChip('الكل (${allScreens.length})', 'all', AppColors.cyanAccent),
                                const SizedBox(width: 8),
                                _buildFilterChip('المتاحة ($availableCount)', 'available', AppColors.available),
                                const SizedBox(width: 8),
                                _buildFilterChip('المشغولة ($occupiedCount)', 'occupied', AppColors.occupied),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              // 3. Grid of 8 Screens or Empty Filter Placeholder
              if (filteredScreens.isEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _selectedFilter == 'occupied'
                                ? Icons.sports_esports_outlined
                                : Icons.tv_off_outlined,
                            size: 48,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _selectedFilter == 'occupied'
                                ? 'لا توجد شاشات مشغولة قيد اللعب حالياً'
                                : 'جميع الشاشات مشغولة حالياً',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedFilter == 'occupied'
                                ? 'يمكنك بدء جلسة جديدة من تبويب الشاشات المتاحة'
                                : 'يمكنك إنهاء الجلسات الحالية لتفريغ الشاشات',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 380,
                      mainAxisExtent: 325,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final screen = filteredScreens[index];
                        final activeSession = screenProvider.getActiveSession(screen.id, screen.activeSessionId);

                        return ScreenCardWidget(
                          screen: screen,
                          activeSession: activeSession,
                          onStartSession: () => _openStartSessionDialog(context, screen),
                          onEndSession: () {
                            if (activeSession != null) {
                              _openCheckoutModal(context, screen, activeSession);
                            }
                          },
                          onChangePlayers: (newCount) {
                            if (activeSession != null) {
                              _openChangeTierDialog(context, activeSession);
                            }
                          },
                          onViewDetails: () {
                            if (activeSession != null) {
                              _openSessionDetails(context, activeSession);
                            }
                          },
                        );
                      },
                      childCount: filteredScreens.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AuthProvider authProvider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 960;

    return AppBar(
      titleSpacing: 16,
      title: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.sports_esports, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            const Text(
              'مركز الألعاب | Game Lounge',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
      ),
      actions: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Live Clock
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time, size: 15, color: AppColors.cyanAccent),
                    const SizedBox(width: 5),
                    Text(
                      AppFormatters.formatTimeOnly(_currentTime),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Live Sync Status Indicator
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: SyncStatusIndicator(isOnline: true),
              ),
              // Market / Inventory Screen Navigation Button
              if (!isCompact)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const InventoryScreen()),
                      );
                    },
                    icon: const Icon(Icons.storefront, size: 17),
                    label: const Text('الماركيت والمخزن', style: TextStyle(fontSize: 12.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceLight,
                      foregroundColor: AppColors.cyanAccent,
                      side: const BorderSide(color: AppColors.cyanAccent, width: 1),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      elevation: 0,
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.storefront, color: AppColors.cyanAccent, size: 20),
                  tooltip: 'الماركيت والمخزن',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const InventoryScreen()),
                    );
                  },
                ),
              // Financial Reports (Admin Only)
              if (authProvider.isAdmin)
                if (!isCompact)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ReportsScreen()),
                        );
                      },
                      icon: const Icon(Icons.analytics_outlined, size: 17),
                      label: const Text('التقارير المالية', style: TextStyle(fontSize: 12.5)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceLight,
                        foregroundColor: AppColors.primaryLight,
                        side: const BorderSide(color: AppColors.primaryNeon, width: 1),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        elevation: 0,
                      ),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.analytics_outlined, color: AppColors.primaryLight, size: 20),
                    tooltip: 'التقارير المالية',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ReportsScreen()),
                      );
                    },
                  ),
              if (authProvider.isAdmin)
                IconButton(
                  icon: const Icon(Icons.add_to_queue, color: AppColors.cyanAccent, size: 20),
                  tooltip: 'إضافة شاشة / طاولة جديدة',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const AddScreenDialog(),
                    );
                  },
                ),
              // User Profile & Role Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () => _showUserProfileModal(context, authProvider),
                  borderRadius: BorderRadius.circular(20),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: authProvider.isAdmin
                            ? AppColors.primaryNeon.withAlpha(40)
                            : AppColors.cyanAccent.withAlpha(40),
                        child: Icon(
                          authProvider.isAdmin ? Icons.admin_panel_settings : Icons.person,
                          color: authProvider.isAdmin ? AppColors.primaryLight : AppColors.cyanAccent,
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: authProvider.isAdmin
                              ? AppColors.primaryNeon.withAlpha(25)
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: authProvider.isAdmin
                                ? AppColors.primaryNeon.withAlpha(80)
                                : AppColors.cardBorder,
                          ),
                        ),
                        child: Text(
                          authProvider.isAdmin ? 'المدير' : 'موظف',
                          style: TextStyle(
                            color: authProvider.isAdmin ? AppColors.primaryLight : AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Quick Seed screens button
              IconButton(
                icon: const Icon(Icons.cloud_sync, color: AppColors.primaryLight, size: 20),
                tooltip: 'تهيئة الشاشات الأولية (1-8)',
                onPressed: () => _seedInitialData(context),
              ),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow({
    required int occupiedCount,
    required int availableCount,
    required int totalActivePlayers,
    required double ongoingRevenue,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            StatBadgeWidget(
              title: 'إجمالي الشاشات',
              value: '${AppConstants.totalScreensCount} شاشات',
              icon: Icons.tv,
              accentColor: AppColors.primaryLight,
            ),
            StatBadgeWidget(
              title: 'مشغولة (قيد اللعب)',
              value: '$occupiedCount شاشات',
              icon: Icons.sports_esports,
              accentColor: AppColors.occupied,
            ),
            StatBadgeWidget(
              title: 'متاحة للتشغيل',
              value: '$availableCount شاشات',
              icon: Icons.check_circle_outline,
              accentColor: AppColors.available,
            ),
            StatBadgeWidget(
              title: 'إجمالي اللاعبين حالياً',
              value: '$totalActivePlayers لاعبين',
              icon: Icons.groups,
              accentColor: AppColors.cyanAccent,
            ),
            StatBadgeWidget(
              title: 'الإيراد اللحظي التقديري',
              value: AppFormatters.formatCurrency(ongoingRevenue),
              icon: Icons.monetization_on_outlined,
              accentColor: AppColors.warning,
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String filterKey, [Color? color]) {
    final isSelected = _selectedFilter == filterKey;
    final activeColor = color ?? AppColors.primaryNeon;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = filterKey;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withAlpha(40) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  void _openStartSessionDialog(BuildContext context, ScreenModel screen) {
    showDialog(
      context: context,
      builder: (ctx) => StartSessionDialog(
        screenNumber: screen.screenNumber,
        onConfirmWithBudget: (playerCount, notes, isBudgetBased, targetBudget, targetDurationMinutes) async {
          final screenProvider = Provider.of<ScreenProvider>(context, listen: false);
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          await screenProvider.startSession(
            screenId: screen.id,
            screenNumber: screen.screenNumber,
            playerCount: playerCount,
            createdBy: authProvider.currentUser?.name,
            notes: notes,
            isBudgetBased: isBudgetBased,
            targetBudget: targetBudget,
            targetDurationMinutes: targetDurationMinutes,
            allocatedEndTime: targetDurationMinutes != null
                ? DateTime.now().add(Duration(minutes: targetDurationMinutes))
                : null,
          );
        },
      ),
    );
  }

  void _openChangeTierDialog(BuildContext context, GameSessionModel session) {
    showDialog(
      context: context,
      builder: (ctx) => ChangePlayerTierDialog(
        session: session,
        onConfirmChange: (newPlayerCount) {
          final screenProvider = Provider.of<ScreenProvider>(context, listen: false);
          screenProvider.changePlayerCount(
            sessionId: session.sessionId,
            newPlayerCount: newPlayerCount,
          );
        },
      ),
    );
  }

  void _openSessionDetails(BuildContext context, GameSessionModel session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SessionDetailsModal(
        session: session,
        onChangePlayers: (newCount) async {
          final screenProvider = Provider.of<ScreenProvider>(context, listen: false);
          await screenProvider.changePlayerCount(
            sessionId: session.sessionId,
            newPlayerCount: newCount,
          );
          if (ctx.mounted) Navigator.pop(ctx);
        },
        onAddOrder: (item) async {
          final screenProvider = Provider.of<ScreenProvider>(context, listen: false);
          try {
            await screenProvider.addOrderItem(sessionId: session.sessionId, item: item);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.occupied,
                  content: Text('خطأ أثناء إضافة الطلب: $e'),
                ),
              );
            }
          }
        },
        onAddMultipleOrders: (items) async {
          final screenProvider = Provider.of<ScreenProvider>(context, listen: false);
          try {
            await screenProvider.addMultipleOrderItems(sessionId: session.sessionId, items: items);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.occupied,
                  content: Text('خطأ أثناء إضافة الطلبات: $e'),
                ),
              );
            }
          }
        },
        onRemoveOrder: (productId) async {
          final screenProvider = Provider.of<ScreenProvider>(context, listen: false);
          try {
            await screenProvider.removeOrderItem(sessionId: session.sessionId, productId: productId);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.occupied,
                  content: Text('خطأ أثناء حذف الطلب: $e'),
                ),
              );
            }
          }
        },
        onEndSession: () {
          _openCheckoutModal(
            context,
            ScreenModel(id: session.screenId, screenNumber: session.screenNumber, isOccupied: true),
            session,
          );
        },
      ),
    );
  }

  void _openCheckoutModal(BuildContext context, ScreenModel screen, GameSessionModel session) {
    showDialog(
      context: context,
      builder: (ctx) => SessionCheckoutModal(
        screen: screen,
        session: session,
        onConfirmPaymentWithAmount: (finalPaidAmount) async {
          final screenProvider = Provider.of<ScreenProvider>(context, listen: false);
          final shiftProvider = Provider.of<ShiftProvider>(context, listen: false);
          final calculation = SessionTimerService.calculateSession(session: session);
          
          shiftProvider.recordSessionToShift(
            gamingRevenue: calculation.totalGamingCost,
            marketRevenue: calculation.totalMarketCost,
            customGrandTotal: finalPaidAmount,
          );

          await screenProvider.endSession(
            sessionId: session.sessionId,
            screenId: screen.id,
            isPaid: true,
            customTotalAmount: finalPaidAmount,
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.available,
                content: Text(
                  'تم استلام ${AppFormatters.formatCurrency(finalPaidAmount)} بنجاح وتم تحرير شاشة ${screen.screenNumber}',
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _seedInitialData(BuildContext context) async {
    final screenProvider = Provider.of<ScreenProvider>(context, listen: false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('جاري تهيئة الـ 8 شاشات الأولية...')),
    );

    await screenProvider.seedDefaultScreens();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.available,
          content: Text('تمت تهيئة الشاشات الأولية بنجاح!'),
        ),
      );
    }
  }

  void _showUserProfileModal(BuildContext context, AuthProvider authProvider) {
    final user = authProvider.currentUser;
    final isAdmin = authProvider.isAdmin;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: isAdmin
                        ? AppColors.primaryNeon.withAlpha(40)
                        : AppColors.cyanAccent.withAlpha(40),
                    child: Icon(
                      isAdmin ? Icons.admin_panel_settings : Icons.person,
                      color: isAdmin ? AppColors.primaryLight : AppColors.cyanAccent,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'مستخدم الصالة',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? 'active.session@gamelounge.iq',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAdmin
                          ? AppColors.primaryNeon.withAlpha(30)
                          : AppColors.cyanAccent.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isAdmin ? AppColors.primaryNeon : AppColors.cyanAccent,
                      ),
                    ),
                    child: Text(
                      isAdmin ? 'مدير عام (Admin)' : 'كابتن صالة (Staff)',
                      style: TextStyle(
                        color: isAdmin ? AppColors.primaryLight : AppColors.cyanAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),
              const Divider(),
              const SizedBox(height: 8),

              // Reports Option (Admin Only)
              if (isAdmin) ...[
                ListTile(
                  leading: const Icon(Icons.analytics_outlined, color: AppColors.primaryLight),
                  title: const Text('التقارير المالية والأرباح (Reports)', style: TextStyle(fontSize: 13.5)),
                  subtitle: const Text('دخل الساعات، مبيعات الماركيت، وصافي الأرباح', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: AppColors.surfaceLight,
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReportsScreen()),
                    );
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.people_alt_outlined, color: AppColors.cyanAccent),
                  title: const Text('إدارة حسابات الموظفين والصلاحيات', style: TextStyle(fontSize: 13.5)),
                  subtitle: const Text('إضافة موظفين، تعديل الأدوار، وحذف الحسابات', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: AppColors.surfaceLight,
                  onTap: () {
                    Navigator.pop(ctx);
                    showDialog(
                      context: context,
                      builder: (_) => const StaffManagementDialog(),
                    );
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.price_change_outlined, color: AppColors.warning),
                  title: const Text('تعديل أسعار ساعات اللعب (Pricing Rates)', style: TextStyle(fontSize: 13.5)),
                  subtitle: const Text('تعديل تسعيرة الساعات لـ 2، 3، و 4 لاعبين فما فوق', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: AppColors.surfaceLight,
                  onTap: () {
                    Navigator.pop(ctx);
                    showDialog(
                      context: context,
                      builder: (_) => const PricingSettingsDialog(),
                    );
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.add_to_queue, color: AppColors.cyanAccent),
                  title: const Text('إضافة شاشة / طاولة ألعاب جديدة', style: TextStyle(fontSize: 13.5)),
                  subtitle: const Text('إضافة وتوسيع أجهزة وشاشات الصالة في اللوحة', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: AppColors.surfaceLight,
                  onTap: () {
                    Navigator.pop(ctx);
                    showDialog(
                      context: context,
                      builder: (_) => const AddScreenDialog(),
                    );
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.print_outlined, color: AppColors.cyanAccent),
                  title: const Text('إعدادات طابعة الفواتير وبيانات الصالة (Receipt Settings)', style: TextStyle(fontSize: 13.5)),
                  subtitle: const Text('البحث والاقتران بطابعة البلوتوث وتخصيص الفاتورة', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: AppColors.surfaceLight,
                  onTap: () {
                    Navigator.pop(ctx);
                    showDialog(
                      context: context,
                      builder: (_) => const PrinterSettingsDialog(),
                    );
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.system_update_alt, color: AppColors.cyanAccent),
                  title: const Text('تحديثات النظام وإصدار التطبيق (Software Updates)', style: TextStyle(fontSize: 13.5)),
                  subtitle: FutureBuilder<String>(
                    future: UpdateService().getCurrentVersion(),
                    builder: (context, snapshot) {
                      final v = snapshot.data ?? '1.0.0';
                      return Text('الإصدار الحالي: v$v • فحص التحديثات السحابية', style: const TextStyle(fontSize: 11));
                    },
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: AppColors.surfaceLight,
                  onTap: () {
                    Navigator.pop(ctx);
                    UpdateService().checkAndShowPrompt(context, isManualCheck: true);
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.delete_forever_outlined, color: AppColors.occupied),
                  title: const Text('تصفير السجلات والبيانات المالية (Clear Test Data)', style: TextStyle(fontSize: 13.5, color: AppColors.occupied)),
                  subtitle: const Text('مسح الجلسات والتوريدات التجريبية وتصفير العدادات للافتتاح', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: AppColors.occupied.withAlpha(15),
                  onTap: () {
                    Navigator.pop(ctx);
                    showDialog(
                      context: context,
                      builder: (_) => const ResetTestDataDialog(),
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],

              // Shift Management Option (For all roles)
              ListTile(
                leading: const Icon(Icons.point_of_sale, color: AppColors.warning),
                title: const Text('إغلاق الجلسة وتسليم الكاش (Shift)', style: TextStyle(fontSize: 13.5)),
                subtitle: const Text('مراجعة إجمالي دخل الجلسة وتسليم صندوق الكاش', style: TextStyle(fontSize: 11)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: AppColors.surfaceLight,
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    builder: (_) => const CloseShiftDialog(),
                  );
                },
              ),
              const SizedBox(height: 8),

              // Sign Out Option
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.occupied),
                title: const Text('تسجيل الخروج من النظام', style: TextStyle(fontSize: 13.5, color: AppColors.occupied)),
                subtitle: const Text('العودة إلى شاشة تسجيل الدخول والتبديل', style: TextStyle(fontSize: 11)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: AppColors.occupied.withAlpha(15),
                onTap: () async {
                  Navigator.pop(ctx);
                  await authProvider.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
