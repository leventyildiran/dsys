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

  /// Ortak AI sorgulama metodu. Özel AI (DeepSeek vb.) ayarları varsa onları kullanır, yoksa Gemini AI'a düşer.
  Future<String> _callAI(String prompt) async {
    final ayarlar = await SistemAyarlariService().get();
    final hasCustomAi = ayarlar != null && ayarlar.aiApiKey != null && ayarlar.aiApiKey!.trim().isNotEmpty;

    if (!hasCustomAi && !AppEnvironment.hasGeminiApiKey) {
      throw Exception('API Anahtarı bulunamadı (Gemini veya Özel AI).');
    }

    if (hasCustomAi) {
      String rawUrl = ayarlar.aiApiUrl?.trim() ?? '';
      if (rawUrl.isEmpty || rawUrl.contains('platform.deepseek.com')) {
        rawUrl = 'https://api.deepseek.com/v1';
      }
      String baseUrl = rawUrl;
      if (!baseUrl.endsWith('/chat/completions')) {
        if (baseUrl.endsWith('/')) {
          baseUrl = '${baseUrl}chat/completions';
        } else {
          baseUrl = '$baseUrl/chat/completions';
        }
      }
      
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
      return resData['choices'][0]['message']['content']?.toString().trim() ?? '';
    } else {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: AppEnvironment.geminiApiKey,
      );

      final response = await model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? '';
    }
  }

  /// Kural tabanlı script başarısız olursa tek maddeyi AI aracılığıyla çözümler.
  Future<YkKararModel?> _aiIleAyristir(String maddeText) async {
    try {
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

      final text = await _callAI(prompt);
      
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
      debugPrint('[GundemParserService._aiIleAyristir] Hata: $e');
      return null;
    }
  }

  /// Birimlerden gelen PDF üst yazısını / kararlarını analiz eder ve YK şablonlarına uygun kararlar üretir.
  Future<List<YkKararModel>> _aiBirimKararlariniAyristir({
    required String pdfText,
    required String toplantiId,
    required String toplantiNo,
    required String toplantiTarihi,
  }) async {
    final prompt = '''
Aşağıdaki metin bir üniversitenin biriminden (merkezinden/enstitüsünden/fakültesinden) gelen bir üst yazı ve/veya karar belgesidir.
Lütfen bu metni analiz et ve içindeki tüm kararları tek tek ayıkla.
Her bir karar için resmi Yürütme Kurulu (YK) kararı şablonuna göre taslak karar metni oluştur.

Genel Bilgiler (Belgeden Çıkarılacak):
- BIRIM_AD: Talebi gönderen birimin tam adı (Örn: Deri, Tekstil ve Seramik Tasarım Uygulama ve Araştırma Merkezi Müdürlüğü)
- BIRIM_EVRAK_TARIHI: Evrakın tarihi (Örn: 23.05.2026)
- BIRIM_EVRAK_SAYISI: Evrakın sayısı (Örn: E-14041313-050.04-351130)
- BIRIM_KURUL_TARIHI: Birimin kendi kurul/karar tarihi (Örn: 21/05/2026)
- BIRIM_TOPLANTI_SAYI: Birimin kendi kurul toplantı sayısı (Örn: 04)

Kararlar:
Metnin içinde geçen her bir karar için ayrı bir Yürütme Kurulu kararı oluştur.
Eğer karar bir Danışmanlık/Ek Ödeme/Katkı Payı kararı ise ŞABLON A'yı doldur.
Eğer karar 2547 Sayılı Kanun'un 58. maddesinin (k) fıkrası kapsamında bir sanayi işbirliği danışmanlığı ise ŞABLON B'yi doldur.

ŞABLON A (Standart Danışmanlık / Ek Ödeme):
"Üniversitemiz {BIRIM_AD} Müdürlüğü’nün {BIRIM_EVRAK_TARIHI} tarih ve {BIRIM_EVRAK_SAYISI} sayılı yazısı ile {BIRIM_KURUL_TARIHI} tarih, {BIRIM_TOPLANTI_SAYI} toplantı sayılı ve {BIRIM_KARAR_NO} numaralı kararına istinaden; Döner Sermaye Yürütme Kurulu’nun {YK_KARAR_TARIHI} tarih ve {YK_KARAR_NO} sayılı kararı ile {FIRMA_UNVAN}’nin talep ettiği “{ISIN_KONUSU}” kapsamında {DANISMANLIK_SURESI} ay süreyle Danışmanlık Hizmeti için görevlendirilen {HOCA_UNVAN} {HOCA_AD_SOYAD} tarafından verilen danışmanlık hizmetine istinaden elde edilen gelirden ayrılan katkı payından aşağıdaki gelir getirici faaliyet cetveli doğrultusunda, dönem ek ödeme katsayısının {KATSAYI} şeklinde belirlenmesi ve elde edilen puanlara göre hesaplanacak katkı payı dağıtımının gerçekleştirilmesine;"

ŞABLON B (58/k Teknik Danışmanlık):
"Üniversitemiz Yönetim Kurulunun {UYK_KARAR_TARIHI} tarih, {UYK_TOPLANTI_SAYI} toplantı sayılı, {UYK_KARAR_NO} numaralı kararıyla 2547 Sayılı Yükseköğretim Kanunun 58. maddesinin (k) fıkrası kapsamında {FIRMA_UNVAN} ye teknik danışmanlık hizmeti vermek üzere görevlendirilen {HOCA_UNVAN} {HOCA_AD_SOYAD} tarafından {HIZMET_BASLANGIC_TARIHI}-{HIZMET_BITIS_TARIHI} ({DANISMANLIK_SURESI} Aylık) tarihleri arasında gerçekleştirilen hizmet için elde edilen {GELIR_TUTARI} TL gelirden ayrılan {KATKI_PAYI_TUTARI} TL katkı payının adı geçen öğretim üyesine tahakkuk ettirilmesine;"

Kurallar:
- {YK_KARAR_TARIHI} değerini "$toplantiTarihi" yap.
- {YK_KARAR_NO} değerini "$toplantiNo" yap.
- {UYK_KARAR_TARIHI}, {UYK_TOPLANTI_SAYI}, {UYK_KARAR_NO} değerlerini eğer metinde geçiyorsa oradan al, geçmiyorsa boş bırak veya uygun bir varsayılan koy.
- Metindeki firma adı, işin konusu, hoca unvanı ve adı, süre, katsayı gibi değişkenleri çıkarıp şablonda süslü parantezli yerlere yerleştir.
- Katsayıyı iki basamaklı (Örn: 19,50 veya 0,42) formatta yaz.
- Karar metninde eğer bir tablo (örneğin hakediş dağılımı, faaliyet cetveli, taksit planları, ödeme/personel listeleri veya rakamsal dağılımlar) varsa, bu tabloyu mutlaka standart markdown tablosu formatında (`| Sütun 1 | Sütun 2 |` ve `|---|---|` şeklinde) karar metninin içine yerleştir. Tablo satırlarının başına ve sonuna mutlaka `|` karakterlerini koy.
- Eğer metin bu şablonlara hiç uymayan bir bütçe aktarımı veya personel görevlendirmesi ise, resmi dille yazılmış düzgün bir Türkçe karar metni oluştur.

Çıktı formatı mutlaka geçerli bir JSON array olmalıdır. Başka hiçbir açıklama yazısı, not veya markdown bloğu (```json gibi) ekleme, sadece JSON listesi döndür:
[
  {
    "baslik": "Karar Başlığı (Örn: Karar 2026/18 veya Birim Kararı)",
    "birimAd": "Birim Adı",
    "kararMetni": "Şablona göre doldurulmuş karar metni",
    "tur": "danismanlik" | "butceAktarim" | "ekOdeme" | "diger"
  }
]

Gelen PDF Metni:
$pdfText
''';

    try {
      final responseText = await _callAI(prompt);
      String jsonText = responseText.trim();
      
      // Extract the JSON array portion safely
      int startIndex = jsonText.indexOf('[');
      int endIndex = jsonText.lastIndexOf(']');
      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        jsonText = jsonText.substring(startIndex, endIndex + 1);
      }

      final List<dynamic> list = jsonDecode(jsonText);
      final listKarar = <YkKararModel>[];
      for (final item in list) {
        final map = item as Map<String, dynamic>;
        YkKararTuru tur = YkKararTuru.diger;
        final strTur = map['tur']?.toString().toLowerCase() ?? 'diger';
        if (strTur == 'danismanlik') {
          tur = YkKararTuru.danismanlik;
        } else if (strTur == 'butceaktarim') {
          tur = YkKararTuru.butceAktarim;
        } else if (strTur == 'ekodeme') {
          tur = YkKararTuru.ekOdeme;
        }

        listKarar.add(YkKararModel(
          id: '',
          toplantiId: toplantiId,
          toplantiNo: toplantiNo,
          kararNo: '',
          baslik: map['baslik']?.toString() ?? 'Birim Kararı',
          kararMetni: map['kararMetni']?.toString() ?? '',
          birimAd: map['birimAd']?.toString() ?? 'Bilinmeyen Birim',
          birimId: '',
          iliskiliKayitId: '',
          kararTarihi: toplantiTarihi,
          tur: tur,
          durum: YkKararDurum.taslak,
          olusturmaTarihi: DateTime.now(),
        ));
      }
      return listKarar;
    } catch (e, stackTrace) {
      debugPrint('[GundemParserService._aiBirimKararlariniAyristir] Hata: $e\n$stackTrace');
      rethrow; // Rethrow to let the UI show the actual error snackbar
    }
  }

  /// Yüklenen PDF dosyasını okur, kararları ayrıştırır ve doğrudan belirtilen toplantıya atayarak kaydeder.
  /// Ayrıca bu kararlara karşılık gelen Gündem Maddelerini üretir.
  Future<(List<YkKararModel>, List<GundemMaddesi>)> pdfToplantiyaKararVeGundemAktar({
    required String toplantiId,
    required String toplantiNo,
    required String toplantiTarihi,
    required Uint8List pdfBytes,
  }) async {
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

      // 2. Metni Parçala / Ayıkla
      final containsGundem = sanitizedMetin.toLowerCase().contains('gündem');
      final parcalar = _scriptIleParcala(sanitizedMetin);
      
      final kararlar = <YkKararModel>[];
      final gundemMaddeleri = <GundemMaddesi>[];

      if (!containsGundem || parcalar.length <= 1) {
        // Bu bir birim karar/üst yazı belgesidir. AI ile analiz et ve şablona uygun kararlar çıkar.
        final extracted = await _aiBirimKararlariniAyristir(
          pdfText: sanitizedMetin,
          toplantiId: toplantiId,
          toplantiNo: toplantiNo,
          toplantiTarihi: toplantiTarihi,
        );
        
        for (int i = 0; i < extracted.length; i++) {
          final k = extracted[i];
          final yeniKararNo = await _ykService.sonrakiKararNoUret(toplantiNo);
          
          final finalKarar = k.copyWith(
            toplantiId: toplantiId,
            toplantiNo: toplantiNo,
            kararNo: yeniKararNo,
            kararTarihi: toplantiTarihi,
            durum: YkKararDurum.taslak,
            olusturmaTarihi: DateTime.now(),
          );
          
          kararlar.add(finalKarar);
          gundemMaddeleri.add(GundemMaddesi(
            siraNo: i + 1,
            baslik: finalKarar.baslik,
            tur: _convertKararTuruToGundemTuru(finalKarar.tur),
            birimAd: finalKarar.birimAd,
            birimId: finalKarar.birimId,
            aciklama: '',
          ));
        }
      } else {
        // Klasik Gündem listesidir (Gündem 01:, Gündem 02: şeklinde parçalanabilir)
        for (int i = 0; i < parcalar.length; i++) {
          final maddeText = parcalar[i];
          YkKararModel? karar;
          if (maddeText.toLowerCase().contains('gündem')) {
            karar = _scriptIleAyristir(maddeText);
          }
          
          if (karar == null) {
            karar = await _aiIleAyristir(maddeText);
          }

          if (karar != null) {
            final yeniKararNo = await _ykService.sonrakiKararNoUret(toplantiNo);
            final guncelKarar = karar.copyWith(
              toplantiId: toplantiId,
              toplantiNo: toplantiNo,
              kararNo: yeniKararNo,
              kararTarihi: toplantiTarihi,
              durum: YkKararDurum.taslak,
            );
            
            kararlar.add(guncelKarar);
            gundemMaddeleri.add(GundemMaddesi(
              siraNo: i + 1,
              baslik: guncelKarar.baslik,
              tur: _convertKararTuruToGundemTuru(guncelKarar.tur),
              birimAd: guncelKarar.birimAd,
              birimId: guncelKarar.birimId,
              aciklama: '',
            ));
          }
        }
      }

      // 3. Firestore'a Kararları Kaydet
      for (final k in kararlar) {
        await _ykService.create(k);
      }

      return (kararlar, gundemMaddeleri);
    } catch (e) {
      debugPrint('[GundemParserService.pdfToplantiyaKararVeGundemAktar] Hata: $e');
      rethrow;
    }
  }

  GundemTuru _convertKararTuruToGundemTuru(YkKararTuru tur) {
    switch (tur) {
      case YkKararTuru.danismanlik:
        return GundemTuru.danismanlik;
      case YkKararTuru.butceAktarim:
        return GundemTuru.butceAktarim;
      case YkKararTuru.ekOdeme:
        return GundemTuru.ekOdeme;
      case YkKararTuru.disHekimligi:
        return GundemTuru.disHekimligi;
      case YkKararTuru.diger:
        return GundemTuru.diger;
    }
  }
}
