import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:erp_printer/main.dart';
import 'package:erp_printer/providers/erp_provider.dart';
import 'package:erp_printer/services/storage_service.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ErpProvider(storage)),
        ],
        child: const MatbaaErpApp(),
      ),
    );

    await tester.pumpAndSettle();

    // التحقق من ظهور لوحة المؤشرات
    expect(find.text('لوحة المؤشرات التفاعلية'), findsOneWidget);
  });
}
