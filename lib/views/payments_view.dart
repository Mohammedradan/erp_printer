import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../providers/erp_provider.dart';
import '../theme/app_theme.dart';
import '../services/pdf_export_service.dart';
import '../widgets/erp_components.dart';

class PaymentsView extends StatefulWidget {
  const PaymentsView({super.key});

  @override
  State<PaymentsView> createState() => _PaymentsViewState();
}

class _PaymentsViewState extends State<PaymentsView> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final erp = context.watch<ErpProvider>();

    final filtered = erp.payments.where((p) {
      return _searchQuery.isEmpty ||
          p.number.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p.reference != null && p.reference!.toLowerCase().contains(_searchQuery.toLowerCase()));
    }).toList();

    final totalPaid = erp.payments.fold(0.0, (s, p) => s + p.amount);

    final isMobile = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ErpPageHeader(
            title: 'المدفوعات وسندات القبض',
            subtitle: 'سجل التحصيلات وربطها بحسابات العملاء مع إمكانية طباعة السند',
            icon: Icons.receipt_long_outlined,
            actions: [
              ElevatedButton.icon(
                onPressed: _showAddPaymentDialog,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('سند قبض جديد'),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // مؤشرات التحصيل والسندات المسجلة
          if (isMobile) ...[
            ErpMetricCard(
              label: 'إجمالي التحصيلات',
              value: AppTheme.formatCurrency(totalPaid, erp.settings.currency),
              helper: '${erp.payments.length} سند مسجل',
              icon: Icons.payments_outlined,
              accent: AppTheme.success,
            ),
            const SizedBox(height: 10),
            ErpMetricCard(
              label: 'عدد السندات',
              value: '${erp.payments.length}',
              helper: 'سند قبض',
              icon: Icons.receipt_long_outlined,
              accent: AppTheme.info,
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: ErpMetricCard(
                    label: 'إجمالي التحصيلات',
                    value: AppTheme.formatCurrency(totalPaid, erp.settings.currency),
                    helper: '${erp.payments.length} سند مسجل',
                    icon: Icons.payments_outlined,
                    accent: AppTheme.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ErpMetricCard(
                    label: 'عدد السندات',
                    value: '${erp.payments.length}',
                    helper: 'سند قبض',
                    icon: Icons.receipt_long_outlined,
                    accent: AppTheme.info,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),

          // شريط البحث
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'بحث برقم السند، اسم العميل، أو المرجع...',
                  prefixIcon: Icon(Icons.search, size: 20),
                  isDense: true,
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // جدول السندات أو كروت الجوال
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (filtered.isEmpty)
                    ErpEmptyState(
                      title: erp.payments.isEmpty ? 'لا توجد سندات قبض بعد' : 'لا توجد نتائج مطابقة',
                      message: erp.payments.isEmpty
                          ? 'ستظهر هنا التحصيلات التي يتم تسجيلها من شاشة سند القبض.'
                          : 'جرّب تعديل كلمات البحث للعثور على السند المطلوب.',
                      icon: Icons.receipt_long_outlined,
                    )
                  else if (MediaQuery.sizeOf(context).width < 1100)
                    _buildMobilePaymentCards(filtered, erp)
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(AppTheme.surfaceSecondary),
                        columns: const [
                          DataColumn(label: Text('رقم السند', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('العميل', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('المبلغ المسدد', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('طريقة الدفع', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('المرجع / رقم الحوالة', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('ملاحظات', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: filtered.map((p) {
                          return DataRow(cells: [
                            DataCell(Text(p.number, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryLight))),
                            DataCell(Text(AppTheme.formatDate(p.date))),
                            DataCell(Text(p.customerName, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Text(AppTheme.formatCurrency(p.amount, erp.settings.currency), style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold))),
                            DataCell(Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: AppTheme.infoSurface, borderRadius: BorderRadius.circular(4)),
                              child: Text(p.paymentMethod, style: const TextStyle(color: AppTheme.info, fontSize: 12, fontWeight: FontWeight.bold)),
                            )),
                            DataCell(Text(p.reference ?? '—')),
                            DataCell(Text(p.notes ?? '—')),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.print_outlined, size: 18, color: AppTheme.textSecondary),
                                tooltip: 'طباعة سند القبض',
                                onPressed: () => _printReceipt(p, erp),
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

  Widget _buildMobilePaymentCards(List<PaymentRecord> filtered, ErpProvider erp) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final p = filtered[index];
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الصف العلوي: رقم السند والتاريخ وطريقة الدفع
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.receipt_long_rounded, size: 16, color: AppTheme.primaryLight),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.number,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryLight),
                          ),
                          Text(
                            AppTheme.formatDate(p.date),
                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.infoSurface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Text(
                      p.paymentMethod,
                      style: const TextStyle(color: AppTheme.info, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppTheme.surfaceSecondary),
              const SizedBox(height: 10),

              // العميل والمبلغ
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('العميل', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        const SizedBox(height: 2),
                        Text(
                          p.customerName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.darkSlate),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('المبلغ المسدد', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                      const SizedBox(height: 2),
                      Text(
                        AppTheme.formatCurrency(p.amount, erp.settings.currency),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.success),
                      ),
                    ],
                  ),
                ],
              ),

              if ((p.reference != null && p.reference!.isNotEmpty) || (p.notes != null && p.notes!.isNotEmpty)) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSecondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (p.reference != null && p.reference!.isNotEmpty)
                        Text(
                          'المرجع: ${p.reference}',
                          style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                        ),
                      if (p.notes != null && p.notes!.isNotEmpty)
                        Text(
                          'ملاحظات: ${p.notes}',
                          style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                        ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 10),
              // زر الطباعة
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => _printReceipt(p, erp),
                  icon: const Icon(Icons.print_outlined, size: 14, color: AppTheme.darkSlate),
                  label: const Text('طباعة السند', style: TextStyle(fontSize: 12, color: AppTheme.darkSlate)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    side: const BorderSide(color: AppTheme.borderColor),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _printReceipt(PaymentRecord payment, ErpProvider erp) async {
    try {
      await PdfExportService.printOrPreviewPaymentReceipt(
        context,
        payment: payment,
        settings: erp.settings,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذرت معاينة سند القبض: $error'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  void _showAddPaymentDialog() {
    final erp = context.read<ErpProvider>();
    Customer? selectedCustomer = erp.customers.isNotEmpty ? erp.customers.first : null;
    final amountCtrl = TextEditingController(text: '50000');
    String method = 'نقدي';
    final refCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: AppTheme.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
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
                            color: AppTheme.primaryLight.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.receipt_long_rounded, color: AppTheme.primaryLight, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'تسجيل سند قبض جديد',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'إثبات سداد دفعة وتحديث رصيد العميل تلقائياً',
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

                    DropdownButtonFormField<Customer>(
                      isExpanded: true,
                      initialValue: selectedCustomer,
                      decoration: const InputDecoration(
                        labelText: 'اختر العميل',
                        prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
                      ),
                      items: erp.customers.map((c) => DropdownMenuItem(
                        value: c,
                        child: Text('${c.name} (الذمة: ${AppTheme.formatCurrency(c.currentBalance, erp.settings.currency)})', overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (c) => setDialogState(() => selectedCustomer = c),
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'المبلغ المقبوض',
                        prefixIcon: Icon(Icons.payments_outlined, size: 18),
                      ),
                    ),
                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: method,
                      decoration: const InputDecoration(
                        labelText: 'طريقة القبض',
                        prefixIcon: Icon(Icons.account_balance_wallet_outlined, size: 18),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'نقدي', child: Text('نقدي', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'تحويل بنكي', child: Text('تحويل بنكي / صرافة', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'شيك', child: Text('شيك', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'آجل', child: Text('آجل / تسوية', overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (m) => setDialogState(() => method = m ?? 'نقدي'),
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: refCtrl,
                      decoration: const InputDecoration(
                        labelText: 'المرجع / رقم الإشعار أو الحوالة',
                        prefixIcon: Icon(Icons.confirmation_number_outlined, size: 18),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظات وتفاصيل إضافية',
                        prefixIcon: Icon(Icons.note_alt_outlined, size: 18),
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
                              if (selectedCustomer == null) return;
                              final amt = double.tryParse(amountCtrl.text) ?? 0;
                              if (amt <= 0) return;

                              final result = await erp.recordPayment(
                                customerId: selectedCustomer!.id,
                                amount: amt,
                                paymentMethod: method,
                                reference: refCtrl.text,
                                notes: notesCtrl.text,
                              );

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
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text('حفظ السند'),
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
}
