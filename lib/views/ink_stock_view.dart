import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../providers/erp_provider.dart';
import '../theme/app_theme.dart';

class InkStockView extends StatefulWidget {
  const InkStockView({super.key});

  @override
  State<InkStockView> createState() => _InkStockViewState();
}

class _InkStockViewState extends State<InkStockView> {
  @override
  Widget build(BuildContext context) {
    final erp = context.watch<ErpProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
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
                  const Text(
                    'إدارة مخزون الأحبار',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'أرصدة أحبار الطباعة (CMYK)، حركات التوريد والاستهلاك',
                    style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showInkMoveDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('تسجيل حركة حبر جديدة'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // بطاقات كروت الأحبار الـ 5 الملونة (CMYK)
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 950 ? 5 : (constraints.maxWidth > 650 ? 3 : 2);
              final aspectRatio = constraints.maxWidth > 950 ? 1.35 : 1.15;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: erp.inks.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: aspectRatio,
                ),
                itemBuilder: (context, idx) {
                  final ink = erp.inks[idx];
                  Color inkColor = Colors.black87;
                  if (ink.colorCode == 'C') inkColor = Colors.cyan.shade700;
                  if (ink.colorCode == 'M') inkColor = Colors.pink.shade600;
                  if (ink.colorCode == 'Y') inkColor = Colors.amber.shade700;
                  if (ink.colorCode == 'K' || ink.colorCode == 'Black') inkColor = Colors.grey.shade900;

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: inkColor,
                              ),
                              AppTheme.statusBadge(ink.isUnderReorder ? 'إعادة طلب' : 'طبيعي'),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  '${ink.name} (${ink.kind})',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '${ink.balance.toStringAsFixed(1)} كجم / علبة',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: ink.isUnderReorder ? Colors.red : AppTheme.darkSlate,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'القيمة: ${AppTheme.formatCurrency(ink.totalValue)}',
                                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 20),

          // جدول مخزون الأحبار
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.colorize, color: AppTheme.primaryGreen),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text('جدول تفاصيل مخزون الأحبار', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ],
                  ),
                  const Divider(),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                      columns: const [
                        DataColumn(label: Text('الحبر واللون', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('الرمز', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('النوع', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('سعر الوحدة', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('الرصيد الحالي', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('حد الطلب', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('قيمة المخزون', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('المورد', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: erp.inks.map((i) {
                        return DataRow(cells: [
                          DataCell(Text(i.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(i.colorCode)),
                          DataCell(Text(i.kind)),
                          DataCell(Text(AppTheme.formatCurrency(i.unitPrice))),
                          DataCell(Text('${i.balance} كجم', style: TextStyle(fontWeight: FontWeight.bold, color: i.isUnderReorder ? Colors.red : Colors.black87))),
                          DataCell(Text('${i.reorderLevel}')),
                          DataCell(AppTheme.statusBadge(i.isUnderReorder ? 'إعادة طلب' : 'طبيعي')),
                          DataCell(Text(AppTheme.formatCurrency(i.totalValue), style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(i.supplier ?? '—')),
                        ]);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // جدول حركات الأحبار
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.history, color: AppTheme.accentGold),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text('سجل حركات الأحبار (شيت حركات_الأحبار)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ],
                  ),
                  const Divider(),
                  if (erp.inkMoves.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('لا توجد حركات أحبار مسجلة بعد')),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                        columns: const [
                          DataColumn(label: Text('رقم الحركة', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('نوع الحركة', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('الحبر', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('الكمية', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('سعر الوحدة', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('القيمة الإجمالية', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('المرجع', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('ملاحظات', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: erp.inkMoves.map((m) {
                          return DataRow(cells: [
                            DataCell(Text(m.number, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Text(AppTheme.formatDate(m.date))),
                            DataCell(AppTheme.statusBadge(m.moveType)),
                            DataCell(Text(m.inkName)),
                            DataCell(Text('${m.qty}')),
                            DataCell(Text(AppTheme.formatCurrency(m.unitPrice))),
                            DataCell(Text(AppTheme.formatCurrency(m.totalValue))),
                            DataCell(Text(m.reference ?? '—')),
                            DataCell(Text(m.notes ?? '—')),
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

  void _showInkMoveDialog() {
    final erp = context.read<ErpProvider>();
    InkItem? selectedInk = erp.inks.isNotEmpty ? erp.inks.first : null;
    String moveType = 'دخول';
    final qtyCtrl = TextEditingController(text: '5');
    final priceCtrl = TextEditingController(text: '${selectedInk?.unitPrice.toInt() ?? 0}');
    final refCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('تسجيل حركة حبر جديدة'),
          content: SizedBox(
            width: MediaQuery.of(ctx).size.width < 500 ? double.maxFinite : 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<InkItem>(
                    isExpanded: true,
                    initialValue: selectedInk,
                    decoration: const InputDecoration(labelText: 'اختر الحبر'),
                    items: erp.inks.map((i) => DropdownMenuItem(value: i, child: Text('${i.name} (${i.kind})', overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (i) {
                      setDialogState(() {
                        selectedInk = i;
                        if (i != null) priceCtrl.text = '${i.unitPrice.toInt()}';
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: moveType,
                    decoration: const InputDecoration(labelText: 'نوع الحركة'),
                    items: const [
                      DropdownMenuItem(value: 'دخول', child: Text('دخول (توريد أحبار)', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'خروج', child: Text('خروج (استهلاك طباعة)', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'تسوية', child: Text('تسوية جردية', overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (m) => setDialogState(() => moveType = m ?? 'دخول'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: qtyCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'الكمية (علبة/كجم)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'سعر الوحدة'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: refCtrl,
                    decoration: const InputDecoration(labelText: 'المرجع'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(labelText: 'ملاحظات'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (selectedInk == null) return;
                final qty = double.tryParse(qtyCtrl.text) ?? 0;
                final price = double.tryParse(priceCtrl.text) ?? selectedInk!.unitPrice;

                final result = await erp.addInkMove(
                  moveType: moveType,
                  inkId: selectedInk!.id,
                  qty: qty,
                  unitPrice: price,
                  reference: refCtrl.text,
                  notes: notesCtrl.text,
                );

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
              child: const Text('حفظ الحركة'),
            ),
          ],
        ),
      ),
    );
  }
}
