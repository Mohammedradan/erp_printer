import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:erp_printer/providers/erp_provider.dart';
import 'package:erp_printer/services/storage_service.dart';

void main() {
  group('اختبار دورة عمل نظام المطبعة المتكامل (End-to-End Workflow)', () {
    late ErpProvider erp;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init(firstRunMode: 'demo');
      erp = ErpProvider(storage);
    });

    test('دورة حياة العمل: تسعير -> عرض سعر -> اعتماد -> أمر إنتاج -> صرف ورق -> تحصيل دفعة -> تقرير الربحية', () async {
      // 1. التحقق من جاهزية البيانات الأولية من الإكسل
      expect(erp.papers.length, 18);
      expect(erp.machines.length, 3);
      expect(erp.products.length, 4);
      expect(erp.finishings.length, 12);
      expect(erp.inks.length, 5);

      final customer = erp.customers.first;
      final initialDebt = customer.currentBalance;
      final initialPaperBalance = erp.papers.first.balance;

      // 2. إنشاء عرض سعر جديد لطباعة 100 كتاب A5
      final quote = await erp.addQuotation(
        customerId: customer.id,
        customerCode: customer.code,
        customerName: customer.name,
        product: 'كتاب A5',
        qty: 100,
        pages: 64,
        paper: 'أوفست أبيض 70جم',
        machine: 'أوفست 50x35',
        unitPrice: 350.0,
        totalCost: 120000.0,
        quoteAmount: 175000.0,
        profit: 55000.0,
        status: 'مسودة',
      );

      expect(quote.number, startsWith('Q-'));
      expect(erp.quotations.first.id, quote.id);

      // 3. اعتماد العرض -> يجب أن يولد أمر إنتاج ويحدث مبيعات العميل
      final initialOrdersCount = erp.productionOrders.length;
      final approval = await erp.updateQuotationStatus(quote.id, 'معتمد');

      expect(approval.isSuccess, true);
      expect(erp.quotations.first.status, 'معتمد');
      expect(erp.productionOrders.length, initialOrdersCount + 1);
      final newOrder = erp.productionOrders.first;
      expect(newOrder.quotationId, quote.id);
      expect(newOrder.status, 'معتمد');

      // ذمة العميل زادت بقيمة العرض المعتمد
      final updatedCustomer = erp.customers.firstWhere((c) => c.id == customer.id);
      expect(updatedCustomer.currentBalance, initialDebt + 175000.0);

      // 4. صرف الورق لأمر الإنتاج -> يجب تسجيل حركة خروج وخصم رصيد الورق
      final initialMovesCount = erp.stockMoves.length;
      final deduction = await erp.deductPaperForOrder(newOrder.id);
      expect(deduction.isSuccess, true);

      // التأكد من تسجيل حركة المخزون
      expect(erp.stockMoves.length, initialMovesCount + 1);
      final move = erp.stockMoves.first;
      expect(move.moveType, 'خروج');
      expect(move.reference, contains(newOrder.number));

      // التأكد من خصم الرصيد
      final updatedPaper = erp.papers.first;
      expect(updatedPaper.balance, lessThan(initialPaperBalance));

      // التأكد من تحديث حالة الأمر إلى قيد الإنتاج
      expect(erp.productionOrders.first.isPaperDeducted, true);
      expect(erp.productionOrders.first.status, 'قيد الإنتاج');

      // 5. تسجيل سند قبض (تحصيل دفعة من العميل) بمبلغ 100,000 ريال
      final initialPaymentsCount = erp.payments.length;
      await erp.recordPayment(
        customerId: customer.id,
        amount: 100000.0,
        paymentMethod: 'تحويل بنكي',
        reference: 'حوالة سداد دفعة',
      );

      expect(erp.payments.length, initialPaymentsCount + 1);
      final customerAfterPayment = erp.customers.firstWhere((c) => c.id == customer.id);
      expect(customerAfterPayment.currentBalance, (initialDebt + 175000.0) - 100000.0);

      // 6. التحقق من مؤشرات الربحية
      expect(erp.totalApprovedSales, greaterThan(0));
      expect(erp.totalProfit, greaterThan(0));
      expect(erp.overallMarginPct, greaterThan(0));
      expect(erp.totalInventoryValue, greaterThan(0));
    });
  });
}
