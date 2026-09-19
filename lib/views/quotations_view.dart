import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../providers/erp_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final erp = context.watch<ErpProvider>();

    var filtered = erp.quotations.where((q) {
      final matchesStatus = _filterStatus == 'الكل' || q.status == _filterStatus;
      final matchesSearch = _searchQuery.isEmpty ||
          q.number.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          q.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          q.product.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesStatus && matchesSearch;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // شريط العنوان والإجراءات
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
                    'أرشيف عروض الأسعار',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'إدارة ومتابعة عروض الأسعار وربطها بمحرك التسعير وأوامر الإنتاج',
                    style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  if (widget.onNavigate != null) widget.onNavigate!(1); // محرك التسعير
                },
                icon: const Icon(Icons.calculate_outlined, size: 18),
                label: const Text('تسعير وإنشاء عرض جديد'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // شريط الفلاتر والبحث
          Card(
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
                            hintText: 'بحث برقم العرض أو العميل...',
                            prefixIcon: Icon(Icons.search, size: 20),
                            isDense: true,
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Text('الحالة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButton<String>(
                                value: _filterStatus,
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem(value: 'الكل', child: Text('جميع الحالات')),
                                  DropdownMenuItem(value: 'مسودة', child: Text('مسودة')),
                                  DropdownMenuItem(value: 'معتمد', child: Text('معتمد')),
                                  DropdownMenuItem(value: 'ملغي', child: Text('ملغي')),
                                ],
                                onChanged: (val) => setState(() => _filterStatus = val!),
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
                            hintText: 'بحث برقم العرض أو اسم العميل أو المنتج...',
                            prefixIcon: Icon(Icons.search, size: 20),
                            isDense: true,
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text('الحالة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _filterStatus,
                        items: const [
                          DropdownMenuItem(value: 'الكل', child: Text('جميع الحالات')),
                          DropdownMenuItem(value: 'مسودة', child: Text('مسودة')),
                          DropdownMenuItem(value: 'معتمد', child: Text('معتمد')),
                          DropdownMenuItem(value: 'ملغي', child: Text('ملغي')),
                        ],
                        onChanged: (val) => setState(() => _filterStatus = val!),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // جدول عروض الأسعار
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('لا توجد عروض أسعار مطابقة للبحث')),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                        columns: const [
                          DataColumn(label: Text('رقم العرض', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('العميل', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('المنتج', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('الكمية', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('الورق والماكينة', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('سعر الوحدة', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('التكلفة الكلية', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('قيمة العرض', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('الربح', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: filtered.map((q) {
                          return DataRow(cells: [
                            DataCell(Text(q.number, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen))),
                            DataCell(Text(AppTheme.formatDate(q.date))),
                            DataCell(Text(q.customerName)),
                            DataCell(Text(q.product)),
                            DataCell(Text('${q.qty}')),
                            DataCell(Text('${q.paper} / ${q.machine}')),
                            DataCell(Text(AppTheme.formatCurrency(q.unitPrice))),
                            DataCell(Text(AppTheme.formatCurrency(q.totalCost))),
                            DataCell(Text(AppTheme.formatCurrency(q.quoteAmount), style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Text(AppTheme.formatCurrency(q.profit), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
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
                                    onPressed: () async {
                                      final result = await erp.updateQuotationStatus(q.id, 'معتمد');
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
                                  onSelected: (val) async {
                                    final result = await erp.updateQuotationStatus(q.id, val);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(result.message),
                                          backgroundColor: result.isSuccess ? AppTheme.primaryGreen : Colors.red.shade700,
                                        ),
                                      );
                                    }
                                  },
                                  itemBuilder: (ctx) {
                                    switch (q.status) {
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
                                      default:
                                        return const <PopupMenuEntry<String>>[];
                                    }
                                  },
                                ),
                              ],
                            )),
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

  void _showQuoteDetails(Quotation q) {
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
                          color: AppTheme.primaryGreen.withOpacity(0.12),
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
                  _buildInfoRow('سعر الوحدة المقترح:', AppTheme.formatCurrency(q.unitPrice)),
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
                            Text(AppTheme.formatCurrency(q.totalCost), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
                              AppTheme.formatCurrency(q.quoteAmount),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                            ),
                          ],
                        ),
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
                              AppTheme.formatCurrency(q.profit),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                            ),
                          ],
                        ),
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
                            settings: context.read<ErpProvider>().settings,
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
                            settings: context.read<ErpProvider>().settings,
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
