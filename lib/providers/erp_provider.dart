import 'package:flutter/foundation.dart';
import '../models/app_models.dart';
import '../services/storage_service.dart';
import '../services/pricing_engine_service.dart';

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

  ErpProvider(this._storage) {
    _loadAll();
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
  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    await _storage.saveSettings(_settings);
    notifyListeners();
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
  /// تعديل سعر فرخ الورق
  Future<void> updatePaperPrice(String paperId, double newPrice) async {
    final idx = _papers.indexWhere((p) => p.id == paperId);
    if (idx != -1) {
      _papers[idx].sheetPrice = newPrice;
      await _storage.savePapers(_papers);
      notifyListeners();
    }
  }

  /// تعديل معايير وأسعار الماكينة (تكلفة الساعة، السرعة، الهالك)
  Future<void> updateMachineRates({
    required String machineId,
    double? hourlyCost,
    int? speedPerHour,
    double? wastePct,
  }) async {
    final idx = _machines.indexWhere((m) => m.id == machineId);
    if (idx != -1) {
      if (hourlyCost != null) _machines[idx].hourlyCost = hourlyCost;
      if (speedPerHour != null) _machines[idx].speedPerHour = speedPerHour;
      if (wastePct != null) _machines[idx].wastePct = wastePct;
      await _storage.saveMachines(_machines);
      notifyListeners();
    }
  }

  /// تعديل سعر خدمة التشطيب
  Future<void> updateFinishingPrice(String finishingId, double newPrice, [String? unit]) async {
    final idx = _finishings.indexWhere((f) => f.id == finishingId);
    if (idx != -1) {
      _finishings[idx].price = newPrice;
      if (unit != null) _finishings[idx].unit = unit;
      await _storage.saveFinishings(_finishings);
      notifyListeners();
    }
  }

  /// تعديل الثوابت العامة للتسعير (سعر البليت، هامش الربح، الضريبة)
  Future<void> updatePricingConstants({
    double? platePrice,
    double? profitMarginPct,
    double? taxPct,
  }) async {
    if (platePrice != null) _settings.defaultPlatePrice = platePrice;
    if (profitMarginPct != null) _settings.defaultProfitMarginPct = profitMarginPct;
    if (taxPct != null) _settings.taxPct = taxPct;
    await _storage.saveSettings(_settings);
    notifyListeners();
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
    final quote = Quotation(
      id: 'Q_${DateTime.now().millisecondsSinceEpoch}',
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
      status: status,
    );

    _quotations.insert(0, quote);
    await _storage.saveQuotations(_quotations);

    // إذا تم إنشاؤه معتمداً، نحدث مبيعات العميل ونولد أمر إنتاج فوراً
    if (status == 'معتمد') {
      _applyCustomerSale(customerId, quoteAmount);
      await createProductionOrderFromQuote(quote);
    }

    notifyListeners();
    return quote;
  }

  Future<void> updateQuotationStatus(String quoteId, String newStatus) async {
    final index = _quotations.indexWhere((q) => q.id == quoteId);
    if (index != -1) {
      final oldStatus = _quotations[index].status;
      _quotations[index].status = newStatus;

      // إذا تحول لمعتمد
      if (oldStatus != 'معتمد' && newStatus == 'معتمد') {
        _applyCustomerSale(_quotations[index].customerId, _quotations[index].quoteAmount);
        await createProductionOrderFromQuote(_quotations[index]);
      }

      await _storage.saveQuotations(_quotations);
      notifyListeners();
    }
  }

  // --- PRODUCTION ORDERS ACTIONS ---
  String generateNextOrderNumber() {
    final year = DateTime.now().year;
    final count = _productionOrders.length + 1;
    return 'PO-$year-${count.toString().padLeft(4, '0')}';
  }

  Future<ProductionOrder> createProductionOrderFromQuote(Quotation quote) async {
    // جلب معلومات الورق والماكينة من تفاصيل التسعير إن وجدت
    final pDetails = quote.pricingDetails;
    final sheetsReq = pDetails != null ? pDetails.totalSheets : (quote.qty * 10.0);
    final sheetsWaste = pDetails != null ? pDetails.sheetsWithWaste : (sheetsReq * 1.05);
    final runHrs = pDetails != null ? pDetails.runHours : 1.5;
    final paperId = pDetails != null ? pDetails.paperId : (_papers.isNotEmpty ? _papers.first.id : '');

    final order = ProductionOrder(
      id: 'PO_${DateTime.now().millisecondsSinceEpoch}',
      number: generateNextOrderNumber(),
      date: DateTime.now(),
      quotationId: quote.id,
      quotationNumber: quote.number,
      customerId: quote.customerId,
      customerName: quote.customerName,
      product: quote.product,
      qty: quote.qty,
      machine: quote.machine,
      paperName: quote.paper,
      paperId: paperId,
      sheetsRequired: sheetsReq,
      sheetsWithWaste: sheetsWaste,
      runHours: runHrs,
      cost: quote.totalCost,
      status: 'معتمد',
      dueDate: DateTime.now().add(const Duration(days: 3)),
      notes: 'تم إنشاؤه تلقائياً من عرض السعر ${quote.number}',
    );

    _productionOrders.insert(0, order);
    await _storage.saveProductionOrders(_productionOrders);
    notifyListeners();
    return order;
  }

  Future<void> updateProductionOrderStatus(String orderId, String newStatus) async {
    final index = _productionOrders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _productionOrders[index].status = newStatus;
      await _storage.saveProductionOrders(_productionOrders);
      notifyListeners();
    }
  }

  Future<void> deleteProductionOrder(String orderId) async {
    _productionOrders.removeWhere((o) => o.id == orderId);
    await _storage.saveProductionOrders(_productionOrders);
    notifyListeners();
  }

  /// صرف الورق لأمر الإنتاج وخصم الرصيد تلقائياً من المخزون
  Future<bool> deductPaperForOrder(String orderId) async {
    final index = _productionOrders.indexWhere((o) => o.id == orderId);
    if (index == -1) return false;
    final order = _productionOrders[index];
    if (order.isPaperDeducted) return true; // مصروف مسبقاً

    // العثور على صنف الورق
    PaperItem? paper;
    if (order.paperId.isNotEmpty) {
      final matches = _papers.where((p) => p.id == order.paperId);
      if (matches.isNotEmpty) paper = matches.first;
    }
    if (paper == null) {
      final matches = _papers.where((p) => order.paperName.contains(p.category));
      if (matches.isNotEmpty) paper = matches.first;
    }
    if (paper == null && _papers.isNotEmpty) paper = _papers.first;

    if (paper == null) return false;

    // حساب كمية أفرخ 100x70 المطلوبة (sheetsWithWaste مقسومة على 4 ملازم)
    final sheetsToDeduct = (order.sheetsWithWaste / (paper.sheetsPerUnit > 0 ? paper.sheetsPerUnit : 4)).ceilToDouble();

    // تسجيل حركة خروج
    await addStockMove(
      moveType: 'خروج',
      paperId: paper.id,
      qtySheets: sheetsToDeduct,
      unitPrice: paper.sheetPrice,
      reference: 'أمر إنتاج ${order.number}',
      notes: 'صرف ورق تلقائي لأمر الإنتاج ${order.number} (${order.product})',
    );

    _productionOrders[index].isPaperDeducted = true;
    if (_productionOrders[index].status == 'معتمد') {
      _productionOrders[index].status = 'قيد الإنتاج';
    }
    await _storage.saveProductionOrders(_productionOrders);
    notifyListeners();
    return true;
  }

  // --- PAPERS & STOCK MOVES ACTIONS ---
  String generateNextStockMoveNumber() {
    final count = _stockMoves.length + 1;
    return 'SM-${count.toString().padLeft(4, '0')}';
  }

  Future<void> addStockMove({
    required String moveType, // دخول / خروج / تسوية
    required String paperId,
    required double qtySheets,
    required double unitPrice,
    String? reference,
    String? supplier,
    String? notes,
  }) async {
    final pIndex = _papers.indexWhere((p) => p.id == paperId);
    if (pIndex == -1) return;
    final paper = _papers[pIndex];

    // تحديث رصيد الورق
    if (moveType == 'دخول') {
      paper.balance += qtySheets;
      if (unitPrice > 0) paper.sheetPrice = unitPrice;
    } else if (moveType == 'خروج') {
      paper.balance -= qtySheets;
    } else if (moveType == 'تسوية') {
      paper.balance = qtySheets; // ضبط مباشر للرصيد
    }

    final move = StockMove(
      id: 'SM_${DateTime.now().millisecondsSinceEpoch}',
      number: generateNextStockMoveNumber(),
      date: DateTime.now(),
      moveType: moveType,
      paperId: paper.id,
      paperCategory: paper.category,
      paperType: paper.paperType,
      gsm: paper.gsm,
      qtySheets: qtySheets,
      unitPrice: unitPrice,
      totalValue: qtySheets * unitPrice,
      reference: reference,
      supplier: supplier ?? paper.supplier,
      notes: notes,
    );

    _stockMoves.insert(0, move);
    await _storage.savePapers(_papers);
    await _storage.saveStockMoves(_stockMoves);
    notifyListeners();
  }

  Future<void> deleteStockMove(String id) async {
    final index = _stockMoves.indexWhere((m) => m.id == id);
    if (index != -1) {
      final move = _stockMoves[index];
      // عكس أثر الحركة على الرصيد
      final pIndex = _papers.indexWhere((p) => p.id == move.paperId);
      if (pIndex != -1) {
        if (move.moveType == 'دخول') {
          _papers[pIndex].balance -= move.qtySheets;
        } else if (move.moveType == 'خروج') {
          _papers[pIndex].balance += move.qtySheets;
        }
        await _storage.savePapers(_papers);
      }
      _stockMoves.removeAt(index);
      await _storage.saveStockMoves(_stockMoves);
      notifyListeners();
    }
  }

  Future<void> addPaper(PaperItem paper) async {
    _papers.add(paper);
    await _storage.savePapers(_papers);
    notifyListeners();
  }

  Future<void> updatePaper(PaperItem paper) async {
    final index = _papers.indexWhere((p) => p.id == paper.id);
    if (index != -1) {
      _papers[index] = paper;
      await _storage.savePapers(_papers);
      notifyListeners();
    }
  }

  Future<void> deletePaper(String id) async {
    _papers.removeWhere((p) => p.id == id);
    await _storage.savePapers(_papers);
    notifyListeners();
  }

  // --- INKS & INK MOVES ACTIONS ---
  Future<void> addInkMove({
    required String moveType,
    required String inkId,
    required double qty,
    required double unitPrice,
    String? reference,
    String? notes,
  }) async {
    final iIndex = _inks.indexWhere((i) => i.id == inkId);
    if (iIndex == -1) return;
    final ink = _inks[iIndex];

    if (moveType == 'دخول') {
      ink.balance += qty;
      if (unitPrice > 0) ink.unitPrice = unitPrice;
    } else if (moveType == 'خروج') {
      ink.balance -= qty;
    } else if (moveType == 'تسوية') {
      ink.balance = qty;
    }

    final move = InkMove(
      id: 'INKM_${DateTime.now().millisecondsSinceEpoch}',
      number: 'IM-${(_inkMoves.length + 1).toString().padLeft(4, '0')}',
      date: DateTime.now(),
      moveType: moveType,
      inkId: ink.id,
      inkName: '${ink.name} (${ink.kind})',
      qty: qty,
      unitPrice: unitPrice,
      totalValue: qty * unitPrice,
      reference: reference,
      notes: notes,
    );

    _inkMoves.insert(0, move);
    await _storage.saveInks(_inks);
    await _storage.saveInkMoves(_inkMoves);
    notifyListeners();
  }

  Future<void> updateInk(InkItem ink) async {
    final idx = _inks.indexWhere((i) => i.id == ink.id);
    if (idx != -1) {
      _inks[idx] = ink;
      await _storage.saveInks(_inks);
      notifyListeners();
    }
  }

  // --- CUSTOMERS & PAYMENTS ACTIONS ---
  String generateNextCustomerCode() {
    return 'C-${(_customers.length + 1).toString().padLeft(4, '0')}';
  }

  Future<void> addCustomer(Customer customer) async {
    _customers.add(customer);
    await _storage.saveCustomers(_customers);
    notifyListeners();
  }

  Future<void> updateCustomer(Customer customer) async {
    final idx = _customers.indexWhere((c) => c.id == customer.id);
    if (idx != -1) {
      _customers[idx] = customer;
      await _storage.saveCustomers(_customers);
      notifyListeners();
    }
  }

  Future<void> deleteCustomer(String id) async {
    _customers.removeWhere((c) => c.id == id);
    await _storage.saveCustomers(_customers);
    notifyListeners();
  }

  void _applyCustomerSale(String customerId, double amount) {
    final idx = _customers.indexWhere((c) => c.id == customerId);
    if (idx != -1) {
      _customers[idx].totalSales += amount;
      _storage.saveCustomers(_customers);
    }
  }

  String generateNextPaymentNumber() {
    return 'PAY-${(_payments.length + 1).toString().padLeft(4, '0')}';
  }

  Future<void> recordPayment({
    required String customerId,
    required double amount,
    String paymentMethod = 'نقدي',
    String? reference,
    String? notes,
  }) async {
    final idx = _customers.indexWhere((c) => c.id == customerId);
    if (idx == -1) return;
    final customer = _customers[idx];

    customer.paid += amount;

    final pay = PaymentRecord(
      id: 'PAY_${DateTime.now().millisecondsSinceEpoch}',
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
    await _storage.saveCustomers(_customers);
    await _storage.savePayments(_payments);
    notifyListeners();
  }

  // --- MACHINES, PRODUCTS, FINISHINGS ACTIONS ---
  Future<void> updateMachine(MachineItem m) async {
    final idx = _machines.indexWhere((x) => x.id == m.id);
    if (idx != -1) {
      _machines[idx] = m;
      await _storage.saveMachines(_machines);
      notifyListeners();
    }
  }

  Future<void> updateFinishing(FinishingItem f) async {
    final idx = _finishings.indexWhere((x) => x.id == f.id);
    if (idx != -1) {
      _finishings[idx] = f;
      await _storage.saveFinishings(_finishings);
      notifyListeners();
    }
  }

  Future<void> addProduct(ProductTemplate p) async {
    _products.add(p);
    await _storage.saveProducts(_products);
    notifyListeners();
  }

  Future<void> updateProduct(ProductTemplate p) async {
    final idx = _products.indexWhere((x) => x.id == p.id);
    if (idx != -1) {
      _products[idx] = p;
      await _storage.saveProducts(_products);
      notifyListeners();
    }
  }

  /// إعادة تعيين البيانات إلى البيانات الأولية للإكسل
  Future<void> resetToExcelDefaults() async {
    await _storage.seedInitialData();
    _loadAll();
    notifyListeners();
  }

  /// تصدير نسخة احتياطية من كافة جداول وبيانات النظام بصيغة JSON
  String exportDatabaseBackup() {
    return _storage.exportBackupJson();
  }

  /// استيراد نسخة احتياطية واستعادة كافة البيانات
  Future<bool> importDatabaseBackup(String jsonStr) async {
    final success = await _storage.importBackupJson(jsonStr);
    if (success) {
      _loadAll();
      notifyListeners();
    }
    return success;
  }
}
