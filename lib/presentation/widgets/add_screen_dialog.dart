import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/screen_provider.dart';

/// Modal dialog allowing Admins to add a new screen/table to the lounge
class AddScreenDialog extends StatefulWidget {
  const AddScreenDialog({super.key});

  @override
  State<AddScreenDialog> createState() => _AddScreenDialogState();
}

class _AddScreenDialogState extends State<AddScreenDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _screenNumberController = TextEditingController();
  final TextEditingController _screenNameController = TextEditingController();
  final TextEditingController _customSectionController = TextEditingController();

  String _selectedDeviceType = 'PS5';
  String _selectedSection = 'الصالة العامة';
  bool _isSaving = false;

  final List<String> _deviceTypes = [
    'PS5',
    'PS4',
    'PC',
    'Xbox',
    'VR / أخرى',
  ];

  final List<String> _sectionOptions = [
    'الصالة العامة',
    'قسم VIP 1',
    'قسم VIP 2',
    'غرفة خاصة 1',
    'غرفة خاصة 2',
    'مخصص...',
  ];

  @override
  void initState() {
    super.initState();
    final screenProvider = Provider.of<ScreenProvider>(context, listen: false);
    final existingNumbers = screenProvider.screens.map((s) => s.screenNumber).toSet();
    int nextNumber = 1;
    while (existingNumbers.contains(nextNumber)) {
      nextNumber++;
    }
    _screenNumberController.text = nextNumber.toString();
  }

  @override
  void dispose() {
    _screenNumberController.dispose();
    _screenNameController.dispose();
    _customSectionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final screenProvider = Provider.of<ScreenProvider>(context, listen: false);

    final screenNum = int.parse(_screenNumberController.text.trim());
    final customName = _screenNameController.text.trim();
    final finalSection = _selectedSection == 'مخصص...'
        ? _customSectionController.text.trim()
        : _selectedSection;

    final created = await screenProvider.addNewScreen(
      screenNumber: screenNum,
      name: customName.isNotEmpty ? customName : null,
      deviceType: _selectedDeviceType,
      sectionName: finalSection.isNotEmpty ? finalSection : null,
    );

    setState(() => _isSaving = false);

    if (mounted) {
      if (created != null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.available,
            content: Text('تمت إضافة ${created.nameArabic} بنجاح!'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.occupied,
            content: Text('حدث خطأ أثناء إضافة الشاشة'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
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
                        color: AppColors.primaryNeon.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.tv, color: AppColors.primaryLight, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'إضافة شاشة / طاولة جديدة',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'توسيع شبكة شاشات الصالة وإتاحتها للعب المباشر',
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

                // 1. Screen Number
                TextFormField(
                  controller: _screenNumberController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'رقم الشاشة / الطاولة *',
                    hintText: 'مثال: 9',
                    prefixIcon: Icon(Icons.pin, color: AppColors.textSecondary),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'يرجى إدخال رقم الشاشة';
                    final parsed = int.tryParse(v.trim());
                    if (parsed == null || parsed <= 0) return 'رقم غير صحيح';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // 2. Custom Screen Name (Optional)
                TextFormField(
                  controller: _screenNameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم الشاشة (اختياري)',
                    hintText: 'مثال: شاشة VIP 1 أو طاولة PC 4',
                    prefixIcon: Icon(Icons.label_outline, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Device Type
                const Text(
                  'نوع الجهاز المشبوك (Device Type):',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _deviceTypes.map((type) {
                    final isSelected = _selectedDeviceType == type;
                    return ChoiceChip(
                      label: Text(type),
                      selected: isSelected,
                      selectedColor: AppColors.cyanAccent.withAlpha(40),
                      backgroundColor: AppColors.surfaceLight,
                      side: BorderSide(
                        color: isSelected ? AppColors.cyanAccent : AppColors.cardBorder,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onSelected: (_) => setState(() => _selectedDeviceType = type),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // 4. Section / Room
                const Text(
                  'القسم أو الغرفة (Room / Section):',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedSection,
                  dropdownColor: AppColors.surfaceLight,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.meeting_room_outlined, color: AppColors.textSecondary),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _sectionOptions.map((sec) {
                    return DropdownMenuItem(
                      value: sec,
                      child: Text(sec, style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSection = val);
                  },
                ),

                if (_selectedSection == 'مخصص...') ...[
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _customSectionController,
                    decoration: const InputDecoration(
                      labelText: 'اسم القسم المخصص',
                      hintText: 'اكتب اسم القسم أو الصالة',
                      prefixIcon: Icon(Icons.edit_location_alt, color: AppColors.textSecondary),
                    ),
                    validator: (v) => _selectedSection == 'مخصص...' && (v == null || v.trim().isEmpty)
                        ? 'يرجى كتابة اسم القسم'
                        : null,
                  ),
                ],

                const SizedBox(height: 22),

                // Action Buttons
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
                          backgroundColor: AppColors.primaryNeon,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add, color: Colors.white, size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    'إضافة الشاشة فوراً',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
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
