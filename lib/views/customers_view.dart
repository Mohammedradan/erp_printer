import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../providers/erp_provider.dart';
import '../theme/app_theme.dart';
import '../services/pdf_export_service.dart';
import '../widgets/erp_components.dart';

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
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ErpPageHeader(
            title: 'العملاء وحسابات الذمم',
            subtitle: 'ملفات العملاء، الأرصدة المستحقة، الحركات المالية وسندات القبض',
            icon: Icons.people_alt_outlined,
            actions: [
              OutlinedButton.icon(
                onPressed: () => _showQuickPaymentSelector(erp),
                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                label: const Text('سند قبض سريع'),
              ),
              ElevatedButton.icon(
                onPressed: _showAddCustomerDialog,
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('إضافة عميل'),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // كروت إجمالية للعملاء والذمم (متجاوبة تماماً بنظام 2x2 على الجوال)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 950;
              final isMobile = constraints.maxWidth < 650;
              final crossAxisCount = isWide ? 4 : 2;
              final aspect = constraints.maxWidth > 1200
                  ? 1.9
                  : (constraints.maxWidth > 950
                      ? 1.6
                      : (isMobile ? 1.38 : 1.75));

              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: isMobile ? 10 : 14,
                mainAxisSpacing: isMobile ? 10 : 14,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: aspect,
                children: [
                  _buildSummaryCard(
                    'إجمالي الذمم المستحقة',
                    AppTheme.formatCurrency(totalReceivables, erp.settings.currency),
                    '$debtorsCount عميل مدين',
                    Icons.account_balance_wallet_rounded,
                    AppTheme.accentGold,
                    badgeText: debtorsCount > 0 ? 'مستحق' : 'خالص',
                    isCompact: isMobile,
                  ),
                  _buildSummaryCard(
                    'إجمالي مبيعات العملاء',
                    AppTheme.formatCurrency(totalSales, erp.settings.currency),
                    'فواتير وعروض معتمدة',
                    Icons.point_of_sale_rounded,
                    AppTheme.primaryGreen,
                    isCompact: isMobile,
                  ),
                  _buildSummaryCard(
                    'إجمالي التحصيلات والمسدد',
                    AppTheme.formatCurrency(totalPaid, erp.settings.currency),
                    'سندات قبض مسجلة',
                    Icons.payments_rounded,
                    AppTheme.info,
                    isCompact: isMobile,
                  ),
                  _buildSummaryCard(
                    'نسبة التحصيل الكلية',
                    '${collectionPct.clamp(0, 100).toStringAsFixed(1)}%',
                    'من إجمالي المستحقات',
                    Icons.pie_chart_rounded,
                    AppTheme.success,
                    isPercentage: true,
                    pctValue: (collectionPct / 100).clamp(0.0, 1.0),
                    isCompact: isMobile,
                  ),
                ],
              );
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
                          color: AppTheme.surfaceSecondary,
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
                        activeColor: AppTheme.dangerButton,
                      ),
                      _buildFilterChip(
                        'settled',
                        'خالص ومسدد (${erp.customers.where((c) => c.currentBalance == 0).length})',
                        Icons.check_circle_outline,
                        activeColor: AppTheme.success,
                      ),
                      _buildFilterChip(
                        'credit',
                        'أرصدة دائنة (${erp.customers.where((c) => c.currentBalance < 0).length})',
                        Icons.arrow_circle_down_outlined,
                        activeColor: AppTheme.info,
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
                            color: filtered.fold(0.0, (s, c) => s + c.currentBalance) > 0 ? AppTheme.dangerButton : AppTheme.success,
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
                  else if (MediaQuery.of(context).size.width < 750)
                    _buildMobileCustomerCards(filtered, erp)
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(AppTheme.surfaceSecondary),
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
                                    color: AppTheme.primaryLight.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    c.code,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryLight,
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
                              DataCell(Text(AppTheme.formatCurrency(c.openingBalance, context.read<ErpProvider>().settings.currency))),
                              DataCell(Text(AppTheme.formatCurrency(c.totalSales, context.read<ErpProvider>().settings.currency))),
                              DataCell(
                                Text(
                                  AppTheme.formatCurrency(c.paid, context.read<ErpProvider>().settings.currency),
                                  style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.w600),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: c.currentBalance > 0
                                        ? AppTheme.dangerSurface
                                        : (c.currentBalance < 0 ? AppTheme.infoSurface : AppTheme.successSurface),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: c.currentBalance > 0
                                          ? AppTheme.danger.withValues(alpha: 0.36)
                                          : (c.currentBalance < 0 ? AppTheme.info.withValues(alpha: 0.36) : AppTheme.success.withValues(alpha: 0.36)),
                                    ),
                                  ),
                                  child: Text(
                                    AppTheme.formatCurrency(c.currentBalance, context.read<ErpProvider>().settings.currency),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: c.currentBalance > 0
                                          ? AppTheme.dangerButton
                                          : (c.currentBalance < 0 ? AppTheme.info : AppTheme.success),
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
                                          backgroundColor: AppTheme.surfaceSecondary,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            custPct >= 1.0 ? AppTheme.success : (custPct >= 0.5 ? AppTheme.warning : AppTheme.danger),
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
                                      icon: const Icon(Icons.history_edu, size: 18, color: AppTheme.info),
                                      tooltip: 'كشف حساب تفصيلي للعميل',
                                      onPressed: () => _showStatementDialog(c),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.darkSlate),
                                      tooltip: 'تعديل بيانات العميل',
                                      onPressed: () => _showEditCustomerDialog(c),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.danger),
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

  Widget _buildMobileCustomerCards(List<Customer> filtered, ErpProvider erp) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final c = filtered[index];
        final totalOwed = c.openingBalance + c.totalSales;
        final custPct = totalOwed > 0 ? (c.paid / totalOwed).clamp(0.0, 1.0) : 1.0;
        final hasDebt = c.currentBalance > 0;
        final isCredit = c.currentBalance < 0;

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasDebt
                  ? AppTheme.danger.withValues(alpha: 0.25)
                  : AppTheme.borderColor,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الصف العلوي: كود العميل وبادج الرصيد
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      c.code,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryLight,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: hasDebt
                            ? AppTheme.dangerSurface
                            : (isCredit ? AppTheme.infoSurface : AppTheme.successSurface),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: hasDebt
                              ? AppTheme.danger.withValues(alpha: 0.36)
                              : (isCredit ? AppTheme.info.withValues(alpha: 0.36) : AppTheme.success.withValues(alpha: 0.36)),
                        ),
                      ),
                      child: Text(
                        hasDebt
                            ? 'مستحق: ${AppTheme.formatCurrency(c.currentBalance, context.read<ErpProvider>().settings.currency)}'
                            : (isCredit
                                ? 'دائن: ${AppTheme.formatCurrency(c.currentBalance.abs(), context.read<ErpProvider>().settings.currency)}'
                                : 'خالص'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: hasDebt
                              ? AppTheme.dangerButton
                              : (isCredit ? AppTheme.info : AppTheme.success),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // اسم العميل
              Text(
                c.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                  color: AppTheme.textDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (c.phone != null && c.phone!.isNotEmpty) ...[
                const SizedBox(height: 5),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: c.phone!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم نسخ رقم الهاتف: ${c.phone}'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.phone_outlined, size: 13, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        c.phone!,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.copy, size: 12, color: AppTheme.textMuted),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppTheme.surfaceSecondary),
              const SizedBox(height: 10),

              // صندوق المبالغ المالية ونسبة السداد
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSecondary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildMobileMetricCol('المبيعات', AppTheme.formatCurrency(c.totalSales, context.read<ErpProvider>().settings.currency), AppTheme.darkSlate),
                        _buildMobileMetricCol('المسدد', AppTheme.formatCurrency(c.paid, context.read<ErpProvider>().settings.currency), AppTheme.success, isBold: true),
                        _buildMobileMetricCol(
                          'المتبقي',
                          AppTheme.formatCurrency(c.currentBalance, context.read<ErpProvider>().settings.currency),
                          hasDebt ? AppTheme.dangerButton : AppTheme.success,
                          isBold: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'السداد: ${(custPct * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: custPct,
                              backgroundColor: AppTheme.surfaceSecondary,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                custPct >= 1.0 ? AppTheme.success : (custPct >= 0.5 ? AppTheme.warning : AppTheme.danger),
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // أزرار الإجراءات
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showQuickPaymentDialog(c),
                    icon: const Icon(Icons.receipt_long, size: 14),
                    label: const Text('سند قبض', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showStatementDialog(c),
                    icon: const Icon(Icons.history_edu, size: 14, color: AppTheme.info),
                    label: const Text('كشف حساب', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      side: const BorderSide(color: AppTheme.borderColor),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showEditCustomerDialog(c),
                    icon: const Icon(Icons.edit_outlined, size: 14, color: AppTheme.darkSlate),
                    label: const Text('تعديل', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      side: const BorderSide(color: AppTheme.borderColor),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.danger),
                    tooltip: 'حذف العميل',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _confirmDeleteCustomer(c),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileMetricCol(String label, String value, Color valueColor, {bool isBold = false}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: valueColor,
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
    bool isCompact = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 10 : 14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
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
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: isCompact ? 18 : 22),
              ),
              if (badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(fontSize: isCompact ? 9.5 : 11, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: isCompact ? 11 : 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    value,
                    style: TextStyle(fontSize: isCompact ? 15 : 18, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
                const SizedBox(height: 2),
                if (isPercentage) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pctValue,
                      backgroundColor: AppTheme.surfaceSecondary,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  subtitle,
                  style: TextStyle(fontSize: isCompact ? 10 : 11, color: AppTheme.textMuted),
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
        backgroundColor: AppTheme.cardBg,
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
                            color: AppTheme.primaryLight.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.person_add_rounded, color: AppTheme.primaryLight, size: 24),
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
        backgroundColor: AppTheme.cardBg,
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
                            color: AppTheme.primaryLight.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.edit_note_rounded, color: AppTheme.primaryLight, size: 24),
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
        backgroundColor: AppTheme.cardBg,
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
                        color: AppTheme.danger.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 24),
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
                                backgroundColor: result.isSuccess ? AppTheme.primaryGreen : AppTheme.dangerButton,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.delete_forever_rounded, size: 18),
                        label: const Text('حذف نهائي'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.dangerButton,
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
                      child: Text('${c.name} (${c.code}) - المستحق: ${AppTheme.formatCurrency(c.currentBalance, context.read<ErpProvider>().settings.currency)}', overflow: TextOverflow.ellipsis),
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
                    color: customer.currentBalance > 0 ? AppTheme.dangerSurface : AppTheme.successSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: customer.currentBalance > 0 ? AppTheme.danger.withValues(alpha: 0.36) : AppTheme.success.withValues(alpha: 0.36)),
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
                          color: customer.currentBalance > 0 ? AppTheme.danger : AppTheme.success,
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
                      backgroundColor: result.isSuccess ? AppTheme.success : AppTheme.dangerButton,
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

  Future<void> _printCustomerStatement(
    Customer customer,
    ErpProvider erp,
    List<StatementRow> statementRows,
  ) async {
    try {
      await PdfExportService.printOrPreviewCustomerStatement(
        context,
        settings: erp.settings,
        customerName: customer.name,
        customerCode: customer.code,
        phone: customer.phone,
        address: customer.address,
        currentBalance: customer.currentBalance,
        rows: statementRows
            .map((row) => CustomerStatementPdfRow(
                  date: row.date,
                  type: row.type,
                  number: row.number,
                  description: row.description,
                  debit: row.debit,
                  credit: row.credit,
                  runningBalance: row.runningBalance,
                ))
            .toList(),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذرت معاينة كشف الحساب: $error'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
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
                const Icon(Icons.history_edu, color: AppTheme.info, size: 22),
                const SizedBox(width: 8),
                Text('كشف حساب ذمة: ${customer.name} (${customer.code})'),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.print_outlined),
              tooltip: 'طباعة كشف الحساب',
              onPressed: () => _printCustomerStatement(customer, erp, statementRows),
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
                    color: AppTheme.surfaceSecondary,
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
                          color: customer.currentBalance > 0 ? AppTheme.dangerSurface : AppTheme.successSurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: customer.currentBalance > 0 ? AppTheme.danger.withValues(alpha: 0.36) : AppTheme.success.withValues(alpha: 0.36)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              customer.currentBalance > 0 ? 'الرصيد المستحق (مدين):' : 'الرصيد النهائي (خالص):',
                              style: TextStyle(fontSize: 11, color: customer.currentBalance > 0 ? AppTheme.dangerButton : AppTheme.success),
                            ),
                            Text(
                              AppTheme.formatCurrency(customer.currentBalance, erp.settings.currency),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: customer.currentBalance > 0 ? AppTheme.dangerButton : AppTheme.success,
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
                        decoration: const BoxDecoration(color: AppTheme.surfaceSecondary),
                        children: const [
                          Padding(padding: EdgeInsets.all(8), child: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          Padding(padding: EdgeInsets.all(8), child: Text('نوع الحركة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          Padding(padding: EdgeInsets.all(8), child: Text('البيان / الوصف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          Padding(padding: EdgeInsets.all(8), child: Text('مدين (+)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.info))),
                          Padding(padding: EdgeInsets.all(8), child: Text('دائن (-)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.success))),
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
                                r.debit > 0 ? AppTheme.formatCurrency(r.debit, context.read<ErpProvider>().settings.currency) : '—',
                                style: TextStyle(fontSize: 11, fontWeight: r.debit > 0 ? FontWeight.bold : FontWeight.normal),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                r.credit > 0 ? AppTheme.formatCurrency(r.credit, context.read<ErpProvider>().settings.currency) : '—',
                                style: TextStyle(fontSize: 11, fontWeight: r.credit > 0 ? FontWeight.bold : FontWeight.normal, color: AppTheme.success),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                AppTheme.formatCurrency(r.runningBalance, context.read<ErpProvider>().settings.currency),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: r.runningBalance > 0 ? AppTheme.dangerButton : AppTheme.success,
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                      // سطر الإجماليات
                      TableRow(
                        decoration: const BoxDecoration(color: AppTheme.surfaceSecondary),
                        children: [
                          const Padding(padding: EdgeInsets.all(8), child: Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          const Padding(padding: EdgeInsets.all(8), child: Text('—')),
                          const Padding(padding: EdgeInsets.all(8), child: Text('صافي المطابقات')),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(AppTheme.formatCurrency(totalDebit, context.read<ErpProvider>().settings.currency), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.info)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(AppTheme.formatCurrency(totalCredit, context.read<ErpProvider>().settings.currency), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.success)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              AppTheme.formatCurrency(customer.currentBalance, context.read<ErpProvider>().settings.currency),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: customer.currentBalance > 0 ? AppTheme.dangerButton : AppTheme.success,
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
