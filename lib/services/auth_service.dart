import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/app_models.dart';
import 'storage_service.dart';

/// خدمة المصادقة: تسجيل الدخول بـ PIN، الجلسات، الصلاحيات
class AuthService {
  final StorageService _storage;

  AuthService(this._storage);

  // ─────────────────────────────────────────────────────────
  // تشفير PIN
  // ─────────────────────────────────────────────────────────

  static String hashPin(String pin) {
    final bytes = utf8.encode(pin.trim());
    return sha256.convert(bytes).toString();
  }

  // ─────────────────────────────────────────────────────────
  // تسجيل الدخول
  // ─────────────────────────────────────────────────────────

  static const int _maxAttempts = 3;
  static const int _lockoutMinutes = 1;

  /// محاولة تسجيل الدخول - يُرجع UserAccount أو null مع رسالة خطأ
  Future<LoginResult> login(String userId, String pin) async {
    final users = _storage.loadUsers();
    UserAccount? user;
    try {
      user = users.firstWhere((u) => u.id == userId);
    } catch (_) {
      return LoginResult.error('المستخدم غير موجود');
    }

    if (!user.isActive) {
      return LoginResult.error('الحساب معطّل، تواصل مع المدير');
    }

    // التحقق من القفل المؤقت
    final lockout = _storage.getLockoutUntil(userId);
    if (lockout != null && DateTime.now().isBefore(lockout)) {
      final remaining = lockout.difference(DateTime.now()).inSeconds;
      return LoginResult.error('محاولات كثيرة. انتظر $remaining ثانية');
    }

    // التحقق من PIN
    final hashed = hashPin(pin);
    if (hashed != user.pinHash) {
      int attempts = _storage.getLoginAttempts(userId) + 1;
      await _storage.setLoginAttempts(userId, attempts);

      if (attempts >= _maxAttempts) {
        final until = DateTime.now().add(
          Duration(minutes: _lockoutMinutes),
        );
        await _storage.setLockoutUntil(userId, until);
        await _storage.setLoginAttempts(userId, 0);
        return LoginResult.error(
          'PIN خاطئ 3 مرات. الحساب مقفول لمدة $_lockoutMinutes دقيقة',
        );
      }

      final remaining = _maxAttempts - attempts;
      return LoginResult.error('PIN خاطئ. محاولات متبقية: $remaining');
    }

    // نجاح - مسح محاولات الفشل وحفظ الجلسة
    await _storage.setLoginAttempts(userId, 0);
    await _storage.setLockoutUntil(userId, null);
    await _storage.setActiveUserId(userId);

    return LoginResult.success(user);
  }

  // ─────────────────────────────────────────────────────────
  // تسجيل الخروج
  // ─────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _storage.setActiveUserId(null);
  }

  // ─────────────────────────────────────────────────────────
  // الجلسة الحالية
  // ─────────────────────────────────────────────────────────

  UserAccount? getCurrentUser() => _storage.getActiveUser();

  bool get isLoggedIn => getCurrentUser() != null;

  // ─────────────────────────────────────────────────────────
  // الصلاحيات
  // ─────────────────────────────────────────────────────────

  bool isAdmin() => getCurrentUser()?.role == UserRole.admin;

  bool hasPermission(UserRole requiredRole) {
    final user = getCurrentUser();
    if (user == null) return false;
    if (requiredRole == UserRole.employee) return true;
    return user.role == UserRole.admin;
  }

  // ─────────────────────────────────────────────────────────
  // إنشاء / تعديل المستخدمين
  // ─────────────────────────────────────────────────────────

  Future<void> createUser({
    required String username,
    required String displayName,
    required String pin,
    required UserRole role,
    String avatarEmoji = '👤',
  }) async {
    final user = UserAccount(
      id: 'U${DateTime.now().millisecondsSinceEpoch}',
      username: username,
      displayName: displayName,
      pinHash: hashPin(pin),
      role: role,
      isActive: true,
      createdAt: DateTime.now(),
      avatarEmoji: avatarEmoji,
    );
    await _storage.addUser(user);
  }

  Future<void> updateUserPin(String userId, String newPin) async {
    final users = _storage.loadUsers();
    final idx = users.indexWhere((u) => u.id == userId);
    if (idx >= 0) {
      users[idx] = users[idx].copyWith(pinHash: hashPin(newPin));
      await _storage.saveUsers(users);
    }
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

  factory LoginResult.success(UserAccount user) =>
      LoginResult._(user: user);

  factory LoginResult.error(String message) =>
      LoginResult._(errorMessage: message);
}
