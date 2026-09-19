import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../providers/erp_provider.dart';
import '../theme/app_theme.dart';

class CustomersView extends StatefulWidget {
  final Function(int)? onNavigate;

  const CustomersView({super.key, this.onNavigate});

  @override
  State<CustomersView> createState() => _CustomersViewState();
}

class _CustomersViewState extends State<CustomersView> {
  String _searchQuery = '';
  String _filterType = 'all'; // all, debt, settled, credit
  String _sortBy = 'debt_desc'; // debt_desc, debt_asc, name, code, sales_desc

  @override
  Widget build(BuildContext context) {
    final erp = context.watch<ErpProvider>();

    // تصفية العملاء
    List<Customer> filtered = erp.customers.where((c) {
      final matchesSearch = _searchQuery.isEmpty ||
          c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.code.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (c.phone != null && c.phone!.contains(_searchQuery)) ||
          (c.address != null && c.address!.toLowerCase().contains(_searchQuery.toLowerCase()));

      if (!matchesSearch) return false;

      if (_filterType == 'debt') {
        return c.currentBalance > 0;
      } else if (_filterType == 'settled') {
        return c.currentBalance == 0;
      } else if (_filterType == 'credit') {
        return c.currentBalance < 0;
      }
      return true;
    }).toList();

    // ترتيب العملاء
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'debt_desc':
          return b.currentBalance.compareTo(a.currentBalance);
        case 'debt_asc':
          return a.currentBalance.compareTo(b.currentBalance);
        case 'name':
          return a.name.compareTo(b.name);
        case 'code':
          return a.code.compareTo(b.code);
        case 'sales_desc':
          return b.totalSales.compareTo(a.totalSales);
        default:
          return b.currentBalance.compareTo(a.currentBalance);
      }
    });

    final totalReceivables = erp.totalReceivables;
    final totalSales = erp.customers.fold(0.0, (s, c) => s + c.totalSales);
    final totalPaid = erp.customers.fold(0.0, (s, c) => s + c.paid);
    final debtorsCount = erp.customers.where((c) => c.currentBalance > 0).length;
    final collectionPct = (totalSales + erp.customers.fold(0.0, (s, c) => s + c.openingBalance)) > 0
        ? (totalPaid / (totalSales + erp.customers.fold(0.0, (s, c) => s + c.openingBalance))) * 100
        : 100.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // شريط العنوان وأزرار الإجراءات الرئيسية
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.people_alt, color: AppTheme.primaryGreen, size: 22),
                      ),
                      const Text(
                        'دليل العملاء وحسابات الذمم',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'بيانات العملاء، الحسابات الجارية، متابعة الذمم المدينة، وسندات القبض الفورية',
                    style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  ),
                ],
              ),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showQuickPaymentSelector(erp),
                    icon: const Icon(Icons.receipt_long, size: 18),
                    label: const Text('تسجيل سند قبض سريع'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accentGold,
                      side: const BorderSide(color: AppTheme.accentGold),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddCustomerDialog(),
                    icon: const Icon(Icons.person_add_rounded, size: 18),
                    label: const Text('إضافة عميل جديد'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // كروت إجمالية للعملاء والذمم (متجاوبة تماماً)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              final isMedium = constraints.maxWidth >= 600 && !isWide;

              if (isWide) {
                return Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'إجمالي الذمم المستحقة',
                        AppTheme.formatCurrency(totalReceivables, erp.settings.currency),
                        '$debtorsCount عميل عليهم مديونية',
                        Icons.account_balance_wallet_rounded,
                        AppTheme.accentGold,
                        badgeText: debtorsCount > 0 ? 'مستحق' : 'خالص',
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildSummaryCard(
                        'إجمالي مبيعات العملاء',
                        AppTheme.formatCurrency(totalSales, erp.settings.currency),
                        'فواتير وعروض معتمدة',
                        Icons.point_of_sale_rounded,
                        AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildSummaryCard(
                        'إجمالي التحصيلات والمسدد',
                        AppTheme.formatCurrency(totalPaid, erp.settings.currency),
                        'سندات قبض مسجلة',
                        Icons.payments_rounded,
                        const Color(0xFF0284C7),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildSummaryCard(
                        'نسبة التحصيل الكلية',
                        '${collectionPct.clamp(0, 100).toStringAsFixed(1)}%',
                        'من إجمالي المستحقات',
                        Icons.pie_chart_rounded,
                        const Color(0xFF16A34A),
                        isPercentage: true,
                        pctValue: (collectionPct / 100).clamp(0.0, 1.0),
                      ),
                    ),
                  ],
                );
              } else if (isMedium) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            'إجمالي الذمم المستحقة',
                            AppTheme.formatCurrency(totalReceivables, erp.settings.currency),
                            '$debtorsCount عميل عليهم مديونية',
                            Icons.account_balance_wallet_rounded,
                            AppTheme.accentGold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            'إجمالي مبيعات العملاء',
                            AppTheme.formatCurrency(totalSales, erp.settings.currency),
                            'فواتير وعروض معتمدة',
                            Icons.point_of_sale_rounded,
                            AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            'إجمالي التحصيلات والمسدد',
                            AppTheme.formatCurrency(totalPaid, erp.settings.currency),
                            'سندات قبض مسجلة',
                            Icons.payments_rounded,
                            const Color(0xFF0284C7),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            'نسبة التحصيل الكلية',
                            '${collectionPct.clamp(0, 100).toStringAsFixed(1)}%',
                            'من إجمالي المستحقات',
                            Icons.pie_chart_rounded,
                            const Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildSummaryCard(
                      'إجمالي الذمم المستحقة',
                      AppTheme.formatCurrency(totalReceivables, erp.settings.currency),
                      '$debtorsCount عميل عليهم مديونية',
                      Icons.account_balance_wallet_rounded,
                      AppTheme.accentGold,
                    ),
                    const SizedBox(height: 10),
                    _buildSummaryCard(
                      'إجمالي مبيعات العملاء',
                      AppTheme.formatCurrency(totalSales, erp.settings.currency),
                      'فواتير وعروض معتمدة',
                      Icons.point_of_sale_rounded,
                      AppTheme.primaryGreen,
                    ),
                    const SizedBox(height: 10),
                    _buildSummaryCard(
                      'إجمالي التحصيلات والمسدد',
                      AppTheme.formatCurrency(totalPaid, erp.settings.currency),
                      'سندات قبض مسجلة',
                      Icons.payments_rounded,
                      const Color(0xFF0284C7),
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 20),

          // شريط البحث والتصفية المتقدم
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 550;
                      final sortDropdown = Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _sortBy,
                            isExpanded: isCompact,
                            icon: const Icon(Icons.sort, size: 18),
                            items: const [
                              DropdownMenuItem(value: 'debt_desc', child: Text('أعلى مديونية أولاً')),
                              DropdownMenuItem(value: 'debt_asc', child: Text('أقل مديونية أولاً')),
                              DropdownMenuItem(value: 'name', child: Text('الاسم أبجدياً')),
                              DropdownMenuItem(value: 'code', child: Text('كود العميل')),
                              DropdownMenuItem(value: 'sales_desc', child: Text('الأعلى مبيعات')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _sortBy = val);
                            },
                          ),
                        ),
                      );

                      if (isCompact) {
                        return Column(
                          children: [
                            TextField(
                              decoration: InputDecoration(
                                hintText: 'بحث باسم العميل، الكود، الهاتف...',
                                prefixIcon: const Icon(Icons.search, size: 20),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () => setState(() => _searchQuery = ''),
                                      )
                                    : null,
                                isDense: true,
                              ),
                              onChanged: (val) => setState(() => _searchQuery = val),
                            ),
                            const SizedBox(height: 10),
                            sortDropdown,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'بحث باسم العميل، الكود، الهاتف، أو العنوان...',
                                prefixIcon: const Icon(Icons.search, size: 20),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () => setState(() => _searchQuery = ''),
                                      )
                                    : null,
                                isDense: true,
                              ),
                              onChanged: (val) => setState(() => _searchQuery = val),
                            ),
                          ),
                          const SizedBox(width: 14),
                          sortDropdown,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // فلاتر سريعة (Chips)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'تصفية حسب الحالة:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                      ),
                      _buildFilterChip('all', 'الكل (${erp.customers.length})', Icons.people_outline),
                      _buildFilterChip(
                        'debt',
                        'عليهم ذمم مستحقة ($debtorsCount)',
                        Icons.warning_amber_rounded,
                        activeColor: Colors.red.shade700,
                      ),
                      _buildFilterChip(
                        'settled',
                        'خالص ومسدد (${erp.customers.where((c) => c.currentBalance == 0).length})',
                        Icons.check_circle_outline,
                        activeColor: Colors.green.shade700,
                      ),
                      _buildFilterChip(
                        'credit',
                        'أرصدة دائنة (${erp.customers.where((c) => c.currentBalance < 0).length})',
                        Icons.arrow_circle_down_outlined,
                        activeColor: Colors.blue.shade700,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // جدول العملاء والذمم
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Text(
                        'قائمة العملاء (${filtered.length} عميل)',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                      ),
                      if (filtered.isNotEmpty)
                        Text(
                          'إجمالي الذمم المعروضة: ${AppTheme.formatCurrency(filtered.fold(0.0, (s, c) => s + c.currentBalance), erp.settings.currency)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: filtered.fold(0.0, (s, c) => s + c.currentBalance) > 0 ? Colors.red.shade700 : Colors.green.shade700,
                          ),
                        ),
                    ],
                  ),
                  const Divider(height: 24),
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.person_search_outlined, size: 48, color: AppTheme.textMuted.withOpacity(0.5)),
                            const SizedBox(height: 12),
                            const Text(
                              'لا يوجد عملاء مطابقين لمعايير البحث والتصفية',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                        horizontalMargin: 16,
                        columnSpacing: 20,
                        columns: const [
                          DataColumn(label: Text('كود العميل', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('اسم العميل / المنشأة', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('الهاتف', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('العنوان', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('الرصيد الافتتاحي', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('إجمالي المبيعات', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('المسدد', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('الرصيد الحالي (الذمة)', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('نسبة السداد', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: filtered.map((c) {
                          final totalOwed = c.openingBalance + c.totalSales;
                          final custPct = totalOwed > 0 ? (c.paid / totalOwed).clamp(0.0, 1.0) : 1.0;

                          return DataRow(
                            cells: [
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    c.code,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryGreen,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.business_outlined, size: 16, color: AppTheme.textMuted),
                                    const SizedBox(width: 6),
                                    Text(
                                      c.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(c.phone ?? '—'),
                                    if (c.phone != null && c.phone!.isNotEmpty) ...[
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(Icons.copy, size: 14, color: AppTheme.textMuted),
                                        tooltip: 'نسخ رقم الهاتف',
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(text: c.phone!));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('تم نسخ رقم الهاتف: ${c.phone}'),
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              DataCell(Text(c.address ?? '—', style: TextStyle(color: AppTheme.textMuted))),
                              DataCell(Text(AppTheme.formatCurrency(c.openingBalance))),
                              DataCell(Text(AppTheme.formatCurrency(c.totalSales))),
                              DataCell(
                                Text(
                                  AppTheme.formatCurrency(c.paid),
                                  style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w600),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: c.currentBalance > 0
                                        ? Colors.red.shade50
                                        : (c.currentBalance < 0 ? Colors.blue.shade50 : Colors.green.shade50),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: c.currentBalance > 0
                                          ? Colors.red.shade200
                                          : (c.currentBalance < 0 ? Colors.blue.shade200 : Colors.green.shade200),
                                    ),
                                  ),
                                  child: Text(
                                    AppTheme.formatCurrency(c.currentBalance),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: c.currentBalance > 0
                                          ? Colors.red.shade700
                                          : (c.currentBalance < 0 ? Colors.blue.shade700 : Colors.green.shade700),
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 80,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${(custPct * 100).toStringAsFixed(0)}%',
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 2),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: custPct,
                                          backgroundColor: Colors.grey.shade200,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            custPct >= 1.0 ? Colors.green : (custPct >= 0.5 ? Colors.amber : Colors.red),
                                          ),
                                          minHeight: 5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _showQuickPaymentDialog(c),
                                      icon: const Icon(Icons.receipt_long, size: 13),
                                      label: const Text('سند قبض', style: TextStyle(fontSize: 11)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.accentGold,
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(Icons.history_edu, size: 18, color: Color(0xFF0284C7)),
                                      tooltip: 'كشف حساب تفصيلي للعميل',
                                      onPressed: () => _showStatementDialog(c),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.darkSlate),
                                      tooltip: 'تعديل بيانات العميل',
                                      onPressed: () => _showEditCustomerDialog(c),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                      tooltip: 'حذف العميل',
                                      onPressed: () => _confirmDeleteCustomer(c),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color, {
    String? badgeText,
    bool isPercentage = false,
    double pctValue = 0.0,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color),
                      ),
                    ],
                  ),
                ),
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (isPercentage) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pctValue,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 5,
                ),
              ),
              const SizedBox(height: 6),
            ],
            Text(subtitle, style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String type, String label, IconData icon, {Color? activeColor}) {
    final isSelected = _filterType == type;
    final color = activeColor ?? AppTheme.primaryGreen;

    return InkWell(
      onTap: () => setState(() => _filterType = type),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppTheme.borderColor,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? color : AppTheme.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : AppTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCustomerDialog() {
    final erp = context.read<ErpProvider>();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final balanceCtrl = TextEditingController(text: '0');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
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
                          child: const Icon(Icons.person_add_rounded, color: AppTheme.primaryGreen, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'إضافة عميل جديد',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'تسجيل بيانات العميل أو المنشأة في قاعدة البيانات',
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

                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'اسم العميل / اسم المنشأة *',
                        prefixIcon: Icon(Icons.business_rounded, size: 18),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال اسم العميل' : null,
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'رقم الهاتف / الجوال',
                        prefixIcon: Icon(Icons.phone_rounded, size: 18),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: addrCtrl,
                      decoration: const InputDecoration(
                        labelText: 'العنوان / المدينة',
                        prefixIcon: Icon(Icons.location_on_rounded, size: 18),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: balanceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'الرصيد الافتتاحي (إن وجد)',
                        prefixIcon: Icon(Icons.account_balance_wallet_rounded, size: 18),
                        helperText: 'سجل رصيد المديونية السابقة إن كان العميل مديناً للمطبعة مسبقاً',
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
                              if (!formKey.currentState!.validate()) return;
                              final cust = Customer(
                                id: 'C_${DateTime.now().millisecondsSinceEpoch}',
                                code: erp.generateNextCustomerCode(),
                                name: nameCtrl.text.trim(),
                                phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                                address: addrCtrl.text.trim().isEmpty ? null : addrCtrl.text.trim(),
                                openingBalance: double.tryParse(balanceCtrl.text) ?? 0,
                              );
                              await erp.addCustomer(cust);
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('تمت إضافة العميل بنجاح: ${cust.name} (${cust.code})')),
                                );
                              }
                            },
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text('حفظ العميل'),
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

  void _showEditCustomerDialog(Customer customer) {
    final erp = context.read<ErpProvider>();
    final nameCtrl = TextEditingController(text: customer.name);
    final phoneCtrl = TextEditingController(text: customer.phone ?? '');
    final addrCtrl = TextEditingController(text: customer.address ?? '');
    final balanceCtrl = TextEditingController(text: customer.openingBalance.toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
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
                          child: const Icon(Icons.edit_note_rounded, color: AppTheme.primaryGreen, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تعديل بيانات العميل: ${customer.code}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                customer.name,
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

                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'اسم العميل / المنشأة *',
                        prefixIcon: Icon(Icons.business_rounded, size: 18),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال اسم العميل' : null,
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'رقم الهاتف',
                        prefixIcon: Icon(Icons.phone_rounded, size: 18),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: addrCtrl,
                      decoration: const InputDecoration(
                        labelText: 'العنوان',
                        prefixIcon: Icon(Icons.location_on_rounded, size: 18),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: balanceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'الرصيد الافتتاحي',
                        prefixIcon: Icon(Icons.account_balance_wallet_rounded, size: 18),
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
                              if (!formKey.currentState!.validate()) return;
                              final updatedCustomer = Customer(
                                id: customer.id,
                                code: customer.code,
                                name: nameCtrl.text.trim(),
                                phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                                address: addrCtrl.text.trim().isEmpty ? null : addrCtrl.text.trim(),
                                openingBalance: double.tryParse(balanceCtrl.text) ?? customer.openingBalance,
                                totalSales: customer.totalSales,
                                paid: customer.paid,
                              );

                              await erp.updateCustomer(updatedCustomer);
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('تم تحديث بيانات العميل: ${updatedCustomer.name}')),
                                );
                              }
                            },
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text('حفظ التعديلات'),
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

  void _confirmDeleteCustomer(Customer customer) {
    final erp = context.read<ErpProvider>();

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
                        'تأكيد حذف العميل',
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
                  'هل أنت متأكد من رغبتك في حذف العميل "${customer.name}" (${customer.code})؟',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                ),
                const SizedBox(height: 6),
                Text(
                  'سيتم حذف سجل العميل وكافة البيانات المرتبطة به. لا يمكن التراجع عن هذا الإجراء.',
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
                          final result = await erp.deleteCustomer(customer.id);
                          if (ctx.mounted && result.isSuccess) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result.message),
                                backgroundColor: result.isSuccess ? AppTheme.primaryGreen : Colors.red.shade700,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.delete_forever_rounded, size: 18),
                        label: const Text('حذف نهائي'),
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

  void _showQuickPaymentSelector(ErpProvider erp) {
    if (erp.customers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد عملاء مسجلون حالياً')),
      );
      return;
    }

    Customer selected = erp.customers.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('اختر العميل لتسجيل سند القبض'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Customer>(
                  value: selected,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'العميل'),
                  items: erp.customers.map((c) {
                    return DropdownMenuItem<Customer>(
                      value: c,
                      child: Text('${c.name} (${c.code}) - المستحق: ${AppTheme.formatCurrency(c.currentBalance)}', overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (c) {
                    if (c != null) setDialogState(() => selected = c);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showQuickPaymentDialog(selected);
              },
              child: const Text('متابعة لتسجيل السند'),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickPaymentDialog(Customer customer) {
    final erp = context.read<ErpProvider>();
    final amountCtrl = TextEditingController(text: '${customer.currentBalance > 0 ? customer.currentBalance.toInt() : 10000}');
    String method = 'نقدي';
    final refCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppTheme.accentGold.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.receipt_long, color: AppTheme.accentGold, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text('تسجيل سند قبض: ${customer.name}', overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: customer.currentBalance > 0 ? Colors.red.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: customer.currentBalance > 0 ? Colors.red.shade200 : Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('الرصيد المستحق حالياً (الذمة):', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        AppTheme.formatCurrency(customer.currentBalance, erp.settings.currency),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: customer.currentBalance > 0 ? Colors.red.shade800 : Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'المبلغ المقبوض (${erp.settings.currency}) *',
                    prefixIcon: const Icon(Icons.attach_money, size: 18),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: method,
                  decoration: const InputDecoration(
                    labelText: 'طريقة الدفع',
                    prefixIcon: Icon(Icons.payment, size: 18),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'نقدي', child: Text('نقدي (الصندوق الرئيسي)', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'تحويل بنكي', child: Text('تحويل بنكي / صرافة', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'شيك', child: Text('شيك بنكي', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'شبكة / بطاقة', child: Text('شبكة / بطاقة مدى', overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (m) => setDialogState(() => method = m ?? 'نقدي'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: refCtrl,
                  decoration: const InputDecoration(
                    labelText: 'المرجع / رقم الإيداع / رقم السند الورقي',
                    prefixIcon: Icon(Icons.confirmation_number_outlined, size: 18),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات وتفاصيل الدفعة',
                    prefixIcon: Icon(Icons.notes, size: 18),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGold),
              onPressed: () async {
                final amt = double.tryParse(amountCtrl.text) ?? 0;
                if (amt <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يرجى إدخال مبلغ صحيح')),
                  );
                  return;
                }
                final result = await erp.recordPayment(
                  customerId: customer.id,
                  amount: amt,
                  paymentMethod: method,
                  reference: refCtrl.text.trim().isEmpty ? null : refCtrl.text.trim(),
                  notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                );
                if (ctx.mounted && result.isSuccess) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result.message),
                      backgroundColor: result.isSuccess ? Colors.green.shade800 : Colors.red.shade700,
                    ),
                  );
                }
              },
              child: const Text('حفظ واعتماد السند'),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatementDialog(Customer customer) {
    final erp = context.read<ErpProvider>();
    final ledgerEntries = erp.ledgerForCustomer(customer.id);

    // دفتر القيود هو المصدر الوحيد لكشف الحساب، ويُظهر الاعتماد والإلغاء والسداد بوضوح.
    final List<StatementRow> statementRows = ledgerEntries.map((entry) {
      final typeLabel = switch (entry.type) {
        'opening_balance' => 'افتتاحي',
        'opening_adjustment' => 'تسوية افتتاحية',
        'sale' => 'عرض معتمد',
        'sale_reversal' => 'إلغاء اعتماد',
        'payment' => 'سند قبض',
        'legacy_sale' => 'مبيعات مرحّلة',
        'legacy_payment' => 'دفعة مرحّلة',
        _ => entry.type,
      };
      return StatementRow(
        date: entry.date,
        type: typeLabel,
        number: entry.referenceNumber ?? '—',
        description: entry.notes ?? typeLabel,
        debit: entry.debit,
        credit: entry.credit,
      );
    }).toList();

    // ترتيب السطور زمنياً
    statementRows.sort((a, b) => a.date.compareTo(b.date));

    // حساب الرصيد التراكمي بعد كل حركة
    double runningBalance = 0.0;
    for (final row in statementRows) {
      runningBalance += (row.debit - row.credit);
      row.runningBalance = runningBalance;
    }

    final totalDebit = statementRows.fold(0.0, (s, r) => s + r.debit);
    final totalCredit = statementRows.fold(0.0, (s, r) => s + r.credit);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.history_edu, color: Color(0xFF0284C7), size: 22),
                const SizedBox(width: 8),
                Text('كشف حساب ذمة: ${customer.name} (${customer.code})'),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.print_outlined),
              tooltip: 'طباعة كشف الحساب',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('جاري إرسال كشف الحساب للطابعة...')),
                );
              },
            ),
          ],
        ),
        content: SizedBox(
          width: 750,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // رأس بطاقة العميل
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('العميل: ${customer.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text('الهاتف: ${customer.phone ?? 'غير مسجل'} | العنوان: ${customer.address ?? 'غير مسجل'}',
                                style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: customer.currentBalance > 0 ? Colors.red.shade50 : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: customer.currentBalance > 0 ? Colors.red.shade200 : Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              customer.currentBalance > 0 ? 'الرصيد المستحق (مدين):' : 'الرصيد النهائي (خالص):',
                              style: TextStyle(fontSize: 11, color: customer.currentBalance > 0 ? Colors.red.shade700 : Colors.green.shade700),
                            ),
                            Text(
                              AppTheme.formatCurrency(customer.currentBalance, erp.settings.currency),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: customer.currentBalance > 0 ? Colors.red.shade700 : Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // جدول كشف الحساب التفصيلي
                const Text('سجل العمليات والحركات المحاسبية التراكمية:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),

                if (statementRows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('لا توجد أي حركات أو فواتير مسجلة لهذا العميل')),
                  )
                else
                  Table(
                    border: TableBorder.all(color: AppTheme.borderColor),
                    columnWidths: const {
                      0: FlexColumnWidth(1.2),
                      1: FlexColumnWidth(1.3),
                      2: FlexColumnWidth(2.5),
                      3: FlexColumnWidth(1.4),
                      4: FlexColumnWidth(1.4),
                      5: FlexColumnWidth(1.5),
                    },
                    children: [
                      TableRow(
                        decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
                        children: const [
                          Padding(padding: EdgeInsets.all(8), child: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          Padding(padding: EdgeInsets.all(8), child: Text('نوع الحركة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          Padding(padding: EdgeInsets.all(8), child: Text('البيان / الوصف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          Padding(padding: EdgeInsets.all(8), child: Text('مدين (+)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blue))),
                          Padding(padding: EdgeInsets.all(8), child: Text('دائن (-)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.green))),
                          Padding(padding: EdgeInsets.all(8), child: Text('الرصيد التراكمي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        ],
                      ),
                      ...statementRows.map((r) {
                        return TableRow(
                          children: [
                            Padding(padding: const EdgeInsets.all(8), child: Text(AppTheme.formatDate(r.date), style: const TextStyle(fontSize: 11))),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text('${r.type}\n${r.number}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                            ),
                            Padding(padding: const EdgeInsets.all(8), child: Text(r.description, style: const TextStyle(fontSize: 11))),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                r.debit > 0 ? AppTheme.formatCurrency(r.debit) : '—',
                                style: TextStyle(fontSize: 11, fontWeight: r.debit > 0 ? FontWeight.bold : FontWeight.normal),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                r.credit > 0 ? AppTheme.formatCurrency(r.credit) : '—',
                                style: TextStyle(fontSize: 11, fontWeight: r.credit > 0 ? FontWeight.bold : FontWeight.normal, color: Colors.green.shade800),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                AppTheme.formatCurrency(r.runningBalance),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: r.runningBalance > 0 ? Colors.red.shade700 : Colors.green.shade700,
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                      // سطر الإجماليات
                      TableRow(
                        decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                        children: [
                          const Padding(padding: EdgeInsets.all(8), child: Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          const Padding(padding: EdgeInsets.all(8), child: Text('—')),
                          const Padding(padding: EdgeInsets.all(8), child: Text('صافي المطابقات')),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(AppTheme.formatCurrency(totalDebit), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blue)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(AppTheme.formatCurrency(totalCredit), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.green.shade800)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              AppTheme.formatCurrency(customer.currentBalance),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: customer.currentBalance > 0 ? Colors.red.shade700 : Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _showQuickPaymentDialog(customer);
            },
            icon: const Icon(Icons.receipt_long, size: 16),
            label: const Text('سند قبض لهذا العميل'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}

class StatementRow {
  final DateTime date;
  final String type;
  final String number;
  final String description;
  final double debit;
  final double credit;
  double runningBalance;

  StatementRow({
    required this.date,
    required this.type,
    required this.number,
    required this.description,
    required this.debit,
    required this.credit,
    this.runningBalance = 0.0,
  });
}
