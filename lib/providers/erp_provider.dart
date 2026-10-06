import 'package:flutter/foundation.dart';
import '../models/app_models.dart';
import '../services/storage_service.dart';
import '../services/pricing_engine_service.dart';

/// نتيجة عملية أعمال يمكن عرض رسالتها في الواجهة دون الاعتماد على الاستثناءات.
class DomainOperationResult {
  final bool isSuccess;
  final String message;

  const DomainOperationResult._(this.isSuccess, this.message);

  factory DomainOperationResult.success(String message) =>
      DomainOperationResult._(true, message);
  factory DomainOperationResult.failure(String message) =>
      DomainOperationResult._(false, message);
}

class ErpProvider with ChangeNotifier {
  final StorageService _storage;

  AppSettings _settings = AppSettings();
  List<PaperItem> _papers = [];
  List<MachineItem> _machines = [];
  List<ProductTemplate> _products = [];
  List<FinishingItem> _finishings = [];
  List<InkItem> _inks = [];
  List<InkMove> _inkMoves = [];
  List<Customer> _customers = [];
  List<Quotation> _quotations = [];
  List<ProductionOrder> _productionOrders = [];
  List<StockMove> _stockMoves = [];
  List<PaymentRecord> _payments = [];
  List<CustomerLedgerEntry> _customerLedger = [];

  ErpProvider(this._storage) {
    _loadAll();
  }

  bool get _hasAdminPermission =>
      !_storage.hasUsers() || _storage.getActiveUser()?.role == UserRole.admin;

  Future<DomainOperationResult?> _requireAdminForOperation(String action) async {
    if (_hasAdminPermission) return null;
    await recordAudit(
      action: 'authorization_denied',
      targetType: 'permission',
      details: 'تم رفض العملية الإدارية: $action',
      success: false,
      severity: AuditSeverity.warning,
    );
    return DomainOperationResult.failure('هذه العملية متاحة للمدير فقط');
  }

  void _loadAll() {
    _settings = _storage.loadSettings();
    _papers = _storage.loadPapers();
    _machines = _storage.loadMachines();
    _products = _storage.loadProducts();
    _finishings = _storage.loadFinishings();
    _inks = _storage.loadInks();
    _inkMoves = _storage.loadInkMoves();
    _customers = _storage.loadCustomers();
    _quotations = _storage.loadQuotations();
    _productionOrders = _storage.loadProductionOrders();
    _stockMoves = _storage.loadStockMoves();
    _payments = _storage.loadPayments();
    _customerLedger = _storage.loadCustomerLedger();
    _syncAllCustomerSummariesFromLedger();
  }

  // --- GETTERS ---
  AppSettings get settings => _settings;
  List<PaperItem> get papers => List.unmodifiable(_papers);
  List<MachineItem> get machines => List.unmodifiable(_machines);
  List<ProductTemplate> get products => List.unmodifiable(_products);
  List<FinishingItem> get finishings => List.unmodifiable(_finishings);
  List<InkItem> get inks => List.unmodifiable(_inks);
  List<InkMove> get inkMoves => List.unmodifiable(_inkMoves);
  List<Customer> get customers => List.unmodifiable(_customers);
  List<Quotation> get quotations => List.unmodifiable(_quotations);
  List<ProductionOrder> get productionOrders => List.unmodifiable(_productionOrders);
  List<StockMove> get stockMoves => List.unmodifiable(_stockMoves);
  List<PaymentRecord> get payments => List.unmodifiable(_payments);
  List<CustomerLedgerEntry> get customerLedger => List.unmodifiable(_customerLedger);

