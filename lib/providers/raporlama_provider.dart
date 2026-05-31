import 'package:flutter/foundation.dart';

import '../services/raporlama_service.dart';

/// Raporlama state yönetimi.
class RaporlamaProvider extends ChangeNotifier {
  RaporlamaProvider({RaporlamaService? service})
      : _service = service ?? RaporlamaService();

  final RaporlamaService _service;

  List<BirimGelirRapor> _birimRaporu = [];
  List<BirimGelirRapor> get birimRaporu => _birimRaporu;

  List<PersonelGelirRapor> _personelRaporu = [];
  List<PersonelGelirRapor> get personelRaporu => _personelRaporu;

  GenelIstatistik? _genelIstatistik;
  GenelIstatistik? get genelIstatistik => _genelIstatistik;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _hataMesaji;
  String? get hataMesaji => _hataMesaji;

  /// Birim gelir raporunu yükler.
  Future<void> birimRaporuYukle({String? yil}) async {
    _isLoading = true;
    _hataMesaji = null;
    notifyListeners();

    try {
      _birimRaporu = await _service.birimGelirRaporu(yil: yil);
    } catch (e) {
      _hataMesaji = 'Birim raporu yüklenirken hata: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Personel gelir raporunu yükler.
  Future<void> personelRaporuYukle(String yil) async {
    _isLoading = true;
    _hataMesaji = null;
    notifyListeners();

    try {
      _personelRaporu = await _service.personelGelirRaporu(yil);
    } catch (e) {
      _hataMesaji = 'Personel raporu yüklenirken hata: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Genel istatistikleri yükler.
  Future<void> genelIstatistikleriYukle() async {
    _isLoading = true;
    notifyListeners();

    try {
      _genelIstatistik = await _service.genelIstatistikler();
    } catch (e) {
      _hataMesaji = 'İstatistikler yüklenemedi: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void mesajlariTemizle() {
    _hataMesaji = null;
    notifyListeners();
  }
}
