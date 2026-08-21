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

  /// Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    if (credential.user != null) {
      return await _firestoreService.getUserProfile(credential.user!.uid);
    }
    return null;
  }

  /// Register / Create a staff or admin user
  Future<UserModel> registerUser({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = UserModel(
      uid: credential.user!.uid,
      name: name,
      role: role,
      email: email,
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
