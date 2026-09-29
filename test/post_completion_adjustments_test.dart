import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:erp_printer/models/app_models.dart';
import 'package:erp_printer/providers/erp_provider.dart';
import 'package:erp_printer/services/storage_service.dart';

/// ينشئ أمر إنتاج معتمداً (من عرض معتمد) لمادة ورقية من P01 وأخرى من P06،
/// ويعيد أحدث أمر إنتاج (الإدراج يكون في مقدمة القائمة).
Future<ProductionOrder> _createApprovedOrder(ErpProvider erp, String name) async {
  final innerPaper = erp.papers.firstWhere((paper) => paper.id == 'P01');
  final coverPaper = erp.papers.firstWhere((paper) => paper.id == 'P06');
  final machine = erp.machines.first;
  final customer = erp.customers.last;

  final pricing = erp.calculateBookPrice(
    productName: name,
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
  return erp.productionOrders.first;
}

void main() {
  group('الصرف الاستثنائي مع عجز والتعديلات بعد الإكمال', () {
    late ErpProvider erp;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      erp = ErpProvider(storage);
    });

    test('معاينة الصرف تكشف العجز قبل التنفيذ', () async {
      final order = await _createApprovedOrder(erp, 'كتاب اختبار المعاينة');
      await erp.addStockMove(
        moveType: 'تسوية',
        paperId: 'P01',
        qtySheets: 2,
        unitPrice: 120,
        reference: 'جرد اختبار',
      );

      final lines = erp.paperIssuancePreview(order.id);
      expect(lines, isNotEmpty);
      final p01Line = lines.firstWhere((line) => line.materialId == 'P01');
      expect(p01Line.availableQty, 2);
      expect(p01Line.requiredQty, greaterThan(2));
      expect(p01Line.hasDeficit, isTrue);
      expect(p01Line.deficit, greaterThan(0));

      final p06Line = lines.firstWhere((line) => line.materialId == 'P06');
      expect(p06Line.hasDeficit, isFalse);
    });

    test('الصرف الاستثنائي الموثق يُنجز الصرف وينزل الرصيد تحت الصفر كسجل تدقيق', () async {
      final order = await _createApprovedOrder(erp, 'كتاب اختبار الصرف الاستثنائي');
      await erp.addStockMove(
        moveType: 'تسوية',
        paperId: 'P01',
        qtySheets: 2,
        unitPrice: 120,
        reference: 'جرد اختبار',
      );
      final paper = erp.papers.firstWhere((p) => p.id == 'P01');

      // الصرف العادي يُرفض وتعرض الرسالة تفاصيل العجز (المتاح والمطلوب).
      final normal = await erp.deductPaperForOrder(order.id);
      expect(normal.isSuccess, isFalse);
      expect(normal.message, contains('عجز'));
      expect(normal.message, contains('المتاح 2'));

      // الصرف الاستثنائي بلا سبب موثق يُرفض.
      final noReason = await erp.deductPaperForOrder(order.id, allowDeficit: true, deficitReason: '   ');
      expect(noReason.isSuccess, isFalse);
      expect(noReason.message, contains('سبباً موثقاً'));

      // الصرف الاستثنائي الموثق ينجح ولو نقص الرصيد.
      final result = await erp.deductPaperForOrder(
        order.id,
        allowDeficit: true,
        deficitReason: 'استمرار عاجل لأمر عميل مهم',
        approvedBy: 'مدير الاختبار',
      );
      expect(result.isSuccess, isTrue);
      expect(order.areAllMaterialsIssued, isTrue);
      expect(order.status, 'قيد الإنتاج');
      expect(paper.balance, lessThan(0));

      final deficitMoves = erp.stockMoves
          .where((move) => move.notes?.contains('صرف استثنائي بعجز') ?? false)
          .toList();
      expect(deficitMoves, isNotEmpty);
      final p01Move = deficitMoves.firstWhere((move) => move.paperId == 'P01');
      expect(p01Move.moveType, 'خروج');
      expect(p01Move.qtySheets, greaterThan(2));
      expect(p01Move.notes, contains('استمرار عاجل لأمر عميل مهم'));
      expect(p01Move.notes, contains('اعتمده: مدير الاختبار'));

      // تسوية الجرد لاحقاً تعيد الرصيد إلى الواقع الفعلي.
      await erp.addStockMove(
        moveType: 'تسوية',
        paperId: 'P01',
        qtySheets: 50,
        unitPrice: 120,
        reference: 'جرد تصحيحي بعد صرف استثنائي',
      );
      expect(paper.balance, 50);
    });

    test('إرجاع الفائض بعد اكتمال الأمر يخفض المطلوب مع المصروف ويحافظ على الاستيفاء', () async {
      final order = await _createApprovedOrder(erp, 'كتاب اختبار الفائض');
      expect((await erp.deductPaperForOrder(order.id)).isSuccess, isTrue);
      expect((await erp.updateProductionOrderStatus(order.id, 'مكتمل')).isSuccess, isTrue);

      final material = order.materialRequirements.firstWhere((m) => m.materialId == 'P01');
      final paper = erp.papers.firstWhere((p) => p.id == 'P01');
      final balanceBefore = paper.balance;
      final issuedBefore = material.quantityIssued;
      expect(issuedBefore, greaterThan(5));

      final result = await erp.returnProductionMaterial(
        orderId: order.id,
        materialRequirementId: material.id,
        quantity: 5,
        notes: 'فائض ورق متين لم يُستهلك',
      );
      expect(result.isSuccess, isTrue);
      // الأمر يبقى مكتملاً مكتملاً الاستيفاء ويعكس الاستهلاك الفعلي.
      expect(order.status, 'مكتمل');
      expect(material.quantityIssued, closeTo(issuedBefore - 5, 0.0001));
      expect(material.quantityRequired, closeTo(issuedBefore - 5, 0.0001));
      expect(order.areAllMaterialsIssued, isTrue);
      expect(paper.balance, closeTo(balanceBefore + 5, 0.0001));

      final surplusMove = erp.stockMoves.firstWhere(
        (move) => move.notes?.contains('إرجاع فائض بعد اكمال أمر الإنتاج') ?? false,
      );
      expect(surplusMove.moveType, 'دخول');
      expect(surplusMove.qtySheets, 5);
      expect(surplusMove.reference, contains('إرجاع فائض بعد الإكمال'));
    });

    test('تسجيل الهالك الفعلي بعد الإكمال يوثق استهلاكاً إضافياً بحركة خروج', () async {
      final order = await _createApprovedOrder(erp, 'كتاب اختبار الهالك');
      expect((await erp.deductPaperForOrder(order.id)).isSuccess, isTrue);
      expect((await erp.updateProductionOrderStatus(order.id, 'مكتمل')).isSuccess, isTrue);

      final material = order.materialRequirements.firstWhere((m) => m.materialId == 'P01');
      final paper = erp.papers.firstWhere((p) => p.id == 'P01');
      final balanceBefore = paper.balance;
      final issuedBefore = material.quantityIssued;

      final result = await erp.recordProductionWaste(
        orderId: order.id,
        materialRequirementId: material.id,
        quantity: 3,
        reason: 'زيادة هالك ماكينة الأوفست',
        recordedBy: 'مدير الاختبار',
      );
      expect(result.isSuccess, isTrue);
      expect(material.quantityIssued, closeTo(issuedBefore + 3, 0.0001));
      expect(material.quantityRequired, closeTo(issuedBefore + 3, 0.0001));
      expect(order.areAllMaterialsIssued, isTrue);
      expect(order.status, 'مكتمل');
      expect(paper.balance, closeTo(balanceBefore - 3, 0.0001));

      final wasteMove = erp.stockMoves.firstWhere(
        (move) => move.notes?.contains('هالك فعلي') ?? false,
      );
      expect(wasteMove.moveType, 'خروج');
      expect(wasteMove.qtySheets, 3);
      expect(wasteMove.reference, contains('هالك فعلي'));
      expect(wasteMove.notes, contains('زيادة هالك ماكينة الأوفست'));
      expect(wasteMove.notes, contains('سجّله: مدير الاختبار'));
    });

    test('ضوابط رفض تسجيل الهالك والصرف الاستثنائي غير الموثق', () async {
      final order = await _createApprovedOrder(erp, 'كتاب اختبار الضوابط');
      final material = order.materialRequirements.firstWhere((m) => m.materialId == 'P01');

      // كمية غير موجبة أو سبب فارغ يُرفضان.
      expect(
        (await erp.recordProductionWaste(
          orderId: order.id,
          materialRequirementId: material.id,
          quantity: 0,
          reason: 'سبب',
        ))
            .isSuccess,
        isFalse,
      );
      expect(
        (await erp.recordProductionWaste(
          orderId: order.id,
          materialRequirementId: material.id,
          quantity: 3,
          reason: '   ',
        ))
            .isSuccess,
        isFalse,
      );
      // أمر معتمد لم يبدأ إنتاجه لا يُسجل عليه هالك.
      expect(
        (await erp.recordProductionWaste(
          orderId: order.id,
          materialRequirementId: material.id,
          quantity: 3,
          reason: 'سبب',
        ))
            .isSuccess,
        isFalse,
      );

      // صرف استثنائي بلا سبب يُرفض حتى مع تفعيل الخيار.
      await erp.addStockMove(
        moveType: 'تسوية',
        paperId: 'P01',
        qtySheets: 1,
        unitPrice: 120,
        reference: 'جرد اختبار',
      );
      final noReason = await erp.deductPaperForOrder(order.id, allowDeficit: true, deficitReason: '');
      expect(noReason.isSuccess, isFalse);

      // الصرف العادي مع العجز يبقى مرفوضاً بالسلوك المحافظ الافتراضي.
      final normal = await erp.deductPaperForOrder(order.id);
      expect(normal.isSuccess, isFalse);
      expect(normal.message, contains('عجز'));
    });

    test('تسجيل هالك يتطلب رصيداً كافياً ولا ينزل الصنف تحت الصفر', () async {
      final order = await _createApprovedOrder(erp, 'كتاب اختبار رصيد الهالك');
      expect((await erp.deductPaperForOrder(order.id)).isSuccess, isTrue);
      expect((await erp.updateProductionOrderStatus(order.id, 'مكتمل')).isSuccess, isTrue);
      final material = order.materialRequirements.firstWhere((m) => m.materialId == 'P01');

      await erp.addStockMove(
        moveType: 'تسوية',
        paperId: 'P01',
        qtySheets: 1,
        unitPrice: 120,
        reference: 'جرد اختبار',
      );

      final result = await erp.recordProductionWaste(
        orderId: order.id,
        materialRequirementId: material.id,
        quantity: 5,
        reason: 'سبب',
      );
      expect(result.isSuccess, isFalse);
      expect(result.message, contains('غير كافٍ'));
      expect(erp.papers.firstWhere((p) => p.id == 'P01').balance, 1);
    });
  });
}
