import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../providers/erp_provider.dart';
import '../theme/app_theme.dart';

class MasterDataView extends StatefulWidget {
  const MasterDataView({super.key});

  @override
  State<MasterDataView> createState() => _MasterDataViewState();
}

class _MasterDataViewState extends State<MasterDataView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final erp = context.watch<ErpProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // شريط العنوان
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'البيانات المرجعية وقوالب المنتجات',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'الماكينات، قوالب المنتجات الافتراضية، وخدمات التشطيب (تطابق شيتات الإكسل)',
                      style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // شريط التبويبات
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppTheme.primaryGreen,
              unselectedLabelColor: AppTheme.textMuted,
              indicatorColor: AppTheme.primaryGreen,
              tabs: const [
                Tab(icon: Icon(Icons.precision_manufacturing), text: 'الماكينات (شيت الماكينات)'),
                Tab(icon: Icon(Icons.auto_stories), text: 'قوالب المنتجات (شيت المنتجات)'),
                Tab(icon: Icon(Icons.content_cut), text: 'خدمات التشطيب (شيت التشطيبات)'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 600,
            child: TabBarView(
              controller: _tabController,
              children: [
                // تبويب 1: الماكينات
                _buildMachinesTab(erp),
                // تبويب 2: قوالب المنتجات
                _buildProductsTab(erp),
                // تبويب 3: التشطيبات
                _buildFinishingsTab(erp),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMachinesTab(ErpProvider erp) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
            columns: const [
              DataColumn(label: Text('اسم الماكينة', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('النوع', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('الهالك %', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('تكلفة التشغيل/ساعة', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('السرعة (فرخ/ساعة)', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('تعديل', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: erp.machines.map((m) {
              return DataRow(cells: [
                DataCell(Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(m.kind)),
                DataCell(Text('${m.wastePct}%')),
                DataCell(Text(AppTheme.formatCurrency(m.hourlyCost))),
                DataCell(Text('${m.speedPerHour}')),
                DataCell(AppTheme.statusBadge(m.status)),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                    onPressed: () => _showEditMachineDialog(m),
                  ),
                ),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildProductsTab(ErpProvider erp) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
            columns: const [
              DataColumn(label: Text('اسم المنتج', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('الفئة', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('صفحات/فرخ 50x35', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('نوع التجليد', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('الماكينة الافتراضية', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('الخامة الافتراضية', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('تعديل', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: erp.products.map((p) {
              return DataRow(cells: [
                DataCell(Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(p.category)),
                DataCell(Text('${p.pagesPerSheet}')),
                DataCell(Text(p.binding)),
                DataCell(Text(p.defaultMachine)),
                DataCell(Text('${p.defaultPaperCategory} ${p.defaultPaperType}')),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                    onPressed: () => _showEditProductDialog(p),
                  ),
                ),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildFinishingsTab(ErpProvider erp) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
            columns: const [
              DataColumn(label: Text('الخدمة (التشطيب)', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('السعر المحدد', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('وحدة الاحتساب', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('تعديل السعر', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: erp.finishings.map((f) {
              return DataRow(cells: [
                DataCell(Text(f.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(AppTheme.formatCurrency(f.price))),
                DataCell(Text(f.unit)),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                    onPressed: () => _showEditFinishingDialog(f),
                  ),
                ),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showEditMachineDialog(MachineItem m) {
    final erp = context.read<ErpProvider>();
    final costCtrl = TextEditingController(text: '${m.hourlyCost.toInt()}');
    final wasteCtrl = TextEditingController(text: '${m.wastePct}');
    final speedCtrl = TextEditingController(text: '${m.speedPerHour}');
    String status = m.status;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('تعديل ماكينة: ${m.name}'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: costCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'تكلفة الساعة (ريال/ساعة)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: wasteCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'الهالك %'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: speedCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'السرعة (فرخ/ساعة)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'الحالة'),
                  items: const [
                    DropdownMenuItem(value: 'نشطة', child: Text('نشطة')),
                    DropdownMenuItem(value: 'موقوفة', child: Text('موقوفة')),
                  ],
                  onChanged: (s) => setDialogState(() => status = s ?? 'نشطة'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                m.hourlyCost = double.tryParse(costCtrl.text) ?? m.hourlyCost;
                m.wastePct = double.tryParse(wasteCtrl.text) ?? m.wastePct;
                m.speedPerHour = int.tryParse(speedCtrl.text) ?? m.speedPerHour;
                m.status = status;
                await erp.updateMachine(m);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('حفظ التعديل'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProductDialog(ProductTemplate p) {
    final erp = context.read<ErpProvider>();
    final ppsCtrl = TextEditingController(text: '${p.pagesPerSheet}');
    final bindingCtrl = TextEditingController(text: p.binding);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تعديل قالب: ${p.name}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: ppsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'صفحات الفرخ 50x35'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: bindingCtrl,
                decoration: const InputDecoration(labelText: 'نوع التجليد الافتراضي'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              p.pagesPerSheet = int.tryParse(ppsCtrl.text) ?? p.pagesPerSheet;
              p.binding = bindingCtrl.text;
              await erp.updateProduct(p);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('حفظ التعديل'),
          ),
        ],
      ),
    );
  }

  void _showEditFinishingDialog(FinishingItem f) {
    final erp = context.read<ErpProvider>();
    final priceCtrl = TextEditingController(text: '${f.price.toInt()}');
    String unit = f.unit;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('تعديل سعر خدمة: ${f.name}'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'السعر (ريال)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: unit,
                  decoration: const InputDecoration(labelText: 'الوحدة'),
                  items: const [
                    DropdownMenuItem(value: 'للعملية', child: Text('للعملية (مقطوع)')),
                    DropdownMenuItem(value: 'للألف', child: Text('للألف فرخ / صفحة')),
                    DropdownMenuItem(value: 'للقطعة', child: Text('للقطعة / النسخة')),
                  ],
                  onChanged: (u) => setDialogState(() => unit = u ?? 'للعملية'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                f.price = double.tryParse(priceCtrl.text) ?? f.price;
                f.unit = unit;
                await erp.updateFinishing(f);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('حفظ التعديل'),
            ),
          ],
        ),
      ),
    );
  }
}
