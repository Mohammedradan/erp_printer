import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../models/app_models.dart';
import 'storage_service.dart';

/// خدمة المصادقة: تسجيل الدخول بـ PIN، الجلسات، الصلاحيات، وسجل التدقيق.
///
/// مبادئ مطبقة هنا:
/// - الـ PIN يُخزَّن بتجزئة مقوّاة (PBKDF2-HMAC-SHA256 + Salt)، لا SHA-256 مجرّدة.
/// - الحسابات القديمة تُرحَّل تلقائياً عند أول تسجيل دخول ناجح.
/// - الصلاحية تُفرض في هذه الطبقة، لا في الواجهة فقط.
/// - كل عملية حساسة تترك سطراً في سجل التدقيق.
class AuthService {
  final StorageService _storage;

  AuthService(this._storage);

  // ─────────────────────────────────────────────────────────
  // تجزئة PIN
  // ─────────────────────────────────────────────────────────

  /// عدد دورات اشتقاق المفتاح للـ PIN.
  ///
  /// الـ PIN هنا 4 أرقام غالباً، فالحماية الفعلية تأتي من الـ Salt الخاص بكل
  /// حساب (يمنع جداول القوس ومهاجمة كل الحسابات دفعة واحدة) ومن القفل
  /// المتصاعد بعد المحاولات الخاطئة. 20000 دورة توازن بين الأمان وزمن
  /// الاستجابة على أجهزة أندرويد المتوسطة.
  static const int pinKdfIterations = 20000;

  static final Random _random = Random.secure();

  /// تجزئة SHA-256 القديمة، تُستخدم فقط للتحقق من الحسابات المرحَّلة.
  static String hashPinLegacy(String pin) {
    final bytes = utf8.encode(pin.trim());
    return sha256.convert(bytes).toString();
  }

  /// ينشئ Salt عشوائياً بطول 16 بايت.
  static String newPinSalt() {
    final bytes = Uint8List.fromList(
      List<int>.generate(16, (_) => _random.nextInt(256)),
    );
    return base64Encode(bytes);
  }

  /// التجزئة المقوّاة للـ PIN: PBKDF2-HMAC-SHA256 على (PIN ‖ Salt).
  ///
  /// [iterations] قابل للتجاوز في الاختبارات لمقارنته بمتجهات اختبار قياسية.
  static String hashPinWithSalt(
    String pin,
    String salt, {
    int iterations = pinKdfIterations,
  }) {
    final password = utf8.encode(pin.trim());
    final saltBytes = utf8.encode(salt);
    const dkLen = 32;
    final hmac = Hmac(sha256, password);
    final out = BytesBuilder();
    final blocks = (dkLen + 31) ~/ 32;
    final block = Uint8List(saltBytes.length + 4)
      ..setRange(0, saltBytes.length, saltBytes);

    for (var i = 1; i <= blocks; i++) {
      block[saltBytes.length + 0] = (i >> 24) & 0xFF;
      block[saltBytes.length + 1] = (i >> 16) & 0xFF;
      block[saltBytes.length + 2] = (i >> 8) & 0xFF;
      block[saltBytes.length + 3] = i & 0xFF;

      var u = Uint8List.fromList(hmac.convert(block).bytes);
      final t = Uint8List.fromList(u);
      for (var c = 1; c < iterations; c++) {
        u = Uint8List.fromList(hmac.convert(u).bytes);
        for (var b = 0; b < t.length; b++) {
          t[b] ^= u[b];
        }
      }
      out.add(t);
    }
    final derived = out.takeBytes();
    return base64Encode(derived.sublist(0, dkLen));
  }

  /// تجزئة جديدة جاهزة للحفظ.
  static ({String hash, String salt}) hashPin(String pin) {
    final salt = newPinSalt();
    return (hash: hashPinWithSalt(pin, salt), salt: salt);
  }

