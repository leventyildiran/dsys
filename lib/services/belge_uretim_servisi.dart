import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';

import '../core/hesaplama_motoru.dart';
import '../core/karar_metni_servisi.dart';
import '../core/turkce_format.dart';
import '../models/dagitim_model.dart';
import '../models/danismanlik_model.dart';
import '../models/gorevli_personel_model.dart';
import '../models/taksit_model.dart';

/// Word/DOCX belge üretim servisi.
///
/// Karar metni + dinamik faaliyet cetveli tablosu üretir.
/// Çıktı formatı: Office Open XML (.docx) formatında Uint8List.
///
/// Şablon A (standart) ve Şablon B (58/k) karar metinlerini,
/// placeholder değerleriyle doldurulmuş tam belge olarak üretir.
class BelgeUretimServisi {
  BelgeUretimServisi._();

  // ─────────────────────────────────────────────────────────────
  // 1. KARAR BELGESİ ÜRETİMİ
  // ─────────────────────────────────────────────────────────────

  /// Taksit onayı sonrası tam karar belgesini üretir.
  ///
  /// İçerik:
  /// - Karar metni (Şablon A veya B)
  /// - Faaliyet cetveli tablosu
  /// - Dağıtım özet tablosu
  static KararBelgesi kararBelgesiOlustur({
    required DanismanlikModel danismanlik,
    required TaksitModel taksit,
    required List<GorevliPersonelModel> gorevliler,
    required List<DagitimModel> dagitimlar,
    required double katsayi,
    String? birimAd,
  }) {
    // 1. Karar metni oluştur
    final isStandart =
        danismanlik.danismanlikTuru == DanismanlikTuru.standart;

    final veriler = _kararVerileriHazirla(
      danismanlik: danismanlik,
      taksit: taksit,
      gorevliler: gorevliler,
      katsayi: katsayi,
      birimAd: birimAd,
    );

    final kararMetni = KararMetniServisi.metinUret(
      isStandart: isStandart,
      veriler: veriler,
    );

    final dogrulama = KararMetniServisi.dogrula(
      isStandart: isStandart,
      veriler: veriler,
    );

    // 2. Faaliyet cetveli tablosu oluştur
    final faaliyetCetveli = _faaliyetCetveliOlustur(
      gorevliler: gorevliler,
      dagitimlar: dagitimlar,
      katsayi: katsayi,
    );

    // 3. Dağıtım özet tablosu
    final dagitimOzeti = _dagitimOzetiOlustur(
      dagitimlar: dagitimlar,
      taksit: taksit,
    );

    return KararBelgesi(
      kararMetni: kararMetni,
      faaliyetCetveli: faaliyetCetveli,
      dagitimOzeti: dagitimOzeti,
      dogrulama: dogrulama,
      tamMetin: _tamMetinBirlestir(kararMetni, faaliyetCetveli, dagitimOzeti),
    );
  }

  /// DOCX formatında belge üretir (Office Open XML) resmi şablonu kullanarak.
  ///
  /// Gerçek .docx ZIP arşivi üretir — Word ile açılabilir.
  static Future<Uint8List> docxOlustur(KararBelgesi belge) async {
    final content = belge.tamMetin;
    return await _buildDocxFromTemplate(content, isKarar: true);
  }

  /// Düz metinden Word (DOCX) dosyası üretir resmi şablonu kullanarak.
  static Future<Uint8List> metindenDocxOlustur(String content) async {
    // Gündem dosyası mı yoksa Karar defteri mi olduğunu içerikten kontrol et
    final isKarar = !content.contains('GÜNDEM MADDELERİ') && 
                    !content.contains('Gündem ') && 
                    !content.contains('TOPLANTI GÜNDEM');
    return await _buildDocxFromTemplate(content, isKarar: isKarar);
  }

