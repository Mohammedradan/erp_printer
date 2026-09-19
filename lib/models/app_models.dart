import 'dart:convert';

/// إعدادات النظام الافتراضية
class AppSettings {
  String sheetSize;
  String unitSize;
  double defaultPlatePrice;
  double defaultProfitMarginPct;
  double workHoursPerDay;
  String currency;
  double taxPct;
  String companyName;
  String companyPhone;
  String companyAddress;
  String taxNumber;
  String quotationNotes;

  AppSettings({
    this.sheetSize = '100x70',
    this.unitSize = '50x35',
    this.defaultPlatePrice = 1250.0,
    this.defaultProfitMarginPct = 30.0,
    this.workHoursPerDay = 8.0,
    this.currency = 'ريال يمني',
    this.taxPct = 0.0,
    this.companyName = 'مطبعة التميز الحديثة',
    this.companyPhone = '+967 770 000 000',
    this.companyAddress = 'صنعاء - الجمهورية اليمنية',
    this.taxNumber = '300012345600003',
    this.quotationNotes = 'الأسعار سارية لمدة 15 يوماً من تاريخ إصدار العرض. يتم البدء في التنفيذ بعد اعتماد البروفة وسداد الدفعة المقدمة.',
  });

  Map<String, dynamic> toJson() => {
        'sheetSize': sheetSize,
        'unitSize': unitSize,
        'defaultPlatePrice': defaultPlatePrice,
        'defaultProfitMarginPct': defaultProfitMarginPct,
        'workHoursPerDay': workHoursPerDay,
        'currency': currency,
        'taxPct': taxPct,
        'companyName': companyName,
        'companyPhone': companyPhone,
        'companyAddress': companyAddress,
        'taxNumber': taxNumber,
        'quotationNotes': quotationNotes,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        sheetSize: json['sheetSize'] ?? '100x70',
        unitSize: json['unitSize'] ?? '50x35',
        defaultPlatePrice: (json['defaultPlatePrice'] ?? 1250).toDouble(),
        defaultProfitMarginPct: (json['defaultProfitMarginPct'] ?? 30).toDouble(),
        workHoursPerDay: (json['workHoursPerDay'] ?? 8).toDouble(),
        currency: json['currency'] ?? 'ريال يمني',
        taxPct: (json['taxPct'] ?? 0).toDouble(),
        companyName: json['companyName'] ?? 'مطبعة التميز الحديثة',
        companyPhone: json['companyPhone'] ?? '+967 770 000 000',
        companyAddress: json['companyAddress'] ?? 'صنعاء - الجمهورية اليمنية',
        taxNumber: json['taxNumber'] ?? '300012345600003',
        quotationNotes: json['quotationNotes'] ??
            'الأسعار سارية لمدة 15 يوماً من تاريخ إصدار العرض. يتم البدء في التنفيذ بعد اعتماد البروفة وسداد الدفعة المقدمة.',
      );
}

/// صنف ورق (قاعدة_الورق)
class PaperItem {
  String id;
  String category; // أوفست، كوشيه، بريستول، دوبلكس، كرافت، ورق مكربن، NCR
  String paperType; // أبيض، لامع، مطفي، 250، إلخ
  int gsm; // الجرام: 70, 80, 100, 115, 150, 300, 55...
  String sheetSize; // 100x70
  int sheetsPerUnit; // 4 ملازم 50x35
  double sheetPrice; // سعر الفرخ
  int reorderLevel; // حد إعادة الطلب
  double balance; // الرصيد الحالي بالأفرخ
  String? supplier; // المورد
  bool isActive;

  PaperItem({
    required this.id,
    required this.category,
    required this.paperType,
    required this.gsm,
    this.sheetSize = '100x70',
    this.sheetsPerUnit = 4,
    this.sheetPrice = 0.0,
    this.reorderLevel = 200,
    this.balance = 0.0,
    this.supplier,
    this.isActive = true,
  });

  String get displayName => '$category $paperType ($gsm جم)';
  String get code => '$category-$paperType-$gsm';
  bool get isUnderReorder => balance <= reorderLevel;
  double get totalValue => balance * sheetPrice;

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'paperType': paperType,
        'gsm': gsm,
        'sheetSize': sheetSize,
        'sheetsPerUnit': sheetsPerUnit,
        'sheetPrice': sheetPrice,
        'reorderLevel': reorderLevel,
        'balance': balance,
        'supplier': supplier,
        'isActive': isActive,
      };

  factory PaperItem.fromJson(Map<String, dynamic> json) => PaperItem(
        id: json['id'],
        category: json['category'],
        paperType: json['paperType'],
        gsm: json['gsm'] ?? 70,
        sheetSize: json['sheetSize'] ?? '100x70',
        sheetsPerUnit: json['sheetsPerUnit'] ?? 4,
        sheetPrice: (json['sheetPrice'] ?? 0).toDouble(),
        reorderLevel: json['reorderLevel'] ?? 200,
        balance: (json['balance'] ?? 0).toDouble(),
        supplier: json['supplier'],
        isActive: json['isActive'] ?? true,
      );
}

