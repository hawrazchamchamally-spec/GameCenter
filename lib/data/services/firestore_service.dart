import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../models/models.dart';

/// Comprehensive Firestore Service for Gaming Lounge Management
class FirestoreService {
  FirebaseFirestore? _firestoreInstance;
  static const Uuid _uuid = Uuid();

  FirestoreService({FirebaseFirestore? firestore}) : _firestoreInstance = firestore;

  FirebaseFirestore get _firestore {
    if (_firestoreInstance != null) return _firestoreInstance!;
    try {
      _firestoreInstance = FirebaseFirestore.instance;
      return _firestoreInstance!;
    } catch (e) {
      throw StateError('Firebase is not initialized: $e');
    }
  }

  // Collection References
  CollectionReference<Map<String, dynamic>> get _screensCol =>
      _firestore.collection(AppConstants.screensCollection);

  CollectionReference<Map<String, dynamic>> get _sessionsCol =>
      _firestore.collection(AppConstants.sessionsCollection);

  CollectionReference<Map<String, dynamic>> get _productsCol =>
      _firestore.collection(AppConstants.productsCollection);

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection(AppConstants.usersCollection);

  CollectionReference<Map<String, dynamic>> get _appConfigCol =>
      _firestore.collection(AppConstants.appConfigCollection);

  // ==========================================
  // 1. SCREENS OPERATIONS (1 to 8 Screens)
  // ==========================================

