import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:game_center/core/utils/thermal_printer_service.dart';
import 'package:game_center/data/models/models.dart';
import 'package:game_center/presentation/screens/reports_screen.dart';
import 'package:game_center/presentation/widgets/close_shift_dialog.dart';
import 'package:game_center/presentation/widgets/printer_settings_dialog.dart';
import 'package:game_center/presentation/widgets/reset_test_data_dialog.dart';
import 'package:game_center/providers/auth_provider.dart';
import 'package:game_center/providers/market_provider.dart';
import 'package:game_center/providers/screen_provider.dart';
import 'package:game_center/providers/shift_provider.dart';

void main() {
  group('Phase 5: ShiftModel & Calculations Tests', () {
    test('ShiftModel calculates total cash and duration correctly', () {
      final startTime = DateTime.now().subtract(const Duration(hours: 4));
      final shift = ShiftModel.startNew(
        shiftId: 'shift_1',
        staffId: 'staff_1',
        staffName: 'أحمد',
        startTime: startTime,
      );

      expect(shift.isActive, isTrue);
      expect(shift.isClosed, isFalse);

      final closedShift = shift.closeShift(
        sessionsCount: 5,
        gamingRevenue: 30000.0,
        marketRevenue: 15000.0,
        notes: 'لا توجد ملاحظات',
      );

      expect(closedShift.isClosed, isTrue);
      expect(closedShift.totalSessionsCount, equals(5));
      expect(closedShift.totalGamingRevenue, equals(30000.0));
      expect(closedShift.totalMarketRevenue, equals(15000.0));
      expect(closedShift.totalCashExpected, equals(45000.0));
      expect(closedShift.notes, equals('لا توجد ملاحظات'));
    });
  });

  group('Phase 5: Thermal Printer Service Tests', () {
    test('ThermalPrinterService generates complete ESC/POS receipt text', () {
      final printerService = ThermalPrinterService();
      final startTime = DateTime.now().subtract(const Duration(hours: 1));
      final session = GameSessionModel(
        sessionId: 'sess_123456789',
        screenId: 'screen_2',
        screenNumber: 2,
        playerCount: 2,
        pricingRate: 3000.0,
        startTime: startTime,
        endTime: startTime.add(const Duration(hours: 1)),
        isPaid: false,
        totalGamingCost: 3000.0,
        totalMarketCost: 2000.0,
        totalAmount: 5000.0,
        orders: [
          OrderItem(
            productId: 'p1',
            productName: 'بيبسي بارد',
            quantity: 2,
            unitPrice: 1000.0,
            totalPrice: 2000.0,
          ),
        ],
      );

      final receipt = printerService.generateReceiptText(
        session: session,
        staffName: 'مصطفى علي',
      );

      expect(receipt, contains('مركز الألعاب | GAME LOUNGE'));
      expect(receipt, contains('شاشة 2'));
      expect(receipt, contains('مصطفى علي'));
      expect(receipt, contains('بيبسي بارد'));
      expect(receipt, contains('3,000 د.ع'));
      expect(receipt, contains('5,000 د.ع'));
      expect(receipt, contains('شكراً لزيارتكم'));
    });
  });

  group('Phase 5: Presentation & Widgets Tests', () {
    testWidgets('ReportsScreen renders financial metrics for Admin', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => AuthProvider(
                initialUser: UserModel(uid: 'admin_1', name: 'المدير العام', role: 'admin'),
              ),
            ),
            ChangeNotifierProvider<MarketProvider>(
              create: (_) => MarketProvider(initialProducts: []),
            ),
            ChangeNotifierProvider<ShiftProvider>(
              create: (_) => ShiftProvider(),
            ),
          ],
          child: const MaterialApp(
            locale: Locale('ar', 'IQ'),
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('ar', 'IQ')],
            home: ReportsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('التقارير المالية والأرباح'), findsOneWidget);
      expect(find.text('اليوم (Today)'), findsOneWidget);
      expect(find.text('هذا الأسبوع'), findsOneWidget);
      expect(find.text('هذا الشهر'), findsOneWidget);
      expect(find.text('صافي الربح الكلي الصافي (Total Net Profit)'), findsOneWidget);
      expect(find.text('إجمالي دخل الجلسات'), findsOneWidget);
      expect(find.text('إجمالي مبيعات الماركيت'), findsOneWidget);
      expect(find.text('صافي أرباح الماركيت'), findsOneWidget);
    });

    testWidgets('ReportsScreen blocks access for Staff user', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => AuthProvider(
                initialUser: UserModel(uid: 'staff_1', name: 'موظف الصالة', role: 'staff'),
              ),
            ),
            ChangeNotifierProvider<MarketProvider>(
              create: (_) => MarketProvider(initialProducts: []),
            ),
            ChangeNotifierProvider<ShiftProvider>(
              create: (_) => ShiftProvider(),
            ),
          ],
          child: const MaterialApp(
            locale: Locale('ar', 'IQ'),
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('ar', 'IQ')],
            home: ReportsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('عذراً، هذه الصفحة مخصصة لمدير الصالة فقط'), findsOneWidget);
      expect(find.text('العودة للرئيسية'), findsOneWidget);
    });

    testWidgets('CloseShiftDialog displays active shift revenue and allows closing', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => AuthProvider(
                initialUser: UserModel(uid: 'staff_1', name: 'كابتن الصالة', role: 'staff'),
              ),
            ),
            ChangeNotifierProvider<ShiftProvider>(
              create: (_) => ShiftProvider(),
            ),
          ],
          child: const MaterialApp(
            locale: Locale('ar', 'IQ'),
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('ar', 'IQ')],
            home: Scaffold(
              body: CloseShiftDialog(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('إغلاق الجلسة وتسليم الكاش'), findsOneWidget);
      expect(find.text('المبلغ النقدي الكلي الواجب تسليمه:'), findsOneWidget);
      expect(find.text('تأكيد الإغلاق وتسليم الكاش'), findsOneWidget);
    });

    testWidgets('PrinterSettingsDialog renders Bluetooth printer options', (tester) async {
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
            body: PrinterSettingsDialog(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('إعدادات الطابعة والفواتير الحرارية'), findsOneWidget);
      expect(find.text('عرض ورق الطباعة (Paper Width):'), findsOneWidget);
      expect(find.text('58 mm'), findsOneWidget);
      expect(find.text('80 mm'), findsOneWidget);
      expect(find.text('طباعة إيصال تجريبي'), findsOneWidget);
    });

    test('ShiftProvider resetShiftToZero resets all counters to 0', () {
      final provider = ShiftProvider();
      expect(provider.currentShift?.totalGamingRevenue, isNonZero);
      expect(provider.shiftHistory.isNotEmpty, isTrue);

      provider.resetShiftToZero(staffName: 'المدير العام', staffId: 'admin_root');

      expect(provider.currentShift?.totalGamingRevenue, equals(0.0));
      expect(provider.currentShift?.totalMarketRevenue, equals(0.0));
      expect(provider.currentShift?.totalCashExpected, equals(0.0));
      expect(provider.currentShift?.totalSessionsCount, equals(0));
      expect(provider.currentShift?.staffName, equals('المدير العام'));
      expect(provider.shiftHistory, isEmpty);
    });

    testWidgets('ResetTestDataDialog enables reset button only upon entering CONFIRM', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => AuthProvider(
                initialUser: UserModel(uid: 'admin_1', name: 'المدير', role: 'admin'),
              ),
            ),
            ChangeNotifierProvider<ShiftProvider>(
              create: (_) => ShiftProvider(),
            ),
            ChangeNotifierProvider<ScreenProvider>(
              create: (_) => ScreenProvider(),
            ),
          ],
          child: const MaterialApp(
            locale: Locale('ar', 'IQ'),
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('ar', 'IQ')],
            home: Scaffold(
              body: ResetTestDataDialog(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('تصفير السجلات والبيانات المالية'), findsOneWidget);
      expect(find.text('تجهيز الصالة للافتتاح الرسمي والتشغيل الفعلي'), findsOneWidget);
      expect(find.text('ما سيتم مسحه وتصفيره فوراً:'), findsOneWidget);
      expect(find.text('ما سيتم الحفاظ عليه (لن يُحذف):'), findsOneWidget);

      final buttonFinder = find.widgetWithText(ElevatedButton, 'تصفير السجلات وتجهيز الصالة للافتتاح');
      expect(buttonFinder, findsOneWidget);

      // Button is disabled initially
      final ElevatedButton initialBtn = tester.widget(buttonFinder);
      expect(initialBtn.onPressed, isNull);

      // Enter wrong word
      await tester.enterText(find.byType(TextField), 'wrong');
      await tester.pump();
      final ElevatedButton wrongBtn = tester.widget(buttonFinder);
      expect(wrongBtn.onPressed, isNull);

      // Enter CONFIRM
      await tester.enterText(find.byType(TextField), 'CONFIRM');
      await tester.pump();
      final ElevatedButton confirmedBtn = tester.widget(buttonFinder);
      expect(confirmedBtn.onPressed, isNotNull);
    });
  });
}
