import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/turkce_format.dart';
import '../models/fatura_model.dart';

/// PDF fatura üretim servisi.
///
/// `pdf` paketini kullanarak gerçek PDF dosyası üretir.
/// Fatura detaylarını profesyonel formatta hazırlar.
class PdfService {
  PdfService._();

  /// Matbu fatura üzerine doğrudan basım için PDF üretir.
  ///
  /// Bu PDF, sınır çizgileri, tablolar veya arka plan resimleri çizmez.
  /// Sadece verileri fiziksel matbu fatura üzerindeki boşluklara denk gelecek
  /// milimetrik koordinatlarla (Positioned widget'ları ile) yerleştirir.
  static Future<Uint8List> matbuFaturaUret(FaturaModel fatura) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero, // Sıfır kenar marjı
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // 1. Fatura Tarihi (Üst Sağ - x: 480pt, y: 80pt)
              if (fatura.faturaTarihi != null)
                pw.Positioned(
                  left: 480,
                  top: 80,
                  child: pw.Text(fatura.faturaTarihi!),
                ),

              // 2. Seri ve Sıra No (Üst Sağ - x: 480pt, y: 100pt)
              if (fatura.seriNo != null || fatura.siraNo != null)
                pw.Positioned(
                  left: 480,
                  top: 100,
                  child: pw.Text('${fatura.seriNo ?? ''} ${fatura.siraNo ?? ''}'),
                ),

              // 3. Firma Ünvanı / Alıcı Bilgisi (Orta Sol - x: 80pt, y: 150pt)
              pw.Positioned(
                left: 80,
                top: 150,
                child: pw.SizedBox(
                  width: 300,
                  child: pw.Text(
                    fatura.firmaUnvan,
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ),

              // 4. Hizmet Detayı / Açıklama (Orta - x: 80pt, y: 280pt)
              pw.Positioned(
                left: 80,
                top: 280,
                child: pw.SizedBox(
                  width: 320,
                  child: pw.Text(fatura.hizmetDetay, style: const pw.TextStyle(fontSize: 10)),
                ),
              ),

              // 5. Hizmet Bedeli / Tutar (Orta Sağ - x: 480pt, y: 280pt)
              pw.Positioned(
                left: 480,
                top: 280,
                child: pw.Text(TurkceFormat.para(fatura.tutar)),
              ),

              // 6. KDV Tutarı (Alt Sağ - x: 480pt, y: 650pt)
              pw.Positioned(
                left: 480,
                top: 650,
                child: pw.Text(TurkceFormat.para(fatura.kdvTutar)),
              ),

              // 7. Toplam Tutar (Alt Sağ - x: 480pt, y: 680pt)
              pw.Positioned(
                left: 480,
                top: 680,
                child: pw.Text(
                  TurkceFormat.para(fatura.toplamTutar),
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Tek bir fatura için PDF üretir.
  static Future<Uint8List> faturaUret(FaturaModel fatura) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Başlık
              pw.Center(
                child: pw.Text(
                  'FATURA',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Fatura bilgileri tablosu
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildBilgiSatiri('Birim', fatura.birimAd),
                    _buildBilgiSatiri('Firma Ünvanı', fatura.firmaUnvan),
                    if (fatura.seriNo != null)
                      _buildBilgiSatiri('Seri No', fatura.seriNo!),
                    if (fatura.siraNo != null)
                      _buildBilgiSatiri('Sıra No', fatura.siraNo!),
                    if (fatura.faturaTarihi != null)
                      _buildBilgiSatiri('Fatura Tarihi', fatura.faturaTarihi!),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Hizmet detayları
              pw.Text(
                'Hizmet Detayı',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(fatura.hizmetDetay),
              pw.SizedBox(height: 20),

              // Tutar tablosu
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      _buildTableCell('Açıklama', bold: true),
                      _buildTableCell('Tutar', bold: true, align: pw.TextAlign.right),
                    ],
                  ),
                  pw.TableRow(children: [
                    _buildTableCell('Hizmet Bedeli'),
                    _buildTableCell(
                      TurkceFormat.para(fatura.tutar),
                      align: pw.TextAlign.right,
                    ),
                  ]),
                  pw.TableRow(children: [
                    _buildTableCell('KDV (%${fatura.kdvOrani.toInt()})'),
                    _buildTableCell(
                      TurkceFormat.para(fatura.kdvTutar),
                      align: pw.TextAlign.right,
                    ),
                  ]),
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey100,
                    ),
                    children: [
                      _buildTableCell('TOPLAM', bold: true),
                      _buildTableCell(
                        TurkceFormat.para(fatura.toplamTutar),
                        bold: true,
                        align: pw.TextAlign.right,
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 40),

              // Alt bilgi
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Text(
                'Bu belge DSYS tarafından otomatik olarak üretilmiştir.',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Toplu fatura listesini tek bir PDF'de üretir.
  static Future<Uint8List> topluFaturaUret(List<FaturaModel> faturalar) async {
    final pdf = pw.Document();

    for (final fatura in faturalar) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'FATURA',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 16),
                _buildBilgiSatiri('Firma', fatura.firmaUnvan),
                _buildBilgiSatiri('Hizmet', fatura.hizmetDetay),
                _buildBilgiSatiri('Tutar', TurkceFormat.para(fatura.tutar)),
                _buildBilgiSatiri('KDV', TurkceFormat.para(fatura.kdvTutar)),
                _buildBilgiSatiri('Toplam', TurkceFormat.para(fatura.toplamTutar)),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  static pw.Widget _buildBilgiSatiri(String etiket, String deger) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              '$etiket:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(deger)),
        ],
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
