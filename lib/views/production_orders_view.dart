import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../providers/erp_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class ProductionOrdersView extends StatefulWidget {
  const ProductionOrdersView({super.key});

  @override
  State<ProductionOrdersView> createState() => _ProductionOrdersViewState();
}

class _ProductionOrdersViewState extends State<ProductionOrdersView> {
  String _filterStatus = 'الكل';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final erp = context.watch<ErpProvider>();
    final auth = context.watch<AuthProvider>();

    final filtered = erp.productionOrders.where((o) {
      final matchesStatus = _filterStatus == 'الكل' || o.status == _filterStatus;
      final matchesSearch = _searchQuery.isEmpty ||
          o.number.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          o.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          o.product.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesStatus && matchesSearch;
    }).toList();

    final isMobile = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // شريط العنوان
          Wrap(
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
                          color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.precision_manufacturing_rounded, color: AppTheme.primaryGreen, size: 22),
                      ),
                      const Text(
                        'أوامر الإنتاج ومتابعة التشغيل',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'متابعة مراحل التنفيذ، الماكينات، استهلاك الورق، ومواعيد التسليم',
                    style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showNewOrderDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('أمر إنتاج يدوي جديد'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // كروت إحصائيات سريعة للأوامر
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              final crossAxisCount = isWide ? 4 : 2;
              final aspect = isWide ? 2.6 : 2.1;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: aspect,
                children: [
                  _buildMiniStatusCard('إجمالي الأوامر', '${erp.productionOrders.length}', const Color(0xFF0F766E), Icons.precision_manufacturing_rounded),
                  _buildMiniStatusCard('معتمدة وجاهزة', '${erp.productionOrders.where((o) => o.status == 'معتمد').length}', const Color(0xFF0284C7), Icons.playlist_add_check_rounded),
                  _buildMiniStatusCard('قيد التشغيل', '${erp.inProgressOrdersCount}', const Color(0xFFD97706), Icons.sync_rounded),
                  _buildMiniStatusCard('مكتملة ومسلمة', '${erp.completedOrdersCount}', const Color(0xFF059669), Icons.verified_rounded),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // شريط البحث والفلترة
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 500;
                  if (isCompact) {
                    return Column(
                      children: [
                        TextField(
                          decoration: const InputDecoration(
                            hintText: 'بحث برقم الأمر، العميل، أو المنتج...',
                            prefixIcon: Icon(Icons.search, size: 20),
                            isDense: true,
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Text('تصفية الحالة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButton<String>(
                                value: _filterStatus,
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem(value: 'الكل', child: Text('جميع الحالات')),
                                  DropdownMenuItem(value: 'مسودة', child: Text('مسودة')),
                                  DropdownMenuItem(value: 'معتمد', child: Text('معتمد')),
                                  DropdownMenuItem(value: 'قيد الإنتاج', child: Text('قيد الإنتاج')),
                                  DropdownMenuItem(value: 'مكتمل', child: Text('مكتمل')),
                                  DropdownMenuItem(value: 'ملغي', child: Text('ملغي')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _filterStatus = val);
                                },
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
                        flex: 2,
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'بحث برقم الأمر، العميل، أو المنتج...',
                            prefixIcon: Icon(Icons.search, size: 20),
                            isDense: true,
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text('تصفية الحالة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _filterStatus,
                        items: const [
                          DropdownMenuItem(value: 'الكل', child: Text('جميع الحالات')),
                          DropdownMenuItem(value: 'مسودة', child: Text('مسودة')),
                          DropdownMenuItem(value: 'معتمد', child: Text('معتمد')),
                          DropdownMenuItem(value: 'قيد الإنتاج', child: Text('قيد الإنتاج')),
                          DropdownMenuItem(value: 'مكتمل', child: Text('مكتمل')),
                          DropdownMenuItem(value: 'ملغي', child: Text('ملغي')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _filterStatus = val);
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // قائمة / جدول أوامر الإنتاج
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('لا توجد أوامر إنتاج مطابقة للبحث')),
                    )
                  else if (MediaQuery.of(context).size.width < 750)
                    _buildMobileOrderCards(filtered, erp)
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                        columns: const [
                          DataColumn(label: Text('رقم الأمر', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('رقم العرض', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('العميل', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('المنتج والكمية', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('الماكينة', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('الخامة المطلوبة', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('الأوراق (مع الهالك)', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('ساعات التشغيل', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('صرف المواد', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('موعد التسليم', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: filtered.map((o) {
                          return DataRow(cells: [
                            DataCell(Text(o.number, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen))),
                            DataCell(Text(AppTheme.formatDate(o.date))),
                            DataCell(Text(o.quotationNumber ?? '—', style: const TextStyle(color: Colors.blueGrey))),
                            DataCell(Text(o.customerName, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Text('${o.product} (${o.qty} نسخة)')),
                            DataCell(Text(o.machine)),
                            DataCell(Text(o.paperName)),
                            DataCell(Text('${o.sheetsWithWaste.toInt()} فرخ')),
                            DataCell(Text('${o.runHours.toStringAsFixed(1)} س')),
                            DataCell(
                              o.areAllMaterialsIssued
                                  ? const Row(
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                                        SizedBox(width: 4),
                                        Text('تم الصرف', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                                      ],
                                    )
                                  : ElevatedButton.icon(
                                      onPressed: () =>
                                          _showIssueMaterialsDialog(o, erp, auth),
                                      icon: const Icon(Icons.outbox, size: 14),
                                      label: Text(
                                        o.materialRequirements.isEmpty
                                            ? 'صرف الآن'
                                            : 'صرف ${o.issuedMaterialsCount}/${o.materialRequirements.length}',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue.shade700,
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      ),
                                    ),
                            ),
                            DataCell(Text(o.dueDate != null ? AppTheme.formatDate(o.dueDate!) : '—')),
                            DataCell(AppTheme.statusBadge(o.status)),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.assignment_turned_in_outlined, size: 18, color: Colors.green),
                                    tooltip: 'إتمام الأمر',
                                    onPressed: o.status != 'قيد الإنتاج'
                                        ? null
                                        : () async {
                                            final result = await erp.updateProductionOrderStatus(o.id, 'مكتمل');
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(result.message),
                                                  backgroundColor: result.isSuccess ? AppTheme.primaryGreen : Colors.red.shade700,
                                                ),
                                              );
                                            }
                                          },
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, size: 18),
                                    onSelected: (st) => _handleOrderMenuSelection(o, st, erp),
                                    itemBuilder: (ctx) {
                                      switch (o.status) {
                                        case 'مسودة':
                                          return const [
                                            PopupMenuItem(value: 'معتمد', child: Text('اعتماد أمر التشغيل')),
                                            PopupMenuItem(value: 'ملغي', child: Text('إلغاء الأمر')),
                                          ];
                                        case 'معتمد':
                                          return [
                                            const PopupMenuItem(value: 'قيد الإنتاج', child: Text('بدء الإنتاج')),
                                            if (o.issuedMaterialsCount > 0)
                                              const PopupMenuItem(value: '_return_materials', child: Text('إرجاع مواد إلى المخزون')),
                                            const PopupMenuItem(value: 'ملغي', child: Text('إلغاء الأمر')),
                                          ];
                                        case 'قيد الإنتاج':
                                          return [
                                            const PopupMenuItem(value: '_return_materials', child: Text('إرجاع مواد إلى المخزون')),
                                            if (auth.isAdmin)
                                              const PopupMenuItem(value: '_record_waste', child: Text('تسجيل هالك فعلي')),
                                            const PopupMenuItem(value: 'مكتمل', child: Text('اكتمال الأمر والتسليم')),
                                          ];
                                        case 'مكتمل':
                                          return [
                                            if (o.issuedMaterialsCount > 0) ...[
                                              const PopupMenuItem(value: '_return_surplus', child: Text('إرجاع فائض إلى المخزون')),
                                              if (auth.isAdmin)
                                                const PopupMenuItem(value: '_record_waste', child: Text('تسجيل هالك فعلي')),
                                            ],
                                          ];
                                        default:
                                          return const <PopupMenuEntry<String>>[];
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                    tooltip: 'حذف',
                                    onPressed: () => _confirmDeleteOrder(o, erp),
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
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatusCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
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
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileOrderCards(List<ProductionOrder> orders, ErpProvider erp) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: orders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final o = orders[index];
        return Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // رأس الكارت: رقم الأمر + الحالة
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            o.number,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppTheme.formatDate(o.date),
                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: AppTheme.statusBadge(o.status),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // العميل والمنتج
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 16, color: Colors.blueGrey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        o.customerName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.darkSlate),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.shopping_bag_outlined, size: 16, color: Colors.blueGrey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${o.product} (${o.qty} نسخة)',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textDark),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // تفاصيل التشغيل: ماكينة، ورق، أفرخ
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.print_outlined, size: 15, color: Color(0xFF0284C7)),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    'الماكينة: ${o.machine}',
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time_rounded, size: 15, color: Color(0xFFD97706)),
                              const SizedBox(width: 5),
                              Text('${o.runHours.toStringAsFixed(1)} س تشغيل', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.layers_outlined, size: 15, color: AppTheme.primaryGreen),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    o.paperName,
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${o.sheetsWithWaste.toInt()} فرخ',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                          ),
                        ],
                      ),
                      if (o.dueDate != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.event_available_outlined, size: 15, color: Colors.blueGrey),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                'موعد التسليم: ${AppTheme.formatDate(o.dueDate!)}',
                                style: const TextStyle(fontSize: 11.5, color: Colors.blueGrey),
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
                // شريط الإجراءات وصرف المواد
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // حالة صرف المواد
                    Expanded(
                      child: o.areAllMaterialsIssued
                          ? const Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'تم صرف المواد',
                                    style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            )
                          : OutlinedButton.icon(
                              onPressed: () =>
                                  _showIssueMaterialsDialog(o, erp, auth),
                              icon: const Icon(Icons.outbox_rounded, size: 15),
                              label: Text(
                                o.materialRequirements.isEmpty
                                    ? 'صرف المواد'
                                    : 'صرف ${o.issuedMaterialsCount}/${o.materialRequirements.length}',
                                style: const TextStyle(fontSize: 11.5),
                                overflow: TextOverflow.ellipsis,
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue.shade700,
                                side: BorderSide(color: Colors.blue.shade300),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                    ),
                    const SizedBox(width: 8),
                    // أزرار التحكم بالأمر
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.assignment_turned_in_outlined, size: 20, color: Colors.green),
                          tooltip: 'إتمام الأمر',
                          onPressed: o.status != 'قيد الإنتاج'
                              ? null
                              : () async {
                                  final result = await erp.updateProductionOrderStatus(o.id, 'مكتمل');
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(result.message),
                                        backgroundColor: result.isSuccess ? AppTheme.primaryGreen : Colors.red.shade700,
                                      ),
                                    );
                                  }
                                },
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.blueGrey),
                          onSelected: (val) => _handleOrderMenuSelection(o, val, erp),
                          itemBuilder: (ctx) {
                            switch (o.status) {
                              case 'مسودة':
                                return const [
                                  PopupMenuItem(value: 'معتمد', child: Text('اعتماد أمر التشغيل')),
                                  PopupMenuItem(value: 'ملغي', child: Text('إلغاء الأمر')),
                                ];
                              case 'معتمد':
                                return [
                                  const PopupMenuItem(value: 'قيد الإنتاج', child: Text('بدء الإنتاج')),
                                  if (o.issuedMaterialsCount > 0)
                                    const PopupMenuItem(value: '_return_materials', child: Text('إرجاع مواد إلى المخزون')),
                                  const PopupMenuItem(value: 'ملغي', child: Text('إلغاء الأمر')),
                                ];
                              case 'قيد الإنتاج':
                                return [
                                  const PopupMenuItem(value: '_return_materials', child: Text('إرجاع مواد إلى المخزون')),
                                  if (auth.isAdmin)
                                    const PopupMenuItem(value: '_record_waste', child: Text('تسجيل هالك فعلي')),
                                  const PopupMenuItem(value: 'مكتمل', child: Text('اكتمال الأمر والتسليم')),
                                ];
                              case 'مكتمل':
                                return [
                                  if (o.issuedMaterialsCount > 0) ...[
                                    const PopupMenuItem(value: '_return_surplus', child: Text('إرجاع فائض إلى المخزون')),
                                    if (auth.isAdmin)
                                      const PopupMenuItem(value: '_record_waste', child: Text('تسجيل هالك فعلي')),
                                  ],
                                ];
                              default:
                                return const <PopupMenuEntry<String>>[];
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                          tooltip: 'حذف',
                          onPressed: () => _confirmDeleteOrder(o, erp),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleOrderMenuSelection(
    ProductionOrder order,
    String value,
    ErpProvider erp,
  ) async {
    if (value == '_return_materials' || value == '_return_surplus') {
      _showReturnMaterialsDialog(order, erp);
      return;
    }
    if (value == '_record_waste') {
      _showActualWasteDialog(order, erp);
      return;
    }
    final result = await erp.updateProductionOrderStatus(order.id, value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.isSuccess ? AppTheme.primaryGreen : Colors.red.shade700,
        ),
      );
    }
  }

  void _showReturnMaterialsDialog(ProductionOrder order, ErpProvider erp) {
    final issuedMaterials = order.materialRequirements
        .where((material) => material.materialType == 'paper' && material.quantityIssued > 0)
        .toList();
    if (issuedMaterials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد مواد مصروفة يمكن إرجاعها لهذا الأمر')),
      );
      return;
    }
    final isPostCompletion = order.status == 'مكتمل';

    ProductionMaterialRequirement selectedMaterial = issuedMaterials.first;
    final quantityCtrl = TextEditingController(
      text: selectedMaterial.quantityIssued.toStringAsFixed(0),
    );
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.assignment_return_rounded, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isPostCompletion ? 'إرجاع فائض إلى المخزون' : 'إرجاع مواد إلى المخزون',
                  style: const TextStyle(fontSize: 17),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('أمر الإنتاج: ${order.number}', style: const TextStyle(color: AppTheme.textMuted)),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<ProductionMaterialRequirement>(
                    isExpanded: true,
                    initialValue: selectedMaterial,
                    decoration: const InputDecoration(
                      labelText: 'المادة المصروفة',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    items: issuedMaterials
                        .map(
                          (material) => DropdownMenuItem(
                            value: material,
                            child: Text(
                              '${material.materialName} — المصروف ${material.quantityIssued.toStringAsFixed(0)} ${material.unit}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (material) {
                      if (material == null) return;
                      setDialogState(() {
                        selectedMaterial = material;
                        quantityCtrl.text = material.quantityIssued.toStringAsFixed(0);
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: quantityCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'كمية الإرجاع',
                      suffixText: selectedMaterial.unit,
                      helperText: 'الحد الأقصى: ${selectedMaterial.quantityIssued.toStringAsFixed(0)} ${selectedMaterial.unit}',
                      prefixIcon: const Icon(Icons.undo_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'سبب الإرجاع / ملاحظات *',
                      prefixIcon: Icon(Icons.note_alt_outlined),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPostCompletion
                        ? 'الأمر مكتمل؛ سيُنشئ النظام حركة دخول موثقة للفائض وتُحدَّث الكمية الفعلية المستهلكة للأمر.'
                        : 'سيُنشئ النظام حركة دخول موثقة ويحافظ على حركة الصرف الأصلية.',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await erp.returnProductionMaterial(
                  orderId: order.id,
                  materialRequirementId: selectedMaterial.id,
                  quantity: double.tryParse(quantityCtrl.text) ?? 0,
                  notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                );
                if (ctx.mounted && result.isSuccess) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result.message),
                      backgroundColor: result.isSuccess ? AppTheme.primaryGreen : Colors.red.shade700,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.assignment_return_rounded),
              label: const Text('تسجيل الإرجاع'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// حوار صرف مواد أمر الإنتاج: يعرض المطلوب مقابل المتاح لكل مادة، وعند وجود
  /// عجز يتيح للمدير فقط الصرف الاستثنائي الموثق بسبب إلزامي.
  Future<void> _showIssueMaterialsDialog(
    ProductionOrder order,
    ErpProvider erp,
    AuthProvider auth,
  ) async {
    final lines = erp.paperIssuancePreview(order.id);
    if (lines.isEmpty) {
      // أوامر قديمة بلا قائمة مواد محفوظة: نفّذ الصرف المباشر كما في السابق.
      final result = await erp.deductPaperForOrder(order.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.isSuccess ? AppTheme.primaryGreen : Colors.red.shade700,
          ),
        );
      }
      return;
    }
    final hasDeficit = lines.any((line) => line.hasDeficit);
    final reasonCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.outbox_rounded, color: Colors.blue),
              SizedBox(width: 8),
              Expanded(child: Text('صرف مواد أمر الإنتاج', style: TextStyle(fontSize: 17))),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('أمر الإنتاج: ${order.number}', style: const TextStyle(color: AppTheme.textMuted)),
                  const SizedBox(height: 12),
                  ...lines.map((line) => _issuanceLineRow(line)),
                  if (hasDeficit) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'رصيد بعض المواد غير كافٍ للصرف؛ الصرف الاستثنائي مع عجز متاح للمدير فقط مع توثيق السبب، ويُنزَّل الرصيد تحت الصفر كإشارة لضرورة تسوية جرد.',
                              style: TextStyle(fontSize: 11.5, color: Colors.red.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (auth.isAdmin) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: reasonCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'سبب الصرف الاستثنائي *',
                          prefixIcon: Icon(Icons.gavel_rounded),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            if (!hasDeficit)
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await erp.deductPaperForOrder(order.id);
                  if (ctx.mounted && result.isSuccess) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result.message),
                        backgroundColor: result.isSuccess ? AppTheme.primaryGreen : Colors.red.shade700,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.outbox_rounded, size: 16),
                label: const Text('صرف المواد'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            if (hasDeficit && auth.isAdmin)
              ElevatedButton.icon(
                onPressed: () async {
                  final reason = reasonCtrl.text.trim();
                  if (reason.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('أدخل سبب الصرف الاستثنائي أولاً')),
                    );
                    return;
                  }
                  final result = await erp.deductPaperForOrder(
                    order.id,
                    allowDeficit: true,
                    deficitReason: reason,
                    approvedBy: auth.currentUser?.displayName,
                  );
                  if (ctx.mounted && result.isSuccess) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result.message),
                        backgroundColor: result.isSuccess ? AppTheme.primaryGreen : Colors.red.shade700,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.warning_amber_rounded, size: 16),
                label: const Text('صرف استثنائي مع عجز'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _issuanceLineRow(PaperIssuanceLine line) {
    final deficit = line.hasDeficit;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: deficit ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: deficit ? Colors.red.shade200 : Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(
            deficit ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            color: deficit ? Colors.red.shade700 : Colors.green.shade700,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              line.materialName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            'المطلوب ${line.requiredQty.toStringAsFixed(0)} / المتاح ${line.availableQty.toStringAsFixed(0)}'
            '${deficit ? ' — عجز ${line.deficit.toStringAsFixed(0)}' : ''}',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: deficit ? Colors.red.shade700 : Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

  /// حوار تسجيل هالك فعلي (للمدير): يوثق استهلاكاً إضافياً فعلياً على أمر
  /// قيد الإنتاج أو مكتمل بحركة خروج مستقلة.
  void _showActualWasteDialog(ProductionOrder order, ErpProvider erp) {
    final issuedMaterials = order.materialRequirements
        .where((material) => material.materialType == 'paper' && material.quantityIssued > 0)
        .toList();
    if (issuedMaterials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد مواد مصروفة يمكن تسجيل هالكها لهذا الأمر')),
      );
      return;
    }
    final auth = context.read<AuthProvider>();

    ProductionMaterialRequirement selectedMaterial = issuedMaterials.first;
    final quantityCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.local_fire_department_outlined, color: Colors.deepOrange),
              SizedBox(width: 8),
              Expanded(child: Text('تسجيل هالك فعلي', style: TextStyle(fontSize: 17))),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('أمر الإنتاج: ${order.number}', style: const TextStyle(color: AppTheme.textMuted)),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<ProductionMaterialRequirement>(
                    isExpanded: true,
                    initialValue: selectedMaterial,
                    decoration: const InputDecoration(
                      labelText: 'المادة المصروفة',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    items: issuedMaterials
                        .map(
                          (material) => DropdownMenuItem(
                            value: material,
                            child: Text(
                              '${material.materialName} — المصروف ${material.quantityIssued.toStringAsFixed(0)} ${material.unit}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (material) {
                      if (material == null) return;
                      setDialogState(() {
                        selectedMaterial = material;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  Builder(
                    builder: (fieldCtx) {
                      final paperMatch = erp.papers
                          .where((paper) => paper.id == selectedMaterial.materialId)
                          .toList();
                      final available =
                          paperMatch.isNotEmpty ? paperMatch.first.balance : 0.0;
                      return TextFormField(
                        controller: quantityCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'كمية الهالك الفعلي',
                          suffixText: selectedMaterial.unit,
                          helperText: 'الرصيد الحالي: ${available.toStringAsFixed(0)} ${selectedMaterial.unit}',
                          prefixIcon: const Icon(Icons.whatshot_rounded),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'سبب الهالك / ملاحظات *',
                      prefixIcon: Icon(Icons.note_alt_outlined),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'سيُنشئ النظام حركة خروج موثقة ويزيد الاستهلاك الفعلي للأمر مقابل الكمية المقدرة.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await erp.recordProductionWaste(
                  orderId: order.id,
                  materialRequirementId: selectedMaterial.id,
                  quantity: double.tryParse(quantityCtrl.text) ?? 0,
                  reason: notesCtrl.text.trim(),
                  recordedBy: auth.currentUser?.displayName,
                );
                if (ctx.mounted && result.isSuccess) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result.message),
                      backgroundColor: result.isSuccess ? AppTheme.primaryGreen : Colors.red.shade700,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.local_fire_department_outlined),
              label: const Text('تسجيل الهالك'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteOrder(ProductionOrder o, ErpProvider erp) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تأكيد الحذف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('هل أنت متأكد من حذف أمر الإنتاج ${o.number}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.blueGrey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final result = await erp.deleteProductionOrder(o.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.isSuccess ? AppTheme.primaryGreen : Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _showNewOrderDialog() {
    final erp = context.read<ErpProvider>();
    Customer? selectedCustomer = erp.customers.isNotEmpty ? erp.customers.first : null;
    ProductTemplate? selectedProduct = erp.products.isNotEmpty ? erp.products.first : null;
    MachineItem? selectedMachine = erp.machines.isNotEmpty ? erp.machines.first : null;
    PaperItem? selectedPaper = erp.papers.isNotEmpty ? erp.papers.first : null;
    final qtyCtrl = TextEditingController(text: '500');
    final sheetsCtrl = TextEditingController(text: '2000');
    final hoursCtrl = TextEditingController(text: '1.5');
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        final isMobile = MediaQuery.of(ctx).size.width < 600;

        return StatefulBuilder(
          builder: (ctx, setDialogState) => Dialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 520),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ترويسة راقية مع أيقونة وزر إغلاق
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.precision_manufacturing_rounded, color: AppTheme.primaryGreen, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'إنشاء أمر إنتاج يدوي',
                                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'تخصيص أمر التشغيل وتعيين الماكينة والمواد الخام',
                                  style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8)),
                            tooltip: 'إغلاق',
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFF1F5F9),
                              padding: const EdgeInsets.all(6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: AppTheme.borderColor),
                      const SizedBox(height: 18),

                      // العميل
                      DropdownButtonFormField<Customer>(
                        isExpanded: true,
                        initialValue: selectedCustomer,
                        decoration: const InputDecoration(
                          labelText: 'العميل',
                          prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.primaryGreen, size: 20),
                        ),
                        items: erp.customers
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c.name, overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (c) => setDialogState(() => selectedCustomer = c),
                      ),
                      const SizedBox(height: 14),

                      // المنتج والكمية
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<ProductTemplate>(
                              isExpanded: true,
                              initialValue: selectedProduct,
                              decoration: const InputDecoration(
                                labelText: 'المنتج',
                                prefixIcon: Icon(Icons.menu_book_rounded, color: AppTheme.primaryGreen, size: 20),
                              ),
                              items: erp.products
                                  .map((p) => DropdownMenuItem(
                                        value: p,
                                        child: Text(p.name, overflow: TextOverflow.ellipsis),
                                      ))
                                  .toList(),
                              onChanged: (p) => setDialogState(() => selectedProduct = p),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: qtyCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'الكمية',
                                suffixText: 'نسخة',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // الماكينة والخامة
                      if (isMobile) ...[
                        DropdownButtonFormField<MachineItem>(
                          isExpanded: true,
                          initialValue: selectedMachine,
                          decoration: const InputDecoration(
                            labelText: 'ماكينة الطباعة',
                            prefixIcon: Icon(Icons.precision_manufacturing_outlined, color: AppTheme.primaryGreen, size: 20),
                          ),
                          items: erp.machines
                              .map((m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(m.name, overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: (m) => setDialogState(() => selectedMachine = m),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<PaperItem>(
                          isExpanded: true,
                          initialValue: selectedPaper,
                          decoration: const InputDecoration(
                            labelText: 'الخامة / نوع الورق',
                            prefixIcon: Icon(Icons.inventory_2_outlined, color: AppTheme.primaryGreen, size: 20),
                          ),
                          items: erp.papers
                              .map((p) => DropdownMenuItem(
                                    value: p,
                                    child: Text(p.displayName, overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: (p) => setDialogState(() => selectedPaper = p),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<MachineItem>(
                                isExpanded: true,
                                initialValue: selectedMachine,
                                decoration: const InputDecoration(
                                  labelText: 'ماكينة الطباعة',
                                  prefixIcon: Icon(Icons.precision_manufacturing_outlined, color: AppTheme.primaryGreen, size: 20),
                                ),
                                items: erp.machines
                                    .map((m) => DropdownMenuItem(
                                          value: m,
                                          child: Text(m.name, overflow: TextOverflow.ellipsis),
                                        ))
                                    .toList(),
                                onChanged: (m) => setDialogState(() => selectedMachine = m),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<PaperItem>(
                                isExpanded: true,
                                initialValue: selectedPaper,
                                decoration: const InputDecoration(
                                  labelText: 'الخامة / نوع الورق',
                                  prefixIcon: Icon(Icons.inventory_2_outlined, color: AppTheme.primaryGreen, size: 20),
                                ),
                                items: erp.papers
                                    .map((p) => DropdownMenuItem(
                                          value: p,
                                          child: Text(p.displayName, overflow: TextOverflow.ellipsis),
                                        ))
                                    .toList(),
                                onChanged: (p) => setDialogState(() => selectedPaper = p),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),

                      // الأفراخ وساعات التشغيل
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: sheetsCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'الأفراخ المطلوبة',
                                suffixText: 'فرخ',
                                prefixIcon: Icon(Icons.layers_outlined, color: AppTheme.primaryGreen, size: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: hoursCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'ساعات التشغيل',
                                suffixText: 'ساعة',
                                prefixIcon: Icon(Icons.timer_outlined, color: AppTheme.primaryGreen, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ملاحظات أمر الإنتاج
                      TextFormField(
                        controller: notesCtrl,
                        decoration: const InputDecoration(
                          labelText: 'ملاحظات وتوجيهات التشغيل',
                          prefixIcon: Icon(Icons.note_alt_outlined, color: AppTheme.primaryGreen, size: 20),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 22),

                      // أزرار الإجراءات
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.darkSlate,
                                side: const BorderSide(color: AppTheme.borderColor, width: 1.2),
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('إلغاء', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.check_rounded, size: 18),
                              label: const Text('إنشاء أمر الإنتاج', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryGreen,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                              onPressed: () async {
                                if (selectedCustomer == null || selectedProduct == null || selectedMachine == null || selectedPaper == null) return;
                                final qty = int.tryParse(qtyCtrl.text) ?? 500;
                                final sheets = double.tryParse(sheetsCtrl.text) ?? 2000;
                                final hrs = double.tryParse(hoursCtrl.text) ?? 1.5;

                                final order = ProductionOrder(
                                  id: 'PO_${DateTime.now().millisecondsSinceEpoch}',
                                  number: erp.generateNextOrderNumber(),
                                  date: DateTime.now(),
                                  customerId: selectedCustomer!.id,
                                  customerName: selectedCustomer!.name,
                                  product: selectedProduct!.name,
                                  qty: qty,
                                  machine: selectedMachine!.name,
                                  paperName: selectedPaper!.displayName,
                                  paperId: selectedPaper!.id,
                                  sheetsRequired: sheets * 0.95,
                                  sheetsWithWaste: sheets,
                                  runHours: hrs,
                                  cost: sheets * (selectedPaper!.sheetPrice / 4) + hrs * selectedMachine!.hourlyCost,
                                  status: 'معتمد',
                                  dueDate: DateTime.now().add(const Duration(days: 3)),
                                  notes: notesCtrl.text,
                                );

                                final result = await erp.addManualProductionOrder(order);
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
      },
    );
  }
}
