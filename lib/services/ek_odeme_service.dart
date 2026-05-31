import 'package:flutter/foundation.dart';

import '../models/ek_odeme_model.dart';
import 'firestore_service.dart';

/// Dönemsel ek ödeme dağıtım servis katmanı.
///
/// Firestore yolu: `ekOdemeler/{ekOdemeId}`
class EkOdemeService {
  EkOdemeService({FirestoreService? firestoreService})
      : _service = firestoreService ?? FirestoreService();

  final FirestoreService _service;
  static const String _collection = 'ekOdemeler';

  /// Tüm ek ödeme kayıtlarını getirir.
  Future<List<EkOdemeModel>> getAll() async {
    try {
      final snapshot = await _service.getAll(_collection);
      return snapshot.docs
          .map((doc) => EkOdemeModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[EkOdemeService.getAll] Hata: $e');
      return [];
    }
  }

  /// Birime göre ek ödemeleri getirir.
  Future<List<EkOdemeModel>> getByBirim(String birimId) async {
    try {
      final snapshot = await _service.where(
        _collection,
        field: 'birimId',
        isEqualTo: birimId,
      );
      return snapshot.docs
          .map((doc) => EkOdemeModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[EkOdemeService.getByBirim] Hata: $e');
      return [];
    }
  }

  /// Tekil ek ödeme kaydı getirir.
  Future<EkOdemeModel?> getById(String id) async {
    try {
      final doc = await _service.get(_collection, id);
      if (!doc.exists || doc.data() == null) return null;
      return EkOdemeModel.fromMap(id, doc.data()!);
    } catch (e) {
      debugPrint('[EkOdemeService.getById] Hata: $e');
      return null;
    }
  }

  /// Yeni ek ödeme kaydı oluşturur.
  Future<String> create(EkOdemeModel model) async {
    try {
      final data = model.toMap();
      data['olusturmaTarihi'] = DateTime.now().toIso8601String();
      final docRef = await _service.add(_collection, data);
      return docRef.id;
    } catch (e) {
      debugPrint('[EkOdemeService.create] Hata: $e');
      rethrow;
    }
  }

  /// Ek ödeme kaydını günceller.
  Future<void> update(String id, Map<String, dynamic> data) async {
    try {
      await _service.update(_collection, id, data);
    } catch (e) {
      debugPrint('[EkOdemeService.update] Hata: $e');
      rethrow;
    }
  }

  /// Durum değiştir.
  Future<void> durumDegistir(String id, EkOdemeDurum yeniDurum) async {
    await update(id, {'durum': yeniDurum.value});
  }

  /// Ek ödeme kaydını siler.
  Future<void> delete(String id) async {
    try {
      await _service.delete(_collection, id);
    } catch (e) {
      debugPrint('[EkOdemeService.delete] Hata: $e');
      rethrow;
    }
  }

  /// Gerçek zamanlı dinleme.
  Stream<List<EkOdemeModel>> stream() {
    return _service.stream(_collection).map((snapshot) => snapshot.docs
        .map((doc) => EkOdemeModel.fromMap(doc.id, doc.data()))
        .toList());
  }
}
