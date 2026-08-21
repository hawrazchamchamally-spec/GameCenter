import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/models.dart';
import '../data/services/firestore_service.dart';

/// State Management Provider for Gaming Screens (1 to 8)
class ScreenProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;

  List<ScreenModel> _screens = [];
  Map<String, GameSessionModel> _activeSessions = {}; // screenId -> GameSessionModel
  bool _isLoading = true;
  String? _errorMessage;

  StreamSubscription<List<ScreenModel>>? _screensSubscription;
  StreamSubscription<List<GameSessionModel>>? _sessionsSubscription;

  ScreenProvider({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService() {
    _init();
  }

  // Getters
  List<ScreenModel> get screens => _screens;
  Map<String, GameSessionModel> get activeSessions => _activeSessions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get occupiedScreensCount => _screens.where((s) => s.isOccupied == true).length;
  int get availableScreensCount => _screens.where((s) => s.isOccupied == false).length;

  /// Returns the active session for a given screen by screenId or activeSessionId
  GameSessionModel? getActiveSession(String screenId, [String? activeSessionId]) {
    if (_activeSessions.containsKey(screenId)) {
      return _activeSessions[screenId];
    }
    if (activeSessionId != null && _activeSessions.containsKey(activeSessionId)) {
      return _activeSessions[activeSessionId];
    }
    return null;
  }

  void _init() {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Listen to Screens Stream
      _screensSubscription = _firestoreService.getScreensStream().listen(
        (screensList) {
          _screens = screensList;
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
        },
        onError: (error) {
          _isLoading = false;
          _errorMessage = error.toString();
          notifyListeners();
        },
      );

      // 2. Listen to Active Sessions Stream
      _sessionsSubscription = _firestoreService.getActiveSessionsStream().listen(
        (sessionsList) {
          final Map<String, GameSessionModel> sessionMap = {};
          for (final session in sessionsList) {
            sessionMap[session.screenId] = session;
            if (session.sessionId.isNotEmpty) {
              sessionMap[session.sessionId] = session;
            }
          }
          _activeSessions = sessionMap;
          notifyListeners();
        },
        onError: (error) {
          // Handle session stream error
        },
      );
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Initialize default 8 screens
  Future<void> seedDefaultScreens() async {
    try {
      await _firestoreService.initializeDefaultScreens();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Start a session on a screen
  Future<GameSessionModel?> startSession({
    required String screenId,
    required int screenNumber,
    required int playerCount,
    String? createdBy,
    String? notes,
    bool isBudgetBased = false,
    double? targetBudget,
    int? targetDurationMinutes,
    DateTime? allocatedEndTime,
  }) async {
    try {
      final session = await _firestoreService.startSession(
        screenId: screenId,
        screenNumber: screenNumber,
        playerCount: playerCount,
        createdBy: createdBy,
        notes: notes,
        isBudgetBased: isBudgetBased,
        targetBudget: targetBudget,
        targetDurationMinutes: targetDurationMinutes,
        allocatedEndTime: allocatedEndTime,
      );
      _activeSessions[screenId] = session;
      _activeSessions[session.sessionId] = session;

      // Update local screen status immediately for instant UI feedback
      final index = _screens.indexWhere((s) => s.id == screenId);
      if (index != -1) {
        _screens[index] = _screens[index].copyWith(
          isOccupied: true,
          activeSessionId: session.sessionId,
        );
      }
      notifyListeners();
      return session;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Change player count during an active session
  Future<void> changePlayerCount({
    required String sessionId,
    required int newPlayerCount,
  }) async {
    try {
      await _firestoreService.changeSessionPlayerCount(
        sessionId: sessionId,
        newPlayerCount: newPlayerCount,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Add market order item to an active session
  Future<void> addOrderItem({
    required String sessionId,
    required OrderItem item,
  }) async {
    try {
      // Optimistic local update
      if (_activeSessions.containsKey(sessionId)) {
        final current = _activeSessions[sessionId]!;
        final updated = current.addOrder(item);
        _activeSessions[sessionId] = updated;
        _activeSessions[current.screenId] = updated;
        notifyListeners();
      }

      await _firestoreService.addOrderItemToSession(
        sessionId: sessionId,
        item: item,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Add multiple market order items in batch to an active session
  Future<void> addMultipleOrderItems({
    required String sessionId,
    required List<OrderItem> items,
  }) async {
    try {
      // Optimistic local update
      if (_activeSessions.containsKey(sessionId)) {
        var current = _activeSessions[sessionId]!;
        for (final item in items) {
          current = current.addOrder(item);
        }
        _activeSessions[sessionId] = current;
        _activeSessions[current.screenId] = current;
        notifyListeners();
      }

      await _firestoreService.addMultipleOrderItemsToSession(
        sessionId: sessionId,
        items: items,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Remove market order item from an active session
  Future<void> removeOrderItem({
    required String sessionId,
    required String productId,
  }) async {
    try {
      // Optimistic local update
      if (_activeSessions.containsKey(sessionId)) {
        final current = _activeSessions[sessionId]!;
        final updated = current.removeOrder(productId);
        _activeSessions[sessionId] = updated;
        _activeSessions[current.screenId] = updated;
        notifyListeners();
      }

      await _firestoreService.removeOrderItemFromSession(
        sessionId: sessionId,
        productId: productId,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// End session and release screen
  Future<GameSessionModel?> endSession({
    required String sessionId,
    required String screenId,
    bool isPaid = true,
    double? customTotalAmount,
  }) async {
    try {
      final finalized = await _firestoreService.endSession(
        sessionId: sessionId,
        screenId: screenId,
        isPaid: isPaid,
        customTotalAmount: customTotalAmount,
      );
      _activeSessions.remove(screenId);
      _activeSessions.remove(sessionId);

      final index = _screens.indexWhere((s) => s.id == screenId);
      if (index != -1) {
        _screens[index] = _screens[index].copyWith(
          isOccupied: false,
          clearActiveSession: true,
          lastSessionEndedAt: DateTime.now(),
        );
      }
      notifyListeners();
      return finalized;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Add a new screen/table to the lounge
  Future<ScreenModel?> addNewScreen({
    required int screenNumber,
    String? name,
    String? deviceType,
    String? sectionName,
  }) async {
    try {
      final screen = await _firestoreService.addNewScreen(
        screenNumber: screenNumber,
        name: name,
        deviceType: deviceType,
        sectionName: sectionName,
      );
      final index = _screens.indexWhere((s) => s.id == screen.id || s.screenNumber == screen.screenNumber);
      if (index != -1) {
        _screens[index] = screen;
      } else {
        _screens.add(screen);
        _screens.sort((a, b) => a.screenNumber.compareTo(b.screenNumber));
      }
      notifyListeners();
      return screen;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Reset all local screens and active sessions (called after system purge)
  void resetAllScreensState() {
    _activeSessions = {};
    _screens = _screens.map((s) => s.copyWith(
      isOccupied: false,
      activeSessionId: null,
      lastSessionEndedAt: null,
    )).toList();
    notifyListeners();
  }

  @override
  void dispose() {
    _screensSubscription?.cancel();
    _sessionsSubscription?.cancel();
    super.dispose();
  }
}
