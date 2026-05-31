import 'package:flutter/foundation.dart';

import '../models/evrak_arsiv_model.dart';
import '../services/evrak_arsiv_service.dart';

/// Evrak arşiv state yönetimi.
class EvrakArsivProvider extends ChangeNotifier {
  EvrakArsivProvider({EvrakArsivService? service})
      : _service = service ?? EvrakArsivService();

  final EvrakArsivService _service;

  List<EvrakModel> _evraklar = [];
  List<EvrakModel> get evraklar => _evraklar;

  List<EvrakModel> _aramaSonuclari = [];
  List<EvrakModel> get aramaSonuclari => _aramaSonuclari;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _aramaAktif = false;
  bool get aramaAktif => _aramaAktif;

  String? _hataMesaji;
  String? get hataMesaji => _hataMesaji;

  String? _basariMesaji;
  String? get basariMesaji => _basariMesaji;

  /// Tüm evrakları yükler.
  Future<void> evraklariYukle() async {
    _isLoading = true;
    _hataMesaji = null;
    _aramaAktif = false;
    notifyListeners();

    try {
      _evraklar = await _service.getAll();
    } catch (e) {
      _hataMesaji = 'Evraklar yüklenirken hata: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Metin bazlı arama yapar.
  Future<void> ara(String aramaMetni) async {
    if (aramaMetni.trim().isEmpty) {
      _aramaAktif = false;
      _aramaSonuclari = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _aramaAktif = true;
    notifyListeners();

    try {
      _aramaSonuclari = await _service.ara(aramaMetni);
    } catch (e) {
      _hataMesaji = 'Arama sırasında hata: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Evrak türüne göre filtreler.
  Future<void> turFiltrele(EvrakTuru tur) async {
    _isLoading = true;
    notifyListeners();

    try {
      _evraklar = await _service.getByTur(tur);
      _aramaAktif = false;
    } catch (e) {
      _hataMesaji = 'Filtreleme hatası: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Yeni evrak kaydı oluşturur.
  Future<bool> evrakOlustur(EvrakModel model) async {
    try {
      await _service.create(model);
      _basariMesaji = 'Evrak başarıyla eklendi.';
      await evraklariYukle();
      return true;
    } catch (e) {
      _hataMesaji = 'Evrak eklenemedi: $e';
      notifyListeners();
      return false;
    }
  }

  /// Evrak arşivler.
  Future<bool> arsivle(String id) async {
    try {
      await _service.arsivle(id);
      _basariMesaji = 'Evrak arşivlendi.';
      await evraklariYukle();
      return true;
    } catch (e) {
      _hataMesaji = 'Arşivlenemedi: $e';
      notifyListeners();
      return false;
    }
  }

  /// Siler.
  Future<bool> evrakSil(String id) async {
    try {
      await _service.delete(id);
      _basariMesaji = 'Evrak silindi.';
      await evraklariYukle();
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
