import 'package:flutter/foundation.dart';

import '../models/dagitim_model.dart';
import 'firestore_service.dart';

/// Personel bazlı dağıtım alt-koleksiyon servisi.
///
/// Firestore yolu: `danismanliklar/{danismanlikId}/taksitler/{taksitId}/dagitim/{personelId}`
/// Her taksit onaylandığında hesaplanan kişi bazlı hakedişler buraya yazılır.
class DagitimService {
  DagitimService({FirestoreService? firestoreService})
      : _service = firestoreService ?? FirestoreService();

  final FirestoreService _service;

  /// Alt koleksiyon yolunu döner.
  String _path(String danismanlikId, String taksitId) =>
      'danismanliklar/$danismanlikId/taksitler/$taksitId/dagitim';

  /// Taksit dağıtımındaki tüm personel kayıtlarını getirir.
  Future<List<DagitimModel>> getAll(
    String danismanlikId,
    String taksitId,
  ) async {
    try {
      final snapshot = await _service.getAll(_path(danismanlikId, taksitId));
      return snapshot.docs
          .map((doc) => DagitimModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[DagitimService.getAll] Hata: $e');
      return [];
    }
  }

  /// Tek bir personelin dağıtım kaydını getirir.
  Future<DagitimModel?> getByPersonelId(
    String danismanlikId,
    String taksitId,
    String personelId,
  ) async {
    try {
      final doc = await _service.get(
        _path(danismanlikId, taksitId),
        personelId,
      );
      if (!doc.exists || doc.data() == null) return null;
      return DagitimModel.fromMap(personelId, doc.data()!);
    } catch (e) {
      debugPrint('[DagitimService.getByPersonelId] Hata: $e');
      return null;
    }
  }

  /// Personel dağıtım kaydını oluşturur/günceller.
  ///
  /// personelId doküman ID'si olarak kullanılır (doğal anahtar).
  Future<void> kaydet(
    String danismanlikId,
    String taksitId,
    DagitimModel dagitim,
  ) async {
    try {
      await _service.set(
        _path(danismanlikId, taksitId),
        dagitim.personelId,
        dagitim.toMap(),
        merge: false,
      );
    } catch (e) {
      debugPrint('[DagitimService.kaydet] Hata: $e');
      rethrow;
    }
  }

  /// Toplu dağıtım kaydı — tüm personel listesini tek seferde yazar.
  Future<void> topluKaydet(
    String danismanlikId,
    String taksitId,
    List<DagitimModel> dagitimlar,
  ) async {
    try {
      for (final dagitim in dagitimlar) {
        await _service.set(
          _path(danismanlikId, taksitId),
          dagitim.personelId,
          dagitim.toMap(),
          merge: false,
        );
      }
    } catch (e) {
      debugPrint('[DagitimService.topluKaydet] Hata: $e');
      rethrow;
    }
  }

  /// Dağıtım kayıtlarını gerçek zamanlı dinler.
  Stream<List<DagitimModel>> stream(String danismanlikId, String taksitId) {
    return _service
        .stream(_path(danismanlikId, taksitId))
        .map((snapshot) => snapshot.docs
            .map((doc) => DagitimModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Tek bir dağıtım kaydını siler.
  Future<void> delete(
    String danismanlikId,
    String taksitId,
    String personelId,
  ) async {
    try {
      await _service.delete(_path(danismanlikId, taksitId), personelId);
    } catch (e) {
      debugPrint('[DagitimService.delete] Hata: $e');
      rethrow;
    }
  }
}
