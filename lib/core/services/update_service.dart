import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/app_version_model.dart';
import '../../data/services/firestore_service.dart';
import '../../presentation/widgets/update_dialog.dart';

/// Result object returned by [UpdateService.checkForUpdates]
class UpdateCheckResult {
  final bool hasUpdate;
  final bool isForced;
  final String currentVersion;
  final AppVersionModel? remoteVersion;
  final String downloadUrl;

  const UpdateCheckResult({
    required this.hasUpdate,
    required this.currentVersion,
    this.isForced = false,
    this.remoteVersion,
    this.downloadUrl = '',
  });
}

/// Service managing remote updates across Android, iOS, Windows, and Web
class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  final FirestoreService _firestoreService = FirestoreService();
  String? _cachedCurrentVersion;
  bool _isChecking = false;

  /// Get current app version dynamically from platform package info
  Future<String> getCurrentVersion() async {
    if (_cachedCurrentVersion != null) return _cachedCurrentVersion!;
    try {
      final info = await PackageInfo.fromPlatform();
      _cachedCurrentVersion = info.version.isNotEmpty ? info.version : '1.0.0';
      return _cachedCurrentVersion!;
    } catch (e) {
      debugPrint('Error getting PackageInfo: $e');
      _cachedCurrentVersion = '1.0.0';
      return _cachedCurrentVersion!;
    }
  }

  /// Check remote Firestore configuration for updates
  Future<UpdateCheckResult> checkForUpdates({
    FirestoreService? firestoreOverride,
    String? currentVersionOverride,
  }) async {
    final currentVersion = currentVersionOverride ?? await getCurrentVersion();
    final firestore = firestoreOverride ?? _firestoreService;

    try {
      final remoteConfig = await firestore.getVersionInfo();
      if (remoteConfig == null) {
        return UpdateCheckResult(
          hasUpdate: false,
          currentVersion: currentVersion,
        );
      }

      final isNewer = remoteConfig.isNewerThan(currentVersion);
      final downloadUrl = remoteConfig.getDownloadUrlForPlatform(
        defaultTargetPlatform,
        isWeb: kIsWeb,
      );

      return UpdateCheckResult(
        hasUpdate: isNewer,
        isForced: isNewer && remoteConfig.forceUpdate,
        currentVersion: currentVersion,
        remoteVersion: remoteConfig,
        downloadUrl: downloadUrl,
      );
    } catch (e) {
      debugPrint('Error during update check: $e');
      return UpdateCheckResult(
        hasUpdate: false,
        currentVersion: currentVersion,
      );
    }
  }

  /// Launch update download link or app store page
  Future<bool> launchDownloadUrl(String url) async {
    if (url.trim().isEmpty) return false;
    try {
      final uri = Uri.parse(url.trim());
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Error launching update URL: $e');
      return false;
    }
  }

  /// Check for updates and optionally present the modal dialog
  Future<void> checkAndShowPrompt(
    BuildContext context, {
    bool isManualCheck = false,
  }) async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      final result = await checkForUpdates();

      if (!context.mounted) return;

      if (result.hasUpdate && result.remoteVersion != null) {
        showDialog(
          context: context,
          barrierDismissible: !result.isForced,
          builder: (_) => UpdateDialog(result: result),
        );
      } else if (isManualCheck) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1B2838),
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Color(0xFF00E5FF), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'أنت تستخدم أحدث إصدار من التطبيق (v${result.currentVersion})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      _isChecking = false;
    }
  }
}