  /// يتحقق من PIN مقابل حساب قد يكون قديماً (بلا Salt) أو مقوّى.
  static bool verifyPin(UserAccount user, String pin) {
    final candidate = pin.trim();
    final salt = user.pinSalt;
    if (salt != null && salt.isNotEmpty) {
      return _constantTimeEquals(hashPinWithSalt(candidate, salt), user.pinHash);
    }
    return _constantTimeEquals(hashPinLegacy(candidate), user.pinHash);
  }

  /// هل هذا الحساب ما زال بالتجزئة القديمة ويحتاج ترقية؟
  static bool needsPinUpgrade(UserAccount user) =>
      user.pinSalt == null || user.pinSalt!.isEmpty;

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  // ─────────────────────────────────────────────────────────
  // سياسة القفل بعد المحاولات الخاطئة (متصاعدة)
  // ─────────────────────────────────────────────────────────

  static const int _maxAttempts = 5;

  /// مدة القفل بالدقائق حسب رقم الجولة: 1 ← 5 ← 30.
  static int lockoutMinutesFor(int failedRound) => switch (failedRound) {
        <= 1 => 1,
        2 => 5,
        _ => 30,
      };

  int _failedRoundFor(String userId) =>
      _storage.getIntPref('${_kFailedRounds}_$userId') ?? 0;

  static const String _kFailedRounds = 'erp_login_failed_rounds';

  // ─────────────────────────────────────────────────────────
  // تسجيل الدخول
  // ─────────────────────────────────────────────────────────

  /// محاولة تسجيل الدخول - يُرجع [LoginResult] مع رسالة خطأ عند الفشل.
  Future<LoginResult> login(String userId, String pin) async {
    final users = _storage.loadUsers();
    UserAccount? user;
    try {
      user = users.firstWhere((u) => u.id == userId);
    } catch (_) {
      await _audit(
        action: 'login_failed',
        targetType: 'user',
        targetId: userId,
        details: 'محاولة دخول بمستخدم غير موجود',
        success: false,
        severity: AuditSeverity.warning,
      );
      return LoginResult.error('المستخدم غير موجود');
    }

    if (!user.isActive) {
      await _audit(
        action: 'login_blocked',
        targetType: 'user',
        targetId: user.id,
        actor: user,
        details: 'الحساب معطّل',
        success: false,
        severity: AuditSeverity.warning,
      );
      return LoginResult.error('الحساب معطّل، تواصل مع المدير');
    }

    final lockout = _storage.getLockoutUntil(userId);
    if (lockout != null && DateTime.now().isBefore(lockout)) {
      final remaining = lockout.difference(DateTime.now()).inSeconds;
      return LoginResult.error('محاولات كثيرة. انتظر $remaining ثانية');
    }

    if (!verifyPin(user, pin)) {
      final attempts = _storage.getLoginAttempts(userId) + 1;
      await _storage.setLoginAttempts(userId, attempts);

      if (attempts >= _maxAttempts) {
        final round = _failedRoundFor(userId) + 1;
        final minutes = lockoutMinutesFor(round);
        await _storage.setIntPref('${_kFailedRounds}_$userId', round);
        await _storage.setLockoutUntil(
          userId,
          DateTime.now().add(Duration(minutes: minutes)),
        );
        await _storage.setLoginAttempts(userId, 0);
        await _audit(
          action: 'login_locked',
          targetType: 'user',
          targetId: user.id,
          actor: user,
          details: 'قفل الحساب $minutes دقيقة بعد $_maxAttempts محاولات خاطئة',
          success: false,
          severity: AuditSeverity.critical,
        );
        return LoginResult.error(
          'PIN خاطئ $_maxAttempts مرات. الحساب مقفول لمدة $minutes دقيقة',
        );
      }

      final remaining = _maxAttempts - attempts;
      await _audit(
        action: 'login_failed',
        targetType: 'user',
        targetId: user.id,
        actor: user,
        details: 'PIN خاطئ، محاولات متبقية $remaining',
        success: false,
        severity: AuditSeverity.warning,
      );
      return LoginResult.error('PIN خاطئ. محاولات متبقية: $remaining');
    }

    // نجاح — تصفير العدادات وترقية التجزئة القديمة إن لزم.
    await _storage.setLoginAttempts(userId, 0);
    await _storage.setLockoutUntil(userId, null);
    await _storage.setIntPref('${_kFailedRounds}_$userId', 0);

    if (needsPinUpgrade(user)) {
      final upgraded = hashPin(pin);
      user = user.copyWith(pinHash: upgraded.hash, pinSalt: upgraded.salt);
      await _storage.updateUser(user);
      await _audit(
        action: 'pin_upgraded',
        targetType: 'user',
        targetId: user.id,
        actor: user,
        details: 'ترقية تجزئة PIN من SHA-256 إلى PBKDF2 مع Salt',
      );
    }

    await _storage.setActiveUserId(userId);
    await attachSession(user);
    await _audit(
      action: 'login_success',
      targetType: 'user',
      targetId: user.id,
      actor: user,
      details: 'تسجيل دخول ${user.role.label}',
    );

    return LoginResult.success(user);
  }

