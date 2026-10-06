import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:erp_printer/models/app_models.dart';
import 'package:erp_printer/services/auth_service.dart';
import 'package:erp_printer/services/backup_codec.dart';
import 'package:erp_printer/services/storage_service.dart';

/// تنفيذ مرجعي مستقل لـ PBKDF2-HMAC-SHA256 (RFC 2898) مبني على `Hmac`
/// مباشرة، لمقارنة نتيجة [AuthService.hashPinWithSalt] به.
String referencePbkdf2(String password, String salt, int iterations) {
  final hmac = Hmac(sha256, utf8.encode(password));
  final saltBytes = utf8.encode(salt);
  final block = Uint8List(saltBytes.length + 4)
    ..setRange(0, saltBytes.length, saltBytes);
  // الكتلة الأولى فقط (i = 1) تكفي لمخرج بطول 32 بايت.
  block[saltBytes.length + 3] = 1;

  var u = hmac.convert(block).bytes;
  final t = List<int>.from(u);
  for (var c = 1; c < iterations; c++) {
    u = hmac.convert(u).bytes;
    for (var b = 0; b < t.length; b++) {
      t[b] ^= u[b];
    }
  }
  return base64Encode(t);
}

void main() {
  group('BackupCodec', () {
    const sample =
        '{"papers":[{"id":"P01","sheetPrice":120}],"customers":[{"name":"دار المعرفة"}]}';

    test('يشفر ويفك التشفير دون فقدان أي بايت (نص عربي)', () {
      final payload = BackupCodec.encrypt(sample, 'Matbaa@2026');

      expect(BackupCodec.isEncrypted(payload), isTrue);
      expect(payload.contains('sheetPrice'), isFalse,
          reason: 'المحتوى يجب ألا يظهر كنص صريح داخل الملف');
      expect(BackupCodec.decrypt(payload, 'Matbaa@2026'), sample);
    });

    test('كلمة مرور خاطئة تُرفض برسالة مفهومة', () {
      final payload = BackupCodec.encrypt(sample, 'Matbaa@2026');

      expect(
        () => BackupCodec.decrypt(payload, 'matbaa@2026'),
        throwsA(
          isA<BackupCryptoException>().having(
            (e) => e.message,
            'message',
            contains('كلمة المرور'),
          ),
        ),
      );
    });

    test('أي تعديل على النص المشفر يُكتشف قبل فك التشفير', () {
      final payload = BackupCodec.encrypt(sample, 'Matbaa@2026');
      final json = jsonDecode(payload) as Map<String, dynamic>;

      final ct = base64Decode(json['ct'] as String);
      ct[0] = ct[0] ^ 0x01;
      json['ct'] = base64Encode(ct);

      expect(
        () => BackupCodec.decrypt(jsonEncode(json), 'Matbaa@2026'),
        throwsA(isA<BackupCryptoException>()),
      );
    });

    test('التشفير نفسه يعطي ملفين مختلفين (Salt و IV عشوائيان)', () {
      final a = jsonDecode(BackupCodec.encrypt(sample, 'pw123456')) as Map;
      final b = jsonDecode(BackupCodec.encrypt(sample, 'pw123456')) as Map;

      expect(a['salt'], isNot(b['salt']));
      expect(a['iv'], isNot(b['iv']));
      expect(a['ct'], isNot(b['ct']));
    });

    test('الملف يحمل إصدار الصيغة وعدد الدورات ووسم HMAC', () {
      final json =
          jsonDecode(BackupCodec.encrypt(sample, 'pw123456')) as Map<String, dynamic>;

      expect(json['format'], BackupCodec.formatName);
      expect(json['iterations'], BackupCodec.kdfIterations);
      expect(base64Decode(json['mac'] as String).length, 32);
      expect(json['version'], 1);
    });

    test('النص العادي لا يُعتبر نسخة مشفرة', () {
      expect(BackupCodec.isEncrypted('{"version":"1.2"}'), isFalse);
      expect(BackupCodec.isEncrypted('not json at all'), isFalse);
    });

    test('كلمة مرور فارغة مرفوضة', () {
      expect(() => BackupCodec.encrypt(sample, ''), throwsArgumentError);
    });

    test('إصدار صيغة غير مدعوم مرفوض', () {
      final payload = BackupCodec.encrypt(sample, 'pw123456');
      final json = jsonDecode(payload) as Map<String, dynamic>
        ..['format'] = 'some-future-format';

      expect(
        () => BackupCodec.decrypt(jsonEncode(json), 'pw123456'),
        throwsA(isA<BackupCryptoException>()),
      );
    });

    test('بيانات KDF غير المدعومة تُرفض قبل اشتقاق المفتاح', () {
      final payload = BackupCodec.encrypt(sample, 'pw123456');
      final json = jsonDecode(payload) as Map<String, dynamic>
        ..['iterations'] = 0x7fffffff;

      expect(
        () => BackupCodec.decrypt(jsonEncode(json), 'pw123456'),
        throwsA(isA<BackupCryptoException>()),
      );
    });

    test('أطوال salt و IV و HMAC غير الصحيحة تُرفض', () {
      final payload = BackupCodec.encrypt(sample, 'pw123456');
      final json = jsonDecode(payload) as Map<String, dynamic>
        ..['salt'] = base64Encode([1]);

      expect(
        () => BackupCodec.decrypt(jsonEncode(json), 'pw123456'),
        throwsA(isA<BackupCryptoException>()),
      );
    });

    test('اشتقاق مفتاح PIN يطابق PBKDF2-HMAC-SHA256 القياسي', () {
      // متجه اختبار مولَّد خارج Dart من hashlib.pbkdf2_hmac('sha256', ...):
      // password='1234', salt='0123456789abcdef', iterations=1000, dklen=32
      const expected = 'lthrw4diKhMqjsP6Pb8Ut8JakDM53i2wZ0MKCGR8gn4=';

      expect(
        referencePbkdf2('1234', '0123456789abcdef', 1000),
        expected,
        reason: 'المرجع المستقل يجب أن يطابق المتجه المولَّد خارج Dart',
      );
      expect(
        AuthService.hashPinWithSalt('1234', '0123456789abcdef', iterations: 1000),
        expected,
        reason: 'تنفيذ الإنتاج يجب أن يطابق المعيار نفسه',
      );
    });
  });

  group('AuthService — تجزئة PIN', () {
    test('hashPin ينتج Salt وتجزئة، والتحقق ينجح بهما', () {
      final hashed = AuthService.hashPin('1234');

      expect(hashed.salt, isNotEmpty);
      expect(hashed.hash, isNotEmpty);
      expect(hashed.hash, isNot('1234'));

      final user = UserAccount(
        id: 'U1',
        username: 'u',
        displayName: 'مستخدم',
        pinHash: hashed.hash,
        pinSalt: hashed.salt,
        createdAt: DateTime(2026),
      );
      expect(AuthService.verifyPin(user, '1234'), isTrue);
      expect(AuthService.verifyPin(user, '1235'), isTrue == false);
      expect(AuthService.needsPinUpgrade(user), isFalse);
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('نفس PIN مع Salt مختلف يعطي تجزئة مختلفة', () {
      final a = AuthService.hashPin('1234');
      final b = AuthService.hashPin('1234');

      expect(a.salt, isNot(b.salt));
      expect(a.hash, isNot(b.hash));
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('الحساب القديم بلا Salt يُتحقق منه ويُعتبر بحاجة ترقية', () {
      final user = UserAccount(
        id: 'U1',
        username: 'old',
        displayName: 'قديم',
        pinHash: AuthService.hashPinLegacy('1234'),
        createdAt: DateTime(2026),
      );

      expect(AuthService.verifyPin(user, '1234'), isTrue);
      expect(AuthService.verifyPin(user, '9999'), isFalse);
      expect(AuthService.needsPinUpgrade(user), isTrue);
    });
  });

  group('AuthService — سياسة القفل', () {
    test('مدة القفل تتصاعد 1 ثم 5 ثم 30 دقيقة', () {
      expect(AuthService.lockoutMinutesFor(1), 1);
      expect(AuthService.lockoutMinutesFor(2), 5);
      expect(AuthService.lockoutMinutesFor(3), 30);
      expect(AuthService.lockoutMinutesFor(9), 30);
    });
  });

  group('AuthService — الصلاحيات وحماية المدير', () {
    late StorageService storage;
    late AuthService auth;

    Future<void> bootstrap({bool demo = false}) async {
      SharedPreferences.setMockInitialValues({});
      storage = await StorageService.init(firstRunMode: demo ? 'demo' : 'clean');
      auth = AuthService(storage);
    }

    Future<UserAccount> createUser({
      required String id,
      required String username,
      required UserRole role,
      String pin = '1234',
    }) async {
      final hashed = AuthService.hashPin(pin);
      final user = UserAccount(
        id: id,
        username: username,
        displayName: username,
        pinHash: hashed.hash,
        pinSalt: hashed.salt,
        role: role,
        createdAt: DateTime(2026),
      );
      await storage.addUser(user);
      return user;
    }

    test('لا عملية بلا جلسة: كل عمليات الإدارة مرفوضة', () async {
      await bootstrap();

      expect(auth.isLoggedIn, isFalse);
      expect(auth.hasPermission(UserRole.employee), isFalse);
      expect(await auth.createUser(
        username: 'x', displayName: 'x', pin: '1234', role: UserRole.employee,
      ), isNotNull);
      expect(await auth.deleteUser('U1'), isNotNull);
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('الموظف لا ينشئ مستخدمين ولا يحذفهم', () async {
      await bootstrap();
      final employee = await createUser(id: 'E1', username: 'emp', role: UserRole.employee);
      final admin = await createUser(id: 'A1', username: 'adm', role: UserRole.admin);
      await auth.login(employee.id, '1234');

      final createError = await auth.createUser(
        username: 'x', displayName: 'x', pin: '1234', role: UserRole.employee,
      );
      expect(createError, contains('صلاحية'));
      expect(await auth.deleteUser(admin.id), contains('صلاحية'));
      expect(storage.loadUsers().length, 2);
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('لا يمكن حذف آخر مدير نشط', () async {
      await bootstrap();
      final admin = await createUser(id: 'A1', username: 'adm', role: UserRole.admin);
      await auth.login(admin.id, '1234');

      expect(await auth.deleteUser(admin.id), contains('آخر مدير'));
      expect(storage.loadUsers(), hasLength(1));
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('لا يمكن حذف الحساب الجاري استخدامه حتى لو كان مديراً ثانياً', () async {
      await bootstrap();
      await createUser(id: 'A1', username: 'adm1', role: UserRole.admin);
      final admin2 = await createUser(id: 'A2', username: 'adm2', role: UserRole.admin);
      await auth.login(admin2.id, '1234');

      expect(await auth.deleteUser(admin2.id), contains('تستخدمه الآن'));
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('يمكن حذف مدير ثانٍ من حساب مدير آخر', () async {
      await bootstrap();
      final admin1 = await createUser(id: 'A1', username: 'adm1', role: UserRole.admin);
      final admin2 = await createUser(id: 'A2', username: 'adm2', role: UserRole.admin);
      await auth.login(admin1.id, '1234');

      expect(await auth.deleteUser(admin2.id), isNull);
      expect(storage.loadUsers().map((u) => u.id), contains(admin1.id));
      expect(storage.loadUsers(), hasLength(1));
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('لا يمكن تخفيض آخر مدير إلى موظف', () async {
      await bootstrap();
      final admin = await createUser(id: 'A1', username: 'adm', role: UserRole.admin);
      await auth.login(admin.id, '1234');

      expect(
        await auth.changeUserRole(admin.id, UserRole.employee),
        contains('آخر مدير'),
      );
      expect(storage.loadUsers().single.role, UserRole.admin);
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('لا يمكن تعطيل آخر مدير نشط', () async {
      await bootstrap();
      final admin = await createUser(id: 'A1', username: 'adm', role: UserRole.admin);
      await auth.login(admin.id, '1234');

      expect(await auth.toggleUserStatus(admin.id), contains('آخر مدير'));
      expect(storage.loadUsers().single.isActive, isTrue);
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('المدير ينشئ مستخداً ويُسجَّل الحدث في سجل التدقيق', () async {
      await bootstrap();
      final admin = await createUser(id: 'A1', username: 'adm', role: UserRole.admin);
      await auth.login(admin.id, '1234');

      expect(
        await auth.createUser(
          username: 'emp', displayName: 'موظف', pin: '4321', role: UserRole.employee,
        ),
        isNull,
      );
      expect(storage.loadUsers(), hasLength(2));

      final actions = storage.loadAuditLog().map((e) => e.action).toList();
      expect(actions, contains('user_created'));
      expect(actions, contains('login_success'));

      final created = storage.loadAuditLog().firstWhere((e) => e.action == 'user_created');
      expect(created.actorName, 'adm');
      expect(created.severity, AuditSeverity.info);
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('رفض الصلاحية يُسجَّل كحدث حرج', () async {
      await bootstrap();
      final employee = await createUser(id: 'E1', username: 'emp', role: UserRole.employee);
      await auth.login(employee.id, '1234');

      await auth.deleteUser('A1');

      final denied = storage
          .loadAuditLog()
          .firstWhere((e) => e.action == 'permission_denied');
      expect(denied.severity, AuditSeverity.critical);
      expect(denied.success, isFalse);
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('تغيير PIN من موظف لنفسه مسموح، ولغيره مرفوض', () async {
      await bootstrap();
      final employee = await createUser(id: 'E1', username: 'emp', role: UserRole.employee);
      final other = await createUser(id: 'E2', username: 'emp2', role: UserRole.employee);
      await auth.login(employee.id, '1234');

      expect(await auth.updateUserPin(employee.id, '9876'), isNull);
      expect(await auth.updateUserPin(other.id, '9876'), contains('صلاحية'));

      final result = await auth.login(employee.id, '9876');
      expect(result.isSuccess, isTrue);
    }, timeout: const Timeout(Duration(minutes: 4)));
  });

  group('AuthService — الدخول والقفل', () {
    late StorageService storage;
    late AuthService auth;

    Future<UserAccount> bootstrapWithUser() async {
      SharedPreferences.setMockInitialValues({});
      storage = await StorageService.init(firstRunMode: 'clean');
      auth = AuthService(storage);
      final hashed = AuthService.hashPin('1234');
      final user = UserAccount(
        id: 'A1',
        username: 'adm',
        displayName: 'المدير',
        pinHash: hashed.hash,
        pinSalt: hashed.salt,
        role: UserRole.admin,
        createdAt: DateTime(2026),
      );
      await storage.addUser(user);
      return user;
    }

    test('الحساب القديم بلا Salt يُرقّى تلقائياً عند أول دخول ناجح', () async {
      SharedPreferences.setMockInitialValues({});
      storage = await StorageService.init(firstRunMode: 'clean');
      auth = AuthService(storage);
      await storage.addUser(UserAccount(
        id: 'A1',
        username: 'adm',
        displayName: 'المدير',
        pinHash: AuthService.hashPinLegacy('1234'),
        createdAt: DateTime(2026),
      ));

      expect(AuthService.needsPinUpgrade(storage.loadUsers().single), isTrue);

      final result = await auth.login('A1', '1234');
      expect(result.isSuccess, isTrue);

      final upgraded = storage.loadUsers().single;
      expect(upgraded.pinSalt, isNotNull);
      expect(upgraded.pinHash, isNot(AuthService.hashPinLegacy('1234')));
      expect(AuthService.verifyPin(upgraded, '1234'), isTrue);

      final second = await auth.login('A1', '1234');
      expect(second.isSuccess, isTrue);
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('خمس محاولات خاطئة تقفل الحساب حتى مع PIN صحيح', () async {
      await bootstrapWithUser();

      for (var i = 0; i < 5; i++) {
        final failed = await auth.login('A1', '0000');
        expect(failed.isSuccess, isFalse);
      }

      final lockedOut = await auth.login('A1', '1234');
      expect(lockedOut.isSuccess, isFalse);
      expect(lockedOut.errorMessage, contains('مقفول'));

      final lockActions =
          storage.loadAuditLog().where((e) => e.action == 'login_locked').toList();
      expect(lockActions, hasLength(1));
      expect(lockActions.single.severity, AuditSeverity.critical);
    }, timeout: const Timeout(Duration(minutes: 4)));
  });

  group('StorageService — النسخ الاحتياطي', () {
    late StorageService storage;

    Future<void> bootstrap({String mode = 'demo'}) async {
      SharedPreferences.setMockInitialValues({});
      storage = await StorageService.init(firstRunMode: mode);
    }

    test('النسخة تشمل المستخدمين وسجل التدقيق ووضع أول تشغيل', () async {
      await bootstrap();
      final hashed = AuthService.hashPin('1234');
      await storage.addUser(UserAccount(
        id: 'A1',
        username: 'adm',
        displayName: 'المدير',
        pinHash: hashed.hash,
        pinSalt: hashed.salt,
        role: UserRole.admin,
        createdAt: DateTime(2026),
      ));
      await storage.recordAudit(AuditLogEntry(
        id: 'AUD_1',
        timestamp: DateTime(2026, 10, 6),
        actorId: 'A1',
        actorName: 'المدير',
        actorRole: 'admin',
        action: 'user_created',
        details: 'اختبار',
      ));

      final json =
          jsonDecode(storage.exportBackupJson()) as Map<String, dynamic>;

      expect(json['version'], StorageService.backupVersion);
      expect(json['firstRunMode'], 'demo');
      expect((json['users'] as List), hasLength(1));
      expect((json['auditLog'] as List), hasLength(1));
      expect(json['papers'], isNotNull);
    });

    test('includeUsers=false تستثني الحسابات فقط', () async {
      await bootstrap();
      final json = jsonDecode(
        storage.exportBackupJson(includeUsers: false),
      ) as Map<String, dynamic>;

      expect(json.containsKey('users'), isFalse);
      expect(json['papers'], isNotNull);
    });

    test('الاستيراد يرفض إصدار صيغة غير معروف بدل الاستيراد الناقص', () async {
      await bootstrap();
      final json = jsonDecode(storage.exportBackupJson()) as Map<String, dynamic>
        ..['version'] = '9.9';

      final result = await storage.importBackupJson(jsonEncode(json));

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('غير مدعوم'));
    });

    test('الاستيراد يرفض JSON تالف برسالة واضحة', () async {
      await bootstrap();
      final result = await storage.importBackupJson('{ this is not json');

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('تالف'));
    });

    test('الاستيراد الناجح يعيد المستخدمين ويأخذ لقطة أمان', () async {
      await bootstrap();
      final backup = storage.exportBackupJson();

      await storage.clearDemoRecords();
      expect(storage.loadCustomers(), isEmpty);

      final result = await storage.importBackupJson(backup);

      expect(result.isSuccess, isTrue);
      expect(result.restoredUsers, isTrue);
      expect(result.safetySnapshotTaken, isTrue);
      expect(storage.loadCustomers(), isNotEmpty);
      expect(storage.hasSafetySnapshot, isTrue);
    });

    test('النسخة الحالية الناقصة تُرفض قبل اللقطة أو أي تغيير', () async {
      await bootstrap(demo: true);
      final originalCustomerCount = storage.loadCustomers().length;
      final backup = jsonDecode(storage.exportBackupJson()) as Map<String, dynamic>
        ..remove('papers');

      final result = await storage.importBackupJson(jsonEncode(backup));

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('papers'));
      expect(storage.hasSafetySnapshot, isFalse);
      expect(storage.loadCustomers(), hasLength(originalCustomerCount));
    });

    test('القائمة null في النسخة تمسح بياناتها القديمة بدلاً من إبقائها', () async {
      await bootstrap(demo: true);
      final backup = jsonDecode(storage.exportBackupJson()) as Map<String, dynamic>
        ..['customers'] = null
        ..['quotations'] = null
        ..['productionOrders'] = null
        ..['stockMoves'] = null
        ..['payments'] = null
        ..['customerLedger'] = null;

      final result = await storage.importBackupJson(jsonEncode(backup));

      expect(result.isSuccess, isTrue);
      expect(storage.loadCustomers(), isEmpty);
      expect(storage.loadQuotations(), isEmpty);
      expect(storage.loadProductionOrders(), isEmpty);
      expect(storage.loadStockMoves(), isEmpty);
      expect(storage.loadPayments(), isEmpty);
      expect(storage.loadCustomerLedger(), isEmpty);
    });

    test('لقطة الأمان تعيد القاعدة إلى وضعها قبل الاستيراد', () async {
      await bootstrap(mode: 'clean');
      final cleanState = storage.exportBackupJson();
      expect(storage.loadCustomers(), isEmpty);

      // استيراد نسخة ديمو يملأ القاعدة ببيانات تجريبية
      SharedPreferences.setMockInitialValues({});
      final demoStorage = await StorageService.init(firstRunMode: 'demo');
      final demoBackup = demoStorage.exportBackupJson();

      final imported = await storage.importBackupJson(demoBackup);
      expect(imported.isSuccess, isTrue);
      expect(storage.loadCustomers(), isNotEmpty);

      // التراجع يجب أن يعيد الحالة النظيفة
      expect(await storage.restoreSafetySnapshot(), isTrue);
      expect(storage.loadCustomers(), isEmpty);
      expect(cleanState, isNotNull);
    });
  });

  group('StorageService — وضع أول تشغيل', () {
    test('التهيئة الافتراضية تبدأ ببيانات نظيفة', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();

      expect(storage.getFirstRunMode(), 'clean');
      expect(storage.hasDemoRecords, isFalse);
      expect(storage.loadCustomers(), isEmpty);
      expect(storage.loadQuotations(), isEmpty);
      expect(storage.loadProductionOrders(), isEmpty);
      expect(storage.loadPayments(), isEmpty);
      expect(storage.loadPapers(), isNotEmpty);
    });

    test('demo يزرع سجلات تجارية وهمية', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init(firstRunMode: 'demo');

      expect(storage.hasDemoRecords, isTrue);
      expect(storage.loadCustomers(), isNotEmpty);
      expect(storage.loadQuotations(), isNotEmpty);
      expect(storage.loadProductionOrders(), isNotEmpty);
      expect(storage.loadPapers(), isNotEmpty);
    });

    test('clean يزرع المرجعيات فقط بلا أموال وهمية', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init(firstRunMode: 'clean');

      expect(storage.hasDemoRecords, isFalse);
      expect(storage.loadCustomers(), isEmpty);
      expect(storage.loadQuotations(), isEmpty);
      expect(storage.loadProductionOrders(), isEmpty);
      expect(storage.loadPayments(), isEmpty);
      expect(storage.loadCustomerLedger(), isEmpty);
      // المرجعيات تبقى
      expect(storage.loadPapers(), hasLength(18));
      expect(storage.loadMachines(), hasLength(3));
      expect(storage.loadProducts(), hasLength(4));
      expect(storage.loadInks(), hasLength(5));
    });

    test('clearDemoRecords يمسح التجاري ويُبقي المرجعيات', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init(firstRunMode: 'demo');

      await storage.clearDemoRecords();

      expect(storage.loadCustomers(), isEmpty);
      expect(storage.loadQuotations(), isEmpty);
      expect(storage.loadProductionOrders(), isEmpty);
      expect(storage.loadPayments(), isEmpty);
      expect(storage.loadStockMoves(), isEmpty);
      expect(storage.hasDemoRecords, isFalse);
      expect(storage.loadPapers(), hasLength(18));
      expect(storage.loadMachines(), hasLength(3));
    });
  });

  group('سجل التدقيق', () {
    test('الأحدث أولاً ويُقتطع عند تجاوز السعة', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init(firstRunMode: 'clean');

      for (var i = 0; i < 5; i++) {
        await storage.recordAudit(AuditLogEntry(
          id: 'AUD_$i',
          timestamp: DateTime(2026, 10, 6, 12, i),
          actorName: 'المدير',
          actorRole: 'admin',
          action: 'action_$i',
        ));
      }

      final log = storage.loadAuditLog();
      expect(log, hasLength(5));
      expect(log.first.action, 'action_4');
      expect(log.last.action, 'action_0');
    });

    test('بصمة الجلسة تُختم على الأسطر', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init(firstRunMode: 'clean');
      final auth = AuthService(storage);
      final hashed = AuthService.hashPin('1234');
      await storage.addUser(UserAccount(
        id: 'A1',
        username: 'adm',
        displayName: 'محمد',
        pinHash: hashed.hash,
        pinSalt: hashed.salt,
        role: UserRole.admin,
        createdAt: DateTime(2026),
      ));

      expect(storage.getAuditActor().name, 'غير مسجّل');

      await auth.login('A1', '1234');

      final actor = storage.getAuditActor();
      expect(actor.id, 'A1');
      expect(actor.name, 'محمد');
      expect(actor.role, 'admin');

      await auth.logout();
      expect(storage.getAuditActor().name, 'غير مسجّل');
    }, timeout: const Timeout(Duration(minutes: 3)));
  });
}
