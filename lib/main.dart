import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/erp_provider.dart';
import 'providers/auth_provider.dart';
import 'services/storage_service.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'views/login_view.dart';
import 'views/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storageService = await StorageService.init();
  final authService = AuthService(storageService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ErpProvider(storageService)),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService, storageService),
        ),
      ],
      child: const MatbaaErpApp(),
    ),
  );
}

class MatbaaErpApp extends StatelessWidget {
  const MatbaaErpApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return MaterialApp(
      title: 'نظام مطبعة ERP المتكامل',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      // إذا كان المستخدم مسجّل دخول، ابدأ بالتطبيق مباشرة
      home: auth.isLoggedIn ? const MainLayout() : const LoginView(),
    );
  }
}
