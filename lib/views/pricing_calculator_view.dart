import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../providers/erp_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../services/pricing_engine_service.dart';
import '../services/pdf_export_service.dart';

class PricingCalculatorView extends StatefulWidget {
  final Function(int)? onNavigate;

  const PricingCalculatorView({super.key, this.onNavigate});

  @override
  State<PricingCalculatorView> createState() => _PricingCalculatorViewState();
}

class _PricingCalculatorViewState extends State<PricingCalculatorView> {
  // القالب المحدد
  ProductPricingType _activeTemplate = ProductPricingType.book;

  // ==========================
  // مدخلات قالب الكتاب (Book)
  // ==========================
  int _bookPages = 96;
  int _bookPagesPerSig = 8; // 8 أو 16
  int _bookQty = 1000;
  PaperItem? _bookInnerPaper;
  MachineItem? _bookMachine;
  int _bookInnerColors = 1;
  PaperItem? _bookCoverPaper;
  int _bookCoverFitsPerSheet = 4;
  final int _bookCoverColors = 4;
  bool _bookCoverLamination = true;
  String _bookBindingType = 'حراري'; // حراري / دبوس / سلك / خياطة
  double _bookWidthCm = 14.8; // عرض الكتاب النهائي بالسم
  double _bookHeightCm = 21.0; // طول الكتاب النهائي بالسم

  // ==========================
  // مدخلات قالب الـ NCR
  // ==========================
  int _ncrCopies = 3; // أصل + صورتين
  int _ncrSheetsPerBook = 50; // وصل/دفتر
  int _ncrBooksCount = 100; // عدد الدفاتر
  final int _ncrColorsCount = 1; // ألوان الطباعة
  bool _ncrHasNumbering = true;
  bool _ncrHasAssembly = true;
  MachineItem? _ncrMachine;
  final List<PaperItem?> _ncrPapers = [null, null, null, null];

  // ==========================
  // مدخلات قالب الكرت (Card)
  // ==========================
  double _cardWidthCm = 9.0;
  double _cardHeightCm = 5.5;
  int _cardQty = 1000;
  PaperItem? _cardPaper;
  String _cardSheetSize = '100x70';
  int _cardPrintSides = 2; // وجهين (4/4)
  MachineItem? _cardMachine;
  final int _cardColorsCount = 4;
  bool _cardHasCutting = true;
  bool _cardHasLamination = true;

  // ==========================
  // مدخلات القالب المخصص (Custom)
  // ==========================
  ProductTemplate? _selectedCustomProduct;
  PaperItem? _customPaper;
  MachineItem? _customMachine;
  int _customQty = 1000;
  int _customPages = 16;
  final int _customColors = 4;
  final int _customPlates = 4;

  // ==========================
  // الثوابت العامة للحسبة الحالية
  // ==========================
  double _plateCost = 1250.0;
  double _profitMarginPct = 30.0;
  double _taxPct = 0.0;
  final List<String> _selectedFinishingIds = [];
  int _ncrSetsPerSheet = 16; // عدد الوصولات في الفرخ 50×35 (يُحسب تلقائياً)
  double _ncrWidthCm = 14.0; // عرض الوصل/الدفتر بالسم
  double _ncrHeightCm = 20.0; // طول الوصل/الدفتر بالسم

  // وحدات تحكم نصوص
  late TextEditingController _bookPagesCtrl;
  late TextEditingController _bookQtyCtrl;
  late TextEditingController _ncrCopiesCtrl;
  late TextEditingController _ncrSheetsCtrl;
  late TextEditingController _ncrBooksCtrl;
  late TextEditingController _cardWidthCtrl;
  late TextEditingController _cardHeightCtrl;
  late TextEditingController _cardQtyCtrl;
  late TextEditingController _customQtyCtrl;
  late TextEditingController _customPagesCtrl;
  late TextEditingController _plateCostCtrl;
  late TextEditingController _marginCtrl;
  late TextEditingController _taxCtrl;
  late TextEditingController _bookWidthCtrl;
  late TextEditingController _bookHeightCtrl;
  late TextEditingController _ncrWidthCtrl;
  late TextEditingController _ncrHeightCtrl;

