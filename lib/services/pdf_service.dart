import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/turkce_format.dart';
import '../models/fatura_model.dart';
import '../models/gundem_model.dart';
import '../models/yk_karar_model.dart';
import '../models/sistem_ayarlari_model.dart';

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

  /// Yürütme Kurulu Karar Defteri için PDF üretir.
  static Future<Uint8List> ykKararDefteriPdfUret(
    ToplantiModel toplanti,
    List<YkKararModel> kararlar,
    List<KurulUyesiModel> kurulUyeleri, {
    String? kurumAdi,
    String? antetBasligi,
  }) async {
    final pdf = pw.Document();

    final regularFont = await PdfGoogleFonts.tinosRegular();
    final boldFont = await PdfGoogleFonts.tinosBold();

    final textStyle = pw.TextStyle(font: regularFont, fontSize: 12, height: 1.4);
    final boldStyle = pw.TextStyle(font: boldFont, fontSize: 12);
    final titleStyle = pw.TextStyle(font: boldFont, fontSize: 14);

    final titleKurum = (kurumAdi == null || kurumAdi.trim().isEmpty) ? 'UŞAK ÜNİVERSİTESİ' : kurumAdi.toUpperCase();
    final titleAntet = (antetBasligi == null || antetBasligi.trim().isEmpty) ? 'DÖNER SERMAYE YÜRÜTME KURULU KARARLARI' : antetBasligi.toUpperCase();

    final baskanUye = kurulUyeleri.firstWhere(
      (u) => u.gorev.toLowerCase().contains('başkan') || u.gorev.toLowerCase().contains('baskan'),
      orElse: () => kurulUyeleri.isNotEmpty
          ? kurulUyeleri.first
          : const KurulUyesiModel(siraNo: '1', gorev: 'Başkan', adSoyad: ''),
    );
    final baskanAdi = baskanUye.adSoyad;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return [
            // Resmi Başlık
            pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                'T.C.',
                style: boldStyle,
              ),
            ),
            pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                titleKurum,
                style: boldStyle,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Center(
              child: pw.Text(
                titleAntet,
                style: titleStyle,
              ),
            ),
            pw.SizedBox(height: 12),

            // Toplantı Bilgileri Kutusu (Single border without divider)
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 0.8),
              ),
              padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOPLANTI SAYISI: ${toplanti.toplantiNo}', style: boldStyle),
                  pw.Text('KARAR TARİHİ: ${toplanti.toplantiTarihi}', style: boldStyle),
                ],
              ),
            ),
            pw.SizedBox(height: 15),

            // Preamble / Giriş Metni
            pw.Paragraph(
              text:
                  "      Uşak Üniversitesi Döner Sermaye Yürütme Kurulu Rektör Yardımcısı $baskanAdi başkanlığında ${toplanti.toplantiTarihi} tarihinde saat 10:00' da toplandı. Gündem maddeleri görüşülerek aşağıdaki kararlar alındı.",
              style: textStyle,
              textAlign: pw.TextAlign.justify,
            ),

            // Kararlar Listesi
            if (kararlar.isEmpty)
              pw.Paragraph(
                text: 'Bu toplantıya ait onaylanmış karar bulunmamaktadır.',
                style: textStyle,
              )
            else
              ...kararlar.map((karar) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(height: 15),
                    pw.Text(
                      'KARAR ${karar.kararNo.isNotEmpty ? karar.kararNo : "Taslak"}',
                      style: boldStyle,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Paragraph(
                      text: '      ${karar.kararMetni}',
                      style: textStyle,
                      textAlign: pw.TextAlign.justify,
                    ),
                  ],
                );
              }),

            pw.SizedBox(height: 20),
            // Oy birliği ifadesi
            pw.Center(
              child: pw.Text(
                'Katılanların oy birliği ile karar verildi.',
                style: textStyle,
              ),
            ),
            pw.SizedBox(height: 20),

            // İmza Tablosu
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
              columnWidths: {
                0: const pw.FixedColumnWidth(50),
                1: const pw.FixedColumnWidth(80),
                2: const pw.FlexColumnWidth(3),
                3: const pw.FixedColumnWidth(100),
              },
              children: [
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Sıra No', style: boldStyle, textAlign: pw.TextAlign.center),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Görevi', style: boldStyle, textAlign: pw.TextAlign.center),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Üyenin Adı Soyadı', style: boldStyle, textAlign: pw.TextAlign.center),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('İmzası', style: boldStyle, textAlign: pw.TextAlign.center),
                    ),
                  ],
                ),
                ...List.generate(kurulUyeleri.length, (index) {
                  final uye = kurulUyeleri[index];
                  return _buildSignatureRow(
                    (index + 1).toString(),
                    uye.gorev,
                    uye.adSoyad,
                    boldStyle,
                    textStyle,
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.TableRow _buildSignatureRow(
    String siraNo,
    String gorev,
    String adSoyad,
    pw.TextStyle boldStyle,
    pw.TextStyle textStyle,
  ) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(siraNo, style: textStyle, textAlign: pw.TextAlign.center),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(gorev, style: textStyle),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(adSoyad, style: boldStyle),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.SizedBox(height: 25),
        ),
      ],
    );
  }

  /// Toplantı Gündem Maddeleri için PDF üretir (Word antetli şablona göre).
  static Future<Uint8List> ykGundemPdfUret(ToplantiModel toplanti) async {
    final pdf = pw.Document();

    final regularFont = await PdfGoogleFonts.tinosRegular();
    final boldFont = await PdfGoogleFonts.tinosBold();

    final textStyle = pw.TextStyle(font: regularFont, fontSize: 12, height: 1.5);
    final boldStyle = pw.TextStyle(font: boldFont, fontSize: 12);
    final titleStyle = pw.TextStyle(font: boldFont, fontSize: 14, decoration: pw.TextDecoration.underline);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 50, vertical: 40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header title
              pw.Center(
                child: pw.Text(
                  'DÖNER SERMAYE YÜRÜTME KURULU GÜNDEM MADDELERİ',
                  style: titleStyle,
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 25),

              // Intro text
              pw.Text(
                'Uşak Üniversitesi Döner Sermaye Yürütme Kurulunun ${toplanti.toplantiTarihi} tarihli toplantı gündem maddeleri aşağıdaki gibidir.',
                style: textStyle,
              ),
              pw.SizedBox(height: 15),

              // Agenda list
              ...toplanti.gundemMaddeleri.map((madde) {
                final siraStr = madde.siraNo.toString().padLeft(2, '0');
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 12),
                  child: pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                          text: 'Gündem $siraStr: ',
                          style: boldStyle,
                        ),
                        pw.TextSpan(
                          text: madde.baslik,
                          style: textStyle,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}

