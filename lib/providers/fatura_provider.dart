import 'package:flutter/foundation.dart';

import '../models/fatura_model.dart';
import '../services/fatura_service.dart';

/// Fatura basım ve PDF önizleme state yönetimi.
class FaturaProvider extends ChangeNotifier {
  FaturaProvider({FaturaService? service})
      : _service = service ?? FaturaService();

  final FaturaService _service;

  List<FaturaModel> _faturalar = [];
  List<FaturaModel> get faturalar => _faturalar;

  List<FaturaModel> _kuyruk = [];
  List<FaturaModel> get kuyruk => _kuyruk;

  FaturaModel? _seciliFatura;
  FaturaModel? get seciliFatura => _seciliFatura;

  List<FaturaParseSonuc> _parseSonuclari = [];
  List<FaturaParseSonuc> get parseSonuclari => _parseSonuclari;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _hataMesaji;
  String? get hataMesaji => _hataMesaji;

  String? _basariMesaji;
  String? get basariMesaji => _basariMesaji;

  /// Tüm faturaları yükler.
  Future<void> faturalariYukle() async {
    _isLoading = true;
    _hataMesaji = null;
    notifyListeners();

    try {
      _faturalar = await _service.getAll();
      _kuyruk = _faturalar
          .where((f) => f.durum == FaturaDurum.bekleyen)
          .toList();
    } catch (e) {
      _hataMesaji = 'Faturalar yüklenirken hata: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fatura seçer (önizleme için).
  void faturaSecme(FaturaModel fatura) {
    _seciliFatura = fatura;
    notifyListeners();
  }

  /// Metin ayrıştırır (toplu fatura talebi).
  void metinAyristir(String metin) {
    _parseSonuclari = _service.metinAyristir(metin);
    notifyListeners();
  }

  /// Parse sonuçlarından toplu fatura oluşturur.
  Future<bool> topluFaturaOlustur({
    required String birimId,
    required String birimAd,
  }) async {
    if (_parseSonuclari.isEmpty) {
      _hataMesaji = 'Ayrıştırılmış fatura verisi bulunamadı.';
      notifyListeners();
      return false;
    }

    try {
      final faturalar = _parseSonuclari.map((sonuc) {
        final kdvTutar = sonuc.tutar * 0.20;
        return FaturaModel(
          id: '',
          birimId: birimId,
          birimAd: birimAd,
          firmaUnvan: sonuc.firmaUnvan,
          hizmetDetay: sonuc.hizmetDetay,
          tutar: sonuc.tutar,
          kdvOrani: 20,
          kdvTutar: kdvTutar,
          toplamTutar: sonuc.tutar + kdvTutar,
        );
      }).toList();

      await _service.topluOlustur(faturalar);
      _basariMesaji = '${faturalar.length} fatura kuyruğa eklendi.';
      _parseSonuclari = [];
      await faturalariYukle();
      return true;
    } catch (e) {
      _hataMesaji = 'Toplu fatura oluşturulamadı: $e';
      notifyListeners();
      return false;
    }
  }

  /// Yeni fatura oluşturur.
  Future<bool> faturaOlustur(FaturaModel model) async {
    try {
      await _service.create(model);
      _basariMesaji = 'Fatura oluşturuldu.';
      await faturalariYukle();
      return true;
    } catch (e) {
      _hataMesaji = 'Fatura oluşturulamadı: $e';
      notifyListeners();
      return false;
    }
  }

  /// Faturayı basıldı olarak işaretler.
  Future<bool> basildiIsaretle(String id) async {
    try {
      await _service.basildiIsaretle(id);
      _basariMesaji = 'Fatura basıldı olarak işaretlendi.';
      await faturalariYukle();
      return true;
    } catch (e) {
      _hataMesaji = 'İşaretlenemedi: $e';
      notifyListeners();
      return false;
    }
  }

  /// Fatura günceller.
  Future<bool> faturaGuncelle(String id, Map<String, dynamic> data) async {
    try {
      await _service.update(id, data);
      await faturalariYukle();
      return true;
    } catch (e) {
      _hataMesaji = 'Güncelleme hatası: $e';
      notifyListeners();
      return false;
    }
  }

  /// Siler.
  Future<bool> faturaSil(String id) async {
    try {
      await _service.delete(id);
      _basariMesaji = 'Fatura silindi.';
      await faturalariYukle();
      return true;
    } catch (e) {
      _hataMesaji = 'Silinemedi: $e';
      notifyListeners();
      return false;
    }
  }

  /// Kuyrukta bekleyen fatura sayısı.
  int get kuyrukSayisi => _kuyruk.length;

  void mesajlariTemizle() {
    _hataMesaji = null;
    _basariMesaji = null;
    notifyListeners();
  }
}
