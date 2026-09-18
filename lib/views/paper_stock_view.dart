import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../providers/erp_provider.dart';
import '../theme/app_theme.dart';

class PaperStockView extends StatefulWidget {
  const PaperStockView({super.key});

  @override
  State<PaperStockView> createState() => _PaperStockViewState();
}

class _PaperStockViewState extends State<PaperStockView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // فلاتر تبويب الأصناف
  String _paperSearchQuery = '';
  String _categoryFilter = 'الكل';
  bool _onlyLowStock = false;
  String _paperSortBy = 'name'; // name, balance_desc, balance_asc, price_desc

  // فلاتر تبويب الحركات
  String _moveSearchQuery = '';
  String _moveTypeFilter = 'الكل'; // الكل, دخول, خروج, تسوية

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final erp = context.watch<ErpProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // شريط العنوان الرئيسي
          _buildHeader(erp),
          const SizedBox(height: 16),

          // كروت المؤشرات الإحصائية
          _buildMetricsGrid(erp),
          const SizedBox(height: 20),

          // شريط التبويبات المتجاوب
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppTheme.primaryGreen,
              unselectedLabelColor: AppTheme.textMuted,
              indicatorColor: AppTheme.primaryGreen,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: [
                Tab(
                  icon: const Icon(Icons.layers_outlined),
                  text: 'أرصدة وخامات الورق (${erp.papers.length})',
                ),
                Tab(
                  icon: const Icon(Icons.history_outlined),
                  text: 'سجل حركات المخزون (${erp.stockMoves.length})',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // محتوى التبويب النشط
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              if (_tabController.index == 0) {
                return _buildPaperBalancesSection(erp);
              } else {
                return _buildStockMovesSection(erp);
              }
            },
          ),
        ],
      ),
    );
  }

  // --- شريط العنوان ---
  Widget _buildHeader(ErpProvider erp) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 10,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.inventory_2, color: AppTheme.primaryGreen, size: 22),
                ),
                const Text(
                  'قاعدة الورق وإدارة المخزون',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'أرصدة الورق، أسعار الأفرخ، كروت الأصناف، والتوريد والمنصرف للإنتاج',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
          ],
        ),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => _showNewMovementDialog(null),
              icon: const Icon(Icons.swap_horiz, size: 18),
              label: const Text('تسجيل حركة مخزون'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryGreen,
                side: const BorderSide(color: AppTheme.primaryGreen),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _showPaperDialog(null),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('إضافة صنف ورق جديد'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            ),
          ],
        ),
      ],
    );
  }

  // --- كروت المؤشرات الإحصائية ---
  Widget _buildMetricsGrid(ErpProvider erp) {
    final totalSheets = erp.papers.fold<double>(0, (s, p) => s + p.balance).toInt();
    final lowStockCount = erp.lowStockPapers.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 950 ? 4 : (constraints.maxWidth > 550 ? 2 : 1);
        final aspect = constraints.maxWidth > 1200 ? 2.6 : (constraints.maxWidth > 950 ? 2.1 : 2.2);

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: aspect,
          children: [
            _buildMetricCard(
              title: 'إجمالي قيمة مخزون الورق',
              value: AppTheme.formatCurrency(erp.totalPaperInventoryValue, erp.settings.currency),
              subtitle: '$totalSheets فرخ 100x70 بالمستودع',
              icon: Icons.account_balance_wallet_outlined,
              color: AppTheme.primaryGreen,
              onTap: null,
            ),
            _buildMetricCard(
              title: 'أصناف تحت حد الطلب',
              value: '$lowStockCount صنف',
              subtitle: lowStockCount == 0 ? 'المخزون بالمستوى الآمن' : 'اضغط لعرض الأصناف المحتاجة لطلب',
              icon: Icons.warning_amber_rounded,
              color: lowStockCount == 0 ? Colors.green : Colors.red.shade700,
              onTap: () {
                setState(() {
                  _tabController.index = 0;
                  _onlyLowStock = !_onlyLowStock;
                });
              },
            ),
            _buildMetricCard(
              title: 'أصناف الورق المسجلة',
              value: '${erp.papers.length} خامة',
              subtitle: 'أوفست، كوشيه، بريستول، NCR...',
              icon: Icons.layers_outlined,
              color: const Color(0xFF0284C7),
              onTap: null,
            ),
            _buildMetricCard(
              title: 'حركات المخزون المسجلة',
              value: '${erp.stockMoves.length} حركة',
              subtitle: 'وارد / منصرف / تسوية',
              icon: Icons.history_edu_outlined,
              color: AppTheme.accentGold,
              onTap: () => setState(() => _tabController.index = 1),
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
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: TextStyle(fontSize: 12, color: AppTheme.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        value,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 11, color: AppTheme.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // تبويب 1: أرصدة وخامات الورق
  // ==========================================
  Widget _buildPaperBalancesSection(ErpProvider erp) {
    final categories = ['الكل', ...erp.papers.map((p) => p.category).toSet()];

    final filtered = erp.papers.where((p) {
      final matchesCategory = _categoryFilter == 'الكل' || p.category == _categoryFilter;
      final matchesLowStock = !_onlyLowStock || p.isUnderReorder;
      final q = _paperSearchQuery.trim().toLowerCase();
      final matchesSearch = q.isEmpty ||
          p.displayName.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          p.paperType.toLowerCase().contains(q) ||
          '${p.gsm}'.contains(q) ||
          (p.supplier != null && p.supplier!.toLowerCase().contains(q));
      return matchesCategory && matchesLowStock && matchesSearch;
    }).toList();

    // الترتيب
    if (_paperSortBy == 'balance_desc') {
      filtered.sort((a, b) => b.balance.compareTo(a.balance));
    } else if (_paperSortBy == 'balance_asc') {
      filtered.sort((a, b) => a.balance.compareTo(b.balance));
    } else if (_paperSortBy == 'price_desc') {
      filtered.sort((a, b) => b.sheetPrice.compareTo(a.sheetPrice));
    } else {
      filtered.sort((a, b) => a.displayName.compareTo(b.displayName));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // شريط البحث والفلترة
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 600;
                final searchInput = TextField(
                  decoration: InputDecoration(
                    hintText: 'بحث باسم الخامة، الجرام، الفئة، أو المورد...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _paperSearchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _paperSearchQuery = ''),
                          )
                        : null,
                    isDense: true,
                  ),
                  onChanged: (val) => setState(() => _paperSearchQuery = val),
                );

                final sortDropdown = Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _paperSortBy,
                      isExpanded: isCompact,
                      icon: const Icon(Icons.sort, size: 18),
                      items: const [
                        DropdownMenuItem(value: 'name', child: Text('الاسم أبجدياً')),
                        DropdownMenuItem(value: 'balance_desc', child: Text('الأعلى رصيداً')),
                        DropdownMenuItem(value: 'balance_asc', child: Text('الأقل رصيداً')),
                        DropdownMenuItem(value: 'price_desc', child: Text('الأعلى سعراً')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _paperSortBy = val);
                      },
                    ),
                  ),
                );

                if (isCompact) {
                  return Column(
                    children: [
                      searchInput,
                      const SizedBox(height: 10),
                      sortDropdown,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: searchInput),
                    const SizedBox(width: 12),
                    sortDropdown,
                  ],
                );
              },
            ),
            const SizedBox(height: 12),

            // رقائق الفئات والتصفية
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('الفئات:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ...categories.map((c) {
                  final isSelected = _categoryFilter == c;
                  return ChoiceChip(
                    label: Text(c),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryGreen.withOpacity(0.15),
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.primaryGreen : AppTheme.textDark,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (_) => setState(() => _categoryFilter = c),
                  );
                }),
                FilterChip(
                  label: Text('تحت حد الطلب (${erp.lowStockPapers.length})'),
                  selected: _onlyLowStock,
                  selectedColor: Colors.red.shade100,
                  checkmarkColor: Colors.red.shade900,
                  labelStyle: TextStyle(
                    color: _onlyLowStock ? Colors.red.shade900 : Colors.black87,
                    fontWeight: _onlyLowStock ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  onSelected: (val) => setState(() => _onlyLowStock = val),
                ),
              ],
            ),
            const Divider(height: 24),

            // جدول الأصناف
            if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('لا توجد أصناف ورق مطابقة لخيارات البحث')),
              )
            else if (MediaQuery.of(context).size.width < 750)
              _buildMobilePaperCards(filtered, erp)
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                  columns: const [
                    DataColumn(label: Text('الفئة', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('النوع والجرام', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('مقاس الفرخ', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('ملازم 50x35', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('سعر الفرخ', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('الرصيد الحالي', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('حد الطلب', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('حالة المخزون', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('القيمة الإجمالية', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('المورد', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: filtered.map((p) {
                    final status = p.balance <= 0
                        ? 'نافد'
                        : (p.isUnderReorder ? 'إعادة طلب' : 'طبيعي');

                    return DataRow(cells: [
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            p.category,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen, fontSize: 12),
                          ),
                        ),
                      ),
                      DataCell(Text('${p.paperType} (${p.gsm} جم)', style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(p.sheetSize)),
                      DataCell(Text('${p.sheetsPerUnit}')),
                      DataCell(Text(AppTheme.formatCurrency(p.sheetPrice))),
                      DataCell(
                        Text(
                          '${p.balance.toInt()} فرخ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: p.balance <= 0 ? Colors.red : (p.isUnderReorder ? Colors.amber.shade900 : Colors.black87),
                          ),
                        ),
                      ),
                      DataCell(Text('${p.reorderLevel}')),
                      DataCell(AppTheme.statusBadge(status)),
                      DataCell(Text(AppTheme.formatCurrency(p.totalValue), style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(p.supplier ?? '—')),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // حركة سريعة
                            IconButton(
                              icon: const Icon(Icons.add_shopping_cart, size: 18, color: AppTheme.primaryGreen),
                              tooltip: 'تسجيل حركة مخزون للصنف',
                              onPressed: () => _showNewMovementDialog(p),
                            ),
                            // كارت الصنف
                            IconButton(
                              icon: const Icon(Icons.receipt_long_outlined, size: 18, color: Color(0xFF0284C7)),
                              tooltip: 'كارت الصنف وسجل الحركات',
                              onPressed: () => _showItemStockCardDialog(p, erp),
                            ),
                            // تعديل
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.accentGold),
                              tooltip: 'تعديل بيانات وسعر الصنف',
                              onPressed: () => _showPaperDialog(p),
                            ),
                            // حذف
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              tooltip: 'حذف الصنف',
                              onPressed: () => _confirmDeletePaper(p, erp),
                            ),
                          ],
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // تبويب 2: سجل الحركات المخزنية
  // ==========================================
  Widget _buildStockMovesSection(ErpProvider erp) {
    final filteredMoves = erp.stockMoves.where((m) {
      final matchesType = _moveTypeFilter == 'الكل' || m.moveType == _moveTypeFilter;
      final q = _moveSearchQuery.trim().toLowerCase();
      final matchesSearch = q.isEmpty ||
          m.number.toLowerCase().contains(q) ||
          m.paperCategory.toLowerCase().contains(q) ||
          m.paperType.toLowerCase().contains(q) ||
          '${m.gsm}'.contains(q) ||
          (m.reference != null && m.reference!.toLowerCase().contains(q)) ||
          (m.supplier != null && m.supplier!.toLowerCase().contains(q)) ||
          (m.notes != null && m.notes!.toLowerCase().contains(q));
      return matchesType && matchesSearch;
    }).toList();

    // إحصائيات سريعة للحركات
    final totalIn = erp.stockMoves.where((m) => m.moveType == 'دخول').fold<double>(0, (s, m) => s + m.qtySheets);
    final totalOut = erp.stockMoves.where((m) => m.moveType == 'خروج').fold<double>(0, (s, m) => s + m.qtySheets);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ملخص الوارد والمنصرف
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_downward, color: Color(0xFF15803D), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'إجمالي الوارد: ${totalIn.toInt()} فرخ',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF15803D), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_upward, color: Color(0xFFB91C1C), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'إجمالي المنصرف: ${totalOut.toInt()} فرخ',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB91C1C), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // شريط البحث ونوع الحركة
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 600;
                final searchInput = TextField(
                  decoration: InputDecoration(
                    hintText: 'بحث برقم الحركة، اسم الصنف، المرجع، المورد...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _moveSearchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _moveSearchQuery = ''),
                          )
                        : null,
                    isDense: true,
                  ),
                  onChanged: (val) => setState(() => _moveSearchQuery = val),
                );

                final typeDropdown = Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _moveTypeFilter,
                      isExpanded: isCompact,
                      items: const [
                        DropdownMenuItem(value: 'الكل', child: Text('جميع الحركات')),
                        DropdownMenuItem(value: 'دخول', child: Text('دخول (توريد)')),
                        DropdownMenuItem(value: 'خروج', child: Text('خروج (صرف إنتاج)')),
                        DropdownMenuItem(value: 'تسوية', child: Text('تسوية جردية')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _moveTypeFilter = val);
                      },
                    ),
                  ),
                );

                if (isCompact) {
                  return Column(
                    children: [
                      searchInput,
                      const SizedBox(height: 10),
                      typeDropdown,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: searchInput),
                    const SizedBox(width: 12),
                    typeDropdown,
                  ],
                );
              },
            ),
            const Divider(height: 24),

            if (filteredMoves.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('لا توجد حركات مخزون مسجلة تطابق البحث')),
              )
            else if (MediaQuery.of(context).size.width < 750)
              _buildMobileStockMoveCards(filteredMoves, erp)
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                  columns: const [
                    DataColumn(label: Text('رقم الحركة', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('نوع الحركة', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('الخامة والجرام', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('الكمية (فرخ)', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('سعر الوحدة', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('القيمة الإجمالية', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('المرجع', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('المورد / الجهة', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('ملاحظات', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('إلغاء الحركة', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: filteredMoves.map((m) {
                    return DataRow(cells: [
                      DataCell(Text(m.number, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(AppTheme.formatDate(m.date))),
                      DataCell(AppTheme.statusBadge(m.moveType)),
                      DataCell(Text('${m.paperCategory} ${m.paperType} (${m.gsm}جم)', style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(
                        '${m.moveType == 'خروج' ? '-' : '+'}${m.qtySheets.toInt()} فرخ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: m.moveType == 'خروج' ? Colors.red : Colors.green.shade800,
                        ),
                      )),
                      DataCell(Text(AppTheme.formatCurrency(m.unitPrice))),
                      DataCell(Text(AppTheme.formatCurrency(m.totalValue), style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(m.reference ?? '—')),
                      DataCell(Text(m.supplier ?? '—')),
                      DataCell(Text(m.notes ?? '—')),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          tooltip: 'إلغاء هذه الحركة وعكس الرصيد',
                          onPressed: () => _confirmDeleteStockMove(m, erp),
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // نافذة كارت الصنف وسجل الحركات الخاص به
  // ==========================================
  void _showItemStockCardDialog(PaperItem paper, ErpProvider erp) {
    final itemMoves = erp.stockMoves.where((m) => m.paperId == paper.id).toList();
    itemMoves.sort((a, b) => a.date.compareTo(b.date)); // ترتيب زمني

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: 800,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // رأس الكارت
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.badge_outlined, color: AppTheme.primaryGreen, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'كارت صنف: ${paper.displayName}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                          ),
                          Text(
                            'المقاس: ${paper.sheetSize} | ${paper.sheetsPerUnit} ملازم/فرخ | حد الطلب: ${paper.reorderLevel} فرخ',
                            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 20),

              // شريط الرصيد والقيمة الحاليين
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceAround,
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _buildLedgerMetric('الرصيد الحالي', '${paper.balance.toInt()} فرخ', paper.isUnderReorder ? Colors.red : AppTheme.primaryGreen),
                    _buildLedgerMetric('سعر الفرخ', AppTheme.formatCurrency(paper.sheetPrice), AppTheme.darkSlate),
                    _buildLedgerMetric('قيمة المخزون', AppTheme.formatCurrency(paper.totalValue), const Color(0xFF0284C7)),
                    _buildLedgerMetric('حالة الصنف', paper.isUnderReorder ? 'إعادة طلب' : 'طبيعي', paper.isUnderReorder ? Colors.red : Colors.green),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // جدول حركات الصنف
              const Text(
                'سجل الحركات الزمنية للصنف:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: itemMoves.isEmpty
                    ? const Center(child: Text('لا توجد حركات مسجلة لهذا الصنف بعد'))
                    : SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                            columns: const [
                              DataColumn(label: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('رقم الحركة', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('نوع الحركة', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('الكمية (فرخ)', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('سعر الوحدة', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('المرجع / البيان', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('المورد / المستلم', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: itemMoves.map((m) {
                              return DataRow(cells: [
                                DataCell(Text(AppTheme.formatDate(m.date))),
                                DataCell(Text(m.number)),
                                DataCell(AppTheme.statusBadge(m.moveType)),
                                DataCell(Text(
                                  '${m.moveType == 'خروج' ? '-' : '+'}${m.qtySheets.toInt()}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: m.moveType == 'خروج' ? Colors.red : Colors.green.shade800,
                                  ),
                                )),
                                DataCell(Text(AppTheme.formatCurrency(m.unitPrice))),
                                DataCell(Text(AppTheme.formatCurrency(m.totalValue))),
                                DataCell(Text(m.reference ?? '—')),
                                DataCell(Text(m.supplier ?? '—')),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 12),

              // زر إضافة حركة جديدة من داخل الكارت
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showNewMovementDialog(paper);
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('تسجيل حركة لهذا الصنف'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLedgerMetric(String title, String val, Color color) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  // ==========================================
  // نافذة إضافة / تعديل صنف ورق
  // ==========================================
  void _showPaperDialog(PaperItem? paperToEdit) {
    final isEditing = paperToEdit != null;
    final erp = context.read<ErpProvider>();

    final categoriesList = ['أوفست', 'كوشيه', 'بريستول', 'دوبلكس', 'كرافت', 'NCR', 'ورق مكربن'];
    String selectedCategory = paperToEdit?.category ?? 'أوفست';
    if (!categoriesList.contains(selectedCategory)) {
      categoriesList.add(selectedCategory);
    }

    final typeCtrl = TextEditingController(text: paperToEdit?.paperType ?? 'أبيض');
    final gsmCtrl = TextEditingController(text: '${paperToEdit?.gsm ?? 80}');
    final sheetSizeCtrl = TextEditingController(text: paperToEdit?.sheetSize ?? '100x70');
    final sheetsPerUnitCtrl = TextEditingController(text: '${paperToEdit?.sheetsPerUnit ?? 4}');
    final priceCtrl = TextEditingController(text: '${paperToEdit?.sheetPrice.toInt() ?? 100}');
    final reorderCtrl = TextEditingController(text: '${paperToEdit?.reorderLevel ?? 200}');
    final initialBalanceCtrl = TextEditingController(text: '${paperToEdit?.balance.toInt() ?? 1000}');
    final supplierCtrl = TextEditingController(text: paperToEdit?.supplier ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // رأس النافذة التنفيذي
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isEditing ? Icons.edit_note_rounded : Icons.post_add_rounded,
                            color: AppTheme.primaryGreen,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEditing ? 'تعديل صنف الورق' : 'إضافة صنف ورق جديد',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isEditing ? paperToEdit.displayName : 'تسجيل مواصفات الخامة وسعر الشراء وحد الأمان',
                                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 14),

                    // الفئة ونوع الورق
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'فئة الورق',
                              prefixIcon: Icon(Icons.category_outlined, size: 18),
                            ),
                            items: categoriesList.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (val) {
                              if (val != null) setDialogState(() => selectedCategory = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: typeCtrl,
                            decoration: const InputDecoration(
                              labelText: 'نوع الخامة (أبيض، لامع...)',
                              prefixIcon: Icon(Icons.format_paint_outlined, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // الجرام ومقاس الفرخ
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: gsmCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'الجرام (GSM)',
                              prefixIcon: Icon(Icons.fitness_center_outlined, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: sheetSizeCtrl,
                            decoration: const InputDecoration(
                              labelText: 'مقاس الفرخ (سم)',
                              prefixIcon: Icon(Icons.aspect_ratio_outlined, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ملازم الفرخ وسعر الفرخ
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: sheetsPerUnitCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'ملازم 50x35 لكل فرخ',
                              prefixIcon: Icon(Icons.grid_view_rounded, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: priceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'سعر الفرخ الواحد',
                              prefixIcon: Icon(Icons.payments_outlined, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // حد إعادة الطلب والرصيد الحالي
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: reorderCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'حد إعادة الطلب (فرخ)',
                              prefixIcon: Icon(Icons.notification_important_outlined, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: initialBalanceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: isEditing ? 'الرصيد الحالي (فرخ)' : 'الرصيد الافتتاحي (فرخ)',
                              prefixIcon: const Icon(Icons.inventory_2_outlined, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: supplierCtrl,
                      decoration: const InputDecoration(
                        labelText: 'اسم المورد المعتمد (اختياري)',
                        prefixIcon: Icon(Icons.storefront_outlined, size: 18),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // أزرار التحكم
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              side: const BorderSide(color: AppTheme.borderColor),
                            ),
                            child: const Text('إلغاء', style: TextStyle(color: AppTheme.textMuted)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final gsm = int.tryParse(gsmCtrl.text) ?? 80;
                              final sheetsPerUnit = int.tryParse(sheetsPerUnitCtrl.text) ?? 4;
                              final sheetPrice = double.tryParse(priceCtrl.text) ?? 0.0;
                              final reorderLevel = int.tryParse(reorderCtrl.text) ?? 200;
                              final balance = double.tryParse(initialBalanceCtrl.text) ?? 0.0;

                              if (isEditing) {
                                paperToEdit.category = selectedCategory;
                                paperToEdit.paperType = typeCtrl.text.trim();
                                paperToEdit.gsm = gsm;
                                paperToEdit.sheetSize = sheetSizeCtrl.text.trim();
                                paperToEdit.sheetsPerUnit = sheetsPerUnit;
                                paperToEdit.sheetPrice = sheetPrice;
                                paperToEdit.reorderLevel = reorderLevel;
                                paperToEdit.balance = balance;
                                paperToEdit.supplier = supplierCtrl.text.trim().isEmpty ? null : supplierCtrl.text.trim();

                                await erp.updatePaper(paperToEdit);
                              } else {
                                final newId = 'P_${DateTime.now().millisecondsSinceEpoch}';
                                final newPaper = PaperItem(
                                  id: newId,
                                  category: selectedCategory,
                                  paperType: typeCtrl.text.trim(),
                                  gsm: gsm,
                                  sheetSize: sheetSizeCtrl.text.trim(),
                                  sheetsPerUnit: sheetsPerUnit,
                                  sheetPrice: sheetPrice,
                                  reorderLevel: reorderLevel,
                                  balance: balance,
                                  supplier: supplierCtrl.text.trim().isEmpty ? null : supplierCtrl.text.trim(),
                                );
                                await erp.addPaper(newPaper);
                              }

                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(isEditing ? 'تم تحديث بيانات الصنف بنجاح!' : 'تم إضافة صنف الورق الجديد بنجاح!')),
                                );
                              }
                            },
                            icon: Icon(isEditing ? Icons.check_rounded : Icons.add_rounded, size: 18),
                            label: Text(isEditing ? 'حفظ التعديلات' : 'إضافة الصنف'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
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

  // ==========================================
  // تأكيد حذف صنف ورق
  // ==========================================
  void _confirmDeletePaper(PaperItem paper, ErpProvider erp) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'تأكيد حذف صنف الورق',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  'هل أنت متأكد من رغبتك في حذف الصنف "${paper.displayName}"؟',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                ),
                const SizedBox(height: 6),
                Text(
                  'الرصيد الحالي للصنف: ${paper.balance.toInt()} فرخ.\n(ملاحظة: لن يتم حذف حركات المخزون السابقة المسجلة عليه)',
                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.4),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: const BorderSide(color: AppTheme.borderColor),
                        ),
                        child: const Text('إلغاء', style: TextStyle(color: AppTheme.textMuted)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await erp.deletePaper(paper.id);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تم حذف الصنف ${paper.displayName} بنجاح')),
                            );
                          }
                        },
                        icon: const Icon(Icons.delete_forever_rounded, size: 18),
                        label: const Text('نعم، حذف الصنف'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // نافذة تسجيل حركة مخزون جديدة
  // ==========================================
  void _showNewMovementDialog(PaperItem? defaultPaper) {
    final erp = context.read<ErpProvider>();
    PaperItem? selectedPaper = defaultPaper ?? (erp.papers.isNotEmpty ? erp.papers.first : null);
    String moveType = 'دخول';
    final qtyCtrl = TextEditingController(text: '1000');
    final priceCtrl = TextEditingController(text: '${selectedPaper?.sheetPrice.toInt() ?? 0}');
    final refCtrl = TextEditingController();
    final supplierCtrl = TextEditingController(text: selectedPaper?.supplier ?? '');
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // رأس النافذة
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.swap_horiz_rounded, color: AppTheme.primaryGreen, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'تسجيل حركة مخزون جديدة',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'توريد جديد، صرف تشغيل للإنتاج، أو تسوية جرد',
                                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 14),

                    DropdownButtonFormField<PaperItem>(
                      isExpanded: true,
                      initialValue: selectedPaper,
                      decoration: const InputDecoration(
                        labelText: 'صنف الورق',
                        prefixIcon: Icon(Icons.layers_outlined, size: 18),
                      ),
                      items: erp.papers.map((p) => DropdownMenuItem(value: p, child: Text(p.displayName, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (p) {
                        setDialogState(() {
                          selectedPaper = p;
                          if (p != null) {
                            priceCtrl.text = '${p.sheetPrice.toInt()}';
                            supplierCtrl.text = p.supplier ?? '';
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: moveType,
                      decoration: const InputDecoration(
                        labelText: 'نوع الحركة',
                        prefixIcon: Icon(Icons.sync_alt_rounded, size: 18),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'دخول', child: Text('دخول (شراء / توريد جديد)', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'خروج', child: Text('خروج (صرف إنتاج / تالف)', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'تسوية', child: Text('تسوية (جرد ومطابقة الرصيد)', overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (m) => setDialogState(() => moveType = m ?? 'دخول'),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: qtyCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'الكمية (أفرخ 100x70)',
                              prefixIcon: Icon(Icons.pin_outlined, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: priceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'سعر الفرخ الواحد',
                              prefixIcon: Icon(Icons.payments_outlined, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: refCtrl,
                      decoration: const InputDecoration(
                        labelText: 'المرجع (رقم الفاتورة أو أمر التشغيل)',
                        prefixIcon: Icon(Icons.receipt_outlined, size: 18),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: supplierCtrl,
                      decoration: const InputDecoration(
                        labelText: 'اسم المورد / الجهة المستلمة',
                        prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظات إضافية على الحركة',
                        prefixIcon: Icon(Icons.note_alt_outlined, size: 18),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // أزرار التحكم
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              side: const BorderSide(color: AppTheme.borderColor),
                            ),
                            child: const Text('إلغاء', style: TextStyle(color: AppTheme.textMuted)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              if (selectedPaper == null) return;
                              final qty = double.tryParse(qtyCtrl.text) ?? 0;
                              final price = double.tryParse(priceCtrl.text) ?? selectedPaper!.sheetPrice;

                              await erp.addStockMove(
                                moveType: moveType,
                                paperId: selectedPaper!.id,
                                qtySheets: qty,
                                unitPrice: price,
                                reference: refCtrl.text.trim().isEmpty ? null : refCtrl.text.trim(),
                                supplier: supplierCtrl.text.trim().isEmpty ? null : supplierCtrl.text.trim(),
                                notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                              );

                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تم تسجيل حركة المخزون وتحديث رصيد الورق بنجاح!')),
                                );
                              }
                            },
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text('حفظ الحركة'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
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

  // ==========================================
  // تأكيد إلغاء حركة مخزون
  // ==========================================
  void _confirmDeleteStockMove(StockMove move, ErpProvider erp) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'تأكيد إلغاء حركة المخزون',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  'هل أنت متأكد من رغبتك في إلغاء الحركة رقم "${move.number}"؟',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                ),
                const SizedBox(height: 6),
                Text(
                  'النوع: ${move.moveType} | الكمية: ${move.qtySheets.toInt()} فرخ.\n(سيتم عكس أثر الحركة على رصيد المخزون تلقائياً)',
                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.4),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: const BorderSide(color: AppTheme.borderColor),
                        ),
                        child: const Text('إلغاء', style: TextStyle(color: AppTheme.textMuted)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await erp.deleteStockMove(move.id);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تم إلغاء الحركة ${move.number} وعكس أثر الرصيد بنجاح')),
                            );
                          }
                        },
                        icon: const Icon(Icons.delete_forever_rounded, size: 18),
                        label: const Text('نعم، إلغاء الحركة'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // العرض المتجاوب للهاتف المحمول (Mobile Cards)
  // ==========================================
  Widget _buildMobilePaperCards(List<PaperItem> papers, ErpProvider erp) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: papers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final p = papers[index];
        final isUnder = p.isUnderReorder;
        final isDepleted = p.balance <= 0;
        final status = isDepleted ? 'نافد' : (isUnder ? 'إعادة طلب' : 'طبيعي');

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDepleted
                  ? Colors.red.shade300
                  : (isUnder ? Colors.orange.shade300 : AppTheme.borderColor),
              width: (isDepleted || isUnder) ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الصف العلوي: الفئة واسم الخامة والشارة
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      p.category,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${p.paperType} (${p.gsm} جم)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.darkSlate,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  AppTheme.statusBadge(status),
                ],
              ),
              const SizedBox(height: 10),

              // شبكة البيانات الأساسية
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMobileField('الرصيد الحالي:', '${p.balance.toInt()} فرخ',
                            highlightColor: isDepleted
                                ? Colors.red
                                : (isUnder ? Colors.orange.shade900 : Colors.green.shade800),
                            isBold: true),
                        _buildMobileField('حد الطلب:', '${p.reorderLevel} فرخ'),
                      ],
                    ),
                    const Divider(height: 12, thickness: 0.5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMobileField('سعر الفرخ:', AppTheme.formatCurrency(p.sheetPrice), isBold: true),
                        _buildMobileField('مقاس الفرخ:', p.sheetSize),
                      ],
                    ),
                    const Divider(height: 12, thickness: 0.5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMobileField('ملازم 50x35:', '${p.sheetsPerUnit} ملازم'),
                        _buildMobileField('قيمة المخزون:', AppTheme.formatCurrency(p.totalValue)),
                      ],
                    ),
                    if (p.supplier != null && p.supplier!.isNotEmpty) ...[
                      const Divider(height: 12, thickness: 0.5),
                      Row(
                        children: [
                          const Icon(Icons.storefront_outlined, size: 14, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'المورد: ${p.supplier}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // أزرار التحكم والإجراءات السريعة
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showNewMovementDialog(p),
                      icon: const Icon(Icons.add_shopping_cart, size: 15),
                      label: const Text('تسجيل حركة', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryGreen,
                        side: const BorderSide(color: AppTheme.primaryGreen),
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.receipt_long_outlined, size: 19, color: Color(0xFF0284C7)),
                    tooltip: 'كارت الصنف',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _showItemStockCardDialog(p, erp),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 19, color: AppTheme.accentGold),
                    tooltip: 'تعديل',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _showPaperDialog(p),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 19, color: Colors.red),
                    tooltip: 'حذف',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _confirmDeletePaper(p, erp),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileField(String label, String value, {Color? highlightColor, bool isBold = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: highlightColor ?? AppTheme.darkSlate,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileStockMoveCards(List<StockMove> moves, ErpProvider erp) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: moves.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final m = moves[index];
        final isOut = m.moveType == 'خروج';

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(m.number, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 8),
                      Text(AppTheme.formatDate(m.date), style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    ],
                  ),
                  AppTheme.statusBadge(m.moveType),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${m.paperCategory} ${m.paperType} (${m.gsm}جم)',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.darkSlate),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${isOut ? '-' : '+'}${m.qtySheets.toInt()} فرخ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isOut ? Colors.red : Colors.green.shade800,
                      ),
                    ),
                    Text('السعر: ${AppTheme.formatCurrency(m.unitPrice)}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    Text(
                      'الإجمالي: ${AppTheme.formatCurrency(m.totalValue)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.darkSlate),
                    ),
                  ],
                ),
              ),
              if ((m.reference != null && m.reference!.isNotEmpty) || (m.notes != null && m.notes!.isNotEmpty)) ...[
                const SizedBox(height: 6),
                Text(
                  [
                    if (m.reference != null && m.reference!.isNotEmpty) 'المرجع: ${m.reference}',
                    if (m.notes != null && m.notes!.isNotEmpty) 'ملاحظات: ${m.notes}',
                  ].join(' | '),
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _confirmDeleteStockMove(m, erp),
                  icon: const Icon(Icons.delete_outline, size: 14, color: Colors.red),
                  label: const Text('إلغاء الحركة', style: TextStyle(color: Colors.red, fontSize: 11)),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
