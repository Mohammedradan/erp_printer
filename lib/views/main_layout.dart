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
    final isAdmin = context.read<AuthProvider>().isAdmin;
    const adminOnlyTabs = {8, 9, 10, 11, 12};
    if (!isAdmin && adminOnlyTabs.contains(_selectedIndex)) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('هذه الصفحة متاحة للمدير فقط', textAlign: TextAlign.center),
        ),
      );
    }

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
      NavItem(index: 1, title: 'محرك التسعير', icon: Icons.calculate_outlined),
      NavItem(index: 2, title: 'عروض الأسعار', icon: Icons.request_quote_outlined),
      NavItem(index: 3, title: 'أوامر الإنتاج', icon: Icons.precision_manufacturing_outlined),
      NavItem(index: 4, title: 'مخزون الورق', icon: Icons.inventory_2_outlined),
      NavItem(index: 5, title: 'مخزون الأحبار', icon: Icons.colorize_outlined),
      NavItem(index: 6, title: 'العملاء والذمم', icon: Icons.people_alt_outlined),
      NavItem(index: 7, title: 'المدفوعات وسندات القبض', icon: Icons.receipt_long_outlined),
      NavItem(index: 8, title: 'الماكينات والتشطيب', icon: Icons.settings_suggest_outlined),
      NavItem(index: 9, title: 'تقارير الربحية', icon: Icons.analytics_outlined),
      NavItem(index: 10, title: 'إعدادات النظام', icon: Icons.settings_outlined),
      NavItem(index: 11, title: 'الأسعار والتكاليف', icon: Icons.price_change_outlined),
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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 900;
    final currentItem = _getCurrentNavItem();
    final companyName = erp.settings.companyName.trim();
    final today = AppTheme.formatDate(DateTime.now());
    final lowStockCount = erp.lowStockPapers.length + erp.lowStockInks.length;

    final navSections = <NavSection>[
      NavSection(title: 'التشغيل اليومي', items: [
        NavItem(index: 0, title: 'لوحة المؤشرات', icon: Icons.dashboard_outlined),
        NavItem(index: 1, title: 'محرك التسعير', icon: Icons.calculate_outlined),
        NavItem(index: 2, title: 'عروض الأسعار', icon: Icons.request_quote_outlined),
        NavItem(index: 3, title: 'أوامر الإنتاج', icon: Icons.precision_manufacturing_outlined),
        if (isAdmin)
          NavItem(index: 11, title: 'الأسعار والتكاليف', icon: Icons.price_change_outlined),
      ]),
      NavSection(title: 'المخزون والعملاء', items: [
        NavItem(index: 4, title: 'مخزون الورق', icon: Icons.inventory_2_outlined),
        NavItem(index: 5, title: 'مخزون الأحبار', icon: Icons.colorize_outlined),
        NavItem(index: 6, title: 'العملاء والذمم', icon: Icons.people_alt_outlined),
      ]),
      NavSection(title: 'المالية والإدارة', items: [
        NavItem(index: 7, title: 'المدفوعات وسندات القبض', icon: Icons.receipt_long_outlined),
        if (isAdmin)
          NavItem(index: 9, title: 'تقارير الربحية', icon: Icons.analytics_outlined),
        if (isAdmin)
          NavItem(index: 8, title: 'الماكينات والتشطيب', icon: Icons.settings_suggest_outlined),
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
          titleSpacing: 0,
          leading: isDesktop
              ? IconButton(
                  icon: Icon(_isSidebarCollapsed ? Icons.menu_rounded : Icons.menu_open_rounded),
                  tooltip: _isSidebarCollapsed ? 'توسيع القائمة' : 'تصغير القائمة',
                  onPressed: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
                )
              : IconButton(
                  icon: const Icon(Icons.menu_rounded),
                  tooltip: 'القائمة الرئيسية',
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
          title: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withValues(alpha: 0.34),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(currentItem.icon, size: 18, color: AppTheme.primaryLight),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      currentItem.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.darkSlate),
                    ),
                    if (isDesktop && screenWidth >= 1280)
                      Text(
                        companyName.isEmpty ? 'نظام إدارة المطبعة' : companyName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                      ),
                  ],
                ),
              ),
            ],
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, thickness: 1, color: AppTheme.borderColor),
          ),
          actions: [
            if (isDesktop && screenWidth >= 1200)
              Container(
                margin: const EdgeInsetsDirectional.only(end: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: AppTheme.scaffoldBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.textMuted),
                    const SizedBox(width: 6),
                    Text(today, style: const TextStyle(fontSize: 12, color: AppTheme.textDark, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            if (lowStockCount > 0)
              IconButton(
                tooltip: 'مواد وصلت إلى حد إعادة الطلب ($lowStockCount)',
                onPressed: () => setState(() => _selectedIndex = erp.lowStockPapers.isNotEmpty ? 4 : 5),
                icon: Badge(
                  label: Text('$lowStockCount', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                  backgroundColor: AppTheme.danger,
                  child: const Icon(Icons.notifications_none_rounded),
                ),
              ),
            PopupMenuButton<String>(
              tooltip: 'حساب المستخدم',
              onSelected: (value) {
                if (value == 'users' && isAdmin) {
                  setState(() => _selectedIndex = 12);
                } else if (value == 'logout') {
                  _showLogoutConfirmationDialog(auth);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(currentUser?.displayName ?? 'مستخدم النظام', style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.darkSlate)),
                      const SizedBox(height: 3),
                      Text(currentUser?.role.label ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                if (isAdmin)
                  const PopupMenuItem<String>(
                    value: 'users',
                    child: Row(children: [Icon(Icons.manage_accounts_outlined, size: 18, color: AppTheme.primaryLight), SizedBox(width: 9), Text('إدارة المستخدمين')]),
                  ),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(children: [Icon(Icons.logout_rounded, size: 18, color: AppTheme.danger), SizedBox(width: 9), Text('تسجيل الخروج')]),
                ),
              ],
              child: Padding(
                padding: EdgeInsetsDirectional.only(start: 4, end: isDesktop ? 14 : 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (currentUser != null)
                      UserAvatar.fromUser(currentUser, size: 32, showBadge: false)
                    else
                      const CircleAvatar(radius: 16, child: Icon(Icons.person_outline, size: 18)),
                    if (isDesktop && screenWidth >= 1160) ...[
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 130),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(currentUser?.displayName ?? 'المستخدم', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
                            Text(currentUser?.role.label ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, color: AppTheme.textMuted)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppTheme.textMuted),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        drawer: isDesktop ? null : _buildMobileDrawer(erp, auth, navSections),
        bottomNavigationBar: isDesktop ? null : _buildMobileBottomNav(auth),
        body: Row(
          children: [
            if (isDesktop)
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: _isSidebarCollapsed ? 72 : 250,
                decoration: const BoxDecoration(
                  color: AppTheme.sidebarBg,
                  border: Border(left: BorderSide(color: AppTheme.borderColor)),
                ),
                child: _buildSidebarContent(erp, auth, _isSidebarCollapsed, navSections),
              ),
            Expanded(
              child: Container(
                color: AppTheme.scaffoldBg,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final media = MediaQuery.of(context);
                    final contentWidth = min(constraints.maxWidth, 1760.0);
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1760),
                        child: MediaQuery(
                          data: media.copyWith(size: Size(contentWidth, media.size.height)),
                          child: _buildCurrentView(),
                        ),
                      ),
                    );
                  },
                ),
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
                          color: AppTheme.primaryLight.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.print_rounded, color: AppTheme.primaryLight, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              erp.settings.companyName.trim().isEmpty ? 'إدارة المطبعة' : erp.settings.companyName,
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
                    final itemLowStockCount = switch (item.index) {
                      4 => erp.lowStockPapers.length,
                      5 => erp.lowStockInks.length,
                      _ => 0,
                    };
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
                          color: isSelected ? AppTheme.selectedSurface : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected ? Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.32)) : null,
                        ),
                        child: Row(
                          children: [
                            Tooltip(
                              message: item.title,
                              child: Icon(
                                item.icon,
                                size: 20,
                                color: isSelected ? AppTheme.primaryLight : AppTheme.textMuted,
                              ),
                            ),
                            if (!isCollapsed) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? AppTheme.primaryLight : AppTheme.textDark,
                                  ),
                                ),
                              ),
                              if (itemLowStockCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: AppTheme.danger, borderRadius: BorderRadius.circular(10)),
                                  child: Text(
                                    '$itemLowStockCount',
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
                  onPressed: () => _showLogoutConfirmationDialog(auth),
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
    // يظل العرض مناسباً للهاتف مع مساحة كافية لعناوين الأقسام الطويلة.
    final drawerWidth = min(screenWidth * 0.78, 320.0);

    return Drawer(
      width: drawerWidth,
      elevation: 16,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
      ),
      backgroundColor: AppTheme.sidebarBg,
      child: Column(
        children: [
          _buildDrawerHeader(erp),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 4, bottom: 28),
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
                      final itemLowStockCount = switch (item.index) {
                        4 => erp.lowStockPapers.length,
                        5 => erp.lowStockInks.length,
                        _ => 0,
                      };
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1.5),
                        child: Material(
                          color: isSelected ? AppTheme.selectedSurface : Colors.transparent,
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
                                border: isSelected ? Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.28)) : null,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppTheme.primaryGreen : AppTheme.surfaceSecondary,
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
                                        color: isSelected ? AppTheme.primaryLight : AppTheme.darkSlate,
                                      ),
                                    ),
                                  ),
                                  if (itemLowStockCount > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: AppTheme.danger,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '$itemLowStockCount',
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
                                        color: AppTheme.primaryLight,
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
        color: AppTheme.sidebarBg,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.selectedSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: const Icon(Icons.print_rounded, color: AppTheme.primaryLight, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      erp.settings.companyName.trim().isEmpty ? 'إدارة المطبعة' : erp.settings.companyName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Text(
                      'ERP المطبعة المتكامل',
                      style: TextStyle(fontSize: 9.5, color: AppTheme.textSecondary),
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
                    color: AppTheme.surfaceSecondary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: const Icon(Icons.close, size: 14, color: AppTheme.textSecondary),
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
                  color: AppTheme.surfaceSecondary,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 9.5, color: AppTheme.primaryLight),
                    const SizedBox(width: 3.5),
                    Text(
                      AppTheme.formatDate(DateTime.now()),
                      style: const TextStyle(fontSize: 9, color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
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
        color: AppTheme.sidebarBg,
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
                  icon: const Icon(Icons.logout, size: 20, color: AppTheme.danger),
                  tooltip: 'تسجيل الخروج',
                  onPressed: () {
                    _scaffoldKey.currentState?.closeDrawer();
                    _showLogoutConfirmationDialog(auth);
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
        color: AppTheme.sidebarBg,
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
          backgroundColor: AppTheme.sidebarBg,
          indicatorColor: AppTheme.primaryLight.withValues(alpha: 0.55),
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
              selectedIcon: Icon(Icons.dashboard, color: AppTheme.primaryLight, size: 22),
              label: 'المؤشرات',
            ),
            NavigationDestination(
              icon: Icon(Icons.calculate_outlined, size: 22),
              selectedIcon: Icon(Icons.calculate, color: AppTheme.primaryLight, size: 22),
              label: 'التسعير',
            ),
            NavigationDestination(
              icon: Icon(Icons.request_quote_outlined, size: 22),
              selectedIcon: Icon(Icons.request_quote, color: AppTheme.primaryLight, size: 22),
              label: 'العروض',
            ),
            NavigationDestination(
              icon: Icon(Icons.precision_manufacturing_outlined, size: 22),
              selectedIcon: Icon(Icons.precision_manufacturing, color: AppTheme.primaryLight, size: 22),
              label: 'الإنتاج',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_rounded, size: 22),
              selectedIcon: Icon(Icons.menu_open_rounded, color: AppTheme.primaryLight, size: 22),
              label: 'المزيد',
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmationDialog(AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppTheme.danger, size: 22),
            SizedBox(width: 8),
            Text('تسجيل الخروج', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من رغبتك في تسجيل الخروج من النظام؟',
          style: TextStyle(fontSize: 13.5, color: AppTheme.darkSlate),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await auth.logout();
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginView()),
              );
            },
            child: const Text('تسجيل خروج', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
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
