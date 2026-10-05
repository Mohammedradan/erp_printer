import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

/// مزوّد حالة المصادقة وإدارة المستخدمين
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final StorageService _storage;

  UserAccount? _currentUser;
  List<UserAccount> _users = [];
  bool _isLoading = false;
  String? _error;

  AuthProvider(this._authService, this._storage) {
    _loadInitialState();
  }

  // ─────────────────────────────────────────────────────────
  // Getters
  // ─────────────────────────────────────────────────────────

  UserAccount? get currentUser => _currentUser;
  List<UserAccount> get users => List.unmodifiable(_users);
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasUsers => _users.isNotEmpty;

  bool get needsFirstSetup => _users.isEmpty;

  // ─────────────────────────────────────────────────────────
  // التهيئة الأولى
  // ─────────────────────────────────────────────────────────

  void _loadInitialState() {
    _users = _storage.loadUsers();
    _currentUser = _authService.getCurrentUser();
  }

  void refresh() {
    _users = _storage.loadUsers();
    _currentUser = _authService.getCurrentUser();
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────
  // تسجيل الدخول والخروج
  // ─────────────────────────────────────────────────────────

  Future<LoginResult> login(String userId, String pin) async {
    _setLoading(true);
    _error = null;

    final result = await _authService.login(userId, pin);

    if (result.isSuccess) {
      _currentUser = result.user;
      _clearError();
    } else {
      _error = result.errorMessage;
    }

    _setLoading(false);
    return result;
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    _clearError();
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────
  // إدارة المستخدمين (Admin فقط)
  // ─────────────────────────────────────────────────────────

  Future<String?> createUser({
    required String username,
    required String displayName,
    required String pin,
    required UserRole role,
    String avatarEmoji = '👤',
  }) async {
    if (_users.any((u) => u.username.toLowerCase() == username.toLowerCase())) {
      return 'اسم المستخدم موجود مسبقاً';
    }
    if (pin.trim().length < 4) {
      return 'PIN يجب أن يكون 4 أرقام على الأقل';
    }

    final error = await _authService.createUser(
      username: username,
      displayName: displayName,
      pin: pin,
      role: role,
      avatarEmoji: avatarEmoji,
    );
    if (error != null) {
      _error = error;
      notifyListeners();
      return error;
    }
    _users = _storage.loadUsers();
    notifyListeners();
    return null;
  }

  Future<String?> updateUser(UserAccount updated) async {
    final denied = await _authService.requireAdmin('تعديل بيانات مستخدم');
    if (denied != null) {
      _error = denied;
      notifyListeners();
      return denied;
    }
    await _storage.updateUser(updated);
    _users = _storage.loadUsers();
    if (_currentUser?.id == updated.id) {
      _currentUser = updated;
      await _authService.attachSession(updated);
    }
    notifyListeners();
    return null;
  }

  Future<String?> changeUserPin(String userId, String newPin) async {
    if (newPin.trim().length < 4) return 'PIN يجب أن يكون 4 أرقام على الأقل';
    final error = await _authService.updateUserPin(userId, newPin);
    if (error != null) {
      _error = error;
      notifyListeners();
      return error;
    }
    _users = _storage.loadUsers();
    notifyListeners();
    return null;
  }

  Future<String?> changeUserRole(String userId, UserRole newRole) =>
      _runGuarded(() => _authService.changeUserRole(userId, newRole));

  Future<String?> toggleUserStatus(String userId) =>
      _runGuarded(() => _authService.toggleUserStatus(userId));

  Future<String?> deleteUser(String userId) =>
      _runGuarded(() => _authService.deleteUser(userId));

  /// ينفّذ عملية محمية: يمرر رسالة الرفض للواجهة ويحدّث القائمة عند النجاح.
  Future<String?> _runGuarded(Future<String?> Function() action) async {
    final error = await action();
    if (error != null) {
      _error = error;
      notifyListeners();
      return error;
    }
    _users = _storage.loadUsers();
    _currentUser = _authService.getCurrentUser();
    notifyListeners();
    return null;
  }

  // ─────────────────────────────────────────────────────────
  // سجل التدقيق
  // ─────────────────────────────────────────────────────────

  /// سجل التدقيق كاملاً (الأحدث أولاً).
  List<AuditLogEntry> get auditLog => _storage.loadAuditLog();

  /// يسجل حدثاً من طبقة الأعمال (يستخدمه ErpProvider للعمليات الحساسة).
  Future<void> audit({
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
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
