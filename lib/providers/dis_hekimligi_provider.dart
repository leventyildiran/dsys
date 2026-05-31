import 'package:flutter/foundation.dart';

import '../models/dis_hekimligi_model.dart';
import '../services/dis_hekimligi_service.dart';

/// Diş Hekimliği Katkı Payı Dağıtım state yönetimi.
class DisHekimligiProvider extends ChangeNotifier {
  DisHekimligiProvider({DisHekimligiService? service})
      : _service = service ?? DisHekimligiService();

  final DisHekimligiService _service;

  List<DisHekimligiDagitimModel> _dagitimlar = [];
  List<DisHekimligiDagitimModel> get dagitimlar => _dagitimlar;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _hataMesaji;
  String? get hataMesaji => _hataMesaji;

  String? _basariMesaji;
  String? get basariMesaji => _basariMesaji;

  /// Tüm dağıtımları yükler.
  Future<void> dagitimlariYukle() async {
    _isLoading = true;
    _hataMesaji = null;
    notifyListeners();

    try {
      _dagitimlar = await _service.getAll();
    } catch (e) {
      _hataMesaji = 'Dağıtımlar yüklenirken hata: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Yeni dağıtım oluşturur.
  Future<bool> dagitimOlustur(DisHekimligiDagitimModel model) async {
    try {
      await _service.create(model);
      _basariMesaji = 'Diş Hekimliği dağıtımı başarıyla oluşturuldu.';
      await dagitimlariYukle();
      return true;
    } catch (e) {
      _hataMesaji = 'Dağıtım oluşturulamadı: $e';
      notifyListeners();
      return false;
    }
  }

  /// Durum değiştir.
  Future<bool> durumDegistir(String id, DisHekimligiDurum yeniDurum) async {
    try {
      await _service.durumDegistir(id, yeniDurum);
      _basariMesaji = 'Durum güncellendi.';
      await dagitimlariYukle();
      return true;
    } catch (e) {
      _hataMesaji = 'Durum değiştirilemedi: $e';
      notifyListeners();
      return false;
    }
  }

  /// Siler.
  Future<bool> dagitimSil(String id) async {
    try {
      await _service.delete(id);
      _basariMesaji = 'Dağıtım silindi.';
      await dagitimlariYukle();
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
