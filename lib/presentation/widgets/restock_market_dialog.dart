import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/market_provider.dart';

/// Modal Dialog for restocking inventory items with admin supervision and cost updates
class RestockMarketDialog extends StatefulWidget {
  final ProductModel? initialProduct;

  const RestockMarketDialog({
    super.key,
    this.initialProduct,
  });

  @override
  State<RestockMarketDialog> createState() => _RestockMarketDialogState();
}

class _RestockMarketDialogState extends State<RestockMarketDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedProductId;
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _costPriceController = TextEditingController();
  final TextEditingController _sellingPriceController = TextEditingController();
  final TextEditingController _adminController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _adminController.text = authProvider.currentUser?.name ?? 'مدير الصالة';

    if (widget.initialProduct != null) {
      _selectProduct(widget.initialProduct!);
    }
  }

  void _selectProduct(ProductModel product) {
    setState(() {
      _selectedProductId = product.id;
      _costPriceController.text = product.costPrice.toStringAsFixed(0);
      _sellingPriceController.text = product.sellingPrice.toStringAsFixed(0);
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _adminController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.occupied,
          content: Text('يرجى اختيار المنتج المراد توريده أولاً'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final marketProvider = Provider.of<MarketProvider>(context, listen: false);

    final incomingQty = int.parse(_quantityController.text.trim());
    final costPrice = double.parse(_costPriceController.text.trim());
    final sellingPrice = double.parse(_sellingPriceController.text.trim());
    final adminName = _adminController.text.trim();
    final notes = _notesController.text.trim();

    final result = await marketProvider.restockProduct(
      productId: _selectedProductId!,
      incomingQuantity: incomingQty,
      unitCostPrice: costPrice,
      unitSellingPrice: sellingPrice,
      approvedByAdmin: adminName.isNotEmpty ? adminName : 'مدير الصالة',
      notes: notes.isNotEmpty ? notes : null,
    );

    setState(() => _isSaving = false);

    if (mounted) {
      if (result != null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.available,
            content: Text(
              'تم توريد +$incomingQty قطعة لـ "${result.productName}" بنجاح وتسجيل العملية في التقارير!',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.occupied,
            content: Text('حدث خطأ أثناء حفظ عملية التوريد'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final marketProvider = Provider.of<MarketProvider>(context);
    final allProducts = marketProvider.allProducts;

    ProductModel? currentProduct;
    if (_selectedProductId != null) {
      currentProduct = allProducts.firstWhere(
        (p) => p.id == _selectedProductId,
        orElse: () => allProducts.isNotEmpty
            ? allProducts.first
            : ProductModel(
                id: '',
                name: '',
                costPrice: 0,
                sellingPrice: 0,
                stockQuantity: 0,
              ),
      );
    }

    final incomingQty = int.tryParse(_quantityController.text.trim()) ?? 0;
    final costPrice = double.tryParse(_costPriceController.text.trim()) ?? 0.0;
    final sellingPrice = double.tryParse(_sellingPriceController.text.trim()) ?? 0.0;
    final totalBatchCost = incomingQty * costPrice;
    final profitPerUnit = sellingPrice - costPrice;
    final newStockTotal = (currentProduct?.stockQuantity ?? 0) + incomingQty;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 780),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.available.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.inventory, color: AppColors.available, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تعبئة وتوريد بضاعة المخزن (Restock)',
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'إضافة كميات جديدة، تحديث الأسعار، واعتمادها رسمياً',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // 1. Select Existing Product
                const Text(
                  'اختر الصنف المراد توريده *',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedProductId,
                  isExpanded: true,
                  dropdownColor: AppColors.surfaceLight,
                  decoration: const InputDecoration(
                    hintText: 'اختر منتج من القائمة...',
                    prefixIcon: Icon(Icons.fastfood_outlined, color: AppColors.textSecondary),
                  ),
                  items: allProducts.map((prod) {
                    return DropdownMenuItem(
                      value: prod.id,
                      child: Text(
                        '${prod.name} (${prod.category ?? 'ماركيت'}) - الرصيد: ${prod.stockQuantity}',
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      final prod = allProducts.firstWhere((p) => p.id == val);
                      _selectProduct(prod);
                    }
                  },
                  validator: (v) => v == null || v.isEmpty ? 'يرجى اختيار الصنف' : null,
                ),

                if (currentProduct != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('الرصيد الحالي بالمخزن:', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text(
                          '${currentProduct.stockQuantity} قطعة',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: currentProduct.isOutOfStock ? AppColors.occupied : AppColors.cyanAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // 2. Incoming Quantity
                TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'الكمية الواردة الجديدة (+) *',
                    hintText: 'مثال: 24',
                    prefixIcon: Icon(Icons.add_box_outlined, color: AppColors.available),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'يرجى إدخال الكمية';
                    final parsed = int.tryParse(v.trim());
                    if (parsed == null || parsed <= 0) return 'الكمية يجب أن تكون أكبر من 0';
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: 14),

                // 3. Pricing (Cost & Selling)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _costPriceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'سعر الشراء للقطعة *',
                          suffixText: 'د.ع',
                          prefixIcon: Icon(Icons.attach_money, color: AppColors.warning),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'يرجى إدخال التكلفة';
                          final parsed = double.tryParse(v.trim());
                          if (parsed == null || parsed < 0) return 'سعر غير صحيح';
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _sellingPriceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'سعر البيع للزبون *',
                          suffixText: 'د.ع',
                          prefixIcon: Icon(Icons.point_of_sale, color: AppColors.cyanAccent),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'يرجى إدخال سعر البيع';
                          final parsed = double.tryParse(v.trim());
                          if (parsed == null || parsed <= 0) return 'سعر غير صحيح';
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 4. Batch Financial Summary Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('إجمالي تكلفة الشراء للوجبة:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text(
                            AppFormatters.formatCurrency(totalBatchCost),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.warning),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('الرصيد الجديد بعد الحفظ:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text(
                            '$newStockTotal قطعة',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.available),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('هامش الربح المتوقع للقطعة:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text(
                            AppFormatters.formatCurrency(profitPerUnit),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: profitPerUnit >= 0 ? AppColors.available : AppColors.occupied,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 5. Admin Supervisor & Notes
                TextFormField(
                  controller: _adminController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المسؤول المشرف على التوريد *',
                    prefixIcon: Icon(Icons.admin_panel_settings_outlined, color: AppColors.textSecondary),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'يرجى إدخال اسم المسؤول' : null,
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات / رقم وصل التوريد (اختياري)',
                    prefixIcon: Icon(Icons.receipt_outlined, color: AppColors.textSecondary),
                  ),
                ),

                const SizedBox(height: 20),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.available,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline, color: Colors.black, size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    'تأكيد وحفظ التوريد',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
