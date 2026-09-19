import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../providers/auth_provider.dart';
import '../providers/erp_provider.dart';
import '../theme/app_theme.dart';

class DashboardView extends StatelessWidget {
  final Function(int) onNavigate;

  const DashboardView({super.key, required this.onNavigate});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'صباح الخير والبركة ☀️';
    if (hour >= 12 && hour < 17) return 'طاب يومك بكل خير 🌤️';
    return 'مساء الخير والإنتاجية 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final erp = context.watch<ErpProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final companyName = erp.settings.companyName.isNotEmpty ? erp.settings.companyName : 'مطبعة الجودة الحديثة';

    // حسابات إحصائية إضافية
    final totalCollected = erp.payments.fold(0.0, (sum, p) => sum + p.amount);
    final collectionPct = erp.totalApprovedSales > 0
        ? ((totalCollected / erp.totalApprovedSales) * 100).clamp(0.0, 100.0)
        : 0.0;

    final draftOrders = erp.productionOrders.where((o) => o.status == 'مسودة').length;
    final approvedOrders = erp.productionOrders.where((o) => o.status == 'معتمد').length;
    final inProgressOrders = erp.productionOrders.where((o) => o.status == 'قيد الإنتاج').length;
    final completedOrders = erp.productionOrders.where((o) => o.status == 'مكتمل').length;

    final activeMachinesCount = erp.machines.where(
      (m) => erp.productionOrders.any((o) => o.machine == m.name && o.status == 'قيد الإنتاج'),
    ).length;

    final lowStockCount = erp.lowStockPapers.length + erp.lowStockInks.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. ترويسة رئيسية فخمة (Executive Hero Header)
          _buildHeroHeader(
            context: context,
            companyName: companyName,
            userName: user?.displayName ?? 'المدير',
            inProgressOrders: inProgressOrders,
            lowStockCount: lowStockCount,
            approvedQuotes: erp.approvedQuotationsCount,
          ),
          const SizedBox(height: 18),

          // 2. تنبيه النواقص الذكي (إن وجد)
          if (lowStockCount > 0) ...[
            _buildLowStockAlert(lowStockCount),
            const SizedBox(height: 18),
          ],

          // 3. شبكة المؤشرات الحيوية الرئيسية (KPI Cards)
          _buildKpiSection(erp, totalCollected, collectionPct),
          const SizedBox(height: 20),

          // 4. شريط نبض خط الإنتاج والماكينات (Production Pulse)
          _buildProductionPulseBar(
            draftCount: draftOrders,
            approvedCount: approvedOrders,
            inProgressCount: inProgressOrders,
            completedCount: completedOrders,
            activeMachines: activeMachinesCount,
            totalMachines: erp.machines.length,
          ),
          const SizedBox(height: 20),

          // 5. القسم السفلي: أوامر الإنتاج النشطة + عروض الأسعار والوصول السريع
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1100;