/// ماكينة الطباعة (الماكينات)
class MachineItem {
  String id;
  String name; // أوفست 50x35 / Epson / Sharp
  String kind; // Offset / Digital / Copier
  double wastePct; // الهالك %
  double hourlyCost; // تكلفة التشغيل/ساعة
  int speedPerHour; // السرعة فرخ/ساعة
  String status; // نشطة / موقوفة

  MachineItem({
    required this.id,
    required this.name,
    required this.kind,
    this.wastePct = 5.0,
    this.hourlyCost = 5000.0,
    this.speedPerHour = 5000,
    this.status = 'نشطة',
  });

  bool get isActive => status == 'نشطة';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kind': kind,
        'wastePct': wastePct,
        'hourlyCost': hourlyCost,
        'speedPerHour': speedPerHour,
        'status': status,
      };

  factory MachineItem.fromJson(Map<String, dynamic> json) => MachineItem(
        id: json['id'],
        name: json['name'],
        kind: json['kind'],
        wastePct: (json['wastePct'] ?? 5).toDouble(),
        hourlyCost: (json['hourlyCost'] ?? 5000).toDouble(),
        speedPerHour: json['speedPerHour'] ?? 5000,
        status: json['status'] ?? 'نشطة',
      );
}

/// قالب المنتج (المنتجات)
class ProductTemplate {
  String id;
  String name; // كتاب A5 / مجلة A4 / فاتورة NCR / سند قبض NCR
  String category; // كتب / دفاتر
  int? defaultPages;
  int? defaultNcrCopies; // عدد النسخ NCR
  int? defaultSheetsPerBook; // أوراق/دفتر
  int? defaultBooks;
  String binding; // حراري / دبوس
  int pagesPerSheet; // صفحات/فرخ 50x35 (8 للكتاب، 4 للمجلة والدفاتر)
  String defaultMachine;
  String defaultPaperCategory;
  String defaultPaperType;

  ProductTemplate({
    required this.id,
    required this.name,
    required this.category,
    this.defaultPages,
    this.defaultNcrCopies,
    this.defaultSheetsPerBook,
    this.defaultBooks,
    this.binding = 'دبوس',
    this.pagesPerSheet = 4,
    this.defaultMachine = 'أوفست 50x35',
    this.defaultPaperCategory = 'أوفست',
    this.defaultPaperType = 'أبيض',
  });

  bool get isNcr => category == 'دفاتر' || name.contains('NCR');

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'defaultPages': defaultPages,
        'defaultNcrCopies': defaultNcrCopies,
        'defaultSheetsPerBook': defaultSheetsPerBook,
        'defaultBooks': defaultBooks,
        'binding': binding,
        'pagesPerSheet': pagesPerSheet,
        'defaultMachine': defaultMachine,
        'defaultPaperCategory': defaultPaperCategory,
        'defaultPaperType': defaultPaperType,
      };

  factory ProductTemplate.fromJson(Map<String, dynamic> json) => ProductTemplate(
        id: json['id'],
        name: json['name'],
        category: json['category'],
        defaultPages: json['defaultPages'],
        defaultNcrCopies: json['defaultNcrCopies'],
        defaultSheetsPerBook: json['defaultSheetsPerBook'],
        defaultBooks: json['defaultBooks'],
        binding: json['binding'] ?? 'دبوس',
        pagesPerSheet: json['pagesPerSheet'] ?? 4,
        defaultMachine: json['defaultMachine'] ?? 'أوفست 50x35',
        defaultPaperCategory: json['defaultPaperCategory'] ?? 'أوفست',
        defaultPaperType: json['defaultPaperType'] ?? 'أبيض',
      );
}

/// خدمة تشطيب (التشطيبات)
class FinishingItem {
  String id;
  String name; // قص، طي، تدبيس، ترقيم، سلوفان مطفي، سلوفان لامع، UV، تذهيب، تكسير، تخريم، تجليد حراري، تجليد سلك
  double price; // السعر
  String unit; // للعملية / للألف / للقطعة

  FinishingItem({
    required this.id,
    required this.name,
    this.price = 0.0,
    this.unit = 'للعملية',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'unit': unit,
      };

  factory FinishingItem.fromJson(Map<String, dynamic> json) => FinishingItem(
        id: json['id'],
        name: json['name'],
        price: (json['price'] ?? 0).toDouble(),
        unit: json['unit'] ?? 'للعملية',
      );
}

/// الحبر ومخزونه (الأحبار)
class InkItem {
  String id;
  String name; // أسود، سماوي، أرجواني، أصفر
  String colorCode; // K, C, M, Y, Black
  String kind; // Offset / Digital
  double unitPrice;
  double balance; // بالكيلو أو العلبة
  double reorderLevel;
  String? supplier;

