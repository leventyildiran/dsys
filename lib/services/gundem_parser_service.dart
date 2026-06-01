import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../core/app_environment.dart';
import '../models/gundem_model.dart';
import '../models/yk_karar_model.dart';
import '../models/sistem_ayarlari_model.dart';
import 'data_service.dart';
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

      final sanitizedMetin = _sanitizeExtractedText(pdfMetni);

      // 2. Metni Parçala (Gündem 01:, Gündem 02: kuralına göre)
      final maddeler = _scriptIleParcala(sanitizedMetin);
      
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

  // ─────────────────────────────────────────────────────────
  // Gündem Ekranı İçin: PDF → GundemMaddesi listesi
  // ─────────────────────────────────────────────────────────

  /// PDF byte'larından düz metin çıkarır.
  String pdfMetniCikar(Uint8List pdfBytes) {
    final document = PdfDocument(inputBytes: pdfBytes);
    final textExtractor = PdfTextExtractor(document);
    final metin = textExtractor.extractText();
    document.dispose();

    if (metin.trim().isEmpty) {
      throw Exception('PDF belgesinden metin çıkarılamadı veya belge boş.');
    }
    return _sanitizeExtractedText(metin);
  }

  /// PDF text parser'dan gelen bozuk (tofu / replacement box) veya tablo çizgisi karakterlerini filtreler.
  String _sanitizeExtractedText(String text) {
    final lines = text.split('\n');
    final cleanLines = <String>[];
    
    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        cleanLines.add('');
        continue;
      }
      
      // Box/Tofu karakterlerini (\uFFFD / 65533) say
      final replacementCount = trimmed.codeUnits.where((char) => char == 0xFFFD || char == 65533).length;
      final totalLength = trimmed.length;
      
      // Eğer bir satırın %30'undan fazlası bozuk karakter ise tablo kenarı vs.'dir, tamamen atla
      if (totalLength > 0 && (replacementCount / totalLength) > 0.3) {
        continue;
      }
      
      // Geri kalan replacement karakterlerini temizle
      var cleanLine = trimmed.replaceAll('\uFFFD', '').trim();
      
      // Eğer satır boş kalırsa ya da sadece tablo çizgisi/noktalama barındırıyorsa atla
      if (cleanLine.isEmpty || RegExp(r'^[-_+|=*#\uFFFD\s]+$').hasMatch(cleanLine)) {
        continue;
      }
      
      cleanLines.add(cleanLine);
    }
    
    // Satırları tekrar birleştir, üst üste boş satır yığılmasını engelle
    final resultLines = <String>[];
    bool lastWasEmpty = false;
    for (var line in cleanLines) {
      if (line.isEmpty) {
        if (!lastWasEmpty) {
          resultLines.add('');
          lastWasEmpty = true;
        }
      } else {
        resultLines.add(line);
        lastWasEmpty = false;
      }
    }
    
    return resultLines.join('\n').trim();
  }

  /// Çıkarılan metni GundemMaddesi listesine dönüştürür.
  List<GundemMaddesi> metniGundemMaddelerineAyristir(String metin) {
    final parcalar = _scriptIleParcala(metin);
    final maddeler = <GundemMaddesi>[];

    for (int i = 0; i < parcalar.length; i++) {
      final maddeText = parcalar[i];
      final parts = maddeText.split(':');
      final baslik = parts.length >= 2
          ? parts.sublist(1).join(':').trim()
          : maddeText.trim();

      // Birim adını çıkarmaya çalış
      String birimAd = '';
      final mudurluguIndex = baslik.toLowerCase().indexOf('müdürlüğü');
      if (mudurluguIndex != -1) {
        final spaceAfter = baslik.indexOf(' ', mudurluguIndex);
        if (spaceAfter != -1 && spaceAfter < baslik.length) {
          birimAd = baslik.substring(0, spaceAfter).trim();
          birimAd = birimAd.replaceAll(RegExp(r"['\u2019]n[u\u00fc]n,\$|['\u2019]n[u\u00fc]n\$|,\$"), '').trim();
        }
      }

      // Gündem türünü tespit et
      GundemTuru tur = GundemTuru.diger;
      final lowerBaslik = baslik.toLowerCase();
      if (lowerBaslik.contains('danışmanlık') || lowerBaslik.contains('danismanlik')) {
        tur = GundemTuru.danismanlik;
      } else if (lowerBaslik.contains('ek ödeme') || lowerBaslik.contains('ek odeme')) {
        tur = GundemTuru.ekOdeme;
      } else if (lowerBaslik.contains('katkı payı') || lowerBaslik.contains('katki payi')) {
        tur = GundemTuru.ekOdeme;
      } else if (lowerBaslik.contains('bütçe aktarım') || lowerBaslik.contains('butce aktarim')) {
        tur = GundemTuru.butceAktarim;
      }

      maddeler.add(GundemMaddesi(
        siraNo: i + 1,
        baslik: baslik.isNotEmpty ? baslik : maddeText.trim(),
        tur: tur,
        birimAd: birimAd,
        aciklama: '',
      ));
    }

    return maddeler;
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
        toplantiId: '',
        toplantiNo: '',
        kararNo: '',
        baslik: baslik,
        kararMetni: icerik,
        birimAd: birimAd,
        birimId: '', // Varsayılan boş
        iliskiliKayitId: '', // Varsayılan boş
        kararTarihi: DateTime.now().toIso8601String().split('T')[0], // Bugünün tarihi
        tur: YkKararTuru.diger,
        durum: YkKararDurum.taslak,
        olusturmaTarihi: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Script ayrıştırma hatası, fallback tetiklenecek: $e');
      return null;
    }
  }

  /// Kural tabanlı script başarısız olursa tek maddeyi Gemini AI veya özel API (örn. DeepSeek) aracılığıyla çözümler.
  Future<YkKararModel?> _aiIleAyristir(String maddeText) async {
    final ayarlar = await SistemAyarlariService().get();
    final hasCustomAi = ayarlar != null && ayarlar.aiApiKey != null && ayarlar.aiApiKey!.trim().isNotEmpty;

    if (!hasCustomAi && !AppEnvironment.hasGeminiApiKey) {
      debugPrint('Gemini API veya Özel AI Ayarları bulunamadı, fallback çalıştırılamadı.');
      return null;
    }

    try {
      String text = '';
      if (hasCustomAi) {
        String baseUrl = ayarlar.aiApiUrl?.trim() ?? 'https://api.deepseek.com/v1';
        if (!baseUrl.endsWith('/chat/completions')) {
          if (baseUrl.endsWith('/')) {
            baseUrl = '${baseUrl}chat/completions';
          } else {
            baseUrl = '$baseUrl/chat/completions';
          }
        }
        
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

        final modelName = ayarlar.aiModel?.trim() ?? 'deepseek-chat';
        final response = await http.post(
          Uri.parse(baseUrl),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Authorization': 'Bearer ${ayarlar.aiApiKey}',
          },
          body: jsonEncode({
            'model': modelName,
            'messages': [
              {'role': 'user', 'content': prompt}
            ],
            'temperature': 0.1,
          }),
        );

        if (response.statusCode != 200) {
          throw Exception('API Hatası: ${response.statusCode} - ${response.body}');
        }

        final resData = jsonDecode(utf8.decode(response.bodyBytes));
        text = resData['choices'][0]['message']['content']?.toString().trim() ?? '';
      } else {
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
        text = response.text?.trim() ?? '';
      }
      
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
        birimId: '',
        iliskiliKayitId: '',
        kararTarihi: DateTime.now().toIso8601String().split('T')[0],
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
