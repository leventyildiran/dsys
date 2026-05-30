import 'package:flutter/foundation.dart';

import '../models/aylik_hakedis_model.dart';
import 'firestore_service.dart';

/// Personel aylık toplam hakediş takip servisi.
///
/// Firestore yolu: `personel/{personelId}/aylikToplamHakedis/{yilAy}`
/// EYDMA yasal tavan kontrolünde kullanılır.
class PersonelHakedisService {
  PersonelHakedisService({FirestoreService? firestoreService})
      : _service = firestoreService ?? FirestoreService();

  final FirestoreService _service;

  /// Alt koleksiyon yolunu döner.
  String _path(String personelId) =>
      'personel/$personelId/aylikToplamHakedis';

  /// Belirli personelin belirli ay hakediş kaydını getirir.
  Future<AylikHakedisModel?> get(String personelId, String yilAy) async {
    try {
      final doc = await _service.get(_path(personelId), yilAy);
      if (!doc.exists || doc.data() == null) return null;
      return AylikHakedisModel.fromMap(yilAy, doc.data()!);
    } catch (e) {
      debugPrint('[PersonelHakedisService.get] Hata: $e');
      return null;
    }
  }

  /// Personelin tüm aylık hakediş kayıtlarını getirir.
  Future<List<AylikHakedisModel>> getAll(String personelId) async {
    try {
      final snapshot = await _service.getAll(_path(personelId));
      return snapshot.docs
          .map((doc) => AylikHakedisModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[PersonelHakedisService.getAll] Hata: $e');
      return [];
    }
  }

  /// Hakediş kaydını oluşturur veya günceller.
  ///
  /// `yilAy` doküman ID'si olarak kullanılır (ör: "2026-04").
  Future<void> kaydet(String personelId, AylikHakedisModel hakedis) async {
    try {
      await _service.set(
        _path(personelId),
        hakedis.yilAy,
        hakedis.toMap(),
        merge: true,
      );
    } catch (e) {
      debugPrint('[PersonelHakedisService.kaydet] Hata: $e');
      rethrow;
    }
  }

  /// Döner sermaye gelirini artırır ve toplamı günceller.
  ///
  /// Mevcut kayıt yoksa sıfırdan oluşturur.
  Future<void> donerSermayeEkle(
    String personelId,
    String yilAy,
    double eklenenTutar,
  ) async {
    try {
      final mevcut = await get(personelId, yilAy);
      final yeniDonerSermaye = (mevcut?.donerSermaye ?? 0.0) + eklenenTutar;
      final yeniToplam = yeniDonerSermaye + (mevcut?.ikinciOgretim ?? 0.0);

      await _service.set(
        _path(personelId),
        yilAy,
        {
          'donerSermaye': yeniDonerSermaye,
          'ikinciOgretim': mevcut?.ikinciOgretim ?? 0.0,
          'toplam': yeniToplam,
        },
        merge: true,
      );
    } catch (e) {
      debugPrint('[PersonelHakedisService.donerSermayeEkle] Hata: $e');
      rethrow;
    }
  }

  /// Personelin belirli bir aydaki toplam mevcut gelirini döner.
  ///
  /// EYDMA tavan kontrolünde `toplamAylikMevcutGelir` olarak kullanılır.
  Future<double> toplamAylikGelir(String personelId, String yilAy) async {
    final hakedis = await get(personelId, yilAy);
    return hakedis?.toplam ?? 0.0;
  }

  /// Hakediş kayıtlarını gerçek zamanlı dinler.
  Stream<List<AylikHakedisModel>> stream(String personelId) {
    return _service
        .stream(_path(personelId))
        .map((snapshot) => snapshot.docs
            .map((doc) => AylikHakedisModel.fromMap(doc.id, doc.data()))
            .toList());
  }
}
