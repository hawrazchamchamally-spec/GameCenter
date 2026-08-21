import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an item ordered from the market attached to a gaming session
class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final DateTime? orderedAt;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.orderedAt,
  });

  /// Factory helper that automatically calculates totalPrice from quantity * unitPrice
  factory OrderItem.create({
    required String productId,
    required String productName,
    required int quantity,
    required double unitPrice,
    DateTime? orderedAt,
  }) {
    return OrderItem(
      productId: productId,
      productName: productName,
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: quantity * unitPrice,
      orderedAt: orderedAt ?? DateTime.now(),
    );
  }

  String get itemId => productId;
  String get title => productName;
  double get price => unitPrice;

  /// Converts to Map JSON for Firestore with primitive types only
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'itemId': productId,
      'title': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'price': unitPrice,
      'totalPrice': totalPrice,
      'orderedAt': orderedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() => toMap();

  /// Factory constructor from Map JSON
  factory OrderItem.fromMap(Map<String, dynamic> map) {
    DateTime? parseOrderedDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      if (value is Timestamp) return value.toDate();
      return null;
    }

    final qty = (map['quantity'] as num?)?.toInt() ?? 1;
    final unitP = (map['unitPrice'] as num?)?.toDouble() ??
        (map['price'] as num?)?.toDouble() ??
        0.0;
    final totalP = (map['totalPrice'] as num?)?.toDouble() ?? (qty * unitP);
    final pId = (map['productId'] ?? map['itemId'] ?? '').toString();
    final pName = (map['productName'] ?? map['title'] ?? '').toString();

    return OrderItem(
      productId: pId,
      productName: pName,
      quantity: qty,
      unitPrice: unitP,
      totalPrice: totalP,
      orderedAt: parseOrderedDate(map['orderedAt']),
    );
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem.fromMap(json);

  OrderItem copyWith({
    String? productId,
    String? productName,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    DateTime? orderedAt,
  }) {
    final updatedQty = quantity ?? this.quantity;
    final updatedUnitPrice = unitPrice ?? this.unitPrice;

    return OrderItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: updatedQty,
      unitPrice: updatedUnitPrice,
      totalPrice: totalPrice ?? (updatedQty * updatedUnitPrice),
      orderedAt: orderedAt ?? this.orderedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderItem &&
          runtimeType == other.runtimeType &&
          productId == other.productId &&
          quantity == other.quantity &&
          unitPrice == other.unitPrice;

  @override
  int get hashCode => productId.hashCode ^ quantity.hashCode ^ unitPrice.hashCode;
}
