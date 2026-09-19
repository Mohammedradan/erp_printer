import 'dart:math';
import '../models/app_models.dart';

/// نتيجة توزيع وتقطيع الكروت أو المطبوعات داخل الفرخ
class SheetImpositionResult {
  final double sheetWidth;
  final double sheetHeight;
  final double itemWidth;
  final double itemHeight;
  final int itemsAlongWidth;
  final int itemsAlongHeight;
  final int totalItemsPerSheet;
  final String layoutDirection; // 'طولي' أو 'عرضي'

  SheetImpositionResult({
    required this.sheetWidth,
    required this.sheetHeight,
    required this.itemWidth,
    required this.itemHeight,
    required this.itemsAlongWidth,
    required this.itemsAlongHeight,
    required this.totalItemsPerSheet,
    required this.layoutDirection,
  });
}

/// محرك التسعير الشامل والمفصل لقوالب المنتجات المطبعية
class PricingEngineService {
  /// حساب التوزيع الأمثل للمطبوعات داخل الفرخ (Imposition Calculator)
  static SheetImpositionResult calculateImposition({
    required double sheetWidthCm,
    required double sheetHeightCm,
    required double itemWidthCm,
    required double itemHeightCm,
    double marginCm = 1.5, // هوامش مسموحة للبنس والملاقط والقص
  }) {
    final netW = max(1.0, sheetWidthCm - marginCm);
    final netH = max(1.0, sheetHeightCm - marginCm);

    final w = max(0.5, itemWidthCm);
    final h = max(0.5, itemHeightCm);

    // الخيار 1: اتجاه طولي
    final fit1W = (netW / w).floor();
    final fit1H = (netH / h).floor();
    final total1 = fit1W * fit1H;

    // الخيار 2: اتجاه عرضي (تدوير 90 درجة)
    final fit2W = (netW / h).floor();
    final fit2H = (netH / w).floor();
    final total2 = fit2W * fit2H;

    if (total2 > total1) {
      return SheetImpositionResult(
        sheetWidth: sheetWidthCm,
        sheetHeight: sheetHeightCm,
        itemWidth: itemWidthCm,
        itemHeight: itemHeightCm,
        itemsAlongWidth: fit2W,
        itemsAlongHeight: fit2H,
        totalItemsPerSheet: max(1, total2),
        layoutDirection: 'عرضي (مقلوب 90°)',
      );
    } else {
      return SheetImpositionResult(
        sheetWidth: sheetWidthCm,
        sheetHeight: sheetHeightCm,
        itemWidth: itemWidthCm,
        itemHeight: itemHeightCm,
        itemsAlongWidth: fit1W,
        itemsAlongHeight: fit1H,
        totalItemsPerSheet: max(1, total1),
        layoutDirection: 'طولي (مباشر)',
      );
    }
  }

