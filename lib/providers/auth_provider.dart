import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/session_storage_service.dart';
import '../../data/models/models.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firestore_service.dart';

/// Provider managing authentication state and role-based access control (Admin / Staff)
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final FirestoreService _firestoreService;
  final SessionStorageService _sessionStorage;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<User?>? _authSubscription;

  AuthProvider({
    AuthService? authService,
    FirestoreService? firestoreService,
    SessionStorageService? sessionStorage,
    UserModel? initialUser,
  })  : _authService = authService ?? AuthService(),
        _firestoreService = firestoreService ?? FirestoreService(),
        _sessionStorage = sessionStorage ?? SessionStorageService() {
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

  void _init() async {
    _isLoading = true;
    notifyListeners();

    // 1. Auto Login: Restore persistent user session from local storage
    try {
      final savedUser = await _sessionStorage.getSavedUserSession();
      if (savedUser != null) {
        _currentUser = savedUser;
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Local session check error: $e');
    }

    // 2. Firebase Auth state listener
    try {
      _authSubscription = _authService.authStateChanges.listen(
        (firebaseUser) async {
          if (firebaseUser != null) {
            try {
              final profile = await _firestoreService.getUserProfile(firebaseUser.uid);
              _currentUser = profile ?? _currentUser ?? UserModel(
                uid: firebaseUser.uid,
                name: firebaseUser.displayName ?? 'مستخدم الصالة',
                username: firebaseUser.email?.split('@').first ?? firebaseUser.uid,
                email: firebaseUser.email,
                role: 'admin',
              );
              if (_currentUser != null) {
                await _sessionStorage.saveUserSession(_currentUser!);
              }
            } catch (e) {
              // Retain local session
            }
          }
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign in with username/email and password
  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final identifier = email.trim();
    final cleanPassword = password.trim();

    try {
      // 1. Direct check for Firestore registered users (by username or email)
      try {
        final dbUser = await _firestoreService.getUserByUsername(identifier);
        if (dbUser != null && dbUser.password != null && dbUser.password == cleanPassword) {
          final updated = dbUser.copyWith(lastLoginAt: DateTime.now());
          await _firestoreService.saveUserProfile(updated);
          _currentUser = updated;
          await _sessionStorage.saveUserSession(updated);
          _isLoading = false;
          notifyListeners();
          return true;
        }
      } catch (_) {}

      // 2. Demo credentials check
      if ((identifier.toLowerCase() == 'admin' || identifier.contains('admin')) &&
          (cleanPassword == 'admin123' || cleanPassword == 'admin')) {
        _currentUser = UserModel(
          uid: 'admin_1',
          name: 'مدير الصالة (Admin)',
          username: 'admin',
          email: 'admin@gamelounge.iq',
          role: 'admin',
          lastLoginAt: DateTime.now(),
        );
        await _sessionStorage.saveUserSession(_currentUser!);
        _isLoading = false;
        notifyListeners();
        return true;
      } else if ((identifier.toLowerCase() == 'staff' || identifier.contains('staff')) &&
          (cleanPassword == 'staff123' || cleanPassword == 'staff')) {
        _currentUser = UserModel(
          uid: 'staff_1',
          name: 'كابتن الصالة (Staff)',
          username: 'staff',
          email: 'staff@gamelounge.iq',
          role: 'staff',
          lastLoginAt: DateTime.now(),
        );
        await _sessionStorage.saveUserSession(_currentUser!);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      // 3. Firebase Auth sign-in
      final loggedInUser = await _authService.signInWithEmailAndPassword(
        email: identifier,
        password: cleanPassword,
      );

      if (loggedInUser != null) {
        _currentUser = loggedInUser;
        await _sessionStorage.saveUserSession(loggedInUser);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _currentUser = null;
      _isLoading = false;
      _errorMessage = 'اسم المستخدم أو كلمة المرور غير صحيحة';
      notifyListeners();
      return false;
    } catch (e) {
      _currentUser = null;
      _isLoading = false;
      _errorMessage = 'فشل تسجيل الدخول: اسم المستخدم أو كلمة المرور غير صحيحة';
      notifyListeners();
      return false;
    }
  }

  /// Fast demo sign-in as Admin
  void signInAsDemoAdmin() {
    _currentUser = const UserModel(
      uid: 'admin_demo',
      name: 'مدير الصالة (Admin)',
      username: 'admin',
      email: 'admin@gamelounge.iq',
      role: 'admin',
    );
    _sessionStorage.saveUserSession(_currentUser!);
    _errorMessage = null;
    notifyListeners();
  }

  /// Fast demo sign-in as Staff
  void signInAsDemoStaff({String? name}) {
    _currentUser = UserModel(
      uid: const Uuid().v4(),
      name: name ?? 'كابتن الصالة (Staff)',
      username: 'staff',
      email: 'staff@gamelounge.iq',
      role: 'staff',
    );
    _sessionStorage.saveUserSession(_currentUser!);
    _errorMessage = null;
    notifyListeners();
  }

  /// Register a new staff user with username & password (Admin only action)
  Future<bool> registerStaffUser({
    required String name,
    required String username,
    required String password,
    required String role,
    String? email,
  }) async {
    if (!isAdmin) {
      _errorMessage = 'غير مسموح إلا للمدير فقط';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cleanUsername = username.trim().toLowerCase();
      final effectiveEmail = email?.trim() ?? '$cleanUsername@gamecenter.local';

      final newUser = UserModel(
        uid: cleanUsername,
        name: name.trim(),
        username: cleanUsername,
        email: effectiveEmail,
        password: password.trim(),
        role: role,
        createdAt: DateTime.now(),
      );

      await _firestoreService.saveUserProfile(newUser);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update an existing user/staff/admin account (Admin only action)
  Future<bool> updateStaffUser(UserModel updatedUser) async {
    if (!isAdmin) {
      _errorMessage = 'غير مسموح إلا للمدير فقط';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestoreService.saveUserProfile(updatedUser);

      // If the currently active user was updated, refresh active session and storage
      if (_currentUser?.uid == updatedUser.uid ||
          _currentUser?.username == updatedUser.username) {
        _currentUser = updatedUser;
        await _sessionStorage.saveUserSession(updatedUser);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete a staff user (Admin only action)
  Future<bool> deleteStaffUser(String uid) async {
    if (!isAdmin) {
      _errorMessage = 'غير مسموح إلا للمدير فقط';
      notifyListeners();
      return false;
    }

    try {
      await _firestoreService.deleteStaffUser(uid);

      // If the current user deleted their own account, log out immediately
      if (_currentUser?.uid == uid || _currentUser?.username == uid) {
        await signOut();
      } else {
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Sign out - Clears current session and local storage, preserving user records in Firestore
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _sessionStorage.clearUserSession();
    } catch (_) {}

    try {
      await _authService.signOut();
    } catch (_) {}

    _currentUser = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
