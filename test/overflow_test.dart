import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:erp_printer/main.dart';
import 'package:erp_printer/providers/erp_provider.dart';
import 'package:erp_printer/providers/auth_provider.dart';
import 'package:erp_printer/models/app_models.dart';
import 'package:erp_printer/services/auth_service.dart';
import 'package:erp_printer/services/storage_service.dart';
import 'package:erp_printer/views/login_view.dart';
import 'package:erp_printer/views/main_layout.dart';

Future<void> _testAllTabs(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({});
  final storage = await StorageService.init();
  final provider = ErpProvider(storage);
  final authService = AuthService(storage);
  await authService.createUser(
    username: 'test_admin',
    displayName: 'مدير الاختبار',
    pin: '1234',
    role: UserRole.admin,
  );
  final user = storage.loadUsers().first;
  final authProvider = AuthProvider(authService, storage);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: provider),
        ChangeNotifierProvider<AuthProvider>(create: (_) => authProvider),
      ],
      child: const MatbaaErpApp(),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.byType(LoginView), findsOneWidget);
  expect(tester.takeException(), isNull, reason: 'User-selection layout overflowed at $size');

  await tester.tap(find.text('تسجيل الدخول بالـ PIN'));
  await tester.pumpAndSettle();
  expect(find.text('أدخل رمز المرور السري (PIN)'), findsOneWidget);
  expect(tester.takeException(), isNull, reason: 'PIN-entry layout overflowed at $size');

  await authProvider.login(user.id, '1234');
  await tester.pumpAndSettle();
  expect(find.byType(MainLayout), findsOneWidget);

  final views = [
    ('لوحة المؤشرات', 0),
    ('محرك التسعير الحي', 1),
    ('عروض الأسعار', 2),
    ('أوامر الإنتاج', 3),
    ('قاعدة الورق والمخزون', 4),
    ('مخزون الأحبار', 5),
    ('العملاء وحسابات الذمم', 6),
    ('المدفوعات وسندات القبض', 7),
    ('الماكينات والقوالب والتشطيب', 8),
    ('تقارير الربحية والتحليل', 9),
    ('إعدادات النظام', 10),
    ('إدارة الأسعار والتكاليف', 11),
    ('إدارة المستخدمين', 12),
  ];

  for (final (title, index) in views) {
    debugPrint('Testing tab ($size): $title (index $index)');
    final state = tester.state<MainLayoutState>(find.byType(MainLayout));
    state.setTab(index);
    await tester.pumpAndSettle();
    final error = tester.takeException();
    if (error != null) {
      debugPrint('>>> OVERFLOW DETECTED ON TAB: $title (index $index) <<<');
      throw error;
    }
  }
}

void main() {
  testWidgets('Test all views for overflow issues on mobile portrait (390x844)', (WidgetTester tester) async {
    await _testAllTabs(tester, const Size(390, 844));
  });

  testWidgets('Test all views for overflow issues on tablet portrait (768x1024)', (WidgetTester tester) async {
    await _testAllTabs(tester, const Size(768, 1024));
  });

  testWidgets('Test all views for overflow issues at standard desktop size (1024x768)', (WidgetTester tester) async {
    await _testAllTabs(tester, const Size(1024, 768));
  });

  testWidgets('Test all views for overflow issues at laptop size (1366x768)', (WidgetTester tester) async {
    await _testAllTabs(tester, const Size(1366, 768));
  });

  testWidgets('Test all views for overflow issues at Full HD (1920x1080)', (WidgetTester tester) async {
    await _testAllTabs(tester, const Size(1920, 1080));
  });
}
