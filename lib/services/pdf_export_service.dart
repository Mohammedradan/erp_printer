import 'dart:typed_data';
import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart' as intl;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/app_models.dart';

class PdfExportService {
  static const PdfColor primaryColor = PdfColor.fromInt(0xFF1E3A5F);
  static const PdfColor accentColor = PdfColor.fromInt(0xFF0D6E57);
  static const PdfColor textDark = PdfColor.fromInt(0xFF1F2937);
  static const PdfColor textMuted = PdfColor.fromInt(0xFF4B5563);
  static const PdfColor bgLight = PdfColor.fromInt(0xFFF9FAFB);
  static const PdfColor borderLight = PdfColor.fromInt(0xFFE5E7EB);

  /// إنشاء مستند PDF رسمي لعرض السعر
  static Future<Uint8List> generateQuotationPdf({
    required Quotation quotation,
    required AppSettings settings,
  }) async {
    final pdf = pw.Document();

    // تحميل الخط العربي الموثوق
    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicBold = await PdfGoogleFonts.cairoBold();

    final numFormat = intl.NumberFormat('#,##0.00');
    final dateFormat = intl.DateFormat('yyyy/MM/dd');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        theme: pw.ThemeData.withFont(
          base: arabicFont,
          bold: arabicBold,
          fontFallback: [arabicFont, arabicBold],
        ),
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) {
          final pricing = quotation.pricingDetails;
          final currency = settings.currency;

          return [
            // ترويسة المطبعة وعرض السعر
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 14),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: primaryColor, width: 2.5)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // بيانات المطبعة
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        settings.companyName,
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'أنظمة وحلول الطباعة التجارية والتغليف',
                        style: pw.TextStyle(fontSize: 9, color: textMuted),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'هاتف: ${settings.companyPhone}',
                        style: pw.TextStyle(fontSize: 9, color: textDark),
                      ),
                      pw.Text(
                        'العنوان: ${settings.companyAddress}',
                        style: pw.TextStyle(fontSize: 9, color: textDark),
                      ),
                      if (settings.taxNumber.isNotEmpty)
                        pw.Text(
                          'الرقم الضريبي: ${settings.taxNumber}',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: textDark),
                        ),
                    ],
                  ),

                  // بطاقة عرض السعر
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: bgLight,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                      border: pw.Border.all(color: borderLight),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'عرض سعر / QUOTATION',
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'رقم العرض: ${quotation.number}',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                        pw.Text(
                          'التاريخ: ${dateFormat.format(quotation.date)}',
                          style: pw.TextStyle(fontSize: 9, color: textMuted),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: pw.BoxDecoration(
                            color: quotation.isApproved ? PdfColors.green100 : PdfColors.amber100,
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                          ),
                          child: pw.Text(
                            quotation.status,
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: quotation.isApproved ? PdfColors.green900 : PdfColors.amber900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 14),

            // بيانات العميل والمواصفات العامة
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: bgLight,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: borderLight),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('العميل المستفيد:', quotation.customerName),
                        _buildInfoRow('كود العميل:', quotation.customerCode),
                        _buildInfoRow('المنتج المطلوب:', quotation.product),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('الكمية المطلوبة:', '${quotation.qty} نسخة/دفتر'),
                        if (quotation.pages > 0)
                          _buildInfoRow('عدد الصفحات:', '${quotation.pages} صفحة'),
                        if (quotation.ncrCopies > 0)
                          _buildInfoRow('أوراق الطقم (NCR):', '${quotation.ncrCopies} ورق'),
                        _buildInfoRow('خامة الورق الأساسية:', quotation.paper),
                        _buildInfoRow('الماكينة المقترحة:', quotation.machine),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 16),

            // لا تُصدّر تفاصيل التكلفة أو خطوات الإنتاج إلى نسخة العميل.

            // بطاقة الملخص المالي النهائي
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 260,
                  decoration: pw.BoxDecoration(
                    border: pw.TableBorder.all(color: borderLight, width: 1),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    children: [
                      _buildSummaryRow('المبلغ قبل الضريبة:', '${numFormat.format(quotation.quoteAmount)} $currency', isBold: true),
                      if (pricing != null && pricing.taxAmount > 0) ...[
                        _buildSummaryRow('ضريبة القيمة المضافة (${pricing.taxPct.toInt()}%):', '${numFormat.format(pricing.taxAmount)} $currency'),
                        _buildSummaryRow('الإجمالي الشامل للضريبة:', '${numFormat.format(pricing.grandTotalAmount)} $currency', isGrandTotal: true),
                      ] else ...[
                        _buildSummaryRow('الإجمالي الصافي المطلوب:', '${numFormat.format(quotation.quoteAmount)} $currency', isGrandTotal: true),
                      ],
                      _buildSummaryRow('سعر النسخة الواحدة:', '${numFormat.format(quotation.unitPrice)} $currency / وحدة', isAccent: true),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 18),

            // الشروط والأحكام وملاحظات العرض
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: bgLight,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: borderLight),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'الشروط والأحكام وملاحظات التسليم:',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primaryColor),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    quotation.notes?.isNotEmpty == true
                        ? quotation.notes!
                        : settings.quotationNotes,
                    style: pw.TextStyle(fontSize: 8.5, color: textDark, lineSpacing: 1.5),
                  ),
                ],
              ),
            ),

            pw.Spacer(),

            // منطقة التوقيع والختم
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('توقيع واعتماد العميل', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 35),
                    pw.Container(width: 140, height: 1, color: borderLight),
                    pw.SizedBox(height: 3),
                    pw.Text('الاسم / الصفة:', style: pw.TextStyle(fontSize: 8, color: textMuted)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('إدارة المبيعات والطباعة', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 35),
                    pw.Container(width: 140, height: 1, color: borderLight),
                    pw.SizedBox(height: 3),
                    pw.Text('الختم والاعتماد الرسمي', style: pw.TextStyle(fontSize: 8, color: textMuted)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// معاينة وطباعة عرض السعر عبر مشغل النظام المدمج
  static Future<void> printOrPreviewQuotation(
    BuildContext context, {
    required Quotation quotation,
    required AppSettings settings,
  }) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => generateQuotationPdf(
        quotation: quotation,
        settings: settings,
      ),
      name: 'Quotation_${quotation.number}.pdf',
    );
  }

  /// مشاركة ملف عرض السعر PDF مباشرة (واتساب، تيليجرام، إيميل)
  static Future<void> shareQuotationPdf({
    required Quotation quotation,
    required AppSettings settings,
  }) async {
    final pdfBytes = await generateQuotationPdf(
      quotation: quotation,
      settings: settings,
    );
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'عرض_سعر_${quotation.number}.pdf',
    );
  }

  // --- عناصر المساعدة البنائية لـ PDF ---

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: textMuted),
          ),
          pw.SizedBox(width: 6),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: textDark),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildHeaderCell(String text, {double? width}) {
    final child = pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      ),
    );
    return width != null ? pw.SizedBox(width: width, child: child) : child;
  }

  static pw.Widget _buildDataCell(String text, {bool bold = false, pw.TextAlign align = pw.TextAlign.right}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textDark,
        ),
      ),
    );
  }

  static pw.Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    bool isGrandTotal = false,
    bool isAccent = false,
  }) {
    final bgColor = isGrandTotal
        ? primaryColor
        : (isAccent ? const PdfColor(0.93, 0.97, 0.94) : PdfColors.white);
    final textColor = isGrandTotal ? PdfColors.white : (isAccent ? accentColor : textDark);

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      color: bgColor,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isGrandTotal ? 10.5 : 9,
              fontWeight: isGrandTotal || isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: textColor,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: isGrandTotal ? 11 : 9.5,
              fontWeight: pw.FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
