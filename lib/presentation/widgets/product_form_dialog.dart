import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';

/// Dialog to add a new product or edit an existing product in the market inventory
class ProductFormDialog extends StatefulWidget {
  final ProductModel? productToEdit;
  final Function(ProductModel product) onSave;

  const ProductFormDialog({
    super.key,
    this.productToEdit,
    required this.onSave,
  });

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _costPriceController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _stockController;
  String _selectedCategory = 'مشروبات باردة';

  final List<String> _defaultCategories = [
    'مشروبات باردة',
    'مشروبات طاقة',
    'سناكس',
    'وجبات سريعة',
    'مشروبات ساخنة',
    'إضافات وأخرى',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    _nameController = TextEditingController(text: p?.name ?? '');
    _costPriceController = TextEditingController(
      text: p != null ? p.costPrice.toStringAsFixed(0) : '',
    );
    _sellingPriceController = TextEditingController(
      text: p != null ? p.sellingPrice.toStringAsFixed(0) : '',
    );
    _stockController = TextEditingController(
      text: p != null ? p.stockQuantity.toString() : '10',
    );
    if (p?.category != null && p!.category!.isNotEmpty) {
      if (!_defaultCategories.contains(p.category)) {
        _defaultCategories.add(p.category!);
      }
      _selectedCategory = p.category!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  double get _currentCostPrice => double.tryParse(_costPriceController.text.trim()) ?? 0.0;
  double get _currentSellingPrice => double.tryParse(_sellingPriceController.text.trim()) ?? 0.0;
  double get _estimatedProfit => _currentSellingPrice - _currentCostPrice;

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.productToEdit != null;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                    child: Icon(
                      isEditing ? Icons.edit_note : Icons.add_box_outlined,
                      color: AppColors.cyanAccent,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'تعديل بيانات المنتج' : 'إضافة منتج جديد للمخزن',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          isEditing ? 'تحديث الأسعار أو الكميات المتوفرة' : 'تسجيل منتج ومخزون وسعر الشراء/البيع',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(),

              // Form fields
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),

                      // Product Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'اسم المنتج *',
                          hintText: 'مثال: ريد بول / بيبسي / ليز...',
                          prefixIcon: Icon(Icons.shopping_bag_outlined, color: AppColors.textSecondary),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'يرجى إدخال اسم المنتج';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      // Category Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'فئة المنتج',
                          prefixIcon: Icon(Icons.category_outlined, color: AppColors.textSecondary),
                        ),
                        dropdownColor: AppColors.surfaceLight,
                        items: _defaultCategories.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Text(cat),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedCategory = val;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 14),

                      // Prices Row
                      Row(
                        children: [
                          // Cost Price
                          Expanded(
                            child: TextFormField(
                              controller: _costPriceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'سعر الشراء (التكلفة) *',
                                hintText: 'مثال: 500',
                                suffixText: 'د.ع',
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'مطلوب';
                                }
                                if (double.tryParse(val) == null) {
                                  return 'رقم غير صحيح';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Selling Price
                          Expanded(
                            child: TextFormField(
                              controller: _sellingPriceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'سعر البيع للزبون *',
                                hintText: 'مثال: 1000',
                                suffixText: 'د.ع',
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'مطلوب';
                                }
                                if (double.tryParse(val) == null) {
                                  return 'رقم غير صحيح';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Stock Quantity
                      TextFormField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'الكمية المتوفرة بالمخزن *',
                          hintText: 'مثال: 24',
                          prefixIcon: Icon(Icons.inventory_2_outlined, color: AppColors.textSecondary),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'يرجى إدخال الكمية بالمخزن';
                          }
                          if (int.tryParse(val) == null) {
                            return 'يجب أن تكون الكمية رقماً صحيحاً';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Live Profit Preview Badge
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _estimatedProfit >= 0
                              ? AppColors.available.withAlpha(20)
                              : AppColors.occupied.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _estimatedProfit >= 0
                                ? AppColors.available.withAlpha(60)
                                : AppColors.occupied.withAlpha(60),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    _estimatedProfit >= 0 ? Icons.trending_up : Icons.trending_down,
                                    color: _estimatedProfit >= 0 ? AppColors.available : AppColors.occupied,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'هامش الربح المتوقع للقطعة:',
                                      style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppFormatters.formatCurrency(_estimatedProfit),
                              style: TextStyle(
                                color: _estimatedProfit >= 0 ? AppColors.available : AppColors.occupied,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _submitForm,
                      icon: const Icon(Icons.save),
                      label: Text(isEditing ? 'حفظ التعديلات' : 'إضافة المنتج'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNeon,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final cost = double.parse(_costPriceController.text.trim());
    final selling = double.parse(_sellingPriceController.text.trim());
    final stock = int.parse(_stockController.text.trim());
    final name = _nameController.text.trim();

    final product = (widget.productToEdit ?? ProductModel(
      id: const Uuid().v4(),
      name: name,
      costPrice: cost,
      sellingPrice: selling,
      stockQuantity: stock,
      category: _selectedCategory,
    )).copyWith(
      name: name,
      costPrice: cost,
      sellingPrice: selling,
      stockQuantity: stock,
      category: _selectedCategory,
    );

    widget.onSave(product);
    Navigator.pop(context);
  }
}
