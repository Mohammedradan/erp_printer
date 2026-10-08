import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/app_models.dart';
import '../theme/app_theme.dart';
import '../widgets/user_avatar.dart';
import '../widgets/erp_components.dart';

/// شاشة إدارة المستخدمين والصلاحيات (للمدير العام فقط)
class UserManagementView extends StatelessWidget {
  const UserManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final isNarrow = MediaQuery.sizeOf(context).width < 600;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.all(isNarrow ? 12 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ErpPageHeader(
              title: 'إدارة المستخدمين والصلاحيات',
              subtitle: 'إدارة الحسابات والأدوار ورموز الدخول الخاصة بفريق المطبعة',
              icon: Icons.manage_accounts_outlined,
              actions: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: const Text('إضافة مستخدم'),
                  onPressed: () => _showAddUserDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: auth.users.isEmpty
                  ? const ErpEmptyState(
                      title: 'لا يوجد مستخدمون مسجلون',
                      message: 'أضف حساباً للموظف الذي سيستخدم النظام.',
                      icon: Icons.group_outlined,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 12),
                      itemCount: auth.users.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _UserTile(user: auth.users[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const _AddUserDialog(),
    );
  }
}

// ─────────────────────────────────────────────────────────
// بطاقة المستخدم
// ─────────────────────────────────────────────────────────

class _UserTile extends StatelessWidget {
  final UserAccount user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final isCurrentUser = auth.currentUser?.id == user.id;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: user.role == UserRole.admin
              ? AppTheme.primaryLight.withValues(alpha: 0.4)
              : AppTheme.borderColor,
          width: user.role == UserRole.admin ? 1.5 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: UserAvatar.fromUser(user, size: 48, showBadge: true),
        title: Row(
          children: [
            Text(
              user.displayName,
              style: const TextStyle(
                color: AppTheme.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            if (isCurrentUser) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.successSurface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: const Text(
                  'أنت (الحالي)',
                  style: TextStyle(color: AppTheme.success, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: user.role == UserRole.admin
                      ? AppTheme.successSurface
                      : AppTheme.infoSurface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: user.role == UserRole.admin
                        ? AppTheme.borderColor
                        : AppTheme.borderColor,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      user.role == UserRole.admin
                          ? Icons.shield_rounded
                          : Icons.badge_outlined,
                      size: 13,
                      color: user.role == UserRole.admin
                          ? AppTheme.success
                          : AppTheme.info,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user.role == UserRole.admin ? 'مدير النظام' : 'موظف',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: user.role == UserRole.admin
                            ? AppTheme.success
                            : AppTheme.info,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '@${user.username}',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(width: 8),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: user.isActive ? AppTheme.primaryLight : AppTheme.danger,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                user.isActive ? 'نشط' : 'معطل',
                style: TextStyle(
                  fontSize: 11,
                  color: user.isActive ? AppTheme.success : AppTheme.danger,
                ),
              ),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppTheme.textMuted),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          onSelected: (action) => _handleAction(action, context, auth),
          itemBuilder: (_) => [
            _menuItem('edit', Icons.edit_outlined, 'تعديل البيانات'),
            _menuItem('pin', Icons.lock_reset_outlined, 'تغيير رمز PIN'),
            if (!isCurrentUser)
              _menuItem(
                'toggle',
                user.isActive ? Icons.block : Icons.check_circle_outline,
                user.isActive ? 'تعطيل الحساب' : 'تفعيل الحساب',
              ),
            if (!isCurrentUser)
              _menuItem(
                'delete',
                Icons.delete_outline,
                'حذف المستخدم',
                isDestructive: true,
              ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    String label, {
    bool isDestructive = false,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: isDestructive ? AppTheme.danger : AppTheme.textDark),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(color: isDestructive ? AppTheme.danger : AppTheme.textDark, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(
    String action,
    BuildContext ctx,
    AuthProvider auth,
  ) async {
    switch (action) {
      case 'edit':
        showDialog(context: ctx, builder: (_) => _EditUserDialog(user: user));
        break;
      case 'pin':
        showDialog(context: ctx, builder: (_) => _ChangePinDialog(user: user));
        break;
      case 'toggle':
        final error = await auth.toggleUserStatus(user.id);
        if (!ctx.mounted) return;
        if (error != null) _showError(ctx, error);
        break;
      case 'delete':
        _confirmDelete(ctx, auth);
        break;
    }
  }

  /// يعرض رفض العملية (صلاحية/آخر مدير) بدل تجاهله بصمت.
  void _showError(BuildContext ctx, String message) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.dangerButton,
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, AuthProvider auth) {
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تأكيد حذف المستخدم'),
        content: Text('هل تريد بالتأكيد حذف حساب "${user.displayName}"؟ لا يمكن التراجع.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(dialogCtx);
              final error = await auth.deleteUser(user.id);
              Navigator.pop(dialogCtx);
              if (error != null) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(error),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppTheme.dangerButton,
                  ),
                );
              }
            },
            child: const Text('حذف الحساب', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// ديالوج إضافة مستخدم جديد
// ─────────────────────────────────────────────────────────

class _AddUserDialog extends StatefulWidget {
  const _AddUserDialog();

  @override
  State<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<_AddUserDialog> {
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  UserRole _role = UserRole.employee;
  String _colorId = 'sapphire';
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('إضافة مستخدم جديد للنظام', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // المعاينة الحية للأفاتار
              Center(
                child: Column(
                  children: [
                    UserAvatar(
                      displayName: _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'U',
                      role: _role,
                      colorIdOrEmoji: _colorId,
                      size: 60,
                      showBadge: true,
                    ),
                    const SizedBox(height: 10),
                    // اختيار اللون التنفيذي
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: kExecutiveColors.map((ec) {
                        final isSelected = ec.id == _colorId;
                        return GestureDetector(
                          onTap: () => setState(() => _colorId = ec.id),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(colors: [ec.primary, ec.secondary]),
                              border: Border.all(
                                color: isSelected ? AppTheme.darkSlate : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _field(_nameCtrl, 'الاسم الكامل للمستخدم', Icons.person_outline),
              const SizedBox(height: 10),
              _field(_usernameCtrl, 'اسم الدخول (e.g. ahmed)', Icons.alternate_email),
              const SizedBox(height: 10),
              _field(_pinCtrl, 'رمز PIN (4 إلى 6 أرقام)', Icons.lock_outline, isPin: true),
              const SizedBox(height: 14),
              // اختيار الدور
              const Text('صلاحية الدور:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Row(
                children: [
                  _roleChip('موظف (تشغيل وتسعير)', UserRole.employee),
                  const SizedBox(width: 8),
                  _roleChip('مدير (كامل الصلاحيات)', UserRole.admin),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 12)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('إضافة المستخدم'),
          ),
        ],
      ),
    );
  }

  Widget _roleChip(String label, UserRole role) {
    final selected = _role == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _role = role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryGreen : AppTheme.surfaceSecondary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppTheme.primaryGreen : AppTheme.borderColor,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppTheme.textDark,
              fontSize: 11.5,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon, {bool isPin = false}) {
    return TextField(
      controller: ctrl,
      obscureText: isPin,
      keyboardType: isPin ? TextInputType.number : TextInputType.text,
      maxLength: isPin ? 6 : null,
      decoration: InputDecoration(
        counterText: '',
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppTheme.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty || _usernameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'يرجى إكمال جميع البيانات');
      return;
    }
    if (_pinCtrl.text.length < 4) {
      setState(() => _error = 'رمز PIN يجب أن يكون 4 أرقام على الأقل');
      return;
    }

    final auth = context.read<AuthProvider>();
    final err = await auth.createUser(
      username: _usernameCtrl.text.trim(),
      displayName: _nameCtrl.text.trim(),
      pin: _pinCtrl.text,
      role: _role,
      avatarEmoji: _colorId,
    );

    if (!mounted) return;
    if (err != null) {
      setState(() => _error = err);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────
// ديالوج تعديل مستخدم
// ─────────────────────────────────────────────────────────

class _EditUserDialog extends StatefulWidget {
  final UserAccount user;
  const _EditUserDialog({required this.user});

  @override
  State<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<_EditUserDialog> {
  late TextEditingController _nameCtrl;
  late String _colorId;
  late UserRole _role;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.displayName);
    _colorId = widget.user.avatarEmoji;
    _role = widget.user.role;
    _nameCtrl.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تعديل بيانات المستخدم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    UserAvatar(
                      displayName: _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'U',
                      role: _role,
                      colorIdOrEmoji: _colorId,
                      size: 60,
                      showBadge: true,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: kExecutiveColors.map((ec) {
                        final isSelected = ec.id == _colorId;
                        return GestureDetector(
                          onTap: () => setState(() => _colorId = ec.id),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(colors: [ec.primary, ec.secondary]),
                              border: Border.all(
                                color: isSelected ? AppTheme.darkSlate : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'الاسم الكامل',
                  prefixIcon: const Icon(Icons.person_outline, size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 14),
              const Text('الدور والصلاحيات:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Row(
                children: [
                  _roleBtn('موظف', UserRole.employee),
                  const SizedBox(width: 8),
                  _roleBtn('مدير', UserRole.admin),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final auth = context.read<AuthProvider>();
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              final error = await auth.updateUser(widget.user.copyWith(
                displayName: _nameCtrl.text.trim(),
                role: _role,
                avatarEmoji: _colorId,
              ));
              navigator.pop();
              if (error != null) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(error),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppTheme.dangerButton,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('حفظ التعديلات'),
          ),
        ],
      ),
    );
  }

  Widget _roleBtn(String label, UserRole role) {
    final selected = _role == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _role = role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryGreen : AppTheme.surfaceSecondary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppTheme.primaryGreen : AppTheme.borderColor,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppTheme.textDark,
              fontSize: 12,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────
// ديالوج تغيير رمز PIN
// ─────────────────────────────────────────────────────────

class _ChangePinDialog extends StatefulWidget {
  final UserAccount user;
  const _ChangePinDialog({required this.user});

  @override
  State<_ChangePinDialog> createState() => _ChangePinDialogState();
}

class _ChangePinDialogState extends State<_ChangePinDialog> {
  final _newPinCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'تغيير رمز PIN - ${widget.user.displayName}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _pinField(_newPinCtrl, 'رمز PIN الجديد'),
            const SizedBox(height: 10),
            _pinField(_confirmCtrl, 'تأكيد رمز PIN'),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 12)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('تحديث PIN'),
          ),
        ],
      ),
    );
  }

  Widget _pinField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      obscureText: true,
      keyboardType: TextInputType.number,
      maxLength: 6,
      decoration: InputDecoration(
        counterText: '',
        hintText: hint,
        prefixIcon: const Icon(Icons.lock_outline, size: 18),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _save() async {
    if (_newPinCtrl.text.length < 4) {
      setState(() => _error = 'رمز PIN يجب أن يكون 4 أرقام على الأقل');
      return;
    }
    if (_newPinCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'رمز PIN غير متطابق');
      return;
    }

    final auth = context.read<AuthProvider>();
    final error = await auth.changeUserPin(widget.user.id, _newPinCtrl.text);
    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم تحديث رمز PIN بنجاح ✅'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _newPinCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }
}
