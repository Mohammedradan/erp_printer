import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../providers/erp_provider.dart';
import '../providers/auth_provider.dart';
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
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    final isMobile = MediaQuery.of(context).size.width < 600;
    final underReorderCount = erp.inks.where((i) => i.isUnderReorder).length;
    final totalInkWeight = erp.inks.fold(0.0, (s, i) => s + i.balance);
    final totalInkValue = erp.inks.fold(0.0, (s, i) => s + i.totalValue);

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الهيدر الرئيسي الفخم (Hero Banner)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0F172A), // Dark slate
                  Color(0xFF1E293B),
                  Color(0xFF0F766E), // Teal/Emerald accent
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: -20,
                  bottom: -20,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 18, vertical: isMobile ? 14 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.colorize_rounded, color: Colors.cyanAccent, size: 22),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'إدارة مخزون الأحبار',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'أرصدة أحبار الطباعة (CMYK)، حركات التوريد والاستهلاك',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.75),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${totalInkWeight.toStringAsFixed(1)} كجم رصيد كلي',
                              style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (isAdmin)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'القيمة: ${AppTheme.formatCurrency(totalInkValue, erp.settings.currency)}',
                                style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                          if (underReorderCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.warning_amber_rounded, size: 13, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$underReorderCount بحاجة لطلب',
                                    style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ElevatedButton.icon(
                            onPressed: () => _showInkMoveDialog(),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('تسجيل حركة حبر', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // بطاقات كروت الأحبار
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 950;
              final isMedium = constraints.maxWidth > 650;

              if (isWide || isMedium) {
                final crossAxisCount = isWide ? 5 : 3;
                final aspectRatio = isWide ? 1.35 : 1.15;
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
                  itemBuilder: (context, idx) => _buildInkCard(erp.inks[idx], isAdmin),
                );
              }

              // وضع الجوال (Mobile): إذا كان العدد فردياً، نعرض الزوجين في شبكة 2x2 والأخير كبطاقة بعرض كامل
              final hasOddRemainder = erp.inks.length % 2 != 0;
              final gridCount = hasOddRemainder ? erp.inks.length - 1 : erp.inks.length;

              return Column(
                children: [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: gridCount,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.25,
                    ),
                    itemBuilder: (context, idx) => _buildInkCard(erp.inks[idx], isAdmin),
                  ),
                  if (hasOddRemainder) ...[
                    const SizedBox(height: 10),
                    _buildHorizontalInkCard(erp.inks.last, isAdmin),
                  ],
                ],
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
                  if (MediaQuery.of(context).size.width < 750)
                    _buildMobileInkDetails(erp.inks, isAdmin)
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                        columns: [
                          const DataColumn(label: Text('الحبر واللون', style: TextStyle(fontWeight: FontWeight.bold))),
                          const DataColumn(label: Text('الرمز', style: TextStyle(fontWeight: FontWeight.bold))),
                          const DataColumn(label: Text('النوع', style: TextStyle(fontWeight: FontWeight.bold))),
                          if (isAdmin) const DataColumn(label: Text('سعر الوحدة', style: TextStyle(fontWeight: FontWeight.bold))),
                          const DataColumn(label: Text('الرصيد الحالي', style: TextStyle(fontWeight: FontWeight.bold))),
                          const DataColumn(label: Text('حد الطلب', style: TextStyle(fontWeight: FontWeight.bold))),
                          const DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
                          if (isAdmin) const DataColumn(label: Text('قيمة المخزون', style: TextStyle(fontWeight: FontWeight.bold))),
                          const DataColumn(label: Text('المورد', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: erp.inks.map((i) {
                          return DataRow(cells: [
                            DataCell(Text(i.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Text(i.colorCode)),
                            DataCell(Text(i.kind)),
                            if (isAdmin) DataCell(Text(AppTheme.formatCurrency(i.unitPrice))),
                            DataCell(Text('${i.balance} كجم', style: TextStyle(fontWeight: FontWeight.bold, color: i.isUnderReorder ? Colors.red : Colors.black87))),
                            DataCell(Text('${i.reorderLevel}')),
                            DataCell(AppTheme.statusBadge(i.isUnderReorder ? 'إعادة طلب' : 'طبيعي')),
                            if (isAdmin) DataCell(Text(AppTheme.formatCurrency(i.totalValue), style: const TextStyle(fontWeight: FontWeight.bold))),
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
                  else if (MediaQuery.of(context).size.width < 750)
                    _buildMobileInkMoveCards(erp.inkMoves, isAdmin)
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                        columns: [
                          const DataColumn(label: Text('رقم الحركة', style: TextStyle(fontWeight: FontWeight.bold))),
                          const DataColumn(label: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold))),
                          const DataColumn(label: Text('نوع الحركة', style: TextStyle(fontWeight: FontWeight.bold))),
                          const DataColumn(label: Text('الحبر', style: TextStyle(fontWeight: FontWeight.bold))),
                          const DataColumn(label: Text('الكمية', style: TextStyle(fontWeight: FontWeight.bold))),
                          if (isAdmin) const DataColumn(label: Text('سعر الوحدة', style: TextStyle(fontWeight: FontWeight.bold))),
                          if (isAdmin) const DataColumn(label: Text('القيمة الإجمالية', style: TextStyle(fontWeight: FontWeight.bold))),
                          const DataColumn(label: Text('المرجع', style: TextStyle(fontWeight: FontWeight.bold))),
                          const DataColumn(label: Text('ملاحظات', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: erp.inkMoves.map((m) {
                          return DataRow(cells: [
                            DataCell(Text(m.number, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Text(AppTheme.formatDate(m.date))),
                            DataCell(AppTheme.statusBadge(m.moveType)),
                            DataCell(Text(m.inkName)),
                            DataCell(Text('${m.qty}')),
                            if (isAdmin) DataCell(Text(AppTheme.formatCurrency(m.unitPrice))),
                            if (isAdmin) DataCell(Text(AppTheme.formatCurrency(m.totalValue))),
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

  Widget _buildHorizontalInkCard(InkItem ink, bool isAdmin) {
    Color inkColor = Colors.black87;
    if (ink.colorCode == 'C') inkColor = Colors.cyan.shade700;
    if (ink.colorCode == 'M') inkColor = Colors.pink.shade600;
    if (ink.colorCode == 'Y') inkColor = Colors.amber.shade700;
    if (ink.colorCode == 'K' || ink.colorCode == 'Black') inkColor = Colors.grey.shade900;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: inkColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${ink.name} (${ink.kind})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  if (isAdmin)
                    Text(
                      'القيمة: ${AppTheme.formatCurrency(ink.totalValue)}',
                      style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AppTheme.statusBadge(ink.isUnderReorder ? 'إعادة طلب' : 'طبيعي'),
                const SizedBox(height: 4),
                Text(
                  '${ink.balance.toStringAsFixed(1)} كجم / علبة',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: ink.isUnderReorder ? Colors.red : AppTheme.darkSlate,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInkCard(InkItem ink, bool isAdmin) {
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
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: ink.isUnderReorder ? Colors.red : AppTheme.darkSlate,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (isAdmin)
                    Text(
                      'القيمة: ${AppTheme.formatCurrency(ink.totalValue)}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
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
  }

  Widget _buildMobileInkDetails(List<InkItem> inks, bool isAdmin) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: inks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, idx) {
        final i = inks[idx];
        Color inkColor = Colors.black87;
        if (i.colorCode == 'C') inkColor = Colors.cyan.shade700;
        if (i.colorCode == 'M') inkColor = Colors.pink.shade600;
        if (i.colorCode == 'Y') inkColor = Colors.amber.shade700;
        if (i.colorCode == 'K' || i.colorCode == 'Black') inkColor = Colors.grey.shade900;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Row(
            children: [
              CircleAvatar(radius: 8, backgroundColor: inkColor),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(i.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('حد الطلب: ${i.reorderLevel} كجم • المورد: ${i.supplier ?? '—'}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${i.balance} كجم',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: i.isUnderReorder ? Colors.red : AppTheme.darkSlate)),
                  if (isAdmin)
                    Text(AppTheme.formatCurrency(i.totalValue),
                        style: const TextStyle(fontSize: 11, color: AppTheme.primaryGreen, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileInkMoveCards(List<InkMove> moves, bool isAdmin) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: moves.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final m = moves[idx];
        final isSupply = m.moveType.contains('توريد');
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(m.number, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkSlate)),
                  AppTheme.statusBadge(m.moveType),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${m.inkName} • ${AppTheme.formatDate(m.date)}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${isSupply ? '+' : '-'}${m.qty} كجم',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isSupply ? Colors.green.shade700 : Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (isAdmin)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('سعر الوحدة: ${AppTheme.formatCurrency(m.unitPrice)}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    Text('الإجمالي: ${AppTheme.formatCurrency(m.totalValue)}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.darkSlate)),
                  ],
                ),
              if (m.reference != null && m.reference!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('المرجع: ${m.reference}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showInkMoveDialog() {
    final erp = context.read<ErpProvider>();
    final isAdmin = context.read<AuthProvider>().isAdmin;
    InkItem? selectedInk = erp.inks.isNotEmpty ? erp.inks.first : null;
    String moveType = 'دخول';
    final qtyCtrl = TextEditingController(text: '5');
    final priceCtrl = TextEditingController(text: isAdmin ? '${selectedInk?.unitPrice.toInt() ?? 0}' : '0');
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
                        if (isAdmin && i != null) priceCtrl.text = '${i.unitPrice.toInt()}';
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
                      if (isAdmin) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: priceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'سعر الوحدة'),
                          ),
                        ),
                      ],
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
                final price = isAdmin ? (double.tryParse(priceCtrl.text) ?? selectedInk!.unitPrice) : selectedInk!.unitPrice;

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