  @override
  void initState() {
    super.initState();
    _bookPagesCtrl = TextEditingController(text: '$_bookPages');
    _bookQtyCtrl = TextEditingController(text: '$_bookQty');
    _ncrCopiesCtrl = TextEditingController(text: '$_ncrCopies');
    _ncrSheetsCtrl = TextEditingController(text: '$_ncrSheetsPerBook');
    _ncrBooksCtrl = TextEditingController(text: '$_ncrBooksCount');
    _cardWidthCtrl = TextEditingController(text: '$_cardWidthCm');
    _cardHeightCtrl = TextEditingController(text: '$_cardHeightCm');
    _cardQtyCtrl = TextEditingController(text: '$_cardQty');
    _customQtyCtrl = TextEditingController(text: '$_customQty');
    _customPagesCtrl = TextEditingController(text: '$_customPages');
    _plateCostCtrl = TextEditingController(text: '${_plateCost.toInt()}');
    _marginCtrl = TextEditingController(text: '${_profitMarginPct.toInt()}');
    _taxCtrl = TextEditingController(text: '${_taxPct.toInt()}');
    _bookWidthCtrl = TextEditingController(text: '$_bookWidthCm');
    _bookHeightCtrl = TextEditingController(text: '$_bookHeightCm');
    _ncrWidthCtrl = TextEditingController(text: '$_ncrWidthCm');
    _ncrHeightCtrl = TextEditingController(text: '$_ncrHeightCm');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initDefaults();
    });
  }

  void _initDefaults() {
    final erp = context.read<ErpProvider>();

    _plateCost = erp.settings.defaultPlatePrice;
    _profitMarginPct = erp.settings.defaultProfitMarginPct;
    _taxPct = erp.settings.taxPct;
    _plateCostCtrl.text = '${_plateCost.toInt()}';
    _marginCtrl.text = '${_profitMarginPct.toInt()}';
    _taxCtrl.text = '${_taxPct.toInt()}';

    // افتراضيات الكتاب
    final offsetPapers = erp.papers.where((p) => p.category == 'أوفست');
    _bookInnerPaper = offsetPapers.isNotEmpty ? offsetPapers.first : (erp.papers.isNotEmpty ? erp.papers.first : null);

    final coverPapers = erp.papers.where((p) => p.category == 'كوشيه' && p.gsm >= 250);
    _bookCoverPaper = coverPapers.isNotEmpty ? coverPapers.first : (erp.papers.isNotEmpty ? erp.papers.first : null);

    _bookMachine = erp.machines.isNotEmpty ? erp.machines.first : null;

    // افتراضيات NCR
    final ncrWhite = erp.papers.where((p) => (p.category == 'NCR' || p.category == 'ورق مكربن') && p.paperType.contains('أبيض'));
    final ncrPink = erp.papers.where((p) => (p.category == 'NCR' || p.category == 'ورق مكربن') && p.paperType.contains('وردي'));
    final ncrYellow = erp.papers.where((p) => (p.category == 'NCR' || p.category == 'ورق مكربن') && p.paperType.contains('أصفر'));

    _ncrPapers[0] = ncrWhite.isNotEmpty ? ncrWhite.first : (erp.papers.isNotEmpty ? erp.papers.first : null);
    _ncrPapers[1] = ncrPink.isNotEmpty ? ncrPink.first : (erp.papers.isNotEmpty ? erp.papers.first : null);
    _ncrPapers[2] = ncrYellow.isNotEmpty ? ncrYellow.first : (erp.papers.isNotEmpty ? erp.papers.first : null);
    _ncrMachine = erp.machines.isNotEmpty ? erp.machines.first : null;

    // افتراضيات الكروت
    final cardPapers = erp.papers.where((p) => p.category == 'كوشيه' && p.gsm >= 300);
    _cardPaper = cardPapers.isNotEmpty ? cardPapers.first : (erp.papers.isNotEmpty ? erp.papers.first : null);
    _cardMachine = erp.machines.isNotEmpty ? erp.machines.first : null;

    // افتراضيات المخصص
    if (erp.products.isNotEmpty) _selectedCustomProduct = erp.products.first;
    _customPaper = erp.papers.isNotEmpty ? erp.papers.first : null;
    _customMachine = erp.machines.isNotEmpty ? erp.machines.first : null;

    // حساب القيم الأولية من المقاسات الافتراضية
    _bookPagesPerSig = _calcBookPagesPerSig(_bookWidthCm, _bookHeightCm);
    _bookCoverFitsPerSheet = _calcCoverFitsPerSheet(_bookWidthCm, _bookHeightCm);
    _ncrSetsPerSheet = _calcNcrSetsPerSheet(_ncrWidthCm, _ncrHeightCm);

    setState(() {});
  }

  @override
  void dispose() {
    _bookPagesCtrl.dispose();
    _bookQtyCtrl.dispose();
    _ncrCopiesCtrl.dispose();
    _ncrSheetsCtrl.dispose();
    _ncrBooksCtrl.dispose();
    _cardWidthCtrl.dispose();
    _cardHeightCtrl.dispose();
    _cardQtyCtrl.dispose();
    _customQtyCtrl.dispose();
    _customPagesCtrl.dispose();
    _plateCostCtrl.dispose();
    _marginCtrl.dispose();
    _taxCtrl.dispose();
    _bookWidthCtrl.dispose();
    _bookHeightCtrl.dispose();
    _ncrWidthCtrl.dispose();
    _ncrHeightCtrl.dispose();
    super.dispose();
  }

  // =========================================================================
  // الحساب الفوري حسب القالب النشط
  // =========================================================================
  PricingResult _calculateActivePricing(ErpProvider erp) {
    switch (_activeTemplate) {
      case ProductPricingType.book:
        final innerPaper = _bookInnerPaper ?? erp.papers.first;
        final coverPaper = _bookCoverPaper ?? innerPaper;
        final machine = _bookMachine ?? erp.machines.first;

        FinishingItem? lam;
        final lamMatches = erp.finishings.where((f) => f.name.contains('سلوفان'));
        if (lamMatches.isNotEmpty) lam = lamMatches.first;

        FinishingItem? bind;
        final bindMatches = erp.finishings.where((f) => f.name.contains(_bookBindingType));
        if (bindMatches.isNotEmpty) bind = bindMatches.first;

        return erp.calculateBookPrice(
          productName: 'كتاب ($_bookPages ص - $_bookBindingType)',
          pages: _bookPages,
          pagesPerSignature: _bookPagesPerSig,
          qty: _bookQty,
          innerPaper: innerPaper,
          machine: machine,
          innerColors: _bookInnerColors,
          coverPaper: coverPaper,
          coverFitsPerSheet: _bookCoverFitsPerSheet,
          coverColors: _bookCoverColors,
          coverLamination: _bookCoverLamination,
          laminationFinishing: lam,
          bindingType: _bookBindingType,
          bindingFinishing: bind,
          selectedFinishingIds: _selectedFinishingIds,
          plateCost: _plateCost,
          profitMarginPct: _profitMarginPct,
          taxPct: _taxPct,
        );

      case ProductPricingType.ncr:
        final machine = _ncrMachine ?? erp.machines.first;
        final activePapers = <PaperItem>[];
        for (int i = 0; i < _ncrCopies; i++) {
          if (i < _ncrPapers.length && _ncrPapers[i] != null) {
            activePapers.add(_ncrPapers[i]!);
          } else if (erp.papers.isNotEmpty) {
            activePapers.add(erp.papers.first);
          }
        }

        FinishingItem? numFin;
        final numMatches = erp.finishings.where((f) => f.name.contains('ترقيم'));
        if (numMatches.isNotEmpty) numFin = numMatches.first;

        FinishingItem? assFin;
        final assMatches = erp.finishings.where((f) => f.name.contains('تدبيس'));
        if (assMatches.isNotEmpty) assFin = assMatches.first;

        return erp.calculateNcrPrice(
          productName: 'دفتر NCR ($_ncrCopies نسخ - $_ncrSheetsPerBook وصل)',
          ncrCopies: _ncrCopies,
          sheetsPerBook: _ncrSheetsPerBook,
          booksCount: _ncrBooksCount,
          papersPerColor: activePapers,
          setsPerSheet: _ncrSetsPerSheet,
          machine: machine,
          colorsCount: _ncrColorsCount,
          hasNumbering: _ncrHasNumbering,
          numberingFinishing: numFin,
          hasAssemblyAndBinding: _ncrHasAssembly,
          assemblyFinishing: assFin,
          selectedFinishingIds: _selectedFinishingIds,
          plateCost: _plateCost,
          profitMarginPct: _profitMarginPct,
          taxPct: _taxPct,
        );

      case ProductPricingType.card:
        final paper = _cardPaper ?? erp.papers.first;
        final machine = _cardMachine ?? erp.machines.first;

        FinishingItem? cutFin;
        final cutMatches = erp.finishings.where((f) => f.name == 'قص');
        if (cutMatches.isNotEmpty) cutFin = cutMatches.first;

        FinishingItem? lamFin;
        final lamMatches = erp.finishings.where((f) => f.name.contains('سلوفان'));
        if (lamMatches.isNotEmpty) lamFin = lamMatches.first;

        return erp.calculateCardPrice(
          productName: 'كروت شخصية / بروشور ($_cardWidthCm×$_cardHeightCm سم)',
          cardWidthCm: _cardWidthCm,
          cardHeightCm: _cardHeightCm,
          qty: _cardQty,
          paper: paper,
          sheetSize: _cardSheetSize,
          printSides: _cardPrintSides,
          machine: machine,
          colorsCount: _cardColorsCount,
          hasCutting: _cardHasCutting,
          cuttingFinishing: cutFin,
          hasLamination: _cardHasLamination,
          laminationFinishing: lamFin,
          selectedFinishingIds: _selectedFinishingIds,
          plateCost: _plateCost,
          profitMarginPct: _profitMarginPct,
          taxPct: _taxPct,
        );

      case ProductPricingType.custom:
        final product = _selectedCustomProduct ?? (erp.products.isNotEmpty ? erp.products.first : ProductTemplate(id: 'c', name: 'منتج مخصص', category: 'أخرى'));
        final paper = _customPaper ?? erp.papers.first;
        final machine = _customMachine ?? erp.machines.first;

        return erp.calculatePrice(
          product: product,
          qty: _customQty,
          pages: _customPages,
          ncrCopies: 0,
          sheetsPerBook: 0,
          booksCount: 0,
          colorsCount: _customColors,
          platesCount: _customPlates,
          plateCost: _plateCost,
          profitMarginPct: _profitMarginPct,
          paper: paper,
          machine: machine,
          selectedFinishingIds: _selectedFinishingIds,
          taxPct: _taxPct,
        );
    }
  }

  // =========================================================================
  // دوال مساعدة: حساب مقاسات الطباعة تلقائياً
  // =========================================================================

  /// عدد صفحات الملزمة من مقاس الكتاب (باستخدام ورق 50×35 سم)
  int _calcBookPagesPerSig(double widthCm, double heightCm) {
    const double sw = 48.5; // 50 - 1.5 هوامش
    const double sh = 33.5; // 35 - 1.5 هوامش
    final w = widthCm > 0 ? widthCm : 14.8;
    final h = heightCm > 0 ? heightCm : 21.0;
    final fit1 = (sw / w).floor() * (sh / h).floor();
    final fit2 = (sw / h).floor() * (sh / w).floor();
    final best = fit1 > fit2 ? fit1 : fit2;
    return (best < 1 ? 1 : best) * 2; // وجهان × أفضل توزيع
  }

  /// عدد الأغلفة في الفرخ الكبير 100×70
  int _calcCoverFitsPerSheet(double bookWidthCm, double bookHeightCm) {
    const double sw = 98.0; // 100 - 2 هوامش
    const double sh = 68.0; // 70 - 2 هوامش
    final bw = bookWidthCm > 0 ? bookWidthCm : 14.8;
    final bh = bookHeightCm > 0 ? bookHeightCm : 21.0;
    final coverW = bw * 2 + 1.5; // وجهان + ظهر الغلاف
    final fit1 = (sw / coverW).floor() * (sh / bh).floor();
    final fit2 = (sw / bh).floor() * (sh / coverW).floor();
    final best = fit1 > fit2 ? fit1 : fit2;
    return best < 1 ? 1 : best;
  }

  /// عدد الوصولات في الفرخ 50×35 للدفاتر NCR
  int _calcNcrSetsPerSheet(double widthCm, double heightCm) {
    const double sw = 48.5;
    const double sh = 33.5;
    final w = widthCm > 0 ? widthCm : 14.0;
    final h = heightCm > 0 ? heightCm : 20.0;
    final fit1 = (sw / w).floor() * (sh / h).floor();
    final fit2 = (sw / h).floor() * (sh / w).floor();
    final best = fit1 > fit2 ? fit1 : fit2;
    return best < 1 ? 1 : best;
  }

  @override
  Widget build(BuildContext context) {
    final erp = context.watch<ErpProvider>();
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    if (erp.papers.isEmpty || erp.machines.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final result = _calculateActivePricing(erp);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;
        final isWide = constraints.maxWidth >= 950;
        final inputsWidget = _buildInputsSection(erp, isAdmin);
        final outputsWidget = _buildOutputsSection(result, erp, isAdmin);

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 12 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // شريط العنوان وأزرار الإجراءات
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'محرك التسعير الذكي وقوالب المنتجات',
                        style: TextStyle(
                          fontSize: isMobile ? 17 : 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkSlate,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'مسار حساب تخصصي: كتب، دفاتر، كروت، وقوالب مخصصة',
                        style: TextStyle(fontSize: isMobile ? 11.5 : 13, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (isAdmin)
                        OutlinedButton.icon(
                          onPressed: () {
                          if (widget.onNavigate != null) {
                            widget.onNavigate!(11); // فتح قسم إدارة الأسعار
                          }
                        },
                        icon: const Icon(Icons.price_change_outlined, size: 16),
                        label: Text(isMobile ? 'الأسعار' : 'إدارة وتعديل الأسعار', style: TextStyle(fontSize: isMobile ? 12 : 13)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryGreen,
                          side: const BorderSide(color: AppTheme.primaryGreen),
                          padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 14, vertical: isMobile ? 8 : 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showSaveQuotationDialog(result),
                        icon: const Icon(Icons.note_add_outlined, size: 16),
                        label: Text(isMobile ? 'إنشاء عرض سعر' : 'إنشاء عرض سعر من الحسبة', style: TextStyle(fontSize: isMobile ? 12 : 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 8 : 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 12 : 16),

              // كرت الملخص الفوري للتسعير (يظهر بأعلى الجوال مباشرة لتحديث النتيجة الحية)
              if (isMobile) _buildMobileLiveSummary(result, erp, isAdmin),

              // شريط اختيار قالب المنتج (Tabs)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTemplateChip(ProductPricingType.book, '📖 كتاب ومجلة', 'الصفحات → الملازم → الغلاف → التجليد', isMobile: isMobile),
                      const SizedBox(width: 6),
                      _buildTemplateChip(ProductPricingType.ncr, '📑 دفاتر NCR مكربنة', 'أوراق الدفتر → الألوان → الترقيم', isMobile: isMobile),
                      const SizedBox(width: 6),
                      _buildTemplateChip(ProductPricingType.card, '📇 كرت ومطبوع فردي', 'المقاس → التوزيع → القص', isMobile: isMobile),
                      const SizedBox(width: 6),
                      _buildTemplateChip(ProductPricingType.custom, '📦 منتج مخصص', 'معادلة تكاليف حرة', isMobile: isMobile),
                    ],
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 14 : 20),

              // تقسيم الشاشة: عمود المدخلات (يمين) + عمود المخرجات ومسار الحساب (يسار)
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: inputsWidget),
                    const SizedBox(width: 20),
                    Expanded(flex: 5, child: outputsWidget),
                  ],
                )
              else
                Column(
                  children: [
                    inputsWidget,
                    const SizedBox(height: 20),
                    outputsWidget,
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileLiveSummary(PricingResult result, ErpProvider erp, bool isAdmin) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.darkSlate,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('سعر بيع النسخة', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${result.unitPrice.toStringAsFixed(2)} ${erp.settings.currency}',
                        style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('إجمالي البيع المقترح', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${AppTheme.formatCurrency(result.lineAmount)} ${erp.settings.currency}',
                        style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isAdmin) ...[
            const SizedBox(height: 8),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'التكلفة: ${AppTheme.formatCurrency(result.lineTotalCost)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'الربح: ${AppTheme.formatCurrency(result.profit)} (${result.profitMarginPct.toStringAsFixed(0)}%)',
                    style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 11, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTemplateChip(ProductPricingType type, String title, String subtitle, {bool isMobile = false}) {
    final isSelected = _activeTemplate == type;
    return InkWell(
      onTap: () => setState(() => _activeTemplate = type),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 14, vertical: isMobile ? 8 : 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: AppTheme.primaryGreen, width: 1.5) : Border.all(color: Colors.transparent),
        ),
        child: isMobile
            ? Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? AppTheme.primaryGreen : AppTheme.darkSlate,
                  fontSize: 13,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? AppTheme.primaryGreen : AppTheme.darkSlate,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isSelected ? AppTheme.primaryGreen : AppTheme.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // =========================================================================
  // قسم المدخلات التفاعلي حسب القالب
  // =========================================================================
  Widget _buildInputsSection(ErpProvider erp, bool isAdmin) {
    return Column(
      children: [
        if (_activeTemplate == ProductPricingType.book) _buildBookInputs(erp, isAdmin),
        if (_activeTemplate == ProductPricingType.ncr) _buildNcrInputs(erp, isAdmin),
        if (_activeTemplate == ProductPricingType.card) _buildCardInputs(erp, isAdmin),
        if (_activeTemplate == ProductPricingType.custom) _buildCustomInputs(erp, isAdmin),
        const SizedBox(height: 16),
        if (isAdmin) _buildPricingConstantsCard(),
      ],
    );
  }

  // مدخلات قالب الكتاب
  Widget _buildBookInputs(ErpProvider erp, bool isAdmin) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 650;

            final pagesField = TextFormField(
              controller: _bookPagesCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'عدد الصفحات الكلية',
                helperText: 'مثال: 96، 128...',
                prefixIcon: Icon(Icons.format_list_numbered),
              ),
              onChanged: (v) => setState(() => _bookPages = int.tryParse(v) ?? 16),
            );

            final autoSigVal = _calcBookPagesPerSig(_bookWidthCm, _bookHeightCm);
            final sigOptions = (<int>{4, 8, 12, 16, autoSigVal}.toList()..sort());
            final sigField = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('صفحات الملزمة (من الفرخ 50×35)',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: sigOptions.map((v) => FilterChip(
                    label: Text('$v${v == autoSigVal ? ' ✓' : ''}',
                        style: TextStyle(fontSize: 12, fontWeight: v == autoSigVal ? FontWeight.bold : FontWeight.normal)),
                    selected: v == _bookPagesPerSig,
                    selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
                    checkmarkColor: AppTheme.primaryGreen,
                    onSelected: (_) => setState(() => _bookPagesPerSig = v),
                  )).toList(),
                ),
              ],
            );

            final qtyField = TextFormField(
              controller: _bookQtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'عدد النسخ',
                helperText: 'الكمية المطلوبة',
                prefixIcon: Icon(Icons.copy),
              ),
              onChanged: (v) => setState(() => _bookQty = int.tryParse(v) ?? 100),
            );

            final paperField = DropdownButtonFormField<PaperItem>(
              initialValue: _bookInnerPaper,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'ورق المتن الداخلي'),
              items: erp.papers.map((p) {
                return DropdownMenuItem(value: p, child: Text(isAdmin ? '${p.displayName} (${p.sheetPrice} ر.ي)' : p.displayName));
              }).toList(),
              onChanged: (p) => setState(() => _bookInnerPaper = p),
            );

            final machineField = DropdownButtonFormField<MachineItem>(
              initialValue: _bookMachine,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'ماكينة المتن'),
              items: erp.machines.map((m) {
                return DropdownMenuItem(value: m, child: Text('${m.name} (${m.wastePct}% هالك)'));
              }).toList(),
              onChanged: (m) => setState(() => _bookMachine = m),
            );

            final colorsField = DropdownButtonFormField<int>(
              initialValue: _bookInnerColors,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'ألوان المتن'),
              items: const [
                DropdownMenuItem(value: 1, child: Text('1 لون (أسود)')),
                DropdownMenuItem(value: 2, child: Text('2 لون')),
                DropdownMenuItem(value: 4, child: Text('4 ألوان (ملون)')),
              ],
              onChanged: (v) => setState(() => _bookInnerColors = v ?? 1),
            );

            final autoCoverFits = _calcCoverFitsPerSheet(_bookWidthCm, _bookHeightCm);
            final coverFitsOptions = (<int>{2, 4, 6, 8, autoCoverFits}.toList()..sort());
            final coverFitsWidget = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('أغلفة/فرخ 100×70', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: coverFitsOptions.map((v) => FilterChip(
                    label: Text('$v${v == autoCoverFits ? ' ✓' : ''}',
                        style: TextStyle(fontSize: 12, fontWeight: v == autoCoverFits ? FontWeight.bold : FontWeight.normal)),
                    selected: v == _bookCoverFitsPerSheet,
                    selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
                    checkmarkColor: AppTheme.primaryGreen,
                    onSelected: (_) => setState(() => _bookCoverFitsPerSheet = v),
                  )).toList(),
                ),
              ],
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.menu_book, color: AppTheme.primaryGreen),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('مدخلات الكتاب: المقاس والصفحات والغلاف والتجليد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 12),

                // ── مقاس الكتاب النهائي ──
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryGreen.withValues(alpha: 0.07), Colors.white],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.35)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.straighten_outlined, color: AppTheme.primaryGreen, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'مقاس الكتاب النهائي بالسنتيمتر (العرض × الطول)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkSlate),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // أزرار المقاسات الشائعة
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final p in [
                            ('جيب (10.5×14.8)', 10.5, 14.8),
                            ('A5 (14.8×21)', 14.8, 21.0),
                            ('17×12 سم', 12.0, 17.0),
                            ('A4 (21×29.7)', 21.0, 29.7),
                            ('20×14 سم', 14.0, 20.0),
                          ])
                            ActionChip(
                              label: Text(p.$1, style: const TextStyle(fontSize: 11)),
                              backgroundColor: (_bookWidthCm == p.$2 && _bookHeightCm == p.$3)
                                  ? AppTheme.primaryGreen.withValues(alpha: 0.15)
                                  : null,
                              side: BorderSide(
                                color: (_bookWidthCm == p.$2 && _bookHeightCm == p.$3)
                                    ? AppTheme.primaryGreen
                                    : AppTheme.borderColor,
                                width: (_bookWidthCm == p.$2 && _bookHeightCm == p.$3) ? 1.5 : 1,
                              ),
                              onPressed: () {
                                setState(() {
                                  _bookWidthCm = p.$2;
                                  _bookHeightCm = p.$3;
                                  _bookWidthCtrl.text = '${p.$2}';
                                  _bookHeightCtrl.text = '${p.$3}';
                                  _bookPagesPerSig = _calcBookPagesPerSig(_bookWidthCm, _bookHeightCm);
                                  _bookCoverFitsPerSheet = _calcCoverFitsPerSheet(_bookWidthCm, _bookHeightCm);
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // حقول الإدخال المباشر
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _bookWidthCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'العرض',
                                suffixText: 'سم',
                                isDense: true,
                                prefixIcon: Icon(Icons.swap_horiz, size: 18),
                              ),
                              onChanged: (v) {
                                final w = double.tryParse(v);
                                if (w != null && w > 0) {
                                  setState(() {
                                    _bookWidthCm = w;
                                    _bookPagesPerSig = _calcBookPagesPerSig(_bookWidthCm, _bookHeightCm);
                                    _bookCoverFitsPerSheet = _calcCoverFitsPerSheet(_bookWidthCm, _bookHeightCm);
                                  });
                                }
                              },
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text('×', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: _bookHeightCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'الطول',
                                suffixText: 'سم',
                                isDense: true,
                                prefixIcon: Icon(Icons.height, size: 18),
                              ),
                              onChanged: (v) {
                                final h = double.tryParse(v);
                                if (h != null && h > 0) {
                                  setState(() {
                                    _bookHeightCm = h;
                                    _bookPagesPerSig = _calcBookPagesPerSig(_bookWidthCm, _bookHeightCm);
                                    _bookCoverFitsPerSheet = _calcCoverFitsPerSheet(_bookWidthCm, _bookHeightCm);
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // النتيجة المحسوبة تلقائياً
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_fix_high, size: 16, color: AppTheme.primaryGreen),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'حساب تلقائي: من فرخ 50×35 ← '
                                '${_calcBookPagesPerSig(_bookWidthCm, _bookHeightCm)} صفحة/ملزمة  |  '
                                '${_calcCoverFitsPerSheet(_bookWidthCm, _bookHeightCm)} غلاف/فرخ 100×70',
                                style: const TextStyle(fontSize: 12, color: AppTheme.primaryGreen, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // الصفحات والكمية
                if (isNarrow) ...[
                  pagesField,
                  const SizedBox(height: 12),
                  sigField,
                  const SizedBox(height: 12),
                  qtyField,
                ] else ...[
                  Row(
                    children: [
                      Expanded(child: pagesField),
                      const SizedBox(width: 12),
                      Expanded(child: sigField),
                      const SizedBox(width: 12),
                      Expanded(child: qtyField),
                    ],
                  ),
                ],
                const SizedBox(height: 16),

                // ورق المتن وماكينة الطباعة
                if (isNarrow) ...[
                  paperField,
                  const SizedBox(height: 12),
                  machineField,
                  const SizedBox(height: 12),
                  colorsField,
                ] else ...[
                  Row(
                    children: [
                      Expanded(flex: 3, child: paperField),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: machineField),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: colorsField),
                    ],
                  ),
                ],
                const SizedBox(height: 16),

                // مواصفات الغلاف
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    border: Border.all(color: AppTheme.borderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('مواصفات الغلاف الخارجي:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      if (isNarrow) ...[
                        DropdownButtonFormField<PaperItem>(
                          initialValue: _bookCoverPaper,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'خامة ورق الغلاف'),
                          items: erp.papers.map((p) {
                            return DropdownMenuItem(value: p, child: Text(p.displayName));
                          }).toList(),
                          onChanged: (p) => setState(() => _bookCoverPaper = p),
                        ),
                        const SizedBox(height: 10),
                        coverFitsWidget,
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Switch(
                              value: _bookCoverLamination,
                              onChanged: (v) => setState(() => _bookCoverLamination = v),
                            ),
                            const SizedBox(width: 8),
                            const Text('سلوفان غلاف'),
                          ],
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<PaperItem>(
                                initialValue: _bookCoverPaper,
                                isExpanded: true,
                                decoration: const InputDecoration(labelText: 'خامة ورق الغلاف'),
                                items: erp.papers.map((p) {
                                  return DropdownMenuItem(value: p, child: Text(p.displayName));
                                }).toList(),
                                onChanged: (p) => setState(() => _bookCoverPaper = p),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: coverFitsWidget,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  Switch(
                                    value: _bookCoverLamination,
                                    onChanged: (v) => setState(() => _bookCoverLamination = v),
                                  ),
                                  const SizedBox(width: 6),
                                  const Expanded(child: Text('سلوفان غلاف', overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // التجليد
                DropdownButtonFormField<String>(
                  initialValue: _bookBindingType,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'نوع التجليد',
                    prefixIcon: Icon(Icons.bookmark_border),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'حراري', child: Text('تجليد حراري (غراء ساخن)')),
                    DropdownMenuItem(value: 'دبوس', child: Text('تدبيس سلك (دبوسين)')),
                    DropdownMenuItem(value: 'سلك', child: Text('تجليد سلك حلزوني (Wire)')),
                    DropdownMenuItem(value: 'خياطة', child: Text('خياطة وتجليد فاخر')),
                  ],
                  onChanged: (v) => setState(() => _bookBindingType = v ?? 'حراري'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // مدخلات قالب الـ NCR
  Widget _buildNcrInputs(ErpProvider erp, bool isAdmin) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 650;

            final copiesField = TextFormField(
              controller: _ncrCopiesCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'عدد النسخ المكربنة',
                helperText: 'أصل + صور (مثلاً 3 أو 4)',
                prefixIcon: Icon(Icons.layers),
              ),
              onChanged: (v) {
                setState(() {
                  _ncrCopies = int.tryParse(v) ?? 3;
                  if (_ncrCopies > 4) _ncrCopies = 4;
                });
              },
            );

            final sheetsField = TextFormField(
              controller: _ncrSheetsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'أوراق/وصولات الدفتر',
                helperText: 'عادة 50 أو 100 وصل',
                prefixIcon: Icon(Icons.file_copy_outlined),
              ),
              onChanged: (v) => setState(() => _ncrSheetsPerBook = int.tryParse(v) ?? 50),
            );

            final booksField = TextFormField(
              controller: _ncrBooksCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'عدد الدفاتر',
                helperText: 'إجمالي الدفاتر المطلوبة',
                prefixIcon: Icon(Icons.menu_book),
              ),
              onChanged: (v) => setState(() => _ncrBooksCount = int.tryParse(v) ?? 50),
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.receipt_long, color: AppTheme.primaryGreen),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('مدخلات دفاتر NCR: النسخ وأوراق الدفتر وتوزيع الألوان والترقيم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 12),

                // ── مقاس الوصل/الدفتر النهائي ──
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.withValues(alpha: 0.07), Colors.white],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.35)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.straighten_outlined, color: Colors.blue, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'مقاس الوصل/الدفتر بالسنتيمتر (العرض × الطول)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final p in [
                            ('سند (10×20)', 10.0, 20.0),
                            ('A6 (10.5×14.8)', 10.5, 14.8),
                            ('فاتورة (14×20)', 14.0, 20.0),
                            ('A5 (14.8×21)', 14.8, 21.0),
                          ])
                            ActionChip(
                              label: Text(p.$1, style: const TextStyle(fontSize: 11)),
                              backgroundColor: (_ncrWidthCm == p.$2 && _ncrHeightCm == p.$3)
                                  ? Colors.blue.withValues(alpha: 0.15) : null,
                              side: BorderSide(
                                color: (_ncrWidthCm == p.$2 && _ncrHeightCm == p.$3)
                                    ? Colors.blue : AppTheme.borderColor,
                              ),
                              onPressed: () {
                                setState(() {
                                  _ncrWidthCm = p.$2;
                                  _ncrHeightCm = p.$3;
                                  _ncrWidthCtrl.text = '${p.$2}';
                                  _ncrHeightCtrl.text = '${p.$3}';
                                  _ncrSetsPerSheet = _calcNcrSetsPerSheet(_ncrWidthCm, _ncrHeightCm);
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _ncrWidthCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'العرض', suffixText: 'سم', isDense: true,
                                prefixIcon: Icon(Icons.swap_horiz, size: 18),
                              ),
                              onChanged: (v) {
                                final w = double.tryParse(v);
                                if (w != null && w > 0) {
                                  setState(() {
                                    _ncrWidthCm = w;
                                    _ncrSetsPerSheet = _calcNcrSetsPerSheet(_ncrWidthCm, _ncrHeightCm);
                                  });
                                }
                              },
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text('×', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: _ncrHeightCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'الطول', suffixText: 'سم', isDense: true,
                                prefixIcon: Icon(Icons.height, size: 18),
                              ),
                              onChanged: (v) {
                                final h = double.tryParse(v);
                                if (h != null && h > 0) {
                                  setState(() {
                                    _ncrHeightCm = h;
                                    _ncrSetsPerSheet = _calcNcrSetsPerSheet(_ncrWidthCm, _ncrHeightCm);
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_fix_high, size: 16, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              'حساب تلقائي: $_ncrSetsPerSheet وصل/فرخ 50×35',
                              style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                if (isNarrow) ...[
                  copiesField,
                  const SizedBox(height: 12),
                  sheetsField,
                  const SizedBox(height: 12),
                  booksField,
                ] else ...[
                  Row(
                    children: [
                      Expanded(child: copiesField),
                      const SizedBox(width: 12),
                      Expanded(child: sheetsField),
                      const SizedBox(width: 12),
                      Expanded(child: booksField),
                    ],
                  ),
                ],
                const SizedBox(height: 16),

                // توزيع أوراق الألوان لكل نسخة
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    border: Border.all(color: AppTheme.borderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('توزيع ألوان الورق المكربن لكل نسخة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      for (int i = 0; i < _ncrCopies; i++) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 95,
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppTheme.borderColor)),
                                child: Text(i == 0 ? 'الأصل (الأولى)' : 'صورة رقم $i', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonFormField<PaperItem>(
                                  initialValue: _ncrPapers[i],
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    labelText: 'خامة النسخة ${i + 1}',
                                  ),
                                  items: erp.papers.where((p) => p.category == 'NCR' || p.category == 'ورق مكربن').map((p) {
                                    return DropdownMenuItem(value: p, child: Text(isAdmin ? '${p.displayName} (${p.sheetPrice} ر.ي)' : p.displayName));
                                  }).toList(),
                                  onChanged: (p) => setState(() => _ncrPapers[i] = p),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // الماكينة والترقيم والتجميع
                if (isNarrow) ...[
                  DropdownButtonFormField<MachineItem>(
                    initialValue: _ncrMachine,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'ماكينة الطباعة'),
                    items: erp.machines.map((m) {
                      return DropdownMenuItem(value: m, child: Text('${m.name} (${m.wastePct}% هالك)'));
                    }).toList(),
                    onChanged: (m) => setState(() => _ncrMachine = m),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Switch(
                        value: _ncrHasNumbering,
                        onChanged: (v) => setState(() => _ncrHasNumbering = v),
                      ),
                      const SizedBox(width: 8),
                      const Text('ترقيم تسلسلي'),
                    ],
                  ),
                  Row(
                    children: [
                      Switch(
                        value: _ncrHasAssembly,
                        onChanged: (v) => setState(() => _ncrHasAssembly = v),
                      ),
                      const SizedBox(width: 8),
                      const Text('تجميع وتجليد قماش'),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<MachineItem>(
                          initialValue: _ncrMachine,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'ماكينة الطباعة'),
                          items: erp.machines.map((m) {
                            return DropdownMenuItem(value: m, child: Text('${m.name} (${m.wastePct}% هالك)'));
                          }).toList(),
                          onChanged: (m) => setState(() => _ncrMachine = m),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Switch(
                              value: _ncrHasNumbering,
                              onChanged: (v) => setState(() => _ncrHasNumbering = v),
                            ),
                            const SizedBox(width: 4),
                            const Expanded(child: Text('ترقيم', overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Switch(
                              value: _ncrHasAssembly,
                              onChanged: (v) => setState(() => _ncrHasAssembly = v),
                            ),
                            const SizedBox(width: 4),
                            const Expanded(child: Text('تجليد قماش', overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  // مدخلات قالب الكرت
  Widget _buildCardInputs(ErpProvider erp, bool isAdmin) {
    final imposition = PricingEngineService.calculateImposition(
      sheetWidthCm: _cardSheetSize.contains('50') ? 50.0 : 100.0,
      sheetHeightCm: _cardSheetSize.contains('35') ? 35.0 : 70.0,
      itemWidthCm: _cardWidthCm,
      itemHeightCm: _cardHeightCm,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 650;

            final widthField = TextFormField(
              controller: _cardWidthCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'عرض الكرت (سم)', prefixIcon: Icon(Icons.straighten)),
              onChanged: (v) => setState(() => _cardWidthCm = double.tryParse(v) ?? 9.0),
            );

            final heightField = TextFormField(
              controller: _cardHeightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'طول الكرت (سم)', prefixIcon: Icon(Icons.height)),
              onChanged: (v) => setState(() => _cardHeightCm = double.tryParse(v) ?? 5.5),
            );

            final qtyField = TextFormField(
              controller: _cardQtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'الكمية (كروت)', prefixIcon: Icon(Icons.copy_all)),
              onChanged: (v) => setState(() => _cardQty = int.tryParse(v) ?? 1000),
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.credit_card, color: AppTheme.primaryGreen),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('مدخلات الكرت: المقاس والتوزيع في الفرخ والقص والتشطيب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 12),

                // أزرار مقاسات سريعة
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    ActionChip(
                      label: const Text('كرت (9 × 5.5)', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        setState(() {
                          _cardWidthCm = 9.0;
                          _cardHeightCm = 5.5;
                          _cardWidthCtrl.text = '9.0';
                          _cardHeightCtrl.text = '5.5';
                        });
                      },
                    ),
                    ActionChip(
                      label: const Text('كرت (9 × 5)', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        setState(() {
                          _cardWidthCm = 9.0;
                          _cardHeightCm = 5.0;
                          _cardWidthCtrl.text = '9.0';
                          _cardHeightCtrl.text = '5.0';
                        });
                      },
                    ),
                    ActionChip(
                      label: const Text('A6 (14.8 × 10.5)', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        setState(() {
                          _cardWidthCm = 14.8;
                          _cardHeightCm = 10.5;
                          _cardWidthCtrl.text = '14.8';
                          _cardHeightCtrl.text = '10.5';
                        });
                      },
                    ),
                    ActionChip(
                      label: const Text('A5 (21 × 14.8)', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        setState(() {
                          _cardWidthCm = 21.0;
                          _cardHeightCm = 14.8;
                          _cardWidthCtrl.text = '21.0';
                          _cardHeightCtrl.text = '14.8';
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (isNarrow) ...[
                  widthField,
                  const SizedBox(height: 10),
                  heightField,
                  const SizedBox(height: 10),
                  qtyField,
                ] else ...[
                  Row(
                    children: [
                      Expanded(child: widthField),
                      const SizedBox(width: 12),
                      Expanded(child: heightField),
                      const SizedBox(width: 12),
                      Expanded(child: qtyField),
                    ],
                  ),
                ],
                const SizedBox(height: 14),

                // بطاقة التوزيع الذكي داخل الفرخ
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.grid_view, color: AppTheme.primaryGreen, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'توزيع الفرخ (${imposition.layoutDirection}): الفرخ ينتج ${imposition.totalItemsPerSheet} كرت (${imposition.itemsAlongWidth} × ${imposition.itemsAlongHeight})',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // الورق ومقاس الفرخ والوجهات
                if (isNarrow) ...[
                  DropdownButtonFormField<PaperItem>(
                    initialValue: _cardPaper,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'خامة ورق الكرت'),
                    items: erp.papers.map((p) {
                      return DropdownMenuItem(value: p, child: Text(isAdmin ? '${p.displayName} (${p.sheetPrice} ر.ي)' : p.displayName));
                    }).toList(),
                    onChanged: (p) => setState(() => _cardPaper = p),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _cardSheetSize,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'مقاس الفرخ'),
                    items: const [
                      DropdownMenuItem(value: '100x70', child: Text('فرخ كامل 100×70 سم')),
                      DropdownMenuItem(value: '50x35', child: Text('نصف فرخ 50×35 سم')),
                    ],
                    onChanged: (v) => setState(() => _cardSheetSize = v ?? '100x70'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue: _cardPrintSides,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'وجهات الطباعة'),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('وجه واحد (4/0)')),
                      DropdownMenuItem(value: 2, child: Text('وجهين (4/4)')),
                    ],
                    onChanged: (v) => setState(() => _cardPrintSides = v ?? 1),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<MachineItem>(
                    initialValue: _cardMachine,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'ماكينة الطباعة'),
                    items: erp.machines.map((m) {
                      return DropdownMenuItem(value: m, child: Text('${m.name} (${m.wastePct}% هالك)'));
                    }).toList(),
                    onChanged: (m) => setState(() => _cardMachine = m),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Switch(
                        value: _cardHasCutting,
                        onChanged: (v) => setState(() => _cardHasCutting = v),
                      ),
                      const SizedBox(width: 8),
                      const Text('قص آلي'),
                      const SizedBox(width: 20),
                      Switch(
                        value: _cardHasLamination,
                        onChanged: (v) => setState(() => _cardHasLamination = v),
                      ),
                      const SizedBox(width: 8),
                      const Text('سلوفان'),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<PaperItem>(
                          initialValue: _cardPaper,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'خامة ورق الكرت'),
                          items: erp.papers.map((p) {
                            return DropdownMenuItem(value: p, child: Text(isAdmin ? '${p.displayName} (${p.sheetPrice} ر.ي)' : p.displayName));
                          }).toList(),
                          onChanged: (p) => setState(() => _cardPaper = p),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          initialValue: _cardSheetSize,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'مقاس الفرخ'),
                          items: const [
                            DropdownMenuItem(value: '100x70', child: Text('100×70 سم')),
                            DropdownMenuItem(value: '50x35', child: Text('50×35 سم')),
                          ],
                          onChanged: (v) => setState(() => _cardSheetSize = v ?? '100x70'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<int>(
                          initialValue: _cardPrintSides,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'الطباعة'),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('وجه (4/0)')),
                            DropdownMenuItem(value: 2, child: Text('وجهين (4/4)')),
                          ],
                          onChanged: (v) => setState(() => _cardPrintSides = v ?? 1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<MachineItem>(
                          initialValue: _cardMachine,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'ماكينة الطباعة'),
                          items: erp.machines.map((m) {
                            return DropdownMenuItem(value: m, child: Text('${m.name} (${m.wastePct}% هالك)'));
                          }).toList(),
                          onChanged: (m) => setState(() => _cardMachine = m),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Switch(
                              value: _cardHasCutting,
                              onChanged: (v) => setState(() => _cardHasCutting = v),
                            ),
                            const SizedBox(width: 4),
                            const Expanded(child: Text('قص آلي', overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Switch(
                              value: _cardHasLamination,
                              onChanged: (v) => setState(() => _cardHasLamination = v),
                            ),
                            const SizedBox(width: 4),
                            const Expanded(child: Text('سلوفان', overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  // مدخلات قالب مخصص
  Widget _buildCustomInputs(ErpProvider erp, bool isAdmin) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 650;

            final productField = DropdownButtonFormField<ProductTemplate>(
              initialValue: _selectedCustomProduct,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'اختر القالب'),
              items: erp.products.map((p) {
                return DropdownMenuItem(value: p, child: Text('${p.name} (${p.category})'));
              }).toList(),
              onChanged: (p) => setState(() => _selectedCustomProduct = p),
            );

            final qtyField = TextFormField(
              controller: _customQtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'الكمية المطلوبة'),
              onChanged: (v) => setState(() => _customQty = int.tryParse(v) ?? 1000),
            );

            final pagesField = TextFormField(
              controller: _customPagesCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'عدد الصفحات'),
              onChanged: (v) => setState(() => _customPages = int.tryParse(v) ?? 16),
            );

            final paperField = DropdownButtonFormField<PaperItem>(
              initialValue: _customPaper,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'الخامة'),
              items: erp.papers.map((p) {
                return DropdownMenuItem(value: p, child: Text(p.displayName));
              }).toList(),
              onChanged: (p) => setState(() => _customPaper = p),
            );

            final machineField = DropdownButtonFormField<MachineItem>(
              initialValue: _customMachine,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'الماكينة'),
              items: erp.machines.map((m) {
                return DropdownMenuItem(value: m, child: Text(m.name));
              }).toList(),
              onChanged: (m) => setState(() => _customMachine = m),
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.dashboard_customize, color: AppTheme.primaryGreen),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('مدخلات قالب مخصص: منتجات مفتوحة وقابلة للإضافة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 12),

                if (isNarrow) ...[
                  productField,
                  const SizedBox(height: 10),
                  qtyField,
                  const SizedBox(height: 10),
                  pagesField,
                  const SizedBox(height: 10),
                  paperField,
                  const SizedBox(height: 10),
                  machineField,
                ] else ...[
                  Row(
                    children: [
                      Expanded(flex: 2, child: productField),
                      const SizedBox(width: 12),
                      Expanded(flex: 1, child: qtyField),
                      const SizedBox(width: 12),
                      Expanded(flex: 1, child: pagesField),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(flex: 2, child: paperField),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: machineField),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  // كرت الثوابت والربح والضريبة
  Widget _buildPricingConstantsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;

            final plateField = TextFormField(
              controller: _plateCostCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'سعر البليت/الزنك'),
              onChanged: (v) => setState(() => _plateCost = double.tryParse(v) ?? 1250),
            );

            final marginField = TextFormField(
              controller: _marginCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'هامش الربح (%)'),
              onChanged: (v) => setState(() => _profitMarginPct = double.tryParse(v) ?? 30),
            );

            final taxField = TextFormField(
              controller: _taxCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'الضريبة (%)'),
              onChanged: (v) => setState(() => _taxPct = double.tryParse(v) ?? 0),
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.tune, color: AppTheme.primaryGreen),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('ثوابت التسعير والربح والضريبة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                if (isNarrow) ...[
                  plateField,
                  const SizedBox(height: 10),
                  marginField,
                  const SizedBox(height: 10),
                  taxField,
                ] else ...[
                  Row(
                    children: [
                      Expanded(child: plateField),
                      const SizedBox(width: 12),
                      Expanded(child: marginField),
                      const SizedBox(width: 12),
                      Expanded(child: taxField),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  // =========================================================================
  // قسم النتائج ومسار الحساب التفصيلي
  // =========================================================================
  Widget _buildOutputsSection(PricingResult result, ErpProvider erp, bool isAdmin) {
    return Column(
      children: [
        // كرت الإجماليات الكبرى
        Card(
          color: AppTheme.darkSlate,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmall = constraints.maxWidth < 320;
                    if (isSmall) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('سعر بيع الوحدة', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                          Text(
                            '${result.unitPrice.toStringAsFixed(2)} ${erp.settings.currency}',
                            style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text('إجمالي البيع المقترح', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                          Text(
                            '${AppTheme.formatCurrency(result.lineAmount)} ${erp.settings.currency}',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      );
                    }
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('سعر بيع الوحدة', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(
                                '${result.unitPrice.toStringAsFixed(2)} ${erp.settings.currency}',
                                style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 22, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('إجمالي البيع المقترح', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(
                                '${AppTheme.formatCurrency(result.lineAmount)} ${erp.settings.currency}',
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const Divider(color: Colors.white24, height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 10,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    if (isAdmin) _buildMiniMetric('التكلفة الصناعية', AppTheme.formatCurrency(result.lineTotalCost)),
                    if (isAdmin) _buildMiniMetric('صافي الربح', AppTheme.formatCurrency(result.profit), valueColor: const Color(0xFF4ADE80)),
                    if (result.taxPct > 0)
                      _buildMiniMetric('الضريبة (${result.taxPct}%)', AppTheme.formatCurrency(result.taxAmount)),
                    if (result.taxPct > 0)
                      _buildMiniMetric('الإجمالي مع الضريبة', AppTheme.formatCurrency(result.grandTotalAmount), valueColor: const Color(0xFFFBBF24)),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (isAdmin) const SizedBox(height: 16),

        // بطاقة مسار الحساب المتسلسل (Step-by-Step Pipeline) — للمدير فقط.
        if (isAdmin) Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.route, color: AppTheme.primaryGreen),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('مسار الحساب التفصيلي خطوة بخطوة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('تسلسل الحساب وتفاصيل التكلفة في كل مرحلة من مراحل التصنيع', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                const Divider(),
                const SizedBox(height: 8),

                // الخطوات المتسلسلة
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: result.stepDetails.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final step = result.stepDetails[idx];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        border: Border.all(color: AppTheme.borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 11,
                                backgroundColor: AppTheme.primaryGreen,
                                child: Text('${idx + 1}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(step.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkSlate)),
                              ),
                              if (step.cost > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${step.cost.toStringAsFixed(1)} ${erp.settings.currency}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen, fontSize: 11),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(step.description, style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                          if (step.metrics.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: step.metrics.entries.map((m) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: AppTheme.borderColor),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${m.key}: ${m.value}',
                                    style: const TextStyle(fontSize: 10, color: AppTheme.darkSlate),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: () => _showSaveQuotationDialog(result),
              icon: const Icon(Icons.bookmark_add_outlined, size: 18),
              label: const Text('حفظ كعرض سعر رسمي'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final tempQuote = Quotation(
                  id: 'TEMP_PREVIEW',
                  number: 'PREVIEW-${DateTime.now().millisecondsSinceEpoch % 10000}',
                  date: DateTime.now(),
                  customerId: 'CUST-TEMP',
                  customerCode: 'CUST',
                  customerName: 'عميل عام / عرض سعر مباشر',
                  product: result.productName,
                  qty: result.qty,
                  pages: result.pages,
                  ncrCopies: result.ncrCopies,
                  paper: '${result.paperCategory} ${result.paperType} ${result.paperGsm}جم',
                  machine: result.machineName,
                  unitPrice: result.unitPrice,
                  totalCost: result.lineTotalCost,
                  quoteAmount: result.lineAmount,
                  profit: result.profit,
                  pricingDetails: result,
                );
                PdfExportService.printOrPreviewQuotation(
                  context,
                  quotation: tempQuote,
                  settings: erp.settings,
                );
              },
              icon: const Icon(Icons.print_outlined, size: 18),
              label: const Text('معاينة وطباعة PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.darkSlate,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {
                final tempQuote = Quotation(
                  id: 'TEMP_SHARE',
                  number: 'QUOTE-${DateTime.now().millisecondsSinceEpoch % 10000}',
                  date: DateTime.now(),
                  customerId: 'CUST-TEMP',
                  customerCode: 'CUST',
                  customerName: 'عميل عام / عرض سعر مباشر',
                  product: result.productName,
                  qty: result.qty,
                  pages: result.pages,
                  ncrCopies: result.ncrCopies,
                  paper: '${result.paperCategory} ${result.paperType} ${result.paperGsm}جم',
                  machine: result.machineName,
                  unitPrice: result.unitPrice,
                  totalCost: result.lineTotalCost,
                  quoteAmount: result.lineAmount,
                  profit: result.profit,
                  pricingDetails: result,
                );
                PdfExportService.shareQuotationPdf(
                  quotation: tempQuote,
                  settings: erp.settings,
                );
              },
              icon: const Icon(Icons.share_outlined, size: 18),
              label: const Text('مشاركة PDF'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniMetric(String title, String val, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          val,
          style: TextStyle(color: valueColor ?? Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  // حوار إنشاء وحفظ عرض سعر رسمي بتصميم عصري راقٍ
  void _showSaveQuotationDialog(PricingResult result) {
    final erp = context.read<ErpProvider>();
    Customer? selectedCustomer = erp.customers.isNotEmpty ? erp.customers.first : null;
    final notesCtrl = TextEditingController(text: 'تسعير تلقائي لـ ${result.productName}');
    String status = 'مسودة';

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isMobile = MediaQuery.of(ctx).size.width < 600;

          return Dialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 480),
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
                            child: const Icon(Icons.request_quote_rounded, color: AppTheme.primaryGreen, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'حفظ كعرض سعر جديد',
                                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'إنشاء وتوثيق عرض سعر رسمي للعميل',
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

                      // اختيار العميل
                      DropdownButtonFormField<Customer>(
                        isExpanded: true,
                        initialValue: selectedCustomer,
                        decoration: const InputDecoration(
                          labelText: 'اختر العميل',
                          prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.primaryGreen, size: 20),
                        ),
                        items: erp.customers.map((c) {
                          return DropdownMenuItem(
                            value: c,
                            child: Text(
                              '${c.name} (${c.code})',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          );
                        }).toList(),
                        selectedItemBuilder: (context) {
                          return erp.customers.map((c) {
                            return Text(
                              '${c.name} (${c.code})',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            );
                          }).toList();
                        },
                        onChanged: (c) => setDialogState(() => selectedCustomer = c),
                      ),
                      const SizedBox(height: 14),

                      // حالة العرض
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: status,
                        decoration: const InputDecoration(
                          labelText: 'حالة العرض والاعتماد',
                          prefixIcon: Icon(Icons.verified_outlined, color: AppTheme.primaryGreen, size: 20),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'مسودة',
                            child: Text('مسودة (Draft) - بدون توليد أمر إنتاج', overflow: TextOverflow.ellipsis, maxLines: 1),
                          ),
                          DropdownMenuItem(
                            value: 'معتمد',
                            child: Text('معتمد (Approved) - توليد أمر إنتاج آلياً', overflow: TextOverflow.ellipsis, maxLines: 1),
                          ),
                        ],
                        selectedItemBuilder: (context) => const [
                          Text('مسودة (Draft)', overflow: TextOverflow.ellipsis, maxLines: 1),
                          Text('معتمد (توليد أمر إنتاج تلقائياً)', overflow: TextOverflow.ellipsis, maxLines: 1),
                        ],
                        onChanged: (s) => setDialogState(() => status = s ?? 'مسودة'),
                      ),
                      const SizedBox(height: 14),

                      // ملاحظات العرض
                      TextFormField(
                        controller: notesCtrl,
                        decoration: const InputDecoration(
                          labelText: 'ملاحظات وتفاصيل العرض',
                          prefixIcon: Icon(Icons.note_alt_outlined, color: AppTheme.primaryGreen, size: 20),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 18),

                      // كرت بطاقة القيمة الإجمالية والأرباح
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.receipt_long_rounded, color: AppTheme.darkSlate, size: 18),
                                    SizedBox(width: 8),
                                    Text('القيمة الإجمالية:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkSlate)),
                                  ],
                                ),
                                Text(
                                  AppTheme.formatCurrency(result.lineAmount, erp.settings.currency),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.darkSlate),
                                ),
                              ],
                            ),
                            if (context.read<AuthProvider>().isAdmin) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Divider(height: 1, color: Color(0xFFDCFCE7)),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.trending_up_rounded, color: Color(0xFF16A34A), size: 18),
                                      SizedBox(width: 8),
                                      Text('صافي الربح المتوقع:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF16A34A))),
                                    ],
                                  ),
                                  Text(
                                    AppTheme.formatCurrency(result.profit, erp.settings.currency),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF16A34A)),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),

                      // أزرار الإجراءات السفلية المتجاوبة
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
                              onPressed: () async {
                                if (selectedCustomer == null) return;
                                await erp.addQuotation(
                                  customerId: selectedCustomer!.id,
                                  customerCode: selectedCustomer!.code,
                                  customerName: selectedCustomer!.name,
                                  product: result.productName,
                                  qty: result.qty,
                                  pages: result.pages,
                                  ncrCopies: result.ncrCopies,
                                  paper: '${result.paperCategory} ${result.paperType} ${result.paperGsm}جم',
                                  machine: result.machineName,
                                  unitPrice: result.unitPrice,
                                  totalCost: result.lineTotalCost,
                                  quoteAmount: result.lineAmount,
                                  profit: result.profit,
                                  notes: notesCtrl.text,
                                  pricingDetails: result,
                                  status: status,
                                );
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.white, size: 18),
                                        SizedBox(width: 8),
                                        Text('تم إنشاء وحفظ عرض السعر بنجاح!'),
                                      ],
                                    ),
                                    backgroundColor: AppTheme.primaryGreen,
                                  ),
                                );
                                if (widget.onNavigate != null) widget.onNavigate!(2);
                              },
                              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                              label: const Text('تأكيد وحفظ العرض', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryGreen,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
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
          );
        },
      ),
    );
  }
}
