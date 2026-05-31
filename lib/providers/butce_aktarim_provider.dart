import 'package:flutter/foundation.dart';

import '../models/butce_aktarim_model.dart';
import '../services/butce_aktarim_service.dart';

/// Bütçe aktarımları state yönetimi.
class ButceAktarimProvider extends ChangeNotifier {
  ButceAktarimProvider({ButceAktarimService? service})
      : _service = service ?? ButceAktarimService();

  final ButceAktarimService _service;

  List<ButceAktarimModel> _aktarimlar = [];
  List<ButceAktarimModel> get aktarimlar => _aktarimlar;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _hataMesaji;
  String? get hataMesaji => _hataMesaji;

  String? _basariMesaji;
  String? get basariMesaji => _basariMesaji;

  /// Tüm aktarımları yükler.
  Future<void> aktarimlariYukle() async {
    _isLoading = true;
    _hataMesaji = null;
    notifyListeners();

    try {
      _aktarimlar = await _service.getAll();
    } catch (e) {
      _hataMesaji = 'Aktarımlar yüklenirken hata: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Yeni aktarım oluşturur.
  Future<bool> aktarimOlustur(ButceAktarimModel model) async {
    try {
      await _service.create(model);
      _basariMesaji = 'Bütçe aktarımı başarıyla oluşturuldu.';
      await aktarimlariYukle();
      return true;
    } catch (e) {
      _hataMesaji = 'Aktarım oluşturulamadı: $e';
      notifyListeners();
      return false;
    }
  }

  /// Aktarım durumunu değiştirir.
  Future<bool> durumDegistir(
      String id, ButceAktarimDurum yeniDurum) async {
    try {
      await _service.durumDegistir(id, yeniDurum);
      _basariMesaji = 'Durum "${yeniDurum.displayName}" olarak güncellendi.';
      await aktarimlariYukle();
      return true;
    } catch (e) {
      _hataMesaji = 'Durum değiştirilemedi: $e';
      notifyListeners();
      return false;
    }
  }

  /// Aktarım siler.
  Future<bool> aktarimSil(String id) async {
    try {
      await _service.delete(id);
      _basariMesaji = 'Aktarım silindi.';
      await aktarimlariYukle();
      return true;
    } catch (e) {
      _hataMesaji = 'Aktarım silinemedi: $e';
      notifyListeners();
      return false;
    }
  }

  /// Mesajları temizle.
  void mesajlariTemizle() {
    _hataMesaji = null;
    _basariMesaji = null;
    notifyListeners();
  }
}