  /// Assets'ten şablonu yükler, word/document.xml dosyasını değiştirir ve ZIP olarak geri döndürür.
  static Future<Uint8List> _buildDocxFromTemplate(String content, {required bool isKarar}) async {
    final templatePath = isKarar
        ? 'assets/templates/karar_sablonu.docx'
        : 'assets/templates/gundem_sablonu.docx';

    // Şablon byte'larını assets'ten yükle
    final ByteData assetData = await rootBundle.load(templatePath);
    final List<int> templateBytes = assetData.buffer.asUint8List(
      assetData.offsetInBytes,
      assetData.lengthInBytes,
    );

    // ZIP arşivini aç
    final archive = ZipDecoder().decodeBytes(templateBytes);

    // word/document.xml dosyasını bul
    final docFileIndex = archive.files.indexWhere((f) => f.name == 'word/document.xml');
    if (docFileIndex == -1) {
      throw Exception('word/document.xml şablon içinde bulunamadı.');
    }
    final docFile = archive.files[docFileIndex];
    final originalXml = utf8.decode(docFile.content as List<int>, allowMalformed: true);

    // Şablondaki sayfa yapısını (sectPr: margins, headers, footers) korumak için sectPr tag'ini bul
    final sectPrMatch = RegExp(r'<w:sectPr\b[^>]*>.*?</w:sectPr>', dotAll: true).firstMatch(originalXml);
    final sectPrXml = sectPrMatch?.group(0) ?? '';

    // Şablondaki w:document açılış tag'ini (tüm xmlns tanımlarıyla birlikte) koru
    final documentOpenMatch = RegExp(r'<w:document\b[^>]*>', dotAll: true).firstMatch(originalXml);
    final documentOpenXml = documentOpenMatch?.group(0) ?? '''<w:document xmlns:wpc="http://schemas.microsoft.com/office/word/2010/wordprocessingCanvas"
            xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
            xmlns:o="urn:schemas-microsoft-com:office:office"
            xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
            xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math"
            xmlns:v="urn:schemas-microsoft-com:vml"
            xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
            xmlns:w10="urn:schemas-microsoft-com:office:word"
            xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
            xmlns:w14="http://schemas.microsoft.com/office/word/2010/wordml"
            xmlns:wpg="http://schemas.microsoft.com/office/word/2010/wordprocessingGroup"
            xmlns:wpi="http://schemas.microsoft.com/office/word/2010/wordprocessingInk"
            xmlns:wne="http://schemas.microsoft.com/office/word/2006/wordml"
            xmlns:wps="http://schemas.microsoft.com/office/word/2010/wordprocessingShape"
            mc:Ignorable="w14">''';

    // Yeni body içeriğini üret
    final generatedBody = _buildDocumentBodyXml(content, sectPrXml);

    final finalDocXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
$documentOpenXml
  <w:body>
$generatedBody
  </w:body>
</w:document>''';

    final docFileData = utf8.encode(finalDocXml);

    // Yeni ZIP arşivi oluşturup dosyaları aktar (word/document.xml'i güncelleyerek)
    final newArchive = Archive();
    for (final f in archive.files) {
      if (f.name == 'word/document.xml') {
        newArchive.addFile(ArchiveFile('word/document.xml', docFileData.length, docFileData));
      } else {
        newArchive.addFile(f);
      }
    }

    final zipData = ZipEncoder().encode(newArchive);
    return Uint8List.fromList(zipData!);
  }

  /// Gelen metin satırlarını ve tablolarını w:body formatına dönüştürür.
  static String _buildDocumentBodyXml(String content, String sectPrXml) {
    final lines = content.split('\n');
    final bodyContent = StringBuffer();
    
    List<List<String>>? currentTable;
    
    for (final line in lines) {
      final trimmed = line.trim();
      
      if (trimmed.startsWith('|') && trimmed.endsWith('|') && trimmed.length > 2) {
        // Tablo satırı
        if (trimmed.contains(RegExp(r'^\|[\s:-|]+$'))) {
          continue; // Tablo ayracı (|---|) ise atla
        }
        final cells = trimmed.split('|')
            .map((c) => c.trim())
            .toList();
        if (cells.first.isEmpty) cells.removeAt(0);
        if (cells.isNotEmpty && cells.last.isEmpty) cells.removeLast();
        
        currentTable ??= [];
        currentTable.add(cells);
      } else {
        // Tablo dışı satır. Varsa önceki tabloyu yazdır.
        if (currentTable != null) {
          bodyContent.writeln(_buildDocxTableXml(currentTable));
          currentTable = null;
        }
        
        if (trimmed.isNotEmpty) {
          final escaped = _xmlEscape(trimmed);
          final isHeading = _isHeadingLine(trimmed);
          
          if (isHeading) {
            // Başlık paragrafları kalın, ortalanmış ve paragraf arası açık olur
            bodyContent.writeln('''
    <w:p>
      <w:pPr>
        <w:spacing w:before="240" w:after="120" w:line="360" w:lineRule="auto"/>
        <w:jc w:val="center"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman" w:cs="Times New Roman"/>
          <w:b/>
          <w:sz w:val="24"/>
          <w:szCs w:val="24"/>
        </w:rPr>
        <w:t xml:space="preserve">$escaped</w:t>
      </w:r>
    </w:p>''');
          } else {
            // Normal paragraflar iki yana yaslı, Times New Roman 12pt ve ilk satır girintili olur
            final deservesIndent = !_isNonIndentedLine(trimmed);
            final indentXml = deservesIndent 
                ? '<w:ind w:leftChars="0" w:left="0" w:firstLineChars="0" w:firstLine="720"/>' 
                : '';
                
            bodyContent.writeln('''
    <w:p>
      <w:pPr>
        <w:spacing w:line="360" w:lineRule="auto"/>
        $indentXml
        <w:jc w:val="both"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman" w:cs="Times New Roman"/>
          <w:sz w:val="24"/>
          <w:szCs w:val="24"/>
        </w:rPr>
        <w:t xml:space="preserve">$escaped</w:t>
      </w:r>
    </w:p>''');
          }
        }
      }
    }
    
    if (currentTable != null) {
      bodyContent.writeln(_buildDocxTableXml(currentTable));
    }
    
    // Sayfa yapısını (margins, header/footer referansları vb.) en sona ekle
    if (sectPrXml.isNotEmpty) {
      bodyContent.writeln(sectPrXml);
    }
    
    return bodyContent.toString();
  }

  static bool _isHeadingLine(String line) {
    final upper = line.toUpperCase();
    if (upper.startsWith('KARAR ') || upper.startsWith('GÜNDEM ')) return true;
    if (upper == 'GELİR GETİRİCİ FAALİYET CETVELİ' || 
        upper == 'DAĞITIM ÖZETİ' || 
        upper == 'İMZA TABLOSU' ||
        upper == 'GELİR GETİRİCİ FAALİYET CETVELİ BAŞLIĞI') return true;
    return false;
  }

  static bool _isNonIndentedLine(String line) {
    final upper = line.toUpperCase();
    if (upper == 'T.C.' || 
        upper.startsWith('UŞAK ÜNİVERSİTESİ') || 
        upper.startsWith('DÖNER SERMAYE') ||
        upper.contains('TOPLANTI SAYISI:') ||
        upper.contains('KARAR TARİHİ:') ||
        upper.contains('─')) return true;
    return false;
  }

  // ─────────────────────────────────────────────────────────────
  // 2. YARDIMCI: VERİ HAZIRLAMA
  // ─────────────────────────────────────────────────────────────

  static Map<String, String?> _kararVerileriHazirla({
    required DanismanlikModel danismanlik,
    required TaksitModel taksit,
    required List<GorevliPersonelModel> gorevliler,
    required double katsayi,
    String? birimAd,
  }) {
    final hocaUnvan = gorevliler.isNotEmpty ? gorevliler.first.unvan : '';
    final hocaAdSoyad =
        gorevliler.isNotEmpty ? gorevliler.first.adSoyad : '';

    final isStandart =
        danismanlik.danismanlikTuru == DanismanlikTuru.standart;

    if (isStandart) {
      return {
        'BIRIM_AD': birimAd ?? danismanlik.birimKisaAd,
        'BIRIM_EVRAK_TARIHI': taksit.birimEvrakTarihi,
        'BIRIM_EVRAK_SAYISI': taksit.birimEvrakSayisi,
        'BIRIM_KURUL_TARIHI': taksit.birimKurulTarihi,
        'BIRIM_TOPLANTI_SAYI': taksit.birimToplantiSayisi,
        'BIRIM_KARAR_NO': taksit.birimKararNo,
        'YK_KARAR_TARIHI': danismanlik.ykKararTarihi,
        'YK_KARAR_NO': danismanlik.ykKararNo,
        'FIRMA_UNVAN': danismanlik.firmaUnvan,
        'ISIN_KONUSU': danismanlik.konusu,
        'DANISMANLIK_SURESI': danismanlik.suresi.toString(),
        'HOCA_UNVAN': hocaUnvan,
        'HOCA_AD_SOYAD': hocaAdSoyad,
        'KATSAYI': katsayi > 0 ? TurkceFormat.katsayi(katsayi) : null,
      };
    } else {
      // Sanayi İşbirliği 58/k
      final baslangic = danismanlik.baslangicTarihi != null
          ? TurkceFormat.tarih(danismanlik.baslangicTarihi!)
          : null;
      final bitis = danismanlik.bitisTarihi != null
          ? TurkceFormat.tarih(danismanlik.bitisTarihi!)
          : null;

      // KDV hariç matrah üzerinden %85 katkı payı
      final matrah = HesaplamaMotoru.kdvHaricMatrahHesapla(
        taksit.brutTutar,
        danismanlik.kdvOrani,
      );
      final katkiPayi = matrah * 0.85;

      return {
        'UYK_KARAR_TARIHI': danismanlik.ykKararTarihi,
        'UYK_TOPLANTI_SAYI': danismanlik.ykToplantiSayisi,
        'UYK_KARAR_NO': danismanlik.ykKararNo,
        'FIRMA_UNVAN': danismanlik.firmaUnvan,
        'HOCA_UNVAN': hocaUnvan,
        'HOCA_AD_SOYAD': hocaAdSoyad,
        'HIZMET_BASLANGIC_TARIHI': baslangic,
        'HIZMET_BITIS_TARIHI': bitis,
        'DANISMANLIK_SURESI': danismanlik.suresi.toString(),
        'GELIR_TUTARI': TurkceFormat.para(matrah).replaceAll(' TL', ''),
        'KATKI_PAYI_TUTARI':
            TurkceFormat.para(katkiPayi).replaceAll(' TL', ''),
      };
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 3. FAALİYET CETVELİ TABLOSU
  // ─────────────────────────────────────────────────────────────

  static FaaliyetCetveli _faaliyetCetveliOlustur({
    required List<GorevliPersonelModel> gorevliler,
    required List<DagitimModel> dagitimlar,
    required double katsayi,
  }) {
    final satirlar = <FaaliyetCetveliSatir>[];

    for (final dagitim in dagitimlar) {
      satirlar.add(FaaliyetCetveliSatir(
        adSoyad: dagitim.adSoyad,
        unvan: dagitim.unvan,
        unvanKatsayisi: dagitim.unvanKatsayisi,
        toplamPuan: dagitim.bireyselPuan / dagitim.unvanKatsayisi,
        bireyselPuan: dagitim.bireyselPuan,
        brutHakedis: dagitim.brutHakedis,
        odenebilirHakedis: dagitim.odenebilirHakedis ?? dagitim.brutHakedis,
        tavanAsimi: dagitim.tavanKontrol,
      ));
    }

    return FaaliyetCetveli(
      satirlar: satirlar,
      katsayi: katsayi,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 4. DAĞITIM ÖZET TABLOSU
  // ─────────────────────────────────────────────────────────────

  static DagitimOzeti _dagitimOzetiOlustur({
    required List<DagitimModel> dagitimlar,
    required TaksitModel taksit,
  }) {
    double toplamBrutHakedis = 0;
    double toplamOdenebilir = 0;
    double toplamFazlalik = 0;

    for (final d in dagitimlar) {
      toplamBrutHakedis += d.brutHakedis;
      toplamOdenebilir += d.odenebilirHakedis ?? d.brutHakedis;
      toplamFazlalik += d.fazlalikHavuzTutari ?? 0;
    }

    return DagitimOzeti(
      brutTaksitTutari: taksit.brutTutar,
      hazinePayi: taksit.hazinePayi ?? 0,
      bapPayi: taksit.bapPayi ?? 0,
      aracGerecPayi: taksit.aracGerecPayi ?? 0,
      dagitilabilirTutar: taksit.dagitilabilirTutar ?? 0,
      toplamBrutHakedis: toplamBrutHakedis,
      toplamOdenebilirHakedis: toplamOdenebilir,
      toplamFazlalikHavuz: toplamFazlalik,
      personelSayisi: dagitimlar.length,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 5. TAM METİN BİRLEŞTİRME
  // ─────────────────────────────────────────────────────────────

  static String _tamMetinBirlestir(
    String kararMetni,
    FaaliyetCetveli cetveli,
    DagitimOzeti ozet,
  ) {
    final buffer = StringBuffer();

    // Karar metni
    buffer.writeln(kararMetni);
    buffer.writeln();
    buffer.writeln();

    // Faaliyet cetveli başlığı
    buffer.writeln('GELİR GETİRİCİ FAALİYET CETVELİ');
    buffer.writeln('─' * 80);
    buffer.writeln(
      'Sıra | Unvan | Ad Soyad | Ünvan Kats. | Toplam Puan | '
      'Bireysel Puan | Brüt Hakediş | Ödenebilir',
    );
    buffer.writeln('─' * 80);

    for (int i = 0; i < cetveli.satirlar.length; i++) {
      final s = cetveli.satirlar[i];
      buffer.writeln(
        '${i + 1}    | ${s.unvan} | ${s.adSoyad} | '
        '${TurkceFormat.ondalik(s.unvanKatsayisi)} | '
        '${TurkceFormat.ondalik(s.toplamPuan)} | '
        '${TurkceFormat.ondalik(s.bireyselPuan)} | '
        '${TurkceFormat.para(s.brutHakedis)} | '
        '${TurkceFormat.para(s.odenebilirHakedis)}'
        '${s.tavanAsimi ? " ⚠️ TAVAN" : ""}',
      );
    }
    buffer.writeln('─' * 80);
    buffer.writeln(
      'Dönem Ek Ödeme Katsayısı: ${TurkceFormat.katsayi(cetveli.katsayi)}',
    );
    buffer.writeln();

    // Dağıtım özeti
    buffer.writeln('DAĞITIM ÖZETİ');
    buffer.writeln('─' * 40);
    buffer.writeln(
        'Brüt Taksit Tutarı     : ${TurkceFormat.para(ozet.brutTaksitTutari)}');
    buffer.writeln(
        'Hazine Payı            : ${TurkceFormat.para(ozet.hazinePayi)}');
    buffer.writeln(
        'BAP Payı               : ${TurkceFormat.para(ozet.bapPayi)}');
    buffer.writeln(
        'Araç-Gereç Payı        : ${TurkceFormat.para(ozet.aracGerecPayi)}');
    buffer.writeln(
        'Dağıtılabilir Tutar    : ${TurkceFormat.para(ozet.dagitilabilirTutar)}');
    buffer.writeln(
        'Toplam Brüt Hakediş    : ${TurkceFormat.para(ozet.toplamBrutHakedis)}');
    buffer.writeln(
        'Toplam Ödenebilir      : ${TurkceFormat.para(ozet.toplamOdenebilirHakedis)}');
    if (ozet.toplamFazlalikHavuz > 0) {
      buffer.writeln(
          'Fazlalık (Havuz)       : ${TurkceFormat.para(ozet.toplamFazlalikHavuz)}');
    }
    buffer.writeln('Personel Sayısı        : ${ozet.personelSayisi}');

    return buffer.toString();
  }

  // ─────────────────────────────────────────────────────────────
  // 6. DOCX (Office Open XML) ÜRETİMİ — Gerçek ZIP Arşivi
  // ─────────────────────────────────────────────────────────────





  /// Markdown tablosundan yerel (native) Word XML tablosu üretir.
  static String _buildDocxTableXml(List<List<String>> tableData) {
    final buffer = StringBuffer();
    buffer.writeln('<w:tbl>');
    
    // Tablo özellikleri (Kenarlıklar, ortalama hizalama ve hücre dolguları)
    buffer.writeln('''
      <w:tblPr>
        <w:tblStyle w:val="TableGrid"/>
        <w:tblW w:w="5000" w:type="pct"/>
        <w:tblBorders>
          <w:top w:val="single" w:sz="4" w:space="0" w:color="CCCCCC"/>
          <w:left w:val="single" w:sz="4" w:space="0" w:color="CCCCCC"/>
          <w:bottom w:val="single" w:sz="4" w:space="0" w:color="CCCCCC"/>
          <w:right w:val="single" w:sz="4" w:space="0" w:color="CCCCCC"/>
          <w:insideH w:val="single" w:sz="4" w:space="0" w:color="CCCCCC"/>
          <w:insideV w:val="single" w:sz="4" w:space="0" w:color="CCCCCC"/>
        </w:tblBorders>
        <w:tblCellMar>
          <w:top w:w="120" w:type="dxa"/>
          <w:left w:w="150" w:type="dxa"/>
          <w:bottom w:w="120" w:type="dxa"/>
          <w:right w:w="150" w:type="dxa"/>
        </w:tblCellMar>
        <w:jc w:val="center"/>
      </w:tblPr>
    ''');
    
    // Tablo Grid yapısı (Sütunlar)
    if (tableData.isNotEmpty) {
      final colCount = tableData.first.length;
      buffer.writeln('<w:tblGrid>');
      for (int i = 0; i < colCount; i++) {
        buffer.writeln('<w:gridCol/>');
      }
      buffer.writeln('</w:tblGrid>');
    }
    
    // Satırlar ve Hücreler
    for (int rowIndex = 0; rowIndex < tableData.length; rowIndex++) {
      final row = tableData[rowIndex];
      final isHeader = rowIndex == 0;
      buffer.writeln('<w:tr>');
      
      for (final cell in row) {
        final escaped = _xmlEscape(cell);
        buffer.writeln('<w:tc>');
        
        // Hücre özellikleri (Başlık için hafif gri arka plan dolgusu)
        buffer.writeln('<w:tcPr>');
        buffer.writeln('<w:tcW w:w="0" w:type="auto"/>');
        if (isHeader) {
          buffer.writeln('<w:shd w:val="clear" w:color="auto" w:fill="F5F5F5"/>');
        }
        buffer.writeln('</w:tcPr>');
        
        // Paragraf ve hizalama
        buffer.writeln('<w:p>');
        buffer.writeln('<w:pPr>');
        buffer.writeln('<w:spacing w:before="60" w:after="60" w:line="240" w:lineRule="auto"/>');
        // Sayısal veya başlık hücresi ise ortala, değilse sola hizala
        if (isHeader || RegExp(r'^\d+(\.\d+)?\s*([%₺]|TL)?$').hasMatch(cell.trim())) {
          buffer.writeln('<w:jc w:val="center"/>');
        } else {
          buffer.writeln('<w:jc w:val="left"/>');
        }
        buffer.writeln('</w:pPr>');
        
        buffer.writeln('<w:r>');
        buffer.writeln('<w:rPr>');
        buffer.writeln('<w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman" w:cs="Times New Roman"/>');
        buffer.writeln('<w:sz w:val="22"/>'); // Tablolarda 11pt font kullanılır
        buffer.writeln('<w:szCs w:val="22"/>');
        if (isHeader) {
          buffer.writeln('<w:b/>'); // Başlık hücresi kalın
        }
        buffer.writeln('</w:rPr>');
        buffer.writeln('<w:t xml:space="preserve">$escaped</w:t>');
        buffer.writeln('</w:r>');
        buffer.writeln('</w:p>');
        
        buffer.writeln('</w:tc>');
      }
      buffer.writeln('</w:tr>');
    }
    
    buffer.writeln('</w:tbl>');
    return buffer.toString();
  }

  static String _xmlEscape(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}

// ─────────────────────────────────────────────────────────────
// VERİ MODELLERİ
// ─────────────────────────────────────────────────────────────

/// Üretilen karar belgesi.
class KararBelgesi {
  const KararBelgesi({
    required this.kararMetni,
    required this.faaliyetCetveli,
    required this.dagitimOzeti,
    required this.dogrulama,
    required this.tamMetin,
  });

  final String kararMetni;
  final FaaliyetCetveli faaliyetCetveli;
  final DagitimOzeti dagitimOzeti;
  final SablonDogrulamaSonucu dogrulama;
  final String tamMetin;

  /// Belge üretimi tamamlanabilir mi?
  bool get uretimHazir => dogrulama.gecerli;
}

/// Faaliyet cetveli tablosu modeli.
class FaaliyetCetveli {
  const FaaliyetCetveli({
    required this.satirlar,
    required this.katsayi,
  });

  final List<FaaliyetCetveliSatir> satirlar;
  final double katsayi;
}

/// Faaliyet cetveli tek satır.
class FaaliyetCetveliSatir {
  const FaaliyetCetveliSatir({
    required this.adSoyad,
    required this.unvan,
    required this.unvanKatsayisi,
    required this.toplamPuan,
    required this.bireyselPuan,
    required this.brutHakedis,
    required this.odenebilirHakedis,
    required this.tavanAsimi,
  });

  final String adSoyad;
  final String unvan;
  final double unvanKatsayisi;
  final double toplamPuan;
  final double bireyselPuan;
  final double brutHakedis;
  final double odenebilirHakedis;
  final bool tavanAsimi;
}

/// Dağıtım özet bilgileri.
class DagitimOzeti {
  const DagitimOzeti({
    required this.brutTaksitTutari,
    required this.hazinePayi,
    required this.bapPayi,
    required this.aracGerecPayi,
    required this.dagitilabilirTutar,
    required this.toplamBrutHakedis,
    required this.toplamOdenebilirHakedis,
    required this.toplamFazlalikHavuz,
    required this.personelSayisi,
  });

  final double brutTaksitTutari;
  final double hazinePayi;
  final double bapPayi;
  final double aracGerecPayi;
  final double dagitilabilirTutar;
  final double toplamBrutHakedis;
  final double toplamOdenebilirHakedis;
  final double toplamFazlalikHavuz;
  final int personelSayisi;

  double get artikBakiye => dagitilabilirTutar - toplamBrutHakedis;
}