              final ordersCard = _buildActiveOrdersSection(erp);
              final rightColumn = Column(
                children: [
                  _buildQuickActionsCard(),
                  const SizedBox(height: 18),
                  _buildRecentQuotationsCard(erp),
                ],
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: ordersCard),
                    const SizedBox(width: 18),
                    Expanded(flex: 2, child: rightColumn),
                  ],
                );
              } else {
                return Column(
                  children: [
                    ordersCard,
                    const SizedBox(height: 18),
                    rightColumn,
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 1. ترويسة تفاعلية راقية
  // =========================================================================
  Widget _buildHeroHeader({
    required BuildContext context,
    required String companyName,
    required String userName,
    required int inProgressOrders,
    required int lowStockCount,
    required int approvedQuotes,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0A2E1C),
            Color(0xFF114B31),
            Color(0xFF1A5D3F),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F5132).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: -30,
            bottom: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 650;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                          ),
                          child: const Icon(Icons.print_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'لوحة المؤشرات التفاعلية',
                                style: TextStyle(
                                  color: Color(0xFFD1FAE5),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_getGreeting()}، $userName',
                                style: const TextStyle(
                                  color: Color(0xFFA7F3D0),
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                companyName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (!isNarrow)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.calendar_today_rounded, color: Color(0xFFD1FAE5), size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  AppTheme.formatDate(DateTime.now()),
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white12, height: 1),
                    const SizedBox(height: 16),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildHeroPill(
                              icon: Icons.precision_manufacturing_rounded,
                              label: '$inProgressOrders أوامر جارية',
                              color: const Color(0xFFFDE68A),
                              bgColor: Colors.black.withValues(alpha: 0.25),
                            ),
                            _buildHeroPill(
                              icon: Icons.receipt_long_rounded,
                              label: '$approvedQuotes عروض معتمدة',
                              color: const Color(0xFF86EFAC),
                              bgColor: Colors.black.withValues(alpha: 0.25),
                            ),
                            if (lowStockCount > 0)
                              _buildHeroPill(
                                icon: Icons.warning_amber_rounded,
                                label: '$lowStockCount نواقص مخزون',
                                color: const Color(0xFFFCA5A5),
                                bgColor: Colors.red.withValues(alpha: 0.25),
                              ),
                          ],
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => onNavigate(1),
                              icon: const Icon(Icons.calculate_rounded, size: 16),
                              label: const Text('محرك التسعير الحي'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => onNavigate(2),
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: const Text('عرض سعر جديد'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white38),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
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
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 2. شريط تنبيه النواقص
  // =========================================================================
  Widget _buildLowStockAlert(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade50, Colors.orange.shade50],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline_rounded, color: Colors.red.shade800, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تنبيه نقص المخزون ($count أصناف وصلت حد الطلب)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red.shade900),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'يرجى مراجعة أرصدة الورق والأحبار لإصدار أوامر التوريد.',
                  style: TextStyle(fontSize: 11.5, color: Colors.red.shade800),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: () => onNavigate(4),
            icon: const Icon(Icons.arrow_forward_rounded, size: 14),
            label: const Text('المخزون', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 3. كروت المؤشرات الحيوية الرئيسية
  // =========================================================================
  Widget _buildKpiSection(ErpProvider erp, double totalCollected, double collectionPct) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;
        final crossAxisCount = constraints.maxWidth > 1100 ? 4 : 2;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: isMobile ? 10 : 14,
          mainAxisSpacing: isMobile ? 10 : 14,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: constraints.maxWidth > 1250 ? 1.95 : (constraints.maxWidth > 650 ? 2.1 : 1.35),
          children: [
            _buildModernStatCard(
              title: 'إجمالي المبيعات المعتمدة',
              value: AppTheme.formatCurrency(erp.totalApprovedSales, erp.settings.currency),
              subtext: '${erp.approvedQuotationsCount} عروض معتمدة',
              badgeText: 'نشطة',
              icon: Icons.payments_rounded,
              accentColor: const Color(0xFF0F5132),
              gradientColors: const [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
              onTap: () => onNavigate(2),
              isCompact: isMobile,
            ),
            _buildModernStatCard(
              title: 'إجمالي الأرباح الصافية',
              value: AppTheme.formatCurrency(erp.totalProfit, erp.settings.currency),
              subtext: 'بعد خصم الخامات',
              badgeText: '${erp.overallMarginPct.toStringAsFixed(1)}%',
              icon: Icons.trending_up_rounded,
              accentColor: const Color(0xFF059669),
              gradientColors: const [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
              onTap: () => onNavigate(9),
              isCompact: isMobile,
            ),
            _buildModernStatCard(
              title: 'قيمة المخزون الإجمالي',
              value: AppTheme.formatCurrency(erp.totalInventoryValue, erp.settings.currency),
              subtext: isMobile
                  ? 'ورق: ${AppTheme.formatCurrency(erp.totalPaperInventoryValue)}'
                  : 'ورق: ${AppTheme.formatCurrency(erp.totalPaperInventoryValue)} | أحبار: ${AppTheme.formatCurrency(erp.totalInkInventoryValue)}',
              badgeText: '${erp.papers.length + erp.inks.length} صنف',
              icon: Icons.inventory_2_rounded,
              accentColor: const Color(0xFF0284C7),
              gradientColors: const [Color(0xFFF0F9FF), Color(0xFFE0F2FE)],
              onTap: () => onNavigate(4),
              isCompact: isMobile,
            ),
            _buildModernStatCard(
              title: 'ذمم العملاء المستحقة',
              value: AppTheme.formatCurrency(erp.totalReceivables, erp.settings.currency),
              subtext: 'تحصيل ${AppTheme.formatCurrency(totalCollected)}',
              badgeText: '${collectionPct.toStringAsFixed(0)}%',
              icon: Icons.account_balance_wallet_rounded,
              accentColor: const Color(0xFFD97706),
              gradientColors: const [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
              onTap: () => onNavigate(6),
              isCompact: isMobile,
            ),
          ],
        );
      },
    );
  }

  Widget _buildModernStatCard({
    required String title,
    required String value,
    required String subtext,
    required String badgeText,
    required IconData icon,
    required Color accentColor,
    required List<Color> gradientColors,
    required VoidCallback onTap,
    bool isCompact = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(isCompact ? 10 : 15),
        decoration: BoxDecoration(
          color: Colors.white,
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
                    gradient: LinearGradient(colors: gradientColors),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accentColor.withValues(alpha: 0.15)),
                  ),
                  child: Icon(icon, color: accentColor, size: isCompact ? 17 : 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: isCompact ? 9.5 : 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: isCompact ? 11 : 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
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
                      fontSize: isCompact ? 15 : 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkSlate,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              subtext,
              style: TextStyle(fontSize: isCompact ? 10 : 11, color: AppTheme.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 4. شريط نبض خط الإنتاج وإشغال الماكينات
  // =========================================================================
  Widget _buildProductionPulseBar({
    required int draftCount,
    required int approvedCount,
    required int inProgressCount,
    required int completedCount,
    required int activeMachines,
    required int totalMachines,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 850;

          final stagesRow = Row(
            children: [
              _buildPulseStep('مسودة', draftCount, Colors.blueGrey, Icons.edit_note_rounded),
              _buildPulseDivider(),
              _buildPulseStep('معتمد', approvedCount, const Color(0xFF0284C7), Icons.check_circle_outline_rounded),
              _buildPulseDivider(),
              _buildPulseStep('قيد الإنتاج', inProgressCount, const Color(0xFFD97706), Icons.engineering_rounded, isHighlight: true),
              _buildPulseDivider(),
              _buildPulseStep('مكتمل', completedCount, const Color(0xFF15803D), Icons.verified_rounded),
            ],
          );

          final machinesPill = Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.precision_manufacturing_rounded,
                  size: 16,
                  color: activeMachines > 0 ? AppTheme.primaryGreen : AppTheme.textMuted,
                ),
                const SizedBox(width: 8),
                Text(
                  'الماكينات: $activeMachines / $totalMachines نشطة',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: activeMachines > 0 ? AppTheme.primaryGreen : AppTheme.darkSlate,
                  ),
                ),
              ],
            ),
          );

          if (isWide) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: stagesRow),
                const SizedBox(width: 16),
                machinesPill,
              ],
            );
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                stagesRow,
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerRight, child: machinesPill),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildPulseStep(String title, int count, Color color, IconData icon, {bool isHighlight = false}) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                count.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              color: isHighlight ? color : AppTheme.textMuted,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPulseDivider() {
    return Container(
      width: 1,
      height: 24,
      color: AppTheme.borderColor,
    );
  }

  // =========================================================================
  // 5. قسم أوامر الإنتاج النشطة
  // =========================================================================
  Widget _buildActiveOrdersSection(ErpProvider erp) {
    final activeOrders = erp.productionOrders.take(5).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.assignment_rounded, color: AppTheme.primaryGreen, size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'أوامر الإنتاج الحالية',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppTheme.darkSlate),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => onNavigate(3),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                  label: const Text('عرض الكل', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.primaryGreen),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (activeOrders.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.assignment_turned_in_outlined, size: 40, color: Colors.black26),
                    SizedBox(height: 10),
                    Text('لا توجد أوامر إنتاج مسجلة حالياً', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeOrders.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final order = activeOrders[idx];
                return _buildOrderRowItem(order);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildOrderRowItem(ProductionOrder order) {
    return InkWell(
      onTap: () => onNavigate(3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Text(
                    order.number,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: AppTheme.darkSlate),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(child: AppTheme.statusBadge(order.status)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${order.product} (${order.qty} نسخة)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${order.customerName} • ${order.machine}',
                    style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      order.areAllMaterialsIssued ? Icons.check_circle_rounded : Icons.pending_outlined,
                      size: 12,
                      color: order.areAllMaterialsIssued ? Colors.green : Colors.orange.shade800,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      order.areAllMaterialsIssued ? 'المواد مصروفة' : 'بانتظار الصرف',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: order.areAllMaterialsIssued ? Colors.green.shade800 : Colors.orange.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 6. مركز العمليات السريعة الحديث
  // =========================================================================
  Widget _buildQuickActionsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.flash_on_rounded, color: Color(0xFF0284C7), size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'مركز العمليات السريعة',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppTheme.darkSlate),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionButton(
                  icon: Icons.calculate_outlined,
                  title: 'تسعير سريع',
                  color: const Color(0xFF0F5132),
                  onTap: () => onNavigate(1),
                ),
                _buildActionButton(
                  icon: Icons.post_add_rounded,
                  title: 'عرض سعر',
                  color: const Color(0xFFD97706),
                  onTap: () => onNavigate(2),
                ),
                _buildActionButton(
                  icon: Icons.inventory_2_outlined,
                  title: 'حركات الورق',
                  color: const Color(0xFF0284C7),
                  onTap: () => onNavigate(4),
                ),
                _buildActionButton(
                  icon: Icons.format_color_fill_rounded,
                  title: 'مخزون الحبر',
                  color: const Color(0xFF7C3AED),
                  onTap: () => onNavigate(5),
                ),
                _buildActionButton(
                  icon: Icons.payments_outlined,
                  title: 'سند قبض',
                  color: const Color(0xFF059669),
                  onTap: () => onNavigate(7),
                ),
                _buildActionButton(
                  icon: Icons.insights_rounded,
                  title: 'تقارير الأرباح',
                  color: const Color(0xFFDC2626),
                  onTap: () => onNavigate(9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Text(
              title,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 7. أحدث عروض الأسعار
  // =========================================================================
  Widget _buildRecentQuotationsCard(ErpProvider erp) {
    final recentQuotes = erp.quotations.take(4).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.request_quote_rounded, color: AppTheme.accentGold, size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'أحدث عروض الأسعار',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppTheme.darkSlate),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => onNavigate(2),
                  child: const Text('المزيد', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (recentQuotes.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('لا توجد عروض أسعار مسجلة', style: TextStyle(color: AppTheme.textMuted, fontSize: 12.5)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentQuotes.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final q = recentQuotes[idx];
                return InkWell(
                  onTap: () => onNavigate(2),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${q.number} • ${q.customerName}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppTheme.darkSlate),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${q.product} (${q.qty} نسخة)',
                                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              AppTheme.formatCurrency(q.quoteAmount),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppTheme.primaryGreen),
                            ),
                            const SizedBox(height: 2),
                            AppTheme.statusBadge(q.status),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