  // =========================================================================
  // 1. قالب الكتاب (Book Pricing)
  // الصفحات → الملازم → عدد النسخ → الورق → الهالك → الطباعة → الغلاف → التجليد → الربح
  // =========================================================================
  static PricingResult calculateBookPricing({
    required String productName,
    required int pages,
    required int pagesPerSignature, // 8 أو 16 حسب الحجم (A5 / A4)
    required int qty, // عدد النسخ
    required PaperItem innerPaper,
    required MachineItem machine,
    required int innerColors,
    required PaperItem coverPaper,
    required int coverFitsPerSheet, // كم غلاف في فرخ 100x70 (عادة 4 أو 8)
    required int coverColors,
    required bool coverLamination,
    FinishingItem? laminationFinishing,
    required String bindingType, // حراري / دبوس / سلك / خياطة
    FinishingItem? bindingFinishing,
    required List<FinishingItem> allFinishings,
    required List<String> selectedFinishingIds,
    required double plateCost,
    required double profitMarginPct,
    double taxPct = 0.0,
  }) {
    final validQty = qty > 0 ? qty : 1;
    final validPages = pages > 0 ? pages : 16;
    final validPps = pagesPerSignature > 0 ? pagesPerSignature : 8;

    final stepDetails = <PricingStepDetail>[];

    // 1. الملازم (Signatures)
    final signaturesPerBook = (validPages / validPps).ceil();
    final totalSignatures = signaturesPerBook * validQty;

    stepDetails.add(PricingStepDetail(
      stepNumber: '1',
      title: 'الصفحات والملازم',
      description: '$validPages صفحة مقسمة إلى ملازم ($validPps صفحة/ملزمة)',
      metrics: {
        'عدد الملازم/نسخة': '$signaturesPerBook ملازم',
        'إجمالي الملازم للكمية': '$totalSignatures ملزمة',
      },
    ));

    // 2. عدد النسخ
    stepDetails.add(PricingStepDetail(
      stepNumber: '2',
      title: 'عدد النسخ المطلوبة',
      description: 'إنتاج $validQty نسخة كاملة من الكتاب',
      metrics: {
        'الكمية': '$validQty نسخة',
      },
    ));

    // 3. الورق الداخلي (أفرخ 100×70)
    // كل فرخ 100×70 يعطي 4 ملازم 50×35
    final fitsPerSheet = innerPaper.sheetsPerUnit > 0 ? innerPaper.sheetsPerUnit : 4;
    final netInnerSheets = (totalSignatures / fitsPerSheet).ceilToDouble();

    // 4. الهالك (Waste)
    final wastePct = machine.wastePct;
    final wasteInnerSheets = (netInnerSheets * (wastePct / 100.0)).ceilToDouble();
    final totalInnerSheetsWithWaste = netInnerSheets + wasteInnerSheets;
    final innerPaperCost = totalInnerSheetsWithWaste * innerPaper.sheetPrice;

    stepDetails.add(PricingStepDetail(
      stepNumber: '3 & 4',
      title: 'ورق المتن الداخلي والهالك',
      description: 'خامة ${innerPaper.displayName} بسعر ${innerPaper.sheetPrice.toStringAsFixed(1)} للفرخ',
      cost: innerPaperCost,
      metrics: {
        'الأفرخ الصافية': '${netInnerSheets.toInt()} فرخ',
        'نسبة الهالك': '${wastePct.toStringAsFixed(1)}%',
        'أفرخ الهالك': '${wasteInnerSheets.toInt()} فرخ',
        'إجمالي أفرخ المتن': '${totalInnerSheetsWithWaste.toInt()} فرخ',
        'تكلفة ورق المتن': '${innerPaperCost.toStringAsFixed(1)}',
      },
    ));

    // 5. الطباعة (Machine & Plates for Inner Pages)
    final speed = machine.speedPerHour > 0 ? machine.speedPerHour : 5000;
    final innerRunHours = totalInnerSheetsWithWaste / speed;
    final innerMachineCost = innerRunHours * machine.hourlyCost;

    // زنكات المتن = ملازم النسخة × عدد الألوان (وجهين عادة)
    final innerPlatesCount = max(1, signaturesPerBook * (innerColors > 0 ? innerColors : 1));
    final innerPlatesCost = innerPlatesCount * plateCost;

    stepDetails.add(PricingStepDetail(
      stepNumber: '5',
      title: 'طباعة المتن الداخلي',
      description: 'ماكينة ${machine.name} ($innerColors لون) مع $innerPlatesCount بليت',
      cost: innerMachineCost + innerPlatesCost,
      metrics: {
        'ساعات التشغيل': '${innerRunHours.toStringAsFixed(2)} ساعة',
        'تكلفة الماكينة': '${innerMachineCost.toStringAsFixed(1)}',
        'زنكات المتن': '$innerPlatesCount بليت (${innerPlatesCost.toStringAsFixed(1)})',
      },
    ));

    // 6. الغلاف (Cover: Paper + Print + Lamination)
    final coverFits = coverFitsPerSheet > 0 ? coverFitsPerSheet : 4;
    final netCoverSheets = (validQty / coverFits).ceilToDouble();
    final coverWasteSheets = (netCoverSheets * (wastePct / 100.0)).ceilToDouble();
    final totalCoverSheets = netCoverSheets + coverWasteSheets;
    final coverPaperCost = totalCoverSheets * coverPaper.sheetPrice;

    final coverRunHours = totalCoverSheets / speed;
    final coverMachineCost = coverRunHours * machine.hourlyCost;
    final coverPlatesCount = max(1, coverColors > 0 ? coverColors : 4);
    final coverPlatesCost = coverPlatesCount * plateCost;

    double coverLamCost = 0.0;
    if (coverLamination) {
      if (laminationFinishing != null) {
        if (laminationFinishing.unit == 'للألف') {
          coverLamCost = laminationFinishing.price * (validQty / 1000.0);
        } else if (laminationFinishing.unit == 'للقطعة') {
          coverLamCost = laminationFinishing.price * validQty;
        } else {
          coverLamCost = laminationFinishing.price;
        }
      } else {
        // افتراضي 4000 لكل ألف
        coverLamCost = 4000.0 * (validQty / 1000.0);
      }
    }

    final totalCoverCost = coverPaperCost + coverMachineCost + coverPlatesCost + coverLamCost;

    stepDetails.add(PricingStepDetail(
      stepNumber: '6',
      title: 'الغلاف وطباعته وسلوفانه',
      description: 'ورق ${coverPaper.displayName} + طباعة $coverColors ألوان + ${coverLamination ? 'سلوفان' : 'بدون سلوفان'}',
      cost: totalCoverCost,
      metrics: {
        'أفرخ الغلاف': '${totalCoverSheets.toInt()} فرخ',
        'ورق الغلاف': '${coverPaperCost.toStringAsFixed(1)}',
        'طباعة وزنكات الغلاف': '${(coverMachineCost + coverPlatesCost).toStringAsFixed(1)}',
        'سلوفان الغلاف': '${coverLamCost.toStringAsFixed(1)}',
      },
    ));

    // 7. التجليد (Binding) والتشطيبات الإضافية
    double bindingCost = 0.0;
    if (bindingFinishing != null) {
      if (bindingFinishing.unit == 'للقطعة') {
        bindingCost = bindingFinishing.price * validQty;
      } else if (bindingFinishing.unit == 'للألف') {
        bindingCost = bindingFinishing.price * (validQty / 1000.0);
      } else {
        bindingCost = bindingFinishing.price;
      }
    } else {
      // تسعير افتراضي حسب نوع التجليد
      if (bindingType.contains('حراري')) {
        bindingCost = 50.0 * validQty;
      } else if (bindingType.contains('سلك')) {
        bindingCost = 80.0 * validQty;
      } else {
        bindingCost = 25.0 * validQty;
      }
    }

    // تشطيبات إضافية
    double otherFinishingCost = 0.0;
    final selectedFinishingNames = <String>[];
    for (final fId in selectedFinishingIds) {
      final match = allFinishings.where((f) => f.id == fId);
      if (match.isNotEmpty) {
        final f = match.first;
        selectedFinishingNames.add(f.name);
        if (f.unit == 'للقطعة') {
          otherFinishingCost += f.price * validQty;
        } else if (f.unit == 'للألف') {
          otherFinishingCost += f.price * (validQty / 1000.0);
        } else {
          otherFinishingCost += f.price;
        }
      }
    }

    final totalFinishingAndBindingCost = bindingCost + otherFinishingCost;

    stepDetails.add(PricingStepDetail(
      stepNumber: '7',
      title: 'التجليد والتشطيب',
      description: 'تجليد ($bindingType) وتشذيب الكتاب',
      cost: totalFinishingAndBindingCost,
      metrics: {
        'تكلفة التجليد': '${bindingCost.toStringAsFixed(1)}',
        'تشطيبات إضافية': '${otherFinishingCost.toStringAsFixed(1)}',
      },
    ));

    // 8. التكلفة الكلية وهامش الربح والضريبة
    final lineTotalCost = innerPaperCost +
        innerMachineCost +
        innerPlatesCost +
        coverPaperCost +
        coverMachineCost +
        coverPlatesCost +
        coverLamCost +
        totalFinishingAndBindingCost;

    final marginFactor = 1.0 + (profitMarginPct / 100.0);
    final lineAmount = (lineTotalCost * marginFactor).roundToDouble();
    final profit = lineAmount - lineTotalCost;
    final unitPrice = validQty > 0 ? (lineAmount / validQty) : 0.0;

    final taxAmount = (taxPct > 0) ? (lineAmount * (taxPct / 100.0)).roundToDouble() : 0.0;
    final grandTotal = lineAmount + taxAmount;

    stepDetails.add(PricingStepDetail(
      stepNumber: '8',
      title: 'التكلفة الإجمالية وصافي الربح',
      description: 'تطبيق هامش ربح ${profitMarginPct.toStringAsFixed(1)}% ${taxPct > 0 ? 'وضريبة $taxPct%' : ''}',
      cost: lineAmount,
      metrics: {
        'التكلفة الصناعية': '${lineTotalCost.toStringAsFixed(1)}',
        'صافي الربح': '${profit.toStringAsFixed(1)}',
        'سعر بيع النسخة': '${unitPrice.toStringAsFixed(2)}',
        'الإجمالي قبل الضريبة': '${lineAmount.toStringAsFixed(1)}',
        if (taxPct > 0) 'الضريبة': '${taxAmount.toStringAsFixed(1)}',
        if (taxPct > 0) 'الإجمالي النهائي': '${grandTotal.toStringAsFixed(1)}',
      },
    ));

    return PricingResult(
      productName: productName,
      qty: validQty,
      pages: validPages,
      ncrCopies: 0,
      sheetsPerBook: 0,
      booksCount: 0,
      colorsCount: innerColors,
      platesCount: innerPlatesCount + coverPlatesCount,
      plateCost: plateCost,
      profitMarginPct: profitMarginPct,
      paperId: innerPaper.id,
      paperCategory: innerPaper.category,
      paperType: innerPaper.paperType,
      paperGsm: innerPaper.gsm,
      paperSheetPrice: innerPaper.sheetPrice,
      machineId: machine.id,
      machineName: machine.name,
      wastePct: wastePct,
      hourlyCost: machine.hourlyCost,
      speedPerHour: machine.speedPerHour,
      selectedFinishingIds: selectedFinishingIds,
      selectedFinishingNames: selectedFinishingNames,
      sheetsPerUnit: signaturesPerBook.toDouble(),
      totalSheets: netInnerSheets + netCoverSheets,
      sheetsWithWaste: totalInnerSheetsWithWaste + totalCoverSheets,
      paperCost: innerPaperCost + coverPaperCost,
      runHours: innerRunHours + coverRunHours,
      machineCost: innerMachineCost + coverMachineCost,
      finishingCost: coverLamCost + totalFinishingAndBindingCost,
      zincCost: innerPlatesCost + coverPlatesCost,
      lineTotalCost: lineTotalCost,
      unitPrice: unitPrice,
      lineAmount: lineAmount,
      profit: profit,
      templateType: 'book',
      taxPct: taxPct,
      taxAmount: taxAmount,
      grandTotalAmount: grandTotal,
      stepDetails: stepDetails,
      materialRequirements: [
        PricingMaterialRequirement(
          materialId: innerPaper.id,
          materialName: innerPaper.displayName,
          quantity: totalInnerSheetsWithWaste,
          unitCost: innerPaper.sheetPrice,
        ),
        PricingMaterialRequirement(
          materialId: coverPaper.id,
          materialName: coverPaper.displayName,
          quantity: totalCoverSheets,
          unitCost: coverPaper.sheetPrice,
        ),
      ],
      extraMetrics: {
        'signaturesPerBook': signaturesPerBook,
        'coverPaper': coverPaper.displayName,
        'bindingType': bindingType,
        'innerPaperCost': innerPaperCost,
        'coverTotalCost': totalCoverCost,
      },
    );
  }

