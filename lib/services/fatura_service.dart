import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../core/paginated_result.dart';
import '../models/fatura_model.dart';
import 'data_service.dart';
import 'firestore_service.dart';

/// Fatura basım ve PDF önizleme servis katmanı.
///
/// Firestore yolu: `faturalar/{faturaId}`
class FaturaService {
  FaturaService({FirestoreService? firestoreService})
      : _service = firestoreService ?? FirestoreService();

  final FirestoreService _service;
  static const String _collection = 'faturalar';

  /// Tüm faturaları getirir.
  Future<List<FaturaModel>> getAll() async {
    try {
      final snapshot = await _service.getAll(_collection);
      return snapshot.docs
          .map((doc) => FaturaModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[FaturaService.getAll] Hata: $e');
      return [];
    }
  }

  Future<PaginatedResult<FaturaModel,
      QueryDocumentSnapshot<Map<String, dynamic>>>> getPage({
    int limit = 20,
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
  }) async {
    try {
      final page = await _service.getPage(
        _collection,
        limit: limit,
        startAfterDocument: startAfterDocument,
        queryBuilder: (ref) => ref.orderBy('olusturmaTarihi', descending: true),
      );
      return PaginatedResult(
        items: page.docs
            .map((doc) => FaturaModel.fromMap(doc.id, doc.data()))
            .toList(),
        hasMore: page.hasMore,
        nextCursor: page.lastDocument,
      );
    } catch (e) {
      debugPrint('[FaturaService.getPage] Hata: $e');
      return const PaginatedResult(items: [], hasMore: false);
    }
  }

  /// Birime göre faturaları getirir.
  Future<List<FaturaModel>> getByBirim(String birimId) async {
    try {
      final snapshot = await _service.where(
        _collection,
        field: 'birimId',
        isEqualTo: birimId,
      );
      return snapshot.docs
          .map((doc) => FaturaModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[FaturaService.getByBirim] Hata: $e');
      return [];
    }
  }

  /// Bekleyen faturaları getirir (kuyruk).
  Future<List<FaturaModel>> getBekleyenler() async {
    try {
      final snapshot = await _service.where(
        _collection,
        field: 'durum',
        isEqualTo: FaturaDurum.bekleyen.value,
      );
      return snapshot.docs
          .map((doc) => FaturaModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[FaturaService.getBekleyenler] Hata: $e');
      return [];
    }
  }

  /// Tekil fatura getirir.
  Future<FaturaModel?> getById(String id) async {
    try {
      final doc = await _service.get(_collection, id);
      if (!doc.exists || doc.data() == null) return null;
      return FaturaModel.fromMap(id, doc.data()!);
    } catch (e) {
      debugPrint('[FaturaService.getById] Hata: $e');
      return null;
    }
  }

  /// Yeni fatura kaydı oluşturur.
  Future<String> create(FaturaModel model) async {
    try {
      final data = model.toMap();
      data['olusturmaTarihi'] = DateTime.now().toIso8601String();
      final docRef = await _service.add(_collection, data);
      return docRef.id;
    } catch (e) {
      debugPrint('[FaturaService.create] Hata: $e');
      rethrow;
    }
  }

  /// Toplu fatura oluşturur (metin ayrıştırma sonrası).
  Future<List<String>> topluOlustur(List<FaturaModel> faturalar) async {
    try {
      final ids = <String>[];
      for (final fatura in faturalar) {
        final id = await create(fatura);
        ids.add(id);
      }
      return ids;
    } catch (e) {
      debugPrint('[FaturaService.topluOlustur] Hata: $e');
      rethrow;
    }
  }

  /// Fatura kaydını günceller.
  Future<void> update(String id, Map<String, dynamic> data) async {
    try {
      await _service.update(_collection, id, data);
    } catch (e) {
      debugPrint('[FaturaService.update] Hata: $e');
      rethrow;
    }
  }

  /// Fatura durumunu değiştirir.
  Future<void> durumDegistir(String id, FaturaDurum yeniDurum) async {
    await update(id, {'durum': yeniDurum.value});
  }

  /// Faturayı basıldı olarak işaretler.
  Future<void> basildiIsaretle(String id) async {
    await durumDegistir(id, FaturaDurum.basildi);
  }

  /// Metin ayrıştırma — gelen fatura taleplerini parse eder.
  ///
  /// Önce harici extractor (ayar aktifse), başarısızsa regex fallback çalışır.
  Future<List<FaturaParseSonuc>> metinAyristirGelismis(String metin) async {
    final sanitized = _sanitizeExtractedText(metin);
    final harici = await _hariciExtractorIleAyristir(sanitized);
    if (harici.isNotEmpty) {
      return harici;
    }
    return metinAyristir(sanitized);
  }

  /// PDF'ten metin çıkarır.
  String pdfMetniCikar(Uint8List pdfBytes) {
    final document = PdfDocument(inputBytes: pdfBytes);
    final textExtractor = PdfTextExtractor(document);
    final metin = textExtractor.extractText();
    document.dispose();

    if (metin.trim().isEmpty) {
      throw Exception('PDF belgesinden metin çıkarılamadı veya belge boş.');
    }
    return metin;
  }

  /// PDF içeriğini ayrıştırır; üst yazı bölümlerini atlayıp fatura satırlarını işler.
  Future<List<FaturaParseSonuc>> pdfAyristir(Uint8List pdfBytes) async {
    final hamMetin = pdfMetniCikar(pdfBytes);
    final temizMetin = _sanitizeExtractedText(hamMetin);
    final ustYaziAtlanmis = _ustYaziyiAtla(temizMetin);
    return metinAyristirGelismis(ustYaziAtlanmis);
  }

  /// Belgedeki üst yazı/sunum kısmını atlayarak veri tablosuna yaklaşır.
  String _ustYaziyiAtla(String metin) {
    final satirlar = metin.split('\n');
    if (satirlar.isEmpty) return metin;

    final veriBaslangicRegex = RegExp(
      r'(numune\s*no|melbes|başvuru\s*no|basvuru\s*no|firma|unvan|hizmet|analiz|tahlil|kalem|miktar|birim\s*fiyat|toplam|kdv)',
      caseSensitive: false,
    );

    var baslangic = -1;
    for (var i = 0; i < satirlar.length; i++) {
      if (veriBaslangicRegex.hasMatch(satirlar[i])) {
        baslangic = i;
        break;
      }
    }

    if (baslangic <= 0) return metin;

    final from = baslangic > 2 ? baslangic - 2 : 0;
    return satirlar.sublist(from).join('\n').trim();
  }

  String _sanitizeExtractedText(String text) {
    final lines = text.split('\n');
    final cleanLines = <String>[];
    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        cleanLines.add('');
        continue;
      }

      final replacementCount = trimmed.codeUnits
          .where((char) => char == 0xFFFD || char == 65533)
          .length;
      final totalLength = trimmed.length;
      if (totalLength > 0 && (replacementCount / totalLength) > 0.3) {
        continue;
      }

      final cleanLine = trimmed.replaceAll('\uFFFD', '').trim();
      if (cleanLine.isEmpty ||
          RegExp(r'^[-_+|=*#\s]+$').hasMatch(cleanLine)) {
        continue;
      }
      cleanLines.add(cleanLine);
    }

    final resultLines = <String>[];
    var lastWasEmpty = false;
    for (final line in cleanLines) {
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

  Future<List<FaturaParseSonuc>> _hariciExtractorIleAyristir(String metin) async {
    try {
      final ayarlar = await SistemAyarlariService().get();
      if (ayarlar == null || !ayarlar.hasActiveExtractor) {
        return const [];
      }

      final url = ayarlar.extractorApiUrl!.trim();
      final headers = <String, String>{
        'Content-Type': 'application/json; charset=utf-8',
      };
      final apiKey = ayarlar.extractorApiKey?.trim() ?? '';
      if (apiKey.isNotEmpty) {
        headers['Authorization'] =
            apiKey.startsWith('Bearer ') ? apiKey : 'Bearer $apiKey';
      }

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({
          'task': 'fatura_extract',
          'provider': ayarlar.extractorProvider,
          'pdfText': metin,
          'requiredFields': const [
            'firmaUnvan',
            'hizmetDetay',
            'tutar',
            'numuneNo',
            'melbesBasvuruNo',
          ],
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Extractor API hatası: ${response.statusCode}');
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      List<dynamic> rawList;
      if (decoded is List) {
        rawList = decoded;
      } else if (decoded is Map<String, dynamic> && decoded['faturalar'] is List) {
        rawList = decoded['faturalar'] as List<dynamic>;
      } else if (decoded is Map<String, dynamic> && decoded['items'] is List) {
        rawList = decoded['items'] as List<dynamic>;
      } else {
        throw Exception('Extractor çıktısı beklenen formatta değil.');
      }

      final sonuclar = <FaturaParseSonuc>[];
      for (final item in rawList) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item as Map);

        final firma = _firstNonEmpty(
          map,
          const ['firmaUnvan', 'firma', 'sirket', 'unvan'],
        );
        final hizmet = _firstNonEmpty(
          map,
          const ['hizmetDetay', 'hizmet', 'aciklama'],
        );
        final numuneNo = _firstNonEmpty(
          map,
          const ['numuneNo', 'numune', 'numune_no'],
        );
        final melbesBasvuruNo = _firstNonEmpty(
          map,
          const [
            'melbesBasvuruNo',
            'melbes_basvuru_no',
            'basvuruNo',
            'basvuru_no',
          ],
        );
        final kalemler = _extractKalemlerFromExtractorMap(map);
        var tutar = _toDouble(map['tutar'] ?? map['bedel'] ?? map['ucret']);
        if (tutar <= 0 && kalemler.isNotEmpty) {
          tutar = kalemler.fold<double>(0, (acc, item) => acc + item.tutar);
        }
        final finalHizmet = hizmet.isNotEmpty
            ? hizmet
            : kalemler.map((k) => k.aciklama).join(' | ');

        if (firma.isEmpty && finalHizmet.isEmpty && tutar <= 0) {
          continue;
        }

        sonuclar.add(FaturaParseSonuc(
          firmaUnvan: firma,
          hizmetDetay: finalHizmet,
          tutar: tutar,
          kalemler: kalemler,
          numuneNo: numuneNo.isEmpty ? null : numuneNo,
          melbesBasvuruNo:
              melbesBasvuruNo.isEmpty ? null : melbesBasvuruNo,
        ));
      }

      return sonuclar;
    } catch (e) {
      debugPrint('[FaturaService._hariciExtractorIleAyristir] Hata: $e');
      return const [];
    }
  }

  String _firstNonEmpty(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  List<FaturaKalem> _extractKalemlerFromExtractorMap(Map<String, dynamic> map) {
    final dynamic raw = map['kalemler'] ?? map['satirlar'] ?? map['items'];
    if (raw is! List) return const [];

    final kalemler = <FaturaKalem>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final row = Map<String, dynamic>.from(item as Map);
      final aciklama = _firstNonEmpty(
        row,
        const ['aciklama', 'hizmet', 'test', 'ad'],
      );
      if (aciklama.isEmpty) continue;
      final adet = (row['adet'] as num?)?.toInt() ??
          int.tryParse((row['adet'] ?? '').toString()) ??
          1;
      final birimFiyat = _toDouble(
        row['birimFiyat'] ?? row['fiyat'] ?? row['ucret'] ?? row['bedel'],
      );
      final tutar = _toDouble(row['tutar'] ?? row['toplam']);
      final finalTutar = tutar > 0 ? tutar : birimFiyat * adet;

      kalemler.add(FaturaKalem(
        aciklama: aciklama,
        adet: adet,
        birimFiyat: birimFiyat,
        tutar: finalTutar,
      ));
    }

    return kalemler;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    final raw = value.toString().trim();
    if (raw.isEmpty) return 0;
    final normalized = raw.replaceAll(RegExp(r'[^0-9,\.]'), '');
    if (normalized.contains(',') && normalized.contains('.')) {
      final fixed = normalized.replaceAll('.', '').replaceAll(',', '.');
      return double.tryParse(fixed) ?? 0;
    }
    if (normalized.contains(',')) {
      return double.tryParse(normalized.replaceAll(',', '.')) ?? 0;
    }
    return double.tryParse(normalized) ?? 0;
  }

  ///
  /// Regex tabanlı kural bazlı ayrıştırma (Script-First).
  /// Düzensiz metinler için AI fallback gerekir.
  List<FaturaParseSonuc> metinAyristir(String metin) {
    final tabloSonuclari = _tabloFormatiniAyristir(metin);
    if (tabloSonuclari.isNotEmpty) {
      return tabloSonuclari;
    }

    final sonuclar = <FaturaParseSonuc>[];
    final satirlar = metin.split('\n').where((s) => s.trim().isNotEmpty);

    // Basit regex bazlı ayrıştırma
    final firmaRegex = RegExp(r'(?:firma|şirket|unvan)\s*[:\-]\s*(.+)', caseSensitive: false);
    final tutarRegex = RegExp(r'(?:tutar|ücret|bedel)\s*[:\-]\s*([\d.,]+)', caseSensitive: false);
    final hizmetRegex = RegExp(r'(?:hizmet|analiz|tahlil|test)\s*[:\-]\s*(.+)', caseSensitive: false);
    final numuneNoRegex = RegExp(r'(?:numune\s*no|numune\s*nr|numune\s*#)\s*[:\-]?\s*(.+)', caseSensitive: false);
    final melbesBasvuruNoRegex = RegExp(r'(?:melbes\s*başvuru\s*no|melbes\s*basvuru\s*no|başvuru\s*no|basvuru\s*no)\s*[:\-]?\s*(.+)', caseSensitive: false);

    String? mevcutFirma;
    String? mevcutHizmet;
    double? mevcutTutar;
    String? mevcutNumuneNo;
    String? mevcutMelbesBasvuruNo;

    for (final satir in satirlar) {
      final firmaMatch = firmaRegex.firstMatch(satir);
      final tutarMatch = tutarRegex.firstMatch(satir);
      final hizmetMatch = hizmetRegex.firstMatch(satir);
      final numuneNoMatch = numuneNoRegex.firstMatch(satir);
      final melbesBasvuruNoMatch = melbesBasvuruNoRegex.firstMatch(satir);

      if (firmaMatch != null) {
        // Önceki kaydı kaydet
        if (mevcutFirma != null) {
          final oncekiKalemler = <FaturaKalem>[];
          if ((mevcutHizmet ?? '').trim().isNotEmpty) {
            oncekiKalemler.add(FaturaKalem(
              aciklama: mevcutHizmet!.trim(),
              adet: 1,
              birimFiyat: mevcutTutar ?? 0,
              tutar: mevcutTutar ?? 0,
            ));
          }
          sonuclar.add(FaturaParseSonuc(
            firmaUnvan: mevcutFirma,
            hizmetDetay: mevcutHizmet ?? '',
            tutar: mevcutTutar ?? 0,
            kalemler: oncekiKalemler,
            numuneNo: mevcutNumuneNo,
            melbesBasvuruNo: mevcutMelbesBasvuruNo,
          ));
        }
        mevcutFirma = firmaMatch.group(1)?.trim();
        mevcutHizmet = null;
        mevcutTutar = null;
        mevcutNumuneNo = null;
        mevcutMelbesBasvuruNo = null;
      }

      if (hizmetMatch != null) {
        mevcutHizmet = hizmetMatch.group(1)?.trim();
      }

      if (tutarMatch != null) {
        final tutarStr = tutarMatch.group(1)?.replaceAll('.', '').replaceAll(',', '.');
        mevcutTutar = double.tryParse(tutarStr ?? '0');
      }

      if (numuneNoMatch != null) {
        mevcutNumuneNo = numuneNoMatch.group(1)?.trim();
      }

      if (melbesBasvuruNoMatch != null) {
        mevcutMelbesBasvuruNo = melbesBasvuruNoMatch.group(1)?.trim();
      }
    }

    // Son kaydı ekle
    if (mevcutFirma != null) {
      final kalemler = <FaturaKalem>[];
      if ((mevcutHizmet ?? '').trim().isNotEmpty) {
        kalemler.add(FaturaKalem(
          aciklama: mevcutHizmet!.trim(),
          adet: 1,
          birimFiyat: mevcutTutar ?? 0,
          tutar: mevcutTutar ?? 0,
        ));
      }
      sonuclar.add(FaturaParseSonuc(
        firmaUnvan: mevcutFirma,
        hizmetDetay: mevcutHizmet ?? '',
        tutar: mevcutTutar ?? 0,
        kalemler: kalemler,
        numuneNo: mevcutNumuneNo,
        melbesBasvuruNo: mevcutMelbesBasvuruNo,
      ));
    }

    return sonuclar;
  }

  List<FaturaParseSonuc> _tabloFormatiniAyristir(String metin) {
    final normalized = metin.trim();
    if (normalized.isEmpty) return const [];

    final tabloIpuclari = RegExp(
      r'(fatura\s*bilgileri|numune\s*a[çc]iklamasi|numune\s*alim\s*tarihi|birim\s*fiyat|toplam\s*fiyat)',
      caseSensitive: false,
    );
    if (!tabloIpuclari.hasMatch(normalized)) {
      return const [];
    }

    final melbesRegex = RegExp(
      r'melbes\s*ba[sş]vuru\s*no\s*[:\-]?\s*([a-z0-9\-/]+)',
      caseSensitive: false,
    );
    final melbesMatches = melbesRegex.allMatches(normalized).toList();

    final bloklar = <String>[];
    if (melbesMatches.isEmpty) {
      bloklar.add(normalized);
    } else {
      for (var i = 0; i < melbesMatches.length; i++) {
        final start = i == 0 ? 0 : melbesMatches[i].start;
        final end = (i + 1 < melbesMatches.length)
            ? melbesMatches[i + 1].start
            : normalized.length;
        bloklar.add(normalized.substring(start, end));
      }
    }

    final sonuclar = <FaturaParseSonuc>[];
    for (final blok in bloklar) {
      final melbesNo = _extractWithRegex(
        blok,
        RegExp(
          r'melbes\s*ba[sş]vuru\s*no\s*[:\-]?\s*([a-z0-9\-/]+)',
          caseSensitive: false,
        ),
      );
      final numuneNo = _extractWithRegex(
        blok,
        RegExp(
          r'numune\s*no\s*[:\-]?\s*([a-z0-9\-/]+)',
          caseSensitive: false,
        ),
      );

      if (melbesNo == null && numuneNo == null) {
        continue;
      }

      final firma = _extractFirmaFromBlock(blok);
      final kalemler = _extractKalemlerFromBlock(blok);
      final toplamSatir = _extractWithRegex(
        blok,
        RegExp(
          r'toplam\s*fiyat[^\d]*([\d\.]+,\d{2})',
          caseSensitive: false,
        ),
      );

      final toplam = toplamSatir != null
          ? _toDouble(toplamSatir)
          : kalemler.fold<double>(0, (acc, item) => acc + item.tutar);

      final hizmetDetay = kalemler.isEmpty
          ? 'Numune analizi'
          : kalemler.map((k) => k.aciklama).join(' | ');

      sonuclar.add(FaturaParseSonuc(
        firmaUnvan: firma,
        hizmetDetay: hizmetDetay,
        tutar: toplam,
        kalemler: kalemler,
        numuneNo: numuneNo,
        melbesBasvuruNo: melbesNo,
      ));
    }

    return sonuclar;
  }

  String _extractFirmaFromBlock(String blok) {
    final satirlar = blok
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final firmaRegex = RegExp(
      r'(ltd\.?\s*[şs]ti\.?|a\.?\s*[şs]\.?|anonim|san\.?|tic\.?|limited)',
      caseSensitive: false,
    );

    for (var i = 0; i < satirlar.length; i++) {
      if (firmaRegex.hasMatch(satirlar[i])) {
        final next = (i + 1 < satirlar.length && satirlar[i + 1].length < 80)
            ? ' ${satirlar[i + 1]}'
            : '';
        return '${satirlar[i]}$next'.trim();
      }
    }

    return 'Firma Bilgisi Ayrıştırılamadı';
  }

  List<FaturaKalem> _extractKalemlerFromBlock(String blok) {
    final satirlar = blok.split('\n');
    final kalemler = <FaturaKalem>[];
    final kalemRegex = RegExp(
      r'^(.*?)\s+\*?\s*(\d+)\s+\p{Sc}?\s*([\d\.]+,\d{2})\s*$',
      caseSensitive: false,
      unicode: true,
    );

    for (final hamSatir in satirlar) {
      final satir = hamSatir.trim();
      if (satir.isEmpty) continue;
      final match = kalemRegex.firstMatch(satir);
      if (match == null) continue;

      final aciklama = (match.group(1) ?? '').trim();
      final adet = int.tryParse((match.group(2) ?? '1').trim()) ?? 1;
      final fiyatStr = (match.group(3) ?? '').trim();
      final birimFiyat = _toDouble(fiyatStr);
      final tutar = birimFiyat * adet;
      if (aciklama.isEmpty || tutar <= 0) continue;
      kalemler.add(FaturaKalem(
        aciklama: aciklama,
        adet: adet,
        birimFiyat: birimFiyat,
        tutar: tutar,
      ));
    }

    return kalemler;
  }

  String? _extractWithRegex(String text, RegExp regex) {
    final match = regex.firstMatch(text);
    final value = match?.group(1)?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  /// Fatura kaydını siler.
  Future<void> delete(String id) async {
    try {
      await _service.delete(_collection, id);
    } catch (e) {
      debugPrint('[FaturaService.delete] Hata: $e');
      rethrow;
    }
  }

  /// Gerçek zamanlı dinleme.
  Stream<List<FaturaModel>> stream() {
    return _service.stream(_collection).map((snapshot) => snapshot.docs
        .map((doc) => FaturaModel.fromMap(doc.id, doc.data()))
        .toList());
  }
}

/// Metin ayrıştırma sonucu.
class FaturaParseSonuc {
  const FaturaParseSonuc({
    required this.firmaUnvan,
    required this.hizmetDetay,
    required this.tutar,
    this.kalemler = const [],
    this.numuneNo,
    this.melbesBasvuruNo,
  });

  final String firmaUnvan;
  final String hizmetDetay;
  final double tutar;
  final List<FaturaKalem> kalemler;
  final String? numuneNo;
  final String? melbesBasvuruNo;
}
