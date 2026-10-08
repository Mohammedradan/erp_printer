import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Dark-first design tokens and Material theme shared by every ERP module.
class AppTheme {
  // Surfaces
  static const Color scaffoldBg = Color(0xFF171D29);
  static const Color sidebarBg = Color(0xFF202938);
  static const Color cardBg = Color(0xFF273243);
  static const Color surfaceSecondary = Color(0xFF303C4D);
  static const Color borderColor = Color(0xFF3A4658);
  static const Color selectedSurface = Color(0xFF123C32);
  static const Color successSurface = Color(0xFF173D32);
  static const Color warningSurface = Color(0xFF49351F);
  static const Color dangerSurface = Color(0xFF472B34);
  static const Color infoSurface = Color(0xFF1D3851);

  // Print-house green identity and semantic colors
  static const Color primaryGreen = Color(0xFF07553B);
  static const Color primaryLight = Color(0xFF10B981);
  static const Color accentGold = Color(0xFFF59E0B);
  static const Color success = Color(0xFF4ADE80);
  static const Color warning = Color(0xFFFBBF24);
  static const Color danger = Color(0xFFF87171);
  static const Color dangerButton = Color(0xFFB42332);
  static const Color info = Color(0xFF60A5FA);

  // Text tokens. Keep the old names as aliases while screens migrate to tokens.
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFFA7B3C5);
  static const Color darkSlate = textPrimary;
  static const Color textDark = textPrimary;
  static const Color textMuted = textSecondary;

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryLight,
      brightness: Brightness.dark,
      primary: primaryLight,
      onPrimary: const Color(0xFF062C21),
      secondary: primaryGreen,
      onSecondary: Colors.white,
      error: danger,
      onError: const Color(0xFF2B1115),
      surface: cardBg,
      onSurface: textPrimary,
      surfaceTint: Colors.transparent,
    ).copyWith(
      outline: borderColor,
      outlineVariant: borderColor,
      surfaceContainerLowest: scaffoldBg,
      surfaceContainerLow: sidebarBg,
      surfaceContainer: cardBg,
      surfaceContainerHigh: surfaceSecondary,
      surfaceContainerHighest: surfaceSecondary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: scaffoldBg,
      canvasColor: cardBg,
      dialogBackgroundColor: cardBg,
      fontFamily: 'Cairo',
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: textPrimary),
        displayMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: textPrimary),
        displaySmall: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: textPrimary),
        headlineLarge: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: textPrimary),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary),
        headlineSmall: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: textPrimary),
        titleLarge: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: textPrimary),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: TextStyle(fontSize: 15, color: textPrimary),
        bodyMedium: TextStyle(fontSize: 13, color: textPrimary),
        bodySmall: TextStyle(fontSize: 12, color: textSecondary),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: textSecondary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: sidebarBg,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 58,
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
        iconTheme: IconThemeData(color: textSecondary, size: 21),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderColor),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        shadowColor: Colors.black.withValues(alpha: 0.32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary),
        contentTextStyle: const TextStyle(fontSize: 14, color: textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceSecondary,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: primaryLight, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: danger, width: 1.5),
        ),
        labelStyle: const TextStyle(fontSize: 13, color: textSecondary),
        floatingLabelStyle: const TextStyle(fontSize: 13, color: primaryLight, fontWeight: FontWeight.w600),
        hintStyle: const TextStyle(fontSize: 13, color: textSecondary),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: surfaceSecondary,
          disabledForegroundColor: textSecondary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLight,
          side: const BorderSide(color: borderColor),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(surfaceSecondary),
        headingTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary),
        dataTextStyle: const TextStyle(fontSize: 12, color: textPrimary),
        dividerThickness: 0.7,
        horizontalMargin: 16,
        columnSpacing: 22,
        headingRowHeight: 46,
        dataRowMinHeight: 46,
        dataRowMaxHeight: 64,
      ),
      dividerTheme: const DividerThemeData(color: borderColor, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surfaceSecondary,
        contentTextStyle: const TextStyle(color: textPrimary, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: borderColor),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: sidebarBg,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primaryGreen.withValues(alpha: 0.52),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? textPrimary : textSecondary,
          );
        }),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surfaceSecondary,
        surfaceTintColor: Colors.transparent,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(11),
          side: const BorderSide(color: borderColor),
        ),
        textStyle: const TextStyle(fontSize: 13, color: textPrimary),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: sidebarBg,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
        tileColor: Colors.transparent,
        selectedColor: primaryLight,
        selectedTileColor: selectedSurface,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: primaryLight,
        unselectedLabelColor: textSecondary,
        indicatorColor: primaryLight,
        dividerColor: borderColor,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: surfaceSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        textStyle: const TextStyle(color: textPrimary, fontSize: 12),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryLight,
        linearTrackColor: surfaceSecondary,
        circularTrackColor: surfaceSecondary,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: cardBg,
        showDragHandle: true,
      ),
      iconTheme: const IconThemeData(color: textSecondary),
      visualDensity: VisualDensity.standard,
    );
  }

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

  /// Compact semantic status pill shared by tables and mobile record cards.
  static Widget statusBadge(String status) {
    late final Color background;
    late final Color foreground;
    late final IconData icon;

    switch (status) {
      case 'معتمد':
      case 'نشطة':
      case 'طبيعي':
      case 'مكتمل':
      case 'جاهز للتسليم':
      case 'دخول':
        background = successSurface;
        foreground = success;
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'قيد الإنتاج':
      case 'قيد التجهيز':
      case 'قيد الطباعة':
      case 'التشطيب والتجليد':
      case 'إعادة طلب':
      case 'مرسل':
        background = warningSurface;
        foreground = warning;
        icon = Icons.schedule_rounded;
        break;
      case 'مسودة':
      case 'تسوية':
        background = surfaceSecondary;
        foreground = textSecondary;
        icon = Icons.edit_note_rounded;
        break;
      case 'نافد':
      case 'ملغي':
      case 'مرفوض':
      case 'موقوفة':
      case 'خروج':
        background = dangerSurface;
        foreground = danger;
        icon = Icons.error_outline_rounded;
        break;
      default:
        background = surfaceSecondary;
        foreground = textSecondary;
        icon = Icons.info_outline_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 5),
          Text(
            status,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: foreground, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
