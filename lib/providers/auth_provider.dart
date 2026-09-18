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
    // التحقق من عدم تكرار اسم المستخدم
    if (_users.any((u) => u.username.toLowerCase() == username.toLowerCase())) {
      return 'اسم المستخدم موجود مسبقاً';
    }
    if (pin.length < 4) {
      return 'PIN يجب أن يكون 4 أرقام على الأقل';
    }

    await _authService.createUser(
      username: username,
      displayName: displayName,
      pin: pin,
      role: role,
      avatarEmoji: avatarEmoji,
    );
    _users = _storage.loadUsers();
    notifyListeners();
    return null; // نجاح
  }

  Future<void> updateUser(UserAccount updated) async {
    await _storage.updateUser(updated);
    _users = _storage.loadUsers();
    // تحديث المستخدم الحالي إذا كان هو نفسه
    if (_currentUser?.id == updated.id) {
      _currentUser = updated;
    }
    notifyListeners();
  }

  Future<String?> changeUserPin(String userId, String newPin) async {
    if (newPin.length < 4) return 'PIN يجب أن يكون 4 أرقام على الأقل';
    await _authService.updateUserPin(userId, newPin);
    _users = _storage.loadUsers();
    notifyListeners();
    return null;
  }

  Future<void> toggleUserStatus(String userId) async {
    final users = _storage.loadUsers();
    final idx = users.indexWhere((u) => u.id == userId);
    if (idx >= 0) {
      users[idx] = users[idx].copyWith(isActive: !users[idx].isActive);
      await _storage.saveUsers(users);
      _users = users;
      notifyListeners();
    }
  }

  Future<void> deleteUser(String userId) async {
    await _storage.deleteUser(userId);
    _users = _storage.loadUsers();
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
