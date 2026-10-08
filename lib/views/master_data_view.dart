import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../providers/erp_provider.dart';
import '../theme/app_theme.dart';

class MasterDataView extends StatefulWidget {
  const MasterDataView({super.key});

  @override
  State<MasterDataView> createState() => _MasterDataViewState();
}

class _MasterDataViewState extends State<MasterDataView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final erp = context.watch<ErpProvider>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            isMobile ? 12 : 20,
            isMobile ? 12 : 20,
            isMobile ? 12 : 20,
            isMobile ? 95 : 30,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. ترويسة تنفيذية فخمة (Executive Hero Header)
              _buildHeroHeader(erp, isMobile),
              SizedBox(height: isMobile ? 14 : 20),

              // 2. شريط التبويبات المتجاوب الفاخر
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
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
                  labelColor: AppTheme.primaryLight,
                  unselectedLabelColor: AppTheme.textMuted,
                  indicatorColor: AppTheme.primaryLight,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  tabs: [
                    Tab(
                      icon: const Icon(Icons.precision_manufacturing_rounded, size: 19),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('الماكينات'),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${erp.machines.length}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryLight),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Tab(
                      icon: const Icon(Icons.auto_stories_rounded, size: 19),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('قوالب المنتجات'),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppTheme.info.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${erp.products.length}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.info),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Tab(
                      icon: const Icon(Icons.content_cut_rounded, size: 19),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('خدمات التشطيب'),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppTheme.warning.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${erp.finishings.length}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.warning),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isMobile ? 12 : 16),

              // محتوى التبويب النشط
              if (_tabController.index == 0)
                _buildMachinesTab(erp, isMobile)
              else if (_tabController.index == 1)
                _buildProductsTab(erp, isMobile)
              else
                _buildFinishingsTab(erp, isMobile),
            ],
          ),
        );
      },
    );
  }

  // --- ترويسة تنفيذية فخمة ---
  Widget _buildHeroHeader(ErpProvider erp, bool isMobile) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -25,
            bottom: -35,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryLight.withValues(alpha: 0.035),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isMobile ? 14 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isMobile ? 8 : 10),
                      decoration: BoxDecoration(
                        color: AppTheme.selectedSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Icon(Icons.settings_suggest_rounded, color: AppTheme.primaryLight, size: isMobile ? 22 : 26),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: AppTheme.selectedSurface,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'المعايير المرجعية والتشغيلية • ERP المطبعة',
                              style: TextStyle(
                                color: AppTheme.primaryLight,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'الماكينات وقوالب المنتجات والتشطيب',
                            style: TextStyle(
                              fontSize: isMobile ? 17 : 21,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'معايير الطاقة الإنتاجية، الهالك، وأسعار الخدمات وتكلفة الساعة',
                            style: TextStyle(
                              fontSize: isMobile ? 11 : 12.5,
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildHeroBadge(
                        icon: Icons.precision_manufacturing_rounded,
                        label: '${erp.machines.length} ماكينات نشطة',
                      ),
                      const SizedBox(width: 8),
                      _buildHeroBadge(
                        icon: Icons.auto_stories_rounded,
                        label: '${erp.products.length} قوالب منتجات',
                      ),
                      const SizedBox(width: 8),
                      _buildHeroBadge(
                        icon: Icons.content_cut_rounded,
                        label: '${erp.finishings.length} خدمة تشطيب',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBadge({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryLight),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // تبويب 1: الماكينات
  // ==========================================
  Widget _buildMachinesTab(ErpProvider erp, bool isMobile) {
    if (isMobile) {
      return Column(
        children: erp.machines.map((m) => _buildMachineMobileCard(m)).toList(),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppTheme.surfaceSecondary),
            columns: const [
              DataColumn(label: Text('اسم الماكينة', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('النوع', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('الهالك %', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('تكلفة التشغيل/ساعة', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('السرعة (فرخ/ساعة)', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('تعديل', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: erp.machines.map((m) {
              return DataRow(cells: [
                DataCell(Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(m.kind)),
                DataCell(Text('${m.wastePct}%')),
                DataCell(Text(AppTheme.formatCurrency(m.hourlyCost, context.read<ErpProvider>().settings.currency))),
                DataCell(Text('${m.speedPerHour}')),
                DataCell(AppTheme.statusBadge(m.status)),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, size: 18, color: AppTheme.info),
                    onPressed: () => _showEditMachineDialog(m),
                  ),
                ),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMachineMobileCard(MachineItem m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.precision_manufacturing_rounded, color: AppTheme.primaryLight, size: 21),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    m.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                AppTheme.statusBadge(m.status),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppTheme.surfaceSecondary),
            const SizedBox(height: 12),

            // شبكة كبسولات مواصفات الماكينة التنفيذية
            Row(
              children: [
                Expanded(
                  child: _buildSpecPill(
                    icon: Icons.category_outlined,
                    label: 'نوع الماكينة',
                    value: m.kind,
                    bgColor: AppTheme.surfaceSecondary,
                    textColor: AppTheme.darkSlate,
                    iconColor: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSpecPill(
                    icon: Icons.warning_amber_rounded,
                    label: 'نسبة الهالك',
                    value: '%${m.wastePct}',
                    bgColor: AppTheme.warningSurface,
                    textColor: AppTheme.warning,
                    iconColor: AppTheme.accentGold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildSpecPill(
                    icon: Icons.monetization_on_outlined,
                    label: 'تكلفة الساعة',
                    value: AppTheme.formatCurrency(m.hourlyCost, context.read<ErpProvider>().settings.currency),
                    bgColor: AppTheme.successSurface,
                    textColor: AppTheme.success,
                    iconColor: AppTheme.primaryLight,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSpecPill(
                    icon: Icons.speed_rounded,
                    label: 'السرعة الإنتاجية',
                    value: '${m.speedPerHour} فرخ/س',
                    bgColor: AppTheme.infoSurface,
                    textColor: AppTheme.info,
                    iconColor: AppTheme.info,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showEditMachineDialog(m),
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: const Text('تعديل معايير الماكينة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successSurface,
                  foregroundColor: AppTheme.primaryLight,
                  elevation: 0,
                  side: BorderSide(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // تبويب 2: قوالب المنتجات
  // ==========================================
  Widget _buildProductsTab(ErpProvider erp, bool isMobile) {
    if (isMobile) {
      return Column(
        children: erp.products.map((p) => _buildProductMobileCard(p)).toList(),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppTheme.surfaceSecondary),
            columns: const [
              DataColumn(label: Text('اسم المنتج', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('الفئة', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('صفحات/فرخ 50x35', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('نوع التجليد', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('الماكينة الافتراضية', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('الخامة الافتراضية', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('تعديل', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: erp.products.map((p) {
              return DataRow(cells: [
                DataCell(Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(p.category)),
                DataCell(Text('${p.pagesPerSheet}')),
                DataCell(Text(p.binding)),
                DataCell(Text(p.defaultMachine)),
                DataCell(Text('${p.defaultPaperCategory} ${p.defaultPaperType}')),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, size: 18, color: AppTheme.info),
                    onPressed: () => _showEditProductDialog(p),
                  ),
                ),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildProductMobileCard(ProductTemplate p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppTheme.info.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_stories_rounded, color: AppTheme.info, size: 21),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    p.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.infoSurface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Text(
                    p.category,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.info),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppTheme.surfaceSecondary),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildSpecPill(
                    icon: Icons.layers_outlined,
                    label: 'صفحات الفرخ (50x35)',
                    value: '${p.pagesPerSheet} صفحة',
                    bgColor: AppTheme.infoSurface,
                    textColor: AppTheme.info,
                    iconColor: AppTheme.info,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSpecPill(
                    icon: Icons.menu_book_outlined,
                    label: 'نوع التجليد',
                    value: p.binding.isEmpty ? 'بدون تجليد' : p.binding,
                    bgColor: AppTheme.surfaceSecondary,
                    textColor: AppTheme.darkSlate,
                    iconColor: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildSpecPill(
                    icon: Icons.precision_manufacturing_outlined,
                    label: 'الماكينة الافتراضية',
                    value: p.defaultMachine,
                    bgColor: AppTheme.selectedSurface,
                    textColor: AppTheme.primaryLight,
                    iconColor: AppTheme.primaryLight,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSpecPill(
                    icon: Icons.description_outlined,
                    label: 'الخامة الافتراضية',
                    value: '${p.defaultPaperCategory} ${p.defaultPaperType}',
                    bgColor: AppTheme.surfaceSecondary,
                    textColor: AppTheme.primaryLight,
                    iconColor: AppTheme.primaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showEditProductDialog(p),
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: const Text('تعديل قالب المنتج'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.infoSurface,
                  foregroundColor: AppTheme.info,
                  elevation: 0,
                  side: BorderSide(color: AppTheme.info.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // تبويب 3: خدمات التشطيب
  // ==========================================
  Widget _buildFinishingsTab(ErpProvider erp, bool isMobile) {
    if (isMobile) {
      return Column(
        children: erp.finishings.map((f) => _buildFinishingMobileCard(f)).toList(),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppTheme.surfaceSecondary),
            columns: const [
              DataColumn(label: Text('الخدمة (التشطيب)', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('السعر المحدد', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('وحدة الاحتساب', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('تعديل السعر', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: erp.finishings.map((f) {
              return DataRow(cells: [
                DataCell(Text(f.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(AppTheme.formatCurrency(f.price, context.read<ErpProvider>().settings.currency))),
                DataCell(Text(f.unit)),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, size: 18, color: AppTheme.info),
                    onPressed: () => _showEditFinishingDialog(f),
                  ),
                ),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildFinishingMobileCard(FinishingItem f) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.content_cut_rounded, color: AppTheme.warning, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    f.name,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkSlate,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceSecondary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'وحدة الاحتساب: ${f.unit}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.successSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Text(
                    AppTheme.formatCurrency(f.price, context.read<ErpProvider>().settings.currency),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.success,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 32,
                  child: TextButton.icon(
                    onPressed: () => _showEditFinishingDialog(f),
                    icon: const Icon(Icons.edit_rounded, size: 15),
                    label: const Text('تعديل', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.info,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecPill({
    required IconData icon,
    required String label,
    required String value,
    required Color bgColor,
    required Color textColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: textColor.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: textColor.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditMachineDialog(MachineItem m) {
    final erp = context.read<ErpProvider>();
    final costCtrl = TextEditingController(text: '${m.hourlyCost.toInt()}');
    final wasteCtrl = TextEditingController(text: '${m.wastePct}');
    final speedCtrl = TextEditingController(text: '${m.speedPerHour}');
    String status = m.status;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit_note_rounded, color: AppTheme.primaryLight, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'تعديل ماكينة: ${m.name}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: costCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'تكلفة الساعة (ريال/ساعة)',
                    prefixIcon: Icon(Icons.monetization_on_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: wasteCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'نسبة الهالك %',
                    prefixIcon: Icon(Icons.warning_amber_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: speedCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'السرعة الإنتاجية (فرخ/ساعة)',
                    prefixIcon: Icon(Icons.speed_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(
                    labelText: 'حالة التشغيل',
                    prefixIcon: Icon(Icons.toggle_on_outlined, size: 20),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'نشطة', child: Text('نشطة')),
                    DropdownMenuItem(value: 'موقوفة', child: Text('موقوفة')),
                  ],
                  onChanged: (s) => setDialogState(() => status = s ?? 'نشطة'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                m.hourlyCost = double.tryParse(costCtrl.text) ?? m.hourlyCost;
                m.wastePct = double.tryParse(wasteCtrl.text) ?? m.wastePct;
                m.speedPerHour = int.tryParse(speedCtrl.text) ?? m.speedPerHour;
                m.status = status;
                await erp.updateMachine(m);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('حفظ التعديل', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProductDialog(ProductTemplate p) {
    final erp = context.read<ErpProvider>();
    final ppsCtrl = TextEditingController(text: '${p.pagesPerSheet}');
    final bindingCtrl = TextEditingController(text: p.binding);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_stories_rounded, color: AppTheme.info, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'تعديل قالب: ${p.name}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: ppsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'صفحات الفرخ 50x35',
                  prefixIcon: Icon(Icons.layers_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: bindingCtrl,
                decoration: const InputDecoration(
                  labelText: 'نوع التجليد الافتراضي',
                  prefixIcon: Icon(Icons.menu_book_outlined, size: 20),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              p.pagesPerSheet = int.tryParse(ppsCtrl.text) ?? p.pagesPerSheet;
              p.binding = bindingCtrl.text;
              await erp.updateProduct(p);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.info,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('حفظ التعديل', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditFinishingDialog(FinishingItem f) {
    final erp = context.read<ErpProvider>();
    final priceCtrl = TextEditingController(text: '${f.price.toInt()}');
    String unit = f.unit;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.content_cut_rounded, color: AppTheme.warning, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'تعديل سعر خدمة: ${f.name}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'السعر المحدد (ريال)',
                    prefixIcon: Icon(Icons.monetization_on_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: unit,
                  decoration: const InputDecoration(
                    labelText: 'وحدة الاحتساب',
                    prefixIcon: Icon(Icons.tune_rounded, size: 20),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'للعملية', child: Text('للعملية (مقطوع)')),
                    DropdownMenuItem(value: 'للألف', child: Text('للألف فرخ / صفحة')),
                    DropdownMenuItem(value: 'للقطعة', child: Text('للقطعة / النسخة')),
                  ],
                  onChanged: (u) => setDialogState(() => unit = u ?? 'للعملية'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                f.price = double.tryParse(priceCtrl.text) ?? f.price;
                f.unit = unit;
                await erp.updateFinishing(f);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warning,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('حفظ التعديل', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
