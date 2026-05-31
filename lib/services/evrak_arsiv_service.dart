import 'package:flutter/foundation.dart';

import '../models/evrak_arsiv_model.dart';
import 'firestore_service.dart';

/// Evrak arşiv servis katmanı.
///
/// Dahili evrak arşivi, arama ve EBYS özelliklerini sağlar.
/// Firestore yolu: `evraklar/{evrakId}`
class EvrakArsivService {
  EvrakArsivService({FirestoreService? firestoreService})
      : _service = firestoreService ?? FirestoreService();

  final FirestoreService _service;
  static const String _collection = 'evraklar';

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
}
