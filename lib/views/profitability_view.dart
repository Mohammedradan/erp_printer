import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/erp_provider.dart';
import '../theme/app_theme.dart';

class ProfitabilityView extends StatelessWidget {
  const ProfitabilityView({super.key});

  @override
  Widget build(BuildContext context) {
    final erp = context.watch<ErpProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // شريط العنوان الرئيسي
          _buildHeader(context),
          const SizedBox(height: 20),

          // كروت المؤشرات السريعة KPI
          _buildKpiGrid(erp),
          const SizedBox(height: 24),

          // المحتوى التفصيلي: المؤشرات المالية وتحليلات المنتجات والماكينات
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 850;

              final indicatorsCard = _buildFinancialIndicatorsCard(erp);
              final analysisCards = _buildAnalysisCards(erp);

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: indicatorsCard),
                    const SizedBox(width: 20),
                    Expanded(flex: 4, child: analysisCards),
                  ],
                );
              } else {
                return Column(
                  children: [
                    indicatorsCard,
                    const SizedBox(height: 20),
                    analysisCards,
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // شريط العنوان
  Widget _buildHeader(BuildContext context) {
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
                  child: const Icon(Icons.analytics_rounded, color: AppTheme.primaryGreen, size: 22),
                ),
                const Text(
                  'تقارير الربحية والمؤشرات المالية',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'تحليل دقيق للإيرادات، تكاليف الإنتاج، هوامش الأرباح، وكفاءة تشغيل الماكينات',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
          ],
        ),
        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('تم تجهيز التقرير المالي وتصديره بنجاح'),
                  ],
                ),
                backgroundColor: AppTheme.primaryGreen,
              ),
            );
          },
          icon: const Icon(Icons.download_rounded, size: 18),
          label: const Text('تصدير التقرير المالي'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryGreen,
            side: const BorderSide(color: AppTheme.primaryGreen),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  // كروت المؤشرات السريعة (KPIs)
  Widget _buildKpiGrid(ErpProvider erp) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;
        final crossAxisCount = constraints.maxWidth > 950 ? 4 : 2;
        final aspect = constraints.maxWidth > 1200 ? 2.3 : (constraints.maxWidth > 950 ? 2.0 : (isMobile ? 1.38 : 2.0));

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: isMobile ? 10 : 14,
          mainAxisSpacing: isMobile ? 10 : 14,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: aspect,
          children: [
            _buildKpiCard(
              title: 'المبيعات المعتمدة',
              value: AppTheme.formatCurrency(erp.totalApprovedSales, erp.settings.currency),
              subtitle: '${erp.approvedQuotationsCount} عروض مؤكدة',
              icon: Icons.payments_outlined,
              badgeColor: const Color(0xFF059669),
              gradientColors: [Colors.white, const Color(0xFFF0FDF4)],
              isCompact: isMobile,
            ),
            _buildKpiCard(
              title: 'التكلفة التشغيلية',
              value: AppTheme.formatCurrency(erp.totalApprovedCost, erp.settings.currency),
              subtitle: 'خامات + تشغيل + هالك',
              icon: Icons.receipt_long_outlined,
              badgeColor: const Color(0xFFD97706),
              gradientColors: [Colors.white, const Color(0xFFFFFBEB)],
              isCompact: isMobile,
            ),
            _buildKpiCard(
              title: 'صافي الربح المحقق',
              value: AppTheme.formatCurrency(erp.totalProfit, erp.settings.currency),
              subtitle: 'هامش ${erp.overallMarginPct.toStringAsFixed(1)}%',
              icon: Icons.trending_up_rounded,
              badgeColor: AppTheme.primaryGreen,
              gradientColors: [Colors.white, const Color(0xFFECFDF5)],
              isCompact: isMobile,
            ),
            _buildKpiCard(
              title: 'قيمة المخزون',
              value: AppTheme.formatCurrency(erp.totalInventoryValue, erp.settings.currency),
              subtitle: '${erp.papers.length + erp.inks.length} صنف مسجل',
              icon: Icons.inventory_2_outlined,
              badgeColor: const Color(0xFF0284C7),
              gradientColors: [Colors.white, const Color(0xFFF0F9FF)],
              isCompact: isMobile,
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color badgeColor,
    required List<Color> gradientColors,
    bool isCompact = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(isCompact ? 10 : 14),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: badgeColor, size: 18),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          value,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 10, color: AppTheme.textMuted.withValues(alpha: 0.8)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: badgeColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted.withValues(alpha: 0.8)),
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

  // بطاقة المؤشرات المالية والتشغيلية
  Widget _buildFinancialIndicatorsCard(ErpProvider erp) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.table_chart_outlined, color: AppTheme.primaryGreen, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'المؤشرات المالية والتشغيلية الشاملة',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.darkSlate),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 6),
            _buildIndicatorRow(
              title: 'إجمالي قيمة العروض المعتمدة',
              subtitle: 'المبيعات المؤكدة من أوامر العملاء',
              value: AppTheme.formatCurrency(erp.totalApprovedSales, erp.settings.currency),
              color: AppTheme.primaryGreen,
              icon: Icons.check_circle_outline,
            ),
            _buildIndicatorRow(
              title: 'التكاليف التشغيلية المباشرة',
              subtitle: 'خامات الورق، بليتات، تشغيل، وتشطيب',
              value: AppTheme.formatCurrency(erp.totalApprovedCost, erp.settings.currency),
              color: AppTheme.darkSlate,
              icon: Icons.toll_outlined,
            ),
            _buildIndicatorRow(
              title: 'صافي الربح المحقق',
              subtitle: 'الفارق الصافي بين الإيراد والتكلفة الكلية',
              value: AppTheme.formatCurrency(erp.totalProfit, erp.settings.currency),
              color: const Color(0xFF059669),
              isBold: true,
              icon: Icons.trending_up,
            ),
            _buildIndicatorRow(
              title: 'متوسط هامش الربح الإجمالي',
              subtitle: 'نسبة الأرباح الصافية إلى حجم المبيعات',
              value: '${erp.overallMarginPct.toStringAsFixed(1)} %',
              color: AppTheme.accentGold,
              isBold: true,
              icon: Icons.pie_chart_outline,
            ),
            _buildIndicatorRow(
              title: 'عدد عروض الأسعار المعتمدة',
              subtitle: 'العروض التي دخلت دورة التشغيل الفعلي',
              value: '${erp.approvedQuotationsCount} عروض',
              icon: Icons.request_quote_outlined,
            ),
            _buildIndicatorRow(
              title: 'أوامر الإنتاج المكتملة',
              subtitle: 'الأوامر المسلمة والمصنعة بالكامل',
              value: '${erp.completedOrdersCount} أوامر',
              icon: Icons.done_all,
            ),
            _buildIndicatorRow(
              title: 'قيمة مخزون الورق الفعلي',
              subtitle: 'إجمالي رصيد الأفرخ مقيّمة بسعر الشراء',
              value: AppTheme.formatCurrency(erp.totalPaperInventoryValue, erp.settings.currency),
              icon: Icons.layers_outlined,
            ),
            _buildIndicatorRow(
              title: 'قيمة مخزون الأحبار والخامات',
              subtitle: 'أحبار الأوفست ومستلزمات الطباعة',
              value: AppTheme.formatCurrency(erp.totalInkInventoryValue, erp.settings.currency),
              icon: Icons.format_paint_outlined,
            ),
            _buildIndicatorRow(
              title: 'إجمالي قيمة المخزون الكلي',
              subtitle: 'أصول المستودع الجاهزة للتشغيل (ورق + أحبار)',
              value: AppTheme.formatCurrency(erp.totalInventoryValue, erp.settings.currency),
              color: const Color(0xFF0284C7),
              isBold: true,
              icon: Icons.account_balance_outlined,
            ),
            _buildIndicatorRow(
              title: 'إجمالي ذمم العملاء المستحقة',
              subtitle: 'المبالغ المتبقية للتحصيل طرف العملاء',
              value: AppTheme.formatCurrency(erp.totalReceivables, erp.settings.currency),
              color: Colors.orange.shade800,
              isBold: true,
              icon: Icons.pending_actions_outlined,
            ),
          ],
        ),
      ),
    );
  }

  // بطاقات التحليلات الجانبية: ربحية المنتجات وكفاءة الماكينات
  Widget _buildAnalysisCards(ErpProvider erp) {
    return Column(
      children: [
        // بطاقة الربحية حسب المنتجات
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.pie_chart_rounded, color: Colors.purple, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('الربحية حسب نوع المنتج', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(),
                ...erp.products.map((prod) {
                  final quotes = erp.quotations.where((q) => q.product == prod.name && q.status == 'معتمد');
                  final sales = quotes.fold(0.0, (s, q) => s + q.quoteAmount);
                  final profit = quotes.fold(0.0, (s, q) => s + q.profit);
                  final margin = sales > 0 ? (profit / sales) * 100 : 0.0;
                  final progress = erp.totalApprovedSales > 0 ? (sales / erp.totalApprovedSales).clamp(0.0, 1.0) : 0.0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              prod.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              AppTheme.formatCurrency(sales),
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 7,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: const AlwaysStoppedAnimation(AppTheme.primaryGreen),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'صافي الربح: ${AppTheme.formatCurrency(profit)}',
                                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: (margin >= 25 ? Colors.green : Colors.orange).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'هامش: ${margin.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: margin >= 25 ? Colors.green.shade800 : Colors.orange.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // بطاقة كفاءة وتشغيل الماكينات
        Card(
          color: const Color(0xFFF8FAFC),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.precision_manufacturing_rounded, color: AppTheme.primaryLight, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('مؤشرات كفاءة وتشغيل الماكينات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(),
                ...erp.machines.map((m) {
                  final orders = erp.productionOrders.where((o) => o.machine == m.name);
                  final totalHours = orders.fold(0.0, (s, o) => s + o.runHours);

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                              Text('النوع: ${m.kind} | السرعة: ${m.speedPerHour.toInt()} طبعة/س', style: TextStyle(fontSize: 11, color: AppTheme.textMuted), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${totalHours.toStringAsFixed(1)} ساعة تشغيل', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryGreen)),
                            Text('نسبة الهالك: ${m.wastePct}%', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIndicatorRow({
    required String title,
    required String subtitle,
    required String value,
    Color? color,
    bool isBold = false,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: color ?? AppTheme.textMuted),
            const SizedBox(width: 10),
          ],
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                    color: isBold ? AppTheme.darkSlate : AppTheme.textDark,
                  ),
                ),
                Text(subtitle, style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: isBold ? 15 : 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: color ?? AppTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