  InkItem({
    required this.id,
    required this.name,
    required this.colorCode,
    required this.kind,
    this.unitPrice = 0.0,
    this.balance = 0.0,
    this.reorderLevel = 2.0,
    this.supplier,
  });

  bool get isUnderReorder => balance <= reorderLevel;
  double get totalValue => balance * unitPrice;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorCode': colorCode,
        'kind': kind,
        'unitPrice': unitPrice,
        'balance': balance,
        'reorderLevel': reorderLevel,
        'supplier': supplier,
      };

  factory InkItem.fromJson(Map<String, dynamic> json) => InkItem(
        id: json['id'],
        name: json['name'],
        colorCode: json['colorCode'],
        kind: json['kind'],
        unitPrice: (json['unitPrice'] ?? 0).toDouble(),
        balance: (json['balance'] ?? 0).toDouble(),
        reorderLevel: (json['reorderLevel'] ?? 2).toDouble(),
        supplier: json['supplier'],
      );
}

/// حركة الحبر
class InkMove {
  String id;
  String number;
  DateTime date;
  String moveType; // دخول / خروج / تسوية
  String inkId;
  String inkName;
  double qty;
  double unitPrice;
  double totalValue;
  String? reference;
  String? notes;

  InkMove({
    required this.id,
    required this.number,
    required this.date,
    required this.moveType,
    required this.inkId,
    required this.inkName,
    required this.qty,
    required this.unitPrice,
    required this.totalValue,
    this.reference,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'date': date.toIso8601String(),
        'moveType': moveType,
        'inkId': inkId,
        'inkName': inkName,
        'qty': qty,
        'unitPrice': unitPrice,
        'totalValue': totalValue,
        'reference': reference,
        'notes': notes,
      };

  factory InkMove.fromJson(Map<String, dynamic> json) => InkMove(
        id: json['id'],
        number: json['number'],
        date: DateTime.parse(json['date']),
        moveType: json['moveType'],
        inkId: json['inkId'],
        inkName: json['inkName'],
        qty: (json['qty'] ?? 0).toDouble(),
        unitPrice: (json['unitPrice'] ?? 0).toDouble(),
        totalValue: (json['totalValue'] ?? 0).toDouble(),
        reference: json['reference'],
        notes: json['notes'],
      );
}

/// حركة مخزون الورق (حركات_المخزون)
class StockMove {
  String id;
  String number; // SM-0001
  DateTime date;
  String moveType; // دخول / خروج / تسوية
  String paperId;
  String paperCategory;
  String paperType;
  int gsm;
  double qtySheets; // الكمية بالفرخ
  double unitPrice;
  double totalValue;
  String? reference; // رقم أمر الإنتاج أو فاتورة المشتريات
  /// معرّف الحركة الأصلية عند إنشاء قيد عكسي؛ يبقى الأصل محفوظاً للتدقيق.
  String? reversalOfId;
  String? supplier;
  String? notes;

  StockMove({
    required this.id,
    required this.number,
    required this.date,
    required this.moveType,
    required this.paperId,
    required this.paperCategory,
    required this.paperType,
    required this.gsm,
    required this.qtySheets,
    this.unitPrice = 0.0,
    required this.totalValue,
    this.reference,
    this.reversalOfId,
    this.supplier,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'date': date.toIso8601String(),
        'moveType': moveType,
        'paperId': paperId,
        'paperCategory': paperCategory,
        'paperType': paperType,
        'gsm': gsm,
        'qtySheets': qtySheets,
        'unitPrice': unitPrice,
        'totalValue': totalValue,
        'reference': reference,
        'reversalOfId': reversalOfId,
        'supplier': supplier,
        'notes': notes,
      };

  factory StockMove.fromJson(Map<String, dynamic> json) => StockMove(
        id: json['id'],
        number: json['number'],
        date: DateTime.parse(json['date']),
        moveType: json['moveType'],
        paperId: json['paperId'],
        paperCategory: json['paperCategory'],
        paperType: json['paperType'],
        gsm: json['gsm'] ?? 70,
        qtySheets: (json['qtySheets'] ?? 0).toDouble(),
        unitPrice: (json['unitPrice'] ?? 0).toDouble(),
        totalValue: (json['totalValue'] ?? 0).toDouble(),
        reference: json['reference'],
        reversalOfId: json['reversalOfId'],
        supplier: json['supplier'],
        notes: json['notes'],
      );
}

/// العميل (العملاء)
class Customer {
  String id;
  String code; // C-0001
  String name;
  String? phone;
  String? address;
  double openingBalance; // الرصيد الافتتاحي
  double totalSales; // إجمالي المبيعات
  double paid; // إجمالي المدفوع

