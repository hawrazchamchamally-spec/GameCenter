import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a product in the attached lounge market/café
class ProductModel {
  final String id;
  final String name;
  final double costPrice;
  final double sellingPrice;
  final int stockQuantity;
  final String? category;
  final String? barcode;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProductModel({
    required this.id,
    required this.name,
    required this.costPrice,
    required this.sellingPrice,
    required this.stockQuantity,
    this.category,
    this.barcode,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
  });

  /// Profit per unit in IQD
  double get profitPerUnit => sellingPrice - costPrice;

  /// Check if out of stock
  bool get isOutOfStock => stockQuantity <= 0;

  /// Check if low stock (e.g. less than 5 items)
  bool get isLowStock => stockQuantity > 0 && stockQuantity <= 5;

  /// Converts to Firestore JSON Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'stockQuantity': stockQuantity,
      'category': category,
      'barcode': barcode,
      'imageUrl': imageUrl,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  /// Factory constructor from Map JSON
  factory ProductModel.fromMap(Map<String, dynamic> map, {String id = ''}) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return ProductModel(
      id: id.isNotEmpty ? id : (map['id'] as String? ?? ''),
      name: map['name'] as String? ?? '',
      costPrice: (map['costPrice'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (map['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      stockQuantity: (map['stockQuantity'] as num?)?.toInt() ??
          (map['stock'] as num?)?.toInt() ??
          0,
      category: map['category'] as String?,
      barcode: map['barcode'] as String?,
      imageUrl: map['imageUrl'] as String?,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json, {String id = ''}) =>
      ProductModel.fromMap(json, id: id);

  /// Factory constructor from Firestore DocumentSnapshot
  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ProductModel.fromMap(data, id: doc.id);
  }

  ProductModel copyWith({
    String? id,
    String? name,
    double? costPrice,
    double? sellingPrice,
    int? stockQuantity,
    String? category,
    String? barcode,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      category: category ?? this.category,
      barcode: barcode ?? this.barcode,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          sellingPrice == other.sellingPrice &&
          stockQuantity == other.stockQuantity;

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ sellingPrice.hashCode ^ stockQuantity.hashCode;
}
