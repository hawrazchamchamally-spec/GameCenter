import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

/// Firebase Authentication Service for Game Lounge
class AuthService {
  FirebaseAuth? _authInstance;
  final FirestoreService _firestoreService;

  AuthService({
    FirebaseAuth? auth,
    FirestoreService? firestoreService,
  })  : _authInstance = auth,
        _firestoreService = firestoreService ?? FirestoreService();

  FirebaseAuth get _auth {
    if (_authInstance != null) return _authInstance!;
    try {
      _authInstance = FirebaseAuth.instance;
      return _authInstance!;
    } catch (e) {
      throw StateError('Firebase Auth not initialized: $e');
    }
  }

  /// Stream of auth state changes
  Stream<User?> get authStateChanges {
    try {
      return _auth.authStateChanges();
    } catch (_) {
      return Stream.value(null);
    }
  }

  /// Current Firebase User
  User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Sign in with email or username and password
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final identifier = email.trim();
    final effectiveEmail = identifier.contains('@')
        ? identifier
        : '${identifier.toLowerCase()}@gamecenter.local';

    // 1. Direct check from Firestore database
    try {
      final dbUser = await _firestoreService.getUserByUsername(identifier);
      if (dbUser != null) {
        if (dbUser.password != null && dbUser.password == password.trim()) {
          final updated = dbUser.copyWith(lastLoginAt: DateTime.now());
          await _firestoreService.saveUserProfile(updated);
          return updated;
        }
      }
    } catch (_) {}

    // 2. Firebase Auth verification fallback
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: effectiveEmail,
        password: password.trim(),
      );

      if (credential.user != null) {
        final profile = await _firestoreService.getUserProfile(credential.user!.uid);
        return profile ??
            UserModel(
              uid: credential.user!.uid,
              name: credential.user!.displayName ?? identifier,
              username: identifier.contains('@') ? identifier.split('@').first : identifier,
              email: credential.user!.email ?? effectiveEmail,
              role: 'admin',
              lastLoginAt: DateTime.now(),
            );
      }
    } catch (e) {
      // If neither matches, throw error for caller to handle
      throw Exception('بيانات تسجيل الدخول غير صحيحة');
    }
    return null;
  }

  /// Register / Create a staff or admin user
  Future<UserModel> registerUser({
    required String name,
    required String username,
    required String password,
    required String role,
    String? email,
  }) async {
    final cleanUsername = username.trim().toLowerCase();
    final effectiveEmail = email?.trim() ?? '$cleanUsername@gamecenter.local';

    String uid = cleanUsername;

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: effectiveEmail,
        password: password.trim(),
      );
      if (credential.user != null) {
        uid = credential.user!.uid;
      }
    } catch (_) {
      // Firebase auth might fail if offline or virtual domain, proceed with Firestore storage
    }

    final user = UserModel(
      uid: cleanUsername.isNotEmpty ? cleanUsername : uid,
      name: name.trim(),
      username: cleanUsername,
      role: role,
      email: effectiveEmail,
      password: password.trim(),
      createdAt: DateTime.now(),
    );

    await _firestoreService.saveUserProfile(user);
    return user;
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {}
  }
}