  /// Stream of all 8 screens ordered by screenNumber
  Stream<List<ScreenModel>> getScreensStream() {
    try {
      return _screensCol
          .orderBy('screenNumber', descending: false)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => ScreenModel.fromFirestore(doc))
              .toList())
          .handleError((_) => <ScreenModel>[]);
    } catch (_) {
      return Stream.value(<ScreenModel>[]);
    }
  }

  /// Get a single screen by ID safely
  Future<ScreenModel?> getScreenById(String screenId) async {
    if (screenId.isEmpty) return null;
    try {
      final doc = await _screensCol.doc(screenId).get();
      if (!doc.exists) return null;
      return ScreenModel.fromFirestore(doc);
    } catch (_) {
      return null;
    }
  }

  /// Initialize and seed the 8 default screens if not already present
  Future<void> initializeDefaultScreens() async {
    try {
      final snapshot = await _screensCol.get();

      // If screens collection is empty or missing screens, seed all 8 screens
      if (snapshot.docs.isEmpty) {
        final batch = _firestore.batch();

        for (int i = 1; i <= AppConstants.totalScreensCount; i++) {
          final docRef = _screensCol.doc('screen_$i');
          final screen = ScreenModel(
            id: 'screen_$i',
            screenNumber: i,
            isOccupied: false,
            activeSessionId: null,
            lastSessionEndedAt: null,
          );
          batch.set(docRef, screen.toJson());
        }

        await batch.commit();
      } else if (snapshot.docs.length < AppConstants.totalScreensCount) {
        // Seed missing screens
        final existingNumbers = snapshot.docs
            .map((d) => (d.data()['screenNumber'] as num?)?.toInt() ?? 0)
            .toSet();

        final batch = _firestore.batch();
        for (int i = 1; i <= AppConstants.totalScreensCount; i++) {
          if (!existingNumbers.contains(i)) {
            final docRef = _screensCol.doc('screen_$i');
            final screen = ScreenModel(
              id: 'screen_$i',
              screenNumber: i,
              isOccupied: false,
              activeSessionId: null,
              lastSessionEndedAt: null,
            );
            batch.set(docRef, screen.toJson());
          }
        }
        await batch.commit();
      }
    } catch (e) {
      // Ignore or log error
    }
  }

  /// Update screen details
  Future<void> updateScreen(ScreenModel screen) async {
    if (screen.id.isEmpty) return;
    try {
      await _screensCol.doc(screen.id).set(screen.toJson(), SetOptions(merge: true));
    } catch (_) {}
  }

  // ==========================================
  // 2. GAME SESSIONS OPERATIONS
  // ==========================================

  /// Starts a new session on a specific screen and marks screen as occupied atomically
  Future<GameSessionModel> startSession({
    required String screenId,
    required int screenNumber,
    required int playerCount,
    String? createdBy,
    String? notes,
    bool isBudgetBased = false,
    double? targetBudget,
    int? targetDurationMinutes,
    DateTime? allocatedEndTime,
  }) async {
    final effectiveScreenId = screenId.isNotEmpty ? screenId : 'screen_$screenNumber';
    final sessionId = _uuid.v4();
    final newSession = GameSessionModel.startNew(
      sessionId: sessionId,
      screenId: effectiveScreenId,
      screenNumber: screenNumber,
      playerCount: playerCount,
      createdBy: createdBy,
      notes: notes,
      isBudgetBased: isBudgetBased,
      targetBudget: targetBudget,
      targetDurationMinutes: targetDurationMinutes,
      allocatedEndTime: allocatedEndTime,
    );

    final batch = _firestore.batch();

    // 1. Create session document
    final sessionRef = _sessionsCol.doc(sessionId);
    batch.set(sessionRef, newSession.toJson());

    // 2. Update screen status to occupied with activeSessionId
    final screenRef = _screensCol.doc(effectiveScreenId);
    batch.set(screenRef, {
      'id': effectiveScreenId,
      'screenNumber': screenNumber,
      'isOccupied': true,
      'activeSessionId': sessionId,
    }, SetOptions(merge: true));

    await batch.commit();
    return newSession;
  }

  /// Stream of a specific session by ID safely
  Stream<GameSessionModel?> getSessionStream(String sessionId) {
    if (sessionId.isEmpty) return Stream.value(null);
    try {
      return _sessionsCol.doc(sessionId).snapshots().map((doc) {
        if (!doc.exists) return null;
        return GameSessionModel.fromFirestore(doc);
      }).handleError((_) => null);
    } catch (_) {
      return Stream.value(null);
    }
  }

  /// Get active session for a specific screen safely
  Future<GameSessionModel?> getActiveSessionForScreen(String screenId) async {
    if (screenId.isEmpty) return null;
    try {
      final query = await _sessionsCol
          .where('screenId', isEqualTo: screenId)
          .where('endTime', isNull: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;
      return GameSessionModel.fromFirestore(query.docs.first);
    } catch (_) {
      return null;
    }
  }

  /// Stream of all active sessions safely
  Stream<List<GameSessionModel>> getActiveSessionsStream() {
    try {
      return _sessionsCol
          .where('endTime', isNull: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => GameSessionModel.fromFirestore(doc))
              .toList())
          .handleError((_) => <GameSessionModel>[]);
    } catch (_) {
      return Stream.value(<GameSessionModel>[]);
    }
  }

  /// Stream of completed sessions safely
  Stream<List<GameSessionModel>> getCompletedSessionsStream({int limit = 50}) {
    try {
      return _sessionsCol
          .where('endTime', isNull: false)
          .orderBy('endTime', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => GameSessionModel.fromFirestore(doc))
              .toList())
          .handleError((_) => <GameSessionModel>[]);
    } catch (_) {
      return Stream.value(<GameSessionModel>[]);
    }
  }

  /// Update player count in an active session (closes current interval, starts new one)
  Future<void> changeSessionPlayerCount({
    required String sessionId,
    required int newPlayerCount,
  }) async {
    final sessionDoc = await _sessionsCol.doc(sessionId).get();
    if (!sessionDoc.exists) return;

    final currentSession = GameSessionModel.fromFirestore(sessionDoc);
    final updatedSession = currentSession.changePlayerCount(newPlayerCount);

    await _sessionsCol.doc(sessionId).update(updatedSession.toJson());
  }

  /// Adds an order to the active session and decrements product stock without transactions (safe on Web & all platforms)
  Future<void> addOrderItemToSession({
    required String sessionId,
    required OrderItem item,
  }) async {
    if (sessionId.isEmpty || item.productId.isEmpty) return;

    try {
      final docRef = _sessionsCol.doc(sessionId);
      final snapshot = await docRef.get();
      if (!snapshot.exists) return;

      final sessionData = snapshot.data() ?? {};
      final session = GameSessionModel.fromMap(sessionData, id: snapshot.id);

      final updatedSession = session.addOrder(item);
      final updatedOrdersList = updatedSession.orders.map((o) => o.toMap()).toList();
      final totalMarket = updatedSession.totalMarketCost;
      final totalAmount = updatedSession.totalGamingCost + totalMarket;

      await docRef.set({
        'orders': updatedOrdersList,
        'totalMarketCost': totalMarket,
        'totalMarketAmount': totalMarket,
        'totalAmount': totalAmount,
      }, SetOptions(merge: true));

      // Decrement product stock directly
      final targetProductId = item.productId.isNotEmpty ? item.productId : item.itemId;
      if (targetProductId.isNotEmpty) {
        final productRef = _productsCol.doc(targetProductId);
        final productSnapshot = await productRef.get();
        if (productSnapshot.exists) {
          await productRef.update({
            'stockQuantity': FieldValue.increment(-item.quantity),
            'stock': FieldValue.increment(-item.quantity),
          });
        }
      }
    } catch (e) {
      debugPrint('Detailed Error in addOrderItemToSession: $e');
    }
  }

  /// Adds multiple orders to the active session and decrements stock in batch
  Future<void> addMultipleOrderItemsToSession({
    required String sessionId,
    required List<OrderItem> items,
  }) async {
    if (sessionId.isEmpty || items.isEmpty) return;

    try {
      final docRef = _sessionsCol.doc(sessionId);
      final snapshot = await docRef.get();
      if (!snapshot.exists) return;

      final sessionData = snapshot.data() ?? {};
      var session = GameSessionModel.fromMap(sessionData, id: snapshot.id);

      for (final item in items) {
        session = session.addOrder(item);
      }

      final updatedOrdersList = session.orders.map((o) => o.toMap()).toList();
      final totalMarket = session.totalMarketCost;
      final totalAmount = session.totalGamingCost + totalMarket;

      await docRef.set({
        'orders': updatedOrdersList,
        'totalMarketCost': totalMarket,
        'totalMarketAmount': totalMarket,
        'totalAmount': totalAmount,
      }, SetOptions(merge: true));

      // Decrement stock for all items
      for (final item in items) {
        final targetProductId = item.productId.isNotEmpty ? item.productId : item.itemId;
        if (targetProductId.isNotEmpty) {
          final productRef = _productsCol.doc(targetProductId);
          final productSnapshot = await productRef.get();
          if (productSnapshot.exists) {
            await productRef.update({
              'stockQuantity': FieldValue.increment(-item.quantity),
              'stock': FieldValue.increment(-item.quantity),
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Detailed Error in addMultipleOrderItemsToSession: $e');
    }
  }

  /// Alias for addOrderItemToSession
  Future<void> addMarketItemToSession(String sessionId, OrderItem item) =>
      addOrderItemToSession(sessionId: sessionId, item: item);

  /// Removes an order item from session and restores stock without transactions
  Future<void> removeOrderItemFromSession({
    required String sessionId,
    required String productId,
    int? restoreQuantity,
  }) async {
    if (sessionId.isEmpty || productId.isEmpty) return;

    try {
      final docRef = _sessionsCol.doc(sessionId);
      final snapshot = await docRef.get();
      if (!snapshot.exists) return;

      final sessionData = snapshot.data() ?? {};
      final session = GameSessionModel.fromMap(sessionData, id: snapshot.id);

      final orderItem = session.orders.firstWhere(
        (o) => o.productId == productId || o.itemId == productId,
        orElse: () => OrderItem(
          productId: '',
          productName: '',
          quantity: 0,
          unitPrice: 0,
          totalPrice: 0,
        ),
      );

      final qtyToRestore = restoreQuantity ?? orderItem.quantity;

      final updatedSession = session.removeOrder(productId);
      final updatedOrdersList = updatedSession.orders.map((o) => o.toMap()).toList();
      final totalMarket = updatedSession.totalMarketCost;
      final totalAmount = updatedSession.totalGamingCost + totalMarket;

      await docRef.set({
        'orders': updatedOrdersList,
        'totalMarketCost': totalMarket,
        'totalMarketAmount': totalMarket,
        'totalAmount': totalAmount,
      }, SetOptions(merge: true));

      // Restore product stock directly
      if (qtyToRestore > 0) {
        final productRef = _productsCol.doc(productId);
        final productSnapshot = await productRef.get();
        if (productSnapshot.exists) {
          await productRef.update({
            'stockQuantity': FieldValue.increment(qtyToRestore),
            'stock': FieldValue.increment(qtyToRestore),
          });
        }
      }
    } catch (e) {
      debugPrint('Detailed Error in removeOrderItemFromSession: $e');
    }
  }

  /// Alias for removeOrderItemFromSession
  Future<void> removeMarketItemFromSession(String sessionId, String productId, {int? restoreQuantity}) =>
      removeOrderItemFromSession(sessionId: sessionId, productId: productId, restoreQuantity: restoreQuantity);

  /// Ends a session, marks payment status, and frees the screen atomically
  Future<GameSessionModel> endSession({
    required String sessionId,
    required String screenId,
    bool isPaid = true,
    DateTime? endAt,
    double? customTotalAmount,
  }) async {
    final now = endAt ?? DateTime.now();

    final sessionDoc = await _sessionsCol.doc(sessionId).get();
    if (!sessionDoc.exists) {
      throw Exception('الجلسة غير موجودة');
    }

    final currentSession = GameSessionModel.fromFirestore(sessionDoc);
    final finalizedSession = currentSession.endSession(
      endAt: now,
      isPaid: isPaid,
      customTotalAmount: customTotalAmount,
    );

    final batch = _firestore.batch();

    // 1. Update session to ended
    batch.update(_sessionsCol.doc(sessionId), finalizedSession.toJson());

    // 2. Free screen and record last ended session timestamp
    final screenRef = _screensCol.doc(screenId);
    batch.set(screenRef, {
      'isOccupied': false,
      'activeSessionId': null,
      'lastSessionEndedAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));

    await batch.commit();
    return finalizedSession;
  }

  // ==========================================
  // 3. PRODUCTS & MARKET OPERATIONS
  // ==========================================

  /// Stream of all products ordered by name
  Stream<List<ProductModel>> getProductsStream() {
    return _productsCol
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromFirestore(doc))
            .toList());
  }

  /// Add new product to market
  Future<ProductModel> addProduct(ProductModel product) async {
    final docRef = _productsCol.doc(product.id.isNotEmpty ? product.id : _uuid.v4());
    final newProduct = product.copyWith(
      id: docRef.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await docRef.set(newProduct.toJson());
    return newProduct;
  }

  /// Update product
  Future<void> updateProduct(ProductModel product) async {
    final updated = product.copyWith(updatedAt: DateTime.now());
    await _productsCol.doc(product.id).update(updated.toJson());
  }

  /// Delete product
  Future<void> deleteProduct(String productId) async {
    await _productsCol.doc(productId).delete();
  }

  /// Update stock quantity directly
  Future<void> updateProductStock(String productId, int newQuantity) async {
    await _productsCol.doc(productId).update({
      'stockQuantity': newQuantity,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ==========================================
  // 4. USERS & ROLES OPERATIONS
  // ==========================================

  /// Get user profile
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _usersCol.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  /// Save or update user profile
  Future<void> saveUserProfile(UserModel user) async {
    await _usersCol.doc(user.uid).set(user.toJson(), SetOptions(merge: true));
  }

  /// Stream of all staff and admin users
  Stream<List<UserModel>> getStaffUsersStream() {
    return _usersCol
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList());
  }

  // ==========================================
  // 5. RECEIPT & PRICING SETTINGS OPERATIONS
  // ==========================================

  CollectionReference<Map<String, dynamic>> get _settingsCol =>
      _firestore.collection(AppConstants.loungeSettingsCollection);

  /// Stream of receipt settings
  Stream<ReceiptSettingsModel> getReceiptSettingsStream() {
    try {
      return _settingsCol.doc('receipt_settings').snapshots().map((doc) {
        if (!doc.exists || doc.data() == null) {
          return const ReceiptSettingsModel();
        }
        return ReceiptSettingsModel.fromMap(doc.data()!);
      }).handleError((_) => const ReceiptSettingsModel());
    } catch (_) {
      return Stream.value(const ReceiptSettingsModel());
    }
  }

  /// Get current receipt settings
  Future<ReceiptSettingsModel> getReceiptSettings() async {
    try {
      final doc = await _settingsCol.doc('receipt_settings').get();
      if (!doc.exists || doc.data() == null) {
        return const ReceiptSettingsModel();
      }
      return ReceiptSettingsModel.fromMap(doc.data()!);
    } catch (e) {
      debugPrint('Error getting receipt settings: $e');
      return const ReceiptSettingsModel();
    }
  }

  /// Save receipt settings
  Future<void> saveReceiptSettings(ReceiptSettingsModel settings) async {
    try {
      await _settingsCol.doc('receipt_settings').set(settings.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving receipt settings: $e');
      rethrow;
    }
  }

  /// Stream of pricing settings
  Stream<PricingSettingsModel> getPricingSettingsStream() {
    try {
      return _settingsCol.doc('pricing_settings').snapshots().map((doc) {
        if (!doc.exists || doc.data() == null) {
          return const PricingSettingsModel();
        }
        return PricingSettingsModel.fromMap(doc.data()!);
      }).handleError((_) => const PricingSettingsModel());
    } catch (_) {
      return Stream.value(const PricingSettingsModel());
    }
  }

  /// Get current pricing settings
  Future<PricingSettingsModel> getPricingSettings() async {
    try {
      final doc = await _settingsCol.doc('pricing_settings').get();
      if (!doc.exists || doc.data() == null) {
        return const PricingSettingsModel();
      }
      return PricingSettingsModel.fromMap(doc.data()!);
    } catch (e) {
      debugPrint('Error getting pricing settings: $e');
      return const PricingSettingsModel();
    }
  }

  /// Save pricing settings
  Future<void> savePricingSettings(PricingSettingsModel settings) async {
    try {
      await _settingsCol.doc('pricing_settings').set(settings.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving pricing settings: $e');
      rethrow;
    }
  }

  /// Add a new screen / table to Firestore
  Future<ScreenModel> addNewScreen({
    required int screenNumber,
    String? name,
    String? deviceType,
    String? sectionName,
  }) async {
    try {
      final docRef = _screensCol.doc('screen_$screenNumber');
      final screen = ScreenModel(
        id: 'screen_$screenNumber',
        screenNumber: screenNumber,
        name: name,
        deviceType: deviceType,
        sectionName: sectionName,
        isOccupied: false,
        activeSessionId: null,
        lastSessionEndedAt: null,
      );
      await docRef.set(screen.toJson(), SetOptions(merge: true));
      return screen;
    } catch (e) {
      debugPrint('Error adding new screen: $e');
      rethrow;
    }
  }

  // ==========================================
  // 6. RESTOCK & PURCHASES OPERATIONS
  // ==========================================

  CollectionReference<Map<String, dynamic>> get _restockCol =>
      _firestore.collection(AppConstants.restockTransactionsCollection);

  /// Records a new restock transaction, increments stock, and updates purchase & selling prices
  Future<RestockTransactionModel> restockProduct({
    required String productId,
    required int incomingQuantity,
    required double unitCostPrice,
    required double unitSellingPrice,
    required String approvedByAdmin,
    String? notes,
  }) async {
    try {
      final productRef = _productsCol.doc(productId);
      final productSnapshot = await productRef.get();

      int previousStock = 0;
      String productName = 'منتج';

      if (productSnapshot.exists && productSnapshot.data() != null) {
        final data = productSnapshot.data()!;
        previousStock = (data['stockQuantity'] as num?)?.toInt() ?? (data['stock'] as num?)?.toInt() ?? 0;
        productName = data['name'] as String? ?? 'منتج';
      }

      final newStock = previousStock + incomingQuantity;
      final totalCost = incomingQuantity * unitCostPrice;

      // 1. Update Product document
      await productRef.set({
        'stockQuantity': newStock,
        'stock': newStock,
        'costPrice': unitCostPrice,
        'sellingPrice': unitSellingPrice,
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));

      // 2. Create Restock Transaction Record
      final restockId = _uuid.v4();
      final restockTransaction = RestockTransactionModel(
        id: restockId,
        productId: productId,
        productName: productName,
        incomingQuantity: incomingQuantity,
        previousStock: previousStock,
        newStock: newStock,
        unitCostPrice: unitCostPrice,
        unitSellingPrice: unitSellingPrice,
        totalCostAmount: totalCost,
        approvedByAdmin: approvedByAdmin,
        timestamp: DateTime.now(),
        notes: notes,
      );

      await _restockCol.doc(restockId).set(restockTransaction.toMap());
      return restockTransaction;
    } catch (e) {
      debugPrint('Error restocking product: $e');
      rethrow;
    }
  }

  /// Stream of all restock transactions ordered by date descending
  Stream<List<RestockTransactionModel>> getRestockTransactionsStream() {
    try {
      return _restockCol
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => RestockTransactionModel.fromFirestore(doc))
              .toList())
          .handleError((_) => <RestockTransactionModel>[]);
    } catch (_) {
      return Stream.value(<RestockTransactionModel>[]);
    }
  }

  /// Get all restock transactions
  Future<List<RestockTransactionModel>> getRestockTransactions() async {
    try {
      final snapshot = await _restockCol.orderBy('timestamp', descending: true).get();
      return snapshot.docs.map((doc) => RestockTransactionModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting restock transactions: $e');
      return [];
    }
  }

  // ==========================================
  // 8. APP VERSION & REMOTE UPDATE CONFIG
  // ==========================================

  /// Get remote version configuration from `app_config/version_info`
  Future<AppVersionModel?> getVersionInfo() async {
    try {
      final doc = await _appConfigCol.doc(AppConstants.versionInfoDoc).get();
      if (!doc.exists || doc.data() == null) return null;
      return AppVersionModel.fromMap(doc.data()!);
    } catch (e) {
      debugPrint('Error getting remote version info: $e');
      return null;
    }
  }

  /// Save or update remote version configuration in `app_config/version_info`
  Future<void> saveVersionInfo(AppVersionModel versionModel) async {
    try {
      await _appConfigCol
          .doc(AppConstants.versionInfoDoc)
          .set(versionModel.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving remote version info: $e');
      rethrow;
    }
  }

  // ==========================================
  // 9. SYSTEM PURGE & DATA RESET (Admin Only)
  // ==========================================

  /// Purges test sessions, restock history, and resets screen occupation state to 0
  /// Preserves: screens list, user accounts, products inventory, and settings.
  Future<void> clearAllTestData() async {
    try {
      // 1. Delete all sessions
      final sessionsSnapshot = await _sessionsCol.get();
      if (sessionsSnapshot.docs.isNotEmpty) {
        final batch1 = _firestore.batch();
        for (final doc in sessionsSnapshot.docs) {
          batch1.delete(doc.reference);
        }
        await batch1.commit();
      }

      // 2. Delete all restock transactions
      final restockSnapshot = await _restockCol.get();
      if (restockSnapshot.docs.isNotEmpty) {
        final batch2 = _firestore.batch();
        for (final doc in restockSnapshot.docs) {
          batch2.delete(doc.reference);
        }
        await batch2.commit();
      }

      // 3. Reset all screens to available/unoccupied
      final screensSnapshot = await _screensCol.get();
      if (screensSnapshot.docs.isNotEmpty) {
        final batch3 = _firestore.batch();
        for (final doc in screensSnapshot.docs) {
          batch3.update(doc.reference, {
            'isOccupied': false,
            'activeSessionId': null,
            'lastSessionEndedAt': null,
          });
        }
        await batch3.commit();
      }

      // 4. Delete any legacy shift documents
      try {
        final shiftsSnapshot = await _firestore.collection('shifts').get();
        if (shiftsSnapshot.docs.isNotEmpty) {
          final batch4 = _firestore.batch();
          for (final doc in shiftsSnapshot.docs) {
            batch4.delete(doc.reference);
          }
          await batch4.commit();
        }
      } catch (_) {}
    } catch (e) {
      debugPrint('Error clearing test data: $e');
      rethrow;
    }
  }
}
