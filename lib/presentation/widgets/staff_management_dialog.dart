import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/models.dart';
import '../../data/services/firestore_service.dart';
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
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _selectedRole = 'staff';
  bool _isAdding = false;
  bool _isSaving = false;
  bool _obscurePassword = true;

  final FirestoreService _firestoreService = FirestoreService();

  // Local fallback demo staff list if Firestore is empty
  final List<UserModel> _fallbackStaffList = const [
    UserModel(uid: 'admin_1', name: 'حسين المنصور', username: 'admin', role: 'admin'),
    UserModel(uid: 'staff_1', name: 'أحمد السامرائي', username: 'ahmed', role: 'staff'),
    UserModel(uid: 'staff_2', name: 'علي الكرخي', username: 'ali', role: 'staff'),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
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

            // Staff List from Firestore Stream
            Expanded(
              child: StreamBuilder<List<UserModel>>(
                stream: _firestoreService.getStaffUsersStream(),
                builder: (context, snapshot) {
                  final staffList = (snapshot.hasData && snapshot.data!.isNotEmpty)
                      ? snapshot.data!
                      : _fallbackStaffList;

                  return ListView.builder(
                    itemCount: staffList.length,
                    itemBuilder: (context, index) {
                      final staff = staffList[index];
                      final isAdmin = staff.isAdmin;

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
                                    staff.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  Text(
                                    '@${staff.displayUsername}',
                                    style: const TextStyle(
                                      color: AppColors.cyanAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
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
                            const SizedBox(width: 4),
                            // Edit User Button
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.cyanAccent),
                              tooltip: 'تعديل الحساب',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _showEditUserDialog(context, staff, authProvider, staffList),
                            ),
                            const SizedBox(width: 6),
                            // Delete User Button
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.occupied),
                              tooltip: 'حذف الحساب',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () async {
                                final totalAdmins = staffList.where((u) => u.isAdmin).length;

                                // Prevent deleting the last remaining admin
                                if (isAdmin && totalAdmins <= 1) {
                                  await showDialog(
                                    context: context,
                                    builder: (c) => AlertDialog(
                                      backgroundColor: AppColors.surface,
                                      title: const Row(
                                        children: [
                                          Icon(Icons.shield_outlined, color: AppColors.warning),
                                          SizedBox(width: 8),
                                          Text('تنبيه أمان النظام'),
                                        ],
                                      ),
                                      content: const Text(
                                        'لا يمكن حذف حساب المدير الوحيد! يجب أن يحتوي النظام على حساب مدير (Admin) آخر نشط على الأقل لمنع إغلاق لوحة التحكم بدون إدارة.',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                      actions: [
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(c),
                                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNeon),
                                          child: const Text('حسناً فهمت'),
                                        ),
                                      ],
                                    ),
                                  );
                                  return;
                                }

                                final isSelf = staff.uid == authProvider.currentUser?.uid ||
                                    staff.username == authProvider.currentUser?.username;

                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    backgroundColor: AppColors.surface,
                                    title: const Text('تأكيد الحذف'),
                                    content: Text(
                                      isSelf
                                          ? 'تحذير: أنت على وشك حذف حسابك الحالي "${staff.name}"! سيتم تسجيل خروجك فوراً بعد تأكيد الحذف.'
                                          : 'هل أنت متأكد من حذف حساب "${staff.name}" نهائياً من النظام؟',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(c, false),
                                        child: const Text('إلغاء'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(c, true),
                                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.occupied),
                                        child: const Text('تأكيد الحذف'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  final success = await authProvider.deleteStaffUser(staff.uid);
                                  if (context.mounted) {
                                    if (success) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          backgroundColor: AppColors.occupied,
                                          content: Text('تم حذف حساب "${staff.name}" بنجاح'),
                                        ),
                                      );
                                      if (isSelf) {
                                        Navigator.of(context).pop();
                                      }
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          backgroundColor: AppColors.occupied,
                                          content: Text(authProvider.errorMessage ?? 'فشل حذف الحساب'),
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
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
              // 1. Full Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'الاسم الكامل *',
                  hintText: 'مثال: مصطفى علي',
                  prefixIcon: Icon(Icons.person_outline, size: 20),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'الاسم الكامل مطلوب' : null,
              ),
              const SizedBox(height: 10),
              // 2. Username
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المستخدم (Username) *',
                  hintText: 'مثال: mustafa99',
                  prefixIcon: Icon(Icons.alternate_email, size: 20),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'اسم المستخدم مطلوب';
                  if (v.trim().length < 3) return 'الحد الأدنى 3 أحرف';
                  if (v.trim().contains(' ')) return 'اسم المستخدم لا يجب أن يحتوي على مسافات';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              // 3. Password
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور / الرمز السري (Password / PIN) *',
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
              // 4. Role
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
                      onPressed: _isSaving
                          ? null
                          : () {
                              setState(() {
                                _isAdding = false;
                                _nameController.clear();
                                _usernameController.clear();
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
                      onPressed: _isSaving
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;
                              final name = _nameController.text.trim();
                              final username = _usernameController.text.trim().toLowerCase();
                              final password = _passwordController.text.trim();

                              setState(() => _isSaving = true);

                              final success = await authProvider.registerStaffUser(
                                name: name,
                                username: username,
                                password: password,
                                role: _selectedRole,
                              );

                              if (!mounted) return;
                              setState(() => _isSaving = false);

                              if (success) {
                                setState(() {
                                  _isAdding = false;
                                  _nameController.clear();
                                  _usernameController.clear();
                                  _passwordController.clear();
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppColors.available,
                                    content: Text('تم حفظ وتأكيد حساب الموظف "$name" بنجاح في قاعدة البيانات'),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppColors.occupied,
                                    content: Text(authProvider.errorMessage ?? 'حدث خطأ أثناء حفظ الحساب'),
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.available),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('حفظ وإضافة الحساب'),
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

  Future<void> _showEditUserDialog(
    BuildContext context,
    UserModel user,
    AuthProvider authProvider,
    List<UserModel> staffList,
  ) async {
    final editFormKey = GlobalKey<FormState>();
    final editNameController = TextEditingController(text: user.name);
    final editPasswordController = TextEditingController(text: user.password ?? '');
    String editRole = user.role;
    bool editObscurePassword = true;
    bool isSavingEdit = false;

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.cardBorder),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryNeon.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit, color: AppColors.cyanAccent, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'تعديل حساب @${user.displayUsername}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: editFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Full Name
                      TextFormField(
                        controller: editNameController,
                        decoration: const InputDecoration(
                          labelText: 'الاسم الكامل *',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'الاسم مطلوب' : null,
                      ),
                      const SizedBox(height: 12),

                      // Password / PIN
                      TextFormField(
                        controller: editPasswordController,
                        obscureText: editObscurePassword,
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور / الرمز السري الجديد',
                          hintText: 'اتركه كما هو إذا لم ترغب في التغيير',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              editObscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () => setDialogState(() => editObscurePassword = !editObscurePassword),
                          ),
                        ),
                        validator: (v) {
                          if (v != null && v.isNotEmpty && v.trim().length < 4) {
                            return 'الحد الأدنى لكلمة المرور 4 خانات';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Role
                      DropdownButtonFormField<String>(
                        initialValue: editRole,
                        decoration: const InputDecoration(
                          labelText: 'نوع الصلاحية',
                          prefixIcon: Icon(Icons.security),
                        ),
                        dropdownColor: AppColors.surface,
                        items: const [
                          DropdownMenuItem(value: 'staff', child: Text('موظف صالة (Staff)')),
                          DropdownMenuItem(value: 'admin', child: Text('مدير عام (Admin)')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => editRole = val);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSavingEdit ? null : () => Navigator.pop(dialogCtx),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: isSavingEdit
                    ? null
                    : () async {
                        if (!editFormKey.currentState!.validate()) return;

                        // Verify at least one admin remains
                        if (user.isAdmin && editRole != 'admin') {
                          final totalAdmins = staffList.where((u) => u.isAdmin).length;
                          if (totalAdmins <= 1) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: AppColors.occupied,
                                content: Text('لا يمكن خفض صلاحية هذا الحساب. يجب وجود مدير (Admin) آخر نشط على الأقل.'),
                              ),
                            );
                            return;
                          }
                        }

                        setDialogState(() => isSavingEdit = true);

                        final newPassword = editPasswordController.text.trim().isNotEmpty
                            ? editPasswordController.text.trim()
                            : user.password;

                        final updatedUser = user.copyWith(
                          name: editNameController.text.trim(),
                          role: editRole,
                          password: newPassword,
                        );

                        final success = await authProvider.updateStaffUser(updatedUser);

                        if (!dialogCtx.mounted) return;
                        setDialogState(() => isSavingEdit = false);

                        if (success) {
                          Navigator.pop(dialogCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.available,
                              content: Text('تم تحديث بيانات حساب "${updatedUser.name}" بنجاح في قاعدة البيانات'),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.occupied,
                              content: Text(authProvider.errorMessage ?? 'حدث خطأ أثناء تحديث الحساب'),
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.available),
                child: isSavingEdit
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('تأكيد التعديلات وحفظها'),
              ),
            ],
          );
        },
      ),
    );
  }
}
