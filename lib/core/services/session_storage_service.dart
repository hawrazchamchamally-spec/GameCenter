import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/models.dart';

/// Local storage service for caching and persisting authenticated user sessions
class SessionStorageService {
  static final SessionStorageService _instance = SessionStorageService._internal();
  factory SessionStorageService() => _instance;
  SessionStorageService._internal();

  static const String _sessionKey = 'gc_active_user_session';

  /// Save active user session locally
  Future<void> saveUserSession(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userMap = user.toJson();
      // Ensure uid is included in saved map
      userMap['uid'] = user.uid;
      final jsonString = jsonEncode(userMap);
      await prefs.setString(_sessionKey, jsonString);
    } catch (e) {
      debugPrint('Error saving user session locally: $e');
    }
  }

  /// Retrieve cached user session from local storage
  Future<UserModel?> getSavedUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_sessionKey);
      if (jsonString == null || jsonString.trim().isEmpty) return null;

      final Map<String, dynamic> userMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return UserModel.fromJson(userMap, uid: userMap['uid'] as String? ?? '');
    } catch (e) {
      debugPrint('Error reading saved user session: $e');
      return null;
    }
  }

  /// Clear saved session on logout
  Future<void> clearUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
    } catch (e) {
      debugPrint('Error clearing saved user session: $e');
    }
  }
}
