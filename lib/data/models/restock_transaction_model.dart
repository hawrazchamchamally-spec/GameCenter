import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an inventory restock transaction record
class RestockTransactionModel {
  final String id;
  final String productId;
  final String productName;
  final int incomingQuantity;
  final int previousStock;
  final int newStock;
  final double unitCostPrice;
  final double unitSellingPrice;
  final double totalCostAmount; // incomingQuantity * unitCostPrice
  final String approvedByAdmin;
  final DateTime timestamp;
  final String? notes;

  const RestockTransactionModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.incomingQuantity,
    required this.previousStock,
    required this.newStock,
    required this.unitCostPrice,
    required this.unitSellingPrice,
    required this.totalCostAmount,
    required this.approvedByAdmin,
    required this.timestamp,
    this.notes,
  });

  /// Convert to Firestore JSON Map
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'incomingQuantity': incomingQuantity,
      'previousStock': previousStock,
      'newStock': newStock,
      'unitCostPrice': unitCostPrice,
      'unitSellingPrice': unitSellingPrice,
      'totalCostAmount': totalCostAmount,
      'approvedByAdmin': approvedByAdmin,
      'timestamp': Timestamp.fromDate(timestamp),
      'notes': notes,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  /// Factory constructor from Map JSON
  factory RestockTransactionModel.fromMap(Map<String, dynamic> map, {String id = ''}) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return RestockTransactionModel(
      id: id.isNotEmpty ? id : (map['id'] as String? ?? ''),
      productId: map['productId'] as String? ?? '',
      productName: map['productName'] as String? ?? 'منتج',
      incomingQuantity: (map['incomingQuantity'] as num?)?.toInt() ?? 0,
      previousStock: (map['previousStock'] as num?)?.toInt() ?? 0,
      newStock: (map['newStock'] as num?)?.toInt() ?? 0,
      unitCostPrice: (map['unitCostPrice'] as num?)?.toDouble() ?? 0.0,
      unitSellingPrice: (map['unitSellingPrice'] as num?)?.toDouble() ?? 0.0,
      totalCostAmount: (map['totalCostAmount'] as num?)?.toDouble() ?? 0.0,
      approvedByAdmin: map['approvedByAdmin'] as String? ?? 'المدير',
      timestamp: parseDate(map['timestamp']),
      notes: map['notes'] as String?,
    );
  }

  /// Factory constructor from Firestore DocumentSnapshot
  factory RestockTransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return RestockTransactionModel.fromMap(data, id: doc.id);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RestockTransactionModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          productId == other.productId &&
          incomingQuantity == other.incomingQuantity &&
          totalCostAmount == other.totalCostAmount;

  @override
  int get hashCode => id.hashCode ^ productId.hashCode ^ incomingQuantity.hashCode;
}
