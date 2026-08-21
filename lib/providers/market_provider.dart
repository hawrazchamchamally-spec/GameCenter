import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/models.dart';
import '../data/services/firestore_service.dart';

/// Provider for Market & Products management
class MarketProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;

  List<ProductModel> _products = [];
  String _searchQuery = '';
  String? _selectedCategory;
  bool _isLoading = true;
  String? _errorMessage;

  StreamSubscription<List<ProductModel>>? _productsSubscription;

  MarketProvider({
    FirestoreService? firestoreService,
    List<ProductModel>? initialProducts,
  }) : _firestoreService = firestoreService ?? FirestoreService() {
    if (initialProducts != null) {
      _products = initialProducts;
      _isLoading = false;
    } else {
      _init();
    }
  }

  // Getters
  List<ProductModel> get products {
    return _products.where((p) {
      final matchesQuery = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == null ||
          _selectedCategory!.isEmpty ||
          p.category == _selectedCategory;
      return matchesQuery && matchesCategory;
    }).toList();
  }

  List<ProductModel> get allProducts => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;

  List<String> get categories {
    final cats = _products
        .map((p) => p.category)
        .where((c) => c != null && c.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    cats.sort();
    return cats;
  }

  List<RestockTransactionModel> _restockTransactions = [];
  StreamSubscription<List<RestockTransactionModel>>? _restockSubscription;

  List<RestockTransactionModel> get restockTransactions => _restockTransactions;

  void _init() {
    _isLoading = true;
    notifyListeners();

    try {
      _productsSubscription = _firestoreService.getProductsStream().listen(
        (productsList) {
          _products = productsList;
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
        },
        onError: (error) {
          _isLoading = false;
          _errorMessage = error.toString();
          notifyListeners();
        },
      );

      _restockSubscription = _firestoreService.getRestockTransactionsStream().listen(
        (transactions) {
          _restockTransactions = transactions;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('Restock stream error: $error');
        },
      );
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  /// Add new product
  Future<ProductModel?> addProduct(ProductModel product) async {
    try {
      final created = await _firestoreService.addProduct(product);
      return created;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Restock product with new incoming quantity, updated cost and selling prices
  Future<RestockTransactionModel?> restockProduct({
    required String productId,
    required int incomingQuantity,
    required double unitCostPrice,
    required double unitSellingPrice,
    required String approvedByAdmin,
    String? notes,
  }) async {
    try {
      final transaction = await _firestoreService.restockProduct(
        productId: productId,
        incomingQuantity: incomingQuantity,
        unitCostPrice: unitCostPrice,
        unitSellingPrice: unitSellingPrice,
        approvedByAdmin: approvedByAdmin,
        notes: notes,
      );

      // Optimistic local update
      final idx = _products.indexWhere((p) => p.id == productId);
      if (idx != -1) {
        _products[idx] = _products[idx].copyWith(
          stockQuantity: _products[idx].stockQuantity + incomingQuantity,
          costPrice: unitCostPrice,
          sellingPrice: unitSellingPrice,
          updatedAt: DateTime.now(),
        );
      }
      _restockTransactions.insert(0, transaction);
      notifyListeners();
      return transaction;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Update existing product
  Future<void> updateProduct(ProductModel product) async {
    try {
      await _firestoreService.updateProduct(product);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Delete product
  Future<void> deleteProduct(String productId) async {
    try {
      await _firestoreService.deleteProduct(productId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _productsSubscription?.cancel();
    _restockSubscription?.cancel();
    super.dispose();
  }
}
