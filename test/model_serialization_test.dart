import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_center/data/models/models.dart';

void main() {
  group('Data Models Serialization Tests', () {
    test('ScreenModel serialization and equality', () {
      const screen = ScreenModel(
        id: 'screen_1',
        screenNumber: 1,
        isOccupied: true,
        activeSessionId: 'sess_123',
      );

      final json = screen.toJson();
      expect(json['screenNumber'], equals(1));
      expect(json['isOccupied'], equals(true));
      expect(json['activeSessionId'], equals('sess_123'));

      final restored = ScreenModel.fromJson(json, id: 'screen_1');
      expect(restored.id, equals('screen_1'));
      expect(restored.screenNumber, equals(1));
      expect(restored.isOccupied, equals(true));
      expect(restored.activeSessionId, equals('sess_123'));
    });

    test('ProductModel serialization and profit calculations', () {
      final product = ProductModel(
        id: 'prod_1',
        name: 'Red Bull',
        costPrice: 2000.0,
        sellingPrice: 3000.0,
        stockQuantity: 25,
        category: 'مشروبات طاقة',
      );

      expect(product.profitPerUnit, equals(1000.0));
      expect(product.isOutOfStock, isFalse);

      final json = product.toJson();
      final restored = ProductModel.fromJson(json, id: 'prod_1');
      expect(restored.name, equals('Red Bull'));
      expect(restored.costPrice, equals(2000.0));
      expect(restored.sellingPrice, equals(3000.0));
      expect(restored.stockQuantity, equals(25));
    });

    test('OrderItem serialization and total price helper', () {
      final order = OrderItem.create(
        productId: 'indomie_1',
        productName: 'Indomie Noodles',
        quantity: 3,
        unitPrice: 1500.0,
      );

      expect(order.totalPrice, equals(4500.0));

      final map = order.toMap();
      expect(map['productId'], equals('indomie_1'));
      expect(map['itemId'], equals('indomie_1'));
      expect(map['productName'], equals('Indomie Noodles'));
      expect(map['title'], equals('Indomie Noodles'));
      expect(map['quantity'], equals(3));
      expect(map['unitPrice'], equals(1500.0));
      expect(map['price'], equals(1500.0));
      expect(map['totalPrice'], equals(4500.0));
      expect(map['orderedAt'], isA<String>());

      final restored = OrderItem.fromMap(map);
      expect(restored.productId, equals('indomie_1'));
      expect(restored.itemId, equals('indomie_1'));
      expect(restored.productName, equals('Indomie Noodles'));
      expect(restored.title, equals('Indomie Noodles'));
      expect(restored.quantity, equals(3));
      expect(restored.unitPrice, equals(1500.0));
      expect(restored.price, equals(1500.0));
      expect(restored.totalPrice, equals(4500.0));

      // Test parsing with alternative keys (itemId, title, price)
      final altMap = <String, dynamic>{
        'itemId': 'pepsi_1',
        'title': 'Pepsi Can',
        'quantity': 2,
        'price': 1000.0,
        'totalPrice': 2000.0,
      };
      final altRestored = OrderItem.fromMap(altMap);
      expect(altRestored.productId, equals('pepsi_1'));
      expect(altRestored.productName, equals('Pepsi Can'));
      expect(altRestored.quantity, equals(2));
      expect(altRestored.unitPrice, equals(1000.0));
      expect(altRestored.totalPrice, equals(2000.0));
    });

    test('GameSessionModel safe orders parsing from dynamic List with mixed maps', () {
      final sessionMap = <String, dynamic>{
        'sessionId': 'sess_1',
        'screenId': 'screen_1',
        'screenNumber': 1,
        'playerCount': 2,
        'pricingRate': 3000.0,
        'orders': <dynamic>[
          {
            'productId': 'coke_1',
            'productName': 'Coca Cola',
            'quantity': 2,
            'unitPrice': 1000.0,
            'totalPrice': 2000.0,
          },
          {
            'productId': 'lays_1',
            'productName': 'Lays Chips',
            'quantity': 1,
            'unitPrice': 1500.0,
            'totalPrice': 1500.0,
          },
        ],
        'rateHistory': <dynamic>[
          {
            'playerCount': 2,
            'ratePerHour': 3000.0,
            'startedAt': '2026-08-18T10:00:00.000Z',
          }
        ],
      };

      final session = GameSessionModel.fromMap(sessionMap);
      expect(session.orders.length, equals(2));
      expect(session.orders[0].productName, equals('Coca Cola'));
      expect(session.orders[0].quantity, equals(2));
      expect(session.orders[1].productName, equals('Lays Chips'));
      expect(session.calculateTotalMarketCost(), equals(3500.0));

      // Test toMap conversion
      final exportedMap = session.toMap();
      expect(exportedMap['orders'], isA<List>());
      expect((exportedMap['orders'] as List).length, equals(2));
      expect((exportedMap['orders'] as List)[0]['productId'], equals('coke_1'));
    });

    test('UserModel serialization and role check', () {
      const admin = UserModel(
        uid: 'admin_1',
        name: 'أحمد الإداري',
        role: 'admin',
        email: 'admin@lounge.com',
      );

      expect(admin.isAdmin, isTrue);
      expect(admin.isStaff, isFalse);

      final json = admin.toJson();
      final restored = UserModel.fromJson(json, uid: 'admin_1');
      expect(restored.name, equals('أحمد الإداري'));
      expect(restored.role, equals('admin'));
    });

    test('ReceiptSettingsModel serialization and defaults', () {
      const defaultSettings = ReceiptSettingsModel();
      expect(defaultSettings.centerName, contains('مركز الألعاب'));
      expect(defaultSettings.phoneNumber, isNotEmpty);

      final custom = defaultSettings.copyWith(
        centerName: 'صالة الألعاب الذهبية',
        phoneNumber: '07709999999',
      );
      final map = custom.toMap();
      expect(map['centerName'], equals('صالة الألعاب الذهبية'));
      expect(map['phoneNumber'], equals('07709999999'));

      final restored = ReceiptSettingsModel.fromMap(map);
      expect(restored.centerName, equals('صالة الألعاب الذهبية'));
      expect(restored.phoneNumber, equals('07709999999'));
    });

    test('PricingSettingsModel serialization and rate lookup', () {
      const defaultPricing = PricingSettingsModel();
      expect(defaultPricing.getRateForPlayers(2), equals(3000.0));
      expect(defaultPricing.getRateForPlayers(3), equals(4000.0));
      expect(defaultPricing.getRateForPlayers(4), equals(5000.0));

      final customPricing = const PricingSettingsModel(
        rate2Players: 3500.0,
        rate3Players: 4500.0,
        rate4Players: 6000.0,
      );
      expect(customPricing.getRateForPlayers(2), equals(3500.0));
      expect(customPricing.getRateForPlayers(4), equals(6000.0));

      final map = customPricing.toMap();
      final restored = PricingSettingsModel.fromMap(map);
      expect(restored.rate2Players, equals(3500.0));
      expect(restored.rate3Players, equals(4500.0));
      expect(restored.rate4Players, equals(6000.0));
    });

    test('GameSessionModel.endSession supports custom discounted totalAmount', () {
      final now = DateTime.now();
      final session = GameSessionModel.startNew(
        sessionId: 'sess_custom_test',
        screenId: 'screen_1',
        screenNumber: 1,
        playerCount: 2,
        startTime: now.subtract(const Duration(hours: 1)),
      ).addOrder(
        OrderItem.create(productId: 'p1', productName: 'Pepsi', quantity: 2, unitPrice: 1000.0),
      );

      // Total without custom discount is 3000 (gaming) + 2000 (market) = 5000
      final standardEnd = session.endSession(endAt: now);
      expect(standardEnd.totalGamingCost, equals(3000.0));
      expect(standardEnd.totalMarketCost, equals(2000.0));
      expect(standardEnd.totalAmount, equals(5000.0));

      // With custom discount (e.g. 4000 IQD received)
      final discountedEnd = session.endSession(endAt: now, customTotalAmount: 4000.0);
      expect(discountedEnd.totalGamingCost, equals(3000.0));
      expect(discountedEnd.totalMarketCost, equals(2000.0));
      expect(discountedEnd.totalAmount, equals(4000.0));
    });

    test('GameSessionModel supports budget-based session and countdown calculations', () {
      final now = DateTime.now();
      final startTime = now.subtract(const Duration(minutes: 40));
      final session = GameSessionModel.startNew(
        sessionId: 'sess_budget_1',
        screenId: 'screen_2',
        screenNumber: 2,
        playerCount: 2,
        startTime: startTime,
        isBudgetBased: true,
        targetBudget: 5000.0,
        targetDurationMinutes: 100, // 100 minutes total
      );

      expect(session.isBudgetBased, isTrue);
      expect(session.targetBudget, equals(5000.0));
      expect(session.targetDurationMinutes, equals(100));
      expect(session.allocatedEndTime, isNotNull);
      expect(session.isTimeExpired(atTime: now), isFalse);

      // Remaining should be approx 60 minutes
      final remaining = session.getRemainingDuration(atTime: now);
      expect(remaining.inMinutes, equals(60));

      // Progress should be approx 40% (40 / 100)
      final progress = session.getBudgetProgressPercentage(atTime: now);
      expect(progress, closeTo(0.40, 0.05));

      // Test expiration after 110 minutes
      final futureTime = startTime.add(const Duration(minutes: 110));
      expect(session.isTimeExpired(atTime: futureTime), isTrue);
      expect(session.getRemainingDuration(atTime: futureTime), equals(Duration.zero));
      expect(session.getBudgetProgressPercentage(atTime: futureTime), equals(1.0));

      // Test serialization toMap and fromMap
      final map = session.toMap();
      expect(map['isBudgetBased'], isTrue);
      expect(map['targetBudget'], equals(5000.0));
      expect(map['targetDurationMinutes'], equals(100));

      final restored = GameSessionModel.fromMap(map);
      expect(restored.isBudgetBased, isTrue);
      expect(restored.targetBudget, equals(5000.0));
      expect(restored.targetDurationMinutes, equals(100));
      expect(restored.allocatedEndTime, isNotNull);
    });

    test('ScreenModel with deviceType and sectionName serialization', () {
      const screen = ScreenModel(
        id: 'screen_9',
        screenNumber: 9,
        name: 'VIP Room Alpha',
        deviceType: 'PS5',
        sectionName: 'غرفة VIP 1',
        isOccupied: false,
      );

      expect(screen.nameArabic, equals('VIP Room Alpha'));

      final json = screen.toJson();
      expect(json['name'], equals('VIP Room Alpha'));
      expect(json['deviceType'], equals('PS5'));
      expect(json['sectionName'], equals('غرفة VIP 1'));

      final restored = ScreenModel.fromJson(json, id: 'screen_9');
      expect(restored.name, equals('VIP Room Alpha'));
      expect(restored.deviceType, equals('PS5'));
      expect(restored.sectionName, equals('غرفة VIP 1'));
    });

    test('RestockTransactionModel serialization and calculations', () {
      final now = DateTime.now();
      final restock = RestockTransactionModel(
        id: 'restock_1',
        productId: 'prod_redbull',
        productName: 'ريد بول كلاسيك',
        incomingQuantity: 24,
        previousStock: 4,
        newStock: 28,
        unitCostPrice: 2000.0,
        unitSellingPrice: 3000.0,
        totalCostAmount: 48000.0,
        approvedByAdmin: 'أحمد الإداري',
        timestamp: now,
        notes: 'وصل توريد رقم 104',
      );

      expect(restock.totalCostAmount, equals(48000.0));
      expect(restock.newStock, equals(28));

      final map = restock.toMap();
      expect(map['incomingQuantity'], equals(24));
      expect(map['totalCostAmount'], equals(48000.0));
      expect(map['approvedByAdmin'], equals('أحمد الإداري'));

      final restored = RestockTransactionModel.fromMap(map, id: 'restock_1');
      expect(restored.id, equals('restock_1'));
      expect(restored.productName, equals('ريد بول كلاسيك'));
      expect(restored.incomingQuantity, equals(24));
      expect(restored.totalCostAmount, equals(48000.0));
    });

    test('AppVersionModel serialization, semantic comparison and platform URLs', () {
      final now = DateTime.now();
      final version = AppVersionModel(
        latestVersion: '1.2.0',
        forceUpdate: true,
        androidUrl: 'https://example.com/app.apk',
        windowsUrl: 'https://example.com/setup.exe',
        iosUrl: 'https://example.com/ios',
        webUrl: 'https://gamecenter.web.app',
        releaseNotes: 'إصلاحات أمنية وتسريع التقارير',
        updatedAt: now,
      );

      // Semantic version comparison
      expect(version.isNewerThan('1.0.0'), isTrue);
      expect(version.isNewerThan('1.1.9'), isTrue);
      expect(version.isNewerThan('1.2.0'), isFalse);
      expect(version.isNewerThan('1.2.1'), isFalse);
      expect(version.isNewerThan('2.0.0'), isFalse);
      expect(version.isNewerThan('v1.0.0+5'), isTrue);

      // Platform URLs
      expect(version.getDownloadUrlForPlatform(TargetPlatform.android), equals('https://example.com/app.apk'));
      expect(version.getDownloadUrlForPlatform(TargetPlatform.windows), equals('https://example.com/setup.exe'));
      expect(version.getDownloadUrlForPlatform(TargetPlatform.iOS), equals('https://example.com/ios'));
      expect(version.getDownloadUrlForPlatform(TargetPlatform.android, isWeb: true), equals('https://gamecenter.web.app'));

      // Serialization toMap / fromMap
      final map = version.toMap();
      expect(map['latest_version'], equals('1.2.0'));
      expect(map['force_update'], isTrue);
      expect(map['android_url'], equals('https://example.com/app.apk'));
      expect(map['release_notes'], equals('إصلاحات أمنية وتسريع التقارير'));

      final restored = AppVersionModel.fromMap(map);
      expect(restored.latestVersion, equals('1.2.0'));
      expect(restored.forceUpdate, isTrue);
      expect(restored.androidUrl, equals('https://example.com/app.apk'));
      expect(restored.windowsUrl, equals('https://example.com/setup.exe'));
      expect(restored.releaseNotes, equals('إصلاحات أمنية وتسريع التقارير'));
    });
  });
}
