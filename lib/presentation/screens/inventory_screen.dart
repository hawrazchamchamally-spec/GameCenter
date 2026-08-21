import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/market_provider.dart';
import '../widgets/product_form_dialog.dart';
import '../widgets/restock_market_dialog.dart';
import '../widgets/stat_badge_widget.dart';

/// Full Inventory & Market Management Screen with Role-based Protection
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  String _stockFilter = 'all'; // 'all', 'low', 'out'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final marketProvider = Provider.of<MarketProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.isAdmin;

    final allProducts = marketProvider.allProducts;
    final categories = marketProvider.categories;

    // Filter products
    final filteredProducts = allProducts.where((p) {
      final matchesQuery = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p.category != null && p.category!.toLowerCase().contains(_searchQuery.toLowerCase()));
      final matchesCategory = _selectedCategory == null ||
          _selectedCategory!.isEmpty ||
          p.category == _selectedCategory;
      final matchesStock = _stockFilter == 'all' ||
          (_stockFilter == 'low' && p.isLowStock) ||
          (_stockFilter == 'out' && p.isOutOfStock);
      return matchesQuery && matchesCategory && matchesStock;
    }).toList();

    // Stats calculations
    final totalProductsCount = allProducts.length;
    final lowStockCount = allProducts.where((p) => p.isLowStock).length;
    final outOfStockCount = allProducts.where((p) => p.isOutOfStock).length;
    
    final totalInventorySellingValue = allProducts.fold<double>(
      0.0,
      (sum, p) => sum + (p.sellingPrice * p.stockQuantity),
    );

    final totalInventoryCostValue = allProducts.fold<double>(
      0.0,
      (sum, p) => sum + (p.costPrice * p.stockQuantity),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storefront_outlined, color: AppColors.cyanAccent, size: 22),
            SizedBox(width: 8),
            Text('إدارة الماركيت والمخزون', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          if (isAdmin) ...[
            TextButton.icon(
              icon: const Icon(Icons.inventory, color: AppColors.available, size: 19),
              label: const Text('تعبئة وتوريد المخزن', style: TextStyle(color: AppColors.available, fontWeight: FontWeight.bold, fontSize: 12.5)),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.available.withAlpha(25),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _openRestockDialog(context),
            ),
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppColors.primaryLight, size: 28),
              tooltip: 'إضافة منتج جديد',
              onPressed: () => _openAddProductDialog(context),
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {},
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. Top Metrics Banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildInventoryHeaderBanner(isAdmin),
                      const SizedBox(height: 14),
                      _buildInventoryStatsRow(
                        totalCount: totalProductsCount,
                        lowStock: lowStockCount,
                        outOfStock: outOfStockCount,
                        inventorySellingValue: totalInventorySellingValue,
                        inventoryCostValue: totalInventoryCostValue,
                        isAdmin: isAdmin,
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Search & Category Filters
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Bar & Quick Restock Button
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'بحث عن صنف بالاسم أو الباركود...',
                                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: AppColors.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: AppColors.cardBorder),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: AppColors.cardBorder),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              onChanged: (val) => setState(() => _searchQuery = val),
                            ),
                          ),
                          if (isAdmin) ...[
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: () => _openRestockDialog(context),
                              icon: const Icon(Icons.add_shopping_cart, size: 18, color: Colors.black),
                              label: const Text('توريد', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.available,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Quick Filter Active Banner
                      if (_stockFilter != 'all') ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _stockFilter == 'out' ? AppColors.occupied.withAlpha(30) : AppColors.warning.withAlpha(30),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _stockFilter == 'out' ? AppColors.occupied : AppColors.warning,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _stockFilter == 'out' ? Icons.remove_shopping_cart : Icons.warning_amber_rounded,
                                size: 16,
                                color: _stockFilter == 'out' ? AppColors.occupied : AppColors.warning,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _stockFilter == 'out'
                                    ? 'عرض الأصناف النافدة فقط (تحتاج توريد عاجل)'
                                    : 'عرض الأصناف منخفضة المخزون (≤5)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _stockFilter == 'out' ? AppColors.occupied : AppColors.warning,
                                ),
                              ),
                              const SizedBox(width: 10),
                              InkWell(
                                onTap: () => setState(() => _stockFilter = 'all'),
                                child: const Icon(Icons.close, size: 16, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Categories Horizontal List
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildCategoryFilterChip('الكل (${allProducts.length})', null),
                            ...categories.map((cat) {
                              final count = allProducts.where((p) => p.category == cat).length;
                              return _buildCategoryFilterChip('$cat ($count)', cat);
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Products Grid
              if (filteredProducts.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 48, color: AppColors.textSecondary),
                        const SizedBox(height: 12),
                        const Text(
                          'لا توجد منتجات مطابقة لخيارات البحث أو الفلترة',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                        if (_stockFilter != 'all' || _selectedCategory != null || _searchQuery.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _searchController.clear();
                                _selectedCategory = null;
                                _stockFilter = 'all';
                              });
                            },
                            child: const Text('إلغاء جميع الفلاتر'),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 460,
                      mainAxisExtent: 200,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = filteredProducts[index];
                        return _buildProductCard(context, product, marketProvider, isAdmin);
                      },
                      childCount: filteredProducts.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _openAddProductDialog(context),
              backgroundColor: AppColors.primaryNeon,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('إضافة منتج جديد', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            )
          : null,
    );
  }

  Widget _buildInventoryHeaderBanner(bool isAdmin) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2A38), Color(0xFF111827)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cyanAccent.withAlpha(50)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مركز إدارة المخزون والماركيت',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAdmin
                      ? 'متابعة حركة المخزون، أسعار التكلفة، وهوامش الأرباح وتوريد البضاعة'
                      : 'عرض الأصناف والكميات المتوفرة لطلبات الصالة والزبائن',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const Icon(Icons.inventory_sharp, color: AppColors.cyanAccent, size: 36),
        ],
      ),
    );
  }

  Widget _buildInventoryStatsRow({
    required int totalCount,
    required int lowStock,
    required int outOfStock,
    required double inventorySellingValue,
    required double inventoryCostValue,
    required bool isAdmin,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        InkWell(
          onTap: () => setState(() => _stockFilter = 'all'),
          borderRadius: BorderRadius.circular(16),
          child: StatBadgeWidget(
            title: 'إجمالي الأصناف',
            value: '$totalCount منتج',
            icon: Icons.category,
            accentColor: _stockFilter == 'all' ? AppColors.cyanAccent : AppColors.primaryLight,
          ),
        ),
        InkWell(
          onTap: () {
            setState(() {
              _stockFilter = (_stockFilter == 'low') ? 'all' : 'low';
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: _stockFilter == 'low' ? Border.all(color: AppColors.warning, width: 2) : null,
            ),
            child: StatBadgeWidget(
              title: 'منخفض المخزون (≤5)',
              value: '$lowStock أصناف',
              icon: Icons.warning_amber_rounded,
              accentColor: AppColors.warning,
            ),
          ),
        ),
        InkWell(
          onTap: () {
            setState(() {
              _stockFilter = (_stockFilter == 'out') ? 'all' : 'out';
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: _stockFilter == 'out' ? Border.all(color: AppColors.occupied, width: 2) : null,
            ),
            child: StatBadgeWidget(
              title: 'نافد من المخزن',
              value: '$outOfStock أصناف',
              icon: Icons.remove_shopping_cart,
              accentColor: AppColors.occupied,
            ),
          ),
        ),
        if (isAdmin) ...[
          StatBadgeWidget(
            title: 'قيمة بضاعة المخزن (سعر الشراء)',
            value: AppFormatters.formatCurrency(inventoryCostValue),
            icon: Icons.account_balance_wallet_outlined,
            accentColor: AppColors.warning,
          ),
          StatBadgeWidget(
            title: 'قيمة المبيعات التقديرية',
            value: AppFormatters.formatCurrency(inventorySellingValue),
            icon: Icons.point_of_sale,
            accentColor: AppColors.cyanAccent,
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryFilterChip(String label, String? categoryValue) {
    final isSelected = _selectedCategory == categoryValue;

    return Padding(
      padding: const EdgeInsets.only(left: 6.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.cyanAccent.withAlpha(35),
        backgroundColor: AppColors.surfaceLight,
        side: BorderSide(
          color: isSelected ? AppColors.cyanAccent : AppColors.cardBorder,
        ),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textSecondary,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (_) {
          setState(() {
            _selectedCategory = categoryValue;
          });
        },
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    ProductModel product,
    MarketProvider marketProvider,
    bool isAdmin,
  ) {
    final isOutOfStock = product.isOutOfStock;
    final isLowStock = product.isLowStock;

    final Color stockColor = isOutOfStock
        ? AppColors.occupied
        : (isLowStock ? AppColors.warning : AppColors.available);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOutOfStock
              ? AppColors.occupied.withAlpha(90)
              : (isLowStock ? AppColors.warning.withAlpha(70) : AppColors.cardBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header: Name & Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  product.category == 'سناكس'
                      ? Icons.cookie_outlined
                      : (product.category == 'وجبات سريعة'
                          ? Icons.fastfood_outlined
                          : (product.category == 'مشروبات ساخنة'
                              ? Icons.coffee
                              : Icons.local_drink)),
                  color: AppColors.cyanAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                    ),
                    if (product.category != null && product.category!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        product.category!,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: stockColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: stockColor.withAlpha(70)),
                ),
                child: Text(
                  isOutOfStock ? 'نافد' : (isLowStock ? 'منخفض (${product.stockQuantity})' : 'متوفر (${product.stockQuantity})'),
                  style: TextStyle(color: stockColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          // Pricing & Cost Details
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('سعر البيع:', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                      Text(
                        AppFormatters.formatCurrency(product.sellingPrice),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                if (isAdmin) ...[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text('سعر الشراء:', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                        Text(
                          AppFormatters.formatCurrency(product.costPrice),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('الربح/قطعة:', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                        Text(
                          AppFormatters.formatCurrency(product.profitPerUnit),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.available, fontWeight: FontWeight.bold, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Bottom Controls: Restock button & Edit/Delete for Admin
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Stock quantity badge
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'الرصيد: ${product.stockQuantity} قطعة',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: stockColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Action buttons (Protected: Admin Only)
              if (isAdmin)
                Row(
                  children: [
                    // Quick Restock Button for this specific item
                    IconButton(
                      icon: const Icon(Icons.add_shopping_cart, size: 18, color: AppColors.available),
                      tooltip: 'توريد هذه المادة',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _openRestockDialog(context, initialProduct: product),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18, color: AppColors.textSecondary),
                      tooltip: 'تعديل المنتج',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _openEditProductDialog(context, product),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.occupied),
                      tooltip: 'حذف المنتج',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _confirmDeleteProduct(context, product, marketProvider),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _openRestockDialog(BuildContext context, {ProductModel? initialProduct}) {
    showDialog(
      context: context,
      builder: (_) => RestockMarketDialog(initialProduct: initialProduct),
    );
  }

  void _openAddProductDialog(BuildContext context) {
    final marketProvider = Provider.of<MarketProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (_) => ProductFormDialog(
        onSave: (prod) => marketProvider.addProduct(prod),
      ),
    );
  }

  void _openEditProductDialog(BuildContext context, ProductModel product) {
    final marketProvider = Provider.of<MarketProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (_) => ProductFormDialog(
        productToEdit: product,
        onSave: (prod) => marketProvider.updateProduct(prod),
      ),
    );
  }

  void _confirmDeleteProduct(
    BuildContext context,
    ProductModel product,
    MarketProvider marketProvider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: AppColors.occupied, size: 22),
            SizedBox(width: 8),
            Text('تأكيد حذف المنتج', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Text('هل أنت متأكد من رغبتك في حذف الصنف "${product.name}" نهائياً من الماركيت؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await marketProvider.deleteProduct(product.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.occupied,
                    content: Text('تم حذف "${product.name}" من الماركيت'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.occupied),
            child: const Text('حذف الصنف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