  Customer({
    required this.id,
    required this.code,
    required this.name,
    this.phone,
    this.address,
    this.openingBalance = 0.0,
    this.totalSales = 0.0,
    this.paid = 0.0,
  });

  /// الرصيد المستحق على العميل (الذمة) = الافتتاحي + المبيعات - المدفوع
  double get currentBalance => openingBalance + totalSales - paid;

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'phone': phone,
        'address': address,
        'openingBalance': openingBalance,
        'totalSales': totalSales,
        'paid': paid,
      };

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: json['id'],
        code: json['code'],
        name: json['name'],
        phone: json['phone'],
        address: json['address'],
        openingBalance: (json['openingBalance'] ?? 0).toDouble(),
        totalSales: (json['totalSales'] ?? 0).toDouble(),
        paid: (json['paid'] ?? 0).toDouble(),
      );
}

/// قيد دفتر حساب العميل. لا يحذف الأثر المالي؛ يتم إنشاء قيد عكسي عند الإلغاء.
class CustomerLedgerEntry {
  final String id;
  final String customerId;
  final DateTime date;
  final String type; // opening_balance / opening_adjustment / sale / sale_reversal / payment / legacy_sale / legacy_payment
  final double debit;
  final double credit;
  final String? referenceId;
  final String? referenceNumber;
  final String? notes;

  CustomerLedgerEntry({
    required this.id,
    required this.customerId,
    required this.date,
    required this.type,
    this.debit = 0.0,
    this.credit = 0.0,
    this.referenceId,
    this.referenceNumber,
    this.notes,
  });

  double get balanceEffect => debit - credit;

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerId': customerId,
        'date': date.toIso8601String(),
        'type': type,
        'debit': debit,
        'credit': credit,
        'referenceId': referenceId,
        'referenceNumber': referenceNumber,
        'notes': notes,
      };

  factory CustomerLedgerEntry.fromJson(Map<String, dynamic> json) =>
      CustomerLedgerEntry(
        id: json['id'],
        customerId: json['customerId'],
        date: DateTime.parse(json['date']),
        type: json['type'],
        debit: (json['debit'] ?? 0).toDouble(),
        credit: (json['credit'] ?? 0).toDouble(),
        referenceId: json['referenceId'],
        referenceNumber: json['referenceNumber'],
        notes: json['notes'],
      );
}

/// سند قبض / دفع (المدفوعات)
class PaymentRecord {
  String id;
  String number; // PAY-0001
  DateTime date;
  String customerId;
  String customerName;
  double amount;
  String paymentMethod; // نقدي / تحويل بنكي / شيك / آجل
  String? reference;
  String? notes;

  PaymentRecord({
    required this.id,
    required this.number,
    required this.date,
    required this.customerId,
    required this.customerName,
    required this.amount,
    this.paymentMethod = 'نقدي',
    this.reference,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'date': date.toIso8601String(),
        'customerId': customerId,
        'customerName': customerName,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'reference': reference,
        'notes': notes,
      };

  factory PaymentRecord.fromJson(Map<String, dynamic> json) => PaymentRecord(
        id: json['id'],
        number: json['number'],
        date: DateTime.parse(json['date']),
        customerId: json['customerId'],
        customerName: json['customerName'],
        amount: (json['amount'] ?? 0).toDouble(),
        paymentMethod: json['paymentMethod'] ?? 'نقدي',
        reference: json['reference'],
        notes: json['notes'],
      );
}

/// نوع قالب التسعير
enum ProductPricingType {
  book,
  ncr,
  card,
  custom,
}

/// بند خطوة حسابية في محرك التسعير
class PricingStepDetail {
  final String stepNumber;
  final String title;
  final String description;
  final double cost;
  final Map<String, String> metrics;

  PricingStepDetail({
    required this.stepNumber,
    required this.title,
    required this.description,
    this.cost = 0.0,
    this.metrics = const {},
  });

  Map<String, dynamic> toJson() => {
        'stepNumber': stepNumber,
        'title': title,
        'description': description,
        'cost': cost,
        'metrics': metrics,
      };

  factory PricingStepDetail.fromJson(Map<String, dynamic> json) => PricingStepDetail(
        stepNumber: json['stepNumber'] ?? '',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        cost: (json['cost'] ?? 0).toDouble(),
        metrics: Map<String, String>.from(json['metrics'] ?? {}),
      );
}

/// مادة مخططة في نتيجة التسعير. الكمية تكون بوحدة صنف المخزون (فرخ للورق).
class PricingMaterialRequirement {
  final String materialId;
  final String materialName;
  final String materialType;
  final double quantity;
  final String unit;
  final double unitCost;

