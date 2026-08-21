import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:game_center/data/models/models.dart';
import 'package:game_center/presentation/screens/inventory_screen.dart';
import 'package:game_center/presentation/screens/login_screen.dart';
import 'package:game_center/presentation/widgets/staff_management_dialog.dart';
import 'package:game_center/presentation/widgets/sync_status_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:game_center/core/services/session_storage_service.dart';
import 'package:game_center/core/utils/session_timer_service.dart';
import 'package:game_center/main.dart';
import 'package:game_center/presentation/screens/home_dashboard_screen.dart';
import 'package:game_center/providers/auth_provider.dart';
import 'package:game_center/providers/market_provider.dart';
import 'package:game_center/providers/screen_provider.dart';
import 'package:game_center/providers/session_provider.dart';
import 'package:game_center/providers/shift_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final testProducts = [
    ProductModel(
      id: 'p1',
      name: 'بيبسي بارد',
      costPrice: 500.0,
      sellingPrice: 1000.0,
      stockQuantity: 24,
      category: 'مشروبات باردة',
    ),
  ];

  group('Phase 4: Auth & Role-based Logic Tests', () {
    test('AuthProvider defaults to unauthenticated on startup', () {
      final authProvider = AuthProvider(initialUser: null);
      expect(authProvider.currentUser, isNull);
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.isAdmin, isFalse);
      expect(authProvider.isStaff, isFalse);
    });

    test('SessionStorageService persists, retrieves and clears session', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = SessionStorageService();

      expect(await storage.getSavedUserSession(), isNull);

      const user = UserModel(
        uid: 'admin_persisted',
        name: 'مدير الصالة',
        username: 'admin_test',
        role: 'admin',
      );

      await storage.saveUserSession(user);
      final restored = await storage.getSavedUserSession();
      expect(restored, isNotNull);
      expect(restored?.uid, equals('admin_persisted'));
      expect(restored?.name, equals('مدير الصالة'));
      expect(restored?.isAdmin, isTrue);

      await storage.clearUserSession();
      expect(await storage.getSavedUserSession(), isNull);
    });

    test('AuthProvider switches roles correctly', () async {
      SharedPreferences.setMockInitialValues({});
      final authProvider = AuthProvider(
        initialUser: const UserModel(
          uid: 'admin_1',
          name: 'المدير',
          username: 'admin',
          email: 'admin@test.com',
          role: 'admin',
        ),
      );

      expect(authProvider.isAdmin, isTrue);
      expect(authProvider.isStaff, isFalse);

      authProvider.signInAsDemoStaff(name: 'علي الموظف');
      expect(authProvider.isAdmin, isFalse);
      expect(authProvider.isStaff, isTrue);
      expect(authProvider.currentUser?.name, equals('علي الموظف'));

      authProvider.signInAsDemoAdmin();
      expect(authProvider.isAdmin, isTrue);
      expect(authProvider.isStaff, isFalse);

      await authProvider.signOut();
      expect(authProvider.currentUser, isNull);
      expect(authProvider.isAuthenticated, isFalse);
    });
  });

  group('Phase 4: Presentation & Role Guards Tests', () {
    testWidgets('SyncStatusIndicator renders and opens details dialog on tap', (tester) async {
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
            body: Center(child: SyncStatusIndicator(isOnline: true)),
          ),
        ),
      );

      expect(find.text('متزامن لحظياً'), findsOneWidget);

      await tester.tap(find.byType(SyncStatusIndicator));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('حالة التزامن اللحظي المباشر'), findsOneWidget);
      expect(find.text('حسناً'), findsOneWidget);
    });

    testWidgets('LoginScreen renders and validates credentials fields', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => AuthProvider(
                initialUser: null,
              ),
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
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('مركز الألعاب | Game Lounge'), findsOneWidget);
      expect(find.text('تسجيل الدخول للنظام'), findsOneWidget);
      expect(find.text('دخول إلى اللوحة الرئيسية'), findsOneWidget);

      // Verify fields are completely empty on launch
      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(2));
      final usernameField = tester.widget<TextFormField>(textFields.first);
      expect(usernameField.controller?.text, isEmpty);
      final passwordField = tester.widget<TextFormField>(textFields.last);
      expect(passwordField.controller?.text, isEmpty);

      // Ensure quick login demo buttons are removed
      expect(find.text('دخول كـ مدير الصالة (Admin)'), findsNothing);
      expect(find.text('دخول كـ موظف الصالة (Staff)'), findsNothing);
    });

    testWidgets('StaffManagementDialog renders staff list and add button', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => AuthProvider(
                initialUser: UserModel(
                  uid: 'admin_1',
                  name: 'المدير',
                  role: 'admin',
                ),
              ),
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
              body: StaffManagementDialog(),
            ),
          ),
        ),
      );

      expect(find.text('إدارة الموظفين والصلاحيات'), findsOneWidget);
      expect(find.text('إضافة حساب موظف جديد'), findsOneWidget);
      expect(find.text('قائمة الموظفين الحاليين:'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsWidgets);
      expect(find.byIcon(Icons.delete_outline), findsWidgets);

      // Tap delete on the only admin account
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Should show the security alert dialog preventing deletion
      expect(find.text('تنبيه أمان النظام'), findsOneWidget);
      expect(find.text('حسناً فهمت'), findsOneWidget);

      await tester.tap(find.text('حسناً فهمت'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('InventoryScreen hides sensitive cost & edit buttons for Staff user', (tester) async {
      // 1. Staff view
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => AuthProvider(
                initialUser: UserModel(
                  uid: 'staff_1',
                  name: 'كابتن الصالة',
                  role: 'staff',
                ),
              ),
            ),
            ChangeNotifierProvider<MarketProvider>(
              create: (_) => MarketProvider(initialProducts: testProducts),
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
            home: InventoryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Staff sees product name and selling price
      expect(find.text('بيبسي بارد'), findsOneWidget);
      expect(find.text('سعر البيع:'), findsOneWidget);

      // Staff should NOT see Cost Price or Profit or Edit/Delete or Add buttons
      expect(find.text('سعر الشراء:'), findsNothing);
      expect(find.text('الربح/قطعة:'), findsNothing);
      expect(find.text('قيمة المبيعات التقديرية'), findsNothing);
      expect(find.byIcon(Icons.edit), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('InventoryScreen shows cost, profit, and edit buttons for Admin user', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // 2. Admin view
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => AuthProvider(
                initialUser: UserModel(
                  uid: 'admin_1',
                  name: 'المدير العام',
                  role: 'admin',
                ),
              ),
            ),
            ChangeNotifierProvider<MarketProvider>(
              create: (_) => MarketProvider(initialProducts: testProducts),
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
            home: InventoryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Admin sees everything
      expect(find.text('بيبسي بارد'), findsOneWidget);
      expect(find.text('سعر البيع:'), findsOneWidget);
      expect(find.text('سعر الشراء:'), findsOneWidget);
      expect(find.text('الربح/قطعة:'), findsOneWidget);
      expect(find.text('قيمة المبيعات التقديرية'), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('AuthGate strictly directs unauthenticated users to LoginScreen', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => AuthProvider(initialUser: null),
            ),
            ChangeNotifierProvider<ScreenProvider>(create: (_) => ScreenProvider()),
            ChangeNotifierProvider<MarketProvider>(create: (_) => MarketProvider()),
            ChangeNotifierProvider<SessionProvider>(create: (_) => SessionProvider()),
            ChangeNotifierProvider<ShiftProvider>(create: (_) => ShiftProvider()),
          ],
          child: const MaterialApp(
            locale: Locale('ar', 'IQ'),
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('ar', 'IQ')],
            home: AuthGate(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(HomeDashboardScreen), findsNothing);
      expect(find.text('تسجيل الدخول للنظام'), findsOneWidget);
    });

    testWidgets('AuthGate directs authenticated user to HomeDashboardScreen', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => AuthProvider(
                initialUser: const UserModel(
                  uid: 'admin_1',
                  name: 'المدير العام',
                  username: 'admin',
                  role: 'admin',
                ),
              ),
            ),
            ChangeNotifierProvider<ScreenProvider>(create: (_) => ScreenProvider()),
            ChangeNotifierProvider<MarketProvider>(create: (_) => MarketProvider()),
            ChangeNotifierProvider<SessionProvider>(create: (_) => SessionProvider()),
            ChangeNotifierProvider<ShiftProvider>(create: (_) => ShiftProvider()),
          ],
          child: const MaterialApp(
            locale: Locale('ar', 'IQ'),
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('ar', 'IQ')],
            home: AuthGate(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(HomeDashboardScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);

      // Cleanly unmount to cancel HomeDashboard periodic clock timer
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      SessionTimerService().stopGlobalTicker();
    });
  });
}
