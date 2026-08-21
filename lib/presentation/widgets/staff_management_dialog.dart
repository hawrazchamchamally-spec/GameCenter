import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

/// Modal dialog for managing staff accounts (Admin Only)
class StaffManagementDialog extends StatefulWidget {
  const StaffManagementDialog({super.key});

  @override
  State<StaffManagementDialog> createState() => _StaffManagementDialogState();
}

class _StaffManagementDialogState extends State<StaffManagementDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _selectedRole = 'staff';
  bool _isAdding = false;
  bool _obscurePassword = true;

  // Local demo staff list
  final List<Map<String, String>> _staffList = [
    {'name': 'أحمد السامرائي', 'email': 'ahmed.staff@gamelounge.iq', 'role': 'staff'},
    {'name': 'علي الكرخي', 'email': 'ali.staff@gamelounge.iq', 'role': 'staff'},
    {'name': 'حسين المنصور', 'email': 'hussein.manager@gamelounge.iq', 'role': 'admin'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: Column(
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
                  child: const Icon(Icons.badge_outlined, color: AppColors.primaryLight, size: 26),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إدارة الموظفين والصلاحيات',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'إضافة كابتن صالة وتحديد الصلاحيات التشغيلية للمدير والموظفين',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),

            // Add Staff toggle
            if (!_isAdding)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _isAdding = true),
                  icon: const Icon(Icons.person_add),
                  label: const Text('إضافة حساب موظف جديد'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNeon,
                  ),
                ),
              )
            else
              _buildAddStaffForm(authProvider),

            const SizedBox(height: 12),
            const Text(
              'قائمة الموظفين الحاليين:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            // Staff List
            Expanded(
              child: ListView.builder(
                itemCount: _staffList.length,
                itemBuilder: (context, index) {
                  final staff = _staffList[index];
                  final isAdmin = staff['role'] == 'admin';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: isAdmin
                              ? AppColors.primaryNeon.withAlpha(40)
                              : AppColors.cyanAccent.withAlpha(40),
                          child: Icon(
                            isAdmin ? Icons.admin_panel_settings : Icons.person,
                            color: isAdmin ? AppColors.primaryLight : AppColors.cyanAccent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                staff['name']!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  fontSize: 13.5,
                                ),
                              ),
                              Text(
                                staff['email']!,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isAdmin
                                ? AppColors.primaryNeon.withAlpha(20)
                                : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isAdmin ? AppColors.primaryNeon : AppColors.cardBorder,
                            ),
                          ),
                          child: Text(
                            isAdmin ? 'مدير صالة' : 'موظف / كابتن',
                            style: TextStyle(
                              color: isAdmin ? AppColors.primaryLight : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.occupied),
                          tooltip: 'حذف الحساب',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            setState(() {
                              _staffList.removeAt(index);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.occupied,
                                content: Text('تم حذف حساب ${staff['name']}'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            // Close button
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إغلاق'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddStaffForm(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'بيانات الموظف الجديد:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم الموظف *',
                  hintText: 'مثال: مصطفى علي',
                  prefixIcon: Icon(Icons.person_outline, size: 20),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'اسم الموظف مطلوب' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني / اسم الدخول *',
                  hintText: 'mustafa.staff@gamelounge.iq',
                  prefixIcon: Icon(Icons.email_outlined, size: 20),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'البريد الإلكتروني مطلوب' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور / رمز الدخول (Password / PIN) *',
                  hintText: 'أدخل كلمة مرور أو رمز سري للدخول...',
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'كلمة المرور مطلوبة';
                  if (v.trim().length < 4) return 'الحد الأدنى 4 خانات';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'نوع الصلاحية',
                  prefixIcon: Icon(Icons.security, size: 20),
                ),
                dropdownColor: AppColors.surface,
                items: const [
                  DropdownMenuItem(value: 'staff', child: Text('موظف صالة (صلاحيات تشغيلية فقط)')),
                  DropdownMenuItem(value: 'admin', child: Text('مدير عام (صلاحيات كاملة 100%)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedRole = val);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _isAdding = false;
                          _passwordController.clear();
                        });
                      },
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;
                        final name = _nameController.text.trim();
                        final email = _emailController.text.trim();
                        final password = _passwordController.text.trim();

                        setState(() {
                          _staffList.add({
                            'name': name,
                            'email': email,
                            'role': _selectedRole,
                          });
                          _isAdding = false;
                          _nameController.clear();
                          _emailController.clear();
                          _passwordController.clear();
                        });

                        await authProvider.registerStaffUser(
                          name: name,
                          email: email,
                          password: password,
                          role: _selectedRole,
                        );

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.available,
                              content: Text('تمت إضافة الموظف "$name" بكلمة المرور المحددة بنجاح'),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.available),
                      child: const Text('حفظ وإضافة الحساب'),
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
}