  PricingMaterialRequirement({
    required this.materialId,
    required this.materialName,
    this.materialType = 'paper',
    required this.quantity,
    this.unit = 'فرخ',
    this.unitCost = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'materialId': materialId,
        'materialName': materialName,
        'materialType': materialType,
        'quantity': quantity,
        'unit': unit,
        'unitCost': unitCost,
      };

  factory PricingMaterialRequirement.fromJson(Map<String, dynamic> json) =>
      PricingMaterialRequirement(
        materialId: json['materialId'] ?? '',
        materialName: json['materialName'] ?? '',
        materialType: json['materialType'] ?? 'paper',
        quantity: (json['quantity'] ?? 0).toDouble(),
        unit: json['unit'] ?? 'فرخ',
        unitCost: (json['unitCost'] ?? 0).toDouble(),
      );
}

/// نتيجة وتفاصيل محرك التسعير (محرك_التسعير - 26 عمود + قوالب المنتجات المتخصصة)
class PricingResult {
  String productName;
  int qty; // الكمية المطلوبة
  int pages; // عدد الصفحات
  int ncrCopies; // عدد نسخ NCR
  int sheetsPerBook; // أوراق/دفتر
  int booksCount; // عدد الدفاتر
  int colorsCount; // عدد الألوان
  int platesCount; // عدد البليتات
  double plateCost; // تكلفة البليت
  double profitMarginPct; // هامش الربح %

  String paperId;
  String paperCategory;
  String paperType;
  int paperGsm;
  double paperSheetPrice;

  String machineId;
  String machineName;
  double wastePct;
  double hourlyCost;
  int speedPerHour;

  List<String> selectedFinishingIds;
  List<String> selectedFinishingNames;

  // الحسابات الناتجة (تطابق أعمدة الإكسل حرفياً)
  double sheetsPerUnit; // الملازم/وحدة (العمود O)
  double totalSheets; // إجمالي الأوراق (العمود P)
  double sheetsWithWaste; // الأوراق مع الهالك (المستخدمة في الأوامر)
  double paperCost; // تكلفة الورق (العمود R)
  double runHours; // ساعات التشغيل (العمود S)
  double machineCost; // تكلفة الماكينة (العمود T)
  double finishingCost; // تكلفة التشطيب (العمود V)
  double zincCost; // تكلفة الزنك / البليتات (العمود W)
  double lineTotalCost; // التكلفة الكلية (العمود X)
  double unitPrice; // سعر الوحدة (العمود Y)
  double lineAmount; // قيمة البيع (العمود Z)
  double profit; // صافي الربح (العمود O في العروض)

  // تفاصيل إضافية خاصة بالقوالب المتخصصة (كتاب، NCR، كرت، منتجات أخرى)
  String templateType; // book, ncr, card, custom
  double taxPct;
  double taxAmount;
  double grandTotalAmount;
  List<PricingStepDetail> stepDetails;
  Map<String, dynamic> extraMetrics;
  List<PricingMaterialRequirement> materialRequirements;

  PricingResult({
    required this.productName,
    required this.qty,
    required this.pages,
    required this.ncrCopies,
    required this.sheetsPerBook,
    required this.booksCount,
    required this.colorsCount,
    required this.platesCount,
    required this.plateCost,
    required this.profitMarginPct,
    required this.paperId,
    required this.paperCategory,
    required this.paperType,
    required this.paperGsm,
    required this.paperSheetPrice,
    required this.machineId,
    required this.machineName,
    required this.wastePct,
    required this.hourlyCost,
    required this.speedPerHour,
    required this.selectedFinishingIds,
    required this.selectedFinishingNames,
    required this.sheetsPerUnit,
    required this.totalSheets,
    required this.sheetsWithWaste,
    required this.paperCost,
    required this.runHours,
    required this.machineCost,
    required this.finishingCost,
    required this.zincCost,
    required this.lineTotalCost,
    required this.unitPrice,
    required this.lineAmount,
    required this.profit,
    this.templateType = 'custom',
    this.taxPct = 0.0,
    this.taxAmount = 0.0,
    this.grandTotalAmount = 0.0,
    this.stepDetails = const [],
    this.extraMetrics = const {},
    this.materialRequirements = const [],
  });