  // =========================================================================
  // 2. قالب دفاتر الـ NCR المكربنة
  // عدد النسخ → أوراق الدفتر → عدد الدفاتر → توزيع الأوراق → الهالك → الطباعة → الترقيم → التجميع → الربح
  // =========================================================================
  static PricingResult calculateNcrPricing({
    required String productName,
    required int ncrCopies, // عدد نسخ الطقم: مثلاً 3 (أصل + صورتين)
    required int sheetsPerBook, // عدد الوصولات/الأطقم في الدفتر (مثلاً 50 وصل)
    required int booksCount, // عدد الدفاتر
    required List<PaperItem> papersPerColor, // قائمة أوراق الألوان [أبيض، وردي، أصفر...]
    required int setsPerSheet, // كم وصل/طقم في الفرخ 100x70 (عادة 16 لمقاس A5 أو 8 لمقاس A4)
    required MachineItem machine,
    required int colorsCount, // ألوان الطباعة
    required bool hasNumbering,
    FinishingItem? numberingFinishing,
    required bool hasAssemblyAndBinding,
    FinishingItem? assemblyFinishing,
    required List<FinishingItem> allFinishings,
    required List<String> selectedFinishingIds,
    required double plateCost,
    required double profitMarginPct,
    double taxPct = 0.0,
  }) {
    final validCopies = max(1, ncrCopies);
    final validSheetsPerBook = max(1, sheetsPerBook);
    final validBooksCount = max(1, booksCount);
    final validSetsPerSheet = max(1, setsPerSheet);

    final stepDetails = <PricingStepDetail>[];

    // 1 & 2 & 3. حساب الأطقم الإجمالية
    final totalSets = validBooksCount * validSheetsPerBook;
    final totalIndividualSheets = totalSets * validCopies;

    stepDetails.add(PricingStepDetail(
      stepNumber: '1-3',
      title: 'عدد النسخ وأوراق الدفتر وعدد الدفاتر',
      description: '$validCopies نسخ مكربنة × $validSheetsPerBook وصل/دفتر × $validBooksCount دفتر',
      metrics: {
        'إجمالي الأطقم (الوصولات)': '$totalSets طقم',
        'إجمالي الأوراق الفردية': '$totalIndividualSheets ورقة',
      },
    ));

    // 4 & 5. توزيع الأوراق لكل لون وحساب الهالك
    // الأفرخ الصافية المطلوبة لكل لون ورق = totalSets / setsPerSheet
    final netSheetsPerColor = (totalSets / validSetsPerSheet).ceilToDouble();
    final wastePct = machine.wastePct;
    final wasteSheetsPerColor = (netSheetsPerColor * (wastePct / 100.0)).ceilToDouble();
    final grossSheetsPerColor = netSheetsPerColor + wasteSheetsPerColor;

    double totalNcrPaperCost = 0.0;
    final colorBreakdownMetrics = <String, String>{};
    final materialRequirements = <PricingMaterialRequirement>[];

    for (int i = 0; i < validCopies; i++) {
      final paper = i < papersPerColor.length ? papersPerColor[i] : (papersPerColor.isNotEmpty ? papersPerColor.first : null);
      final price = paper?.sheetPrice ?? 125.0;
      final colorCost = grossSheetsPerColor * price;
      totalNcrPaperCost += colorCost;
      final colorLabel = paper != null ? paper.paperType : 'نسخة ${i + 1}';
      colorBreakdownMetrics['لون $colorLabel'] = '${grossSheetsPerColor.toInt()} فرخ (${colorCost.toStringAsFixed(1)})';
      if (paper != null) {
        materialRequirements.add(PricingMaterialRequirement(
          materialId: paper.id,
          materialName: paper.displayName,
          quantity: grossSheetsPerColor,
          unitCost: paper.sheetPrice,
        ));
      }
    }

    final totalAllColorsSheetsWithWaste = grossSheetsPerColor * validCopies;

    stepDetails.add(PricingStepDetail(
      stepNumber: '4 & 5',
      title: 'توزيع الأوراق بالألوان والهالك',
      description: 'حساب أفرخ الورق المكربن لكل طبقة ولون بشكل منفصل مع نسبة هالك ${wastePct.toStringAsFixed(1)}%',
      cost: totalNcrPaperCost,
      metrics: {
        'أفرخ كل لون مع الهالك': '${grossSheetsPerColor.toInt()} فرخ',
        'إجمالي أفرخ كل الألوان': '${totalAllColorsSheetsWithWaste.toInt()} فرخ',
        'إجمالي تكلفة ورق NCR': '${totalNcrPaperCost.toStringAsFixed(1)}',
        ...colorBreakdownMetrics,
      },
    ));

    // 6. الطباعة (Printing & Plates)
    // سحبات الماكينة = إجمالي الأوراق المطبوعة / سرعة الماكينة
    final speed = machine.speedPerHour > 0 ? machine.speedPerHour : 5000;
    final runHours = totalAllColorsSheetsWithWaste / speed;
    final machineCost = runHours * machine.hourlyCost;
    final platesCount = max(1, colorsCount);
    final platesCost = platesCount * plateCost;

    stepDetails.add(PricingStepDetail(
      stepNumber: '6',
      title: 'طباعة الدفاتر المكربنة',
      description: 'ماكينة ${machine.name} ($colorsCount لون) لسحب ${totalAllColorsSheetsWithWaste.toInt()} فرخ',
      cost: machineCost + platesCost,
      metrics: {
        'ساعات السحب': '${runHours.toStringAsFixed(2)} ساعة',
        'تكلفة تشغيل الماكينة': '${machineCost.toStringAsFixed(1)}',
        'زنكات الطباعة': '$platesCount زنك (${platesCost.toStringAsFixed(1)})',
      },
    ));

    // 7. الترقيم (Numbering)
    double numberingCost = 0.0;
    if (hasNumbering) {
      if (numberingFinishing != null) {
        if (numberingFinishing.unit == 'للألف') {
          numberingCost = numberingFinishing.price * (totalSets / 1000.0);
        } else if (numberingFinishing.unit == 'للقطعة') {
          numberingCost = numberingFinishing.price * totalSets;
        } else {
          numberingCost = numberingFinishing.price;
        }
      } else {
        // سعر افتراضي 1200 للألف وصل
        numberingCost = 1200.0 * (totalSets / 1000.0);
      }
    }

    stepDetails.add(PricingStepDetail(
      stepNumber: '7',
      title: 'الترقيم التسلسلي (Numbering)',
      description: hasNumbering ? 'ترقيم تصاعدي لـ $totalSets وصل' : 'بدون ترقيم',
      cost: numberingCost,
      metrics: {
        'تكلفة الترقيم': '${numberingCost.toStringAsFixed(1)}',
      },
    ));

    // 8. التجميع والتشطيب (Collation, Cover & Spine Binding)
    double assemblyCost = 0.0;
    if (hasAssemblyAndBinding) {
      if (assemblyFinishing != null) {
        if (assemblyFinishing.unit == 'للقطعة') {
          assemblyCost = assemblyFinishing.price * validBooksCount;
        } else if (assemblyFinishing.unit == 'للألف') {
          assemblyCost = assemblyFinishing.price * (validBooksCount / 1000.0);
        } else {
          assemblyCost = assemblyFinishing.price;
        }
      } else {
        // تكلفة فرز + كرتون خلفي + غلاف كرافت + تدبيس وشريط = 150 للدفتر
        assemblyCost = 150.0 * validBooksCount;
      }
    }

    // تشطيبات إضافية
    double otherFinishingCost = 0.0;
    final selectedFinishingNames = <String>[];
    for (final fId in selectedFinishingIds) {
      final match = allFinishings.where((f) => f.id == fId);
      if (match.isNotEmpty) {
        final f = match.first;
        selectedFinishingNames.add(f.name);
        if (f.unit == 'للقطعة') {
          otherFinishingCost += f.price * validBooksCount;
        } else if (f.unit == 'للألف') {
          otherFinishingCost += f.price * (validBooksCount / 1000.0);
        } else {
          otherFinishingCost += f.price;
        }
      }
    }

    final totalAssemblyAndFinishing = assemblyCost + otherFinishingCost;

    stepDetails.add(PricingStepDetail(
      stepNumber: '8',
      title: 'التجميع والتجليد والتشطيب',
      description: 'فرز ألوان الـ NCR + كرتون خلفي وغلاف أمامي + تدبيس وشريط تجليد',
      cost: totalAssemblyAndFinishing,
      metrics: {
        'تجميع وتجليد الدفاتر': '${assemblyCost.toStringAsFixed(1)}',
        'تشطيبات إضافية': '${otherFinishingCost.toStringAsFixed(1)}',
      },
    ));

    // 9. التكلفة الإجمالية وهامش الربح
    final lineTotalCost = totalNcrPaperCost + machineCost + platesCost + numberingCost + totalAssemblyAndFinishing;
    final marginFactor = 1.0 + (profitMarginPct / 100.0);
    final lineAmount = (lineTotalCost * marginFactor).roundToDouble();
    final profit = lineAmount - lineTotalCost;
    final unitPrice = validBooksCount > 0 ? (lineAmount / validBooksCount) : 0.0;

    final taxAmount = (taxPct > 0) ? (lineAmount * (taxPct / 100.0)).roundToDouble() : 0.0;
    final grandTotal = lineAmount + taxAmount;

    stepDetails.add(PricingStepDetail(
      stepNumber: '9',
      title: 'حساب الربح وسعر بيع الدفتر',
      description: 'تطبيق هامش ربح ${profitMarginPct.toStringAsFixed(1)}% ${taxPct > 0 ? 'وضريبة $taxPct%' : ''}',
      cost: lineAmount,
      metrics: {
        'التكلفة الإجمالية': '${lineTotalCost.toStringAsFixed(1)}',
        'صافي الربح': '${profit.toStringAsFixed(1)}',
        'سعر بيع الدفتر الواحد': '${unitPrice.toStringAsFixed(2)}',
        'الإجمالي': '${lineAmount.toStringAsFixed(1)}',
        if (taxPct > 0) 'الضريبة': '${taxAmount.toStringAsFixed(1)}',
        if (taxPct > 0) 'الإجمالي النهائي': '${grandTotal.toStringAsFixed(1)}',
      },
    ));

    final defaultPaper = papersPerColor.isNotEmpty ? papersPerColor.first : null;

    return PricingResult(
      productName: productName,
      qty: validBooksCount,
      pages: 0,
      ncrCopies: validCopies,
      sheetsPerBook: validSheetsPerBook,
      booksCount: validBooksCount,
      colorsCount: colorsCount,
      platesCount: platesCount,
      plateCost: plateCost,
      profitMarginPct: profitMarginPct,
      paperId: defaultPaper?.id ?? '',
      paperCategory: defaultPaper?.category ?? 'NCR',
      paperType: defaultPaper?.paperType ?? 'أبيض',
      paperGsm: defaultPaper?.gsm ?? 55,
      paperSheetPrice: defaultPaper?.sheetPrice ?? 125,
      machineId: machine.id,
      machineName: machine.name,
      wastePct: wastePct,
      hourlyCost: machine.hourlyCost,
      speedPerHour: machine.speedPerHour,
      selectedFinishingIds: selectedFinishingIds,
      selectedFinishingNames: selectedFinishingNames,
      sheetsPerUnit: (validSheetsPerBook * validCopies / validSetsPerSheet).toDouble(),
      totalSheets: (netSheetsPerColor * validCopies),
      sheetsWithWaste: totalAllColorsSheetsWithWaste,
      paperCost: totalNcrPaperCost,
      runHours: runHours,
      machineCost: machineCost,
      finishingCost: numberingCost + totalAssemblyAndFinishing,
      zincCost: platesCost,
      lineTotalCost: lineTotalCost,
      unitPrice: unitPrice,
      lineAmount: lineAmount,
      profit: profit,
      templateType: 'ncr',
      taxPct: taxPct,
      taxAmount: taxAmount,
      grandTotalAmount: grandTotal,
      stepDetails: stepDetails,
      materialRequirements: materialRequirements,
      extraMetrics: {
        'totalSets': totalSets,
        'numberingCost': numberingCost,
        'assemblyCost': assemblyCost,
        'grossSheetsPerColor': grossSheetsPerColor,
      },
    );
  }

