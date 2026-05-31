import 'package:flutter/foundation.dart';

import '../core/hesaplama_motoru.dart';
import '../models/ek_odeme_model.dart';
import '../services/ek_odeme_service.dart';

/// Dönemsel ek ödeme dağıtımı state yönetimi.
class EkOdemeProvider extends ChangeNotifier {
  EkOdemeProvider({EkOdemeService? service})
      : _service = service ?? EkOdemeService();

  final EkOdemeService _service;

  List<EkOdemeModel> _ekOdemeler = [];
  List<EkOdemeModel> get ekOdemeler => _ekOdemeler;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _hataMesaji;
  String? get hataMesaji => _hataMesaji;

  String? _basariMesaji;
  String? get basariMesaji => _basariMesaji;

  /// Tüm ek ödemeleri yükler.
  Future<void> ekOdemeleriYukle() async {
    _isLoading = true;
    _hataMesaji = null;
    notifyListeners();

    try {
      _ekOdemeler = await _service.getAll();
    } catch (e) {
      _hataMesaji = 'Ek ödemeler yüklenirken hata: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Yeni ek ödeme oluşturur.
  Future<bool> ekOdemeOlustur(EkOdemeModel model) async {
    try {
      await _service.create(model);
      _basariMesaji = 'Ek ödeme dağıtımı başarıyla oluşturuldu.';
      await ekOdemeleriYukle();
      return true;
    } catch (e) {
      _hataMesaji = 'Ek ödeme oluşturulamadı: $e';
      notifyListeners();
      return false;
    }
  }

  /// Katsayı hesaplaması yapar.
  ///
  /// Hakediş = Bireysel Puan × Dönem Katsayısı
  double katsayiHesapla(
      double dagitilabilirTutar, List<EkOdemePersonel> personeller) {
    if (personeller.isEmpty) return 0;

    double toplamPuan = 0;
    for (final p in personeller) {
      toplamPuan += p.puan * p.unvanKatsayisi;
    }

    if (toplamPuan <= 0) return 0;

    final puanModelleri = personeller
        .map((p) => PersonelPuanModel(
              personelId: p.personelId,
              faaliyetPuani: p.puan,
              unvanKatsayisi: p.unvanKatsayisi,
            ))
        .toList();

    return HesaplamaMotoru.katsayiSimulasyonu(
      dagitilabilirTutar,
      toplamPuan,
      puanModelleri,
    );
  }

  /// Durum değiştir.
  Future<bool> durumDegistir(String id, EkOdemeDurum yeniDurum) async {
    try {
      await _service.durumDegistir(id, yeniDurum);
      _basariMesaji = 'Durum güncellendi.';
      await ekOdemeleriYukle();
      return true;
    } catch (e) {
      _hataMesaji = 'Durum değiştirilemedi: $e';
      notifyListeners();
      return false;
    }
  }

  /// Siler.
  Future<bool> ekOdemeSil(String id) async {
    try {
      await _service.delete(id);
      _basariMesaji = 'Ek ödeme silindi.';
      await ekOdemeleriYukle();
      return true;
    } catch (e) {
      _hataMesaji = 'Silinemedi: $e';
      notifyListeners();
      return false;
    }
  }

  void mesajlariTemizle() {
    _hataMesaji = null;
    _basariMesaji = null;
    notifyListeners();
  }
}