  Map<String, dynamic> toJson() => {
        'productName': productName,
        'qty': qty,
        'pages': pages,
        'ncrCopies': ncrCopies,
        'sheetsPerBook': sheetsPerBook,
        'booksCount': booksCount,
        'colorsCount': colorsCount,
        'platesCount': platesCount,
        'plateCost': plateCost,
        'profitMarginPct': profitMarginPct,
        'paperId': paperId,
        'paperCategory': paperCategory,
        'paperType': paperType,
        'paperGsm': paperGsm,
        'paperSheetPrice': paperSheetPrice,
        'machineId': machineId,
        'machineName': machineName,
        'wastePct': wastePct,
        'hourlyCost': hourlyCost,
        'speedPerHour': speedPerHour,
        'selectedFinishingIds': selectedFinishingIds,
        'selectedFinishingNames': selectedFinishingNames,
        'sheetsPerUnit': sheetsPerUnit,
        'totalSheets': totalSheets,
        'sheetsWithWaste': sheetsWithWaste,
        'paperCost': paperCost,
        'runHours': runHours,
        'machineCost': machineCost,
        'finishingCost': finishingCost,
        'zincCost': zincCost,
        'lineTotalCost': lineTotalCost,
        'unitPrice': unitPrice,
        'lineAmount': lineAmount,
        'profit': profit,
        'templateType': templateType,
        'taxPct': taxPct,
        'taxAmount': taxAmount,
        'grandTotalAmount': grandTotalAmount,
        'stepDetails': stepDetails.map((s) => s.toJson()).toList(),
        'extraMetrics': extraMetrics,
        'materialRequirements': materialRequirements.map((m) => m.toJson()).toList(),
      };

  factory PricingResult.fromJson(Map<String, dynamic> json) => PricingResult(
        productName: json['productName'],
        qty: json['qty'] ?? 1,
        pages: json['pages'] ?? 0,
        ncrCopies: json['ncrCopies'] ?? 0,
        sheetsPerBook: json['sheetsPerBook'] ?? 0,
        booksCount: json['booksCount'] ?? 0,
        colorsCount: json['colorsCount'] ?? 1,
        platesCount: json['platesCount'] ?? 1,
        plateCost: (json['plateCost'] ?? 1250).toDouble(),
        profitMarginPct: (json['profitMarginPct'] ?? 30).toDouble(),
        paperId: json['paperId'],
        paperCategory: json['paperCategory'],
        paperType: json['paperType'],
        paperGsm: json['paperGsm'] ?? 70,
        paperSheetPrice: (json['paperSheetPrice'] ?? 0).toDouble(),
        machineId: json['machineId'],
        machineName: json['machineName'],
        wastePct: (json['wastePct'] ?? 5).toDouble(),
        hourlyCost: (json['hourlyCost'] ?? 5000).toDouble(),
        speedPerHour: json['speedPerHour'] ?? 5000,
        selectedFinishingIds: List<String>.from(json['selectedFinishingIds'] ?? []),
        selectedFinishingNames: List<String>.from(json['selectedFinishingNames'] ?? []),
        sheetsPerUnit: (json['sheetsPerUnit'] ?? 0).toDouble(),
        totalSheets: (json['totalSheets'] ?? 0).toDouble(),
        sheetsWithWaste: (json['sheetsWithWaste'] ?? 0).toDouble(),
        paperCost: (json['paperCost'] ?? 0).toDouble(),
        runHours: (json['runHours'] ?? 0).toDouble(),
        machineCost: (json['machineCost'] ?? 0).toDouble(),
        finishingCost: (json['finishingCost'] ?? 0).toDouble(),
        zincCost: (json['zincCost'] ?? 0).toDouble(),
        lineTotalCost: (json['lineTotalCost'] ?? 0).toDouble(),
        unitPrice: (json['unitPrice'] ?? 0).toDouble(),
        lineAmount: (json['lineAmount'] ?? 0).toDouble(),
        profit: (json['profit'] ?? 0).toDouble(),
        templateType: json['templateType'] ?? 'custom',
        taxPct: (json['taxPct'] ?? 0).toDouble(),
        taxAmount: (json['taxAmount'] ?? 0).toDouble(),
        grandTotalAmount: (json['grandTotalAmount'] ?? json['lineAmount'] ?? 0).toDouble(),
        stepDetails: json['stepDetails'] != null
            ? (json['stepDetails'] as List)
                .map((x) => PricingStepDetail.fromJson(x))
                .toList()
            : [],
        extraMetrics: Map<String, dynamic>.from(json['extraMetrics'] ?? {}),
        materialRequirements: json['materialRequirements'] != null
            ? (json['materialRequirements'] as List)
                .map((x) => PricingMaterialRequirement.fromJson(Map<String, dynamic>.from(x)))
                .toList()
            : [],
      );
}

/// عرض سعر (عروض_الأسعار)
class Quotation {
  String id;
  String number; // Q-2026-0001
  DateTime date;
  String customerId;
  String customerCode;
  String customerName;
  String product;
  int qty;
  int pages;
  int ncrCopies;
  String paper; // وصف الورق
  String machine;
  double unitPrice;
  String status; // مسودة / معتمد / مرفوض / ملغي
  double totalCost;
  double quoteAmount; // قيمة العرض
  double profit;
  String? notes;
  PricingResult? pricingDetails;