  // =========================================================================
  // 3. قالب الكروت والمطبوعات الفردية (Business Cards & Flyers)
  // مقاس الكرت → توزيع الكروت داخل الفرخ → عدد الأفراخ → الهالك → عدد وجهات الطباعة → الماكينة → القص → التشطيب → الربح
  // =========================================================================
  static PricingResult calculateCardPricing({
    required String productName,
    required double cardWidthCm, // مثلاً 9.0 سم
    required double cardHeightCm, // مثلاً 5.5 سم
    required int qty, // عدد الكروت المطلوبة
    required PaperItem paper,
    required String sheetSize, // '100x70' أو '50x35'
    required int printSides, // 1 وجه أو 2 وجهين
    required MachineItem machine,
    required int colorsCount, // 4 ألوان
    required bool hasCutting,
    FinishingItem? cuttingFinishing,
    required bool hasLamination,
    FinishingItem? laminationFinishing,
    required List<FinishingItem> allFinishings,
    required List<String> selectedFinishingIds,
    required double plateCost,
    required double profitMarginPct,
    double taxPct = 0.0,
  }) {
    final validQty = max(1, qty);
    final validSides = (printSides == 2) ? 2 : 1;

    // أبعاد الفرخ
    double sheetW = 100.0;
    double sheetH = 70.0;
    if (sheetSize.contains('50') || sheetSize.contains('35')) {
      sheetW = 50.0;
      sheetH = 35.0;
    }

    final stepDetails = <PricingStepDetail>[];

    // 1 & 2. مقاس الكرت وتوزيع الكروت داخل الفرخ (Smart Imposition)
    final imposition = calculateImposition(
      sheetWidthCm: sheetW,
      sheetHeightCm: sheetH,
      itemWidthCm: cardWidthCm,
      itemHeightCm: cardHeightCm,
    );

    final cardsPerSheet = imposition.totalItemsPerSheet;

    stepDetails.add(PricingStepDetail(
      stepNumber: '1 & 2',
      title: 'مقاس الكرت وتوزيعه داخل الفرخ',
      description: 'مقاس ${cardWidthCm}×${cardHeightCm} سم على فرخ ${sheetW.toInt()}×${sheetH.toInt()} سم (${imposition.layoutDirection})',
      metrics: {
        'توزيع بالعرض × بالطول': '${imposition.itemsAlongWidth} × ${imposition.itemsAlongHeight}',
        'عدد الكروت في الفرخ': '$cardsPerSheet كرت/فرخ',
      },
    ));

    // 3 & 4. عدد الأفراخ والهالك
    final netSheets = (validQty / cardsPerSheet).ceilToDouble();
    final wastePct = machine.wastePct;
    final wasteSheets = (netSheets * (wastePct / 100.0)).ceilToDouble();
    final grossSheets = netSheets + wasteSheets;
    final paperCost = grossSheets * paper.sheetPrice;

    stepDetails.add(PricingStepDetail(
      stepNumber: '3 & 4',
      title: 'عدد الأفراخ ونسبة الهالك',
      description: 'خامة ${paper.displayName} مع نسبة هالك ${wastePct.toStringAsFixed(1)}%',
      cost: paperCost,
      metrics: {
        'الأفرخ الصافية': '${netSheets.toInt()} فرخ',
        'أفرخ الهالك': '${wasteSheets.toInt()} فرخ',
        'إجمالي الأفرخ المطلوبة': '${grossSheets.toInt()} فرخ',
        'تكلفة الورق': '${paperCost.toStringAsFixed(1)}',
      },
    ));

    // 5 & 6. وجهات الطباعة والماكينة والزنكات
    // إذا كان وجهين: السحبات تتضاعف، والزنكات إما 4 (قلاب) أو 8
    final totalPasses = grossSheets * validSides;
    final speed = machine.speedPerHour > 0 ? machine.speedPerHour : 5000;
    final runHours = totalPasses / speed;
    final machineCost = runHours * machine.hourlyCost;

    final platesCount = colorsCount * validSides;
    final platesCost = platesCount * plateCost;

    stepDetails.add(PricingStepDetail(
      stepNumber: '5 & 6',
      title: 'وجهات الطباعة والماكينة',
      description: 'طباعة (${validSides == 2 ? "وجهين 4/4" : "وجه واحد 4/0"}) على ماكينة ${machine.name}',
      cost: machineCost + platesCost,
      metrics: {
        'إجمالي سحبات الطباعة': '${totalPasses.toInt()} سحبة',
        'ساعات التشغيل': '${runHours.toStringAsFixed(2)} ساعة',
        'تكلفة الماكينة': '${machineCost.toStringAsFixed(1)}',
        'زنكات الطباعة': '$platesCount زنك (${platesCost.toStringAsFixed(1)})',
      },
    ));

    // 7. القص (Cutting)
    double cuttingCost = 0.0;
    if (hasCutting) {
      if (cuttingFinishing != null) {
        cuttingCost = cuttingFinishing.price;
      } else {
        // تكلفة مقص آلي للكمية
        cuttingCost = 1500.0;
      }
    }

    stepDetails.add(PricingStepDetail(
      stepNumber: '7',
      title: 'القص والتشذيب الآلي',
      description: hasCutting ? 'قص البلوكات وتفريغ الكروت بدقة' : 'بدون قص',
      cost: cuttingCost,
      metrics: {
        'تكلفة القص': '${cuttingCost.toStringAsFixed(1)}',
      },
    ));

    // 8. التشطيب (سلوفان، ركن دائري، Spot UV...)
    double finishingCost = 0.0;
    final selectedFinishingNames = <String>[];

    if (hasLamination) {
      if (laminationFinishing != null) {
        if (laminationFinishing.unit == 'للألف') {
          finishingCost += laminationFinishing.price * (validQty / 1000.0) * validSides;
        } else if (laminationFinishing.unit == 'للقطعة') {
          finishingCost += laminationFinishing.price * validQty * validSides;
        } else {
          finishingCost += laminationFinishing.price;
        }
      } else {
        // افتراضي 4000 للألف فرخ
        finishingCost += 4000.0 * (grossSheets / 1000.0) * validSides;
      }
      selectedFinishingNames.add('سلوفان حراري (${validSides == 2 ? "وجهين" : "وجه"})');
    }

    for (final fId in selectedFinishingIds) {
      final match = allFinishings.where((f) => f.id == fId);
      if (match.isNotEmpty) {
        final f = match.first;
        selectedFinishingNames.add(f.name);
        if (f.unit == 'للقطعة') {
          finishingCost += f.price * validQty;
        } else if (f.unit == 'للألف') {
          finishingCost += f.price * (validQty / 1000.0);
        } else {
          finishingCost += f.price;
        }
      }
    }

    stepDetails.add(PricingStepDetail(
      stepNumber: '8',
      title: 'التشطيبات والمعالجات الإضافية',
      description: selectedFinishingNames.isNotEmpty ? selectedFinishingNames.join(' + ') : 'بدون تشطيبات إضافية',
      cost: finishingCost,
      metrics: {
        'تكلفة التشطيبات': '${finishingCost.toStringAsFixed(1)}',
      },
    ));

    // 9. التكلفة الكلية وهامش الربح
    final lineTotalCost = paperCost + machineCost + platesCost + cuttingCost + finishingCost;
    final marginFactor = 1.0 + (profitMarginPct / 100.0);
    final lineAmount = (lineTotalCost * marginFactor).roundToDouble();
    final profit = lineAmount - lineTotalCost;
    final unitPrice = validQty > 0 ? (lineAmount / validQty) : 0.0;

    final taxAmount = (taxPct > 0) ? (lineAmount * (taxPct / 100.0)).roundToDouble() : 0.0;
    final grandTotal = lineAmount + taxAmount;

    stepDetails.add(PricingStepDetail(
      stepNumber: '9',
      title: 'صافي الربح وسعر بيع الكرت',
      description: 'تطبيق هامش ربح ${profitMarginPct.toStringAsFixed(1)}% ${taxPct > 0 ? 'وضريبة $taxPct%' : ''}',
      cost: lineAmount,
      metrics: {
        'التكلفة الإجمالية': '${lineTotalCost.toStringAsFixed(1)}',
        'صافي الربح': '${profit.toStringAsFixed(1)}',
        'سعر الكرت الواحد': '${unitPrice.toStringAsFixed(3)}',
        'الإجمالي': '${lineAmount.toStringAsFixed(1)}',
        if (taxPct > 0) 'الضريبة': '${taxAmount.toStringAsFixed(1)}',
        if (taxPct > 0) 'الإجمالي النهائي': '${grandTotal.toStringAsFixed(1)}',
      },
    ));

    return PricingResult(
      productName: productName,
      qty: validQty,
      pages: 0,
      ncrCopies: 0,
      sheetsPerBook: 0,
      booksCount: 0,
      colorsCount: colorsCount,
      platesCount: platesCount,
      plateCost: plateCost,
      profitMarginPct: profitMarginPct,
      paperId: paper.id,
      paperCategory: paper.category,
      paperType: paper.paperType,
      paperGsm: paper.gsm,
      paperSheetPrice: paper.sheetPrice,
      machineId: machine.id,
      machineName: machine.name,
      wastePct: wastePct,
      hourlyCost: machine.hourlyCost,
      speedPerHour: machine.speedPerHour,
      selectedFinishingIds: selectedFinishingIds,
      selectedFinishingNames: selectedFinishingNames,
      sheetsPerUnit: 1.0 / cardsPerSheet,
      totalSheets: netSheets,
      sheetsWithWaste: grossSheets,
      paperCost: paperCost,
      runHours: runHours,
      machineCost: machineCost,
      finishingCost: cuttingCost + finishingCost,
      zincCost: platesCost,
      lineTotalCost: lineTotalCost,
      unitPrice: unitPrice,
      lineAmount: lineAmount,
      profit: profit,
      templateType: 'card',
      taxPct: taxPct,
      taxAmount: taxAmount,
      grandTotalAmount: grandTotal,
      stepDetails: stepDetails,
      materialRequirements: [
        PricingMaterialRequirement(
          materialId: paper.id,
          materialName: paper.displayName,
          quantity: grossSheets,
          unitCost: paper.sheetPrice,
        ),
      ],
      extraMetrics: {
        'cardsPerSheet': cardsPerSheet,
        'cardSize': '${cardWidthCm}x$cardHeightCm سم',
        'printSides': validSides,
        'impositionDirection': imposition.layoutDirection,
      },
    );
  }