  /// يختم بصمة المستخدم الحالي على أسطر التدقيق اللاحقة.
  Future<void> attachSession(UserAccount? user) async {
    if (user == null) {
      await _storage.setAuditActor(null);
      return;
    }
    await _storage.setAuditActor(
      jsonEncode({
        'id': user.id,
        'name': user.displayName,
        'role': user.role.toJson,
      }),
    );
  }

  // ─────────────────────────────────────────────────────────
  // تسجيل الخروج والجلسة
  // ─────────────────────────────────────────────────────────

  Future<void> logout() async {
    final user = getCurrentUser();
    await _audit(
      action: 'logout',
      targetType: 'user',
      targetId: user?.id,
      actor: user,
      details: 'تسجيل خروج',
    );
    await _storage.setActiveUserId(null);
    await _storage.setAuditActor(null);
  }

  UserAccount? getCurrentUser() => _storage.getActiveUser();

  bool get isLoggedIn => getCurrentUser() != null;

  // ─────────────────────────────────────────────────────────
  // الصلاحيات — مفروضة هنا لا في الواجهة
  // ─────────────────────────────────────────────────────────

  bool isAdmin() => getCurrentUser()?.role == UserRole.admin;

  /// هل للمستخدم الحالي صلاحية [requiredRole]؟
  bool hasPermission(UserRole requiredRole) {
    final user = getCurrentUser();
    if (user == null) return false;
    if (requiredRole == UserRole.employee) return true;
    return user.role == UserRole.admin;
  }

  /// بوابة صلاحية تُرجع رسالة خطأ عربية أو null عند السماح.
  String? guardRole(UserRole requiredRole, {String? actionLabel}) {
    final user = getCurrentUser();
    final label = actionLabel ?? 'هذه العملية';
    if (user == null) return 'يجب تسجيل الدخول قبل $label';
    if (hasPermission(requiredRole)) return null;
    return 'لا تملك صلاحية $label. هذه العملية للمدير فقط';
  }

  /// يفرض صلاحية المدير: يُرجع رسالة رفض عربية ويسجل المحاولة، أو null عند السماح.
  Future<String?> requireAdmin(String actionLabel) async {
    final error = guardRole(UserRole.admin, actionLabel: actionLabel);
    if (error != null) {
      await _audit(
        action: 'permission_denied',
        targetType: 'auth',
        details: 'محاولة $actionLabel بدون صلاحية مدير',
        success: false,
        severity: AuditSeverity.critical,
      );
    }
    return error;
  }

  // ─────────────────────────────────────────────────────────
  // إنشاء / تعديل / حذف المستخدمين
  // ─────────────────────────────────────────────────────────

  /// عدد المديرين النشطين حالياً.
  int get activeAdminsCount => _storage
      .loadUsers()
      .where((u) => u.role == UserRole.admin && u.isActive)
      .length;

