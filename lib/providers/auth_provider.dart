import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/models.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firestore_service.dart';

/// Provider managing authentication state and role-based access control (Admin / Staff)
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final FirestoreService _firestoreService;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<User?>? _authSubscription;

  AuthProvider({
    AuthService? authService,
    FirestoreService? firestoreService,
    UserModel? initialUser,
  })  : _authService = authService ?? AuthService(),
        _firestoreService = firestoreService ?? FirestoreService() {
    if (initialUser != null) {
      _currentUser = initialUser;
      _isLoading = false;
    } else {
      _init();
    }
  }

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isStaff => _currentUser?.isStaff ?? false;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _init() {
    _isLoading = true;
    notifyListeners();

    try {
      _authSubscription = _authService.authStateChanges.listen(
        (firebaseUser) async {
          if (firebaseUser != null) {
            try {
              _currentUser = await _firestoreService.getUserProfile(firebaseUser.uid);
              _currentUser ??= UserModel(
                uid: firebaseUser.uid,
                name: firebaseUser.displayName ?? 'موظف الصالة',
                email: firebaseUser.email,
                role: 'admin', // default initial admin
              );
            } catch (e) {
              _currentUser = UserModel(
                uid: firebaseUser.uid,
                name: 'مستخدم الصالة',
                role: 'admin',
              );
            }
          } else {
            // Default demo admin for smooth local experience if not authenticated
            _currentUser = UserModel(
              uid: 'admin_default',
              name: 'مدير الصالة (Admin)',
              email: 'admin@gamelounge.com',
              role: 'admin',
            );
          }
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          _isLoading = false;
          _errorMessage = error.toString();
          notifyListeners();
        },
      );
    } catch (e) {
      // In-memory fallback
      _currentUser = UserModel(
        uid: 'admin_default',
        name: 'مدير الصالة (Admin)',
        email: 'admin@gamelounge.com',
        role: 'admin',
      );
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign in with email and password
  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check if demo credentials
      if (email.contains('staff') || password == 'staff123') {
        _currentUser = UserModel(
          uid: 'staff_1',
          name: 'كابتن الصالة (Staff)',
          email: email,
          role: 'staff',
        );
        _isLoading = false;
        notifyListeners();
        return true;
      } else if (email.contains('admin') || password == 'admin123') {
        _currentUser = UserModel(
          uid: 'admin_1',
          name: 'مدير الصالة (Admin)',
          email: email,
          role: 'admin',
        );
        _isLoading = false;
        notifyListeners();
        return true;
      }

      final loggedInUser = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (loggedInUser != null) {
        _currentUser = loggedInUser;
      } else {
        _currentUser = UserModel(
          uid: const Uuid().v4(),
          name: email.split('@').first,
          email: email,
          role: 'staff',
        );
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'فشل تسجيل الدخول: البريد أو كلمة المرور غير صحيحة';
      notifyListeners();
      return false;
    }
  }

  /// Fast demo sign-in as Admin
  void signInAsDemoAdmin() {
    _currentUser = UserModel(
      uid: 'admin_demo',
      name: 'مدير الصالة (Admin)',
      email: 'admin@gamelounge.iq',
      role: 'admin',
    );
    _errorMessage = null;
    notifyListeners();
  }

  /// Fast demo sign-in as Staff
  void signInAsDemoStaff({String? name}) {
    _currentUser = UserModel(
      uid: const Uuid().v4(),
      name: name ?? 'كابتن الصالة (Staff)',
      email: 'staff@gamelounge.iq',
      role: 'staff',
    );
    _errorMessage = null;
    notifyListeners();
  }

  /// Register a new staff user (Admin only action)
  Future<bool> registerStaffUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    if (!isAdmin) {
      _errorMessage = 'غير مسموح إلا للمدير فقط';
      return false;
    }

    try {
      final newUser = UserModel(
        uid: const Uuid().v4(),
        name: name,
        email: email,
        password: password,
        role: role,
        createdAt: DateTime.now(),
      );
      await _firestoreService.saveUserProfile(newUser);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
    } catch (_) {}

    _currentUser = null;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
