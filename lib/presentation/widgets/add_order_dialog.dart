import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../providers/market_provider.dart';

/// Multi-product selection modal dialog with quantity counters (+ / -) to batch-add items to an active session
class AddOrderToSessionDialog extends StatefulWidget {
  final int screenNumber;
  final Function(ProductModel product)? onAddProduct;
  final Function(List<OrderItem> items)? onAddMultipleProducts;

  const AddOrderToSessionDialog({
    super.key,
    required this.screenNumber,
    this.onAddProduct,
    this.onAddMultipleProducts,
  });

  @override
  State<AddOrderToSessionDialog> createState() => _AddOrderToSessionDialogState();
}

class _AddOrderToSessionDialogState extends State<AddOrderToSessionDialog> {
  String? _selectedCategory;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  /// Map of productId -> quantity selected
  final Map<String, int> _selectedQuantities = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get totalCount => _selectedQuantities.values.fold(0, (sum, q) => sum + q);

  double calculateTotalSelectedAmount(List<ProductModel> allProducts) {
    double total = 0.0;
    for (final entry in _selectedQuantities.entries) {
      final product = allProducts.firstWhere(
        (p) => p.id == entry.key,
        orElse: () => ProductModel(
          id: entry.key,
          name: '',
          costPrice: 0,
          sellingPrice: 0,
          stockQuantity: 0,
        ),
      );
      total += product.sellingPrice * entry.value;
    }
    return total;
  }

  void _confirmAndAddSelected(List<ProductModel> allProducts) {
    final List<OrderItem> orderItems = [];

    for (final entry in _selectedQuantities.entries) {
      if (entry.value <= 0) continue;
      final product = allProducts.firstWhere(
        (p) => p.id == entry.key,
        orElse: () => ProductModel(
          id: entry.key,
          name: 'منتج',
          costPrice: 0,
          sellingPrice: 0,
          stockQuantity: 0,
        ),
      );

      orderItems.add(
        OrderItem.create(
          productId: product.id,
          productName: product.name,
          quantity: entry.value,
          unitPrice: product.sellingPrice,
        ),
      );
    }

    if (orderItems.isEmpty) return;

    if (widget.onAddMultipleProducts != null) {
      widget.onAddMultipleProducts!(orderItems);
    } else if (widget.onAddProduct != null) {
      for (final item in orderItems) {
        final product = allProducts.firstWhere(
          (p) => p.id == item.productId,
          orElse: () => ProductModel(
            id: item.productId,
            name: item.productName,
            costPrice: 0,
            sellingPrice: item.unitPrice,
            stockQuantity: 0,
          ),
        );
        widget.onAddProduct!(product);
      }
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final marketProvider = Provider.of<MarketProvider>(context);
    final allProducts = marketProvider.products;
    final categories = marketProvider.categories;

    final filteredProducts = allProducts.where((p) {
      final matchesCat = _selectedCategory == null || p.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p.category ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();

    final totalSelectedAmount = calculateTotalSelectedAmount(allProducts);

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxWidth: 580,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.cyanAccent.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_mall_outlined, color: AppColors.cyanAccent, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إضافة طلبات الماركيت - شاشة ${widget.screenNumber}',
                        style: const TextStyle(
                          fontSize: 17.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Text(
                        'حدد كميات المنتجات واضغط تأكيد الإضافة دفعة واحدة',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (totalCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.available.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.available.withAlpha(100)),
                    ),
                    child: Text(
                      'المحدد: $totalCount قطع',
                      style: const TextStyle(
                        color: AppColors.available,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 14),

            // Search input
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث عن مشروب أو سناك أو وجبة...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim();
                });
              },
            ),

            const SizedBox(height: 10),

            // Category Filter Chips Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip('الكل', null),
                  ...categories.map((c) => _buildCategoryChip(c, c)),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Horizontal Rectangular Products List
            Expanded(
              child: filteredProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'لا توجد منتجات تطابق "$_searchQuery"'
                                : 'لا توجد منتجات مسجلة في هذا القسم',
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: filteredProducts.length,
                      separatorBuilder: (ctx, index) => const SizedBox(height: 8),
                      itemBuilder: (ctx, index) {
                        final product = filteredProducts[index];
                        return _buildHorizontalProductCard(product);
                      },
                    ),
            ),

            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 8),

