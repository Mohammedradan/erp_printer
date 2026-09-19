import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../providers/erp_provider.dart';
import '../theme/app_theme.dart';

class PriceManagementView extends StatefulWidget {
  final Function(int)? onNavigate;
  final int initialTab;

  const PriceManagementView({
    super.key,
    this.onNavigate,
    this.initialTab = 0,
  });

  @override
  State<PriceManagementView> createState() => _PriceManagementViewState();
}

class _PriceManagementViewState extends State<PriceManagementView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // فلاتر الورق
  String _selectedPaperCategory = 'الكل';
  final TextEditingController _paperSearchCtrl = TextEditingController();

  // تحكم الثوابت
  late TextEditingController _platePriceCtrl;
  late TextEditingController _marginCtrl;
  late TextEditingController _taxCtrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 3),
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    final s = context.read<ErpProvider>().settings;
    _platePriceCtrl = TextEditingController(text: s.defaultPlatePrice.toStringAsFixed(0));
    _marginCtrl = TextEditingController(text: s.defaultProfitMarginPct.toStringAsFixed(0));
    _taxCtrl = TextEditingController(text: s.taxPct.toStringAsFixed(0));
  }

  @override
  void didUpdateWidget(covariant PriceManagementView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _tabController.animateTo(widget.initialTab.clamp(0, 3));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _paperSearchCtrl.dispose();
    _platePriceCtrl.dispose();
    _marginCtrl.dispose();
    _taxCtrl.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isSuccess ? Icons.check_circle_outline : Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess ? AppTheme.primaryGreen : AppTheme.darkSlate,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final erp = context.watch<ErpProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. ترويسة تنفيذية فخمة (Executive Hero Header)
          _buildHeroHeader(erp),
          const SizedBox(height: 18),

          // 2. كروت المؤشرات الحيوية للتكاليف والأسعار (4 KPI Cards)
          _buildMetricsGrid(erp),
          const SizedBox(height: 18),

          // 3. شريط التبويبات المتطور بأعداد الأقسام
          _buildTabBar(erp),
          const SizedBox(height: 16),

          // 4. محتوى التبويب النشط
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              switch (_tabController.index) {
                case 0:
                  return _buildPaperPricesTab(erp);
                case 1:
                  return _buildMachinesRatesTab(erp);
                case 2:
                  return _buildFinishingsTab(erp);
                case 3:
                  return _buildConstantsTab(erp);
                default:
                  return const SizedBox.shrink();
              }
            },
          ),
        ],
      ),
    );
  }

  // --- ترويسة تنفيذية فخمة (Executive Hero Header) ---
  Widget _buildHeroHeader(ErpProvider erp) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF064E3B), // Dark emerald
            Color(0xFF047857), // Medium emerald
            Color(0xFF0F766E), // Teal accent
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F5132).withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: -25,
            bottom: -35,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(isMobile ? 10 : 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                          ),
                          child: Icon(Icons.price_change_rounded, color: Colors.white, size: isMobile ? 22 : 26),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'محرك التسعير والتكاليف الصناعية • ERP المطبعة',
                                  style: TextStyle(
                                    color: Color(0xFFD1FAE5),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'إدارة الأسعار وتكاليف التشغيل',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isMobile ? 18 : 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (!isMobile) ...[
                                const SizedBox(height: 3),
                                Text(
                                  'تعديل أسعار الورق والخامات، الماكينات وسرعاتها، نسب الهالك، والتشطيبات بمزامنة حية فورية',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 12.5,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white12, height: 1),
                    const SizedBox(height: 10),

                    // إحصاءات فورية وشارة المزامنة وزر المحرك
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _buildHeroPill(
                              icon: Icons.sync_rounded,
                              label: 'مزامنة حية',
                              color: const Color(0xFFD1FAE5),
                              bgColor: Colors.black.withValues(alpha: 0.25),
                            ),
                            _buildHeroPill(
                              icon: Icons.description_rounded,
                              label: '${erp.papers.length} صنف ورق',
                              color: const Color(0xFFBAE6FD),
                              bgColor: Colors.black.withValues(alpha: 0.22),
                            ),
                            if (!isMobile) ...[
                              _buildHeroPill(
                                icon: Icons.precision_manufacturing_rounded,
                                label: '${erp.machines.length} ماكينات',
                                color: const Color(0xFFFDE68A),
                                bgColor: Colors.black.withValues(alpha: 0.22),
                              ),
                              _buildHeroPill(
                                icon: Icons.content_cut_rounded,
                                label: '${erp.finishings.length} تشطيبات',
                                color: const Color(0xFFDDD6FE),
                                bgColor: Colors.black.withValues(alpha: 0.22),
                              ),
                            ],
                          ],
                        ),
                        if (widget.onNavigate != null)
                          ElevatedButton.icon(
                            onPressed: () => widget.onNavigate!(1), // محرك التسعير الحي
                            icon: const Icon(Icons.calculate_rounded, size: 16),
                            label: Text(
                              isMobile ? 'محرك التسعير' : 'تجربة الأسعار في محرك التسعير',
                              style: TextStyle(fontSize: isMobile ? 12 : 13),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 8 : 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroPill({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // --- كروت المؤشرات الحيوية للتكاليف والأسعار (4 KPI Cards) ---
  Widget _buildMetricsGrid(ErpProvider erp) {
    final avgPaperPrice = erp.papers.isNotEmpty
        ? (erp.papers.fold<double>(0, (sum, p) => sum + p.sheetPrice) / erp.papers.length)
        : 0.0;
    final avgHourlyCost = erp.machines.isNotEmpty
        ? (erp.machines.fold<double>(0, (sum, m) => sum + m.hourlyCost) / erp.machines.length)
        : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;
        final crossAxisCount = constraints.maxWidth > 1050 ? 4 : 2;
        final aspect = constraints.maxWidth > 1200
            ? 1.75
            : (constraints.maxWidth > 1050
                ? 1.55
                : (isMobile ? 1.38 : 1.7));

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: isMobile ? 10 : 14,
          mainAxisSpacing: isMobile ? 10 : 14,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: aspect,
          children: [
            _buildMetricCard(
              title: 'خامات وأصناف الورق',
              value: '${erp.papers.length} خامة',
              subtitle: 'متوسط: ${avgPaperPrice.toStringAsFixed(1)} ${erp.settings.currency}',
              icon: Icons.description_rounded,
              color: AppTheme.primaryGreen,
              bgColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
              onTap: () => _tabController.animateTo(0),
              isCompact: isMobile,
            ),
            _buildMetricCard(
              title: 'ماكينات ومعدلات التشغيل',
              value: '${erp.machines.length} ماكينات',
              subtitle: 'ساعة: ${avgHourlyCost.toStringAsFixed(0)} ${erp.settings.currency}',
              icon: Icons.precision_manufacturing_rounded,
              color: const Color(0xFF0284C7),
              bgColor: const Color(0xFFE0F2FE),
              onTap: () => _tabController.animateTo(1),
              isCompact: isMobile,
            ),
            _buildMetricCard(
              title: 'هامش الربح الافتراضي',
              value: '${erp.settings.defaultProfitMarginPct.toStringAsFixed(0)}%',
              subtitle: 'فوق التكلفة الصناعية',
              icon: Icons.trending_up_rounded,
              color: const Color(0xFF7C3AED),
              bgColor: const Color(0xFFEDE9FE),
              onTap: () => _tabController.animateTo(3),
              isCompact: isMobile,
            ),
            _buildMetricCard(
              title: 'سعر الزنك والضريبة',
              value: '${erp.settings.defaultPlatePrice.toStringAsFixed(0)} ${erp.settings.currency}',
              subtitle: 'زنك 50×35 | ضريبة: ${erp.settings.taxPct.toStringAsFixed(0)}%',
              icon: Icons.layers_rounded,
              color: const Color(0xFFD97706),
              bgColor: const Color(0xFFFEF3C7),
              onTap: () => _tabController.animateTo(3),
              isCompact: isMobile,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback? onTap,
    bool isCompact = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(isCompact ? 10 : 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.all(isCompact ? 6 : 8),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: isCompact ? 18 : 20),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: isCompact ? 10 : 12, color: AppTheme.textMuted.withValues(alpha: 0.6)),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isCompact ? 11 : 12,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: isCompact ? 16 : 19,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkSlate,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: isCompact ? 10 : 11,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  // --- شريط التبويبات المتطور بأعداد الأقسام ---
  Widget _buildTabBar(ErpProvider erp) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: AppTheme.primaryGreen,
        unselectedLabelColor: AppTheme.textMuted,
        indicatorColor: AppTheme.primaryGreen,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: [
          Tab(
            icon: const Icon(Icons.description_outlined, size: 18),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('أسعار الورق والخامات'),
                const SizedBox(width: 8),
                _buildTabBadge('${erp.papers.length}', AppTheme.primaryGreen),
              ],
            ),
          ),
          Tab(
            icon: const Icon(Icons.precision_manufacturing_outlined, size: 18),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('الماكينات والسرعات'),
                const SizedBox(width: 8),
                _buildTabBadge('${erp.machines.length}', const Color(0xFF0284C7)),
              ],
            ),
          ),
          Tab(
            icon: const Icon(Icons.content_cut_outlined, size: 18),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('التشطيبات والتجليد'),
                const SizedBox(width: 8),
                _buildTabBadge('${erp.finishings.length}', const Color(0xFF7C3AED)),
              ],
            ),
          ),
          const Tab(
            icon: Icon(Icons.tune_outlined, size: 18),
            text: 'سعر الزنك والربح والضريبة',
          ),
        ],
      ),
    );
  }

  Widget _buildTabBadge(String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        count,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // =========================================================================
  // تبويب 1: أسعار الورق والخامات (Responsive: Desktop Table vs Mobile Cards)
  // =========================================================================
  Widget _buildPaperPricesTab(ErpProvider erp) {
    final categories = ['الكل', ...erp.papers.map((p) => p.category).toSet()];
    final query = _paperSearchCtrl.text.trim().toLowerCase();

    final filtered = erp.papers.where((p) {
      if (_selectedPaperCategory != 'الكل' && p.category != _selectedPaperCategory) {
        return false;
      }
      if (query.isNotEmpty) {
        final matchesName = p.displayName.toLowerCase().contains(query);
        final matchesCat = p.category.toLowerCase().contains(query);
        final matchesType = p.paperType.toLowerCase().contains(query);
        return matchesName || matchesCat || matchesType;
      }
      return true;
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // شريط البحث المطور مع زر المسح
          TextField(
            controller: _paperSearchCtrl,
            decoration: InputDecoration(
              hintText: 'بحث في خامات وأصناف الورق...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.textMuted),
              suffixIcon: _paperSearchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _paperSearchCtrl.clear();
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.borderColor),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          // شرائح الفئات القابلة للتمرير الأفقي السلس لمنع التكسر على الجوال
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isSelected = _selectedPaperCategory == cat;
                final count = cat == 'الكل'
                    ? erp.papers.length
                    : erp.papers.where((p) => p.category == cat).length;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => _selectedPaperCategory = cat),
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryGreen : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryGreen : AppTheme.borderColor,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              cat,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? Colors.white : AppTheme.darkSlate,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : Colors.black.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : AppTheme.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // محتوى الأصناف المتجاوب
          if (filtered.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Column(
                children: const [
                  Icon(Icons.search_off_rounded, size: 36, color: AppTheme.textMuted),
                  SizedBox(height: 8),
                  Text('لا توجد أصناف ورق مطابقة لمعايير البحث', style: TextStyle(color: AppTheme.textMuted, fontSize: 13.5)),
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 750) {
                  return _buildMobilePaperCards(filtered, erp);
                } else {
                  return _buildDesktopPaperTable(filtered, erp);
                }
              },
            ),
        ],
      ),
    );
  }

  // بطاقات مخصصة للهواتف تمنع انقطاع الأعمدة
  Widget _buildMobilePaperCards(List<PaperItem> papers, ErpProvider erp) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: papers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final p = papers[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        p.category,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryGreen),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Text(
                      '${p.sheetPrice.toStringAsFixed(1)} ${erp.settings.currency} / فرخ',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF047857)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${p.paperType} (${p.gsm} جم)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppTheme.darkSlate),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.aspect_ratio_rounded, size: 15, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text('مقاس الفرخ: ${p.sheetSize} سم', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.grid_view_rounded, size: 15, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text('${p.sheetsPerUnit} ملازم/فرخ', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppTheme.borderColor),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => _editPaperPriceDialog(p, erp),
                  icon: const Icon(Icons.edit_outlined, size: 15, color: AppTheme.primaryGreen),
                  label: const Text('تعديل السعر والمقاس', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.borderColor),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // جدول لسطح المكتب والشاشات الكبيرة
  Widget _buildDesktopPaperTable(List<PaperItem> filtered, ErpProvider erp) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
        columnSpacing: 24,
        columns: const [
          DataColumn(label: Text('الفئة', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('النوع / الجرام', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('مقاس الفرخ', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('ملازم / فرخ', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('سعر الفرخ الحالي', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: filtered.map((paper) {
          return DataRow(
            cells: [
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(paper.category, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                ),
              ),
              DataCell(Text('${paper.paperType} (${paper.gsm} جم)', style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Text('${paper.sheetSize} سم')),
              DataCell(Text('${paper.sheetsPerUnit} ملازم')),
              DataCell(
                Text(
                  '${paper.sheetPrice.toStringAsFixed(1)} ${erp.settings.currency}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                ),
              ),
              DataCell(
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 15, color: AppTheme.primaryGreen),
                  label: const Text('تعديل', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.borderColor),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                  onPressed: () => _editPaperPriceDialog(paper, erp),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _editPaperPriceDialog(PaperItem paper, ErpProvider erp) {
    final priceCtrl = TextEditingController(text: paper.sheetPrice.toStringAsFixed(1));
    final sizeCtrl = TextEditingController(text: paper.sheetSize);
    final sigsCtrl = TextEditingController(text: '${paper.sheetsPerUnit}');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('تعديل سعر ومقاس الفرخ: ${paper.displayName}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الفئة: ${paper.category} | النوع: ${paper.paperType} (${paper.gsm} جم)', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                const SizedBox(height: 14),
                TextFormField(
                  controller: priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'سعر الفرخ الواحد (${erp.settings.currency})',
                    prefixIcon: const Icon(Icons.payments_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: sizeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'مقاس الفرخ القياسي (سم)',
                    prefixIcon: Icon(Icons.aspect_ratio_outlined),
                    hintText: '100x70',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: sigsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'عدد ملازم 50x35 لكل فرخ',
                    prefixIcon: Icon(Icons.grid_view_outlined),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newPrice = double.tryParse(priceCtrl.text.trim()) ?? paper.sheetPrice;
                final newSize = sizeCtrl.text.trim().isNotEmpty ? sizeCtrl.text.trim() : paper.sheetSize;
                final newSigs = int.tryParse(sigsCtrl.text.trim()) ?? paper.sheetsPerUnit;

                paper.sheetPrice = newPrice;
                paper.sheetSize = newSize;
                paper.sheetsPerUnit = newSigs;

                await erp.updatePaper(paper);
                if (ctx.mounted) Navigator.pop(ctx);
                _showSnackBar('تم تحديث سعر ومقاس فرخ ${paper.displayName} بنجاح');
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
              child: const Text('حفظ التعديلات'),
            ),
          ],
        );
      },
    );
  }

  // =========================================================================
  // تبويب 2: الماكينات (تكلفة الساعة، السرعة، نسبة الهالك)
  // =========================================================================
  Widget _buildMachinesRatesTab(ErpProvider erp) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.precision_manufacturing_rounded, size: 20, color: AppTheme.primaryGreen),
              SizedBox(width: 8),
              Text(
                'ماكينات الطباعة ومعدلات التشغيل',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'حدد تكلفة الساعة وسرعة السحب ونسبة الهالك المعتمدة لكل ماكينة للحساب الدقيق في المحرك.',
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: erp.machines.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final machine = erp.machines[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFFF8FAFC),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 720;
                    if (isWide) {
                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.precision_manufacturing, color: AppTheme.primaryGreen, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(machine.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text('النوع: ${machine.kind} | الحالة: ${machine.status}', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: _buildRatePill('تكلفة التشغيل/ساعة', '${machine.hourlyCost.toStringAsFixed(0)} ${erp.settings.currency}', Icons.timer_outlined),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: _buildRatePill('سرعة السحب', '${machine.speedPerHour} فرخ/ساعة', Icons.speed_outlined),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: _buildRatePill('نسبة الهالك', '${machine.wastePct.toStringAsFixed(1)}%', Icons.delete_sweep_outlined),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () => _editMachineRatesDialog(machine, erp),
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('تعديل'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.precision_manufacturing, color: AppTheme.primaryGreen, size: 20),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(machine.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                ],
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.edit, size: 14, color: AppTheme.primaryGreen),
                                label: const Text('تعديل', style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppTheme.borderColor),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                ),
                                onPressed: () => _editMachineRatesDialog(machine, erp),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildRatePill('تكلفة الساعة', '${machine.hourlyCost.toStringAsFixed(0)} ${erp.settings.currency}', Icons.timer_outlined),
                              _buildRatePill('السرعة', '${machine.speedPerHour} فرخ/ساعة', Icons.speed_outlined),
                              _buildRatePill('الهالك', '${machine.wastePct}%', Icons.delete_sweep_outlined),
                            ],
                          ),
                        ],
                      );
                    }
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRatePill(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryGreen),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted)),
              Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.darkSlate)),
            ],
          ),
        ],
      ),
    );
  }

  void _editMachineRatesDialog(MachineItem machine, ErpProvider erp) {
    final costCtrl = TextEditingController(text: machine.hourlyCost.toStringAsFixed(0));
    final speedCtrl = TextEditingController(text: machine.speedPerHour.toString());
    final wasteCtrl = TextEditingController(text: machine.wastePct.toStringAsFixed(1));

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('تعديل معايير: ${machine.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: costCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'تكلفة التشغيل بالساعة (${erp.settings.currency})',
                    prefixIcon: const Icon(Icons.timer_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: speedCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'السرعة (فرخ/ساعة)',
                    prefixIcon: Icon(Icons.speed),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: wasteCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'نسبة الهالك (%)',
                    prefixIcon: Icon(Icons.delete_sweep),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                final hourly = double.tryParse(costCtrl.text.trim()) ?? machine.hourlyCost;
                final speed = int.tryParse(speedCtrl.text.trim()) ?? machine.speedPerHour;
                final waste = double.tryParse(wasteCtrl.text.trim()) ?? machine.wastePct;

                await erp.updateMachineRates(
                  machineId: machine.id,
                  hourlyCost: hourly,
                  speedPerHour: speed,
                  wastePct: waste,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                _showSnackBar('تم حفظ معايير ${machine.name} بنجاح');
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
              child: const Text('حفظ التعديلات'),
            ),
          ],
        );
      },
    );
  }

  // =========================================================================
  // تبويب 3: أسعار التشطيبات والتجليد (Responsive Desktop vs Mobile)
  // =========================================================================
  Widget _buildFinishingsTab(ErpProvider erp) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.content_cut_rounded, size: 20, color: AppTheme.primaryGreen),
              SizedBox(width: 8),
              Text(
                'خدمات التشطيب والتجليد وسعر كل خدمة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'حدد سعر كل عملية ونوع وحدة القياس (للعملية / للألف / للقطعة).',
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 650) {
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: erp.finishings.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final f = erp.finishings[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(f.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.darkSlate)),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('الوحدة: ${f.unit}', style: const TextStyle(color: Colors.blue, fontSize: 11)),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '${f.price.toStringAsFixed(1)} ${erp.settings.currency}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF047857)),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryGreen),
                                tooltip: 'تعديل السعر',
                                onPressed: () => _editFinishingDialog(f, erp),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                  columnSpacing: 28,
                  columns: const [
                    DataColumn(label: Text('الخدمة', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('وحدة القياس', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('السعر الحالي', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('تعديل السعر والوحدة', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: erp.finishings.map((f) {
                    return DataRow(
                      cells: [
                        DataCell(Text(f.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(f.unit, style: const TextStyle(color: Colors.blue, fontSize: 12)),
                          ),
                        ),
                        DataCell(Text('${f.price.toStringAsFixed(1)} ${erp.settings.currency}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF047857)))),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryGreen),
                            tooltip: 'تعديل السعر',
                            onPressed: () => _editFinishingDialog(f, erp),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _editFinishingDialog(FinishingItem f, ErpProvider erp) {
    final priceCtrl = TextEditingController(text: f.price.toStringAsFixed(1));
    String selectedUnit = f.unit;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              title: Text('تعديل سعر: ${f.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'السعر (${erp.settings.currency})',
                      prefixIcon: const Icon(Icons.monetization_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedUnit,
                    decoration: const InputDecoration(labelText: 'وحدة التسعير'),
                    items: const [
                      DropdownMenuItem(value: 'للعملية', child: Text('للعملية (مقطوع)')),
                      DropdownMenuItem(value: 'للألف', child: Text('للألف (نسخة/فرخ)')),
                      DropdownMenuItem(value: 'للقطعة', child: Text('للقطعة (لكل كتاب/دفتر)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDlgState(() => selectedUnit = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                ElevatedButton(
                  onPressed: () async {
                    final newPrice = double.tryParse(priceCtrl.text.trim()) ?? f.price;
                    await erp.updateFinishingPrice(f.id, newPrice, selectedUnit);
                    if (ctx.mounted) Navigator.pop(ctx);
                    _showSnackBar('تم تحديث خدمة ${f.name} بنجاح');
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                  child: const Text('حفظ السعر'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // تبويب 4: سعر الزنك وهامش الربح والضريبة
  // =========================================================================
  Widget _buildConstantsTab(ErpProvider erp) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.tune_rounded, size: 20, color: AppTheme.primaryGreen),
              SizedBox(width: 8),
              Text(
                'ثوابت التسعير والضرائب وهامش الربح',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'هذه القيم هي المعايير الافتراضية المطبقة في كل عملية تسعير جديدة.',
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: isWide ? (constraints.maxWidth - 20) / 2 : double.infinity,
                    child: TextFormField(
                      controller: _platePriceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'سعر البليت / الزنك الافتراضي (${erp.settings.currency})',
                        helperText: 'سعر الزنك الأوفست 50×35 لكل لون/وجه',
                        prefixIcon: const Icon(Icons.layers_outlined),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: isWide ? (constraints.maxWidth - 20) / 2 : double.infinity,
                    child: TextFormField(
                      controller: _marginCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'هامش الربح الافتراضي (%)',
                        helperText: 'النسبة المضافة فوق التكلفة الصناعية',
                        prefixIcon: Icon(Icons.trending_up),
                        filled: true,
                        fillColor: Color(0xFFF8FAFC),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: isWide ? (constraints.maxWidth - 20) / 2 : double.infinity,
                    child: TextFormField(
                      controller: _taxCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'نسبة الضريبة المضافة (%)',
                        helperText: '0 تعني بدون ضريبة، أو النسبة المقررة',
                        prefixIcon: Icon(Icons.receipt_long),
                        filled: true,
                        fillColor: Color(0xFFF8FAFC),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final pPrice = double.tryParse(_platePriceCtrl.text.trim()) ?? erp.settings.defaultPlatePrice;
              final pMargin = double.tryParse(_marginCtrl.text.trim()) ?? erp.settings.defaultProfitMarginPct;
              final pTax = double.tryParse(_taxCtrl.text.trim()) ?? erp.settings.taxPct;

              await erp.updatePricingConstants(
                platePrice: pPrice,
                profitMarginPct: pMargin,
                taxPct: pTax,
              );
              _showSnackBar('تم حفظ ثوابت التسعير والربح والضريبة بنجاح');
            },
            icon: const Icon(Icons.save_rounded),
            label: const Text('حفظ ثوابت التسعير والربح'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
