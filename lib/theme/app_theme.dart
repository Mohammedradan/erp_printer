import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppTheme {
  // الألوان الرئيسية المستوحاة من هوية المطابع الراقية وروح ملف الإكسل
  static const Color primaryGreen = Color(0xFF0F5132); // أخضر مطبعي عميق
  static const Color primaryLight = Color(0xFF198754);
  static const Color accentGold = Color(0xFFD97706); // ذهبي/عنبري راقي
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color cardBg = Colors.white;
  static const Color scaffoldBg = Color(0xFFF1F5F9); // رمادي فاتح مريح
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: scaffoldBg,
      fontFamily: 'Cairo', // يدعم الخطوط العربية الافتراضية
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        secondary: accentGold,
        surface: cardBg,
        surfaceTint: Colors.transparent,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: darkSlate,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: darkSlate,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderColor, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titleTextStyle: const TextStyle(
          color: darkSlate,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
        ),
        contentTextStyle: const TextStyle(
          color: darkSlate,
          fontSize: 14,
          fontFamily: 'Cairo',
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderColor, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderColor, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryLight, width: 1.8),
        ),
        labelStyle: const TextStyle(fontSize: 13, color: textMuted, fontWeight: FontWeight.w500),
        floatingLabelStyle: const TextStyle(fontSize: 13, color: primaryGreen, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }

  // دوال تنسيق الأرقام والعملات والتواريخ
  static String formatCurrency(num value, [String currency = 'ريال']) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return '${formatter.format(value)} $currency';
  }

  static String formatNumber(num value) {
    final formatter = NumberFormat('#,##0.##', 'en_US');
    return formatter.format(value);
  }

  static String formatDate(DateTime date) {
    return DateFormat('yyyy/MM/dd').format(date);
  }

  // بطاقة شارة الحالة
  static Widget statusBadge(String status) {
    Color bg = const Color(0xFFF1F5F9);
    Color fg = textMuted;
    IconData icon = Icons.info_outline;

    switch (status) {
      case 'معتمد':
      case 'نشطة':
      case 'طبيعي':
      case 'مكتمل':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        icon = Icons.check_circle_outline;
        break;
      case 'قيد الإنتاج':
      case 'إعادة طلب':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        icon = Icons.warning_amber_rounded;
        break;
      case 'مسودة':
        bg = const Color(0xFFE2E8F0);
        fg = const Color(0xFF475569);
        icon = Icons.edit_note;
        break;
      case 'نافد':
      case 'ملغي':
      case 'مرفوض':
      case 'موقوفة':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
        icon = Icons.cancel_outlined;
        break;
      case 'دخول':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        icon = Icons.arrow_downward;
        break;
      case 'خروج':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
        icon = Icons.arrow_upward;
        break;
      case 'تسوية':
        bg = const Color(0xFFE0E7FF);
        fg = const Color(0xFF4338CA);
        icon = Icons.tune;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              status,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