  Future<String?> createUser({
    required String username,
    required String displayName,
    required String pin,
    required UserRole role,
    String avatarEmoji = '👤',
  }) async {
    final denied = await requireAdmin('إنشاء مستخدم');
    if (denied != null) return denied;

    if (username.trim().isEmpty || displayName.trim().isEmpty) {
      return 'اسم الدخول والاسم الكامل مطلوبان';
    }
    if (pin.trim().length < 4) {
      return 'الرمز السري يجب ألا يقل عن 4 أرقام';
    }
    final exists =
        _storage.loadUsers().any((u) => u.username == username.trim());
    if (exists) return 'اسم الدخول مستخدم مسبقاً';

    final hashed = hashPin(pin);
    final user = UserAccount(
      id: 'U${DateTime.now().millisecondsSinceEpoch}',
      username: username.trim(),
      displayName: displayName.trim(),
      pinHash: hashed.hash,
      pinSalt: hashed.salt,
      role: role,
      isActive: true,
      createdAt: DateTime.now(),
      avatarEmoji: avatarEmoji,
    );
    await _storage.addUser(user);
    await _audit(
      action: 'user_created',
      targetType: 'user',
      targetId: user.id,
      details: 'إنشاء حساب ${user.displayName} بصلاحية ${role.label}',
    );
    return null;
  }

  Future<String?> updateUserPin(String userId, String newPin) async {
    final current = getCurrentUser();
    final isSelf = current?.id == userId;
    if (!isSelf) {
      final denied = await requireAdmin('تغيير رمز مستخدم آخر');
      if (denied != null) return denied;
    }
    if (newPin.trim().length < 4) {
      return 'الرمز السري يجب ألا يقل عن 4 أرقام';
    }
    final users = _storage.loadUsers();
    final idx = users.indexWhere((u) => u.id == userId);
    if (idx < 0) return 'المستخدم غير موجود';

    final hashed = hashPin(newPin);
    await _storage.updateUser(
      users[idx].copyWith(pinHash: hashed.hash, pinSalt: hashed.salt),
    );
    await _audit(
      action: isSelf ? 'pin_changed_self' : 'pin_changed_by_admin',
      targetType: 'user',
      targetId: userId,
      details: isSelf ? 'تغيير المستخدم رمزه السري' : 'تغيير المدير رمز مستخدم',
      severity: isSelf ? AuditSeverity.info : AuditSeverity.warning,
    );
    return null;
  }

  /// يغيّر صلاحية مستخدم. يمنع تخفيض آخر مدير نشط.
  Future<String?> changeUserRole(String userId, UserRole newRole) async {
    final denied = await requireAdmin('تغيير صلاحيات مستخدم');
    if (denied != null) return denied;

    final users = _storage.loadUsers();
    final idx = users.indexWhere((u) => u.id == userId);
    if (idx < 0) return 'المستخدم غير موجود';

    final target = users[idx];
    if (target.role == UserRole.admin &&
        newRole != UserRole.admin &&
        activeAdminsCount <= 1) {
      await _audit(
        action: 'role_change_blocked',
        targetType: 'user',
        targetId: userId,
        details: 'محاولة تخفيض آخر مدير نشط',
        success: false,
        severity: AuditSeverity.critical,
      );
      return 'لا يمكن تخفيض آخر مدير نشط في النظام. أنشئ مديراً آخر أولاً';
    }

    await _storage.updateUser(target.copyWith(role: newRole));
    await _audit(
      action: 'role_changed',
      targetType: 'user',
      targetId: userId,
      details: 'تغيير صلاحية ${target.displayName} إلى ${newRole.label}',
      severity: AuditSeverity.warning,
    );
    return null;
  }

