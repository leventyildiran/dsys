import 'package:flutter/foundation.dart';

import 'firestore_service.dart';

/// Raporlama servis katmanı.
///
/// Detaylı arama, raporlama ve arşivleme özelliklerini sağlar.
/// Tüm kararların yıl bazlı sorgulanması, gelir/dağıtım analizi,
/// birim performansları ve hoca bazlı yıllık gelir arşivlerini sunar.
class RaporlamaService {
  RaporlamaService({FirestoreService? firestoreService})
      : _service = firestoreService ?? FirestoreService();

  final FirestoreService _service;

  /// Birim bazlı gelir raporu getirir.
  Future<List<BirimGelirRapor>> birimGelirRaporu({String? yil}) async {
    try {
      final danismanliklar = await _service.getAll('danismanliklar');
      final raporMap = <String, BirimGelirRapor>{};

      for (final doc in danismanliklar.docs) {
        final data = doc.data();
        final birimId = data['birimId'] ?? '';
        final birimAd = data['birimKisaAd'] ?? birimId;
        final tutar = (data['toplamTutar'] ?? 0).toDouble();

        if (raporMap.containsKey(birimId)) {
          raporMap[birimId] = raporMap[birimId]!.copyWith(
            toplamGelir: raporMap[birimId]!.toplamGelir + tutar,
            danismanlikSayisi: raporMap[birimId]!.danismanlikSayisi + 1,
          );
        } else {
          raporMap[birimId] = BirimGelirRapor(
            birimId: birimId,
            birimAd: birimAd,
            toplamGelir: tutar,
            danismanlikSayisi: 1,
          );
        }
      }

      return raporMap.values.toList()
        ..sort((a, b) => b.toplamGelir.compareTo(a.toplamGelir));
    } catch (e) {
      debugPrint('[RaporlamaService.birimGelirRaporu] Hata: $e');
      return [];
    }
  }

  /// Personel bazlı yıllık gelir raporu.
  Future<List<PersonelGelirRapor>> personelGelirRaporu(String yil) async {
    try {
      final personeller = await _service.getAll('personel');
      final raporlar = <PersonelGelirRapor>[];

      for (final doc in personeller.docs) {
        final data = doc.data();
        raporlar.add(PersonelGelirRapor(
          personelId: doc.id,
          adSoyad: data['adSoyad'] ?? '',
          unvan: data['unvan'] ?? '',
          birimId: data['birimId'] ?? '',
          yillikToplamGelir: 0, // Hesaplanacak
        ));
      }

      return raporlar;
    } catch (e) {
      debugPrint('[RaporlamaService.personelGelirRaporu] Hata: $e');
      return [];
    }
  }

  /// Genel istatistikler.
  Future<GenelIstatistik> genelIstatistikler() async {
    try {
      final danismanliklar = await _service.getAll('danismanliklar');
      final personel = await _service.getAll('personel');
      final firmalar = await _service.getAll('firmalar');

      double toplamGelir = 0;
      int aktifDanismanlik = 0;

      for (final doc in danismanliklar.docs) {
        final data = doc.data();
        toplamGelir += (data['toplamTutar'] ?? 0).toDouble();
        if (data['durum'] == 'aktif') aktifDanismanlik++;
      }

      return GenelIstatistik(
        toplamDanismanlik: danismanliklar.docs.length,
        aktifDanismanlik: aktifDanismanlik,
        toplamPersonel: personel.docs.length,
        toplamFirma: firmalar.docs.length,
        toplamGelir: toplamGelir,
      );
    } catch (e) {
      debugPrint('[RaporlamaService.genelIstatistikler] Hata: $e');
      return const GenelIstatistik(
        toplamDanismanlik: 0,
        aktifDanismanlik: 0,
        toplamPersonel: 0,
        toplamFirma: 0,
        toplamGelir: 0,
      );
    }
  }
}

/// Birim gelir rapor modeli.
class BirimGelirRapor {
  const BirimGelirRapor({
    required this.birimId,
    required this.birimAd,
    required this.toplamGelir,
    required this.danismanlikSayisi,
  });

  final String birimId;
  final String birimAd;
  final double toplamGelir;
  final int danismanlikSayisi;

  BirimGelirRapor copyWith({
    double? toplamGelir,
    int? danismanlikSayisi,
  }) {
    return BirimGelirRapor(
      birimId: birimId,
      birimAd: birimAd,
      toplamGelir: toplamGelir ?? this.toplamGelir,
      danismanlikSayisi: danismanlikSayisi ?? this.danismanlikSayisi,
    );
  }
}

/// Personel gelir rapor modeli.
class PersonelGelirRapor {
  const PersonelGelirRapor({
    required this.personelId,
    required this.adSoyad,
    required this.unvan,
    required this.birimId,
    required this.yillikToplamGelir,
  });

  final String personelId;
  final String adSoyad;
  final String unvan;
  final String birimId;
  final double yillikToplamGelir;
}

/// Genel istatistik modeli.
class GenelIstatistik {
  const GenelIstatistik({
    required this.toplamDanismanlik,
    required this.aktifDanismanlik,
    required this.toplamPersonel,
    required this.toplamFirma,
    required this.toplamGelir,
  });

  final int toplamDanismanlik;
  final int aktifDanismanlik;
  final int toplamPersonel;
  final int toplamFirma;
  final double toplamGelir;
}
