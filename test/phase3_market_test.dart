import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:game_center/data/models/models.dart';
import 'package:game_center/presentation/screens/inventory_screen.dart';
import 'package:game_center/presentation/widgets/add_order_dialog.dart';
import 'package:game_center/presentation/widgets/product_form_dialog.dart';
import 'package:game_center/presentation/widgets/restock_market_dialog.dart';
import 'package:game_center/providers/auth_provider.dart';
import 'package:game_center/providers/market_provider.dart';

void main() {
  final testProducts = [
    ProductModel(
      id: 'p1',
      name: 'بيبسي بارد',
      costPrice: 500.0,
      sellingPrice: 1000.0,
      stockQuantity: 24,
      category: 'مشروبات باردة',
    ),
    ProductModel(
      id: 'p2',
      name: 'ريد بول كلاسيك',
      costPrice: 2000.0,
      sellingPrice: 3000.0,
      stockQuantity: 4, // low stock
      category: 'مشروبات طاقة',
    ),
    ProductModel(
      id: 'p3',
      name: 'شيبس ليز بالجبنة',
      costPrice: 500.0,
      sellingPrice: 1000.0,
      stockQuantity: 0, // out of stock
      category: 'سناكس',
    ),
  ];

  group('Phase 3: Market & Inventory Business Logic Tests', () {
    test('ProductModel correctly evaluates profit and stock states', () {
      final productAvailable = ProductModel(
        id: 'p1',
        name: 'بيبسي',
        costPrice: 500.0,
        sellingPrice: 1000.0,
        stockQuantity: 20,
        category: 'مشروبات باردة',
      );

      expect(productAvailable.profitPerUnit, equals(500.0));
      expect(productAvailable.isOutOfStock, isFalse);
      expect(productAvailable.isLowStock, isFalse);

      final productLowStock = productAvailable.copyWith(stockQuantity: 4);
      expect(productLowStock.isLowStock, isTrue);
      expect(productLowStock.isOutOfStock, isFalse);

      final productOut = productAvailable.copyWith(stockQuantity: 0);
      expect(productOut.isOutOfStock, isTrue);
    });

    test('Adding and removing market orders updates session totals correctly', () {
      final startTime = DateTime(2026, 8, 18, 14, 0, 0);

      var session = GameSessionModel.startNew(
        sessionId: 'sess_market_1',
        screenId: 'screen_1',
        screenNumber: 1,
        playerCount: 2, // 3000 IQD / hr
        startTime: startTime,
      );

      expect(session.orders.isEmpty, isTrue);
      expect(session.totalMarketCost, equals(0.0));

      // Add 2 Pepsi
      session = session.addOrder(OrderItem.create(
        productId: 'pepsi_1',
        productName: 'Pepsi',
        quantity: 2,
        unitPrice: 1000.0,
      ));

      expect(session.orders.length, equals(1));
      expect(session.totalMarketCost, equals(2000.0));

      // Add 1 Red Bull
      session = session.addOrder(OrderItem.create(
        productId: 'redbull_1',
        productName: 'Red Bull',
        quantity: 1,
        unitPrice: 3000.0,
      ));

      expect(session.orders.length, equals(2));
      expect(session.totalMarketCost, equals(5000.0));

      // Remove Pepsi
      session = session.removeOrder('pepsi_1');
      expect(session.orders.length, equals(1));
      expect(session.totalMarketCost, equals(3000.0));
    });
  });

  group('Phase 3: Presentation & Dialogs Tests', () {
    testWidgets('ProductFormDialog allows entering product details and saving', (tester) async {
      ProductModel? savedProduct;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar', 'IQ'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ar', 'IQ')],
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => ProductFormDialog(
                        onSave: (product) {
                          savedProduct = product;
                        },
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('إضافة منتج جديد للمخزن'), findsOneWidget);
      expect(find.text('اسم المنتج *'), findsOneWidget);

      // Enter name
      await tester.enterText(find.widgetWithText(TextFormField, 'اسم المنتج *'), 'شيبس برينجلز');

      // Enter cost price
      await tester.enterText(find.widgetWithText(TextFormField, 'سعر الشراء (التكلفة) *'), '1500');

      // Enter selling price
      await tester.enterText(find.widgetWithText(TextFormField, 'سعر البيع للزبون *'), '2500');

      // Enter stock
      await tester.enterText(find.widgetWithText(TextFormField, 'الكمية المتوفرة بالمخزن *'), '30');
      await tester.pump();

      // Submit
      await tester.tap(find.text('إضافة المنتج'));
      await tester.pumpAndSettle();

      expect(savedProduct, isNotNull);
      expect(savedProduct!.name, equals('شيبس برينجلز'));
      expect(savedProduct!.costPrice, equals(1500.0));
      expect(savedProduct!.sellingPrice, equals(2500.0));
      expect(savedProduct!.stockQuantity, equals(30));
    });

    testWidgets('AddOrderToSessionDialog renders products and triggers onAddProduct', (tester) async {
      ProductModel? addedProduct;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MarketProvider>(
              create: (_) => MarketProvider(initialProducts: testProducts),
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
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AddOrderToSessionDialog(
                          screenNumber: 2,
                          onAddProduct: (p) {
                            addedProduct = p;
                          },
                        ),
                      );
                    },
                    child: const Text('Open Add Order'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.tap(find.text('Open Add Order'));
      await tester.pumpAndSettle();

      expect(find.text('إضافة طلبات الماركيت - شاشة 2'), findsOneWidget);
      expect(find.text('بيبسي بارد'), findsOneWidget);
      expect(find.text('ريد بول كلاسيك'), findsOneWidget);
      expect(find.text('إلغاء'), findsOneWidget);

      // Tap add on first available product
      await tester.tap(find.widgetWithText(ElevatedButton, 'إضافة').first);
      await tester.pump();

      expect(addedProduct, isNotNull);
      expect(addedProduct!.name, equals('بيبسي بارد'));
    });

    testWidgets('InventoryScreen renders metrics and action buttons', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => AuthProvider(
                initialUser: UserModel(uid: 'admin_1', name: 'المدير', role: 'admin'),
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

      expect(find.text('إدارة الماركيت والمخزون'), findsOneWidget);
      expect(find.text('مركز إدارة المخزون والماركيت'), findsOneWidget);
      expect(find.text('إجمالي الأصناف'), findsOneWidget);
      expect(find.text('منخفض المخزون (≤5)'), findsOneWidget);
      expect(find.text('نافد من المخزن'), findsOneWidget);
      expect(find.text('بيبسي بارد'), findsOneWidget);
      expect(find.text('ريد بول كلاسيك'), findsOneWidget);
      expect(find.text('إضافة منتج جديد'), findsWidgets);
      expect(find.text('تعبئة وتوريد المخزن'), findsWidgets);
      expect(find.text('قيمة بضاعة المخزن (سعر الشراء)'), findsOneWidget);
    });

    testWidgets('RestockMarketDialog renders and validates restock inputs', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => AuthProvider(
                initialUser: UserModel(uid: 'admin_1', name: 'المدير', role: 'admin'),
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
            home: Scaffold(
              body: RestockMarketDialog(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('تعبئة وتوريد بضاعة المخزن (Restock)'), findsOneWidget);
      expect(find.text('اختر الصنف المراد توريده *'), findsOneWidget);
      expect(find.text('الكمية الواردة الجديدة (+) *'), findsOneWidget);
      expect(find.text('سعر الشراء للقطعة *'), findsOneWidget);
      expect(find.text('سعر البيع للزبون *'), findsOneWidget);
      expect(find.text('تأكيد وحفظ التوريد'), findsOneWidget);
    });
  });
}
