import 'package:flutter_test/flutter_test.dart';
import 'package:erp_printer/models/app_models.dart';
import 'package:erp_printer/services/pricing_engine_service.dart';

void main() {
  group('اختبارات محرك التسعير (محاكاة حسابات الإكسل)', () {
    test('حساب تسعير كتاب A5 بدقة تطابق معادلات الإكسل', () {
      final product = ProductTemplate(
        id: 'PRD01',
        name: 'كتاب A5',
        category: 'كتب',
        defaultPages: 100,
        pagesPerSheet: 8,
        defaultMachine: 'أوفست 50x35',
        defaultPaperCategory: 'أوفست',
        defaultPaperType: 'أبيض',
      );

      final paper = PaperItem(
        id: 'P01',
        category: 'أوفست',
        paperType: 'أبيض',
        gsm: 70,
        sheetPrice: 100.0,
        sheetsPerUnit: 4,
        reorderLevel: 500,
      );

      final machine = MachineItem(
        id: 'M01',
        name: 'أوفست 50x35',
        kind: 'Offset',
        wastePct: 5.0,
        hourlyCost: 5000.0,
        speedPerHour: 5000,
      );

      final finishing = FinishingItem(
        id: 'F01',
        name: 'تجليد حراري',
        price: 5000.0,
        unit: 'للعملية',
      );

      final result = PricingEngineService.calculate(
        product: product,
        qty: 1000,
        pages: 100,
        ncrCopies: 0,
        sheetsPerBook: 0,
        booksCount: 0,
        colorsCount: 4,
        platesCount: 4,
        plateCost: 1250.0,
        profitMarginPct: 30.0,
        paper: paper,
        machine: machine,
        allFinishings: [finishing],
        selectedFinishingIds: [finishing.id],
      );

      // التحقق من الحسابات:
      // sheets_per_unit = 100 / 8 = 12.5
      expect(result.sheetsPerUnit, 12.5);
      // total_sheets = 12.5 * 1000 = 12500
      expect(result.totalSheets, 12500.0);
      // sheets_with_waste = 12500 * 1.05 = 13125
      expect(result.sheetsWithWaste, 13125.0);
      // full sheets 100x70 to buy = ceil(13125 / 4) = 3282 أفرخ
      // paper_cost = 3282 * 100 = 328,200
      expect(result.paperCost, 328200.0);
      // run_hours = 13125 / 5000 = 2.625
      expect(result.runHours, 2.625);
      // machine_cost = 2.625 * 5000 = 13125
      expect(result.machineCost, 13125.0);
      // plates_cost = 4 * 1250 = 5000
      expect(result.zincCost, 5000.0);
      // finishing_cost = 5000
      expect(result.finishingCost, 5000.0);
      // total_cost = 328200 + 13125 + 5000 + 5000 = 351,325
      expect(result.lineTotalCost, 351325.0);
      // sale amount with 30% margin = round(351325 * 1.3) = 456,723
      expect(result.lineAmount, 456723.0);
      // profit = 456723 - 351325 = 105,398
      expect(result.profit, 105398.0);
    });

    test('حساب تسعير قالب الكتاب المتخصص (الصفحات والملازم والغلاف والتجليد)', () {
      final innerPaper = PaperItem(id: 'P01', category: 'أوفست', paperType: 'أبيض', gsm: 70, sheetPrice: 120.0, sheetsPerUnit: 4);
      final coverPaper = PaperItem(id: 'P06', category: 'كوشيه', paperType: 'لامع', gsm: 300, sheetPrice: 450.0, sheetsPerUnit: 4);
      final machine = MachineItem(id: 'M01', name: 'أوفست 50x35', kind: 'Offset', wastePct: 5.0, hourlyCost: 5000.0, speedPerHour: 5000);
      final bindFin = FinishingItem(id: 'F11', name: 'تجليد حراري', price: 50.0, unit: 'للقطعة');

      final result = PricingEngineService.calculateBookPricing(
        productName: 'كتاب رواية A5',
        pages: 96,
        pagesPerSignature: 8,
        qty: 1000,
        innerPaper: innerPaper,
        machine: machine,
        innerColors: 1,
        coverPaper: coverPaper,
        coverFitsPerSheet: 4,
        coverColors: 4,
        coverLamination: true,
        bindingType: 'حراري',
        bindingFinishing: bindFin,
        allFinishings: [bindFin],
        selectedFinishingIds: [],
        plateCost: 1250.0,
        profitMarginPct: 30.0,
        taxPct: 5.0,
      );

      expect(result.templateType, 'book');
      expect(result.qty, 1000);
      expect(result.pages, 96);
      expect(result.stepDetails.isNotEmpty, true);
      expect(result.stepDetails.length, 7); // 7 خطوات متسلسلة للكتاب
      expect(result.lineTotalCost > 0, true);
      expect(result.profit > 0, true);
      expect(result.taxPct, 5.0);
      expect(result.grandTotalAmount > result.lineAmount, true);
    });

    test('حساب تسعير قالب دفاتر NCR المتخصص مع توزيع الألوان والترقيم والتجميع', () {
      final whitePaper = PaperItem(id: 'P16', category: 'NCR', paperType: 'أبيض', gsm: 55, sheetPrice: 125.0);
      final pinkPaper = PaperItem(id: 'P17', category: 'NCR', paperType: 'وردي', gsm: 55, sheetPrice: 130.0);
      final yellowPaper = PaperItem(id: 'P18', category: 'NCR', paperType: 'أصفر', gsm: 55, sheetPrice: 130.0);
      final machine = MachineItem(id: 'M01', name: 'أوفست 50x35', kind: 'Offset', wastePct: 5.0, hourlyCost: 5000.0, speedPerHour: 5000);

      final result = PricingEngineService.calculateNcrPricing(
        productName: 'سند قبض 3 نسخ',
        ncrCopies: 3,
        sheetsPerBook: 50,
        booksCount: 100,
        papersPerColor: [whitePaper, pinkPaper, yellowPaper],
        setsPerSheet: 16,
        machine: machine,
        colorsCount: 1,
        hasNumbering: true,
        hasAssemblyAndBinding: true,
        allFinishings: [],
        selectedFinishingIds: [],
        plateCost: 1250.0,
        profitMarginPct: 25.0,
      );

      expect(result.templateType, 'ncr');
      expect(result.booksCount, 100);
      expect(result.ncrCopies, 3);
      expect(result.stepDetails.isNotEmpty, true);
      expect(result.unitPrice > 0, true);
      expect(result.lineAmount > result.lineTotalCost, true);
    });

    test('حساب تسعير قالب الكروت الذكي وتوزيع الفرخ (Smart Imposition)', () {
      final imposition = PricingEngineService.calculateImposition(
        sheetWidthCm: 100.0,
        sheetHeightCm: 70.0,
        itemWidthCm: 9.0,
        itemHeightCm: 5.5,
      );

      // فرخ 100x70 بعد خصم الهوامش يعطي حوالي 10x12 = 120 كرت أو ما يقاربها
      expect(imposition.totalItemsPerSheet > 80, true);

      final cardPaper = PaperItem(id: 'P06', category: 'كوشيه', paperType: 'لامع', gsm: 300, sheetPrice: 460.0);
      final machine = MachineItem(id: 'M01', name: 'أوفست 50x35', kind: 'Offset', wastePct: 5.0, hourlyCost: 5000.0, speedPerHour: 5000);

      final result = PricingEngineService.calculateCardPricing(
        productName: 'كروت شخصية فاخرة',
        cardWidthCm: 9.0,
        cardHeightCm: 5.5,
        qty: 1000,
        paper: cardPaper,
        sheetSize: '100x70',
        printSides: 2, // وجهين
        machine: machine,
        colorsCount: 4,
        hasCutting: true,
        hasLamination: true,
        allFinishings: [],
        selectedFinishingIds: [],
        plateCost: 1250.0,
        profitMarginPct: 35.0,
      );

      expect(result.templateType, 'card');
      expect(result.qty, 1000);
      expect(result.stepDetails.isNotEmpty, true);
      expect(result.unitPrice > 0, true);
      expect(result.paperCost > 0, true);
    });

    test('التحقق من المزامنة الحية: تغيير سعر الفرخ وتكلفة الماكينة ينعكس فوراً على الحسابات الجديدة', () {
      final paper1 = PaperItem(id: 'P01', category: 'أوفست', paperType: 'أبيض', gsm: 70, sheetPrice: 100.0, sheetsPerUnit: 4);
      final machine1 = MachineItem(id: 'M01', name: 'أوفست 50x35', kind: 'Offset', wastePct: 5.0, hourlyCost: 5000.0, speedPerHour: 5000);

      final calc1 = PricingEngineService.calculateCardPricing(
        productName: 'كرت 1',
        cardWidthCm: 9.0,
        cardHeightCm: 5.5,
        qty: 1000,
        paper: paper1,
        sheetSize: '100x70',
        printSides: 1,
        machine: machine1,
        colorsCount: 4,
        hasCutting: false,
        hasLamination: false,
        allFinishings: [],
        selectedFinishingIds: [],
        plateCost: 1250.0,
        profitMarginPct: 30.0,
      );

      // تحديث السعر من 100 إلى 200 للفرخ، وتكلفة الساعة من 5000 إلى 8000
      final paperUpdated = PaperItem(id: 'P01', category: 'أوفست', paperType: 'أبيض', gsm: 70, sheetPrice: 200.0, sheetsPerUnit: 4);
      final machineUpdated = MachineItem(id: 'M01', name: 'أوفست 50x35', kind: 'Offset', wastePct: 5.0, hourlyCost: 8000.0, speedPerHour: 5000);

      final calc2 = PricingEngineService.calculateCardPricing(
        productName: 'كرت 1',
        cardWidthCm: 9.0,
        cardHeightCm: 5.5,
        qty: 1000,
        paper: paperUpdated,
        sheetSize: '100x70',
        printSides: 1,
        machine: machineUpdated,
        colorsCount: 4,
        hasCutting: false,
        hasLamination: false,
        allFinishings: [],
        selectedFinishingIds: [],
        plateCost: 1250.0,
        profitMarginPct: 30.0,
      );

      // التحقق من تضاعف تكلفة الورق وارتفاع تكلفة الماكينة والإجمالي تلقائياً
      expect(calc2.paperCost, calc1.paperCost * 2);
      expect(calc2.machineCost > calc1.machineCost, true);
      expect(calc2.lineTotalCost > calc1.lineTotalCost, true);
      expect(calc2.lineAmount > calc1.lineAmount, true);
    });

    test('حساب تسعير دفاتر NCR مع نسخ متعددة', () {
      final product = ProductTemplate(
        id: 'PRD03',
        name: 'فاتورة NCR',
        category: 'دفاتر',
        defaultNcrCopies: 4,
        defaultSheetsPerBook: 50,
        pagesPerSheet: 4,
      );

      final paper = PaperItem(
        id: 'P13',
        category: 'ورق مكربن',
        paperType: 'أبيض',
        gsm: 55,
        sheetPrice: 110.0,
        sheetsPerUnit: 4,
      );

      final machine = MachineItem(
        id: 'M01',
        name: 'أوفست 50x35',
        kind: 'Offset',
        wastePct: 5.0,
        hourlyCost: 5000.0,
        speedPerHour: 5000,
      );

      final result = PricingEngineService.calculate(
        product: product,
        qty: 100, // 100 دفتر
        pages: 0,
        ncrCopies: 4,
        sheetsPerBook: 50,
        booksCount: 100,
        colorsCount: 1,
        platesCount: 1,
        plateCost: 1250.0,
        profitMarginPct: 30.0,
        paper: paper,
        machine: machine,
        allFinishings: [],
        selectedFinishingIds: [],
      );

      // sheetsPerUnit = (50 * 4) / 4 = 50 ملزمة للدفتر
      expect(result.sheetsPerUnit, 50.0);
      // totalSheets = 50 * 100 = 5000
      expect(result.totalSheets, 5000.0);
      // sheetsWithWaste = 5000 * 1.05 = 5250
      expect(result.sheetsWithWaste, 5250.0);
      // full sheets 100x70 = ceil(5250 / 4) = 1313 فرخ
      // paperCost = 1313 * 110 = 144,430
      expect(result.paperCost, 144430.0);
    });
  });
}
