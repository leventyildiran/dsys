import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/paginated_result.dart';
import '../models/butce_aktarim_model.dart';
import 'firestore_service.dart';

/// Bütçe aktarımları servis katmanı.
///
/// Firestore yolu: `butceAktarimlari/{aktarimId}`
class ButceAktarimService {
  ButceAktarimService({FirestoreService? firestoreService})
      : _service = firestoreService ?? FirestoreService();

  final FirestoreService _service;
  static const String _collection = 'butceAktarimlari';

  /// Tüm bütçe aktarımlarını getirir.
  Future<List<ButceAktarimModel>> getAll() async {
    try {
      final snapshot = await _service.getAll(_collection);
      return snapshot.docs
          .map((doc) => ButceAktarimModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[ButceAktarimService.getAll] Hata: $e');
      return [];
    }

    Future<PaginatedResult<ButceAktarimModel,
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
              .map((doc) => ButceAktarimModel.fromMap(doc.id, doc.data()))
              .toList(),
          hasMore: page.hasMore,
          nextCursor: page.lastDocument,
        );
      } catch (e) {
        debugPrint('[ButceAktarimService.getPage] Hata: $e');
        return const PaginatedResult(items: [], hasMore: false);
      }
    }
  }

  /// Birime göre aktarımları getirir.
  Future<List<ButceAktarimModel>> getByBirim(String birimId) async {
    try {
      final snapshot = await _service.where(
        _collection,
        field: 'birimId',
        isEqualTo: birimId,
      );
      return snapshot.docs
          .map((doc) => ButceAktarimModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[ButceAktarimService.getByBirim] Hata: $e');
      return [];
    }
  }

  /// Tekil aktarım kaydı getirir.
  Future<ButceAktarimModel?> getById(String id) async {
    try {
      final doc = await _service.get(_collection, id);
      if (!doc.exists || doc.data() == null) return null;
      return ButceAktarimModel.fromMap(id, doc.data()!);
    } catch (e) {
      debugPrint('[ButceAktarimService.getById] Hata: $e');
      return null;
    }
  }

  /// Yeni aktarım kaydı oluşturur.
  Future<String> create(ButceAktarimModel model) async {
    try {
      final data = model.toMap();
      data['olusturmaTarihi'] = DateTime.now().toIso8601String();
      final docRef = await _service.add(_collection, data);
      return docRef.id;
    } catch (e) {
      debugPrint('[ButceAktarimService.create] Hata: $e');
      rethrow;
    }
  }

  /// Aktarım kaydını günceller.
  Future<void> update(String id, Map<String, dynamic> data) async {
    try {
      await _service.update(_collection, id, data);
    } catch (e) {
      debugPrint('[ButceAktarimService.update] Hata: $e');
      rethrow;
    }
  }

  /// Aktarım durumunu değiştirir.
  Future<void> durumDegistir(String id, ButceAktarimDurum yeniDurum) async {
    await update(id, {'durum': yeniDurum.value});
  }

  /// Aktarım kaydını siler.
  Future<void> delete(String id) async {
    try {
      await _service.delete(_collection, id);
    } catch (e) {
      debugPrint('[ButceAktarimService.delete] Hata: $e');
      rethrow;
    }
  }

  /// Gerçek zamanlı dinleme.
  Stream<List<ButceAktarimModel>> stream() {
    return _service.stream(_collection).map((snapshot) => snapshot.docs
        .map((doc) => ButceAktarimModel.fromMap(doc.id, doc.data()))
        .toList());
  }
}
