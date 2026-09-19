import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:erp_printer/main.dart';
import 'package:erp_printer/providers/erp_provider.dart';
import 'package:erp_printer/providers/auth_provider.dart';
import 'package:erp_printer/models/app_models.dart';
import 'package:erp_printer/services/auth_service.dart';
import 'package:erp_printer/services/storage_service.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    final authService = AuthService(storage);
    await authService.createUser(
      username: 'test_admin',
      displayName: 'مدير الاختبار',
      pin: '1234',
      role: UserRole.admin,
    );
    final user = storage.loadUsers().first;
    await authService.login(user.id, '1234');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ErpProvider(storage)),
          ChangeNotifierProvider(
            create: (_) => AuthProvider(authService, storage),
          ),
        ],
        child: const MatbaaErpApp(),
      ),
    );

    await tester.pumpAndSettle();

    // التحقق من ظهور لوحة المؤشرات
    expect(find.text('لوحة المؤشرات التفاعلية'), findsOneWidget);
  });
}
