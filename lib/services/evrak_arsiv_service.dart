import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../core/app_environment.dart';
import '../core/app_logger.dart';
import '../core/paginated_result.dart';
import '../models/evrak_arsiv_model.dart';
import '../models/evrak_ocr_sonucu.dart';
import 'firestore_service.dart';

/// Evrak arşiv servis katmanı.
///
/// Dahili evrak arşivi, arama, EBYS ve Firebase Storage dosya yükleme/indirme
/// özelliklerini sağlar.
/// Firestore yolu: `evraklar/{evrakId}`
class EvrakArsivService {
  EvrakArsivService({FirestoreService? firestoreService})
      : _service = firestoreService ?? FirestoreService();

  final FirestoreService _service;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String _collection = 'evraklar';
  static const String _storagePath = 'evraklar';

  /// Tüm evrakları getirir.
  Future<List<EvrakModel>> getAll() async {
    try {
      final snapshot = await _service.getAll(_collection);
      return snapshot.docs
          .map((doc) => EvrakModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[EvrakArsivService.getAll] Hata: $e');
      return [];
    }
  }

  Future<PaginatedResult<EvrakModel,
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
            .map((doc) => EvrakModel.fromMap(doc.id, doc.data()))
            .toList(),
        hasMore: page.hasMore,
        nextCursor: page.lastDocument,
      );
    } catch (e) {
      AppLogger.error(
        'Sayfalı evrak listesi yüklenemedi.',
        scope: 'evrak_arsiv_service',
        error: e,
      );
      return const PaginatedResult(items: [], hasMore: false);
    }
  }

  /// Birime göre evrakları getirir.
  Future<List<EvrakModel>> getByBirim(String birimId) async {
    try {
      final snapshot = await _service.where(
        _collection,
        field: 'birimId',
        isEqualTo: birimId,
      );
      return snapshot.docs
          .map((doc) => EvrakModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[EvrakArsivService.getByBirim] Hata: $e');
      return [];
    }
  }

  /// Evrak türüne göre filtreler.
  Future<List<EvrakModel>> getByTur(EvrakTuru tur) async {
    try {
      final snapshot = await _service.where(
        _collection,
        field: 'evrakTuru',
        isEqualTo: tur.value,
      );
      return snapshot.docs
          .map((doc) => EvrakModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[EvrakArsivService.getByTur] Hata: $e');
      return [];
    }
  }

  /// Metin bazlı arama (başlık ve içerik özeti).
  Future<List<EvrakModel>> ara(String aramaMetni) async {
    try {
      // Firestore'da tam metin arama sınırlı, client-side filtreleme
      final tumEvraklar = await getAll();
      final aramaKucuk = aramaMetni.toLowerCase();
      return tumEvraklar.where((evrak) {
        return evrak.baslik.toLowerCase().contains(aramaKucuk) ||
            (evrak.icerikOzeti?.toLowerCase().contains(aramaKucuk) ?? false) ||
            (evrak.evrakSayisi?.toLowerCase().contains(aramaKucuk) ?? false) ||
            evrak.etiketler.any((e) => e.toLowerCase().contains(aramaKucuk));
      }).toList();
    } catch (e) {
      debugPrint('[EvrakArsivService.ara] Hata: $e');
      return [];
    }
  }

  /// Tekil evrak getirir.
  Future<EvrakModel?> getById(String id) async {
    try {
      final doc = await _service.get(_collection, id);
      if (!doc.exists || doc.data() == null) return null;
      return EvrakModel.fromMap(id, doc.data()!);
    } catch (e) {
      debugPrint('[EvrakArsivService.getById] Hata: $e');
      return null;
    }
  }

  /// Yeni evrak kaydı oluşturur.
  Future<String> create(EvrakModel model) async {
    try {
      final data = model.toMap();
      data['olusturmaTarihi'] = DateTime.now().toIso8601String();
      final docRef = await _service.add(_collection, data);
      return docRef.id;
    } catch (e) {
      debugPrint('[EvrakArsivService.create] Hata: $e');
      rethrow;
    }
  }

  /// Evrak kaydını günceller.
  Future<void> update(String id, Map<String, dynamic> data) async {
    try {
      await _service.update(_collection, id, data);
    } catch (e) {
      debugPrint('[EvrakArsivService.update] Hata: $e');
      rethrow;
    }
  }

  /// Evrak arşivler (soft delete).
  Future<void> arsivle(String id) async {
    await update(id, {'durum': EvrakDurum.arsivlendi.value});
  }

  /// Evrak siler.
  Future<void> delete(String id) async {
    try {
      await _service.delete(_collection, id);
    } catch (e) {
      debugPrint('[EvrakArsivService.delete] Hata: $e');
      rethrow;
    }
  }

  /// Gerçek zamanlı dinleme.
  Stream<List<EvrakModel>> stream() {
    return _service.stream(_collection).map((snapshot) => snapshot.docs
        .map((doc) => EvrakModel.fromMap(doc.id, doc.data()))
        .toList());
  }

  // ─────────────────────────────────────────────────────────────
  // FİREBASE STORAGE - DOSYA YÜKLEME / İNDİRME
  // ─────────────────────────────────────────────────────────────

  /// PDF veya diğer dosyayı Firebase Storage'a yükler.
  ///
  /// Dosya yolu: `evraklar/{evrakId}/{dosyaAdi}`
  /// Dönüş: İndirme URL'si
  Future<String> dosyaYukle({
    required String evrakId,
    required String dosyaAdi,
    required Uint8List dosyaBytes,
    String? contentType,
  }) async {
    try {
      final ref = _storage.ref('$_storagePath/$evrakId/$dosyaAdi');
      final metadata = SettableMetadata(
        contentType: contentType ?? _contentTypeFromExtension(dosyaAdi),
      );

      await ref.putData(dosyaBytes, metadata);
      final downloadUrl = await ref.getDownloadURL();

      // Firestore'daki evrak kaydına dosya URL'sini ekle
      await update(evrakId, {
        'dosyaUrl': downloadUrl,
        'dosyaAdi': dosyaAdi,
      });

      return downloadUrl;
    } catch (e) {
      debugPrint('[EvrakArsivService.dosyaYukle] Hata: $e');
      rethrow;
    }
  }

  /// Firebase Storage'dan dosya indirir.
  ///
  /// Dönüş: Dosya byte dizisi (Uint8List)
  Future<Uint8List?> dosyaIndir(String evrakId, String dosyaAdi) async {
    try {
      final ref = _storage.ref('$_storagePath/$evrakId/$dosyaAdi');
      // Max 50MB
      final bytes = await ref.getData(50 * 1024 * 1024);
      return bytes;
    } catch (e) {
      debugPrint('[EvrakArsivService.dosyaIndir] Hata: $e');
      return null;
    }
  }

  /// Firebase Storage'dan dosya siler.
  Future<void> dosyaSil(String evrakId, String dosyaAdi) async {
    try {
      final ref = _storage.ref('$_storagePath/$evrakId/$dosyaAdi');
      await ref.delete();
    } catch (e) {
      debugPrint('[EvrakArsivService.dosyaSil] Hata: $e');
      // Dosya zaten silinmişse hata yutulur
    }
  }

  /// Dosya uzantısından MIME type belirler.
  String _contentTypeFromExtension(String dosyaAdi) {
    final ext = dosyaAdi.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }

  // ─────────────────────────────────────────────────────────────
  // GEMİNİ AI OCR FALLBACK
  // ─────────────────────────────────────────────────────────────

  /// Gemini AI ile PDF/görsel dosyadan metin çıkarımı (OCR fallback).
  ///
  /// Dosya yüklendiğinde veya içerik özeti boşsa otomatik çağrılabilir.
  /// google_generative_ai paketi kullanılır.
  ///
  /// NOT: Bu özellik düşük önceliklidir ve API anahtarı yapılandırması
  /// gerektirir. Temel altyapı hazırdır.
  Future<EvrakOcrSonucu?> geminiOcrOku(
    Uint8List dosyaBytes,
    String dosyaAdi,
  ) async {
    if (!AppEnvironment.hasGeminiApiKey) {
      AppLogger.warning(
        'Gemini API anahtarı tanımlı değil, OCR atlandı.',
        scope: 'evrak_arsiv_service',
      );
      return null;
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: AppEnvironment.geminiApiKey,
      );
      final response = await model.generateContent([
        Content.multi([
          TextPart(_ocrPrompt(dosyaAdi)),
          DataPart(_contentTypeFromExtension(dosyaAdi), dosyaBytes),
        ]),
      ]);
      final text = response.text?.trim();
      if (text == null || text.isEmpty) {
        return null;
      }
      return _parseOcrResponse(dosyaAdi, text);
    } catch (e) {
      AppLogger.error(
        'Gemini OCR çağrısı başarısız.',
        scope: 'evrak_arsiv_service',
        error: e,
      );
      return null;
    }
  }

  String _ocrPrompt(String dosyaAdi) => '''
Bu dosya bir resmi yazışma, üst yazı veya karar evrakı olabilir.
Dosyayı okuyup aşağıdaki sabit formatta yanıt ver:

BASLIK: ...
SAYI: ...
TARIH: ...
OZET: ...
ETIKETLER: etiket1, etiket2, etiket3

Kurallar:
- Tarih boşsa boş bırak.
- Evrak numarası yoksa boş bırak.
- Özet en fazla 3 cümle olsun.
- Etiketler en fazla 5 adet kısa anahtar kelime olsun.
- Baslık bulunamazsa dosya adından makul bir başlık üret.
- Yalnızca bu alanları döndür, ekstra açıklama ekleme.

Dosya adı: $dosyaAdi
''';

  EvrakOcrSonucu _parseOcrResponse(String dosyaAdi, String responseText) {
    String readField(String name) {
      final match = RegExp(
        '^$name\\s*:\\s*(.*)\$',
        caseSensitive: false,
        multiLine: true,
      ).firstMatch(responseText);
      return match?.group(1)?.trim() ?? '';
    }

    final baslik = readField('BASLIK');
    final etiketler = readField('ETIKETLER')
        .split(',')
        .map((etiket) => etiket.trim())
        .where((etiket) => etiket.isNotEmpty)
        .take(5)
        .toList();

    return EvrakOcrSonucu(
      baslik: baslik.isEmpty ? _dosyaAdindanBaslik(dosyaAdi) : baslik,
      evrakSayisi: readField('SAYI'),
      evrakTarihi: readField('TARIH'),
      icerikOzeti: readField('OZET'),
      etiketler: etiketler,
      hamCevap: responseText,
    );
  }

  String _dosyaAdindanBaslik(String dosyaAdi) {
    final temizAd = dosyaAdi.split('.').first.replaceAll(RegExp(r'[_-]+'), ' ');
    return temizAd.trim().isEmpty ? 'Yeni Evrak' : temizAd.trim();
  }
}