  Quotation({
    required this.id,
    required this.number,
    required this.date,
    required this.customerId,
    required this.customerCode,
    required this.customerName,
    required this.product,
    required this.qty,
    required this.pages,
    this.ncrCopies = 0,
    required this.paper,
    required this.machine,
    required this.unitPrice,
    this.status = 'مسودة',
    required this.totalCost,
    required this.quoteAmount,
    required this.profit,
    this.notes,
    this.pricingDetails,
  });

  bool get isApproved => status == 'معتمد';

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'date': date.toIso8601String(),
        'customerId': customerId,
        'customerCode': customerCode,
        'customerName': customerName,
        'product': product,
        'qty': qty,
        'pages': pages,
        'ncrCopies': ncrCopies,
        'paper': paper,
        'machine': machine,
        'unitPrice': unitPrice,
        'status': status,
        'totalCost': totalCost,
        'quoteAmount': quoteAmount,
        'profit': profit,
        'notes': notes,
        'pricingDetails': pricingDetails?.toJson(),
      };

  factory Quotation.fromJson(Map<String, dynamic> json) => Quotation(
        id: json['id'],
        number: json['number'],
        date: DateTime.parse(json['date']),
        customerId: json['customerId'],
        customerCode: json['customerCode'] ?? '',
        customerName: json['customerName'],
        product: json['product'],
        qty: json['qty'] ?? 1,
        pages: json['pages'] ?? 0,
        ncrCopies: json['ncrCopies'] ?? 0,
        paper: json['paper'],
        machine: json['machine'],
        unitPrice: (json['unitPrice'] ?? 0).toDouble(),
        status: json['status'] ?? 'مسودة',
        totalCost: (json['totalCost'] ?? 0).toDouble(),
        quoteAmount: (json['quoteAmount'] ?? 0).toDouble(),
        profit: (json['profit'] ?? 0).toDouble(),
        notes: json['notes'],
        pricingDetails: json['pricingDetails'] != null
            ? PricingResult.fromJson(json['pricingDetails'])
            : null,
      );
}

/// مادة لازمة لأمر إنتاج. تستخدم للصرف الفعلي من كل صنف على حدة.
class ProductionMaterialRequirement {
  String id;
  String materialId;
  String materialName;
  String materialType;
  double quantityRequired;
  double quantityIssued;
  String unit;
  double unitCostAtApproval;

  ProductionMaterialRequirement({
    required this.id,
    required this.materialId,
    required this.materialName,
    this.materialType = 'paper',
    required this.quantityRequired,
    this.quantityIssued = 0.0,
    this.unit = 'فرخ',
    this.unitCostAtApproval = 0.0,
  });

  bool get isFullyIssued => quantityIssued >= quantityRequired;
  double get remainingQuantity =>
      (quantityRequired - quantityIssued).clamp(0.0, double.infinity).toDouble();

  Map<String, dynamic> toJson() => {
        'id': id,
        'materialId': materialId,
        'materialName': materialName,
        'materialType': materialType,
        'quantityRequired': quantityRequired,
        'quantityIssued': quantityIssued,
        'unit': unit,
        'unitCostAtApproval': unitCostAtApproval,
      };

  factory ProductionMaterialRequirement.fromJson(Map<String, dynamic> json) =>
      ProductionMaterialRequirement(
        id: json['id'] ?? '',
        materialId: json['materialId'] ?? '',
        materialName: json['materialName'] ?? '',
        materialType: json['materialType'] ?? 'paper',
        quantityRequired: (json['quantityRequired'] ?? 0).toDouble(),
        quantityIssued: (json['quantityIssued'] ?? 0).toDouble(),
        unit: json['unit'] ?? 'فرخ',
        unitCostAtApproval: (json['unitCostAtApproval'] ?? 0).toDouble(),
      );
}

/// أمر إنتاج (أوامر_الإنتاج)
class ProductionOrder {
  String id;
  String number; // PO-2026-0001
  DateTime date;
  String? quotationId;
  String? quotationNumber;
  String customerId;
  String customerName;
  String product;
  int qty;
  String machine;
  String paperName;
  String paperId;
  double sheetsRequired; // الأوراق المطلوبة
  double sheetsWithWaste; // الأوراق مع الهالك
  double runHours; // ساعات التشغيل
  double cost; // التكلفة
  String status; // مسودة / معتمد / قيد الإنتاج / مكتمل / ملغي
  DateTime? dueDate; // موعد التسليم
  String? notes;
  bool isPaperDeducted; // توافق مع الأوامر القديمة؛ يعكس صرف جميع المواد في الأوامر الجديدة
  List<ProductionMaterialRequirement> materialRequirements;

