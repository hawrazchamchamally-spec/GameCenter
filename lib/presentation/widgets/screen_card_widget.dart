import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/session_timer_service.dart';
import '../../data/models/models.dart';

/// Interactive Card displaying the status of a Gaming Screen (Screens 1 - 8)
class ScreenCardWidget extends StatefulWidget {
  final ScreenModel screen;
  final GameSessionModel? activeSession;
  final VoidCallback onStartSession;
  final VoidCallback onEndSession;
  final ValueChanged<int> onChangePlayers;
  final VoidCallback onViewDetails;

  const ScreenCardWidget({
    super.key,
    required this.screen,
    this.activeSession,
    required this.onStartSession,
    required this.onEndSession,
    required this.onChangePlayers,
    required this.onViewDetails,
  });

  @override
  State<ScreenCardWidget> createState() => _ScreenCardWidgetState();
}

class _ScreenCardWidgetState extends State<ScreenCardWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final isOccupied = widget.screen.isOccupied || widget.activeSession != null || widget.screen.activeSessionId != null;
    if (isOccupied) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(covariant ScreenCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isOccupied = widget.screen.isOccupied || widget.activeSession != null || widget.screen.activeSessionId != null;
    if (isOccupied) {
      if (_timer == null || !_timer!.isActive) {
        _startTimer();
      }
    } else {
      _timer?.cancel();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOccupied = widget.screen.isOccupied || widget.activeSession != null || widget.screen.activeSessionId != null;
    final session = widget.activeSession;

    final statusColor = isOccupied ? AppColors.occupied : AppColors.available;
    final borderColor = isOccupied
        ? AppColors.occupied.withAlpha(120)
        : AppColors.available.withAlpha(60);

    return InkWell(
      onTap: isOccupied ? (session != null ? widget.onViewDetails : null) : widget.onStartSession,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: isOccupied ? 1.8 : 1.2),
          boxShadow: [
            BoxShadow(
              color: isOccupied
                  ? AppColors.occupied.withAlpha(35)
                  : AppColors.available.withAlpha(15),
              blurRadius: isOccupied ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: isOccupied
                      ? AppColors.occupied.withAlpha(25)
                      : AppColors.available.withAlpha(15),
                  border: Border(
                    bottom: BorderSide(color: borderColor.withAlpha(80)),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: statusColor.withAlpha(140), width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          '${widget.screen.screenNumber}',
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  widget.screen.nameArabic,
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (widget.screen.deviceType != null && widget.screen.deviceType!.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: AppColors.cyanAccent.withAlpha(30),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.cyanAccent.withAlpha(80)),
                                  ),
                                  child: Text(
                                    widget.screen.deviceType!,
                                    style: const TextStyle(
                                      color: AppColors.cyanAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                              if (widget.screen.sectionName != null && widget.screen.sectionName!.isNotEmpty && widget.screen.sectionName != 'الصالة العامة') ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryNeon.withAlpha(30),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.primaryNeon.withAlpha(80)),
                                  ),
                                  child: Text(
                                    widget.screen.sectionName!,
                                    style: const TextStyle(
                                      color: AppColors.primaryLight,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            isOccupied ? 'جلسة نشطة (قيد اللعب)' : 'جاهزة للتشغيل (شاغرة)',
                            style: TextStyle(
                              fontSize: 11,
                              color: isOccupied ? AppColors.occupied : AppColors.available,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Status Indicator Badge
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor.withAlpha(120)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: statusColor,
                                boxShadow: [
                                  BoxShadow(
                                    color: statusColor.withAlpha(180),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isOccupied
                                  ? (session != null && session.isBudgetBased && session.isTimeExpired()
                                      ? 'انتهى الوقت!'
                                      : 'مشغولة')
                                  : 'متاحة',
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Card Body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                  child: isOccupied
                      ? (session != null ? _buildOccupiedContent(session) : _buildSessionLoadingContent())
                      : _buildAvailableContent(),
                ),
              ),

              // Card Footer Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: isOccupied
                    ? Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: session != null ? widget.onViewDetails : null,
                              icon: const Icon(Icons.receipt_long, size: 15),
                              label: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('عرض الجلسة / التفاصيل', style: TextStyle(fontSize: 11.5)),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: widget.onEndSession,
                              icon: const Icon(Icons.check_circle_outline, size: 15),
                              label: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('إنهاء وحساب', style: TextStyle(fontSize: 11.5)),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.occupied,
                                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
                              ),
                            ),
                          ),
                        ],
                      )
                    : ElevatedButton.icon(
                        onPressed: widget.onStartSession,
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('بدء جلسة جديدة', style: TextStyle(fontSize: 13)),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.available,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Occupied session state layout
  Widget _buildOccupiedContent(GameSessionModel session) {
    final calc = SessionTimerService.calculateSession(session: session);
    final elapsed = calc.totalDuration;
    final totalGamingCost = calc.totalGamingCost;
    final totalMarketCost = calc.totalMarketCost;
    final grandTotal = calc.grandTotal;

    final isBudget = session.isBudgetBased;
    final isExpired = session.isTimeExpired();
    final remaining = session.getRemainingDuration();
    final progress = session.getBudgetProgressPercentage();

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Live Timer & Players row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Digital Timer (Elapsed or Countdown)
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: isExpired ? AppColors.occupied.withAlpha(35) : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isExpired
                          ? AppColors.occupied
                          : (isBudget ? AppColors.warning : AppColors.cyanAccent.withAlpha(90)),
                      width: isExpired ? 1.5 : 1.0,
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isExpired
                              ? Icons.alarm_off
                              : (isBudget ? Icons.hourglass_bottom : Icons.timer_outlined),
                          color: isExpired
                              ? AppColors.occupied
                              : (isBudget ? AppColors.warning : AppColors.cyanAccent),
                          size: 15,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isBudget
                              ? (isExpired ? 'انتهى الوقت!' : '⏳ ${AppFormatters.formatDuration(remaining)}')
                              : AppFormatters.formatDuration(elapsed),
                          style: TextStyle(
                            color: isExpired
                                ? AppColors.occupied
                                : (isBudget ? AppColors.warning : AppColors.cyanAccent),
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // Player Count Dropdown/Badge
              Flexible(
                child: PopupMenuButton<int>(
                  initialValue: session.playerCount,
                  tooltip: 'تغيير عدد اللاعبين',
                  onSelected: widget.onChangePlayers,
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.cardBorder),
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 2,
                      child: Text('2 لاعبين (3,000 د.ع/ساعة)'),
                    ),
                    const PopupMenuItem(
                      value: 3,
                      child: Text('3 لاعبين (4,000 د.ع/ساعة)'),
                    ),
                    const PopupMenuItem(
                      value: 4,
                      child: Text('4 لاعبين (5,000 د.ع/ساعة)'),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryNeon.withAlpha(35),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primaryNeon.withAlpha(120)),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.sports_esports, color: AppColors.primaryLight, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${session.playerCount} لاعبين',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11.5,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary, size: 15),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Budget Progress Bar & Info if budget session
          if (isBudget) ...[
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: AppColors.surfaceLight,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isExpired
                      ? AppColors.occupied
                      : (progress > 0.85 ? AppColors.warning : AppColors.cyanAccent),
                ),
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'جلسة محددة: ${AppFormatters.formatCurrency(session.targetBudget ?? 0)}',
                  style: const TextStyle(fontSize: 10, color: AppColors.cyanAccent),
                ),
                Text(
                  '${session.targetDurationMinutes ?? 0} دقيقة',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isExpired ? AppColors.occupied : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 7),

          // Real-time Cost Breakdown Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder.withAlpha(50)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'تكلفة اللعب الحالية:',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      AppFormatters.formatCurrency(totalGamingCost),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
                if (session.orders.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'طلبات الماركت (${session.orders.length}):',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        AppFormatters.formatCurrency(totalMarketCost),
                        style: const TextStyle(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ],
                const Divider(height: 9),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'المجموع اللحظي:',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      AppFormatters.formatCurrency(grandTotal),
                      style: const TextStyle(
                        color: AppColors.cyanAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Available / Ready state layout
  Widget _buildAvailableContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.available.withAlpha(20),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.available.withAlpha(60)),
            ),
            child: const Icon(
              Icons.tv,
              size: 38,
              color: AppColors.available,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'الشاشة شاغرة ومستعدة للتشغيل',
            style: TextStyle(
              color: AppColors.available,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'اضغط لبدء جلسة واختيار عدد اللاعبين',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  /// Temporary loading state while session data is synchronizing
  Widget _buildSessionLoadingContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.occupied),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'جاري مزامنة بيانات الجلسة...',
            style: TextStyle(
              color: AppColors.occupied.withAlpha(200),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