  /// يعطّل أو يفعّل حساباً. لا يعطّل آخر مدير ولا الحساب الحالي.
  Future<String?> toggleUserStatus(String userId) async {
    final denied = await requireAdmin('تغيير حالة مستخدم');
    if (denied != null) return denied;

    final users = _storage.loadUsers();
    final idx = users.indexWhere((u) => u.id == userId);
    if (idx < 0) return 'المستخدم غير موجود';
    final target = users[idx];

    if (target.isActive &&
        target.role == UserRole.admin &&
        activeAdminsCount <= 1) {
      return 'لا يمكن تعطيل آخر مدير نشط في النظام';
    }

    await _storage.updateUser(target.copyWith(isActive: !target.isActive));
    await _audit(
      action: target.isActive ? 'user_deactivated' : 'user_activated',
      targetType: 'user',
      targetId: userId,
      details: '${target.isActive ? 'تعطيل' : 'تفعيل'} حساب ${target.displayName}',
      severity: AuditSeverity.warning,
    );
    return null;
  }

  /// يحذف حساباً. يمنع حذف آخر مدير وحذف الحساب الجاري استخدامه.
  Future<String?> deleteUser(String userId) async {
    final denied = await requireAdmin('حذف مستخدم');
    if (denied != null) return denied;

    final current = getCurrentUser();
    if (current?.id == userId) {
      await _audit(
        action: 'user_delete_blocked',
        targetType: 'user',
        targetId: userId,
        details: 'محاولة حذف الحساب الحالي أثناء استخدامه',
        success: false,
        severity: AuditSeverity.critical,
      );
      return 'لا يمكن حذف الحساب الذي تستخدمه الآن. سجّل الخروج بحساب مدير آخر';
    }

    final users = _storage.loadUsers();
    final idx = users.indexWhere((u) => u.id == userId);
    if (idx < 0) return 'المستخدم غير موجود';
    final target = users[idx];

    if (target.role == UserRole.admin && activeAdminsCount <= 1) {
      await _audit(
        action: 'user_delete_blocked',
        targetType: 'user',
        targetId: userId,
        details: 'محاولة حذف آخر مدير نشط',
        success: false,
        severity: AuditSeverity.critical,
      );
      return 'لا يمكن حذف آخر مدير نشط في النظام. أنشئ مديراً آخر أولاً';
    }

    await _storage.deleteUser(userId);
    await _audit(
      action: 'user_deleted',
      targetType: 'user',
      targetId: userId,
      details: 'حذف حساب ${target.displayName} (${target.role.label})',
      severity: AuditSeverity.critical,
    );
    return null;
  }

  // ─────────────────────────────────────────────────────────
  // التدقيق
  // ─────────────────────────────────────────────────────────

  /// يسجل سطراً في سجل التدقيق ببصمة الجلسة الحالية.
  ///
  /// [actor] يُمرر صراحة في أحداث الدخول حيث لم تُربط الجلسة بعد.
  Future<void> _audit({
    required String action,
    String? targetType,
    String? targetId,
    String details = '',
    bool success = true,
    AuditSeverity severity = AuditSeverity.info,
    UserAccount? actor,
  }) async {
    final resolvedId = actor?.id ?? _storage.getAuditActor().id;
    final resolvedName = actor?.displayName ?? _storage.getAuditActor().name;
    final resolvedRole = actor?.role.toJson ?? _storage.getAuditActor().role;

    await _storage.recordAudit(
      AuditLogEntry(
        id: 'AUD_${DateTime.now().microsecondsSinceEpoch}',
        timestamp: DateTime.now(),
        actorId: resolvedId,
        actorName: resolvedName,
        actorRole: resolvedRole,
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

// ─────────────────────────────────────────────────────────
// نتيجة تسجيل الدخول
// ─────────────────────────────────────────────────────────

class LoginResult {
  final UserAccount? user;
  final String? errorMessage;
  bool get isSuccess => user != null;

  LoginResult._({this.user, this.errorMessage});

  factory LoginResult.success(UserAccount user) => LoginResult._(user: user);

  factory LoginResult.error(String message) =>
      LoginResult._(errorMessage: message);
}