  ProductionOrder({
    required this.id,
    required this.number,
    required this.date,
    this.quotationId,
    this.quotationNumber,
    required this.customerId,
    required this.customerName,
    required this.product,
    required this.qty,
    required this.machine,
    required this.paperName,
    required this.paperId,
    required this.sheetsRequired,
    required this.sheetsWithWaste,
    required this.runHours,
    required this.cost,
    this.status = 'معتمد',
    this.dueDate,
    this.notes,
    this.isPaperDeducted = false,
    this.materialRequirements = const [],
  });

  bool get isCompleted => status == 'مكتمل';
  bool get isInProgress => status == 'قيد الإنتاج';
  bool get areAllMaterialsIssued => materialRequirements.isEmpty
      ? isPaperDeducted
      : materialRequirements.every((material) => material.isFullyIssued);
  int get issuedMaterialsCount => materialRequirements.where((material) => material.quantityIssued > 0).length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'date': date.toIso8601String(),
        'quotationId': quotationId,
        'quotationNumber': quotationNumber,
        'customerId': customerId,
        'customerName': customerName,
        'product': product,
        'qty': qty,
        'machine': machine,
        'paperName': paperName,
        'paperId': paperId,
        'sheetsRequired': sheetsRequired,
        'sheetsWithWaste': sheetsWithWaste,
        'runHours': runHours,
        'cost': cost,
        'status': status,
        'dueDate': dueDate?.toIso8601String(),
        'notes': notes,
        'isPaperDeducted': isPaperDeducted,
        'materialRequirements': materialRequirements.map((material) => material.toJson()).toList(),
      };

  factory ProductionOrder.fromJson(Map<String, dynamic> json) => ProductionOrder(
        id: json['id'],
        number: json['number'],
        date: DateTime.parse(json['date']),
        quotationId: json['quotationId'],
        quotationNumber: json['quotationNumber'],
        customerId: json['customerId'],
        customerName: json['customerName'],
        product: json['product'],
        qty: json['qty'] ?? 1,
        machine: json['machine'],
        paperName: json['paperName'],
        paperId: json['paperId'] ?? '',
        sheetsRequired: (json['sheetsRequired'] ?? 0).toDouble(),
        sheetsWithWaste: (json['sheetsWithWaste'] ?? 0).toDouble(),
        runHours: (json['runHours'] ?? 0).toDouble(),
        cost: (json['cost'] ?? 0).toDouble(),
        status: json['status'] ?? 'معتمد',
        dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
        notes: json['notes'],
        isPaperDeducted: json['isPaperDeducted'] ?? false,
        materialRequirements: json['materialRequirements'] != null
            ? (json['materialRequirements'] as List)
                .map((x) => ProductionMaterialRequirement.fromJson(Map<String, dynamic>.from(x)))
                .toList()
            : [],
      );
}

// ─────────────────────────────────────────────────────────
// نظام المستخدمين والصلاحيات
// ─────────────────────────────────────────────────────────

/// دور المستخدم
enum UserRole { admin, employee }

extension UserRoleExtension on UserRole {
  String get label {
    switch (this) {
      case UserRole.admin:
        return 'مدير';
      case UserRole.employee:
        return 'موظف';
    }
  }

  String get toJson => name;

  static UserRole fromJson(String? value) {
    switch (value) {
      case 'admin':
        return UserRole.admin;
      case 'employee':
        return UserRole.employee;
      default:
        return UserRole.employee;
    }
  }
}

/// حساب المستخدم
class UserAccount {
  String id;
  String username;       // اسم الدخول
  String displayName;    // الاسم الكامل
  String pinHash;        // PIN مشفّر SHA-256
  UserRole role;
  bool isActive;
  DateTime createdAt;
  String avatarEmoji;    // رمز تعبيري للتمييز

  UserAccount({
    required this.id,
    required this.username,
    required this.displayName,
    required this.pinHash,
    this.role = UserRole.employee,
    this.isActive = true,
    required this.createdAt,
    this.avatarEmoji = '👤',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'displayName': displayName,
        'pinHash': pinHash,
        'role': role.toJson,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'avatarEmoji': avatarEmoji,
      };

  factory UserAccount.fromJson(Map<String, dynamic> json) => UserAccount(
        id: json['id'],
        username: json['username'],
        displayName: json['displayName'],
        pinHash: json['pinHash'],
        role: UserRoleExtension.fromJson(json['role']),
        isActive: json['isActive'] ?? true,
        createdAt: DateTime.parse(json['createdAt']),
        avatarEmoji: json['avatarEmoji'] ?? '👤',
      );

  UserAccount copyWith({
    String? displayName,
    String? pinHash,
    UserRole? role,
    bool? isActive,
    String? avatarEmoji,
  }) =>
      UserAccount(
        id: id,
        username: username,
        displayName: displayName ?? this.displayName,
        pinHash: pinHash ?? this.pinHash,
        role: role ?? this.role,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
        avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      );
}