            // Bottom Confirmation Summary Bar
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'إجمالي الماركيت المحدد ($totalCount قطع):',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                      ),
                      Text(
                        AppFormatters.formatCurrency(totalSelectedAmount),
                        style: const TextStyle(
                          color: AppColors.cyanAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: totalCount > 0
                      ? () => _confirmAndAddSelected(allProducts)
                      : null,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: Text('تأكيد وإضافة ($totalCount) للجلسة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.primaryNeon.withAlpha(40),
        backgroundColor: AppColors.cardBg,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.cyanAccent : AppColors.textSecondary,
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? AppColors.cyanAccent : AppColors.cardBorder,
        ),
        onSelected: (_) {
          setState(() {
            _selectedCategory = isSelected ? null : category;
          });
        },
      ),
    );
  }

  /// Horizontal Rectangular Product Card
  Widget _buildHorizontalProductCard(ProductModel product) {
    final isOutOfStock = product.stockQuantity <= 0;
    final isLowStock = product.stockQuantity > 0 && product.stockQuantity <= 5;
    final selectedQty = _selectedQuantities[product.id] ?? 0;

    final Color stockColor = isOutOfStock
        ? AppColors.occupied
        : (isLowStock ? AppColors.warning : AppColors.available);

    final IconData categoryIcon = _getCategoryIcon(product.category);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: selectedQty > 0 ? AppColors.primaryNeon.withAlpha(25) : AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selectedQty > 0
              ? AppColors.primaryNeon
              : (isOutOfStock ? AppColors.occupied.withAlpha(50) : AppColors.cardBorder),
          width: selectedQty > 0 ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Icon Avatar
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: selectedQty > 0
                  ? AppColors.primaryNeon.withAlpha(40)
                  : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              categoryIcon,
              color: selectedQty > 0 ? Colors.white : AppColors.cyanAccent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // Name and Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        AppFormatters.formatCurrency(product.sellingPrice),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.cyanAccent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: stockColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: stockColor.withAlpha(70)),
                      ),
                      child: Text(
                        isOutOfStock
                            ? 'نافد'
                            : 'المتوفر: ${product.stockQuantity}',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: stockColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Multi-Quantity Counter Controls (+ / -) or Add Button
          if (selectedQty == 0)
            ElevatedButton.icon(
              onPressed: isOutOfStock
                  ? null
                  : () {
                      if (widget.onAddProduct != null && widget.onAddMultipleProducts == null) {
                        widget.onAddProduct!(product);
                        Navigator.pop(context);
                      } else {
                        setState(() {
                          _selectedQuantities[product.id] = 1;
                        });
                      }
                    },
              icon: const Icon(Icons.add_shopping_cart, size: 14),
              label: const Text('إضافة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            )
          else
            Container(
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primaryNeon, width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        if (selectedQty > 1) {
                          _selectedQuantities[product.id] = selectedQty - 1;
                        } else {
                          _selectedQuantities.remove(product.id);
                        }
                      });
                    },
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Icon(Icons.remove, size: 16, color: AppColors.occupied),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '$selectedQty',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: (selectedQty < product.stockQuantity)
                        ? () {
                            setState(() {
                              _selectedQuantities[product.id] = selectedQty + 1;
                            });
                          }
                        : null,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Icon(
                        Icons.add,
                        size: 16,
                        color: (selectedQty < product.stockQuantity)
                            ? AppColors.available
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String? category) {
    final cat = (category ?? '').toLowerCase();
    if (cat.contains('مشروب') || cat.contains('drink') || cat.contains('عصير') || cat.contains('ماء')) {
      return Icons.local_drink_outlined;
    }
    if (cat.contains('سناك') || cat.contains('snack') || cat.contains('شيبس') || cat.contains('بسكوت')) {
      return Icons.cookie_outlined;
    }
    if (cat.contains('وجب') || cat.contains('food') || cat.contains('طعام') || cat.contains('برجر')) {
      return Icons.fastfood_outlined;
    }
    if (cat.contains('قهو') || cat.contains('coffee') || cat.contains('شاي') || cat.contains('tea')) {
      return Icons.coffee_outlined;
    }
    return Icons.inventory_2_outlined;
  }
}
