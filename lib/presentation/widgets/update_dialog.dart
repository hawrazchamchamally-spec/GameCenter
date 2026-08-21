import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/services/update_service.dart';
import '../../core/theme/app_colors.dart';

/// Clean, gaming-themed update modal dialog supporting force update and platform-specific links
class UpdateDialog extends StatefulWidget {
  final UpdateCheckResult result;

  const UpdateDialog({
    super.key,
    required this.result,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isLaunching = false;

  String _getPlatformDisplayName() {
    if (kIsWeb) return 'نسخة الويب (Web)';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'نظام أندرويد (Android)';
      case TargetPlatform.windows:
        return 'نظام ويندوز (Windows)';
      case TargetPlatform.iOS:
        return 'نظام آبل (iOS)';
      case TargetPlatform.macOS:
        return 'نظام ماك (macOS)';
      case TargetPlatform.linux:
        return 'نظام لينكس (Linux)';
      case TargetPlatform.fuchsia:
        return 'نظام Fuchsia';
    }
  }

  Future<void> _handleUpdateClick() async {
    setState(() => _isLaunching = true);
    final url = widget.result.downloadUrl;
    final success = await UpdateService().launchDownloadUrl(url);
    if (mounted) {
      setState(() => _isLaunching = false);
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.occupied,
            content: const Text(
              'تعذر فتح رابط التحديث تلقائياً، يرجى التأكد من اتصال الإنترنت أو التواصل مع الإدارة',
              style: TextStyle(fontSize: 12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final remote = widget.result.remoteVersion;
    final isForced = widget.result.isForced;
    final newVersion = remote?.latestVersion ?? '1.0.1';
    final releaseNotes = remote?.releaseNotes ?? 'تحسينات عامة في الأداء واستقرار العمليات.';

    return PopScope(
      canPop: !isForced,
      child: Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: isForced ? AppColors.warning.withAlpha(150) : AppColors.cyanAccent.withAlpha(120),
            width: 1.5,
          ),
        ),
        elevation: 16,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon and Title Header
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isForced ? AppColors.warning : AppColors.cyanAccent).withAlpha(30),
                          border: Border.all(
                            color: (isForced ? AppColors.warning : AppColors.cyanAccent).withAlpha(120),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          isForced ? Icons.warning_amber_rounded : Icons.rocket_launch_rounded,
                          color: isForced ? AppColors.warning : AppColors.cyanAccent,
                          size: 36,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                Text(
                  isForced ? 'تحديث إجباري للنظام' : 'تحديث جديد متوفر للنظام! 🚀',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isForced ? AppColors.warning : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                // Version Diff Pill
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'v${widget.result.currentVersion}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.arrow_forward, size: 14, color: AppColors.cyanAccent),
                        ),
                        Text(
                          'v$newVersion',
                          style: const TextStyle(
                            color: AppColors.available,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (isForced) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.warning.withAlpha(60)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_outlined, color: AppColors.warning, size: 16),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'يجب تثبيت هذا التحديث للمتابعة لضمان دقة العمليات',
                            style: TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Release notes box
                const Text(
                  'تفاصيل ومميزات الإصدار الجديد:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  constraints: const BoxConstraints(maxHeight: 140),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      releaseNotes.isNotEmpty ? releaseNotes : 'تحسينات في الاستقرار والأداء وسرعة المعالجة.',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Platform info badge
                Row(
                  children: [
                    const Icon(Icons.devices, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'المنصة المستهدفة: ${_getPlatformDisplayName()}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Actions
                ElevatedButton.icon(
                  onPressed: _isLaunching ? null : _handleUpdateClick,
                  icon: _isLaunching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Icon(Icons.download_rounded, size: 20),
                  label: Text(
                    _isLaunching ? 'جاري فتح صفحة التحميل...' : 'تحديث النظام الآن',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cyanAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                  ),
                ),

                if (!isForced) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('تذكيري لاحقاً', style: TextStyle(fontSize: 12.5)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
