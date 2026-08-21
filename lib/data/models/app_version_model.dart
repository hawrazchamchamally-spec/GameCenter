import 'package:flutter/foundation.dart';

/// Model representing the remote version configuration stored in Firestore (`app_config/version_info`)
class AppVersionModel {
  final String latestVersion;
  final bool forceUpdate;
  final String androidUrl;
  final String windowsUrl;
  final String iosUrl;
  final String webUrl;
  final String releaseNotes;
  final DateTime? updatedAt;

  const AppVersionModel({
    required this.latestVersion,
    this.forceUpdate = false,
    this.androidUrl = '',
    this.windowsUrl = '',
    this.iosUrl = '',
    this.webUrl = '',
    this.releaseNotes = '',
    this.updatedAt,
  });

  /// Factory constructor from Firestore Map
  factory AppVersionModel.fromMap(Map<String, dynamic> map) {
    DateTime? parsedDate;
    if (map['updated_at'] != null) {
      if (map['updated_at'] is String) {
        parsedDate = DateTime.tryParse(map['updated_at'] as String);
      } else {
        try {
          parsedDate = (map['updated_at'] as dynamic).toDate();
        } catch (_) {
          parsedDate = null;
        }
      }
    }

    return AppVersionModel(
      latestVersion: map['latest_version']?.toString() ?? '1.0.0',
      forceUpdate: map['force_update'] == true,
      androidUrl: map['android_url']?.toString() ?? '',
      windowsUrl: map['windows_url']?.toString() ?? '',
      iosUrl: map['ios_url']?.toString() ?? '',
      webUrl: map['web_url']?.toString() ?? '',
      releaseNotes: map['release_notes']?.toString() ?? '',
      updatedAt: parsedDate,
    );
  }

  /// Converts model to Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'latest_version': latestVersion,
      'force_update': forceUpdate,
      'android_url': androidUrl,
      'windows_url': windowsUrl,
      'ios_url': iosUrl,
      'web_url': webUrl,
      'release_notes': releaseNotes,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Returns the corresponding download / store URL based on current platform
  String getDownloadUrlForPlatform(TargetPlatform platform, {bool isWeb = false}) {
    if (isWeb) {
      if (webUrl.isNotEmpty) return webUrl;
    }
    switch (platform) {
      case TargetPlatform.android:
        return androidUrl.isNotEmpty ? androidUrl : (webUrl.isNotEmpty ? webUrl : windowsUrl);
      case TargetPlatform.windows:
        return windowsUrl.isNotEmpty ? windowsUrl : (webUrl.isNotEmpty ? webUrl : androidUrl);
      case TargetPlatform.iOS:
        return iosUrl.isNotEmpty ? iosUrl : (webUrl.isNotEmpty ? webUrl : androidUrl);
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return webUrl.isNotEmpty ? webUrl : (windowsUrl.isNotEmpty ? windowsUrl : androidUrl);
    }
  }

  /// Checks if [latestVersion] is strictly newer than [currentVersion]
  /// Supports semantic version formats like "1.0.1", "1.0.0+1", "v1.2.0"
  bool isNewerThan(String currentVersion) {
    final cleanCurrent = _cleanVersion(currentVersion);
    final cleanLatest = _cleanVersion(latestVersion);

    if (cleanCurrent.isEmpty || cleanLatest.isEmpty) return false;

    final currentParts = _parseVersionParts(cleanCurrent);
    final latestParts = _parseVersionParts(cleanLatest);

    final maxLen = currentParts.length > latestParts.length ? currentParts.length : latestParts.length;

    for (int i = 0; i < maxLen; i++) {
      final cur = i < currentParts.length ? currentParts[i] : 0;
      final lat = i < latestParts.length ? latestParts[i] : 0;

      if (lat > cur) return true;
      if (lat < cur) return false;
    }

    return false;
  }

  static String _cleanVersion(String v) {
    String res = v.trim();
    if (res.startsWith('v') || res.startsWith('V')) {
      res = res.substring(1).trim();
    }
    final plusIdx = res.indexOf('+');
    if (plusIdx != -1) {
      res = res.substring(0, plusIdx).trim();
    }
    final dashIdx = res.indexOf('-');
    if (dashIdx != -1) {
      res = res.substring(0, dashIdx).trim();
    }
    return res;
  }

  static List<int> _parseVersionParts(String v) {
    return v
        .split('.')
        .map((part) => int.tryParse(part.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
  }

  @override
  String toString() {
    return 'AppVersionModel(latestVersion: $latestVersion, forceUpdate: $forceUpdate, releaseNotes: $releaseNotes)';
  }
}
