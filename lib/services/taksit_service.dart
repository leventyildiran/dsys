import 'package:flutter/foundation.dart';

import '../models/taksit_model.dart';
import 'firestore_service.dart';

/// Taksit alt-koleksiyon servisi.
///
/// Firestore yolu: `danismanliklar/{danismanlikId}/taksitler/{taksitId}`
/// CRUD + durum geçiş yönetimi sağlar.
class TaksitService {
  TaksitService({FirestoreService? firestoreService})
      : _service = firestoreService ?? FirestoreService();

  final FirestoreService _service;

  /// Alt koleksiyon yolunu döner.
  String _path(String danismanlikId) => 'danismanliklar/$danismanlikId/taksitler';

  /// Danışmanlığa ait tüm taksitleri getirir.
  Future<List<TaksitModel>> getAll(String danismanlikId) async {
    try {
      final snapshot = await _service.getAll(
        _path(danismanlikId),
        queryBuilder: (ref) => ref.orderBy('ayNo'),
      );
      return snapshot.docs
          .map((doc) => TaksitModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[TaksitService.getAll] Hata: $e');
      return [];
    }
  }

  /// Tek bir taksiti getirir.
  Future<TaksitModel?> getById(String danismanlikId, String taksitId) async {
    try {
      final doc = await _service.get(_path(danismanlikId), taksitId);
      if (!doc.exists || doc.data() == null) return null;
      return TaksitModel.fromMap(taksitId, doc.data()!);
    } catch (e) {
      debugPrint('[TaksitService.getById] Hata: $e');
      return null;
    }
  }

  /// Yeni taksit oluşturur.
  Future<String> create(String danismanlikId, TaksitModel taksit) async {
    try {
      return await _service.create(_path(danismanlikId), taksit.toMap());
    } catch (e) {
      debugPrint('[TaksitService.create] Hata: $e');
      rethrow;
    }
  }

  /// Taksiti günceller (sadece belirtilen alanlar).
  Future<void> update(
    String danismanlikId,
    String taksitId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _service.update(_path(danismanlikId), taksitId, data);
    } catch (e) {
      debugPrint('[TaksitService.update] Hata: $e');
      rethrow;
    }
  }

  /// Taksit durumunu bir sonraki aşamaya geçirir.
  ///
  /// İzin verilen geçişler:
  /// taslak → mudur_onayinda → merkez_onayinda → yk_gundeminde → onaylandi → odendi
  Future<void> durumGecisi(
    String danismanlikId,
    String taksitId,
    TaksitDurum yeniDurum,
  ) async {
    try {
      final data = <String, dynamic>{'durum': yeniDurum.value};

      // Ödendi durumuna geçildiğinde ödeme tarihini otomatik ata
      if (yeniDurum == TaksitDurum.odendi) {
        data['odemeTarihi'] = DateTime.now().toIso8601String();
      }

      await _service.update(_path(danismanlikId), taksitId, data);
    } catch (e) {
      debugPrint('[TaksitService.durumGecisi] Hata: $e');
      rethrow;
    }
  }

  /// Geçerli durum geçişi kontrol eder.
  ///
  /// Döner: geçiş uygunsa `true`, değilse `false`.
  static bool gecisUygunMu(TaksitDurum mevcut, TaksitDurum hedef) {
    const gecisler = {
      TaksitDurum.taslak: [TaksitDurum.mudurOnayinda],
      TaksitDurum.mudurOnayinda: [TaksitDurum.merkezOnayinda, TaksitDurum.taslak],
      TaksitDurum.merkezOnayinda: [TaksitDurum.ykGundeminde, TaksitDurum.mudurOnayinda],
      TaksitDurum.ykGundeminde: [TaksitDurum.onaylandi, TaksitDurum.merkezOnayinda],
      TaksitDurum.onaylandi: [TaksitDurum.odendi],
      TaksitDurum.odendi: <TaksitDurum>[],
      TaksitDurum.gecikti: [TaksitDurum.odendi],
    };

    return gecisler[mevcut]?.contains(hedef) ?? false;
  }

  /// Danışmanlığa ait taksitleri gerçek zamanlı dinler.
  Stream<List<TaksitModel>> stream(String danismanlikId) {
    return _service
        .stream(
          _path(danismanlikId),
          queryBuilder: (ref) => ref.orderBy('ayNo'),
        )
        .map((snapshot) => snapshot.docs
            .map((doc) => TaksitModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Belirli durumdaki taksitleri filtreler.
  Future<List<TaksitModel>> getByDurum(
    String danismanlikId,
    TaksitDurum durum,
  ) async {
    try {
      final snapshot = await _service.getAll(
        _path(danismanlikId),
        queryBuilder: (ref) => ref.where('durum', isEqualTo: durum.value),
      );
      return snapshot.docs
          .map((doc) => TaksitModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[TaksitService.getByDurum] Hata: $e');
      return [];
    }
  }

  /// Taksiti siler.
  Future<void> delete(String danismanlikId, String taksitId) async {
    try {
      await _service.delete(_path(danismanlikId), taksitId);
    } catch (e) {
      debugPrint('[TaksitService.delete] Hata: $e');
      rethrow;
    }
  }
}
