import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/models.dart';
import '../data/services/firestore_service.dart';

/// Provider for managing a detailed active session with live ticking timer
class SessionProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;

  GameSessionModel? _currentSession;
  Timer? _liveTicker;
  StreamSubscription<GameSessionModel?>? _sessionSubscription;
  bool _isLoading = false;
  String? _errorMessage;

  SessionProvider({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  // Getters
  GameSessionModel? get currentSession => _currentSession;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Current live gaming cost
  double get liveGamingCost {
    if (_currentSession == null) return 0.0;
    return _currentSession!.calculateRealTimeGamingCost();
  }

  /// Current live market cost
  double get liveMarketCost {
    if (_currentSession == null) return 0.0;
    return _currentSession!.calculateTotalMarketCost();
  }

  /// Current live total bill amount
  double get liveTotalAmount {
    if (_currentSession == null) return 0.0;
    return _currentSession!.calculateTotalAmount();
  }

  /// Current live elapsed duration
  Duration get liveDuration {
    if (_currentSession == null) return Duration.zero;
    return _currentSession!.getElapsedDuration();
  }

  /// Selects and attaches to a session
  void selectSession(String sessionId) {
    _sessionSubscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _sessionSubscription = _firestoreService.getSessionStream(sessionId).listen(
      (session) {
        _currentSession = session;
        _isLoading = false;
        notifyListeners();
        _startLiveTicker();
      },
      onError: (error) {
        _isLoading = false;
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  /// Sets session directly
  void setSession(GameSessionModel? session) {
    _currentSession = session;
    notifyListeners();
    if (session != null && session.isActive) {
      _startLiveTicker();
    } else {
      _liveTicker?.cancel();
    }
  }

  void _startLiveTicker() {
    _liveTicker?.cancel();
    if (_currentSession != null && _currentSession!.isActive) {
      _liveTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        notifyListeners(); // Refresh UI for live elapsed seconds and cost
      });
    }
  }

  /// Add market order item to current session
  Future<void> addOrderItem(OrderItem item) async {
    if (_currentSession == null) return;
    try {
      await _firestoreService.addOrderItemToSession(
        sessionId: _currentSession!.sessionId,
        item: item,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Remove market order item from current session
  Future<void> removeOrderItem(String productId) async {
    if (_currentSession == null) return;
    try {
      await _firestoreService.removeOrderItemFromSession(
        sessionId: _currentSession!.sessionId,
        productId: productId,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Update player count in current session
  Future<void> changePlayerCount(int newPlayerCount) async {
    if (_currentSession == null) return;
    try {
      await _firestoreService.changeSessionPlayerCount(
        sessionId: _currentSession!.sessionId,
        newPlayerCount: newPlayerCount,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Clear session
  void clear() {
    _sessionSubscription?.cancel();
    _liveTicker?.cancel();
    _currentSession = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    _liveTicker?.cancel();
    super.dispose();
  }
}
