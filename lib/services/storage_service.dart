import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';

class StorageService {
  static const String _kSettings = 'erp_settings';
  static const String _kPapers = 'erp_papers';
  static const String _kMachines = 'erp_machines';
  static const String _kProducts = 'erp_products';
  static const String _kFinishings = 'erp_finishings';
  static const String _kInks = 'erp_inks';
  static const String _kInkMoves = 'erp_ink_moves';
  static const String _kCustomers = 'erp_customers';
  static const String _kQuotations = 'erp_quotations';
  static const String _kProductionOrders = 'erp_production_orders';
  static const String _kStockMoves = 'erp_stock_moves';
  static const String _kPayments = 'erp_payments';
  static const String _kInitialized = 'erp_initialized_v1';
  static const String _kUsers = 'erp_users';
  static const String _kActiveUserId = 'erp_active_user_id';
  static const String _kLoginAttempts = 'erp_login_attempts';
  static const String _kLockoutUntil = 'erp_lockout_until';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    final service = StorageService(prefs);
    if (!prefs.containsKey(_kInitialized)) {
      await service.seedInitialData();
      await prefs.setBool(_kInitialized, true);
    }
    return service;
  }

  // --- SETTINGS ---
  AppSettings loadSettings() {
    final str = _prefs.getString(_kSettings);
    if (str != null) {
      return AppSettings.fromJson(jsonDecode(str));
    }
    return AppSettings();
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _prefs.setString(_kSettings, jsonEncode(settings.toJson()));
  }

  // --- PAPERS ---
  List<PaperItem> loadPapers() {
    final list = _prefs.getStringList(_kPapers);
    if (list != null) {
      return list.map((s) => PaperItem.fromJson(jsonDecode(s))).toList();
    }
    return [];
  }

  Future<void> savePapers(List<PaperItem> papers) async {
    final list = papers.map((p) => jsonEncode(p.toJson())).toList();
    await _prefs.setStringList(_kPapers, list);
  }

  // --- MACHINES ---
  List<MachineItem> loadMachines() {
    final list = _prefs.getStringList(_kMachines);
    if (list != null) {
      return list.map((s) => MachineItem.fromJson(jsonDecode(s))).toList();
    }
    return [];
  }

  Future<void> saveMachines(List<MachineItem> machines) async {
    final list = machines.map((m) => jsonEncode(m.toJson())).toList();
    await _prefs.setStringList(_kMachines, list);
  }

  // --- PRODUCTS ---
  List<ProductTemplate> loadProducts() {
    final list = _prefs.getStringList(_kProducts);
    if (list != null) {
      return list.map((s) => ProductTemplate.fromJson(jsonDecode(s))).toList();
    }
    return [];
  }

  Future<void> saveProducts(List<ProductTemplate> products) async {
    final list = products.map((p) => jsonEncode(p.toJson())).toList();
    await _prefs.setStringList(_kProducts, list);
  }

  // --- FINISHINGS ---
  List<FinishingItem> loadFinishings() {
    final list = _prefs.getStringList(_kFinishings);
    if (list != null) {
      return list.map((s) => FinishingItem.fromJson(jsonDecode(s))).toList();
    }
    return [];
  }

  Future<void> saveFinishings(List<FinishingItem> finishings) async {
    final list = finishings.map((f) => jsonEncode(f.toJson())).toList();
    await _prefs.setStringList(_kFinishings, list);
  }

  // --- INKS ---
  List<InkItem> loadInks() {
    final list = _prefs.getStringList(_kInks);
    if (list != null) {
      return list.map((s) => InkItem.fromJson(jsonDecode(s))).toList();
    }
    return [];
  }

  Future<void> saveInks(List<InkItem> inks) async {
    final list = inks.map((i) => jsonEncode(i.toJson())).toList();
    await _prefs.setStringList(_kInks, list);
  }

  // --- INK MOVES ---
  List<InkMove> loadInkMoves() {
    final list = _prefs.getStringList(_kInkMoves);
    if (list != null) {
      return list.map((s) => InkMove.fromJson(jsonDecode(s))).toList();
    }
    return [];
  }

  Future<void> saveInkMoves(List<InkMove> moves) async {
    final list = moves.map((m) => jsonEncode(m.toJson())).toList();
    await _prefs.setStringList(_kInkMoves, list);
  }

  // --- CUSTOMERS ---
  List<Customer> loadCustomers() {
    final list = _prefs.getStringList(_kCustomers);
    if (list != null) {
      return list.map((s) => Customer.fromJson(jsonDecode(s))).toList();
    }
    return [];
  }

  Future<void> saveCustomers(List<Customer> customers) async {
    final list = customers.map((c) => jsonEncode(c.toJson())).toList();
    await _prefs.setStringList(_kCustomers, list);
  }

  // --- QUOTATIONS ---
  List<Quotation> loadQuotations() {
    final list = _prefs.getStringList(_kQuotations);
    if (list != null) {
      return list.map((s) => Quotation.fromJson(jsonDecode(s))).toList();
    }
    return [];
  }

  Future<void> saveQuotations(List<Quotation> quotations) async {
    final list = quotations.map((q) => jsonEncode(q.toJson())).toList();
    await _prefs.setStringList(_kQuotations, list);
  }

  // --- PRODUCTION ORDERS ---
  List<ProductionOrder> loadProductionOrders() {
    final list = _prefs.getStringList(_kProductionOrders);
    if (list != null) {
      return list.map((s) => ProductionOrder.fromJson(jsonDecode(s))).toList();
    }
    return [];
  }

  Future<void> saveProductionOrders(List<ProductionOrder> orders) async {
    final list = orders.map((o) => jsonEncode(o.toJson())).toList();
    await _prefs.setStringList(_kProductionOrders, list);
  }

  // --- STOCK MOVES ---
  List<StockMove> loadStockMoves() {
    final list = _prefs.getStringList(_kStockMoves);
    if (list != null) {
      return list.map((s) => StockMove.fromJson(jsonDecode(s))).toList();
    }
    return [];
  }

  Future<void> saveStockMoves(List<StockMove> moves) async {
    final list = moves.map((m) => jsonEncode(m.toJson())).toList();
    await _prefs.setStringList(_kStockMoves, list);
  }

  // --- PAYMENTS ---
  List<PaymentRecord> loadPayments() {
    final list = _prefs.getStringList(_kPayments);
    if (list != null) {
      return list.map((s) => PaymentRecord.fromJson(jsonDecode(s))).toList();
    }
    return [];
  }

  Future<void> savePayments(List<PaymentRecord> payments) async {
    final list = payments.map((p) => jsonEncode(p.toJson())).toList();
    await _prefs.setStringList(_kPayments, list);
  }

  /// تصدير نسخة احتياطية شاملة لكافة بيانات ومحتويات النظام كـ JSON
  String exportBackupJson() {
    final data = <String, dynamic>{
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'settings': _prefs.getString(_kSettings),
      'papers': _prefs.getStringList(_kPapers),
      'machines': _prefs.getStringList(_kMachines),
      'products': _prefs.getStringList(_kProducts),
      'finishings': _prefs.getStringList(_kFinishings),
      'inks': _prefs.getStringList(_kInks),
      'inkMoves': _prefs.getStringList(_kInkMoves),
      'customers': _prefs.getStringList(_kCustomers),
      'quotations': _prefs.getStringList(_kQuotations),
      'productionOrders': _prefs.getStringList(_kProductionOrders),
      'stockMoves': _prefs.getStringList(_kStockMoves),
      'payments': _prefs.getStringList(_kPayments),
    };
    return jsonEncode(data);
  }

  /// استيراد نسخة احتياطية واسترجاع كافة البيانات للقاعدة المحلية
  Future<bool> importBackupJson(String jsonStr) async {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      if (data['settings'] != null) await _prefs.setString(_kSettings, data['settings']);
      if (data['papers'] != null) await _prefs.setStringList(_kPapers, List<String>.from(data['papers']));
      if (data['machines'] != null) await _prefs.setStringList(_kMachines, List<String>.from(data['machines']));
      if (data['products'] != null) await _prefs.setStringList(_kProducts, List<String>.from(data['products']));
      if (data['finishings'] != null) await _prefs.setStringList(_kFinishings, List<String>.from(data['finishings']));
      if (data['inks'] != null) await _prefs.setStringList(_kInks, List<String>.from(data['inks']));
      if (data['inkMoves'] != null) await _prefs.setStringList(_kInkMoves, List<String>.from(data['inkMoves']));
      if (data['customers'] != null) await _prefs.setStringList(_kCustomers, List<String>.from(data['customers']));
      if (data['quotations'] != null) await _prefs.setStringList(_kQuotations, List<String>.from(data['quotations']));
      if (data['productionOrders'] != null) await _prefs.setStringList(_kProductionOrders, List<String>.from(data['productionOrders']));
      if (data['stockMoves'] != null) await _prefs.setStringList(_kStockMoves, List<String>.from(data['stockMoves']));
      if (data['payments'] != null) await _prefs.setStringList(_kPayments, List<String>.from(data['payments']));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// تهيئة البيانات الافتراضية الأولية المستخرجة حرفياً من ملف الإكسل ERP_مطبعة_متكامل.xls
  Future<void> seedInitialData() async {
    final settings = AppSettings(
      sheetSize: '100x70',
      unitSize: '50x35',
      defaultPlatePrice: 1250,
      defaultProfitMarginPct: 30,
      workHoursPerDay: 8,
      currency: 'ريال يمني',
      taxPct: 0,
      companyName: 'مطبعة التميز الحديثة المتكاملة',
      companyPhone: '+967 771 234 567',
      companyAddress: 'صنعاء - التحرير - شارع المطابع',
    );
    await saveSettings(settings);

    // 18 صنف ورق من شيت قاعدة_الورق مع أسعار واقعية وأرصدة تشغيلية
    final papers = [
      PaperItem(id: 'P01', category: 'أوفست', paperType: 'أبيض', gsm: 70, sheetSize: '100x70', sheetsPerUnit: 4, sheetPrice: 120, reorderLevel: 500, balance: 1200, supplier: 'شركة الورق الحديث'),
      PaperItem(id: 'P02', category: 'أوفست', paperType: 'أبيض', gsm: 80, sheetSize: '100x70', sheetsPerUnit: 4, sheetPrice: 140, reorderLevel: 500, balance: 850, supplier: 'شركة الورق الحديث'),
      PaperItem(id: 'P03', category: 'أوفست', paperType: 'أبيض', gsm: 100, sheetSize: '100x70', sheetsPerUnit: 4, sheetPrice: 175, reorderLevel: 500, balance: 400, supplier: 'شركة الورق الحديث'),
      PaperItem(id: 'P04', category: 'كوشيه', paperType: 'لامع', gsm: 115, sheetSize: '100x70', sheetsPerUnit: 4, sheetPrice: 195, reorderLevel: 300, balance: 650, supplier: 'مؤسسة النبراس التجارية'),
      PaperItem(id: 'P05', category: 'كوشيه', paperType: 'لامع', gsm: 150, sheetSize: '100x70', sheetsPerUnit: 4, sheetPrice: 240, reorderLevel: 300, balance: 900, supplier: 'مؤسسة النبراس التجارية'),
      PaperItem(id: 'P06', category: 'كوشيه', paperType: 'لامع', gsm: 300, sheetSize: '100x70', sheetsPerUnit: 4, sheetPrice: 460, reorderLevel: 200, balance: 350, supplier: 'مؤسسة النبراس التجارية'),
      PaperItem(id: 'P07', category: 'كوشيه', paperType: 'مطفي', gsm: 150, sheetSize: '100x70', sheetsPerUnit: 4, sheetPrice: 250, reorderLevel: 300, balance: 500, supplier: 'مؤسسة النبراس التجارية'),
      PaperItem(id: 'P08', category: 'كوشيه', paperType: 'مطفي', gsm: 200, sheetSize: '100x70', sheetsPerUnit: 4, sheetPrice: 320, reorderLevel: 250, balance: 280, supplier: 'مؤسسة النبراس التجارية'),
      PaperItem(id: 'P09', category: 'بريستول', paperType: '250', gsm: 250, sheetSize: '100x70', sheetsPerUnit: 4, sheetPrice: 390, reorderLevel: 250, balance: 300, supplier: 'المورد العالمي للورق'),
      PaperItem(id: 'P10', category: 'بريستول', paperType: '300', gsm: 300, sheetSize: '100x70', sheetsPerUnit: 4, sheetPrice: 470, reorderLevel: 200, balance: 180, supplier: 'المورد العالمي للورق'),
      PaperItem(id: 'P11', category: 'دوبلكس', paperType: '350', gsm: 350, sheetSize: '100x70', sheetsPerUnit: 4, sheetPrice: 380, reorderLevel: 200, balance: 220, supplier: 'المورد العالمي للورق'),
      PaperItem(id: 'P12', category: 'كرافت', paperType: '200', gsm: 200, sheetSize: '100x70', sheetsPerUnit: 4, sheetPrice: 270, reorderLevel: 250, balance: 410, supplier: 'شركة الأمل للتغليف'),
      PaperItem(id: 'P13', category: 'ورق مكربن', paperType: 'أبيض', gsm: 55, sheetSize: '100x70', sheetsPerUnit: 4, sheetPrice: 110, reorderLevel: 200, balance: 750, supplier: 'مؤسسة الأوراق الفنية'),
      PaperItem(id: 'P14', category: 'ورق مكربن', paperType: 'وردي', gsm: 55, sheetSize: '100x70', sheetsPerUnit: 4, sheetPrice: 115, reorderLevel: 200, balance: 600, supplier: 'مؤسسة الأوراق الفنية'),
      PaperItem(id: 'P15', category: 'ورق مكربن', paperType: 'أصفر', gsm: 55, sheetSize: '100x70', sheetsPerUnit: 4, sheetPrice: 115, reorderLevel: 200, balance: 550, supplier: 'مؤسسة الأوراق الفنية'),
      PaperItem(id: 'P16', category: 'NCR', paperType: 'أبيض', gsm: 55, sheetSize: '100x70', sheetsPerUnit: 4, sheetPrice: 125, reorderLevel: 200, balance: 800, supplier: 'شركة NCR الدولية'),
      PaperItem(id: 'P17', category: 'NCR', paperType: 'وردي', gsm: 55, sheetSize: '100x70', sheetsPerUnit: 4, sheetPrice: 130, reorderLevel: 200, balance: 650, supplier: 'شركة NCR الدولية'),
      PaperItem(id: 'P18', category: 'NCR', paperType: 'أصفر', gsm: 55, sheetSize: '100x70', sheetsPerUnit: 4, sheetPrice: 130, reorderLevel: 200, balance: 700, supplier: 'شركة NCR الدولية'),
    ];
    await savePapers(papers);

    // 3 ماكينات من شيت الماكينات
    final machines = [
      MachineItem(id: 'M01', name: 'أوفست 50x35', kind: 'Offset', wastePct: 5.0, hourlyCost: 5000.0, speedPerHour: 5000, status: 'نشطة'),
      MachineItem(id: 'M02', name: 'Epson', kind: 'Digital', wastePct: 2.0, hourlyCost: 3500.0, speedPerHour: 1200, status: 'نشطة'),
      MachineItem(id: 'M03', name: 'Sharp', kind: 'Copier', wastePct: 1.0, hourlyCost: 2000.0, speedPerHour: 800, status: 'نشطة'),
    ];
    await saveMachines(machines);

    // 4 قوالب منتجات من شيت المنتجات
    final products = [
      ProductTemplate(id: 'PRD01', name: 'كتاب A5', category: 'كتب', defaultPages: 96, binding: 'حراري', pagesPerSheet: 8, defaultMachine: 'أوفست 50x35', defaultPaperCategory: 'أوفست', defaultPaperType: 'أبيض'),
      ProductTemplate(id: 'PRD02', name: 'مجلة A4', category: 'كتب', defaultPages: 32, binding: 'دبوس', pagesPerSheet: 4, defaultMachine: 'أوفست 50x35', defaultPaperCategory: 'كوشيه', defaultPaperType: 'لامع'),
      ProductTemplate(id: 'PRD03', name: 'فاتورة NCR', category: 'دفاتر', defaultNcrCopies: 4, defaultSheetsPerBook: 50, binding: 'دبوس', pagesPerSheet: 4, defaultMachine: 'أوفست 50x35', defaultPaperCategory: 'ورق مكربن', defaultPaperType: 'أبيض'),
      ProductTemplate(id: 'PRD04', name: 'سند قبض NCR', category: 'دفاتر', defaultNcrCopies: 3, defaultSheetsPerBook: 50, binding: 'دبوس', pagesPerSheet: 4, defaultMachine: 'أوفست 50x35', defaultPaperCategory: 'ورق مكربن', defaultPaperType: 'أبيض'),
    ];
    await saveProducts(products);

    // 12 خدمة تشطيب من شيت التشطيبات
    final finishings = [
      FinishingItem(id: 'F01', name: 'قص', price: 1500, unit: 'للعملية'),
      FinishingItem(id: 'F02', name: 'طي', price: 2000, unit: 'للألف'),
      FinishingItem(id: 'F03', name: 'تدبيس', price: 1800, unit: 'للألف'),
      FinishingItem(id: 'F04', name: 'ترقيم', price: 1200, unit: 'للألف'),
      FinishingItem(id: 'F05', name: 'سلوفان مطفي', price: 4500, unit: 'للألف'),
      FinishingItem(id: 'F06', name: 'سلوفان لامع', price: 4000, unit: 'للألف'),
      FinishingItem(id: 'F07', name: 'UV', price: 6000, unit: 'للألف'),
      FinishingItem(id: 'F08', name: 'تذهيب', price: 8000, unit: 'للعملية'),
      FinishingItem(id: 'F09', name: 'تكسير', price: 3500, unit: 'للعملية'),
      FinishingItem(id: 'F10', name: 'تخريم', price: 1000, unit: 'للألف'),
      FinishingItem(id: 'F11', name: 'تجليد حراري', price: 50, unit: 'للقطعة'),
      FinishingItem(id: 'F12', name: 'تجليد سلك', price: 80, unit: 'للقطعة'),
    ];
    await saveFinishings(finishings);

    // 5 أحبار من شيت الأحبار
    final inks = [
      InkItem(id: 'INK01', name: 'أسود (K)', colorCode: 'K', kind: 'Offset', unitPrice: 3500, balance: 12, reorderLevel: 2, supplier: 'الشركة الشرقية للأحبار'),
      InkItem(id: 'INK02', name: 'سماوي (C)', colorCode: 'C', kind: 'Offset', unitPrice: 4200, balance: 8, reorderLevel: 2, supplier: 'الشركة الشرقية للأحبار'),
      InkItem(id: 'INK03', name: 'أرجواني (M)', colorCode: 'M', kind: 'Offset', unitPrice: 4200, balance: 7, reorderLevel: 2, supplier: 'الشركة الشرقية للأحبار'),
      InkItem(id: 'INK04', name: 'أصفر (Y)', colorCode: 'Y', kind: 'Offset', unitPrice: 4500, balance: 9, reorderLevel: 2, supplier: 'الشركة الشرقية للأحبار'),
      InkItem(id: 'INK05', name: 'أسود ديجيتال', colorCode: 'Black', kind: 'Digital', unitPrice: 7000, balance: 4, reorderLevel: 1, supplier: 'إبسون الشرق الأوسط'),
    ];
    await saveInks(inks);

    // عملاء تجريبيين
    final customers = [
      Customer(id: 'C01', code: 'C-0001', name: 'دار المعرفة للنشر والتوزيع', phone: '+967 771 111 222', address: 'صنعاء - شارع الزبيري', openingBalance: 0, totalSales: 485000, paid: 350000),
      Customer(id: 'C02', code: 'C-0002', name: 'شركة الأفق للاستيراد والتجارة', phone: '+967 772 333 444', address: 'صنعاء - شارع حدة', openingBalance: 50000, totalSales: 290000, paid: 200000),
      Customer(id: 'C03', code: 'C-0003', name: 'مؤسسة صدى الإعلام للإعلان', phone: '+967 773 555 666', address: 'صنعاء - شارع الستين', openingBalance: 0, totalSales: 160000, paid: 160000),
    ];
    await saveCustomers(customers);

    // عروض أسعار تجريبية
    final quotations = [
      Quotation(
        id: 'Q01',
        number: 'Q-2026-0001',
        date: DateTime.now().subtract(const Duration(days: 3)),
        customerId: 'C01',
        customerCode: 'C-0001',
        customerName: 'دار المعرفة للنشر والتوزيع',
        product: 'كتاب A5',
        qty: 1000,
        pages: 96,
        paper: 'أوفست أبيض 70 جم',
        machine: 'أوفست 50x35',
        unitPrice: 485,
        status: 'معتمد',
        totalCost: 373075,
        quoteAmount: 485000,
        profit: 111925,
        notes: 'كتاب أدبي غلاف كوشيه 300 وسلوفان مطفي',
      ),
      Quotation(
        id: 'Q02',
        number: 'Q-2026-0002',
        date: DateTime.now().subtract(const Duration(days: 1)),
        customerId: 'C02',
        customerCode: 'C-0002',
        customerName: 'شركة الأفق للاستيراد والتجارة',
        product: 'فاتورة NCR',
        qty: 100,
        pages: 0,
        ncrCopies: 4,
        paper: 'ورق مكربن أبيض 55 جم',
        machine: 'أوفست 50x35',
        unitPrice: 2900,
        status: 'معتمد',
        totalCost: 223077,
        quoteAmount: 290000,
        profit: 66923,
        notes: 'دفاتر مقاس A5 أربع نسخ مع ترقيم وتدبيس',
      ),
    ];
    await saveQuotations(quotations);

    // أوامر إنتاج تجريبية
    final productionOrders = [
      ProductionOrder(
        id: 'PO01',
        number: 'PO-2026-0001',
        date: DateTime.now().subtract(const Duration(days: 2)),
        quotationId: 'Q01',
        quotationNumber: 'Q-2026-0001',
        customerId: 'C01',
        customerName: 'دار المعرفة للنشر والتوزيع',
        product: 'كتاب A5',
        qty: 1000,
        machine: 'أوفست 50x35',
        paperName: 'أوفست أبيض 70 جم',
        paperId: 'P01',
        sheetsRequired: 12000,
        sheetsWithWaste: 12600,
        runHours: 2.52,
        cost: 373075,
        status: 'قيد الإنتاج',
        dueDate: DateTime.now().add(const Duration(days: 4)),
        notes: 'تسليم الدفعة الأولى 500 نسخة السبت القادم',
        isPaperDeducted: true,
      ),
      ProductionOrder(
        id: 'PO02',
        number: 'PO-2026-0002',
        date: DateTime.now(),
        quotationId: 'Q02',
        quotationNumber: 'Q-2026-0002',
        customerId: 'C02',
        customerName: 'شركة الأفق للاستيراد والتجارة',
        product: 'فاتورة NCR',
        qty: 100,
        machine: 'أوفست 50x35',
        paperName: 'ورق مكربن أبيض 55 جم',
        paperId: 'P13',
        sheetsRequired: 5000,
        sheetsWithWaste: 5250,
        runHours: 1.05,
        cost: 223077,
        status: 'معتمد',
        dueDate: DateTime.now().add(const Duration(days: 2)),
        notes: 'جاهز لبدء الإنتاج بعد سحب الزنكات',
        isPaperDeducted: false,
      ),
    ];
    await saveProductionOrders(productionOrders);

    // حركات مخزون الورق
    final stockMoves = [
      StockMove(
        id: 'SM01',
        number: 'SM-0001',
        date: DateTime.now().subtract(const Duration(days: 10)),
        moveType: 'دخول',
        paperId: 'P01',
        paperCategory: 'أوفست',
        paperType: 'أبيض',
        gsm: 70,
        qtySheets: 5000,
        unitPrice: 120,
        totalValue: 600000,
        reference: 'فاتورة شراء رقم 1042',
        supplier: 'شركة الورق الحديث',
        notes: 'رصيد افتتاحي مشتريات مخزن رئيسي',
      ),
      StockMove(
        id: 'SM02',
        number: 'SM-0002',
        date: DateTime.now().subtract(const Duration(days: 2)),
        moveType: 'خروج',
        paperId: 'P01',
        paperCategory: 'أوفست',
        paperType: 'أبيض',
        gsm: 70,
        qtySheets: 3150, // 12600 ملازم 50x35 مقسومة على 4 = 3150 فرخ 100x70
        unitPrice: 120,
        totalValue: 378000,
        reference: 'أمر إنتاج PO-2026-0001',
        notes: 'صرف ورق لطباعة 1000 كتاب A5',
      ),
    ];
    await saveStockMoves(stockMoves);

    // سجل المدفوعات
    final payments = [
      PaymentRecord(
        id: 'PAY01',
        number: 'PAY-0001',
        date: DateTime.now().subtract(const Duration(days: 2)),
        customerId: 'C01',
        customerName: 'دار المعرفة للنشر والتوزيع',
        amount: 350000,
        paymentMethod: 'تحويل بنكي',
        reference: 'حوالة بنك الكريمي رقم 98214',
        notes: 'دفعة مقدمة لعرض السعر Q-2026-0001',
      ),
      PaymentRecord(
        id: 'PAY02',
        number: 'PAY-0002',
        date: DateTime.now().subtract(const Duration(days: 1)),
        customerId: 'C02',
        customerName: 'شركة الأفق للاستيراد والتجارة',
        amount: 200000,
        paymentMethod: 'نقدي',
        reference: 'سند قبض يدوي رقم 412',
        notes: 'سداد جزئي للفواتير',
      ),
    ];
    await savePayments(payments);
  }

  // ─────────────────────────────────────────────────────────
  // --- USERS ---
  // ─────────────────────────────────────────────────────────

  List<UserAccount> loadUsers() {
    final list = _prefs.getStringList(_kUsers);
    if (list != null) {
      return list
          .map((e) => UserAccount.fromJson(jsonDecode(e)))
          .toList();
    }
    return [];
  }

  Future<void> saveUsers(List<UserAccount> users) async {
    await _prefs.setStringList(
      _kUsers,
      users.map((u) => jsonEncode(u.toJson())).toList(),
    );
  }

  Future<void> addUser(UserAccount user) async {
    final users = loadUsers();
    users.add(user);
    await saveUsers(users);
  }

  Future<void> updateUser(UserAccount updated) async {
    final users = loadUsers();
    final idx = users.indexWhere((u) => u.id == updated.id);
    if (idx >= 0) users[idx] = updated;
    await saveUsers(users);
  }

  Future<void> deleteUser(String userId) async {
    final users = loadUsers();
    users.removeWhere((u) => u.id == userId);
    await saveUsers(users);
  }

  bool hasUsers() => loadUsers().isNotEmpty;

  // --- SESSION ---

  String? getActiveUserId() => _prefs.getString(_kActiveUserId);

  Future<void> setActiveUserId(String? id) async {
    if (id == null) {
      await _prefs.remove(_kActiveUserId);
    } else {
      await _prefs.setString(_kActiveUserId, id);
    }
  }

  UserAccount? getActiveUser() {
    final id = getActiveUserId();
    if (id == null) return null;
    final users = loadUsers();
    try {
      return users.firstWhere((u) => u.id == id && u.isActive);
    } catch (_) {
      return null;
    }
  }

  // --- LOGIN ATTEMPTS / LOCKOUT ---

  int getLoginAttempts(String userId) {
    return _prefs.getInt('${_kLoginAttempts}_$userId') ?? 0;
  }

  Future<void> setLoginAttempts(String userId, int count) async {
    await _prefs.setInt('${_kLoginAttempts}_$userId', count);
  }

  DateTime? getLockoutUntil(String userId) {
    final str = _prefs.getString('${_kLockoutUntil}_$userId');
    if (str == null) return null;
    return DateTime.tryParse(str);
  }

  Future<void> setLockoutUntil(String userId, DateTime? until) async {
    final key = '${_kLockoutUntil}_$userId';
    if (until == null) {
      await _prefs.remove(key);
    } else {
      await _prefs.setString(key, until.toIso8601String());
    }
  }
}
