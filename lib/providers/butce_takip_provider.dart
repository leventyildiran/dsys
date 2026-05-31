import 'package:flutter/foundation.dart';

import '../models/butce_limit_model.dart';
import '../services/butce_takip_service.dart';

/// Bütçe Ödenek Takip state yönetimi.
///
/// Birim bazlı yıllık ödenek takibi, %10 limit kontrol algoritması
/// ve YK onayına yönlendirme mekanizmasını yönetir.
class ButceTakipProvider extends ChangeNotifier {
  ButceTakipProvider({ButceTakipService? service})
      : _service = service ?? ButceTakipService();

  final ButceTakipService _service;

  // ─────────────────────────────────────────────────────────────
  // STATE
  // ─────────────────────────────────────────────────────────────

  List<ButceLimitModel> _limitler = [];
  List<ButceLimitModel> get limitler => _limitler;

  List<HarcamaTalebi> _bekleyenTalepler = [];
  List<HarcamaTalebi> get bekleyenTalepler => _bekleyenTalepler;

  ButceLimitModel? _seciliLimit;
  ButceLimitModel? get seciliLimit => _seciliLimit;

  int _seciliYil = DateTime.now().year;
  int get seciliYil => _seciliYil;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _hataMesaji;
  String? get hataMesaji => _hataMesaji;

  String? _basariMesaji;
  String? get basariMesaji => _basariMesaji;

  // ─────────────────────────────────────────────────────────────
  // KONSOLİDE DASHBOARD VERİLERİ
  // ─────────────────────────────────────────────────────────────

  /// Toplam ödenek tutarı (tüm birimler).
  double get toplamOdenek =>
      _limitler.fold(0, (sum, l) => sum + l.toplamOdenek);

  /// Toplam harcama tutarı (tüm birimler).
  double get toplamHarcama =>
      _limitler.fold(0, (sum, l) => sum + l.toplamHarcama);

  /// Genel kullanım oranı.
  double get genelKullanimOrani =>
      toplamOdenek == 0 ? 0 : toplamHarcama / toplamOdenek;

  /// Limit aşan birim sayısı.
  int get limitAsanBirimSayisi =>
      _limitler.where((l) => l.limitAsimi).length;

  // ─────────────────────────────────────────────────────────────
  // VERİ YÜKLEME
  // ─────────────────────────────────────────────────────────────

  /// Seçili yıla göre tüm bütçe limitlerini yükler.
  Future<void> limitleriYukle() async {
    _isLoading = true;
    _hataMesaji = null;
    notifyListeners();

    try {
      _limitler = await _service.getByYil(_seciliYil);
      _bekleyenTalepler = await _service.getBekleyenTalepler();
    } catch (e) {
      _hataMesaji = 'Bütçe limitleri yüklenirken hata: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Yıl değiştirir ve verileri yeniden yükler.
  Future<void> yilDegistir(int yil) async {
    _seciliYil = yil;
    await limitleriYukle();
  }

  /// Belirli bir birim limitini seçer.
  void limitSec(ButceLimitModel limit) {
    _seciliLimit = limit;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────
  // BÜTÇE LİMİT CRUD
  // ─────────────────────────────────────────────────────────────

  /// Yeni bütçe limiti oluşturur.
  Future<bool> limitOlustur(ButceLimitModel model) async {
    try {
      await _service.create(model);
      _basariMesaji = 'Bütçe limiti başarıyla oluşturuldu.';
      await limitleriYukle();
      return true;
    } catch (e) {
      _hataMesaji = 'Bütçe limiti oluşturulamadı: $e';
      notifyListeners();
      return false;
    }
  }

  /// Bütçe limitini günceller.
  Future<bool> limitGuncelle(String id, ButceLimitModel model) async {
    try {
      await _service.update(id, model.toMap());
      _basariMesaji = 'Bütçe limiti güncellendi.';
      await limitleriYukle();
      return true;
    } catch (e) {
      _hataMesaji = 'Güncelleme hatası: $e';
      notifyListeners();
      return false;
    }
  }

  /// Bütçe limitini siler.
  Future<bool> limitSil(String id) async {
    try {
      await _service.delete(id);
      _basariMesaji = 'Bütçe limiti silindi.';
      await limitleriYukle();
      return true;
    } catch (e) {
      _hataMesaji = 'Silinemedi: $e';
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // %10 LİMİT KONTROL MEKANİZMASI
  // ─────────────────────────────────────────────────────────────

  /// Harcama yapmadan önce limit kontrolü yapar.
  ///
  /// Eğer harcama kümülasyonu ödenekın %110'unu aşacaksa:
  /// - İşlem bloke edilir
  /// - Harcama talebi YK onayına yönlendirilir
  /// - Kullanıcıya uyarı gösterilir
  ///
  /// Dönüş: true = işlem geçti, false = bloke edildi (YK onayı gerekli)
  Future<bool> harcamaKontrol({
    required String birimId,
    required String birimAd,
    required String kalemKod,
    required double tutar,
    required String aciklama,
  }) async {
    try {
      final talep = await _service.limitKontrol(
        birimId: birimId,
        birimAd: birimAd,
        kalemKod: kalemKod,
        yeniHarcamaTutar: tutar,
        aciklama: aciklama,
        yil: _seciliYil,
      );

      if (talep != null) {
        _hataMesaji =
            'UYARI: "$kalemKod" kaleminde %10 ödenek limiti aşılıyor! '
            'İşlem bloke edildi ve YK onayına yönlendirildi.';
        _bekleyenTalepler = await _service.getBekleyenTalepler();
        notifyListeners();
        return false;
      }

      _basariMesaji = 'Harcama başarıyla kaydedildi.';
      await limitleriYukle();
      return true;
    } catch (e) {
      _hataMesaji = 'Limit kontrolü sırasında hata: $e';
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // YK ONAYI TALEPLERİ
  // ─────────────────────────────────────────────────────────────

  /// Harcama talebini onaylar.
  Future<bool> talepOnayla(String talepId) async {
    try {
      await _service.talepDurumDegistir(talepId, HarcamaTalebiDurum.onaylandi);
      _basariMesaji = 'Harcama talebi onaylandı.';
      _bekleyenTalepler = await _service.getBekleyenTalepler();
      notifyListeners();
      return true;
    } catch (e) {
      _hataMesaji = 'Talep onaylanamadı: $e';
      notifyListeners();
      return false;
    }
  }

  /// Harcama talebini reddeder.
  Future<bool> talepReddet(String talepId) async {
    try {
      await _service.talepDurumDegistir(talepId, HarcamaTalebiDurum.reddedildi);
      _basariMesaji = 'Harcama talebi reddedildi.';
      _bekleyenTalepler = await _service.getBekleyenTalepler();
      notifyListeners();
      return true;
    } catch (e) {
      _hataMesaji = 'Talep reddedilemedi: $e';
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // YARDIMCI
  // ─────────────────────────────────────────────────────────────

  void mesajlariTemizle() {
    _hataMesaji = null;
    _basariMesaji = null;
    notifyListeners();
  }
}
