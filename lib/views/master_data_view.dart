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
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final erp = context.watch<ErpProvider>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 14 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // شريط العنوان
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isMobile ? 8 : 10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.settings_suggest_rounded, color: AppTheme.primaryGreen, size: isMobile ? 22 : 26),
                  ),
                  SizedBox(width: isMobile ? 10 : 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'البيانات المرجعية وقوالب المنتجات',
                          style: TextStyle(
                            fontSize: isMobile ? 18 : 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkSlate,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'الماكينات، قوالب المنتجات الافتراضية، وخدمات التشطيب (تطابق شيتات الإكسل)',
                          style: TextStyle(fontSize: isMobile ? 11.5 : 13, color: AppTheme.textMuted),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 12 : 18),

              // شريط التبويبات المتجاوب
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: AppTheme.primaryGreen,
                  unselectedLabelColor: AppTheme.textMuted,
                  indicatorColor: AppTheme.primaryGreen,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  tabs: [
                    Tab(
                      icon: const Icon(Icons.precision_manufacturing_rounded, size: 19),
                      text: 'الماكينات (${erp.machines.length})',
                    ),
                    Tab(
                      icon: const Icon(Icons.auto_stories_rounded, size: 19),
                      text: 'قوالب المنتجات (${erp.products.length})',
                    ),
                    Tab(
                      icon: const Icon(Icons.content_cut_rounded, size: 19),
                      text: 'خدمات التشطيب (${erp.finishings.length})',
                    ),
                  ],
                ),
              ),
              SizedBox(height: isMobile ? 12 : 16),

              // محتوى التبويب النشط (يتمدد طبيعياً بدون هدر للمساحة)
              if (_tabController.index == 0)
                _buildMachinesTab(erp, isMobile)
              else if (_tabController.index == 1)
                _buildProductsTab(erp, isMobile)
              else
                _buildFinishingsTab(erp, isMobile),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // تبويب 1: الماكينات
  // ==========================================
  Widget _buildMachinesTab(ErpProvider erp, bool isMobile) {
    if (isMobile) {
      return Column(
        children: erp.machines.map((m) => _buildMachineMobileCard(m)).toList(),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.borderColor),
      ),
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
                    icon: const Icon(Icons.edit_rounded, size: 18, color: Colors.blue),
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

  Widget _buildMachineMobileCard(MachineItem m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.precision_manufacturing_rounded, color: Color(0xFF0F766E), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        m.name,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              AppTheme.statusBadge(m.status),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // شبكة مواصفات الماكينة
          Row(
            children: [
              Expanded(
                child: _buildParamItem('النوع:', m.kind),
              ),
              Expanded(
                child: _buildParamItem('الهالك:', '${m.wastePct}%', isHighlight: true),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildParamItem('تكلفة الساعة:', AppTheme.formatCurrency(m.hourlyCost)),
              ),
              Expanded(
                child: _buildParamItem('السرعة الإنتاجية:', '${m.speedPerHour} فرخ/س'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showEditMachineDialog(m),
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: const Text('تعديل معايير الماكينة'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryGreen,
                side: BorderSide(color: AppTheme.primaryGreen.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // تبويب 2: قوالب المنتجات
  // ==========================================
  Widget _buildProductsTab(ErpProvider erp, bool isMobile) {
    if (isMobile) {
      return Column(
        children: erp.products.map((p) => _buildProductMobileCard(p)).toList(),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.borderColor),
      ),
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
                    icon: const Icon(Icons.edit_rounded, size: 18, color: Colors.blue),
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

  Widget _buildProductMobileCard(ProductTemplate p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.auto_stories_rounded, color: Color(0xFF0284C7), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        p.name,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  p.category,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _buildParamItem('صفحات/فرخ:', '${p.pagesPerSheet} صفحة', isHighlight: true),
              ),
              Expanded(
                child: _buildParamItem('التجليد:', p.binding),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildParamItem('الماكينة:', p.defaultMachine),
              ),
              Expanded(
                child: _buildParamItem('الخامة:', '${p.defaultPaperCategory} ${p.defaultPaperType}'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showEditProductDialog(p),
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: const Text('تعديل قالب المنتج'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0284C7),
                side: BorderSide(color: const Color(0xFF0284C7).withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // تبويب 3: خدمات التشطيب
  // ==========================================
  Widget _buildFinishingsTab(ErpProvider erp, bool isMobile) {
    if (isMobile) {
      return Column(
        children: erp.finishings.map((f) => _buildFinishingMobileCard(f)).toList(),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.borderColor),
      ),
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
                    icon: const Icon(Icons.edit_rounded, size: 18, color: Colors.blue),
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

  Widget _buildFinishingMobileCard(FinishingItem f) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFD97706).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.content_cut_rounded, color: Color(0xFFD97706), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f.name,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                ),
                const SizedBox(height: 2),
                Text(
                  'وحدة الحساب: ${f.unit}',
                  style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                AppTheme.formatCurrency(f.price),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
              ),
              const SizedBox(height: 4),
              IconButton(
                icon: const Icon(Icons.edit_rounded, size: 18, color: Colors.blue),
                visualDensity: VisualDensity.compact,
                onPressed: () => _showEditFinishingDialog(f),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParamItem(String label, String value, {bool isHighlight = false}) {
    return Text.rich(
      TextSpan(
        text: '$label ',
        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
        children: [
          TextSpan(
            text: value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              color: isHighlight ? AppTheme.primaryGreen : AppTheme.darkSlate,
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
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
