import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/generate_content.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../core/app_environment.dart';
import '../models/yk_karar_model.dart';
import 'yk_karar_service.dart';

/// PDF formatındaki gündem maddelerini okuyarak YK Karar Taslaklarına dönüştürür.
/// Birincil olarak kural tabanlı (Regex/Script) çalışır.
/// Karmaşık maddelerde ise yapay zeka (Gemini AI) fallback olarak devreye girer.
class GundemParserService {
  GundemParserService({YkKararService? ykService})
      : _ykService = ykService ?? YkKararService();

  final YkKararService _ykService;

  /// Yüklenen PDF dosyasını okur, gündemleri parçalar ve taslak olarak havuza kaydeder.
  Future<List<String>> pdfGundemIceriAktar(Uint8List pdfBytes) async {
    try {
      // 1. PDF'ten Metni Çıkar
      final document = PdfDocument(inputBytes: pdfBytes);
      final textExtractor = PdfTextExtractor(document);
      final pdfMetni = textExtractor.extractText();
      document.dispose();

      if (pdfMetni.trim().isEmpty) {
        throw Exception('PDF belgesinden metin çıkarılamadı veya belge boş.');
      }

      // 2. Metni Parçala (Gündem 01:, Gündem 02: kuralına göre)
      final maddeler = _scriptIleParcala(pdfMetni);
      
      // 3. Karar Modellerine Dönüştür
      final kararlar = <YkKararModel>[];
      
      for (final maddeText in maddeler) {
        YkKararModel? karar = _scriptIleAyristir(maddeText);
        
        // Eğer script ayıklayamazsa (örn: format çok karışık) AI Fallback devreye girer
        if (karar == null) {
          karar = await _aiIleAyristir(maddeText);
        }

        if (karar != null) {
          kararlar.add(karar);
        }
      }

      // 4. Firestore'a Taslak Olarak Ekle
      final idListesi = <String>[];
      for (final k in kararlar) {
        final id = await _ykService.create(k);
        idListesi.add(id);
      }

      return idListesi;
    } catch (e) {
      debugPrint('[GundemParserService.pdfGundemIceriAktar] Hata: $e');
      rethrow;
    }
  }

  /// Metni "Gündem \d{1,2}:" desenine göre parçalar.
  List<String> _scriptIleParcala(String metin) {
    // "Gündem 01:", "Gündem 1:", "Gündem 01 :" vb. her varyasyonu yakalar
    final regex = RegExp(r'Gündem\s+\d{1,2}\s*:', caseSensitive: false);
    final matches = regex.allMatches(metin).toList();

    if (matches.isEmpty) {
      // Hiç Gündem ayracı bulunamadıysa metni tek bir madde olarak al
      return [metin];
    }

    final maddeler = <String>[];
    for (int i = 0; i < matches.length; i++) {
      final start = matches[i].start;
      final end = (i + 1 < matches.length) ? matches[i + 1].start : metin.length;
      maddeler.add(metin.substring(start, end).trim());
    }

    return maddeler;
  }

  /// Tek bir gündem maddesini kural tabanlı olarak Karar Model'e dönüştürür.
  YkKararModel? _scriptIleAyristir(String maddeText) {
    // Örnek Gelen: "Gündem 01: Deri, Tekstil... Müdürlüğü'nün, ... görüşülmesi;"
    try {
      final parts = maddeText.split(':');
      if (parts.length < 2) return null; // Format dışı
      
      final baslik = parts[0].trim(); // Örn: Gündem 01
      final icerik = parts.sublist(1).join(':').trim(); // Geri kalanı

      // Birim Adı Çıkarma Denemesi (Müdürlüğü kelimesine kadar olan kısım)
      String birimAd = 'Genel / Belirsiz Birim';
      final mudurluguIndex = icerik.toLowerCase().indexOf('müdürlüğü');
      if (mudurluguIndex != -1) {
        // "Müdürlüğü" veya "Müdürlüğü'nün" kelimesinin sonunu bul
        final spaceAfter = icerik.indexOf(' ', mudurluguIndex);
        if (spaceAfter != -1 && spaceAfter < icerik.length) {
           birimAd = icerik.substring(0, spaceAfter).trim();
           // Fazlalık noktalama varsa temizle
           birimAd = birimAd.replaceAll(RegExp(r"['’]n[uü]n,$|['’]n[uü]n$|,$"), '').trim();
        }
      }

      // Çok karmaşık mı? (Örneğin içinde çok fazla satır veya anlamsız tablo varsa AI'a pasla)
      // Ancak genellikle bu script başarılı olacaktır.
      
      return YkKararModel(
        id: '',
        toplantiId: '', // Havuza düşmesi için boş
        toplantiNo: '',
        kararNo: '', // Toplantı sonrası atanacak
        baslik: baslik,
        kararMetni: icerik,
        birimAd: birimAd,
        tur: YkKararTuru.diger, // Varsayılan, daha sonra YK değiştirebilir
        durum: YkKararDurum.taslak, // İnceleme için taslak olarak düşer
        olusturmaTarihi: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Script ayrıştırma hatası, fallback tetiklenecek: $e');
      return null;
    }
  }

  /// Kural tabanlı script başarısız olursa tek maddeyi Gemini AI'ye gönderir.
  Future<YkKararModel?> _aiIleAyristir(String maddeText) async {
    if (!AppEnvironment.hasGeminiApiKey) {
      debugPrint('Gemini API yok, fallback çalıştırılamadı.');
      return null; // AI kapalıysa null dön (veri kaybolacak)
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: AppEnvironment.geminiApiKey,
      );

      final prompt = '''
Aşağıdaki metin bir yönetim kurulu gündem maddesidir. Bu metni analiz et ve şu 3 bilgiyi çıkar:
1. Baslik: Maddenin başlığı veya numarası (Örn: Gündem 01).
2. BirimAd: Talebi yapan merkezin veya birimin tam adı. Bulamazsan "Bilinmiyor" yaz.
3. KararMetni: Maddenin detay açıklaması.

Sonucu sadece aşağıdaki formatta, başka hiçbir kelime eklemeden döndür:
BASLIK: [başlık buraya]
BIRIM: [birim buraya]
METIN: [metin buraya]

Gündem Maddesi Metni:
$maddeText
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';
      
      final baslikMatch = RegExp(r'BASLIK:\s*(.+)').firstMatch(text);
      final birimMatch = RegExp(r'BIRIM:\s*(.+)').firstMatch(text);
      final metinMatch = RegExp(r'METIN:\s*(.+)').firstMatch(text);

      final baslik = baslikMatch?.group(1)?.trim() ?? 'Gündem Maddesi (AI)';
      final birim = birimMatch?.group(1)?.trim() ?? 'Bilinmiyor';
      final metin = metinMatch?.group(1)?.trim() ?? maddeText;

      return YkKararModel(
        id: '',
        toplantiId: '',
        toplantiNo: '',
        kararNo: '',
        baslik: baslik,
        kararMetni: metin,
        birimAd: birim,
        tur: YkKararTuru.diger,
        durum: YkKararDurum.taslak,
        olusturmaTarihi: DateTime.now(),
      );
    } catch (e) {
      debugPrint('AI Fallback hatası: $e');
      return null;
    }
  }
}