  // =========================================================================
  // 4. قالب المنتجات الأخرى وقوالب مخصصة (Custom & Extensible Products)
  // والواجهة العامة الموحدة
  // =========================================================================
  static PricingResult calculate({
    required ProductTemplate product,
    required int qty,
    required int pages,
    required int ncrCopies,
    required int sheetsPerBook,
    required int booksCount,
    required int colorsCount,
    required int platesCount,
    required double plateCost,
    required double profitMarginPct,
    required PaperItem paper,
    required MachineItem machine,
    required List<FinishingItem> allFinishings,
    required List<String> selectedFinishingIds,
    double taxPct = 0.0,
  }) {
    final validQty = qty > 0 ? qty : 1;

    // 1) الملازم/وحدة (sheets_per_unit)
    double sheetsPerUnit = 0.0;
    if (product.isNcr) {
      final totalBookSheets = (sheetsPerBook > 0 ? sheetsPerBook : (product.defaultSheetsPerBook ?? 50)) *
          (ncrCopies > 0 ? ncrCopies : (product.defaultNcrCopies ?? 3));
      final pps = product.pagesPerSheet > 0 ? product.pagesPerSheet : 4;
      sheetsPerUnit = totalBookSheets / pps;
    } else {
      final pps = product.pagesPerSheet > 0 ? product.pagesPerSheet : 8;
      final safePages = pages > 0 ? pages : (product.defaultPages ?? 16);
      sheetsPerUnit = safePages / pps;
    }

    // 2) إجمالي الأوراق مع التقريب لأعلى
    final totalSheets = (sheetsPerUnit * validQty).ceilToDouble();

    // 3) نسبة الهالك %
    final wastePct = machine.wastePct;

    // 4) الأوراق مع الهالك
    final sheetsWithWaste = (totalSheets * (1.0 + (wastePct / 100.0))).ceilToDouble();

    // 5) تكلفة الورق
    final fitsPerSheet = paper.sheetsPerUnit > 0 ? paper.sheetsPerUnit : 4;
    final fullSheetsToBuy = (sheetsWithWaste / fitsPerSheet).ceilToDouble();
    final paperCost = fullSheetsToBuy * paper.sheetPrice;

    // 6) ساعات التشغيل
    final speed = machine.speedPerHour > 0 ? machine.speedPerHour : 1000;
    final runHours = sheetsWithWaste / speed;

    // 7) تكلفة الماكينة
    final machineCost = runHours * machine.hourlyCost;

    // 8) تكلفة البليتات والزنكات
    final effectivePlates = platesCount > 0 ? platesCount : (colorsCount > 0 ? colorsCount : 1);
    final zincCost = effectivePlates * plateCost;

    // 9) تكلفة التشطيبات
    double finishingCost = 0.0;
    final selectedFinishingNames = <String>[];
    for (final fId in selectedFinishingIds) {
      final match = allFinishings.where((f) => f.id == fId);
      if (match.isNotEmpty) {
        final f = match.first;
        selectedFinishingNames.add(f.name);
        if (f.unit == 'للقطعة') {
          finishingCost += f.price * validQty;
        } else if (f.unit == 'للألف') {
          finishingCost += f.price * (validQty / 1000.0);
        } else {
          finishingCost += f.price;
        }
      }
    }

    // 10) التكلفة الكلية
    final lineTotalCost = paperCost + machineCost + zincCost + finishingCost;

    // 11) هامش الربح وسعر الوحدة
    final marginFactor = 1.0 + (profitMarginPct / 100.0);
    final lineAmount = (lineTotalCost * marginFactor).roundToDouble();
    final profit = lineAmount - lineTotalCost;
    final unitPrice = validQty > 0 ? (lineAmount / validQty) : 0.0;

    final taxAmount = (taxPct > 0) ? (lineAmount * (taxPct / 100.0)).roundToDouble() : 0.0;
    final grandTotal = lineAmount + taxAmount;

    final stepDetails = [
      PricingStepDetail(
        stepNumber: '1',
        title: 'الكمية والملازم',
        description: '$validQty وحدة بمعدل ${sheetsPerUnit.toStringAsFixed(2)} ملازم/وحدة',
        metrics: {'إجمالي الملازم': '${totalSheets.toInt()} ملزمة'},
      ),
      PricingStepDetail(
        stepNumber: '2',
        title: 'الورق والهالك',
        description: '${paper.displayName} مع نسبة هالك ${wastePct.toStringAsFixed(1)}%',
        cost: paperCost,
        metrics: {
          'أفرخ الشراء': '${fullSheetsToBuy.toInt()} فرخ',
          'تكلفة الورق': '${paperCost.toStringAsFixed(1)}',
        },
      ),
      PricingStepDetail(
        stepNumber: '3',
        title: 'الطباعة والزنكات',
        description: 'ماكينة ${machine.name} ($effectivePlates زنك)',
        cost: machineCost + zincCost,
        metrics: {
          'تكلفة الماكينة': '${machineCost.toStringAsFixed(1)}',
          'تكلفة الزنكات': '${zincCost.toStringAsFixed(1)}',
        },
      ),
      PricingStepDetail(
        stepNumber: '4',
        title: 'التشطيبات',
        description: selectedFinishingNames.isNotEmpty ? selectedFinishingNames.join('، ') : 'بدون تشطيب',
        cost: finishingCost,
        metrics: {'تكلفة التشطيب': '${finishingCost.toStringAsFixed(1)}'},
      ),
      PricingStepDetail(
        stepNumber: '5',
        title: 'الربح والإجمالي',
        description: 'هامش ربح ${profitMarginPct.toStringAsFixed(1)}% ${taxPct > 0 ? 'وضريبة $taxPct%' : ''}',
        cost: lineAmount,
        metrics: {
          'التكلفة': '${lineTotalCost.toStringAsFixed(1)}',
          'الربح': '${profit.toStringAsFixed(1)}',
          'سعر الوحدة': '${unitPrice.toStringAsFixed(2)}',
        },
      ),
    ];

    return PricingResult(
      productName: product.name,
      qty: validQty,
      pages: pages,
      ncrCopies: ncrCopies,
      sheetsPerBook: sheetsPerBook,
      booksCount: booksCount,
      colorsCount: colorsCount,
      platesCount: effectivePlates,
      plateCost: plateCost,
      profitMarginPct: profitMarginPct,
      paperId: paper.id,
      paperCategory: paper.category,
      paperType: paper.paperType,
      paperGsm: paper.gsm,
      paperSheetPrice: paper.sheetPrice,
      machineId: machine.id,
      machineName: machine.name,
      wastePct: wastePct,
      hourlyCost: machine.hourlyCost,
      speedPerHour: machine.speedPerHour,
      selectedFinishingIds: selectedFinishingIds,
      selectedFinishingNames: selectedFinishingNames,
      sheetsPerUnit: sheetsPerUnit,
      totalSheets: totalSheets,
      sheetsWithWaste: sheetsWithWaste,
      paperCost: paperCost,
      runHours: runHours,
      machineCost: machineCost,
      finishingCost: finishingCost,
      zincCost: zincCost,
      lineTotalCost: lineTotalCost,
      unitPrice: unitPrice,
      lineAmount: lineAmount,
      profit: profit,
      templateType: product.isNcr ? 'ncr' : 'custom',
      taxPct: taxPct,
      taxAmount: taxAmount,
      grandTotalAmount: grandTotal,
      stepDetails: stepDetails,
      materialRequirements: [
        PricingMaterialRequirement(
          materialId: paper.id,
          materialName: paper.displayName,
          quantity: fullSheetsToBuy,
          unitCost: paper.sheetPrice,
        ),
      ],
    );
  }
}
