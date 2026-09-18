import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../providers/erp_provider.dart';
import '../theme/app_theme.dart';

class PriceManagementView extends StatefulWidget {
  final Function(int)? onNavigate;
  final int initialTab;

  const PriceManagementView({
    super.key,
    this.onNavigate,
    this.initialTab = 0,
  });

  @override
  State<PriceManagementView> createState() => _PriceManagementViewState();
}

class _PriceManagementViewState extends State<PriceManagementView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // فلاتر الورق
  String _selectedPaperCategory = 'الكل';
  final TextEditingController _paperSearchCtrl = TextEditingController();

  // تحكم الثوابت
  late TextEditingController _platePriceCtrl;
  late TextEditingController _marginCtrl;
  late TextEditingController _taxCtrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 3),
    );
    final s = context.read<ErpProvider>().settings;
    _platePriceCtrl = TextEditingController(text: s.defaultPlatePrice.toStringAsFixed(0));
    _marginCtrl = TextEditingController(text: s.defaultProfitMarginPct.toStringAsFixed(0));
    _taxCtrl = TextEditingController(text: s.taxPct.toStringAsFixed(0));
  }

  @override
  void didUpdateWidget(covariant PriceManagementView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _tabController.animateTo(widget.initialTab.clamp(0, 3));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _paperSearchCtrl.dispose();
    _platePriceCtrl.dispose();
    _marginCtrl.dispose();
    _taxCtrl.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isSuccess ? Icons.check_circle_outline : Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess ? AppTheme.primaryGreen : AppTheme.darkSlate,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
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
                    'إدارة الأسعار وتكاليف التشغيل',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'تعديل أسعار الورق والخامات، الماكينات وسرعاتها، نسب الهالك، التشطيبات، والزنكات بمزامنة حية فورية',
                    style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  ),
                ],
              ),
              if (widget.onNavigate != null)
                ElevatedButton.icon(
                  onPressed: () => widget.onNavigate!(1), // التوجه لمحرك التسعير
                  icon: const Icon(Icons.calculate_outlined, size: 18),
                  label: const Text('تجربة الأسعار في محرك التسعير'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // تنبيه المزامنة الحية
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              border: Border.all(color: const Color(0xFFBBF7D0)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.sync, color: AppTheme.primaryGreen, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'مزامنة حية نشطة: أي تعديل تحفظه هنا ينعكس تلقائياً في نفس اللحظة على جميع الحسابات الجديدة في محرك التسعير.',
                    style: TextStyle(fontSize: 13, color: Colors.green.shade900, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // شريط التبويبات
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
              tabs: const [
                Tab(icon: Icon(Icons.description_outlined), text: 'أسعار الورق والخامات'),
                Tab(icon: Icon(Icons.precision_manufacturing_outlined), text: 'الماكينات (الساعة والسرعة والهالك)'),
                Tab(icon: Icon(Icons.content_cut_outlined), text: 'أسعار التشطيبات والتجليد'),
                Tab(icon: Icon(Icons.tune_outlined), text: 'سعر البليت وهامش الربح والضريبة'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 640,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPaperPricesTab(erp),
                _buildMachinesRatesTab(erp),
                _buildFinishingsTab(erp),
                _buildConstantsTab(erp),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // تبويب 1: أسعار الورق والخامات
  // =========================================================================
  Widget _buildPaperPricesTab(ErpProvider erp) {
    final categories = ['الكل', ...erp.papers.map((p) => p.category).toSet()];
    final query = _paperSearchCtrl.text.trim().toLowerCase();

    final filtered = erp.papers.where((p) {
      if (_selectedPaperCategory != 'الكل' && p.category != _selectedPaperCategory) {
        return false;
      }
      if (query.isNotEmpty) {
        final matchesName = p.displayName.toLowerCase().contains(query);
        final matchesCat = p.category.toLowerCase().contains(query);
        return matchesName || matchesCat;
      }
      return true;
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // شريط البحث والتصفية
            Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 250,
                  child: TextField(
                    controller: _paperSearchCtrl,
                    decoration: const InputDecoration(
                      hintText: 'بحث في الورق...',
                      prefixIcon: Icon(Icons.search, size: 18),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                Wrap(
                  spacing: 6,
                  children: categories.map((cat) {
                    final isSelected = _selectedPaperCategory == cat;
                    return ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        color: isSelected ? AppTheme.primaryGreen : AppTheme.darkSlate,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedPaperCategory = cat);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),

            // جدول الأسعار
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('لا توجد أصناف ورق مطابقة'))
                  : SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                          columns: const [
                            DataColumn(label: Text('الفئة', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('النوع / الجرام', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('مقاس الفرخ', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('ملازم/فرخ', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('سعر الفرخ الحالي', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('تعديل السعر', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: filtered.map((paper) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(paper.category, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                                  ),
                                ),
                                DataCell(Text('${paper.paperType} (${paper.gsm} جم)')),
                                DataCell(Text(paper.sheetSize)),
                                DataCell(Text('${paper.sheetsPerUnit} ملازم')),
                                DataCell(
                                  Text(
                                    '${paper.sheetPrice.toStringAsFixed(1)} ${erp.settings.currency}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                                  ),
                                ),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryGreen, size: 20),
                                    tooltip: 'تعديل سعر الفرخ',
                                    onPressed: () => _editPaperPriceDialog(paper, erp),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _editPaperPriceDialog(PaperItem paper, ErpProvider erp) {
    final priceCtrl = TextEditingController(text: paper.sheetPrice.toStringAsFixed(1));
    final sizeCtrl = TextEditingController(text: paper.sheetSize);
    final sigsCtrl = TextEditingController(text: '${paper.sheetsPerUnit}');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('تعديل سعر ومقاس الفرخ: ${paper.displayName}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الفئة: ${paper.category} | النوع: ${paper.paperType} (${paper.gsm} جم)', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                const SizedBox(height: 14),
                TextFormField(
                  controller: priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'سعر الفرخ الواحد (${erp.settings.currency})',
                    prefixIcon: const Icon(Icons.payments_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: sizeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'مقاس الفرخ القياسي (سم)',
                    prefixIcon: Icon(Icons.aspect_ratio_outlined),
                    hintText: '100x70',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: sigsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'عدد ملازم 50x35 لكل فرخ',
                    prefixIcon: Icon(Icons.grid_view_outlined),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newPrice = double.tryParse(priceCtrl.text.trim()) ?? paper.sheetPrice;
                final newSize = sizeCtrl.text.trim().isNotEmpty ? sizeCtrl.text.trim() : paper.sheetSize;
                final newSigs = int.tryParse(sigsCtrl.text.trim()) ?? paper.sheetsPerUnit;

                paper.sheetPrice = newPrice;
                paper.sheetSize = newSize;
                paper.sheetsPerUnit = newSigs;

                await erp.updatePaper(paper);
                if (ctx.mounted) Navigator.pop(ctx);
                _showSnackBar('تم تحديث سعر ومقاس فرخ ${paper.displayName} بنجاح');
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
              child: const Text('حفظ التعديلات'),
            ),
          ],
        );
      },
    );
  }

  // =========================================================================
  // تبويب 2: الماكينات (تكلفة الساعة، السرعة، نسبة الهالك)
  // =========================================================================
  Widget _buildMachinesRatesTab(ErpProvider erp) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ماكينات الطباعة ومعدلات التشغيل',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
            ),
            const SizedBox(height: 4),
            Text(
              'حدد تكلفة الساعة وسرعة السحب ونسبة الهالك المعتمدة لكل ماكينة للحساب الدقيق في المحرك.',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 12),
            const Divider(),
            Expanded(
              child: ListView.separated(
                itemCount: erp.machines.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final machine = erp.machines[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.borderColor),
                      borderRadius: BorderRadius.circular(10),
                      color: const Color(0xFFF8FAFC),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 700;
                        if (isWide) {
                          return Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.precision_manufacturing, color: AppTheme.primaryGreen, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(machine.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text('النوع: ${machine.kind} | الحالة: ${machine.status}', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: _buildRatePill('تكلفة التشغيل/ساعة', '${machine.hourlyCost.toStringAsFixed(0)} ${erp.settings.currency}', Icons.timer_outlined),
                              ),
                              Expanded(
                                flex: 2,
                                child: _buildRatePill('سرعة السحب', '${machine.speedPerHour} فرخ/ساعة', Icons.speed_outlined),
                              ),
                              Expanded(
                                flex: 2,
                                child: _buildRatePill('نسبة الهالك', '${machine.wastePct.toStringAsFixed(1)}%', Icons.delete_sweep_outlined),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _editMachineRatesDialog(machine, erp),
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('تعديل'),
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                              ),
                            ],
                          );
                        } else {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(machine.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: AppTheme.primaryGreen),
                                    onPressed: () => _editMachineRatesDialog(machine, erp),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  _buildRatePill('تكلفة الساعة', machine.hourlyCost.toStringAsFixed(0), Icons.timer_outlined),
                                  _buildRatePill('السرعة', '${machine.speedPerHour}', Icons.speed_outlined),
                                  _buildRatePill('الهالك', '${machine.wastePct}%', Icons.delete_sweep_outlined),
                                ],
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatePill(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryGreen),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
              Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.darkSlate)),
            ],
          ),
        ],
      ),
    );
  }

  void _editMachineRatesDialog(MachineItem machine, ErpProvider erp) {
    final costCtrl = TextEditingController(text: machine.hourlyCost.toStringAsFixed(0));
    final speedCtrl = TextEditingController(text: machine.speedPerHour.toString());
    final wasteCtrl = TextEditingController(text: machine.wastePct.toStringAsFixed(1));

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('تعديل معايير: ${machine.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: costCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'تكلفة التشغيل بالساعة (${erp.settings.currency})',
                    prefixIcon: const Icon(Icons.timer_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: speedCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'السرعة (فرخ/ساعة)',
                    prefixIcon: Icon(Icons.speed),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: wasteCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'نسبة الهالك (%)',
                    prefixIcon: Icon(Icons.delete_sweep),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                final hourly = double.tryParse(costCtrl.text.trim()) ?? machine.hourlyCost;
                final speed = int.tryParse(speedCtrl.text.trim()) ?? machine.speedPerHour;
                final waste = double.tryParse(wasteCtrl.text.trim()) ?? machine.wastePct;

                await erp.updateMachineRates(
                  machineId: machine.id,
                  hourlyCost: hourly,
                  speedPerHour: speed,
                  wastePct: waste,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                _showSnackBar('تم حفظ معايير ${machine.name} بنجاح');
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
              child: const Text('حفظ التعديلات'),
            ),
          ],
        );
      },
    );
  }

  // =========================================================================
  // تبويب 3: أسعار التشطيبات والتجليد
  // =========================================================================
  Widget _buildFinishingsTab(ErpProvider erp) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'خدمات التشطيب والتجليد وسعر كل خدمة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
            ),
            const SizedBox(height: 4),
            Text(
              'حدد سعر كل عملية ونوع وحدة القياس (للعملية / للألف / للقطعة).',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 12),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                    columns: const [
                      DataColumn(label: Text('الخدمة', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('وحدة القياس', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('السعر الحالي', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('تعديل السعر والوحدة', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: erp.finishings.map((f) {
                      return DataRow(
                        cells: [
                          DataCell(Text(f.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(f.unit, style: const TextStyle(color: Colors.blue, fontSize: 12)),
                            ),
                          ),
                          DataCell(Text('${f.price.toStringAsFixed(1)} ${erp.settings.currency}')),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryGreen),
                              tooltip: 'تعديل السعر',
                              onPressed: () => _editFinishingDialog(f, erp),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editFinishingDialog(FinishingItem f, ErpProvider erp) {
    final priceCtrl = TextEditingController(text: f.price.toStringAsFixed(1));
    String selectedUnit = f.unit;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              title: Text('تعديل سعر: ${f.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'السعر (${erp.settings.currency})',
                      prefixIcon: const Icon(Icons.monetization_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedUnit,
                    decoration: const InputDecoration(labelText: 'وحدة التسعير'),
                    items: const [
                      DropdownMenuItem(value: 'للعملية', child: Text('للعملية (مقطوع)')),
                      DropdownMenuItem(value: 'للألف', child: Text('للألف (نسخة/فرخ)')),
                      DropdownMenuItem(value: 'للقطعة', child: Text('للقطعة (لكل كتاب/دفتر)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDlgState(() => selectedUnit = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                ElevatedButton(
                  onPressed: () async {
                    final newPrice = double.tryParse(priceCtrl.text.trim()) ?? f.price;
                    await erp.updateFinishingPrice(f.id, newPrice, selectedUnit);
                    if (ctx.mounted) Navigator.pop(ctx);
                    _showSnackBar('تم تحديث خدمة ${f.name} بنجاح');
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                  child: const Text('حفظ السعر'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // تبويب 4: سعر البليت وهامش الربح والضريبة
  // =========================================================================
  Widget _buildConstantsTab(ErpProvider erp) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ثوابت التسعير والضرائب وهامش الربح',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
              ),
              const SizedBox(height: 4),
              Text(
                'هذه القيم هي المعايير الافتراضية المطبقة في كل عملية تسعير جديدة.',
                style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 600;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: isWide ? (constraints.maxWidth - 20) / 2 : double.infinity,
                        child: TextFormField(
                          controller: _platePriceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'سعر البليت / الزنك الافتراضي (${erp.settings.currency})',
                            helperText: 'سعر الزنك الأوفست 50×35 لكل لون/وجه',
                            prefixIcon: const Icon(Icons.layers_outlined),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: isWide ? (constraints.maxWidth - 20) / 2 : double.infinity,
                        child: TextFormField(
                          controller: _marginCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'هامش الربح الافتراضي (%)',
                            helperText: 'النسبة المضافة فوق التكلفة الصناعية',
                            prefixIcon: Icon(Icons.trending_up),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: isWide ? (constraints.maxWidth - 20) / 2 : double.infinity,
                        child: TextFormField(
                          controller: _taxCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'نسبة الضريبة المضافة (%)',
                            helperText: '0 تعني بدون ضريبة، أو النسبة المقررة',
                            prefixIcon: Icon(Icons.receipt_long),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  final pPrice = double.tryParse(_platePriceCtrl.text.trim()) ?? erp.settings.defaultPlatePrice;
                  final pMargin = double.tryParse(_marginCtrl.text.trim()) ?? erp.settings.defaultProfitMarginPct;
                  final pTax = double.tryParse(_taxCtrl.text.trim()) ?? erp.settings.taxPct;

                  await erp.updatePricingConstants(
                    platePrice: pPrice,
                    profitMarginPct: pMargin,
                    taxPct: pTax,
                  );
                  _showSnackBar('تم حفظ ثوابت التسعير والربح والضريبة بنجاح');
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('حفظ ثوابت التسعير والربح'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
