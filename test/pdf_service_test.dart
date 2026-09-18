import 'package:flutter_test/flutter_test.dart';
import 'package:erp_printer/models/app_models.dart';
import 'package:erp_printer/services/pdf_export_service.dart';
import 'package:erp_printer/services/pricing_engine_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PdfExportService generates valid PDF bytes for a quotation', () async {
    final quotation = Quotation(
      id: 'q_test_1',
      number: 'Q-2026-0099',
      date: DateTime.now(),
      customerId: 'c_test_1',
      customerCode: 'CUST-001',
      customerName: 'مؤسسة الفجر للتجارة',
      product: 'بروشور إعلاني فاخر',
      qty: 1000,
      pages: 4,
      paper: 'كوشيه 150 جرام',
      machine: 'هايدلبرج SM 74',
      unitPrice: 25.5,
      totalCost: 19600.0,
      quoteAmount: 25500.0,
      profit: 5900.0,
      status: 'معتمد',
      notes: 'شامل التوصيل لمقر المؤسسة',
      pricingDetails: PricingEngineService.calculateCardPricing(
        productName: 'بروشور إعلاني فاخر',
        cardWidthCm: 14.8,
        cardHeightCm: 21.0,
        qty: 1000,
        paper: PaperItem(
          id: 'P01',
          category: 'كوشيه',
          paperType: 'مطفي',
          gsm: 150,
          sheetPrice: 16.0,
          sheetsPerUnit: 4,
          reorderLevel: 500,
        ),
        sheetSize: '100x70',
        printSides: 2,
        machine: MachineItem(
          id: 'M01',
          name: 'هايدلبرج SM 74',
          kind: 'Offset',
          wastePct: 5.0,
          hourlyCost: 5000.0,
          speedPerHour: 5000,
        ),
        colorsCount: 4,
        hasCutting: true,
        hasLamination: false,
        allFinishings: [],
        selectedFinishingIds: [],
        plateCost: 1250.0,
        profitMarginPct: 30.0,
        taxPct: 15.0,
      ),
    );

    final settings = AppSettings();
    final bytes = await PdfExportService.generateQuotationPdf(
      quotation: quotation,
      settings: settings,
    );

    expect(bytes, isNotEmpty);
    // PDF file header starts with %PDF-
    final header = String.fromCharCodes(bytes.take(5));
    expect(header, equals('%PDF-'));
  });
}
