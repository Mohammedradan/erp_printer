import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/erp_provider.dart';
import '../theme/app_theme.dart';

class DashboardView extends StatelessWidget {
  final Function(int) onNavigate;

  const DashboardView({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final erp = context.watch<ErpProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // شريط الترحيب والملخص السريع (متجاوب)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'لوحة المؤشرات التفاعلية',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'نظرة شاملة على عمليات المطبعة، المبيعات، المخزون، والإنتاج',
                    style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  ),
                ],
              ),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => onNavigate(1), // محرك التسعير
                    icon: const Icon(Icons.calculate_outlined, size: 18),
                    label: const Text('محرك التسعير الحي'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => onNavigate(2), // عروض الأسعار
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('عرض سعر جديد'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primaryGreen),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // تنبيهات إعادة الطلب (إن وجدت)
          if (erp.lowStockPapers.isNotEmpty || erp.lowStockInks.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: LayoutBuilder(
                builder: (context, box) {
                  final isCompact = box.maxWidth < 450;
                  if (isCompact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'تنبيه مخزون: (${erp.lowStockPapers.length + erp.lowStockInks.length}) صنف وصل حد الطلب!',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ElevatedButton.icon(
                            onPressed: () => onNavigate(4), // مخزون الورق
                            icon: const Icon(Icons.inventory_2_outlined, size: 16),
                            label: const Text('إدارة المخزون', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'تنبيه مخزون: (${erp.lowStockPapers.length + erp.lowStockInks.length}) صنف وصل حد الطلب!',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => onNavigate(4), // مخزون الورق
                        icon: const Icon(Icons.inventory_2_outlined, size: 16),
                        label: const Text('إدارة المخزون', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

          // كروت المؤشرات المالية الأربعة الرئيسية
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 1000 ? 4 : (constraints.maxWidth > 650 ? 2 : 1);
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: constraints.maxWidth > 1250 ? 2.2 : 1.95,
                children: [
                  _buildStatCard(
                    title: 'إجمالي المبيعات المعتمدة',
                    value: AppTheme.formatCurrency(erp.totalApprovedSales, erp.settings.currency),
                    subtitle: '${erp.approvedQuotationsCount} عروض معتمدة',
                    icon: Icons.payments_outlined,
                    color: const Color(0xFF0F5132),
                    onTap: () => onNavigate(2),
                  ),
                  _buildStatCard(
                    title: 'إجمالي الأرباح الصافية',
                    value: AppTheme.formatCurrency(erp.totalProfit, erp.settings.currency),
                    subtitle: 'هامش ربح ${erp.overallMarginPct.toStringAsFixed(1)}%',
                    icon: Icons.trending_up,
                    color: const Color(0xFF15803D),
                    onTap: () => onNavigate(9),
                  ),
                  _buildStatCard(
                    title: 'قيمة المخزون الكلي',
                    value: AppTheme.formatCurrency(erp.totalInventoryValue, erp.settings.currency),
                    subtitle: 'ورق: ${AppTheme.formatCurrency(erp.totalPaperInventoryValue)} | أحبار: ${AppTheme.formatCurrency(erp.totalInkInventoryValue)}',
                    icon: Icons.inventory_2_outlined,
                    color: const Color(0xFF0284C7),
                    onTap: () => onNavigate(4),
                  ),
                  _buildStatCard(
                    title: 'ذمم العملاء المستحقة',
                    value: AppTheme.formatCurrency(erp.totalReceivables, erp.settings.currency),
                    subtitle: 'من ${erp.customers.length} عملاء مسجلين',
                    icon: Icons.account_balance_wallet_outlined,
                    color: const Color(0xFFD97706),
                    onTap: () => onNavigate(6),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // قسمين: أوامر الإنتاج الحالية + الإجراءات السريعة (متجاوب)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 950;

              final ordersCard = Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.precision_manufacturing_outlined, color: AppTheme.primaryGreen, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'أوامر الإنتاج النشطة',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => onNavigate(3),
                            icon: const Icon(Icons.arrow_forward, size: 16),
                            label: const Text('عرض الكل'),
                          ),
                        ],
                      ),
                      const Divider(),
                      if (erp.productionOrders.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: Text('لا توجد أوامر إنتاج حالياً')),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: erp.productionOrders.take(5).length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, idx) {
                            final order = erp.productionOrders[idx];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: order.status == 'مكتمل'
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFFEF3C7),
                                child: Icon(
                                  order.status == 'مكتمل' ? Icons.check : Icons.build_circle_outlined,
                                  color: order.status == 'مكتمل' ? const Color(0xFF15803D) : const Color(0xFFB45309),
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                '${order.number} — ${order.product} (${order.qty} نسخة)',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              subtitle: Text(
                                'العميل: ${order.customerName} | الماكينة: ${order.machine}',
                                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                              ),
                              trailing: AppTheme.statusBadge(order.status),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              );

              final actionsCard = Column(
                children: [
                  // أحدث عروض الأسعار
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Row(
                                  children: [
                                    Icon(Icons.request_quote_outlined, color: AppTheme.accentGold, size: 20),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'أحدث عروض الأسعار',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(onPressed: () => onNavigate(2), child: const Text('المزيد')),
                            ],
                          ),
                          const Divider(),
                          if (erp.quotations.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: Text('لا توجد عروض أسعار')),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: erp.quotations.take(4).length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, idx) {
                                final q = erp.quotations[idx];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    '${q.number} - ${q.customerName}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  subtitle: Text(
                                    '${q.product} (${q.qty}) | ${AppTheme.formatCurrency(q.quoteAmount)}',
                                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                  ),
                                  trailing: AppTheme.statusBadge(q.status),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // وصول سريع لعمليات الإكسل
                  Card(
                    color: const Color(0xFFF8FAFC),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('وصول سريع للعمليات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ActionChip(
                                avatar: const Icon(Icons.calculate, size: 16, color: AppTheme.primaryGreen),
                                label: const Text('تسعير أمر جديد'),
                                onPressed: () => onNavigate(1),
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.inventory, size: 16, color: Colors.blue),
                                label: const Text('حركات المخزون'),
                                onPressed: () => onNavigate(4),
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.palette, size: 16, color: Colors.purple),
                                label: const Text('مخزون الأحبار'),
                                onPressed: () => onNavigate(5),
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.payments, size: 16, color: Colors.teal),
                                label: const Text('سندات القبض'),
                                onPressed: () => onNavigate(7),
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.analytics, size: 16, color: Colors.orange),
                                label: const Text('تقارير الربحية'),
                                onPressed: () => onNavigate(9),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: ordersCard),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: actionsCard),
                  ],
                );
              } else {
                return Column(
                  children: [
                    ordersCard,
                    const SizedBox(height: 16),
                    actionsCard,
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
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
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
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
}
