import 'package:flutter/material.dart';
import '../models/app_models.dart';

/// باقة الألوان التنفيذية المعتمدة لحسابات النظام بدلاً من الرموز الكرتونية
class ExecutiveColor {
  final String id;
  final String label;
  final Color primary;
  final Color secondary;

  const ExecutiveColor({
    required this.id,
    required this.label,
    required this.primary,
    required this.secondary,
  });
}

const List<ExecutiveColor> kExecutiveColors = [
  ExecutiveColor(
    id: 'emerald',
    label: 'أخضر ملكي',
    primary: Color(0xFF0F5132),
    secondary: Color(0xFF198754),
  ),
  ExecutiveColor(
    id: 'sapphire',
    label: 'أزرق ياقوتي',
    primary: Color(0xFF1E3A8A),
    secondary: Color(0xFF2563EB),
  ),
  ExecutiveColor(
    id: 'violet',
    label: 'بنفسجي إداري',
    primary: Color(0xFF5B21B6),
    secondary: Color(0xFF7C3AED),
  ),
  ExecutiveColor(
    id: 'amber',
    label: 'عنبري ذهبي',
    primary: Color(0xFF92400E),
    secondary: Color(0xFFD97706),
  ),
  ExecutiveColor(
    id: 'teal',
    label: 'فيروزي حديث',
    primary: Color(0xFF115E59),
    secondary: Color(0xFF0D9488),
  ),
  ExecutiveColor(
    id: 'slate',
    label: 'رمادي تنفيذي',
    primary: Color(0xFF1E293B),
    secondary: Color(0xFF475569),
  ),
];

ExecutiveColor getColorById(String id) {
  return kExecutiveColors.firstWhere(
    (c) => c.id == id,
    orElse: () => kExecutiveColors.first,
  );
}

/// أيقونة الأفاتار الاحترافية للمستخدمين (Monogram + Role Badge)
class UserAvatar extends StatelessWidget {
  final String displayName;
  final UserRole role;
  final String? colorIdOrEmoji;
  final double size;
  final bool showBadge;

  const UserAvatar({
    super.key,
    required this.displayName,
    required this.role,
    this.colorIdOrEmoji,
    this.size = 48,
    this.showBadge = true,
  });

  factory UserAvatar.fromUser(UserAccount user, {double size = 48, bool showBadge = true}) {
    return UserAvatar(
      displayName: user.displayName,
      role: user.role,
      colorIdOrEmoji: user.avatarEmoji,
      size: size,
      showBadge: showBadge,
    );
  }

  /// استخراج الحرف الأول أو الحرفين الأوائل من الاسم للـ Monogram
  String get _initials {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      return role == UserRole.admin ? 'A' : 'U';
    }
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0].characters.first}${parts[1].characters.first}'.toUpperCase();
    }
    return trimmed.characters.take(2).toString().toUpperCase();
  }

  ExecutiveColor get _color {
    final raw = colorIdOrEmoji ?? '';
    // مطابقة id معروف
    for (final ec in kExecutiveColors) {
      if (ec.id == raw) return ec;
    }
    // التوزيع التلقائي حسب الدور
    if (role == UserRole.admin) {
      return kExecutiveColors[0]; // Emerald
    } else {
      return kExecutiveColors[1]; // Sapphire
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    final badgeSize = (size * 0.36).clamp(16.0, 26.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // الدائرة الرئيسية مع تدرج لوني وحدود راقية
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.primary, color.secondary],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.primary.withValues(alpha: 0.35),
                  blurRadius: size * 0.25,
                  offset: Offset(0, size * 0.08),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: size >= 60 ? 2.5 : 1.5,
              ),
            ),
            child: Center(
              child: role == UserRole.admin && displayName.trim().toLowerCase() == 'admin'
                  ? Icon(
                      Icons.shield_rounded,
                      size: size * 0.52,
                      color: Colors.white,
                    )
                  : Text(
                      _initials,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size * 0.40,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),

          // شارة الدور في زاوية الأفاتار (اختياري)
          if (showBadge)
            Positioned(
              bottom: -1,
              left: -1,
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: role == UserRole.admin
                      ? const Color(0xFFD97706) // ذهبي أنيق للمدير
                      : const Color(0xFF0284C7),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4),
                  ],
                ),
                child: Center(
                  child: Icon(
                    role == UserRole.admin
                        ? Icons.admin_panel_settings_rounded
                        : Icons.badge_rounded,
                    size: badgeSize * 0.62,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
