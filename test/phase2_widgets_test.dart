import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_center/data/models/models.dart';
import 'package:game_center/presentation/widgets/add_screen_dialog.dart';
import 'package:game_center/presentation/widgets/change_player_tier_dialog.dart';
import 'package:game_center/presentation/widgets/session_checkout_modal.dart';

import 'package:provider/provider.dart';
import 'package:game_center/providers/auth_provider.dart';
import 'package:game_center/providers/screen_provider.dart';

void main() {
  Widget createTestableWidget(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(
            initialUser: UserModel(uid: 'admin_1', name: 'المدير', role: 'admin'),
          ),
        ),
        ChangeNotifierProvider<ScreenProvider>(
          create: (_) => ScreenProvider(),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('ar', 'IQ'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ar', 'IQ')],
        home: Scaffold(body: child),
      ),
    );
  }

  group('Phase 2 Dialogs and Modals Tests', () {
    testWidgets('ChangePlayerTierDialog renders and selects 4 players', (tester) async {
      final session = GameSessionModel.startNew(
        sessionId: 'sess_switch_1',
        screenId: 'screen_1',
        screenNumber: 1,
        playerCount: 2,
        startTime: DateTime.now().subtract(const Duration(minutes: 20)),
      );

      int? newCountResult;

      await tester.pumpWidget(createTestableWidget(
        ChangePlayerTierDialog(
          session: session,
          onConfirmChange: (newCount) {
            newCountResult = newCount;
          },
        ),
      ));

      expect(find.text('تغيير عدد اللاعبين - شاشة 1'), findsOneWidget);
      expect(find.text('الفئة الحالية'), findsOneWidget);
      expect(find.text('4 لاعبين (رباعي)'), findsOneWidget);

      // Select 4 players
      await tester.tap(find.text('4 لاعبين (رباعي)'));
      await tester.pump();

      // Tap confirm button
      await tester.tap(find.text('تأكيد تغيير الفئة'));
      await tester.pump();

      expect(newCountResult, equals(4));
    });

    testWidgets('SessionCheckoutModal renders invoice breakdown and triggers payment', (tester) async {
      final startTime = DateTime.now().subtract(const Duration(hours: 1));

      var session = GameSessionModel.startNew(
        sessionId: 'sess_checkout_1',
        screenId: 'screen_4',
        screenNumber: 4,
        playerCount: 3, // 4,000 IQD / hr
        startTime: startTime,
      );

      session = session.addOrder(OrderItem.create(
        productId: 'chips_1',
        productName: 'Lays Chips',
        quantity: 2,
        unitPrice: 1500.0,
      ));

      bool paymentConfirmed = false;

      const screen = ScreenModel(
        id: 'screen_4',
        screenNumber: 4,
        isOccupied: true,
        activeSessionId: 'sess_checkout_1',
      );

      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestableWidget(
        SessionCheckoutModal(
          screen: screen,
          session: session,
          onConfirmPayment: () {
            paymentConfirmed = true;
          },
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.text('فاتورة تصفية شاشة 4'), findsOneWidget);
      expect(find.text('تفاصيل فترات اللعب (التسعير الذكي)'), findsOneWidget);
      expect(find.textContaining('Lays Chips'), findsOneWidget);
      expect(find.text('المبلغ الإجمالي الكلي المطلوب:'), findsOneWidget);
      expect(find.textContaining('تأكيد الدفع'), findsOneWidget);

      // Tap Confirm Payment
      await tester.tap(find.textContaining('تأكيد الدفع'));
      await tester.pump();

      expect(paymentConfirmed, isTrue);
    });

    testWidgets('AddScreenDialog renders and validates screen inputs', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const AddScreenDialog(),
      ));

      await tester.pumpAndSettle();

      expect(find.text('إضافة شاشة / طاولة جديدة'), findsOneWidget);
      expect(find.text('رقم الشاشة / الطاولة *'), findsOneWidget);
      expect(find.text('نوع الجهاز المشبوك (Device Type):'), findsOneWidget);
      expect(find.text('PS5'), findsOneWidget);
      expect(find.text('PC'), findsOneWidget);
      expect(find.text('إضافة الشاشة فوراً'), findsOneWidget);
    });
  });
}
