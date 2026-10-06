import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:erp_printer/models/app_models.dart';
import 'package:erp_printer/providers/erp_provider.dart';
import 'package:erp_printer/services/storage_service.dart';

void main() {
  group('ErpProvider — صلاحيات التكلفة والتسعير', () {
    late StorageService storage;
    late ErpProvider erp;

    Future<UserAccount> activateUser(UserRole role) async {
      final user = UserAccount(
        id: role == UserRole.admin ? 'ADMIN_1' : 'EMPLOYEE_1',
        username: role == UserRole.admin ? 'admin' : 'employee',
        displayName: role == UserRole.admin ? 'المدير' : 'الموظف',
        pinHash: 'test-hash',
        role: role,
        createdAt: DateTime(2026, 10, 6),
      );
      await storage.addUser(user);
      await storage.setActiveUserId(user.id);
      return user;
    }

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = await StorageService.init(firstRunMode: 'clean');
    });

    test('الموظف لا يستطيع تغيير أسعار الورق أو الماكينات أو ثوابت التسعير', () async {
      await activateUser(UserRole.employee);
      erp = ErpProvider(storage);

      final paper = erp.papers.first;
      final originalPaperPrice = paper.sheetPrice;
      final machine = erp.machines.first;
      final originalHourlyCost = machine.hourlyCost;
      final originalMargin = erp.settings.defaultProfitMarginPct;
      final originalTax = erp.settings.taxPct;
      final changedSettings = AppSettings.fromJson(erp.settings.toJson())
        ..defaultProfitMarginPct = originalMargin + 50;
      final originalPaperCount = erp.papers.length;
      final changedPaper = PaperItem.fromJson(paper.toJson())
        ..sheetPrice = originalPaperPrice + 200;
      final ink = erp.inks.first;
      final originalInkPrice = ink.unitPrice;
      final changedInk = InkItem.fromJson(ink.toJson())
        ..unitPrice = originalInkPrice + 200;

      final paperResult = await erp.updatePaperPrice(paper.id, originalPaperPrice + 500);
      final machineResult = await erp.updateMachineRates(
        machineId: machine.id,
        hourlyCost: originalHourlyCost + 1000,
      );
      final constantsResult = await erp.updatePricingConstants(
        profitMarginPct: originalMargin + 20,
        taxPct: originalTax + 10,
      );
      final settingsResult = await erp.updateSettings(changedSettings);
      final paperObjectResult = await erp.updatePaper(changedPaper);
      final inkObjectResult = await erp.updateInk(changedInk);
      final addPaperResult = await erp.addPaper(PaperItem(
        id: 'P_EMPLOYEE',
        category: 'اختبار',
        paperType: 'أبيض',
        gsm: 80,
        sheetPrice: 25,
      ));

      expect(paperResult.isSuccess, isFalse);
      expect(machineResult.isSuccess, isFalse);
      expect(constantsResult.isSuccess, isFalse);
      expect(settingsResult.isSuccess, isFalse);
      expect(paperObjectResult.isSuccess, isFalse);
      expect(inkObjectResult.isSuccess, isFalse);
      expect(addPaperResult.isSuccess, isFalse);
      expect(erp.papers.length, originalPaperCount);
      expect(erp.papers.first.sheetPrice, originalPaperPrice);
      expect(erp.inks.first.unitPrice, originalInkPrice);
      expect(erp.machines.first.hourlyCost, originalHourlyCost);
      expect(erp.settings.defaultProfitMarginPct, originalMargin);
      expect(erp.settings.taxPct, originalTax);
      expect(erp.auditLog.any((entry) => entry.action == 'authorization_denied'), isTrue);
    });

    test('الموظف يستطيع تسجيل كمية مخزون دون تعديل تكلفة الورق أو الحبر', () async {
      await activateUser(UserRole.employee);
      erp = ErpProvider(storage);

      final paper = erp.papers.first;
      final originalPaperPrice = paper.sheetPrice;
      final paperMove = await erp.addStockMove(
        moveType: 'دخول',
        paperId: paper.id,
        qtySheets: 10,
        unitPrice: 999999,
      );
      expect(paperMove.isSuccess, isTrue);
      expect(erp.papers.first.sheetPrice, originalPaperPrice);
      expect(erp.stockMoves.first.unitPrice, originalPaperPrice);
      expect(erp.stockMoves.first.totalValue, 10 * originalPaperPrice);

      final ink = erp.inks.first;
      final originalInkPrice = ink.unitPrice;
      final inkMove = await erp.addInkMove(
        moveType: 'دخول',
        inkId: ink.id,
        qty: 1,
        unitPrice: 999999,
      );
      expect(inkMove.isSuccess, isTrue);
      expect(erp.inks.first.unitPrice, originalInkPrice);
      expect(erp.inkMoves.first.unitPrice, originalInkPrice);
      expect(erp.inkMoves.first.totalValue, originalInkPrice);
    });

    test('المدير يستطيع تحديث الأسعار والتكلفة', () async {
      await activateUser(UserRole.admin);
      erp = ErpProvider(storage);

      final paper = erp.papers.first;
      final originalPrice = paper.sheetPrice;
      final result = await erp.updatePaperPrice(paper.id, originalPrice + 25);

      expect(result.isSuccess, isTrue);
      expect(erp.papers.first.sheetPrice, originalPrice + 25);
    });

    test('الموظف لا يستطيع تصدير أو استيراد نسخة احتياطية', () async {
      await activateUser(UserRole.employee);
      erp = ErpProvider(storage);

      expect(() => erp.exportDatabaseBackup(), throwsStateError);
      final importResult = await erp.importDatabaseBackup('{"version":1}');
      final restored = await erp.restorePreImportSnapshot();

      expect(importResult.isSuccess, isFalse);
      expect(importResult.errorMessage, contains('المدير'));
      expect(restored, isFalse);
    });
  });
}
