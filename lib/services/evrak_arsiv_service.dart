import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/evrak_arsiv_model.dart';
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
  Future<String?> geminiOcrOku(Uint8List dosyaBytes, String dosyaAdi) async {
    try {
      // ignore: avoid_dynamic_calls
      final {
        'google_generative_ai': _,
      } = <String, dynamic>{
        'google_generative_ai': null,
      };

      // Gemini AI OCR entegrasyonu:
      // Bu metod, google_generative_ai paketi üzerinden Gemini Pro Vision
      // modelini kullanarak PDF/görsel dosyalardan metin çıkarımı yapar.
      //
      // Kullanım:
      // 1. API anahtarı ayarlanmalı (ortam değişkeni veya Remote Config)
      // 2. Dosya base64 encode edilerek modele gönderilir
      // 3. Dönen metin evrak içerik özetine yazılır
      //
      // NOT: Bu özellik düşük önceliklidir ve API anahtarı yapılandırması
      // gerektirir. Temel altyapı hazırdır.
      debugPrint(
          '[EvrakArsivService.geminiOcrOku] OCR çıkarımı başlatılıyor: $dosyaAdi');

      // Placeholder: Gerçek implementasyon API anahtarı ile yapılacak
      return null;
    } catch (e) {
      debugPrint('[EvrakArsivService.geminiOcrOku] Hata: $e');
      return null;
    }
  }
}
