import 'package:flutter/foundation.dart';

import '../models/butce_limit_model.dart';
import 'firestore_service.dart';

/// Bütçe Ödenek Takip servisi.
///
/// Firestore yolu: `butceLimitleri/{limitId}`
/// Harcama talepleri: `harcamaTalepleri/{talepId}`
class ButceTakipService {
  ButceTakipService({FirestoreService? firestoreService})
      : _service = firestoreService ?? FirestoreService();

  final FirestoreService _service;
  static const String _limitsCollection = 'butceLimitleri';
  static const String _taleplerCollection = 'harcamaTalepleri';

  // ─────────────────────────────────────────────────────────────
  // BÜTÇE LİMİT İŞLEMLERİ
  // ─────────────────────────────────────────────────────────────

  /// Tüm bütçe limitlerini getirir.
  Future<List<ButceLimitModel>> getAll() async {
    try {
      final snapshot = await _service.getAll(_limitsCollection);
      return snapshot.docs
          .map((doc) => ButceLimitModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[ButceTakipService.getAll] Hata: $e');
      return [];
    }
  }

  /// Yıla göre bütçe limitlerini getirir.
  Future<List<ButceLimitModel>> getByYil(int yil) async {
    try {
      final snapshot = await _service.where(
        _limitsCollection,
        field: 'yil',
        isEqualTo: yil,
      );
      return snapshot.docs
          .map((doc) => ButceLimitModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[ButceTakipService.getByYil] Hata: $e');
      return [];
    }
  }

  /// Birime göre bütçe limitlerini getirir.
  Future<List<ButceLimitModel>> getByBirim(String birimId) async {
    try {
      final snapshot = await _service.where(
        _limitsCollection,
        field: 'birimId',
        isEqualTo: birimId,
      );
      return snapshot.docs
          .map((doc) => ButceLimitModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[ButceTakipService.getByBirim] Hata: $e');
      return [];
    }
  }

  /// Birim ve yıla göre bütçe limiti getirir.
  Future<ButceLimitModel?> getByBirimVeYil(String birimId, int yil) async {
    try {
      final tumu = await getByBirim(birimId);
      return tumu.where((l) => l.yil == yil).firstOrNull;
    } catch (e) {
      debugPrint('[ButceTakipService.getByBirimVeYil] Hata: $e');
      return null;
    }
  }

  /// Tekil limit kaydı getirir.
  Future<ButceLimitModel?> getById(String id) async {
    try {
      final doc = await _service.get(_limitsCollection, id);
      if (!doc.exists || doc.data() == null) return null;
      return ButceLimitModel.fromMap(id, doc.data()!);
    } catch (e) {
      debugPrint('[ButceTakipService.getById] Hata: $e');
      return null;
    }
  }

  /// Yeni bütçe limiti oluşturur.
  Future<String> create(ButceLimitModel model) async {
    try {
      final data = model.toMap();
      data['olusturmaTarihi'] = DateTime.now().toIso8601String();
      data['guncellenmeTarihi'] = DateTime.now().toIso8601String();
      final docRef = await _service.add(_limitsCollection, data);
      return docRef.id;
    } catch (e) {
      debugPrint('[ButceTakipService.create] Hata: $e');
      rethrow;
    }
  }

  /// Bütçe limitini günceller.
  Future<void> update(String id, Map<String, dynamic> data) async {
    try {
      data['guncellenmeTarihi'] = DateTime.now().toIso8601String();
      await _service.update(_limitsCollection, id, data);
    } catch (e) {
      debugPrint('[ButceTakipService.update] Hata: $e');
      rethrow;
    }
  }

  /// Bütçe limitini siler.
  Future<void> delete(String id) async {
    try {
      await _service.delete(_limitsCollection, id);
    } catch (e) {
      debugPrint('[ButceTakipService.delete] Hata: $e');
      rethrow;
    }
  }

  /// Gerçek zamanlı dinleme.
  Stream<List<ButceLimitModel>> stream() {
    return _service.stream(_limitsCollection).map((snapshot) => snapshot.docs
        .map((doc) => ButceLimitModel.fromMap(doc.id, doc.data()))
        .toList());
  }

  // ─────────────────────────────────────────────────────────────
  // %10 LİMİT KONTROL ALGORİTMASI
  // ─────────────────────────────────────────────────────────────

  /// Harcama yapılmadan önce limit kontrolü yapar.
  ///
  /// Kümülatif harcama, ödenek limitinin %110'unu (ödenek + %10 tolerans)
  /// aşarsa işlemi bloke eder ve YK onayına yönlendirir.
  ///
  /// Dönüş: null = işlem geçebilir, [HarcamaTalebi] = bloke edildi.
  Future<HarcamaTalebi?> limitKontrol({
    required String birimId,
    required String birimAd,
    required String kalemKod,
    required double yeniHarcamaTutar,
    required String aciklama,
    required int yil,
  }) async {
    try {
      final limit = await getByBirimVeYil(birimId, yil);
      if (limit == null) {
        // Limit tanımlı değilse kontrol yapılamaz, geçiş izni ver
        return null;
      }

      // İlgili kalemi bul
      final kalem = limit.kalemler
          .where((k) => k.kod == kalemKod)
          .firstOrNull;

      if (kalem == null) {
        // Kalem bulunamadı, geçiş izni ver
        return null;
      }

      // Yeni kümülatif harcamayı hesapla
      final yeniKumulatif = kalem.harcamaTutar + yeniHarcamaTutar;
      final limitSinir = kalem.odenekTutar * 1.10; // %10 tolerans

      if (yeniKumulatif > limitSinir) {
        // Limit aşılıyor! İşlemi bloke et ve YK onayına yönlendir.
        final talep = HarcamaTalebi(
          id: '',
          birimId: birimId,
          birimAd: birimAd,
          kalemKod: kalemKod,
          tutar: yeniHarcamaTutar,
          aciklama: aciklama,
          durum: HarcamaTalebiDurum.ykOnayinda,
          olusturmaTarihi: DateTime.now(),
        );

        // Talebi Firestore'a kaydet
        await _talepOlustur(talep);
        return talep;
      }

      // Limit dahilinde, harcamayı ekle
      await _harcamaEkle(limit.id, kalemKod, yeniHarcamaTutar);
      return null;
    } catch (e) {
      debugPrint('[ButceTakipService.limitKontrol] Hata: $e');
      rethrow;
    }
  }

  /// Harcamayı kalem kümülatifine ekler.
  Future<void> _harcamaEkle(
    String limitId,
    String kalemKod,
    double tutar,
  ) async {
    final limit = await getById(limitId);
    if (limit == null) return;

    final yeniKalemler = limit.kalemler.map((k) {
      if (k.kod == kalemKod) {
        return k.copyWith(harcamaTutar: k.harcamaTutar + tutar);
      }
      return k;
    }).toList();

    final yeniToplamHarcama = limit.toplamHarcama + tutar;

    await update(limitId, {
      'kalemler': yeniKalemler.map((k) => k.toMap()).toList(),
      'toplamHarcama': yeniToplamHarcama,
    });
  }

  // ─────────────────────────────────────────────────────────────
  // HARCAMA TALEPLERİ (YK ONAYI)
  // ─────────────────────────────────────────────────────────────

  /// Harcama talebi oluşturur (bloke edilen işlem).
  Future<String> _talepOlustur(HarcamaTalebi talep) async {
    try {
      final data = talep.toMap();
      data['olusturmaTarihi'] = DateTime.now().toIso8601String();
      final docRef = await _service.add(_taleplerCollection, data);
      return docRef.id;
    } catch (e) {
      debugPrint('[ButceTakipService._talepOlustur] Hata: $e');
      rethrow;
    }
  }

  /// Tüm harcama taleplerini getirir.
  Future<List<HarcamaTalebi>> getTalepler() async {
    try {
      final snapshot = await _service.getAll(_taleplerCollection);
      return snapshot.docs
          .map((doc) => HarcamaTalebi.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[ButceTakipService.getTalepler] Hata: $e');
      return [];
    }
  }

  /// Bekleyen harcama taleplerini getirir.
  Future<List<HarcamaTalebi>> getBekleyenTalepler() async {
    try {
      final snapshot = await _service.where(
        _taleplerCollection,
        field: 'durum',
        isEqualTo: HarcamaTalebiDurum.ykOnayinda.value,
      );
      return snapshot.docs
          .map((doc) => HarcamaTalebi.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[ButceTakipService.getBekleyenTalepler] Hata: $e');
      return [];
    }
  }

  /// Harcama talebini onaylar veya reddeder.
  Future<void> talepDurumDegistir(
      String talepId, HarcamaTalebiDurum yeniDurum) async {
    try {
      await _service.update(_taleplerCollection, talepId, {
        'durum': yeniDurum.value,
      });
    } catch (e) {
      debugPrint('[ButceTakipService.talepDurumDegistir] Hata: $e');
      rethrow;
    }
  }
}
