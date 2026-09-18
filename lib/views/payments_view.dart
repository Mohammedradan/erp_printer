import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../providers/erp_provider.dart';
import '../theme/app_theme.dart';

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
                    'سجل المدفوعات وسندات القبض',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'سندات القبض والتحصيلات وتحديث حسابات الذمم تلقائياً',
                    style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddPaymentDialog(),
                icon: const Icon(Icons.receipt_long, size: 18),
                label: const Text('سند قبض جديد'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // كرت الإجمالي
          Card(
            color: const Color(0xFFF8FAFC),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.payments, color: Colors.green, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('إجمالي التحصيلات المسجلة بالسندات', style: TextStyle(fontSize: 12, color: AppTheme.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            AppTheme.formatCurrency(totalPaid, erp.settings.currency),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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

          // جدول السندات
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('لا توجد سندات قبض مسجلة')),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
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
                            DataCell(Text(p.number, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen))),
                            DataCell(Text(AppTheme.formatDate(p.date))),
                            DataCell(Text(p.customerName, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Text(AppTheme.formatCurrency(p.amount), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                            DataCell(Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(4)),
                              child: Text(p.paymentMethod, style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
                            )),
                            DataCell(Text(p.reference ?? '—')),
                            DataCell(Text(p.notes ?? '—')),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.print_outlined, size: 18, color: Colors.blueGrey),
                                tooltip: 'طباعة سند القبض',
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('طباعة سند القبض ${p.number}')),
                                  );
                                },
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
          backgroundColor: Colors.white,
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
                            color: AppTheme.primaryGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.receipt_long_rounded, color: AppTheme.primaryGreen, size: 24),
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
                        child: Text('${c.name} (الذمة: ${AppTheme.formatCurrency(c.currentBalance)})', overflow: TextOverflow.ellipsis),
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

                              await erp.recordPayment(
                                customerId: selectedCustomer!.id,
                                amount: amt,
                                paymentMethod: method,
                                reference: refCtrl.text,
                                notes: notesCtrl.text,
                              );

                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تم حفظ السند وتحديث رصيد العميل بنجاح!')),
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
