import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_center/core/theme/app_colors.dart';
import 'package:game_center/data/models/models.dart';
import 'package:game_center/presentation/widgets/screen_card_widget.dart';
import 'package:game_center/presentation/widgets/stat_badge_widget.dart';
import 'package:game_center/presentation/widgets/start_session_dialog.dart';

void main() {
  Widget createTestableWidget(Widget child) {
    return MaterialApp(
      locale: const Locale('ar', 'IQ'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar', 'IQ')],
      home: Scaffold(body: child),
    );
  }

  group('Presentation Widgets Tests', () {
    testWidgets('StatBadgeWidget renders title, value and icon', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const StatBadgeWidget(
          title: 'إجمالي الشاشات',
          value: '8 شاشات',
          icon: Icons.tv,
          accentColor: AppColors.primaryLight,
        ),
      ));

      expect(find.text('إجمالي الشاشات'), findsOneWidget);
      expect(find.text('8 شاشات'), findsOneWidget);
      expect(find.byIcon(Icons.tv), findsOneWidget);
    });

    testWidgets('ScreenCardWidget renders free/available state properly', (tester) async {
      const screen = ScreenModel(
        id: 'screen_1',
        screenNumber: 1,
        isOccupied: false,
      );

      await tester.pumpWidget(createTestableWidget(
        ScreenCardWidget(
          screen: screen,
          activeSession: null,
          onStartSession: () {},
          onEndSession: () {},
          onChangePlayers: (_) {},
          onViewDetails: () {},
        ),
      ));

      expect(find.text('شاشة 1'), findsOneWidget);
      expect(find.text('متاحة'), findsOneWidget);
      expect(find.text('بدء جلسة جديدة'), findsOneWidget);
    });

    testWidgets('ScreenCardWidget renders occupied state with active session', (tester) async {
      const screen = ScreenModel(
        id: 'screen_2',
        screenNumber: 2,
        isOccupied: true,
        activeSessionId: 'sess_1',
      );

      final session = GameSessionModel.startNew(
        sessionId: 'sess_1',
        screenId: 'screen_2',
        screenNumber: 2,
        playerCount: 3,
        startTime: DateTime.now(),
      );

      await tester.pumpWidget(createTestableWidget(
        ScreenCardWidget(
          screen: screen,
          activeSession: session,
          onStartSession: () {},
          onEndSession: () {},
          onChangePlayers: (_) {},
          onViewDetails: () {},
        ),
      ));

      expect(find.text('شاشة 2'), findsOneWidget);
      expect(find.text('مشغولة'), findsOneWidget);
      expect(find.text('3 لاعبين'), findsOneWidget);
      expect(find.text('عرض الجلسة / التفاصيل'), findsOneWidget);
      expect(find.text('إنهاء وحساب'), findsOneWidget);
    });

    testWidgets('StartSessionDialog allows selecting players and confirms', (tester) async {
      int? selectedPlayersResult;

      await tester.pumpWidget(createTestableWidget(
        StartSessionDialog(
          screenNumber: 3,
          onConfirm: (players, notes) {
            selectedPlayersResult = players;
          },
        ),
      ));

      expect(find.text('بدء جلسة - شاشة 3'), findsOneWidget);
      expect(find.text('2 لاعبين (ثنائي)'), findsOneWidget);
      expect(find.text('3 لاعبين (ثلاثي)'), findsOneWidget);
      expect(find.text('4 لاعبين (رباعي)'), findsOneWidget);

      // Tap on 4 players
      await tester.tap(find.text('4 لاعبين (رباعي)'));
      await tester.pump();

      // Tap on Start Session
      await tester.tap(find.text('بدء الجلسة'));
      await tester.pump();

      expect(selectedPlayersResult, equals(4));
    });
  });
}