  List<CustomerLedgerEntry> ledgerForCustomer(String customerId) =>
      List.unmodifiable(_customerLedger
          .where((entry) => entry.customerId == customerId)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date)));

  // --- KPI & STATS CALCULATIONS (محاكاة تقارير_الربحية ولوحة_المؤشرات) ---
  /// إجمالي المبيعات (قيمة العروض المعتمدة)
  double get totalApprovedSales {
    return _quotations
        .where((q) => q.status == 'معتمد')
        .fold(0.0, (sum, q) => sum + q.quoteAmount);
  }

  /// إجمالي التكلفة للعروض المعتمدة
  double get totalApprovedCost {
    return _quotations
        .where((q) => q.status == 'معتمد')
        .fold(0.0, (sum, q) => sum + q.totalCost);
  }

  /// إجمالي الأرباح المحققة
  double get totalProfit => totalApprovedSales - totalApprovedCost;

  /// هامش الربح الإجمالي %
  double get overallMarginPct {
    if (totalApprovedSales <= 0) return 0.0;
    return (totalProfit / totalApprovedSales) * 100.0;
  }

  /// قيمة مخزون الورق الحالية
  double get totalPaperInventoryValue {
    return _papers.fold(0.0, (sum, p) => sum + p.totalValue);
  }

  /// قيمة مخزون الأحبار الحالية
  double get totalInkInventoryValue {
    return _inks.fold(0.0, (sum, i) => sum + i.totalValue);
  }

  /// إجمالي قيمة المخزون الكلي (ورق + أحبار)
  double get totalInventoryValue => totalPaperInventoryValue + totalInkInventoryValue;

  /// إجمالي ذمم العملاء المستحقة
  double get totalReceivables {
    return _customers.fold(0.0, (sum, c) => sum + c.currentBalance);
  }

  /// عدد العروض المعتمدة
  int get approvedQuotationsCount => _quotations.where((q) => q.status == 'معتمد').length;

  /// عدد الأوامر المكتملة
  int get completedOrdersCount => _productionOrders.where((o) => o.status == 'مكتمل').length;

  /// عدد الأوامر قيد الإنتاج
  int get inProgressOrdersCount => _productionOrders.where((o) => o.status == 'قيد الإنتاج').length;

  /// تنبيهات الأصناف التي وصلت لحد إعادة الطلب
  List<PaperItem> get lowStockPapers => _papers.where((p) => p.isUnderReorder).toList();
  List<InkItem> get lowStockInks => _inks.where((i) => i.isUnderReorder).toList();

  // --- SETTINGS ACTIONS ---
  Future<DomainOperationResult> updateSettings(AppSettings newSettings) async {
    final permission = await _requireAdminForOperation('update_settings');
    if (permission != null) return permission;
    _settings = newSettings;
    await _storage.saveSettings(_settings);
    notifyListeners();
    return DomainOperationResult.success('تم تحديث الإعدادات');
  }

  // --- PRICING ENGINE LIVE CALCULATION ---
  PricingResult calculatePrice({
    required ProductTemplate product,
    required int qty,
    required int pages,
    required int ncrCopies,
    required int sheetsPerBook,
    required int booksCount,
    required int colorsCount,
    required int platesCount,
    required double plateCost,
    required double profitMarginPct,
    required PaperItem paper,
    required MachineItem machine,
    required List<String> selectedFinishingIds,
    double? taxPct,
  }) {
    return PricingEngineService.calculate(
      product: product,
      qty: qty,
      pages: pages,
      ncrCopies: ncrCopies,
      sheetsPerBook: sheetsPerBook,
      booksCount: booksCount,
      colorsCount: colorsCount,
      platesCount: platesCount,
      plateCost: plateCost,
      profitMarginPct: profitMarginPct,
      paper: paper,
      machine: machine,
      allFinishings: _finishings,
      selectedFinishingIds: selectedFinishingIds,
      taxPct: taxPct ?? _settings.taxPct,
    );
  }

  /// حساب تكلفة وسعر الكتاب (قالب الكتاب)
  PricingResult calculateBookPrice({
    required String productName,
    required int pages,
    required int pagesPerSignature,
    required int qty,
    required PaperItem innerPaper,
    required MachineItem machine,
    required int innerColors,
    required PaperItem coverPaper,
    required int coverFitsPerSheet,
    required int coverColors,
    required bool coverLamination,
    FinishingItem? laminationFinishing,
    required String bindingType,
    FinishingItem? bindingFinishing,
    required List<String> selectedFinishingIds,
    double? plateCost,
    double? profitMarginPct,
    double? taxPct,
  }) {
    return PricingEngineService.calculateBookPricing(
      productName: productName,
      pages: pages,
      pagesPerSignature: pagesPerSignature,
      qty: qty,
      innerPaper: innerPaper,
      machine: machine,
      innerColors: innerColors,
      coverPaper: coverPaper,
      coverFitsPerSheet: coverFitsPerSheet,
      coverColors: coverColors,
      coverLamination: coverLamination,
      laminationFinishing: laminationFinishing,
      bindingType: bindingType,
      bindingFinishing: bindingFinishing,
      allFinishings: _finishings,
      selectedFinishingIds: selectedFinishingIds,
      plateCost: plateCost ?? _settings.defaultPlatePrice,
      profitMarginPct: profitMarginPct ?? _settings.defaultProfitMarginPct,
      taxPct: taxPct ?? _settings.taxPct,
    );
  }

  /// حساب تكلفة وسعر دفاتر NCR (قالب الـ NCR)
  PricingResult calculateNcrPrice({
    required String productName,
    required int ncrCopies,
    required int sheetsPerBook,
    required int booksCount,
    required List<PaperItem> papersPerColor,
    required int setsPerSheet,
    required MachineItem machine,
    required int colorsCount,
    required bool hasNumbering,
    FinishingItem? numberingFinishing,
    required bool hasAssemblyAndBinding,
    FinishingItem? assemblyFinishing,
    required List<String> selectedFinishingIds,
    double? plateCost,
    double? profitMarginPct,
    double? taxPct,
  }) {
    return PricingEngineService.calculateNcrPricing(
      productName: productName,
      ncrCopies: ncrCopies,
      sheetsPerBook: sheetsPerBook,
      booksCount: booksCount,
      papersPerColor: papersPerColor,
      setsPerSheet: setsPerSheet,
      machine: machine,
      colorsCount: colorsCount,
      hasNumbering: hasNumbering,
      numberingFinishing: numberingFinishing,
      hasAssemblyAndBinding: hasAssemblyAndBinding,
      assemblyFinishing: assemblyFinishing,
      allFinishings: _finishings,
      selectedFinishingIds: selectedFinishingIds,
      plateCost: plateCost ?? _settings.defaultPlatePrice,
      profitMarginPct: profitMarginPct ?? _settings.defaultProfitMarginPct,
      taxPct: taxPct ?? _settings.taxPct,
    );
  }

  /// حساب تكلفة وسعر الكروت والمطبوعات الفردية (قالب الكرت)
  PricingResult calculateCardPrice({
    required String productName,
    required double cardWidthCm,
    required double cardHeightCm,
    required int qty,
    required PaperItem paper,
    required String sheetSize,
    required int printSides,
    required MachineItem machine,
    required int colorsCount,
    required bool hasCutting,
    FinishingItem? cuttingFinishing,
    required bool hasLamination,
    FinishingItem? laminationFinishing,
    required List<String> selectedFinishingIds,
    double? plateCost,
    double? profitMarginPct,
    double? taxPct,
  }) {
    return PricingEngineService.calculateCardPricing(
      productName: productName,
      cardWidthCm: cardWidthCm,
      cardHeightCm: cardHeightCm,
      qty: qty,
      paper: paper,
      sheetSize: sheetSize,
      printSides: printSides,
      machine: machine,
      colorsCount: colorsCount,
      hasCutting: hasCutting,
      cuttingFinishing: cuttingFinishing,
      hasLamination: hasLamination,
      laminationFinishing: laminationFinishing,
      allFinishings: _finishings,
      selectedFinishingIds: selectedFinishingIds,
      plateCost: plateCost ?? _settings.defaultPlatePrice,
      profitMarginPct: profitMarginPct ?? _settings.defaultProfitMarginPct,
      taxPct: taxPct ?? _settings.taxPct,
    );
  }

  // --- ACTIONS FOR DIRECT PRICE MANAGEMENT (قسم إدارة الأسعار الفوري) ---
  /// تعديل سعر فرخ الورق (للمدير فقط).
  Future<DomainOperationResult> updatePaperPrice(String paperId, double newPrice) async {
    final permission = await _requireAdminForOperation('update_paper_price');
    if (permission != null) return permission;
    if (!newPrice.isFinite || newPrice < 0) {
      return DomainOperationResult.failure('سعر الورق غير صالح');
    }
    final idx = _papers.indexWhere((p) => p.id == paperId);
    if (idx == -1) return DomainOperationResult.failure('صنف الورق غير موجود');
    _papers[idx].sheetPrice = newPrice;
    await _storage.savePapers(_papers);
    notifyListeners();
    return DomainOperationResult.success('تم تحديث سعر الورق');
  }

  /// تعديل معايير وأسعار الماكينة (تكلفة الساعة، السرعة، الهالك) للمدير فقط.
  Future<DomainOperationResult> updateMachineRates({
    required String machineId,
    double? hourlyCost,
    int? speedPerHour,
    double? wastePct,
  }) async {
    final permission = await _requireAdminForOperation('update_machine_rates');
    if (permission != null) return permission;
    if ((hourlyCost != null && (!hourlyCost.isFinite || hourlyCost < 0)) ||
        (speedPerHour != null && speedPerHour <= 0) ||
        (wastePct != null && (!wastePct.isFinite || wastePct < 0))) {
      return DomainOperationResult.failure('قيم تسعير الماكينة غير صالحة');
    }
    final idx = _machines.indexWhere((m) => m.id == machineId);
    if (idx == -1) return DomainOperationResult.failure('الماكينة غير موجودة');
    if (hourlyCost != null) _machines[idx].hourlyCost = hourlyCost;
    if (speedPerHour != null) _machines[idx].speedPerHour = speedPerHour;
    if (wastePct != null) _machines[idx].wastePct = wastePct;
    await _storage.saveMachines(_machines);
    notifyListeners();
    return DomainOperationResult.success('تم تحديث أسعار ومعايير الماكينة');
  }

  /// تعديل سعر خدمة التشطيب للمدير فقط.
  Future<DomainOperationResult> updateFinishingPrice(String finishingId, double newPrice, [String? unit]) async {
    final permission = await _requireAdminForOperation('update_finishing_price');
    if (permission != null) return permission;
    if (!newPrice.isFinite || newPrice < 0) {
      return DomainOperationResult.failure('سعر التشطيب غير صالح');
    }
    final idx = _finishings.indexWhere((f) => f.id == finishingId);
    if (idx == -1) return DomainOperationResult.failure('خدمة التشطيب غير موجودة');
    _finishings[idx].price = newPrice;
    if (unit != null) _finishings[idx].unit = unit;
    await _storage.saveFinishings(_finishings);
    notifyListeners();
    return DomainOperationResult.success('تم تحديث سعر التشطيب');
  }

  /// تعديل الثوابت العامة للتسعير (سعر البليت، هامش الربح، الضريبة) للمدير فقط.
  Future<DomainOperationResult> updatePricingConstants({
    double? platePrice,
    double? profitMarginPct,
    double? taxPct,
  }) async {
    final permission = await _requireAdminForOperation('update_pricing_constants');
    if (permission != null) return permission;
    if ((platePrice != null && (!platePrice.isFinite || platePrice < 0)) ||
        (profitMarginPct != null && (!profitMarginPct.isFinite || profitMarginPct < 0)) ||
        (taxPct != null && (!taxPct.isFinite || taxPct < 0))) {
      return DomainOperationResult.failure('ثوابت التسعير غير صالحة');
    }
    if (platePrice != null) _settings.defaultPlatePrice = platePrice;
    if (profitMarginPct != null) _settings.defaultProfitMarginPct = profitMarginPct;
    if (taxPct != null) _settings.taxPct = taxPct;
    await _storage.saveSettings(_settings);
    notifyListeners();
    return DomainOperationResult.success('تم تحديث ثوابت التسعير');
  }

  // --- QUOTATIONS ACTIONS ---
  String generateNextQuotationNumber() {
    final year = DateTime.now().year;
    final count = _quotations.length + 1;
    return 'Q-$year-${count.toString().padLeft(4, '0')}';
  }

  Future<Quotation> addQuotation({
    required String customerId,
    required String customerName,
    required String customerCode,
    required String product,
    required int qty,
    required int pages,
    int ncrCopies = 0,
    required String paper,
    required String machine,
    required double unitPrice,
    required double totalCost,
    required double quoteAmount,
    required double profit,
    String? notes,
    PricingResult? pricingDetails,
    String status = 'مسودة',
  }) async {
    final approveImmediately = status == 'معتمد';
    final quote = Quotation(
      id: 'Q_${DateTime.now().microsecondsSinceEpoch}',
      number: generateNextQuotationNumber(),
      date: DateTime.now(),
      customerId: customerId,
      customerCode: customerCode,
      customerName: customerName,
      product: product,
      qty: qty,
      pages: pages,
      ncrCopies: ncrCopies,
      paper: paper,
      machine: machine,
      unitPrice: unitPrice,
      totalCost: totalCost,
      quoteAmount: quoteAmount,
      profit: profit,
      notes: notes,
      pricingDetails: pricingDetails,
      status: approveImmediately ? 'مسودة' : status,
    );

    _quotations.insert(0, quote);
    await _storage.saveQuotations(_quotations);

    if (approveImmediately) {
      await updateQuotationStatus(quote.id, 'معتمد');
    }

    notifyListeners();
    return quote;
  }

  Future<DomainOperationResult> updateQuotationStatus(
    String quoteId,
    String newStatus,
  ) async {
    const allowedStatuses = {'مسودة', 'مرسل', 'معتمد', 'مرفوض', 'ملغي'};
    if (!allowedStatuses.contains(newStatus)) {
      return DomainOperationResult.failure('حالة عرض السعر غير معروفة');
    }

    final index = _quotations.indexWhere((quote) => quote.id == quoteId);
    if (index == -1) {
      return DomainOperationResult.failure('تعذر العثور على عرض السعر');
    }

    final quote = _quotations[index];
    final oldStatus = quote.status;
    if (oldStatus == newStatus) {
      return DomainOperationResult.success('عرض السعر في الحالة المطلوبة مسبقاً');
    }
    if (oldStatus == 'ملغي' || oldStatus == 'مرفوض') {
      return DomainOperationResult.failure(
        'العرض $oldStatus نهائي ولا يمكن إعادة فتحه؛ أنشئ نسخة جديدة منه',
      );
    }

    const allowedTransitions = <String, Set<String>>{
      'مسودة': {'مرسل', 'معتمد', 'ملغي'},
      'مرسل': {'مسودة', 'معتمد', 'مرفوض', 'ملغي'},
      'معتمد': {'ملغي'},
    };
    if (!(allowedTransitions[oldStatus]?.contains(newStatus) ?? false)) {
      return DomainOperationResult.failure(
        'لا يسمح بالانتقال من حالة $oldStatus إلى $newStatus',
      );
    }

    if (newStatus == 'معتمد') {
      // لا تسجل أثراً مالياً لأمر لن يستطيع النظام صرف خاماته لاحقاً بسبب حذف
      // صنف مشار إليه في تسعير محفوظ.
      final plannedMaterials = quote.pricingDetails?.materialRequirements ??
          const <PricingMaterialRequirement>[];
      for (final material in plannedMaterials.where((item) => item.quantity > 0)) {
        if (material.materialType == 'paper' &&
            !_papers.any((paper) => paper.id == material.materialId)) {
          return DomainOperationResult.failure(
            'لا يمكن اعتماد العرض: صنف الورق ${material.materialName} لم يعد موجوداً في المخزون',
          );
        }
      }

      final hasOrder = _productionOrders.any(
        (order) => order.quotationId == quote.id,
      );
      final hasSaleEntry = _customerLedger.any(
        (entry) => entry.type == 'sale' && entry.referenceId == quote.id,
      );
      if (hasOrder || hasSaleEntry) {
        return DomainOperationResult.failure(
          'لا يمكن اعتماد العرض مرة أخرى لأن له أثراً مالياً أو أمر إنتاج سابقاً',
        );
      }
      if (oldStatus == 'ملغي' || oldStatus == 'مرفوض') {
        return DomainOperationResult.failure(
          'العرض الملغي أو المرفوض لا يعاد اعتماده؛ أنشئ نسخة جديدة منه',
        );
      }

      quote.status = 'معتمد';
      await _recordCustomerSale(quote);
      await createProductionOrderFromQuote(quote);
      await _storage.saveQuotations(_quotations);
      notifyListeners();
      return DomainOperationResult.success(
        'تم اعتماد العرض وتسجيل القيد وإنشاء أمر الإنتاج',
      );
    }

    if (oldStatus == 'معتمد') {
      if (newStatus != 'ملغي') {
        return DomainOperationResult.failure(
          'العرض المعتمد لا يعود لمسودة أو رفض؛ استخدم إلغاء الاعتماد فقط',
        );
      }

      final relatedOrders = _productionOrders
          .where((order) => order.quotationId == quote.id)
          .toList();
      if (relatedOrders.any((order) => order.isPaperDeducted || order.issuedMaterialsCount > 0)) {
        return DomainOperationResult.failure(
          'لا يمكن إلغاء العرض بعد صرف مواد الإنتاج. أعد المواد أو أنشئ تسوية معتمدة أولاً',
        );
      }

      quote.status = 'ملغي';
      for (final order in relatedOrders) {
        order.status = 'ملغي';
      }
      await _reverseCustomerSale(quote);
      await _storage.saveProductionOrders(_productionOrders);
      await _storage.saveQuotations(_quotations);
      notifyListeners();
      return DomainOperationResult.success(
        'تم إلغاء اعتماد العرض وعكس أثره المالي وإلغاء أمر الإنتاج غير المصروف',
      );
    }

    quote.status = newStatus;
    await _storage.saveQuotations(_quotations);
    notifyListeners();
    return DomainOperationResult.success('تم تحديث حالة عرض السعر');
  }

  // --- PRODUCTION ORDERS ACTIONS ---
  String generateNextOrderNumber() {
    final year = DateTime.now().year;
    final count = _productionOrders.length + 1;
    return 'PO-$year-${count.toString().padLeft(4, '0')}';
  }

  List<ProductionMaterialRequirement> _buildMaterialRequirements(
    Quotation quote,
  ) {
    final pricing = quote.pricingDetails;
    final planned = pricing?.materialRequirements ?? const <PricingMaterialRequirement>[];
    final requirements = <ProductionMaterialRequirement>[];

    if (planned.isNotEmpty) {
      final grouped = <String, ProductionMaterialRequirement>{};
      for (final material in planned.where((item) => item.quantity > 0)) {
        final key = '${material.materialType}:${material.materialId}';
        final existing = grouped[key];
        if (existing != null) {
          existing.quantityRequired += material.quantity;
        } else {
          grouped[key] = ProductionMaterialRequirement(
            id: 'MAT_${DateTime.now().microsecondsSinceEpoch}_${grouped.length}',
            materialId: material.materialId,
            materialName: material.materialName,
            materialType: material.materialType,
            quantityRequired: material.quantity,
            unit: material.unit,
            unitCostAtApproval: material.unitCost,
          );
        }
      }
      requirements.addAll(grouped.values);
    }

    // توافق محافظ مع عروض التسعير القديمة التي لا تحتوي متطلبات مواد مفصلة.
    if (requirements.isEmpty) {
      PaperItem? paper;
      if (pricing?.paperId.isNotEmpty == true) {
        final matches = _papers.where((item) => item.id == pricing!.paperId);
        if (matches.isNotEmpty) paper = matches.first;
      }
      paper ??= _findPaperForDescription(quote.paper);
      if (paper != null) {
        final detailedQty = pricing?.sheetsWithWaste ?? (quote.qty * 10.0 * 1.05);
        final fullSheets = (detailedQty /
                (paper.sheetsPerUnit > 0 ? paper.sheetsPerUnit : 4))
            .ceilToDouble();
        requirements.add(ProductionMaterialRequirement(
          id: 'MAT_${DateTime.now().microsecondsSinceEpoch}_0',
          materialId: paper.id,
          materialName: paper.displayName,
          quantityRequired: fullSheets,
          unitCostAtApproval: paper.sheetPrice,
        ));
      }
    }

    return requirements;
  }

  PaperItem? _findPaperForDescription(String description) {
    final exact = _papers.where((paper) => description.contains(paper.category));
    if (exact.isNotEmpty) return exact.first;
    return _papers.isNotEmpty ? _papers.first : null;
  }

  Future<ProductionOrder> createProductionOrderFromQuote(Quotation quote) async {
    final existing = _productionOrders.where((order) => order.quotationId == quote.id);
    if (existing.isNotEmpty) return existing.first;

    final pricing = quote.pricingDetails;
    final materials = _buildMaterialRequirements(quote);
    final sheetsRequired = materials.fold<double>(
      0,
      (sum, material) => sum + material.quantityRequired,
    );
    final paperId = materials.isNotEmpty ? materials.first.materialId : '';
    final paperName = materials.isNotEmpty
        ? materials.map((material) => material.materialName).join(' + ')
        : quote.paper;

    final order = ProductionOrder(
      id: 'PO_${DateTime.now().microsecondsSinceEpoch}',
      number: generateNextOrderNumber(),
      date: DateTime.now(),
      quotationId: quote.id,
      quotationNumber: quote.number,
      customerId: quote.customerId,
      customerName: quote.customerName,
      product: quote.product,
      qty: quote.qty,
      machine: quote.machine,
      paperName: paperName,
      paperId: paperId,
      sheetsRequired: sheetsRequired,
      sheetsWithWaste: sheetsRequired,
      runHours: pricing?.runHours ?? 1.5,
      cost: quote.totalCost,
      status: 'معتمد',
      dueDate: DateTime.now().add(const Duration(days: 3)),
      notes: 'تم إنشاؤه تلقائياً من عرض السعر ${quote.number}',
      materialRequirements: materials,
    );

    _productionOrders.insert(0, order);
    await _storage.saveProductionOrders(_productionOrders);
    notifyListeners();
    return order;
  }

  Future<DomainOperationResult> addManualProductionOrder(
    ProductionOrder order,
  ) async {
    if (order.materialRequirements.isEmpty) {
      final paper = _papers.where((item) => item.id == order.paperId).toList();
      if (paper.isNotEmpty) {
        order.materialRequirements = [
          ProductionMaterialRequirement(
            id: 'MAT_${DateTime.now().microsecondsSinceEpoch}_0',
            materialId: paper.first.id,
            materialName: paper.first.displayName,
            quantityRequired: order.sheetsWithWaste,
            unitCostAtApproval: paper.first.sheetPrice,
          ),
        ];
      }
    }
    _productionOrders.insert(0, order);
    await _storage.saveProductionOrders(_productionOrders);
    notifyListeners();
    return DomainOperationResult.success('تم إنشاء أمر الإنتاج اليدوي');
  }

  Future<DomainOperationResult> updateProductionOrderStatus(
    String orderId,
    String newStatus,
  ) async {
    final index = _productionOrders.indexWhere((order) => order.id == orderId);
    if (index == -1) {
      return DomainOperationResult.failure('تعذر العثور على أمر الإنتاج');
    }
    final order = _productionOrders[index];
    if (order.status == newStatus) {
      return DomainOperationResult.success('أمر الإنتاج في الحالة المطلوبة مسبقاً');
    }
    const allowedTransitions = <String, Set<String>>{
      'مسودة': {'معتمد', 'ملغي'},
      'معتمد': {'قيد الإنتاج', 'ملغي'},
      'قيد الإنتاج': {'مكتمل'},
    };
    if (!(allowedTransitions[order.status]?.contains(newStatus) ?? false)) {
      return DomainOperationResult.failure(
        'لا يسمح بالانتقال من حالة ${order.status} إلى $newStatus',
      );
    }
    if ((newStatus == 'قيد الإنتاج' || newStatus == 'مكتمل') &&
        !order.areAllMaterialsIssued) {
      return DomainOperationResult.failure(
        'لا يمكن بدء أو إكمال الإنتاج قبل صرف جميع المواد المطلوبة',
      );
    }
    if (newStatus == 'ملغي' && order.issuedMaterialsCount > 0) {
      return DomainOperationResult.failure(
        'لا يمكن إلغاء أمر صُرفت له مواد. نفّذ إرجاع المواد أو تسوية أولاً',
      );
    }

    order.status = newStatus;
    await _storage.saveProductionOrders(_productionOrders);
    notifyListeners();
    return DomainOperationResult.success('تم تحديث حالة أمر الإنتاج');
  }

  Future<DomainOperationResult> deleteProductionOrder(String orderId) async {
    final order = _productionOrders.where((item) => item.id == orderId).toList();
    if (order.isEmpty) {
      return DomainOperationResult.failure('تعذر العثور على أمر الإنتاج');
    }
    if (order.first.issuedMaterialsCount > 0 || order.first.isPaperDeducted) {
      return DomainOperationResult.failure(
        'لا يمكن حذف أمر صُرفت له مواد؛ استخدم الإلغاء أو التسوية بدلاً من الحذف',
      );
    }
    if (order.first.quotationId != null) {
      return DomainOperationResult.failure(
        'لا يمكن حذف أمر ناتج عن عرض معتمد؛ ألغِ اعتماد العرض لعكس أثره المالي والتشغيلي',
      );
    }
    _productionOrders.removeWhere((item) => item.id == orderId);
    await _storage.saveProductionOrders(_productionOrders);
    notifyListeners();
    return DomainOperationResult.success('تم حذف أمر الإنتاج غير المصروف');
  }

  /// صرف كل المواد الورقية المتبقية لأمر الإنتاج بعد التحقق من توفرها بالكامل.
  Future<DomainOperationResult> deductPaperForOrder(String orderId) async {
    final index = _productionOrders.indexWhere((order) => order.id == orderId);
    if (index == -1) return DomainOperationResult.failure('تعذر العثور على أمر الإنتاج');
    final order = _productionOrders[index];
    if (order.areAllMaterialsIssued) {
      return DomainOperationResult.success('جميع مواد هذا الأمر مصروفة مسبقاً');
    }

    // ترحيل محافظ للأوامر القديمة التي كانت تحفظ صنف ورق واحد فقط.
    if (order.materialRequirements.isEmpty) {
      final paper = _papers.where((item) => item.id == order.paperId).toList();
      final selectedPaper = paper.isNotEmpty ? paper.first : _findPaperForDescription(order.paperName);
      if (selectedPaper == null) {
        return DomainOperationResult.failure('لا يوجد صنف ورق صالح لأمر الإنتاج');
      }
      final quantity = (order.sheetsWithWaste /
              (selectedPaper.sheetsPerUnit > 0 ? selectedPaper.sheetsPerUnit : 4))
          .ceilToDouble();
      order.materialRequirements = [
        ProductionMaterialRequirement(
          id: 'MAT_LEGACY_${order.id}',
          materialId: selectedPaper.id,
          materialName: selectedPaper.displayName,
          quantityRequired: quantity,
          unitCostAtApproval: selectedPaper.sheetPrice,
        ),
      ];
    }

    final remainingMaterials = order.materialRequirements
        .where((material) =>
            material.materialType == 'paper' && material.remainingQuantity > 0)
        .toList();
    if (remainingMaterials.isEmpty) {
      order.isPaperDeducted = order.areAllMaterialsIssued;
      await _storage.saveProductionOrders(_productionOrders);
      return DomainOperationResult.success('لا توجد مواد ورقية متبقية للصرف');
    }

    // تحقق مسبق من جميع الأصناف حتى لا ينفذ صرف جزئي.
    for (final material in remainingMaterials) {
      final papers = _papers.where((paper) => paper.id == material.materialId).toList();
      if (papers.isEmpty) {
        return DomainOperationResult.failure('صنف المادة ${material.materialName} غير موجود في المخزون');
      }
      if (papers.first.balance + 0.0001 < material.remainingQuantity) {
        return DomainOperationResult.failure(
          'رصيد ${papers.first.displayName} غير كافٍ. المتاح ${papers.first.balance.toStringAsFixed(0)}، والمطلوب ${material.remainingQuantity.toStringAsFixed(0)}',
        );
      }
    }

    // تنفيذ الدفعة بعد اكتمال التحقق؛ لا تستدعي addStockMove هنا حتى لا تحفظ
    // حركةً واحدةً في منتصف الصرف متعدد الخامات.
    for (final material in remainingMaterials) {
      final paper = _papers.firstWhere((item) => item.id == material.materialId);
      final quantity = material.remainingQuantity;
      final unitPrice = material.unitCostAtApproval > 0
          ? material.unitCostAtApproval
          : paper.sheetPrice;
      paper.balance -= quantity;
      _stockMoves.insert(
        0,
        StockMove(
          id: 'SM_${DateTime.now().microsecondsSinceEpoch}_${material.id}',
          number: generateNextStockMoveNumber(),
          date: DateTime.now(),
          moveType: 'خروج',
          paperId: paper.id,
          paperCategory: paper.category,
          paperType: paper.paperType,
          gsm: paper.gsm,
          qtySheets: quantity,
          unitPrice: unitPrice,
          totalValue: quantity * unitPrice,
          reference: 'أمر إنتاج ${order.number}',
          supplier: paper.supplier,
          notes: 'صرف تلقائي لمادة ${material.materialName} لأمر الإنتاج ${order.number}',
        ),
      );
      material.quantityIssued += quantity;
    }

    order.isPaperDeducted = order.areAllMaterialsIssued;
    if (order.status == 'معتمد') order.status = 'قيد الإنتاج';
    await _storage.savePapers(_papers);
    await _storage.saveStockMoves(_stockMoves);
    await _storage.saveProductionOrders(_productionOrders);
    notifyListeners();
    return DomainOperationResult.success('تم صرف جميع المواد المطلوبة لأمر الإنتاج');
  }

  /// يعيد مادة سبق صرفها إلى المخزون ويخفض الكمية المصروفة في أمر الإنتاج.
  /// يُستخدم قبل الإلغاء أو لتصحيح صرف قبل اكتمال الأمر، ولا يحذف حركة الصرف الأصلية.
  Future<DomainOperationResult> returnProductionMaterial({
    required String orderId,
    required String materialRequirementId,
    required double quantity,
    String? notes,
  }) async {
    if (quantity <= 0) {
      return DomainOperationResult.failure('يجب أن تكون كمية الإرجاع أكبر من صفر');
    }
    final returnNotes = notes?.trim();
    if (returnNotes == null || returnNotes.isEmpty) {
      return DomainOperationResult.failure('يجب إدخال سبب أو ملاحظة لإرجاع المواد');
    }
    final orderIndex = _productionOrders.indexWhere((order) => order.id == orderId);
    if (orderIndex == -1) {
      return DomainOperationResult.failure('تعذر العثور على أمر الإنتاج');
    }
    final order = _productionOrders[orderIndex];
    if (order.status == 'مكتمل' || order.status == 'ملغي') {
      return DomainOperationResult.failure(
        'لا يمكن إرجاع مواد من أمر مكتمل أو ملغي؛ أنشئ تسوية تصحيحية موثقة',
      );
    }
    final materialMatches = order.materialRequirements
        .where((material) => material.id == materialRequirementId)
        .toList();
    if (materialMatches.isEmpty) {
      return DomainOperationResult.failure('المادة المطلوبة غير مرتبطة بأمر الإنتاج');
    }
    final material = materialMatches.first;
    if (material.materialType != 'paper') {
      return DomainOperationResult.failure('إرجاع هذه المادة غير مدعوم في المخزون الحالي');
    }
    if (material.quantityIssued + 0.0001 < quantity) {
      return DomainOperationResult.failure(
        'لا يمكن إرجاع كمية أكبر من المصروف. المصروف ${material.quantityIssued.toStringAsFixed(0)} ${material.unit}',
      );
    }
    final papers = _papers.where((paper) => paper.id == material.materialId).toList();
    if (papers.isEmpty) {
      return DomainOperationResult.failure('صنف ${material.materialName} غير موجود في المخزون');
    }

    final paper = papers.first;
    final unitPrice = material.unitCostAtApproval > 0
        ? material.unitCostAtApproval
        : paper.sheetPrice;
    paper.balance += quantity;
    material.quantityIssued = (material.quantityIssued - quantity).clamp(0.0, double.infinity).toDouble();
    order.isPaperDeducted = order.areAllMaterialsIssued;
    // لا يمكن بقاء أمر تحت الإنتاج عندما تعاد إحدى مواده؛ يعود إلى حالة معتمد.
    if (order.status == 'قيد الإنتاج' && !order.areAllMaterialsIssued) {
      order.status = 'معتمد';
    }
    _stockMoves.insert(
      0,
      StockMove(
        id: 'SM_RETURN_${DateTime.now().microsecondsSinceEpoch}_${material.id}',
        number: generateNextStockMoveNumber(),
        date: DateTime.now(),
        moveType: 'دخول',
        paperId: paper.id,
        paperCategory: paper.category,
        paperType: paper.paperType,
        gsm: paper.gsm,
        qtySheets: quantity,
        unitPrice: unitPrice,
        totalValue: quantity * unitPrice,
        reference: 'أمر إنتاج ${order.number} - إرجاع مواد',
        supplier: paper.supplier,
        notes: 'إرجاع ${material.materialName} من أمر الإنتاج ${order.number}: $returnNotes',
      ),
    );
    await _storage.savePapers(_papers);
    await _storage.saveStockMoves(_stockMoves);
    await _storage.saveProductionOrders(_productionOrders);
    notifyListeners();
    return DomainOperationResult.success('تم إرجاع ${quantity.toStringAsFixed(0)} ${material.unit} من ${material.materialName}');
  }

  // --- PAPERS & STOCK MOVES ACTIONS ---
  String generateNextStockMoveNumber() {
    final count = _stockMoves.length + 1;
    return 'SM-${count.toString().padLeft(4, '0')}';
  }

  Future<DomainOperationResult> addStockMove({
    required String moveType, // دخول / خروج / تسوية
    required String paperId,
    required double qtySheets,
    required double unitPrice,
    String? reference,
    String? reversalOfId,
    String? supplier,
    String? notes,
  }) async {
    const allowedMoves = {'دخول', 'خروج', 'تسوية'};
    if (!allowedMoves.contains(moveType)) {
      return DomainOperationResult.failure('نوع حركة المخزون غير صالح');
    }
    if (!qtySheets.isFinite || qtySheets <= 0) {
      return DomainOperationResult.failure('يجب أن تكون كمية حركة المخزون أكبر من صفر');
    }

    final pIndex = _papers.indexWhere((paper) => paper.id == paperId);
    if (pIndex == -1) {
      return DomainOperationResult.failure('صنف الورق غير موجود');
    }
    final paper = _papers[pIndex];
    final isAdmin = _hasAdminPermission;
    final recordedUnitPrice = isAdmin ? unitPrice : paper.sheetPrice;
    if (!recordedUnitPrice.isFinite || recordedUnitPrice < 0) {
      return DomainOperationResult.failure('سعر حركة المخزون غير صالح');
    }
    if (moveType == 'خروج' && paper.balance + 0.0001 < qtySheets) {
      return DomainOperationResult.failure(
        'رصيد ${paper.displayName} غير كافٍ. المتاح ${paper.balance.toStringAsFixed(0)} فرخ فقط',
      );
    }

    if (moveType == 'دخول') {
      paper.balance += qtySheets;
      if (isAdmin && recordedUnitPrice > 0) paper.sheetPrice = recordedUnitPrice;
    } else if (moveType == 'خروج') {
      paper.balance -= qtySheets;
    } else {
      paper.balance = qtySheets;
    }

    final move = StockMove(
      id: 'SM_${DateTime.now().microsecondsSinceEpoch}',
      number: generateNextStockMoveNumber(),
      date: DateTime.now(),
      moveType: moveType,
      paperId: paper.id,
      paperCategory: paper.category,
      paperType: paper.paperType,
      gsm: paper.gsm,
      qtySheets: qtySheets,
      unitPrice: recordedUnitPrice,
      totalValue: qtySheets * recordedUnitPrice,
      reference: reference,
      reversalOfId: reversalOfId,
      supplier: supplier ?? paper.supplier,
      notes: notes,
    );

    _stockMoves.insert(0, move);
    await _storage.savePapers(_papers);
    await _storage.saveStockMoves(_stockMoves);
    notifyListeners();
    return DomainOperationResult.success('تم تسجيل حركة المخزون');
  }

  /// ينشئ حركة معاكسة بدلاً من حذف السجل الأصلي، حتى يبقى سجل المخزون قابلاً للتدقيق.
  Future<DomainOperationResult> reverseStockMove(String id) async {
    final moves = _stockMoves.where((move) => move.id == id).toList();
    if (moves.isEmpty) {
      return DomainOperationResult.failure('تعذر العثور على حركة المخزون');
    }
    final move = moves.first;
    if (move.reversalOfId != null) {
      return DomainOperationResult.failure('لا يمكن عكس حركة عكسية؛ راجع الحركة الأصلية أو أنشئ تصحيحاً جديداً');
    }
    if (_stockMoves.any((item) => item.reversalOfId == move.id)) {
      return DomainOperationResult.failure('سبق إنشاء حركة عكسية لهذه الحركة');
    }
    if (move.reference?.contains('أمر إنتاج') == true) {
      return DomainOperationResult.failure(
        'لا يمكن عكس صرف مرتبط بأمر إنتاج من هنا؛ استخدم إجراء إرجاع مواد موثقاً',
      );
    }
    if (move.moveType == 'تسوية') {
      return DomainOperationResult.failure(
        'لا يمكن عكس حركة تسوية تلقائياً؛ أنشئ تسوية تصحيحية للحفاظ على أثر الجرد',
      );
    }

    final reverseType = move.moveType == 'دخول' ? 'خروج' : 'دخول';
    final result = await addStockMove(
      moveType: reverseType,
      paperId: move.paperId,
      qtySheets: move.qtySheets,
      unitPrice: move.unitPrice,
      reference: 'عكس الحركة ${move.number}',
      reversalOfId: move.id,
      supplier: move.supplier,
      notes: 'قيد عكسي لحركة ${move.number}${move.notes == null ? '' : ': ${move.notes}'}',
    );
    if (!result.isSuccess) return result;
    return DomainOperationResult.success('تم إنشاء حركة عكسية للحركة ${move.number}');
  }

  /// التوافق مع واجهات/استدعاءات قديمة: الحذف محظور حفاظاً على سجل المخزون.
  Future<DomainOperationResult> deleteStockMove(String _) async {
    return DomainOperationResult.failure(
      'لا يمكن حذف حركة المخزون؛ استخدم إنشاء حركة عكسية بدلاً من الحذف',
    );
  }

  Future<DomainOperationResult> addPaper(PaperItem paper) async {
    final permission = await _requireAdminForOperation('add_paper');
    if (permission != null) return permission;
    if (!paper.balance.isFinite || paper.balance < 0 ||
        !paper.sheetPrice.isFinite || paper.sheetPrice < 0) {
      return DomainOperationResult.failure('يجب أن يكون رصيد الورق وسعره صالحين وغير سالبين');
    }
    _papers.add(paper);
    await _storage.savePapers(_papers);
    notifyListeners();
    return DomainOperationResult.success('تمت إضافة صنف الورق');
  }

  Future<DomainOperationResult> updatePaper(PaperItem paper) async {
    final permission = await _requireAdminForOperation('update_paper');
    if (permission != null) return permission;
    if (!paper.balance.isFinite || paper.balance < 0 ||
        !paper.sheetPrice.isFinite || paper.sheetPrice < 0) {
      return DomainOperationResult.failure('يجب أن يكون رصيد الورق وسعره صالحين وغير سالبين');
    }
    final index = _papers.indexWhere((p) => p.id == paper.id);
    if (index == -1) {
      return DomainOperationResult.failure('صنف الورق غير موجود');
    }
    final currentPaper = _papers[index];
    if ((currentPaper.balance - paper.balance).abs() > 0.0001 &&
        _stockMoves.any((move) => move.paperId == paper.id)) {
      return DomainOperationResult.failure(
        'لا تعدّل الرصيد مباشرة بعد تسجيل الحركات؛ استخدم حركة تسوية موثقة',
      );
    }
    _papers[index] = paper;
    await _storage.savePapers(_papers);
    notifyListeners();
    return DomainOperationResult.success('تم تحديث صنف الورق');
  }

  Future<DomainOperationResult> deletePaper(String id) async {
    final permission = await _requireAdminForOperation('delete_paper');
    if (permission != null) return permission;
    final paper = _papers.where((item) => item.id == id).toList();
    if (paper.isEmpty) return DomainOperationResult.failure('صنف الورق غير موجود');
    final isReferencedByMove = _stockMoves.any((move) => move.paperId == id);
    final isReferencedByOrder = _productionOrders.any(
      (order) =>
          order.paperId == id ||
          order.materialRequirements.any((material) => material.materialId == id),
    );
    if (isReferencedByMove || isReferencedByOrder || paper.first.balance.abs() > 0.0001) {
      return DomainOperationResult.failure(
        'لا يمكن حذف صنف له رصيد أو حركات أو أوامر إنتاج مرتبطة؛ احتفظ به لحماية السجل',
      );
    }
    _papers.removeWhere((item) => item.id == id);
    await _storage.savePapers(_papers);
    notifyListeners();
    return DomainOperationResult.success('تم حذف صنف الورق');
  }

  // --- INKS & INK MOVES ACTIONS ---
  Future<DomainOperationResult> addInkMove({
    required String moveType,
    required String inkId,
    required double qty,
    required double unitPrice,
    String? reference,
    String? notes,
  }) async {
    const allowedMoves = {'دخول', 'خروج', 'تسوية'};
    if (!allowedMoves.contains(moveType)) {
      return DomainOperationResult.failure('نوع حركة الحبر غير صالح');
    }
    if (!qty.isFinite || qty <= 0) {
      return DomainOperationResult.failure('يجب أن تكون كمية الحبر أكبر من صفر');
    }

    final iIndex = _inks.indexWhere((ink) => ink.id == inkId);
    if (iIndex == -1) return DomainOperationResult.failure('صنف الحبر غير موجود');
    final ink = _inks[iIndex];
    final isAdmin = _hasAdminPermission;
    final recordedUnitPrice = isAdmin ? unitPrice : ink.unitPrice;
    if (!recordedUnitPrice.isFinite || recordedUnitPrice < 0) {
      return DomainOperationResult.failure('سعر حركة الحبر غير صالح');
    }
    if (moveType == 'خروج' && ink.balance + 0.0001 < qty) {
      return DomainOperationResult.failure(
        'رصيد ${ink.name} غير كافٍ. المتاح ${ink.balance.toStringAsFixed(2)} فقط',
      );
    }

    if (moveType == 'دخول') {
      ink.balance += qty;
      if (isAdmin && recordedUnitPrice > 0) ink.unitPrice = recordedUnitPrice;
    } else if (moveType == 'خروج') {
      ink.balance -= qty;
    } else {
      ink.balance = qty;
    }

    final move = InkMove(
      id: 'INKM_${DateTime.now().microsecondsSinceEpoch}',
      number: 'IM-${(_inkMoves.length + 1).toString().padLeft(4, '0')}',
      date: DateTime.now(),
      moveType: moveType,
      inkId: ink.id,
      inkName: '${ink.name} (${ink.kind})',
      qty: qty,
      unitPrice: recordedUnitPrice,
      totalValue: qty * recordedUnitPrice,
      reference: reference,
      notes: notes,
    );

    _inkMoves.insert(0, move);
    await _storage.saveInks(_inks);
    await _storage.saveInkMoves(_inkMoves);
    notifyListeners();
    return DomainOperationResult.success('تم تسجيل حركة الحبر');
  }

  Future<DomainOperationResult> updateInk(InkItem ink) async {
    final permission = await _requireAdminForOperation('update_ink');
    if (permission != null) return permission;
    if (!ink.unitPrice.isFinite || ink.unitPrice < 0 ||
        !ink.balance.isFinite || ink.balance < 0) {
      return DomainOperationResult.failure('بيانات الحبر غير صالحة');
    }
    final idx = _inks.indexWhere((item) => item.id == ink.id);
    if (idx == -1) return DomainOperationResult.failure('صنف الحبر غير موجود');
    _inks[idx] = ink;
    await _storage.saveInks(_inks);
    notifyListeners();
    return DomainOperationResult.success('تم تحديث صنف الحبر');
  }

  // --- CUSTOMERS & PAYMENTS / CUSTOMER LEDGER ACTIONS ---
  String generateNextCustomerCode() {
    return 'C-${(_customers.length + 1).toString().padLeft(4, '0')}';
  }

  void _syncAllCustomerSummariesFromLedger() {
    for (final customer in _customers) {
      final entries = _customerLedger
          .where((entry) => entry.customerId == customer.id)
          .toList();
      final sales = entries
          .where((entry) => entry.type == 'sale' || entry.type == 'legacy_sale')
          .fold<double>(0, (sum, entry) => sum + entry.debit);
      final reversedSales = entries
          .where((entry) => entry.type == 'sale_reversal')
          .fold<double>(0, (sum, entry) => sum + entry.credit);
      final payments = entries
          .where((entry) => entry.type == 'payment' || entry.type == 'legacy_payment')
          .fold<double>(0, (sum, entry) => sum + entry.credit);
      customer.totalSales = sales - reversedSales;
      customer.paid = payments;
    }
  }

  Future<void> _saveCustomerLedgerAndSummaries() async {
    _syncAllCustomerSummariesFromLedger();
    await _storage.saveCustomerLedger(_customerLedger);
    await _storage.saveCustomers(_customers);
  }

  Future<void> _recordCustomerSale(Quotation quote) async {
    final alreadyRecorded = _customerLedger.any(
      (entry) => entry.type == 'sale' && entry.referenceId == quote.id,
    );
    if (alreadyRecorded) return;
    _customerLedger.add(CustomerLedgerEntry(
      id: 'LED_SALE_${quote.id}',
      customerId: quote.customerId,
      date: DateTime.now(),
      type: 'sale',
      debit: quote.quoteAmount,
      referenceId: quote.id,
      referenceNumber: quote.number,
      notes: 'اعتماد عرض السعر ${quote.number}',
    ));
    await _saveCustomerLedgerAndSummaries();
  }

  Future<void> _reverseCustomerSale(Quotation quote) async {
    final alreadyReversed = _customerLedger.any(
      (entry) => entry.type == 'sale_reversal' && entry.referenceId == quote.id,
    );
    if (alreadyReversed) return;
    _customerLedger.add(CustomerLedgerEntry(
      id: 'LED_REV_${quote.id}',
      customerId: quote.customerId,
      date: DateTime.now(),
      type: 'sale_reversal',
      credit: quote.quoteAmount,
      referenceId: quote.id,
      referenceNumber: quote.number,
      notes: 'إلغاء اعتماد عرض السعر ${quote.number}',
    ));
    await _saveCustomerLedgerAndSummaries();
  }

  Future<void> addCustomer(Customer customer) async {
    _customers.add(customer);
    if (customer.openingBalance != 0) {
      _customerLedger.add(CustomerLedgerEntry(
        id: 'LED_OPEN_${customer.id}',
        customerId: customer.id,
        date: DateTime.now(),
        type: 'opening_balance',
        debit: customer.openingBalance > 0 ? customer.openingBalance : 0,
        credit: customer.openingBalance < 0 ? customer.openingBalance.abs() : 0,
        referenceId: customer.id,
        referenceNumber: 'OPEN-${customer.code}',
        notes: 'رصيد افتتاحي للعميل',
      ));
    }
    await _saveCustomerLedgerAndSummaries();
    notifyListeners();
  }

  Future<void> updateCustomer(Customer customer) async {
    final idx = _customers.indexWhere((item) => item.id == customer.id);
    if (idx != -1) {
      // المبيعات والمدفوعات تلخص من دفتر القيود ولا تقبل تعديلاً مباشراً.
      customer.totalSales = _customers[idx].totalSales;
      customer.paid = _customers[idx].paid;

      final ledgerOpeningBalance = _customerLedger
          .where((entry) =>
              entry.customerId == customer.id &&
              (entry.type == 'opening_balance' || entry.type == 'opening_adjustment'))
          .fold<double>(0, (sum, entry) => sum + entry.balanceEffect);
      final openingDifference = customer.openingBalance - ledgerOpeningBalance;
      if (openingDifference.abs() > 0.0001) {
        _customerLedger.add(CustomerLedgerEntry(
          id: 'LED_OPEN_ADJ_${customer.id}_${DateTime.now().microsecondsSinceEpoch}',
          customerId: customer.id,
          date: DateTime.now(),
          type: 'opening_adjustment',
          debit: openingDifference > 0 ? openingDifference : 0,
          credit: openingDifference < 0 ? openingDifference.abs() : 0,
          referenceId: customer.id,
          referenceNumber: 'OPEN-ADJ-${customer.code}',
          notes: 'تسوية تعديل الرصيد الافتتاحي',
        ));
      }

      _customers[idx] = customer;
      await _saveCustomerLedgerAndSummaries();
      notifyListeners();
    }
  }

  Future<DomainOperationResult> deleteCustomer(String id) async {
    if (_customerLedger.any((entry) => entry.customerId == id) ||
        _quotations.any((quote) => quote.customerId == id) ||
        _payments.any((payment) => payment.customerId == id)) {
      return DomainOperationResult.failure(
        'لا يمكن حذف عميل له قيود أو عروض أو مدفوعات؛ عطل الحساب أو احتفظ بسجله',
      );
    }
    _customers.removeWhere((customer) => customer.id == id);
    await _storage.saveCustomers(_customers);
    notifyListeners();
    return DomainOperationResult.success('تم حذف العميل');
  }

  String generateNextPaymentNumber() {
    return 'PAY-${(_payments.length + 1).toString().padLeft(4, '0')}';
  }

  Future<DomainOperationResult> recordPayment({
    required String customerId,
    required double amount,
    String paymentMethod = 'نقدي',
    String? reference,
    String? notes,
  }) async {
    if (amount <= 0) {
      return DomainOperationResult.failure('يجب أن يكون مبلغ القبض أكبر من صفر');
    }
    final idx = _customers.indexWhere((customer) => customer.id == customerId);
    if (idx == -1) return DomainOperationResult.failure('العميل غير موجود');
    final customer = _customers[idx];

    final pay = PaymentRecord(
      id: 'PAY_${DateTime.now().microsecondsSinceEpoch}',
      number: generateNextPaymentNumber(),
      date: DateTime.now(),
      customerId: customer.id,
      customerName: customer.name,
      amount: amount,
      paymentMethod: paymentMethod,
      reference: reference,
      notes: notes,
    );

    _payments.insert(0, pay);
    _customerLedger.add(CustomerLedgerEntry(
      id: 'LED_PAY_${pay.id}',
      customerId: customer.id,
      date: pay.date,
      type: 'payment',
      credit: amount,
      referenceId: pay.id,
      referenceNumber: pay.number,
      notes: notes ?? 'سند قبض ${pay.number} عبر $paymentMethod',
    ));
    await _storage.savePayments(_payments);
    await _saveCustomerLedgerAndSummaries();
    notifyListeners();
    return DomainOperationResult.success('تم تسجيل سند القبض وتحديث دفتر العميل');
  }

  // --- MACHINES, PRODUCTS, FINISHINGS ACTIONS ---
  Future<DomainOperationResult> updateMachine(MachineItem m) async {
    final permission = await _requireAdminForOperation('update_machine');
    if (permission != null) return permission;
    final idx = _machines.indexWhere((x) => x.id == m.id);
    if (idx == -1) return DomainOperationResult.failure('الماكينة غير موجودة');
    _machines[idx] = m;
    await _storage.saveMachines(_machines);
    notifyListeners();
    return DomainOperationResult.success('تم تحديث الماكينة');
  }

  Future<DomainOperationResult> updateFinishing(FinishingItem f) async {
    final permission = await _requireAdminForOperation('update_finishing');
    if (permission != null) return permission;
    final idx = _finishings.indexWhere((x) => x.id == f.id);
    if (idx == -1) return DomainOperationResult.failure('خدمة التشطيب غير موجودة');
    _finishings[idx] = f;
    await _storage.saveFinishings(_finishings);
    notifyListeners();
    return DomainOperationResult.success('تم تحديث خدمة التشطيب');
  }

  Future<DomainOperationResult> addProduct(ProductTemplate p) async {
    final permission = await _requireAdminForOperation('add_product');
    if (permission != null) return permission;
    _products.add(p);
    await _storage.saveProducts(_products);
    notifyListeners();
    return DomainOperationResult.success('تمت إضافة المنتج');
  }

  Future<DomainOperationResult> updateProduct(ProductTemplate p) async {
    final permission = await _requireAdminForOperation('update_product');
    if (permission != null) return permission;
    final idx = _products.indexWhere((x) => x.id == p.id);
    if (idx == -1) return DomainOperationResult.failure('المنتج غير موجود');
    _products[idx] = p;
    await _storage.saveProducts(_products);
    notifyListeners();
    return DomainOperationResult.success('تم تحديث المنتج');
  }

  /// إعادة تحميل كل القوائم من التخزين (بعد تغييرات تجريها طبقة أخرى).
  void reload() {
    _loadAll();
    notifyListeners();
  }

  /// هل هذه القاعدة مزروعة ببيانات تجارية وهمية؟
  bool get hasDemoRecords => _storage.hasDemoRecords;

  /// إعادة تعيين البيانات إلى البيانات الأولية للإكسل.
  ///
  /// [clean] = true يعيد المرجعيات فقط (ورق/ماكينات/منتجات/أحبار) بلا عملاء
  /// ولا عروض ولا أوامر إنتاج ولا مدفوعات وهمية.
  Future<DomainOperationResult> resetToExcelDefaults({bool clean = false}) async {
    final permission = await _requireAdminForOperation('reset_to_defaults');
    if (permission != null) return permission;
    await _storage.seedInitialData(includeDemoRecords: !clean);
    await _storage.setFirstRunMode(clean ? 'clean' : 'demo');
    _loadAll();
    notifyListeners();
    return DomainOperationResult.success('تمت إعادة تهيئة البيانات');
  }

  /// يمسح السجلات التجارية الوهمية من قاعدة مزروعة بوضع `demo`.
  Future<DomainOperationResult> clearDemoRecords() async {
    final permission = await _requireAdminForOperation('clear_demo_records');
    if (permission != null) return permission;
    await _storage.clearDemoRecords();
    _loadAll();
    notifyListeners();
    return DomainOperationResult.success('تم مسح السجلات التجريبية');
  }

  /// تصدير نسخة احتياطية من كافة جداول وبيانات النظام بصيغة JSON.
  ///
  /// الناتج نص صريح؛ التشفير يتم في طبقة الواجهة عبر `BackupCodec.encrypt`.
  String exportDatabaseBackup({bool includeUsers = true}) {
    if (!_hasAdminPermission) {
      throw StateError('تصدير النسخ الاحتياطية متاح للمدير فقط');
    }
    return _storage.exportBackupJson(includeUsers: includeUsers);
  }

  /// استيراد نسخة احتياطية مع فحص الإصدار ولقطة أمان قبل الكتابة.
  Future<BackupImportResult> importDatabaseBackup(String jsonStr) async {
    final permission = await _requireAdminForOperation('import_backup');
    if (permission != null) {
      return BackupImportResult.failure(permission.message);
    }
    final result = await _storage.importBackupJson(jsonStr);
    if (result.isSuccess) {
      _loadAll();
      notifyListeners();
    }
    return result;
  }

  /// التراجع عن آخر استيراد بالعودة إلى لقطة الأمان.
  Future<bool> restorePreImportSnapshot() async {
    final permission = await _requireAdminForOperation('restore_backup_snapshot');
    if (permission != null) return false;
    final ok = await _storage.restoreSafetySnapshot();
    if (ok) {
      _loadAll();
      notifyListeners();
    }
    return ok;
  }

  /// سجل التدقيق (الأحدث أولاً).
  List<AuditLogEntry> get auditLog => _storage.loadAuditLog();

  /// يسجل حدثاً حساساً في سجل التدقيق ببصمة الجلسة الحالية.
  Future<void> recordAudit({
    required String action,
    String? targetType,
    String? targetId,
    String details = '',
    bool success = true,
    AuditSeverity severity = AuditSeverity.info,
  }) async {
    final actor = _storage.getAuditActor();
    await _storage.recordAudit(
      AuditLogEntry(
        id: 'AUD_${DateTime.now().microsecondsSinceEpoch}',
        timestamp: DateTime.now(),
        actorId: actor.id,
        actorName: actor.name,
        actorRole: actor.role,
        action: action,
        targetType: targetType,
        targetId: targetId,
        details: details,
        success: success,
        severity: severity,
      ),
    );
  }
}
