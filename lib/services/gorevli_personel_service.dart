import 'package:flutter/foundation.dart';

import '../models/gorevli_personel_model.dart';
import 'firestore_service.dart';

/// Danışmanlığa atanan görevli personel alt-koleksiyon servisi.
///
/// Firestore yolu: `danismanliklar/{danismanlikId}/gorevliPersonel/{atamaId}`
/// Personel görevlendirmelerini Firestore'da persist eder.
class GorevliPersonelService {
  GorevliPersonelService({FirestoreService? firestoreService})
      : _service = firestoreService ?? FirestoreService();

  final FirestoreService _service;

  /// Alt koleksiyon yolunu döner.
  String _path(String danismanlikId) =>
      'danismanliklar/$danismanlikId/gorevliPersonel';

  /// Danışmanlığa atanmış tüm personeli getirir.
  Future<List<GorevliPersonelModel>> getAll(String danismanlikId) async {
    try {
      final snapshot = await _service.getAll(_path(danismanlikId));
      return snapshot.docs
          .map((doc) => GorevliPersonelModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[GorevliPersonelService.getAll] Hata: $e');
      return [];
    }
  }

  /// Personel ataması oluşturur.
  Future<String> create(
    String danismanlikId,
    GorevliPersonelModel atama,
  ) async {
    try {
      return await _service.create(_path(danismanlikId), atama.toMap());
    } catch (e) {
      debugPrint('[GorevliPersonelService.create] Hata: $e');
      rethrow;
    }
  }

  /// Personel atamasını günceller (payOranı vb.).
  Future<void> update(
    String danismanlikId,
    String atamaId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _service.update(_path(danismanlikId), atamaId, data);
    } catch (e) {
      debugPrint('[GorevliPersonelService.update] Hata: $e');
      rethrow;
    }
  }

  /// Personel atamasını kaldırır.
  Future<void> delete(String danismanlikId, String atamaId) async {
    try {
      await _service.delete(_path(danismanlikId), atamaId);
    } catch (e) {
      debugPrint('[GorevliPersonelService.delete] Hata: $e');
      rethrow;
    }
  }

  /// Görevli personel listesini gerçek zamanlı dinler.
  Stream<List<GorevliPersonelModel>> stream(String danismanlikId) {
    return _service
        .stream(_path(danismanlikId))
        .map((snapshot) => snapshot.docs
            .map((doc) => GorevliPersonelModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Toplu atama — birden fazla personeli atomik olarak ekler.
  Future<void> topluEkle(
    String danismanlikId,
    List<GorevliPersonelModel> atamalar,
  ) async {
    try {
      final batch = _service.batch();
      final collRef = _service.collection(_path(danismanlikId));

      for (final atama in atamalar) {
        batch.set(collRef.doc(), atama.toMap());
      }

      await batch.commit();
    } catch (e) {
      debugPrint('[GorevliPersonelService.topluEkle] Hata: $e');
      rethrow;
    }
  }
}
