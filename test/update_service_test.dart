import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_center/core/services/update_service.dart';
import 'package:game_center/data/models/app_version_model.dart';
import 'package:game_center/presentation/widgets/update_dialog.dart';

void main() {
  group('UpdateService & UpdateDialog Tests', () {
    test('UpdateCheckResult properties and calculation', () {
      const remote = AppVersionModel(
        latestVersion: '1.5.0',
        forceUpdate: true,
        windowsUrl: 'https://example.com/win.exe',
        releaseNotes: 'ميزة جديدة لإدارة الطاولات',
      );

      final hasUpdate = remote.isNewerThan('1.0.0');
      expect(hasUpdate, isTrue);

      final result = UpdateCheckResult(
        hasUpdate: hasUpdate,
        isForced: hasUpdate && remote.forceUpdate,
        currentVersion: '1.0.0',
        remoteVersion: remote,
        downloadUrl: remote.windowsUrl,
      );

      expect(result.hasUpdate, isTrue);
      expect(result.isForced, isTrue);
      expect(result.currentVersion, equals('1.0.0'));
      expect(result.downloadUrl, equals('https://example.com/win.exe'));
    });

    testWidgets('UpdateDialog renders optional update and allows dismiss', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const result = UpdateCheckResult(
        hasUpdate: true,
        isForced: false,
        currentVersion: '1.0.0',
        remoteVersion: AppVersionModel(
          latestVersion: '1.1.0',
          forceUpdate: false,
          releaseNotes: 'إضافة خاصية الحجز السريع',
        ),
        downloadUrl: 'https://example.com/download',
      );

      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('ar', 'IQ'),
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('ar', 'IQ')],
          home: Scaffold(
            body: UpdateDialog(result: result),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('تحديث جديد متوفر للنظام! 🚀'), findsOneWidget);
      expect(find.text('v1.0.0'), findsOneWidget);
      expect(find.text('v1.1.0'), findsOneWidget);
      expect(find.text('إضافة خاصية الحجز السريع'), findsOneWidget);
      expect(find.text('تحديث النظام الآن'), findsOneWidget);
      expect(find.text('تذكيري لاحقاً'), findsOneWidget);
    });

    testWidgets('UpdateDialog renders force update without dismiss option', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      const result = UpdateCheckResult(
        hasUpdate: true,
        isForced: true,
        currentVersion: '1.0.0',
        remoteVersion: AppVersionModel(
          latestVersion: '2.0.0',
          forceUpdate: true,
          releaseNotes: 'تحديث قواعد الحسابات المالية',
        ),
        downloadUrl: 'https://example.com/download',
      );

      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('ar', 'IQ'),
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('ar', 'IQ')],
          home: Scaffold(
            body: UpdateDialog(result: result),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('تحديث إجباري للنظام'), findsOneWidget);
      expect(find.text('يجب تثبيت هذا التحديث للمتابعة لضمان دقة العمليات'), findsOneWidget);
      expect(find.text('تحديث النظام الآن'), findsOneWidget);
      // "تذكيري لاحقاً" must NOT appear for forced updates
      expect(find.text('تذكيري لاحقاً'), findsNothing);
    });
  });
}
