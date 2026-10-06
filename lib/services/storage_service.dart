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
  static const String _kCustomerLedger = 'erp_customer_ledger';
  static const String _kInitialized = 'erp_initialized_v1';
  static const String _kUsers = 'erp_users';
  static const String _kActiveUserId = 'erp_active_user_id';
  static const String _kLoginAttempts = 'erp_login_attempts';
  static const String _kLockoutUntil = 'erp_lockout_until';
  static const String _kAuditLog = 'erp_audit_log';
  static const String _kAuditActor = 'erp_audit_actor';
  static const String _kLastImportSafety = 'erp_last_import_safety_backup';
  static const String _kFirstRunMode = 'erp_first_run_mode';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  /// تهيئة التخزين.
  ///
  /// [firstRunMode] يُستخدم في أول تشغيل فقط:
  /// - `demo`: بيانات الإكسل المرجعية + سجلات تجارية وهمية للتجربة.
  /// - `clean`: بيانات الإكسل المرجعية (ورق/ماكينات/منتجات/أحبار) بلا عملاء
  ///   ولا عروض ولا أوامر إنتاج ولا مدفوعات وهمية.
  /// القيمة تُسجَّل في [_kFirstRunMode] لتظهر في الإعدادات ولتُضمَّن في النسخة.
  static Future<StorageService> init({String? firstRunMode}) async {
    final prefs = await SharedPreferences.getInstance();
    final service = StorageService(prefs);
    if (!prefs.containsKey(_kInitialized)) {
      final mode = firstRunMode ?? service.getFirstRunMode() ?? 'clean';
      await service.setFirstRunMode(mode);
      await service.seedInitialData(includeDemoRecords: mode != 'clean');
      await prefs.setBool(_kInitialized, true);
    }
    await service.ensureCustomerLedgerFromLegacy();
    return service;
  }

  /// وضع أول تشغيل المسجَّل: `demo` أو `clean` أو null إذا لم يُسجَّل بعد.
  String? getFirstRunMode() => _prefs.getString(_kFirstRunMode);

  Future<void> setFirstRunMode(String mode) =>
      _prefs.setString(_kFirstRunMode, mode);

  /// هل زُرعت بيانات تجريبية في هذه القاعدة؟ تُستخدم لتنبيه المدير.
  bool get hasDemoRecords => getFirstRunMode() != 'clean';

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

  // --- CUSTOMER LEDGER ---
  List<CustomerLedgerEntry> loadCustomerLedger() {
    final list = _prefs.getStringList(_kCustomerLedger);
    if (list == null) return [];
    return list
        .map((entry) => CustomerLedgerEntry.fromJson(jsonDecode(entry)))
        .toList();
  }

  Future<void> saveCustomerLedger(List<CustomerLedgerEntry> entries) async {
    await _prefs.setStringList(
      _kCustomerLedger,
      entries.map((entry) => jsonEncode(entry.toJson())).toList(),
    );
  }

  /// ترحيل محافظ للبيانات القديمة: يبني دفتر القيود من العروض والمدفوعات
  /// ثم يضيف قيوداً تاريخية للفرق حتى يظل رصيد العميل السابق كما هو.
  Future<void> ensureCustomerLedgerFromLegacy({bool force = false}) async {
    if (!force && _prefs.containsKey(_kCustomerLedger)) return;

    final customers = loadCustomers();
    final quotations = loadQuotations();
    final payments = loadPayments();
    final entries = <CustomerLedgerEntry>[];

    for (final customer in customers) {
      if (customer.openingBalance != 0) {
        entries.add(CustomerLedgerEntry(
          id: 'LED_OPEN_${customer.id}',
          customerId: customer.id,
          date: DateTime.now(),
          type: 'opening_balance',
          debit: customer.openingBalance > 0 ? customer.openingBalance : 0,
          credit: customer.openingBalance < 0 ? customer.openingBalance.abs() : 0,
          referenceId: customer.id,
          referenceNumber: 'OPEN-${customer.code}',
          notes: 'رصيد افتتاحي تم ترحيله من بيانات الإصدار السابق',
        ));
      }

      final customerQuotes = quotations
          .where((quote) => quote.customerId == customer.id && quote.status == 'معتمد')
          .toList();
      final quotedSales = customerQuotes.fold<double>(
        0,
        (sum, quote) => sum + quote.quoteAmount,
      );
      for (final quote in customerQuotes) {
        entries.add(CustomerLedgerEntry(
          id: 'LED_SALE_${quote.id}',
          customerId: customer.id,
          date: quote.date,
          type: 'sale',
          debit: quote.quoteAmount,
          referenceId: quote.id,
          referenceNumber: quote.number,
          notes: 'ترحيل عرض سعر معتمد',
        ));
      }
      final legacySalesDifference = customer.totalSales - quotedSales;
      if (legacySalesDifference > 0.0001) {
        entries.add(CustomerLedgerEntry(
          id: 'LED_LEGACY_SALE_${customer.id}',
          customerId: customer.id,
          date: DateTime.now(),
          type: 'legacy_sale',
          debit: legacySalesDifference,
          referenceId: customer.id,
          referenceNumber: 'LEGACY-SALES-${customer.code}',
          notes: 'رصيد مبيعات تاريخي غير مرتبط بعرض محفوظ',
        ));
      }

      final customerPayments = payments
          .where((payment) => payment.customerId == customer.id)
          .toList();
      final recordedPayments = customerPayments.fold<double>(
        0,
        (sum, payment) => sum + payment.amount,
      );
      for (final payment in customerPayments) {
        entries.add(CustomerLedgerEntry(
          id: 'LED_PAY_${payment.id}',
          customerId: customer.id,
          date: payment.date,
          type: 'payment',
          credit: payment.amount,
          referenceId: payment.id,
          referenceNumber: payment.number,
          notes: 'ترحيل سند قبض',
        ));
      }
      final legacyPaymentDifference = customer.paid - recordedPayments;
      if (legacyPaymentDifference > 0.0001) {
        entries.add(CustomerLedgerEntry(
          id: 'LED_LEGACY_PAY_${customer.id}',
          customerId: customer.id,
          date: DateTime.now(),
          type: 'legacy_payment',
          credit: legacyPaymentDifference,
          referenceId: customer.id,
          referenceNumber: 'LEGACY-PAY-${customer.code}',
          notes: 'دفعة تاريخية غير مرتبطة بسند محفوظ',
        ));
      }
    }

    await saveCustomerLedger(entries);
  }

  // ─────────────────────────────────────────────────────────
  // --- النسخ الاحتياطي ---
  // ─────────────────────────────────────────────────────────

  /// إصدار صيغة النسخة الاحتياطية الحالي.
  static const String backupVersion = '1.2';

  /// إصدارات الصيغة التي يستطيع هذا البناء قراءتها.
  static const List<String> supportedBackupVersions = ['1.0', '1.1', '1.2'];

  /// المفاتيح التي تُنقل في النسخة الاحتياطية: (حقل النسخة، مفتاح التخزين).
  static const List<List<String>> _backupKeys = [
    ['settings', _kSettings],
    ['papers', _kPapers],
    ['machines', _kMachines],
    ['products', _kProducts],
    ['finishings', _kFinishings],
    ['inks', _kInks],
    ['inkMoves', _kInkMoves],
    ['customers', _kCustomers],
    ['quotations', _kQuotations],
    ['productionOrders', _kProductionOrders],
    ['stockMoves', _kStockMoves],
    ['payments', _kPayments],
    ['customerLedger', _kCustomerLedger],
    ['users', _kUsers],
    ['auditLog', _kAuditLog],
  ];

  /// تصدير نسخة احتياطية شاملة كـ JSON نصي.
  ///
  /// تشمل المستخدمين وسجل التدقيق. التشفير مسؤولية المستدعي عبر
  /// `BackupCodec.encrypt` حتى لا تبقى كلمة المرور داخل طبقة التخزين.
  ///
  /// [includeUsers] يسمح بإخراج نسخة بلا حسابات عند الحاجة لمشاركتها مع دعم فني.
  String exportBackupJson({bool includeUsers = true}) {
    final data = <String, dynamic>{
      'version': backupVersion,
      'exportDate': DateTime.now().toIso8601String(),
      'firstRunMode': getFirstRunMode(),
    };
    for (final pair in _backupKeys) {
      final field = pair[0];
      if (field == 'users' && !includeUsers) continue;
      final key = pair[1];
      if (key == _kSettings) {
        data[field] = _prefs.getString(key);
      } else {
        data[field] = _prefs.getStringList(key);
      }
    }
    return jsonEncode(data);
  }

  /// يقرأ إصدار صيغة ملف نسخة احتياطية دون استيراده.
  static String? readBackupVersion(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map) return decoded['version']?.toString();
    } catch (_) {
      // يُترك null ليعالجه المستورد كملف غير صالح
    }
    return null;
  }

  /// يستورد نسخة احتياطية.
  ///
  /// الضوابط:
  /// 1. رفض أي إصدار صيغة غير معروف بدل استيراد ناقص صامت.
  /// 2. أخذ لقطة أمان من القاعدة الحالية قبل الكتابة، قابلة للاسترجاع
  ///    عبر [restoreSafetySnapshot] إذا تبيّن أن الملف المستورد خاطئ.
  /// 3. ترحيل محافظ لدفتر قيود العملاء عند استيراد نسخة أقدم لا تحتويه.
  Future<BackupImportResult> importBackupJson(String jsonStr) async {
    if (jsonStr.length > 50 * 1024 * 1024) {
      return BackupImportResult.failure('حجم ملف النسخة الاحتياطية يتجاوز الحد المسموح');
    }

    final Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is! Map) {
        return BackupImportResult.failure('الملف ليس نسخة احتياطية صالحة');
      }
      data = Map<String, dynamic>.from(decoded);
    } catch (_) {
      return BackupImportResult.failure('تعذر قراءة محتوى الملف (JSON تالف)');
    }

    final version = data['version']?.toString();
    if (version == null || !supportedBackupVersions.contains(version)) {
      return BackupImportResult.failure(
        'إصدار النسخة غير مدعوم: ${version ?? 'غير محدد'}. '
        'الإصدارات المقبولة: ${supportedBackupVersions.join('، ')}',
      );
    }

    final validationError = _validateBackupPayload(data, version);
    if (validationError != null) {
      return BackupImportResult.failure(validationError);
    }

    // لقطة أمان قبل أي كتابة مدمّرة.
    try {
      await _prefs.setString(_kLastImportSafety, exportBackupJson());
    } catch (_) {
      // فشل اللقطة لا يوقف الاستيراد، لكنه يُسجَّل في النتيجة
    }

    try {
      for (final pair in _backupKeys) {
        final field = pair[0];
        final key = pair[1];
        if (!data.containsKey(field)) continue;
        if (key == _kSettings) {
          final value = data[field];
          if (value == null) {
            await _prefs.remove(key);
          } else if (value is String) {
            await _prefs.setString(key, value);
          } else if (value is Map) {
            await _prefs.setString(key, jsonEncode(value));
          }
        } else {
          final raw = data[field];
          if (raw == null) {
            // null في التصدير الحالي يعني أن القائمة فارغة، لا أن نحتفظ
            // ببيانات القاعدة السابقة بصمت.
            await _prefs.setStringList(key, <String>[]);
          } else if (raw is List) {
            final serialized = raw
                .map((item) => item is String ? item : jsonEncode(item))
                .cast<String>()
                .toList();
            await _prefs.setStringList(key, serialized);
          }
        }
      }

      final mode = data['firstRunMode'];
      if (mode is String && mode.isNotEmpty) {
        await setFirstRunMode(mode);
      } else if (data.containsKey('firstRunMode') && version == backupVersion) {
        await setFirstRunMode('clean');
      }

      if (data['customerLedger'] == null) {
        await _prefs.remove(_kCustomerLedger);
        await ensureCustomerLedgerFromLegacy(force: true);
      }
    } catch (e) {
      return BackupImportResult.failure('فشل تطبيق النسخة: $e');
    }

    return BackupImportResult.success(
      restoredUsers: data['users'] is List,
      safetySnapshotTaken: _prefs.containsKey(_kLastImportSafety),
    );
  }

  /// يتحقق من بنية النسخة ومحتوى سجلاتها قبل أخذ لقطة الأمان أو الكتابة.
  String? _validateBackupPayload(Map<String, dynamic> data, String version) {
    final requiredFields = version == backupVersion
        ? _backupKeys.map((pair) => pair[0]).where((field) => field != 'users').toList()
        : const ['settings', 'papers', 'machines', 'products', 'finishings', 'inks', 'customers', 'quotations'];

    for (final field in requiredFields) {
      if (!data.containsKey(field)) {
        return 'النسخة $version ناقصة للحقل المطلوب: $field';
      }
    }

    if (version == backupVersion) {
      if (!data.containsKey('firstRunMode') ||
          !data.containsKey('exportDate') ||
          (data['firstRunMode'] != 'clean' && data['firstRunMode'] != 'demo')) {
        return 'بيانات إصدار النسخة الحالية غير مكتملة';
      }
    }

    final mode = data['firstRunMode'];
    if (mode != null && mode != 'clean' && mode != 'demo') {
      return 'وضع التهيئة في النسخة الاحتياطية غير صالح';
    }

    for (final pair in _backupKeys) {
      final field = pair[0];
      if (!data.containsKey(field)) continue; // users مستثنى اختيارياً، وحقول الإصدارات القديمة تُرحّل.
      final value = data[field];
      if (field == 'settings') {
        if (value == null) continue;
        dynamic decodedSettings = value;
        if (value is String) {
          try {
            decodedSettings = jsonDecode(value);
          } catch (_) {
            return 'إعدادات النسخة الاحتياطية تالفة';
          }
        } else if (version == backupVersion || value is! Map) {
          return 'صيغة إعدادات النسخة الاحتياطية غير صالحة';
        }
        if (decodedSettings is! Map) {
          return 'صيغة إعدادات النسخة الاحتياطية غير صالحة';
        }
        continue;
      }

      if (value == null) continue; // null يمثل قائمة فارغة في التصدير.
      if (value is! List) return 'قائمة النسخة الاحتياطية غير صالحة: $field';
      for (final item in value) {
        dynamic decodedItem = item;
        if (item is String) {
          try {
            decodedItem = jsonDecode(item);
          } catch (_) {
            return 'سجل تالف في الحقل: $field';
          }
        } else if (version == backupVersion || item is! Map) {
          return 'صيغة سجل غير صالحة في الحقل: $field';
        }
        if (decodedItem is! Map) return 'صيغة سجل غير صالحة في الحقل: $field';
      }
    }

    return null;
  }

  /// هل توجد لقطة أمان من آخر استيراد؟
  bool get hasSafetySnapshot => _prefs.containsKey(_kLastImportSafety);

  /// يعيد القاعدة إلى وضعها قبل آخر استيراد، ثم يمسح اللقطة.
  Future<bool> restoreSafetySnapshot() async {
    final snapshot = _prefs.getString(_kLastImportSafety);
    if (snapshot == null) return false;
    final result = await importBackupJson(snapshot);
    if (result.isSuccess) {
      // importBackupJson كتب لقطة جديدة؛ نعيد لقطة ما قبل الاستيراد كما هي.
      await _prefs.setString(_kLastImportSafety, snapshot);
    }
    return result.isSuccess;
  }

  // ─────────────────────────────────────────────────────────
  // --- سجل التدقيق ---
  // ─────────────────────────────────────────────────────────

  /// أقصى عدد أسطر يحتفظ بها سجل التدقيق (الأقدم يُستبعد).
  static const int auditLogCapacity = 2000;

  List<AuditLogEntry> loadAuditLog() {
    final list = _prefs.getStringList(_kAuditLog);
    if (list == null) return [];
    final entries = <AuditLogEntry>[];
    for (final raw in list) {
      try {
        entries.add(AuditLogEntry.fromJson(jsonDecode(raw)));
      } catch (_) {
        // سطر تالف لا يُسقط السجل كله
      }
    }
    return entries;
  }

  Future<void> saveAuditLog(List<AuditLogEntry> entries) async {
    final trimmed = entries.length > auditLogCapacity
        ? entries.sublist(0, auditLogCapacity)
        : entries;
    await _prefs.setStringList(
      _kAuditLog,
      trimmed.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  /// يضيف سطراً جديداً في أعلى السجل.
  Future<AuditLogEntry> recordAudit(AuditLogEntry entry) async {
    final entries = loadAuditLog()..insert(0, entry);
    await saveAuditLog(entries);
    return entry;
  }

  Future<void> setAuditActor(String? actorJson) async {
    if (actorJson == null) {
      await _prefs.remove(_kAuditActor);
    } else {
      await _prefs.setString(_kAuditActor, actorJson);
    }
  }

  /// بصمة المستخدم الحالي التي تُختم بها أسطر التدقيق، حتى تكتبها طبقة
  /// التخزين دون أن تحمل مرجعاً لخدمة المصادقة.
  ({String? id, String name, String role}) getAuditActor() {
    final raw = _prefs.getString(_kAuditActor);
    if (raw == null) return (id: null, name: 'غير مسجّل', role: 'unknown');
    try {
      final map = Map<String, dynamic>.from(jsonDecode(raw));
      return (
        id: map['id']?.toString(),
        name: map['name']?.toString() ?? 'غير معروف',
        role: map['role']?.toString() ?? 'unknown',
      );
    } catch (_) {
      return (id: null, name: 'غير معروف', role: 'unknown');
    }
  }

  /// تهيئة البيانات الافتراضية الأولية المستخرجة حرفياً من ملف الإكسل ERP_مطبعة_متكامل.xls.
  ///
  /// [includeDemoRecords] يتحكم في البيانات التجارية الوهمية (عملاء، عروض أسعار،
  /// أوامر إنتاج، مدفوعات). يُترك `true` للتجربة، ويجب أن يكون `false` عند
  /// التثبيت الفعلي حتى لا تُحسب مبيعات وهمية في لوحة المؤشرات والذمم.
  Future<void> seedInitialData({bool includeDemoRecords = true}) async {
    await _prefs.remove(_kCustomerLedger);
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
    if (includeDemoRecords) {
      await _seedDemoRecords();
    }

    await ensureCustomerLedgerFromLegacy(force: true);
  }

  /// يمسح السجلات التجارية الوهمية (عملاء، عروض، أوامر إنتاج، حركات،
  /// مدفوعات، دفتر قيود) ويُبقي المرجعيات: الورق، الماكينات، المنتجات،
  /// التشطيبات، الأحبار، والإعدادات.
  Future<void> clearDemoRecords() async {
    await _prefs.remove(_kCustomers);
    await _prefs.remove(_kQuotations);
    await _prefs.remove(_kProductionOrders);
    await _prefs.remove(_kStockMoves);
    await _prefs.remove(_kPayments);
    await _prefs.remove(_kCustomerLedger);
    await setFirstRunMode('clean');
  }

  /// بيانات تجارية وهمية للتجربة والعرض فقط. تُزرع عند اختيار «نسخة تجريبية»
  /// في أول تشغيل، وتُتجاوز عند اختيار «تثبيت فعلي ببيانات نظيفة».
  Future<void> _seedDemoRecords() async {
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

  /// قراءة/كتابة عدد صحيح بمفتاح حر (يستخدمه عدّاد جولات القفل).
  int? getIntPref(String key) => _prefs.getInt(key);

  Future<void> setIntPref(String key, int value) => _prefs.setInt(key, value);

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


/// نتيجة استيراد نسخة احتياطية: نجاح أو فشل بسبب معلن، بدل `bool` غامض.
class BackupImportResult {
  final bool isSuccess;
  final String? errorMessage;
  final bool restoredUsers;
  final bool safetySnapshotTaken;

  const BackupImportResult._({
    required this.isSuccess,
    this.errorMessage,
    this.restoredUsers = false,
    this.safetySnapshotTaken = false,
  });

  factory BackupImportResult.success({
    bool restoredUsers = false,
    bool safetySnapshotTaken = false,
  }) =>
      BackupImportResult._(
        isSuccess: true,
        restoredUsers: restoredUsers,
        safetySnapshotTaken: safetySnapshotTaken,
      );

  factory BackupImportResult.failure(String message) =>
      BackupImportResult._(isSuccess: false, errorMessage: message);
}
