import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../providers/erp_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../services/pdf_export_service.dart';

class QuotationsView extends StatefulWidget {
  final Function(int)? onNavigate;

  const QuotationsView({super.key, this.onNavigate});

  @override
  State<QuotationsView> createState() => _QuotationsViewState();
}

class _QuotationsViewState extends State<QuotationsView> {
  String _filterStatus = 'الكل';
  String _searchQuery = '';
  String _sortBy = 'date_desc'; // date_desc, date_asc, amount_desc, profit_desc
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final erp = context.watch<ErpProvider>();
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    var filtered = erp.quotations.where((q) {
      final matchesStatus = _filterStatus == 'الكل' || q.status == _filterStatus;
      final query = _searchQuery.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          q.number.toLowerCase().contains(query) ||
          q.customerName.toLowerCase().contains(query) ||
          q.product.toLowerCase().contains(query) ||
          q.paper.toLowerCase().contains(query);
      return matchesStatus && matchesSearch;
    }).toList();

    // فرز النتائج
    final effectiveSortBy = !isAdmin && _sortBy == 'profit_desc' ? 'date_desc' : _sortBy;
    switch (effectiveSortBy) {
      case 'date_asc':
        filtered.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'amount_desc':
        filtered.sort((a, b) => b.quoteAmount.compareTo(a.quoteAmount));
        break;
      case 'profit_desc':
        filtered.sort((a, b) => b.profit.compareTo(a.profit));
        break;
      case 'date_desc':
      default:
        filtered.sort((a, b) => b.date.compareTo(a.date));
        break;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. ترويسة تنفيذية فخمة (Executive Hero Header)
          _buildHeroHeader(erp),
          const SizedBox(height: 18),

          // 2. كروت المؤشرات الإحصائية المتقدمة (KPI Grid)
          _buildMetricsGrid(erp, isAdmin),
          const SizedBox(height: 18),

          // 3. شريط الفلاتر والبحث والترتيب المتقدم
          _buildFilterBar(erp, isAdmin),
          const SizedBox(height: 16),

          // 4. جدول / بطاقات عروض الأسعار المتجاوبة
          _buildQuotationsContent(filtered, erp, isAdmin),
        ],
      ),
    );
  }

  // --- ترويسة تنفيذية فخمة (Executive Hero Header) ---
  Widget _buildHeroHeader(ErpProvider erp) {
    final approvedCount = erp.approvedQuotationsCount;
    final pendingCount = erp.quotations.where((q) => q.status == 'مسودة' || q.status == 'مرسل').length;

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
                          child: Icon(Icons.request_quote_rounded, color: Colors.white, size: isMobile ? 22 : 26),
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
                                  'المبيعات والتسعير • ERP المطبعة',
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
                                'أرشيف وإدارة عروض الأسعار',
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
                                  'إدارة ومتابعة عروض الأسعار، حساب الهوامش والربحية، وتحويل العروض المعتمدة لأوامر إنتاج فورية',
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

                    // إحصاءات فورية وزر محرك التسعير
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
                              icon: Icons.receipt_long_rounded,
                              label: '${erp.quotations.length} عرض',
                              color: const Color(0xFFD1FAE5),
                              bgColor: Colors.black.withValues(alpha: 0.22),
                            ),
                            _buildHeroPill(
                              icon: Icons.verified_rounded,
                              label: '$approvedCount معتمد',
                              color: const Color(0xFFBAE6FD),
                              bgColor: Colors.black.withValues(alpha: 0.22),
                            ),
                            if (pendingCount > 0)
                              _buildHeroPill(
                                icon: Icons.hourglass_top_rounded,
                                label: '$pendingCount قيد المتابعة',
                                color: const Color(0xFFFDE68A),
                                bgColor: Colors.black.withValues(alpha: 0.24),
                              ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            if (widget.onNavigate != null) {
                              widget.onNavigate!(1); // محرك التسعير الحي
                            }
                          },
                          icon: const Icon(Icons.calculate_rounded, size: 16),
                          label: Text(
                            isMobile ? 'تسعير جديد' : 'تسعير وإنشاء عرض جديد',
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

  // --- كروت المؤشرات الإحصائية المتقدمة (KPI Grid) ---
  Widget _buildMetricsGrid(ErpProvider erp, bool isAdmin) {
    final approvedProfit = isAdmin ? erp.quotations
        .where((q) => q.status == 'معتمد')
        .fold<double>(0, (sum, q) => sum + q.profit) : 0.0;
    final winRate = erp.quotations.isNotEmpty
        ? (erp.approvedQuotationsCount / erp.quotations.length * 100)
        : 0.0;
    final pendingCount = erp.quotations
        .where((q) => q.status == 'مسودة' || q.status == 'مرسل')
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;
        final crossAxisCount = constraints.maxWidth > 1050 ? (isAdmin ? 4 : 3) : 2;
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
              title: 'المبيعات المعتمدة',
              value: AppTheme.formatCurrency(erp.totalApprovedSales, erp.settings.currency),
              subtitle: '${erp.approvedQuotationsCount} أمر معتمد',
              icon: Icons.verified_rounded,
              color: AppTheme.primaryGreen,
              bgColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
              onTap: () => setState(() => _filterStatus = 'معتمد'),
              isCompact: isMobile,
            ),
            _buildMetricCard(
              title: 'معدل قبول العروض',
              value: '${winRate.toStringAsFixed(1)}%',
              subtitle: '${erp.approvedQuotationsCount} من ${erp.quotations.length} عرض',
              icon: Icons.pie_chart_rounded,
              color: const Color(0xFF0284C7),
              bgColor: const Color(0xFFE0F2FE),
              onTap: null,
              isCompact: isMobile,
            ),
            if (isAdmin)
              _buildMetricCard(
                title: 'صافي أرباح العروض',
                value: AppTheme.formatCurrency(approvedProfit, erp.settings.currency),
                subtitle: 'العائد المتوقع للتسليم',
                icon: Icons.trending_up_rounded,
                color: const Color(0xFF7C3AED),
                bgColor: const Color(0xFFEDE9FE),
                onTap: null,
                isCompact: isMobile,
              ),
            _buildMetricCard(
              title: 'عروض قيد المتابعة',
              value: '$pendingCount عرض',
              subtitle: pendingCount == 0 ? 'تم الرد على كافة العروض' : 'مسودة أو مرسلة للعميل',
              icon: Icons.hourglass_top_rounded,
              color: pendingCount > 0 ? const Color(0xFFD97706) : const Color(0xFF16A34A),
              bgColor: pendingCount > 0 ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
              badge: pendingCount > 0 && !isMobile
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF59E0B)),
                      ),
                      child: const Text(
                        'متابعة مطلوبة',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                      ),
                    )
                  : null,
              onTap: () => setState(() => _filterStatus = 'مرسل'),
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
    Widget? badge,
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
                  if (badge != null)
                    badge
                  else
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
                          fontSize: isCompact ? 15 : 19,
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

  // --- شريط الفلاتر والبحث والترتيب المتقدم ---
  Widget _buildFilterBar(ErpProvider erp, bool isAdmin) {
    final allCount = erp.quotations.length;
    final draftCount = erp.quotations.where((q) => q.status == 'مسودة').length;
    final sentCount = erp.quotations.where((q) => q.status == 'مرسل').length;
    final approvedCount = erp.quotations.where((q) => q.status == 'معتمد').length;
    final rejectedCount = erp.quotations.where((q) => q.status == 'مرفوض').length;
    final cancelledCount = erp.quotations.where((q) => q.status == 'ملغي').length;

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
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 620;
              if (isCompact) {
                return Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'بحث برقم العرض، اسم العميل، أو المنتج...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.textMuted),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
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
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.sort_rounded, size: 18, color: AppTheme.textMuted),
                        const SizedBox(width: 8),
                        const Text('الترتيب:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.borderColor),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: !isAdmin && _sortBy == 'profit_desc' ? 'date_desc' : _sortBy,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                                items: [
                                  const DropdownMenuItem(value: 'date_desc', child: Text('الأحدث تاريخاً')),
                                  const DropdownMenuItem(value: 'date_asc', child: Text('الأقدم تاريخاً')),
                                  const DropdownMenuItem(value: 'amount_desc', child: Text('الأعلى قيمة')),
                                  if (isAdmin)
                                    const DropdownMenuItem(value: 'profit_desc', child: Text('الأعلى ربحية')),
                                ],
                                onChanged: (val) => setState(() => _sortBy = val ?? 'date_desc'),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'بحث برقم العرض، اسم العميل، أو المنتج المطلوب...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.textMuted),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
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
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sort_rounded, size: 18, color: AppTheme.textMuted),
                        const SizedBox(width: 8),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: !isAdmin && _sortBy == 'profit_desc' ? 'date_desc' : _sortBy,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                            items: [
                              const DropdownMenuItem(value: 'date_desc', child: Text('الأحدث تاريخاً')),
                              const DropdownMenuItem(value: 'date_asc', child: Text('الأقدم تاريخاً')),
                              const DropdownMenuItem(value: 'amount_desc', child: Text('الأعلى قيمة')),
                              if (isAdmin)
                                const DropdownMenuItem(value: 'profit_desc', child: Text('الأعلى ربحية')),
                            ],
                            onChanged: (val) => setState(() => _sortBy = val ?? 'date_desc'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // رقائق تصفية الحالات مع العدادات
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusFilterChip('الكل', allCount, Icons.grid_view_rounded),
                const SizedBox(width: 8),
                _buildStatusFilterChip('مسودة', draftCount, Icons.edit_note_rounded),
                const SizedBox(width: 8),
                _buildStatusFilterChip('مرسل', sentCount, Icons.send_rounded),
                const SizedBox(width: 8),
                _buildStatusFilterChip('معتمد', approvedCount, Icons.check_circle_rounded),
                const SizedBox(width: 8),
                _buildStatusFilterChip('مرفوض', rejectedCount, Icons.cancel_rounded),
                const SizedBox(width: 8),
                _buildStatusFilterChip('ملغي', cancelledCount, Icons.block_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChip(String label, int count, IconData icon) {
    final isSelected = _filterStatus == label;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _filterStatus = label),
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
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : AppTheme.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
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
    );
  }

  // --- محتوى عروض الأسعار المتجاوب (Table vs Cards) ---
  Widget _buildQuotationsContent(List<Quotation> filtered, ErpProvider erp, bool isAdmin) {
    if (filtered.isEmpty) {
      return _buildEmptyState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 750) {
          return _buildMobileQuotationCards(filtered, erp, isAdmin);
        } else {
          return _buildDesktopQuotationTable(filtered, erp, isAdmin);
        }
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded, size: 40, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 14),
          const Text(
            'لا توجد عروض أسعار مطابقة للبحث',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
          ),
          const SizedBox(height: 6),
          const Text(
            'يمكنك تغيير كلمات البحث أو الفلاتر، أو إنشاء عرض سعر جديد عبر محرك التسعير',
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchQuery.isNotEmpty || _filterStatus != 'الكل')
                OutlinedButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _filterStatus = 'الكل';
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('إعادة ضبط الفلاتر'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.borderColor),
                  ),
                ),
              if (widget.onNavigate != null) ...[
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => widget.onNavigate!(1),
                  icon: const Icon(Icons.calculate_rounded, size: 16),
                  label: const Text('محرك التسعير'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // جدول سطح المكتب الفخم
  Widget _buildDesktopQuotationTable(List<Quotation> filtered, ErpProvider erp, bool isAdmin) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // رأس الجدول
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.table_rows_rounded, size: 18, color: AppTheme.primaryGreen),
                    const SizedBox(width: 8),
                    const Text(
                      'سجل عروض الأسعار المسجلة',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppTheme.darkSlate),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${filtered.length} عرض',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderColor),

          // الجدول التفاعلي أو بطاقات الجوال
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('لا توجد عروض أسعار مسجلة'),
              ),
            )
          else if (MediaQuery.of(context).size.width < 750)
            _buildMobileQuotationCards(filtered, erp, isAdmin)
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              columnSpacing: 20,
              dataRowMinHeight: 52,
              dataRowMaxHeight: 56,
              columns: [
                const DataColumn(label: Text('رقم العرض', style: TextStyle(fontWeight: FontWeight.bold))),
                const DataColumn(label: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold))),
                const DataColumn(label: Text('العميل', style: TextStyle(fontWeight: FontWeight.bold))),
                const DataColumn(label: Text('المنتج', style: TextStyle(fontWeight: FontWeight.bold))),
                const DataColumn(label: Text('الكمية', style: TextStyle(fontWeight: FontWeight.bold))),
                const DataColumn(label: Text('الورق والماكينة', style: TextStyle(fontWeight: FontWeight.bold))),
                const DataColumn(label: Text('سعر الوحدة', style: TextStyle(fontWeight: FontWeight.bold))),
                if (isAdmin)
                  const DataColumn(label: Text('التكلفة الكلية', style: TextStyle(fontWeight: FontWeight.bold))),
                const DataColumn(label: Text('قيمة العرض', style: TextStyle(fontWeight: FontWeight.bold))),
                if (isAdmin)
                  const DataColumn(label: Text('الربح المتوقع', style: TextStyle(fontWeight: FontWeight.bold))),
                const DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
                const DataColumn(label: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: filtered.map((q) {
                return DataRow(cells: [
                  DataCell(Text(
                    q.number,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                  )),
                  DataCell(Text(AppTheme.formatDate(q.date))),
                  DataCell(Text(q.customerName, style: const TextStyle(fontWeight: FontWeight.w600))),
                  DataCell(Text(q.product)),
                  DataCell(Text('${q.qty}')),
                  DataCell(Text('${q.paper} / ${q.machine}')),
                  DataCell(Text(AppTheme.formatCurrency(q.unitPrice, erp.settings.currency))),
                  if (isAdmin)
                    DataCell(Text(AppTheme.formatCurrency(q.totalCost, erp.settings.currency))),
                  DataCell(Text(
                    AppTheme.formatCurrency(q.quoteAmount, erp.settings.currency),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                  )),
                  if (isAdmin)
                    DataCell(Text(
                      AppTheme.formatCurrency(q.profit, erp.settings.currency),
                      style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold),
                    )),
                  DataCell(AppTheme.statusBadge(q.status)),
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility_outlined, size: 18, color: Colors.blue),
                        tooltip: 'عرض التفاصيل',
                        onPressed: () => _showQuoteDetails(q),
                      ),
                      IconButton(
                        icon: const Icon(Icons.picture_as_pdf_outlined, size: 18, color: AppTheme.primaryGreen),
                        tooltip: 'معاينة وطباعة PDF',
                        onPressed: () => PdfExportService.printOrPreviewQuotation(
                          context,
                          quotation: q,
                          settings: erp.settings,
                        ),
                      ),
                      if (q.status == 'مسودة' || q.status == 'مرسل')
                        IconButton(
                          icon: const Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
                          tooltip: 'اعتماد العرض وتوليد أمر إنتاج',
                          onPressed: () => _handleStatusChange(q.id, 'معتمد', erp),
                        ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 18),
                        onSelected: (val) => _handleStatusChange(q.id, val, erp),
                        itemBuilder: (ctx) => _buildStatusMenuItems(q.status),
                      ),
                    ],
                  )),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // بطاقات الجوال للشاشات الصغيرة
  Widget _buildMobileQuotationCards(List<Quotation> filtered, ErpProvider erp, bool isAdmin) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final q = filtered[index];
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
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الصف العلوي: رقم العرض، التاريخ، وبادج الحالة
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.request_quote_rounded, size: 16, color: AppTheme.primaryGreen),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                q.number,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.primaryGreen),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 1),
                              Text(
                                AppTheme.formatDate(q.date),
                                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppTheme.statusBadge(q.status),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 10),

              // اسم العميل والمنتج
              Row(
                children: [
                  const Icon(Icons.person_outline_rounded, size: 16, color: AppTheme.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      q.customerName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.darkSlate),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 16, color: AppTheme.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${q.product} • ${q.qty} نسخة',
                      style: const TextStyle(fontSize: 12.5, color: AppTheme.darkSlate),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(right: 22),
                child: Text(
                  '${q.paper} / ${q.machine}',
                  style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 10),

              // صندوق المبالغ المالية
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  children: [
                    _buildMobileMetricCol('سعر الوحدة', AppTheme.formatCurrency(q.unitPrice, erp.settings.currency), AppTheme.darkSlate),
                    _buildMobileMetricCol('قيمة العرض', AppTheme.formatCurrency(q.quoteAmount, erp.settings.currency), AppTheme.primaryGreen, isBold: true),
                    if (isAdmin)
                      _buildMobileMetricCol('الربح المتوقع', AppTheme.formatCurrency(q.profit, erp.settings.currency), const Color(0xFF059669), isBold: true),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // أزرار الإجراءات
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showQuoteDetails(q),
                    icon: const Icon(Icons.visibility_outlined, size: 14),
                    label: const Text('التفاصيل', style: TextStyle(fontSize: 11.5)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      side: const BorderSide(color: AppTheme.borderColor),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => PdfExportService.printOrPreviewQuotation(
                      context,
                      quotation: q,
                      settings: erp.settings,
                    ),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 14, color: AppTheme.primaryGreen),
                    label: const Text('PDF', style: TextStyle(fontSize: 11.5)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      side: const BorderSide(color: AppTheme.borderColor),
                    ),
                  ),
                  if (q.status == 'مسودة' || q.status == 'مرسل')
                    ElevatedButton.icon(
                      onPressed: () => _handleStatusChange(q.id, 'معتمد', erp),
                      icon: const Icon(Icons.check_circle_outline, size: 14),
                      label: const Text('اعتماد', style: TextStyle(fontSize: 11.5)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                    ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18, color: AppTheme.textMuted),
                    onSelected: (val) => _handleStatusChange(q.id, val, erp),
                    itemBuilder: (ctx) => _buildStatusMenuItems(q.status),
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

  List<PopupMenuEntry<String>> _buildStatusMenuItems(String status) {
    switch (status) {
      case 'مسودة':
        return const [
          PopupMenuItem(value: 'مرسل', child: Text('إرسال العرض')),
          PopupMenuItem(value: 'معتمد', child: Text('اعتماد العرض')),
          PopupMenuItem(value: 'ملغي', child: Text('إلغاء العرض')),
        ];
      case 'مرسل':
        return const [
          PopupMenuItem(value: 'مسودة', child: Text('إعادة إلى مسودة')),
          PopupMenuItem(value: 'معتمد', child: Text('اعتماد العرض')),
          PopupMenuItem(value: 'مرفوض', child: Text('رفض العرض')),
          PopupMenuItem(value: 'ملغي', child: Text('إلغاء العرض')),
        ];
      case 'معتمد':
        return const [
          PopupMenuItem(value: 'ملغي', child: Text('إلغاء اعتماد العرض')),
        ];
      case 'مرفوض':
      case 'ملغي':
        return const [
          PopupMenuItem(value: 'مسودة', child: Text('إعادة فتح كمسودة')),
        ];
      default:
        return const <PopupMenuEntry<String>>[];
    }
  }

  Future<void> _handleStatusChange(String quoteId, String newStatus, ErpProvider erp) async {
    final result = await erp.updateQuotationStatus(quoteId, newStatus);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.isSuccess ? AppTheme.primaryGreen : Colors.red.shade700,
        ),
      );
    }
  }

  void _showQuoteDetails(Quotation q) {
    final erp = context.read<ErpProvider>();
    final isAdmin = context.read<AuthProvider>().isAdmin;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
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
                          color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.request_quote_rounded, color: AppTheme.primaryGreen, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'عرض السعر: ${q.number}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.darkSlate),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                AppTheme.statusBadge(q.status),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'تاريخ العرض: ${AppTheme.formatDate(q.date)} | ${q.customerCode}',
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
                  const SizedBox(height: 10),

                  // بطاقة العميل
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, color: AppTheme.primaryGreen, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(q.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text('العميل المسجل', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // تفاصيل المواصفات
                  _buildInfoRow('المنتج المطلوب:', q.product),
                  _buildInfoRow('الكمية المطلوبة:', '${q.qty} نسخة'),
                  if (q.pages > 0) _buildInfoRow('عدد الصفحات:', '${q.pages} صفحة'),
                  if (q.ncrCopies > 0) _buildInfoRow('نسخ NCR:', '${q.ncrCopies} نسخ مكربنة'),
                  _buildInfoRow('الورق المستخدم:', q.paper),
                  _buildInfoRow('الماكينة:', q.machine),
                  _buildInfoRow('سعر الوحدة المقترح:', AppTheme.formatCurrency(q.unitPrice, erp.settings.currency)),
                  const SizedBox(height: 12),

                  // ملخص المبالغ والربحية
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      children: [
                        if (isAdmin)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.toll_outlined, size: 16, color: AppTheme.textMuted),
                                  SizedBox(width: 6),
                                  Text('التكلفة الكلية:', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                                ],
                              ),
                              Text(AppTheme.formatCurrency(q.totalCost, erp.settings.currency), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.receipt_long_rounded, size: 16, color: AppTheme.darkSlate),
                                SizedBox(width: 6),
                                Text('إجمالي قيمة العرض:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkSlate)),
                              ],
                            ),
                            Text(
                              AppTheme.formatCurrency(q.quoteAmount, erp.settings.currency),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                            ),
                          ],
                        ),
                        if (isAdmin) ...[
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.trending_up_rounded, size: 18, color: Color(0xFF059669)),
                                  SizedBox(width: 6),
                                  Text('صافي الربح المتوقع:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                                ],
                              ),
                              Text(
                                AppTheme.formatCurrency(q.profit, erp.settings.currency),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (q.notes != null && q.notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ملاحظات العرض:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.darkSlate)),
                          const SizedBox(height: 4),
                          Text(q.notes!, style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // أزرار الإجراءات
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => PdfExportService.shareQuotationPdf(
                            quotation: q,
                            settings: erp.settings,
                          ),
                          icon: const Icon(Icons.share_outlined, size: 18),
                          label: const Text('مشاركة PDF'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            side: const BorderSide(color: AppTheme.borderColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => PdfExportService.printOrPreviewQuotation(
                            context,
                            quotation: q,
                            settings: erp.settings,
                          ),
                          icon: const Icon(Icons.print_outlined, size: 18),
                          label: const Text('طباعة PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
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
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: AppTheme.textMuted, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: valueColor ?? (isBold ? AppTheme.darkSlate : AppTheme.textDark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
