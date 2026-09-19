import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:erp_printer/models/app_models.dart';
import 'package:erp_printer/providers/erp_provider.dart';
import 'package:erp_printer/services/storage_service.dart';

void main() {
  group('ضوابط سلامة المخزون والاعتماد المالي', () {
    late ErpProvider erp;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      erp = ErpProvider(storage);
    });

    test('أمر الكتاب يصرف ورق المتن والغلاف من صنفين منفصلين', () async {
      final innerPaper = erp.papers.firstWhere((paper) => paper.id == 'P01');
      final coverPaper = erp.papers.firstWhere((paper) => paper.id == 'P06');
      final machine = erp.machines.first;
      final customer = erp.customers.last;
      final innerBefore = innerPaper.balance;
      final coverBefore = coverPaper.balance;

      final pricing = erp.calculateBookPrice(
        productName: 'كتاب اختبار متعدد الخامات',
        pages: 16,
        pagesPerSignature: 8,
        qty: 10,
        innerPaper: innerPaper,
        machine: machine,
        innerColors: 1,
        coverPaper: coverPaper,
        coverFitsPerSheet: 4,
        coverColors: 4,
        coverLamination: false,
        bindingType: 'دبوس',
        selectedFinishingIds: const [],
      );

      expect(pricing.materialRequirements, hasLength(2));
      expect(pricing.materialRequirements.map((item) => item.materialId), containsAll(['P01', 'P06']));

      final quote = await erp.addQuotation(
        customerId: customer.id,
        customerCode: customer.code,
        customerName: customer.name,
        product: pricing.productName,
        qty: pricing.qty,
        pages: pricing.pages,
        paper: '${innerPaper.displayName} + ${coverPaper.displayName}',
        machine: machine.name,
        unitPrice: pricing.unitPrice,
        totalCost: pricing.lineTotalCost,
        quoteAmount: pricing.lineAmount,
        profit: pricing.profit,
        pricingDetails: pricing,
      );

      final approval = await erp.updateQuotationStatus(quote.id, 'معتمد');
      expect(approval.isSuccess, isTrue);
      final order = erp.productionOrders.first;
      expect(order.materialRequirements, hasLength(2));
      expect(order.materialRequirements.every((item) => item.quantityIssued == 0), isTrue);

      final issuance = await erp.deductPaperForOrder(order.id);
      expect(issuance.isSuccess, isTrue);
      expect(order.areAllMaterialsIssued, isTrue);
      expect(erp.stockMoves.where((move) => move.reference?.contains(order.number) ?? false), hasLength(2));
      expect(innerPaper.balance, lessThan(innerBefore));
      expect(coverPaper.balance, lessThan(coverBefore));
    });

    test('إرجاع مواد أمر الإنتاج يعيد الرصيد ويسمح بإلغاء العرض بعد التصفير', () async {
      final innerPaper = erp.papers.firstWhere((paper) => paper.id == 'P01');
      final coverPaper = erp.papers.firstWhere((paper) => paper.id == 'P06');
      final machine = erp.machines.first;
      final customer = erp.customers.last;
      final customerBalanceBefore = customer.currentBalance;
      final balancesBefore = <String, double>{
        innerPaper.id: innerPaper.balance,
        coverPaper.id: coverPaper.balance,
      };
      final pricing = erp.calculateBookPrice(
        productName: 'كتاب اختبار إرجاع المواد',
        pages: 16,
        pagesPerSignature: 8,
        qty: 10,
        innerPaper: innerPaper,
        machine: machine,
        innerColors: 1,
        coverPaper: coverPaper,
        coverFitsPerSheet: 4,
        coverColors: 4,
        coverLamination: false,
        bindingType: 'دبوس',
        selectedFinishingIds: const [],
      );
      final quote = await erp.addQuotation(
        customerId: customer.id,
        customerCode: customer.code,
        customerName: customer.name,
        product: pricing.productName,
        qty: pricing.qty,
        pages: pricing.pages,
        paper: '${innerPaper.displayName} + ${coverPaper.displayName}',
        machine: machine.name,
        unitPrice: pricing.unitPrice,
        totalCost: pricing.lineTotalCost,
        quoteAmount: pricing.lineAmount,
        profit: pricing.profit,
        pricingDetails: pricing,
      );
      expect((await erp.updateQuotationStatus(quote.id, 'معتمد')).isSuccess, isTrue);
      final order = erp.productionOrders.first;
      expect((await erp.deductPaperForOrder(order.id)).isSuccess, isTrue);
      expect(order.status, 'قيد الإنتاج');
      expect(
        (await erp.returnProductionMaterial(
          orderId: order.id,
          materialRequirementId: order.materialRequirements.first.id,
          quantity: 1,
        ))
            .isSuccess,
        isFalse,
      );

      for (final material in List<ProductionMaterialRequirement>.from(order.materialRequirements)) {
        expect(
          (await erp.returnProductionMaterial(
            orderId: order.id,
            materialRequirementId: material.id,
            quantity: material.quantityIssued,
            notes: 'إلغاء تشغيل قبل الطباعة',
          ))
              .isSuccess,
          isTrue,
        );
      }

      expect(order.status, 'معتمد');
      expect(order.isPaperDeducted, isFalse);
      expect(order.materialRequirements.every((item) => item.quantityIssued == 0), isTrue);
      expect(innerPaper.balance, balancesBefore[innerPaper.id]);
      expect(coverPaper.balance, balancesBefore[coverPaper.id]);
      expect(
        erp.stockMoves.where((move) => move.reference?.contains('إرجاع مواد') ?? false),
        hasLength(2),
      );
      expect((await erp.updateQuotationStatus(quote.id, 'ملغي')).isSuccess, isTrue);
      expect(customer.currentBalance, customerBalanceBefore);
    });

    test('فشل صرف خامة واحدة لا يخصم أي خامة أخرى من الأمر متعدد المواد', () async {
      final innerPaper = erp.papers.firstWhere((paper) => paper.id == 'P01');
      final coverPaper = erp.papers.firstWhere((paper) => paper.id == 'P06');
      final machine = erp.machines.first;
      final customer = erp.customers.last;
      final innerBefore = innerPaper.balance;

      // كمية الغلاف المطلوبة في هذا السيناريو أكبر من فرخ واحد.
      expect(
        (await erp.addStockMove(
          moveType: 'تسوية',
          paperId: coverPaper.id,
          qtySheets: 1,
          unitPrice: coverPaper.sheetPrice,
          notes: 'تهيئة اختبار فشل الصرف الذري',
        ))
            .isSuccess,
        isTrue,
      );
      final pricing = erp.calculateBookPrice(
        productName: 'كتاب لا يجب أن يصرف جزئياً',
        pages: 16,
        pagesPerSignature: 8,
        qty: 10,
        innerPaper: innerPaper,
        machine: machine,
        innerColors: 1,
        coverPaper: coverPaper,
        coverFitsPerSheet: 4,
        coverColors: 4,
        coverLamination: false,
        bindingType: 'دبوس',
        selectedFinishingIds: const [],
      );
      final quote = await erp.addQuotation(
        customerId: customer.id,
        customerCode: customer.code,
        customerName: customer.name,
        product: pricing.productName,
        qty: pricing.qty,
        pages: pricing.pages,
        paper: '${innerPaper.displayName} + ${coverPaper.displayName}',
        machine: machine.name,
        unitPrice: pricing.unitPrice,
        totalCost: pricing.lineTotalCost,
        quoteAmount: pricing.lineAmount,
        profit: pricing.profit,
        pricingDetails: pricing,
      );
      expect((await erp.updateQuotationStatus(quote.id, 'معتمد')).isSuccess, isTrue);
      final order = erp.productionOrders.first;

      final issuance = await erp.deductPaperForOrder(order.id);
      expect(issuance.isSuccess, isFalse);
      expect(innerPaper.balance, innerBefore);
      expect(coverPaper.balance, 1);
      expect(order.materialRequirements.every((item) => item.quantityIssued == 0), isTrue);
      expect(
        erp.stockMoves.any((move) => move.reference?.contains(order.number) ?? false),
        isFalse,
      );
    });

    test('أمر NCR متعدد الألوان يصرف كل طبقة من صنفها الصحيح', () async {
      final white = erp.papers.firstWhere((paper) => paper.id == 'P16');
      final pink = erp.papers.firstWhere((paper) => paper.id == 'P17');
      final yellow = erp.papers.firstWhere((paper) => paper.id == 'P18');
      final machine = erp.machines.first;
      final customer = erp.customers.last;
      final before = {for (final paper in [white, pink, yellow]) paper.id: paper.balance};

      final pricing = erp.calculateNcrPrice(
        productName: 'دفتر NCR ثلاثي النسخ',
        ncrCopies: 3,
        sheetsPerBook: 50,
        booksCount: 10,
        papersPerColor: [white, pink, yellow],
        setsPerSheet: 16,
        machine: machine,
        colorsCount: 1,
        hasNumbering: true,
        hasAssemblyAndBinding: true,
        selectedFinishingIds: const [],
      );

      expect(pricing.materialRequirements, hasLength(3));
      final quote = await erp.addQuotation(
        customerId: customer.id,
        customerCode: customer.code,
        customerName: customer.name,
        product: pricing.productName,
        qty: pricing.qty,
        pages: 0,
        ncrCopies: 3,
        paper: 'NCR أبيض + وردي + أصفر',
        machine: machine.name,
        unitPrice: pricing.unitPrice,
        totalCost: pricing.lineTotalCost,
        quoteAmount: pricing.lineAmount,
        profit: pricing.profit,
        pricingDetails: pricing,
      );

      expect((await erp.updateQuotationStatus(quote.id, 'معتمد')).isSuccess, isTrue);
      final order = erp.productionOrders.first;
      expect(order.materialRequirements.map((item) => item.materialId), containsAll(['P16', 'P17', 'P18']));

      expect((await erp.deductPaperForOrder(order.id)).isSuccess, isTrue);
      for (final paper in [white, pink, yellow]) {
        expect(paper.balance, lessThan(before[paper.id]!));
      }
    });

    test('لا يسمح بالصرف الذي يجعل مخزون الورق سالباً', () async {
      final paper = erp.papers.first;
      final before = paper.balance;

      final result = await erp.addStockMove(
        moveType: 'خروج',
        paperId: paper.id,
        qtySheets: before + 1,
        unitPrice: paper.sheetPrice,
      );

      expect(result.isSuccess, isFalse);
      expect(paper.balance, before);
      expect(erp.stockMoves.any((move) => move.qtySheets == before + 1), isFalse);
    });

    test('عكس حركة المخزون ينشئ قيداً مقابلاً ولا يحذف الأصل', () async {
      final paper = erp.papers.first;
      final balanceBefore = paper.balance;
      final movesCountBefore = erp.stockMoves.length;

      expect(
        (await erp.addStockMove(
          moveType: 'دخول',
          paperId: paper.id,
          qtySheets: 10,
          unitPrice: paper.sheetPrice,
          reference: 'توريد اختبار',
        ))
            .isSuccess,
        isTrue,
      );
      final originalMove = erp.stockMoves.first;
      expect(paper.balance, balanceBefore + 10);

      final reversal = await erp.reverseStockMove(originalMove.id);
      expect(reversal.isSuccess, isTrue);
      expect(erp.stockMoves, hasLength(movesCountBefore + 2));
      expect(paper.balance, balanceBefore);
      final reversalMove = erp.stockMoves.first;
      expect(reversalMove.moveType, 'خروج');
      expect(reversalMove.reversalOfId, originalMove.id);
      expect((await erp.reverseStockMove(originalMove.id)).isSuccess, isFalse);
      expect((await erp.deleteStockMove(originalMove.id)).isSuccess, isFalse);
    });

    test('تعديل الرصيد الافتتاحي ينشئ قيد تسوية ويبقي كشف الحساب مطابقاً للرصيد', () async {
      final customer = erp.customers.last;
      final balanceBefore = customer.currentBalance;
      final updatedCustomer = Customer(
        id: customer.id,
        code: customer.code,
        name: customer.name,
        phone: customer.phone,
        address: customer.address,
        openingBalance: customer.openingBalance + 2500,
        totalSales: customer.totalSales,
        paid: customer.paid,
      );

      await erp.updateCustomer(updatedCustomer);
      final persistedCustomer = erp.customers.firstWhere((item) => item.id == customer.id);
      final ledger = erp.ledgerForCustomer(customer.id);
      final ledgerBalance = ledger.fold<double>(
        0,
        (sum, entry) => sum + entry.balanceEffect,
      );

      expect(persistedCustomer.currentBalance, balanceBefore + 2500);
      expect(ledgerBalance, persistedCustomer.currentBalance);
      expect(
        ledger.where((entry) => entry.type == 'opening_adjustment'),
        hasLength(1),
      );
    });

    test('إلغاء عرض غير مصروف يعكس قيد العميل ويمنع إعادة الاعتماد', () async {
      final customer = erp.customers.last;
      final startingBalance = customer.currentBalance;
      final startingOrders = erp.productionOrders.length;
      final quote = await erp.addQuotation(
        customerId: customer.id,
        customerCode: customer.code,
        customerName: customer.name,
        product: 'عرض قابل للإلغاء',
        qty: 20,
        pages: 1,
        paper: 'أوفست أبيض',
        machine: erp.machines.first.name,
        unitPrice: 500,
        totalCost: 7000,
        quoteAmount: 10000,
        profit: 3000,
      );

      final approval = await erp.updateQuotationStatus(quote.id, 'معتمد');
      expect(approval.isSuccess, isTrue);
      expect(customer.currentBalance, startingBalance + quote.quoteAmount);
      expect(erp.productionOrders.length, startingOrders + 1);
      // تكرار طلب الاعتماد وهو في الحالة نفسها لا ينشئ أمراً أو قيداً جديداً.
      expect((await erp.updateQuotationStatus(quote.id, 'معتمد')).isSuccess, isTrue);
      expect(erp.productionOrders.length, startingOrders + 1);
      expect(
        erp.ledgerForCustomer(customer.id).where(
          (entry) => entry.type == 'sale' && entry.referenceId == quote.id,
        ),
        hasLength(1),
      );
      expect(
        (await erp.deleteProductionOrder(erp.productionOrders.first.id)).isSuccess,
        isFalse,
      );

      final cancellation = await erp.updateQuotationStatus(quote.id, 'ملغي');
      expect(cancellation.isSuccess, isTrue);
      expect(customer.currentBalance, startingBalance);
      expect(erp.productionOrders.first.status, 'ملغي');
      expect(
        erp.ledgerForCustomer(customer.id).any(
          (entry) => entry.type == 'sale_reversal' && entry.referenceId == quote.id,
        ),
        isTrue,
      );

      final reapproval = await erp.updateQuotationStatus(quote.id, 'معتمد');
      expect(reapproval.isSuccess, isFalse);
      expect(erp.productionOrders.length, startingOrders + 1);
    });
  });
}
