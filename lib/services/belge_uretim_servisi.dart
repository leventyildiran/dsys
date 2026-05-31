import 'dart:convert';
import 'dart:typed_data';

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

  /// DOCX formatında belge üretir (Office Open XML).
  ///
  /// Minimal .docx yapısı: ZIP arşivi içinde XML dokümanları.
  static Uint8List docxOlustur(KararBelgesi belge) {
    final content = belge.tamMetin;
    final docXml = _buildDocumentXml(content, belge);
    return _buildDocxArchive(docXml);
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
  // 6. DOCX (Office Open XML) ÜRETİMİ
  // ─────────────────────────────────────────────────────────────

  /// Basit bir document.xml üretir (Word paragrafları).
  static String _buildDocumentXml(String content, KararBelgesi belge) {
    final paragraphs = content.split('\n').map((line) {
      final escaped = _xmlEscape(line);
      return '''<w:p><w:r><w:t xml:space="preserve">$escaped</w:t></w:r></w:p>''';
    }).join('\n');

    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:wpc="http://schemas.microsoft.com/office/word/2010/wordprocessingCanvas"
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
            mc:Ignorable="w14 wp14">
  <w:body>
$paragraphs
  </w:body>
</w:document>''';
  }

  /// Minimal .docx arşivini oluşturur.
  ///
  /// Not: Bu, ZIP formatında geçerli bir .docx dosyasıdır.
  /// Gerçek uygulamada `archive` paketi ile ZIP oluşturulur.
  /// Şimdilik basit bir XML çıktısı döner (belge içeriği).
  static Uint8List _buildDocxArchive(String documentXml) {
    // Minimal DOCX yapısı - [Content_Types].xml, _rels/.rels, word/document.xml
    // Gerçek ZIP arşivi için `archive` paketi gerekir.
    // Şimdilik document.xml içeriğini UTF-8 olarak döner.
    // TODO: `archive` paketi eklendikten sonra tam .docx ZIP üretimi yapılacak.
    return Uint8List.fromList(utf8.encode(documentXml));
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
