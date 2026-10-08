import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/erp_provider.dart';
import '../models/app_models.dart';
import '../theme/app_theme.dart';
import '../widgets/user_avatar.dart';
import 'main_layout.dart';

/// شاشة تسجيل الدخول التنفيذية - اختيار المستخدم + رمز PIN
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> with TickerProviderStateMixin {
  UserAccount? _selectedUser;
  String _pin = '';
  bool _showSetup = false;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _shake() {
    _shakeCtrl.forward(from: 0);
  }

  void _addDigit(String d) {
    if (_pin.length < 6) {
      setState(() => _pin += d);
      if (_pin.length == 6) {
        _tryLogin();
      }
    }
  }

  void _removeDigit() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  Future<void> _tryLogin() async {
    if (_selectedUser == null || _pin.length < 4) return;
    final auth = context.read<AuthProvider>();
    final result = await auth.login(_selectedUser!.id, _pin);
    if (!mounted) return;

    if (result.isSuccess) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainLayout()),
      );
    } else {
      setState(() => _pin = '');
      _shake();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(result.errorMessage ?? 'رمز PIN غير صحيح')),
            ],
          ),
          backgroundColor: AppTheme.dangerButton,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.needsFirstSetup || _showSetup) {
      return _FirstSetupScreen(
        onDone: () => setState(() => _showSetup = false),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBg,
        body: SafeArea(
          child: _selectedUser == null
              ? _UserSelectionScreen(
                  users: auth.users,
                  onSelect: (u) => setState(() {
                    _selectedUser = u;
                    _pin = '';
                  }),
                )
              : _PinScreen(
                  user: _selectedUser!,
                  pin: _pin,
                  shakeAnim: _shakeAnim,
                  onDigit: _addDigit,
                  onDelete: _removeDigit,
                  onLogin: _tryLogin,
                  onBack: () => setState(() {
                    _selectedUser = null;
                    _pin = '';
                  }),
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// شاشة اختيار المستخدم (تصميم احترافي متوازن)
// ─────────────────────────────────────────────────────────

class _UserSelectionScreen extends StatelessWidget {
  final List<UserAccount> users;
  final ValueChanged<UserAccount> onSelect;

  const _UserSelectionScreen({required this.users, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final erp = context.watch<ErpProvider>();
    final companyName = erp.settings.companyName.isNotEmpty
        ? erp.settings.companyName
        : 'نظام إدارة المطبعة';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // الشعار وهوية المطبعة
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.28), width: 1.2),
                ),
                child: const Icon(Icons.print_rounded, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 18),
              Text(
                companyName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryLight,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'نظام ERP وإدارة العمليات المطبعية',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // بطاقات المستخدمين
              if (users.length == 1)
                _SingleUserCard(user: users.first, onTap: onSelect)
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'اختر حسابك لتسجيل الدخول:',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: users.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _UserCard(user: users[i], onTap: onSelect),
                    ),
                  ],
                ),

              const SizedBox(height: 36),
              // تذييل النظام
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSecondary,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield_outlined, size: 14, color: AppTheme.primaryLight),
                    const SizedBox(width: 6),
                    Text(
                      'بيانات محلية • دخول محمي برمز PIN',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// بطاقة احترافية في حالة وجود مستخدم واحد (مثل المدير فقط)
class _SingleUserCard extends StatelessWidget {
  final UserAccount user;
  final ValueChanged<UserAccount> onTap;

  const _SingleUserCard({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBg, // Dark Slate Card
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: user.role == UserRole.admin
              ? AppTheme.primaryLight.withValues(alpha: 0.35)
              : AppTheme.borderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          UserAvatar.fromUser(user, size: 76, showBadge: true),
          const SizedBox(height: 16),
          Text(
            user.displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.selectedSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_user_rounded, size: 14, color: AppTheme.primaryLight),
                const SizedBox(width: 5),
                Text(
                  user.role == UserRole.admin ? 'مدير النظام • صلاحيات كاملة' : user.role.label,
                  style: const TextStyle(
                    color: AppTheme.primaryLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => onTap(user),
              icon: const Icon(Icons.lock_open_rounded, size: 18),
              label: const Text(
                'تسجيل الدخول بالـ PIN',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة مستخدم ضمن قائمة المستخدمين المتعددين
class _UserCard extends StatelessWidget {
  final UserAccount user;
  final ValueChanged<UserAccount> onTap;

  const _UserCard({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: user.isActive ? () => onTap(user) : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: user.role == UserRole.admin
                  ? AppTheme.primaryLight.withValues(alpha: 0.3)
                  : AppTheme.borderColor,
            ),
          ),
          child: Row(
            children: [
              UserAvatar.fromUser(user, size: 48, showBadge: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user.role == UserRole.admin ? 'مدير النظام' : 'موظف النظام',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// شاشة إدخال رمز PIN (تصميم مريح وتفاعلي)
// ─────────────────────────────────────────────────────────

class _PinScreen extends StatelessWidget {
  final UserAccount user;
  final String pin;
  final Animation<double> shakeAnim;
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final VoidCallback onLogin;
  final VoidCallback onBack;

  const _PinScreen({
    required this.user,
    required this.pin,
    required this.shakeAnim,
    required this.onDigit,
    required this.onDelete,
    required this.onLogin,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // زر العودة لاختيار مستخدم
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_forward_ios, size: 14),
                  label: const Text('تغيير الحساب'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryLight,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // الأفاتار واسم المستخدم
              UserAvatar.fromUser(user, size: 76, showBadge: true),
              const SizedBox(height: 14),
              Text(
                user.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSecondary,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Text(
                  user.role == UserRole.admin ? 'مدير النظام • صلاحيات كاملة' : user.role.label,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'أدخل رمز المرور السري (PIN)',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),

              // مؤشر PIN (دوائر تفاعلية ذات توهج)
              AnimatedBuilder(
                animation: shakeAnim,
                builder: (_, child) {
                  final offset = (shakeAnim.value * 14 *
                          (1 - shakeAnim.value) *
                          (shakeAnim.value > 0.5 ? -1 : 1))
                      .clamp(-12.0, 12.0);
                  return Transform.translate(
                    offset: Offset(offset, 0),
                    child: child,
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (i) {
                    final filled = i < pin.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutBack,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: filled ? 16 : 14,
                      height: filled ? 16 : 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled ? AppTheme.primaryLight : AppTheme.surfaceSecondary,
                        border: Border.all(
                          color: filled ? AppTheme.primaryLight : AppTheme.borderColor,
                          width: 1.8,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 28),

              // لوحة الأرقام LTR حصراً لترتيب الأرقام عالمياً بشكل طبيعي 1 2 3
              Directionality(
                textDirection: TextDirection.ltr,
                child: _PinPad(
                  onDigit: onDigit,
                  onDelete: onDelete,
                  onConfirm: onLogin,
                  canConfirm: pin.length >= 4,
                  hasInput: pin.isNotEmpty,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinPad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final VoidCallback onConfirm;
  final bool canConfirm;
  final bool hasInput;

  const _PinPad({
    required this.onDigit,
    required this.onDelete,
    required this.onConfirm,
    required this.canConfirm,
    required this.hasInput,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // الصف الأول: 1, 2, 3
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _PinButton(digit: '1', subText: '', onTap: () => onDigit('1')),
            _PinButton(digit: '2', subText: 'ABC', onTap: () => onDigit('2')),
            _PinButton(digit: '3', subText: 'DEF', onTap: () => onDigit('3')),
          ],
        ),
        const SizedBox(height: 14),
        // الصف الثاني: 4, 5, 6
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _PinButton(digit: '4', subText: 'GHI', onTap: () => onDigit('4')),
            _PinButton(digit: '5', subText: 'JKL', onTap: () => onDigit('5')),
            _PinButton(digit: '6', subText: 'MNO', onTap: () => onDigit('6')),
          ],
        ),
        const SizedBox(height: 14),
        // الصف الثالث: 7, 8, 9
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _PinButton(digit: '7', subText: 'PQRS', onTap: () => onDigit('7')),
            _PinButton(digit: '8', subText: 'TUV', onTap: () => onDigit('8')),
            _PinButton(digit: '9', subText: 'WXYZ', onTap: () => onDigit('9')),
          ],
        ),
        const SizedBox(height: 14),
        // الصف الرابع: [تأكيد / دخول] [0] [حذف ⌫]
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // زر التأكيد (يظهر بتأثير زمردي عند كتابة 4 أرقام على الأقل)
            _PinActionButton(
              icon: Icons.check_rounded,
              onTap: canConfirm ? onConfirm : null,
              isActive: canConfirm,
              isConfirm: true,
            ),
            // رقم صفر
            _PinButton(digit: '0', subText: '+', onTap: () => onDigit('0')),
            // زر الحذف
            _PinActionButton(
              icon: Icons.backspace_outlined,
              onTap: hasInput ? onDelete : null,
              isActive: hasInput,
              isConfirm: false,
            ),
          ],
        ),
      ],
    );
  }
}

/// زر رقمي فاخر بهوية أنظمة الهواتف الحديثة (iOS / OneUI Passcode)
class _PinButton extends StatelessWidget {
  final String digit;
  final String subText;
  final VoidCallback onTap;

  const _PinButton({
    required this.digit,
    required this.subText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(38),
        splashColor: AppTheme.primaryLight.withValues(alpha: 0.18),
        highlightColor: AppTheme.primaryLight.withValues(alpha: 0.08),
        child: Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.surfaceSecondary,
            border: Border.all(color: AppTheme.borderColor, width: 1.2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                digit,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w400,
                  height: 1.1,
                ),
              ),
              if (subText.isNotEmpty)
                Text(
                  subText,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                )
              else
                const SizedBox(height: 11),
            ],
          ),
        ),
      ),
    );
  }
}

/// أزرار الإجراءات في لوحة الأرقام (تأكيد / حذف)
class _PinActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isActive;
  final bool isConfirm;

  const _PinActionButton({
    required this.icon,
    required this.onTap,
    required this.isActive,
    required this.isConfirm,
  });

  @override
  Widget build(BuildContext context) {
    if (!isActive && isConfirm) {
      return const SizedBox(width: 74, height: 74);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(38),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isConfirm && isActive
                ? AppTheme.primaryGreen
                : (isActive ? AppTheme.surfaceSecondary : Colors.transparent),
            border: Border.all(
              color: isConfirm && isActive
                  ? AppTheme.primaryLight
                  : (isActive ? AppTheme.borderColor : Colors.transparent),
              width: 1.2,
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              size: isConfirm ? 28 : 23,
              color: isActive ? AppTheme.textPrimary : AppTheme.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// شاشة الإعداد الأول - إنشاء حساب المدير العام (تصميم تنفيذي راقٍ)
// ─────────────────────────────────────────────────────────

class _FirstSetupScreen extends StatefulWidget {
  final VoidCallback onDone;
  const _FirstSetupScreen({required this.onDone});

  @override
  State<_FirstSetupScreen> createState() => _FirstSetupScreenState();
}

class _FirstSetupScreenState extends State<_FirstSetupScreen> {
  final _nameCtrl = TextEditingController(text: 'مدير المطبعة');
  final _pinCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String _selectedColorId = 'emerald';
  bool _obscurePin = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(() => setState(() {}));
  }

  Future<void> _create() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'يرجى إدخال اسم المسؤول أو المدير');
      return;
    }
    if (_pinCtrl.text.length < 4) {
      setState(() => _error = 'رمز PIN يجب أن يتكون من 4 أرقام على الأقل');
      return;
    }
    if (_pinCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'رمز PIN غير متطابق في خانة التأكيد');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    final err = await auth.createUser(
      username: 'admin',
      displayName: _nameCtrl.text.trim(),
      pin: _pinCtrl.text,
      role: UserRole.admin,
      avatarEmoji: _selectedColorId,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (err != null) {
      setState(() => _error = err);
    } else {
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    final erp = context.watch<ErpProvider>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBg,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // الشعار
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.28)),
                      ),
                      child: const Icon(Icons.print_rounded, color: Colors.white, size: 38),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      erp.settings.companyName.isNotEmpty
                          ? erp.settings.companyName
                          : 'نظام ERP المطبعة',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'مرحباً بك! إعداد حساب المسؤول الرئيسي (Admin)',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // بطاقة الإعداد
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderColor),
                  boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // معاينة الأفاتار الحي
                          Center(
                            child: Column(
                              children: [
                                UserAvatar(
                                  displayName: _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'A',
                                  role: UserRole.admin,
                                  colorIdOrEmoji: _selectedColorId,
                                  size: 72,
                                  showBadge: true,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'اختر النمط اللوني لحسابك:',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // منتقي الألوان التنفيذية
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: kExecutiveColors.map((ec) {
                                    final isSelected = ec.id == _selectedColorId;
                                    return GestureDetector(
                                      onTap: () => setState(() => _selectedColorId = ec.id),
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [ec.primary, ec.secondary],
                                          ),
                                          border: Border.all(
                                            color: isSelected ? Colors.white : Colors.transparent,
                                            width: 2.2,
                                          ),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: ec.primary.withValues(alpha: 0.6),
                                                    blurRadius: 8,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: isSelected
                                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                                            : null,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Divider(color: AppTheme.borderColor),
                          const SizedBox(height: 16),

                          // الحقول
                          _buildLabel('اسم المسؤول أو المدير'),
                          _buildField(
                            _nameCtrl,
                            'مثال: مدير المطبعة / أحمد محمد',
                            Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 16),

                          _buildLabel('رمز المرور السري PIN (من 4 إلى 6 أرقام)'),
                          _buildField(
                            _pinCtrl,
                            '••••••',
                            Icons.lock_outline_rounded,
                            isPin: true,
                          ),
                          const SizedBox(height: 16),

                          _buildLabel('تأكيد رمز PIN'),
                          _buildField(
                            _confirmCtrl,
                            '••••••',
                            Icons.lock_reset_rounded,
                            isPin: true,
                          ),

                          if (_error != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.danger.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: AppTheme.danger, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: const TextStyle(color: AppTheme.danger, fontSize: 12.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: _loading ? null : _create,
                              icon: _loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.check_circle_outline_rounded),
                              label: Text(
                                _loading ? 'جاري إنشاء الحساب...' : 'حفظ وبدء تشغيل النظام',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    bool isPin = false,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: isPin && _obscurePin,
      keyboardType: isPin ? TextInputType.number : TextInputType.name,
      maxLength: isPin ? 6 : null,
      style: const TextStyle(color: Colors.white, fontSize: 14.5),
      decoration: InputDecoration(
        counterText: '',
        hintText: hint,
        hintStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
        suffixIcon: isPin
            ? IconButton(
                icon: Icon(
                  _obscurePin ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePin = !_obscurePin),
              )
            : null,
        filled: true,
        fillColor: AppTheme.surfaceSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryLight, width: 1.5),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _pinCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }
}
