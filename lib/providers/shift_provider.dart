import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/models.dart';
import '../../data/services/firestore_service.dart';

/// Provider managing staff work shifts and cash drawer balancing
class ShiftProvider extends ChangeNotifier {
  ShiftModel? _currentShift;
  List<ShiftModel> _shiftHistory = [];
  final bool _isLoading = false;
  String? _errorMessage;

  ShiftProvider({
    FirestoreService? firestoreService,
    ShiftModel? initialShift,
    List<ShiftModel>? initialHistory,
  }) {
    if (initialShift != null) {
      _currentShift = initialShift;
    } else {
      // Auto-start default demo shift for immediate seamless operation
      _currentShift = ShiftModel.startNew(
        shiftId: 'shift_default_1',
        staffId: 'staff_1',
        staffName: 'موظف الصالة',
        startTime: DateTime.now().subtract(const Duration(hours: 3)),
      ).copyWith(
        totalSessionsCount: 4,
        totalGamingRevenue: 24000.0,
        totalMarketRevenue: 12000.0,
        totalCashExpected: 36000.0,
      );
    }
    if (initialHistory != null) {
      _shiftHistory = initialHistory;
    } else {
      _initDemoHistory();
    }
  }

  ShiftModel? get currentShift => _currentShift;
  bool get hasActiveShift => _currentShift != null && _currentShift!.isActive;
  List<ShiftModel> get shiftHistory => _shiftHistory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _initDemoHistory() {
    final now = DateTime.now();
    _shiftHistory = [
      ShiftModel(
        id: 'shift_hist_1',
        staffId: 'staff_1',
        staffName: 'أحمد السامرائي',
        startTime: now.subtract(const Duration(days: 1, hours: 8)),
        endTime: now.subtract(const Duration(days: 1)),
        status: 'closed',
        totalSessionsCount: 14,
        totalGamingRevenue: 85000.0,
        totalMarketRevenue: 34000.0,
        totalCashExpected: 119000.0,
        notes: 'تم تسليم كامل الكاش ومطابقة الصندوق بدون أي نقص',
        createdAt: now.subtract(const Duration(days: 1, hours: 8)),
      ),
      ShiftModel(
        id: 'shift_hist_2',
        staffId: 'staff_2',
        staffName: 'علي الكرخي',
        startTime: now.subtract(const Duration(days: 2, hours: 8)),
        endTime: now.subtract(const Duration(days: 2)),
        status: 'closed',
        totalSessionsCount: 18,
        totalGamingRevenue: 110000.0,
        totalMarketRevenue: 48000.0,
        totalCashExpected: 158000.0,
        notes: 'شفت مسائي مزدحم، تم استلام الكاش كاملاً',
        createdAt: now.subtract(const Duration(days: 2, hours: 8)),
      ),
    ];
  }

  /// Start a new staff shift
  void startShift({
    required String staffId,
    required String staffName,
  }) {
    _currentShift = ShiftModel.startNew(
      shiftId: const Uuid().v4(),
      staffId: staffId,
      staffName: staffName,
    );
    notifyListeners();
  }

  /// Record a completed session onto the active shift (supporting custom discounted totals)
  void recordSessionToShift({
    required double gamingRevenue,
    required double marketRevenue,
    double? customGrandTotal,
  }) {
    if (_currentShift == null) return;

    final effectiveGaming = customGrandTotal != null
        ? (customGrandTotal - marketRevenue).clamp(0.0, double.infinity)
        : gamingRevenue;

    final newCount = _currentShift!.totalSessionsCount + 1;
    final newGaming = _currentShift!.totalGamingRevenue + effectiveGaming;
    final newMarket = _currentShift!.totalMarketRevenue + marketRevenue;
    final newTotal = _currentShift!.totalCashExpected + (customGrandTotal ?? (gamingRevenue + marketRevenue));

    _currentShift = _currentShift!.copyWith(
      totalSessionsCount: newCount,
      totalGamingRevenue: newGaming,
      totalMarketRevenue: newMarket,
      totalCashExpected: newTotal,
    );

    notifyListeners();
  }

  /// Finalize and close the current shift
  Future<ShiftModel?> closeCurrentShift({String? notes}) async {
    if (_currentShift == null) return null;

    final closedShift = _currentShift!.closeShift(
      sessionsCount: _currentShift!.totalSessionsCount,
      gamingRevenue: _currentShift!.totalGamingRevenue,
      marketRevenue: _currentShift!.totalMarketRevenue,
      notes: notes,
    );

    _shiftHistory.insert(0, closedShift);
    _currentShift = null;
    notifyListeners();
    return closedShift;
  }

  /// Completely resets current shift and historical records to 0 for grand opening
  void resetShiftToZero({String? staffName, String? staffId}) {
    _shiftHistory = [];
    _currentShift = ShiftModel.startNew(
      shiftId: const Uuid().v4(),
      staffId: staffId ?? 'admin_1',
      staffName: staffName ?? 'المدير',
      startTime: DateTime.now(),
    );
    notifyListeners();
  }
}
