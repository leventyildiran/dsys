import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/paginated_result.dart';
import '../models/dis_hekimligi_model.dart';
import 'firestore_service.dart';

/// Diş Hekimliği Katkı Payı Dağıtım servis katmanı.
///
/// Firestore yolu: `disHekimligiDagitimlari/{dagitimId}`
class DisHekimligiService {
  DisHekimligiService({FirestoreService? firestoreService})
      : _service = firestoreService ?? FirestoreService();

  final FirestoreService _service;
  static const String _collection = 'disHekimligiDagitimlari';

  /// Tüm dağıtım kayıtlarını getirir.
  Future<List<DisHekimligiDagitimModel>> getAll() async {
    try {
      final snapshot = await _service.getAll(_collection);
      return snapshot.docs
          .map((doc) => DisHekimligiDagitimModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[DisHekimligiService.getAll] Hata: $e');
      return [];
    }

    Future<PaginatedResult<DisHekimligiDagitimModel,
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
              .map((doc) => DisHekimligiDagitimModel.fromMap(doc.id, doc.data()))
              .toList(),
          hasMore: page.hasMore,
          nextCursor: page.lastDocument,
        );
      } catch (e) {
        debugPrint('[DisHekimligiService.getPage] Hata: $e');
        return const PaginatedResult(items: [], hasMore: false);
      }
    }
  }

  /// Tekil dağıtım kaydı getirir.
  Future<DisHekimligiDagitimModel?> getById(String id) async {
    try {
      final doc = await _service.get(_collection, id);
      if (!doc.exists || doc.data() == null) return null;
      return DisHekimligiDagitimModel.fromMap(id, doc.data()!);
    } catch (e) {
      debugPrint('[DisHekimligiService.getById] Hata: $e');
      return null;
    }
  }

  /// Yeni dağıtım kaydı oluşturur.
  Future<String> create(DisHekimligiDagitimModel model) async {
    try {
      final data = model.toMap();
      data['olusturmaTarihi'] = DateTime.now().toIso8601String();
      final docRef = await _service.add(_collection, data);
      return docRef.id;
    } catch (e) {
      debugPrint('[DisHekimligiService.create] Hata: $e');
      rethrow;
    }
  }

  /// Dağıtım kaydını günceller.
  Future<void> update(String id, Map<String, dynamic> data) async {
    try {
      await _service.update(_collection, id, data);
    } catch (e) {
      debugPrint('[DisHekimligiService.update] Hata: $e');
      rethrow;
    }
  }

  /// Durum değiştir.
  Future<void> durumDegistir(String id, DisHekimligiDurum yeniDurum) async {
    await update(id, {'durum': yeniDurum.value});
  }

  /// Dağıtım kaydını siler.
  Future<void> delete(String id) async {
    try {
      await _service.delete(_collection, id);
    } catch (e) {
      debugPrint('[DisHekimligiService.delete] Hata: $e');
      rethrow;
    }
  }

  /// Gerçek zamanlı dinleme.
  Stream<List<DisHekimligiDagitimModel>> stream() {
    return _service.stream(_collection).map((snapshot) => snapshot.docs
        .map((doc) => DisHekimligiDagitimModel.fromMap(doc.id, doc.data()))
        .toList());
  }
}
