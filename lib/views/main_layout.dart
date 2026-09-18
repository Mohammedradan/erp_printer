import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/erp_provider.dart';
import '../providers/auth_provider.dart';
import '../models/app_models.dart';
import '../theme/app_theme.dart';
import 'dashboard_view.dart';
import 'pricing_calculator_view.dart';
import 'quotations_view.dart';
import 'production_orders_view.dart';
import 'paper_stock_view.dart';
import 'ink_stock_view.dart';
import 'customers_view.dart';
import 'payments_view.dart';
import 'profitability_view.dart';
import 'master_data_view.dart';
import 'settings_view.dart';
import 'price_management_view.dart';
import 'user_management_view.dart';
import 'login_view.dart';
import '../widgets/user_avatar.dart';

class MainLayout extends StatefulWidget {
  final int initialIndex;
  const MainLayout({super.key, this.initialIndex = 0});

  @override
  State<MainLayout> createState() => MainLayoutState();
}

class MainLayoutState extends State<MainLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late int _selectedIndex;
  bool _isSidebarCollapsed = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void setTab(int index) {
    setState(() => _selectedIndex = index);
  }


  int _priceManagementSubTab = 0;

  void navigateToTab(int viewIndex, [int subTab = 0]) {
    setState(() {
      _selectedIndex = viewIndex;
      if (viewIndex == 11) {
        _priceManagementSubTab = subTab;
      }
    });
  }

  Widget _buildCurrentView() {
    switch (_selectedIndex) {
      case 0:
        return DashboardView(onNavigate: (idx) => setState(() => _selectedIndex = idx));
      case 1:
        return PricingCalculatorView(onNavigate: (idx) => setState(() => _selectedIndex = idx));
      case 2:
        return QuotationsView(onNavigate: (idx) => setState(() => _selectedIndex = idx));
      case 3:
        return const ProductionOrdersView();
      case 4:
        return const PaperStockView();
      case 5:
        return const InkStockView();
      case 6:
        return CustomersView(onNavigate: (idx) => setState(() => _selectedIndex = idx));
      case 7:
        return const PaymentsView();
      case 8:
        return const MasterDataView();
      case 9:
        return const ProfitabilityView();
      case 10:
        return SettingsView(
          onNavigate: (idx) => setState(() => _selectedIndex = idx),
          onNavigateWithTab: (idx, subTab) => navigateToTab(idx, subTab),
        );
      case 11:
        return PriceManagementView(
          onNavigate: (idx) => setState(() => _selectedIndex = idx),
          initialTab: _priceManagementSubTab,
        );
      case 12:
        return const UserManagementView();
      default:
        return DashboardView(onNavigate: (idx) => setState(() => _selectedIndex = idx));
    }
  }

  /// جميع عناصر التنقل (للبحث عن العنصر الحالي)
  NavItem _getCurrentNavItem() {
    final allItems = [
      NavItem(index: 0, title: 'لوحة المؤشرات', icon: Icons.dashboard_outlined),
      NavItem(index: 1, title: 'محرك التسعير الحي', icon: Icons.calculate_outlined),
      NavItem(index: 2, title: 'عروض الأسعار', icon: Icons.request_quote_outlined),
      NavItem(index: 3, title: 'أوامر الإنتاج', icon: Icons.precision_manufacturing_outlined),
      NavItem(index: 4, title: 'قاعدة الورق والمخزون', icon: Icons.inventory_2_outlined),
      NavItem(index: 5, title: 'مخزون الأحبار', icon: Icons.colorize_outlined),
      NavItem(index: 6, title: 'العملاء وحسابات الذمم', icon: Icons.people_alt_outlined),
      NavItem(index: 7, title: 'المدفوعات وسندات القبض', icon: Icons.receipt_long_outlined),
      NavItem(index: 8, title: 'الماكينات والقوالب والتشطيب', icon: Icons.settings_suggest_outlined),
      NavItem(index: 9, title: 'تقارير الربحية والتحليل', icon: Icons.analytics_outlined),
      NavItem(index: 10, title: 'إعدادات النظام', icon: Icons.settings_outlined),
      NavItem(index: 11, title: 'إدارة الأسعار والتكاليف', icon: Icons.price_change_outlined),
      NavItem(index: 12, title: 'إدارة المستخدمين', icon: Icons.manage_accounts_outlined),
    ];
    try {
      return allItems.firstWhere((item) => item.index == _selectedIndex);
    } catch (_) {
      return allItems.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final erp = context.watch<ErpProvider>();
    final auth = context.watch<AuthProvider>();
    final currentUser = auth.currentUser;
    final isAdmin = auth.isAdmin;
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final currentItem = _getCurrentNavItem();
    final todayStr = AppTheme.formatDate(DateTime.now());

    // قائمة التنقل الديناميكية حسب الصلاحيات
    final List<NavSection> navSections = [
      NavSection(title: 'لوحة التحكم والعمليات', items: [
        NavItem(index: 0, title: 'لوحة المؤشرات', icon: Icons.dashboard_outlined),
        NavItem(index: 1, title: 'محرك التسعير الحي', icon: Icons.calculate_outlined),
        if (isAdmin)
          NavItem(index: 11, title: 'إدارة الأسعار والتكاليف', icon: Icons.price_change_outlined),
        NavItem(index: 2, title: 'عروض الأسعار', icon: Icons.request_quote_outlined),
        NavItem(index: 3, title: 'أوامر الإنتاج', icon: Icons.precision_manufacturing_outlined),
      ]),
      NavSection(title: 'المخزون والمواد', items: [
        NavItem(index: 4, title: 'قاعدة الورق والمخزون', icon: Icons.inventory_2_outlined),
        NavItem(index: 5, title: 'مخزون الأحبار', icon: Icons.colorize_outlined),
      ]),
      NavSection(title: 'العملاء والمالية', items: [
        NavItem(index: 6, title: 'العملاء وحسابات الذمم', icon: Icons.people_alt_outlined),
        NavItem(index: 7, title: 'المدفوعات وسندات القبض', icon: Icons.receipt_long_outlined),
        if (isAdmin)
          NavItem(index: 9, title: 'تقارير الربحية والتحليل', icon: Icons.analytics_outlined),
      ]),
      NavSection(title: 'البيانات المرجعية والنظام', items: [
        NavItem(index: 8, title: 'الماكينات والقوالب والتشطيب', icon: Icons.settings_suggest_outlined),
        if (isAdmin)
          NavItem(index: 10, title: 'إعدادات النظام', icon: Icons.settings_outlined),
        if (isAdmin)
          NavItem(index: 12, title: 'إدارة المستخدمين', icon: Icons.manage_accounts_outlined),
      ]),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          toolbarHeight: 60,
          elevation: 0,
          backgroundColor: Colors.white,
          leading: isDesktop
              ? IconButton(
                  icon: Icon(
                    _isSidebarCollapsed ? Icons.menu : Icons.menu_open,
                    color: AppTheme.darkSlate,
                    size: 22,
                  ),
                  tooltip: _isSidebarCollapsed ? 'توسيع القائمة' : 'تصغير القائمة',
                  onPressed: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
                )
              : IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.menu_rounded, color: AppTheme.darkSlate, size: 20),
                  ),
                  tooltip: 'القائمة الرئيسية',
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: AppTheme.borderColor),
          ),
          title: isDesktop
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: InkWell(
                        onTap: () => setState(() => _selectedIndex = 0),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.print_rounded, color: AppTheme.primaryGreen, size: 18),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  erp.settings.companyName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_left, color: AppTheme.textMuted, size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(currentItem.icon, size: 15, color: AppTheme.primaryGreen),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                currentItem.title,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.darkSlate,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(currentItem.icon, size: 18, color: AppTheme.primaryGreen),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        currentItem.title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkSlate,
                        ),
                      ),
                    ),
                  ],
                ),
          actions: [
            if (isDesktop) ...[
              // التاريخ اليومي
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 13, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      todayStr,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textDark, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
            ],

            // تنبيهات إعادة الطلب
            if (erp.lowStockPapers.isNotEmpty || erp.lowStockInks.isNotEmpty)
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: Badge(
                  label: Text('${erp.lowStockPapers.length + erp.lowStockInks.length}'),
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.notifications_active_outlined, color: Colors.red, size: 20),
                ),
                tooltip: 'تنبيهات نقص المخزون',
                onPressed: () => setState(() => _selectedIndex = 4),
              ),

            if (isDesktop) ...[
              const SizedBox(width: 4),
              // حالة الاتصال بالشبكة
              Tooltip(
                message: 'شبكة LAN متصلة',
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: const Icon(Icons.wifi, color: Color(0xFF16A34A), size: 16),
                ),
              ),
            ],

            const SizedBox(width: 6),

            // مستخدم النظام الحالي
            GestureDetector(
              onTap: () async {
                await auth.logout();
                if (!mounted) return;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginView()),
                );
              },
              child: Tooltip(
                message: '${currentUser?.displayName ?? 'مجهول'} - ${currentUser?.role.label ?? ''} (اضغط للخروج)',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isDesktop) Text(
                      currentUser?.displayName ?? '',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textDark, fontWeight: FontWeight.w600),
                    ),
                    if (isDesktop) const SizedBox(width: 6),
                    if (currentUser != null)
                      UserAvatar.fromUser(currentUser, size: 30, showBadge: false),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
        drawer: isDesktop ? null : _buildMobileDrawer(erp, auth, navSections),
        bottomNavigationBar: isDesktop ? null : _buildMobileBottomNav(auth),
        body: Row(
          children: [
            if (isDesktop)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _isSidebarCollapsed ? 70 : 260,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(left: BorderSide(color: AppTheme.borderColor)),
                ),
                child: _buildSidebarContent(erp, auth, _isSidebarCollapsed, navSections),
              ),
            Expanded(
              child: Container(
                color: AppTheme.scaffoldBg,
                child: _buildCurrentView(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarContent(ErpProvider erp, AuthProvider auth, bool isCollapsed, List<NavSection> navSections) {
    final currentUser = auth.currentUser;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Column(
      children: [
        if (!isCollapsed)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.print_rounded, color: AppTheme.primaryGreen, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              erp.settings.companyName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                            ),
                            const Text(
                              'ERP المطبعة المتكامل',
                              style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isDesktop)
                  IconButton(
                    icon: const Icon(Icons.menu_open, size: 18, color: AppTheme.textMuted),
                    onPressed: () => setState(() => _isSidebarCollapsed = true),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: AppTheme.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: IconButton(
              icon: const Icon(Icons.menu, size: 20, color: AppTheme.textMuted),
              onPressed: () => setState(() => _isSidebarCollapsed = false),
            ),
          ),
        if (!isDesktop) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 12, color: AppTheme.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          AppTheme.formatDate(DateTime.now()),
                          style: const TextStyle(fontSize: 11, color: AppTheme.textDark, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi, color: Color(0xFF16A34A), size: 13),
                      const SizedBox(width: 4),
                      Text(
                        'LAN متصل',
                        style: TextStyle(fontSize: 11, color: Colors.green.shade800, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: navSections.map((section) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isCollapsed)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                      child: Text(
                        section.title,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                      ),
                    ),
                  ...section.items.map((item) {
                    final isSelected = _selectedIndex == item.index;
                    return InkWell(
                      onTap: () {
                        setState(() => _selectedIndex = item.index);
                        if (!isDesktop && (_scaffoldKey.currentState?.isDrawerOpen ?? false)) {
                          _scaffoldKey.currentState?.closeDrawer();
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryGreen.withOpacity(0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected ? Border.all(color: AppTheme.primaryLight.withOpacity(0.3)) : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              size: 20,
                              color: isSelected ? AppTheme.primaryGreen : AppTheme.textMuted,
                            ),
                            if (!isCollapsed) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? AppTheme.primaryGreen : AppTheme.textDark,
                                  ),
                                ),
                              ),
                              if (item.index == 4 && erp.lowStockPapers.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                                  child: Text(
                                    '${erp.lowStockPapers.length}',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            }).toList(),
          ),
        ),
        const Divider(height: 1),
        if (!isCollapsed)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                if (currentUser != null)
                  UserAvatar.fromUser(currentUser, size: 34, showBadge: false),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(currentUser?.displayName ?? 'مجهول',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Text(currentUser?.role.label ?? '',
                          style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, size: 16, color: AppTheme.textMuted),
                  tooltip: 'تسجيل الخروج',
                  onPressed: () async {
                    await auth.logout();
                    if (!mounted) return;
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginView()),
                    );
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// القائمة الجانبية المخصصة للهاتف بتصميم راقٍ وعصري
  Widget _buildMobileDrawer(ErpProvider erp, AuthProvider auth, List<NavSection> navSections) {
    final screenWidth = MediaQuery.of(context).size.width;
    // عرض القائمة الجانبية 70% فقط من الشاشة (بحد أقصى 275dp) ليبقى ثلث الشاشة ظاهراً بوضوح في الخلفية
    final drawerWidth = min(screenWidth * 0.70, 275.0);

    return Drawer(
      width: drawerWidth,
      elevation: 16,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
      ),
      backgroundColor: Colors.white,
      child: Column(
        children: [
          _buildDrawerHeader(erp),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: navSections.map((section) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                      child: Text(
                        section.title,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMuted,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    ...section.items.map((item) {
                      final isSelected = _selectedIndex == item.index;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1.5),
                        child: Material(
                          color: isSelected ? const Color(0xFFF0FDF4) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: () {
                              setState(() => _selectedIndex = item.index);
                              _scaffoldKey.currentState?.closeDrawer();
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7.5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: isSelected ? Border.all(color: const Color(0xFFBBF7D0)) : null,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppTheme.primaryGreen : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      item.icon,
                                      size: 16,
                                      color: isSelected ? Colors.white : AppTheme.textMuted,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isSelected ? AppTheme.primaryGreen : AppTheme.darkSlate,
                                      ),
                                    ),
                                  ),
                                  if (item.index == 4 && erp.lowStockPapers.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade600,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${erp.lowStockPapers.length}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  else if (isSelected)
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: const BoxDecoration(
                                        color: AppTheme.primaryGreen,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }).toList(),
            ),
          ),
          _buildDrawerFooter(erp, auth),
        ],
      ),
    );
  }

  /// ترويسة أنيقة وعصرية مدمجة لقائمة الجوال
  Widget _buildDrawerHeader(ErpProvider erp) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, MediaQuery.of(context).padding.top + 8, 12, 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.4)),
                ),
                child: const Icon(Icons.print_rounded, color: Color(0xFF4ADE80), size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      erp.settings.companyName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'ERP المطبعة المتكامل',
                      style: TextStyle(fontSize: 9.5, color: Colors.white60),
                    ),
                  ],
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 14, color: Colors.white70),
                ),
                onPressed: () => _scaffoldKey.currentState?.closeDrawer(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 9.5, color: Colors.white70),
                    const SizedBox(width: 3.5),
                    Text(
                      AppTheme.formatDate(DateTime.now()),
                      style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: const Color(0xFF4ADE80).withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi, color: Color(0xFF4ADE80), size: 10),
                    SizedBox(width: 3),
                    Text(
                      'متصل محلياً',
                      style: TextStyle(fontSize: 9, color: Color(0xFF4ADE80), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// تذييل لقائمة الجوال يتضمن بيانات المستخدم واختصار الإعدادات
  Widget _buildDrawerFooter(ErpProvider erp, AuthProvider auth) {
    final currentUser = auth.currentUser;
    final isAdmin = auth.isAdmin;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                if (currentUser != null)
                  UserAvatar.fromUser(currentUser, size: 36, showBadge: false),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUser?.displayName ?? 'المستخدم',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                      ),
                      Text(
                        currentUser?.role.label ?? 'مستخدم ERP',
                        style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                if (isAdmin)
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, size: 20, color: AppTheme.textMuted),
                    tooltip: 'إعدادات النظام',
                    onPressed: () {
                      setState(() => _selectedIndex = 10);
                      _scaffoldKey.currentState?.closeDrawer();
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.logout, size: 20, color: Colors.redAccent),
                  tooltip: 'تسجيل الخروج',
                  onPressed: () async {
                    await auth.logout();
                    if (!mounted) return;
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginView()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// شريط التنقل السفلي السريع للجوال (Bottom Navigation Bar)
  Widget _buildMobileBottomNav(AuthProvider auth) {
    final currentIdx = (_selectedIndex >= 0 && _selectedIndex <= 3) ? _selectedIndex : 4;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderColor, width: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: NavigationBar(
          height: 62,
          elevation: 0,
          backgroundColor: Colors.white,
          indicatorColor: AppTheme.primaryGreen.withOpacity(0.12),
          selectedIndex: currentIdx,
          onDestinationSelected: (idx) {
            if (idx == 4) {
              _scaffoldKey.currentState?.openDrawer();
            } else {
              setState(() => _selectedIndex = idx);
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined, size: 22),
              selectedIcon: Icon(Icons.dashboard, color: AppTheme.primaryGreen, size: 22),
              label: 'المؤشرات',
            ),
            NavigationDestination(
              icon: Icon(Icons.calculate_outlined, size: 22),
              selectedIcon: Icon(Icons.calculate, color: AppTheme.primaryGreen, size: 22),
              label: 'التسعير',
            ),
            NavigationDestination(
              icon: Icon(Icons.request_quote_outlined, size: 22),
              selectedIcon: Icon(Icons.request_quote, color: AppTheme.primaryGreen, size: 22),
              label: 'العروض',
            ),
            NavigationDestination(
              icon: Icon(Icons.precision_manufacturing_outlined, size: 22),
              selectedIcon: Icon(Icons.precision_manufacturing, color: AppTheme.primaryGreen, size: 22),
              label: 'الإنتاج',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_rounded, size: 22),
              selectedIcon: Icon(Icons.menu_open_rounded, color: AppTheme.primaryGreen, size: 22),
              label: 'المزيد',
            ),
          ],
        ),
      ),
    );
  }
}

class NavSection {
  final String title;
  final List<NavItem> items;

  NavSection({required this.title, required this.items});
}

class NavItem {
  final int index;
  final String title;
  final IconData icon;

  NavItem({required this.index, required this.title, required this.icon});
}
