import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/evrak_arsiv_model.dart';
import '../models/evrak_ocr_sonucu.dart';
import '../services/evrak_arsiv_service.dart';

/// Evrak arşiv state yönetimi.
class EvrakArsivProvider extends ChangeNotifier {
  EvrakArsivProvider({EvrakArsivService? service})
      : _service = service ?? EvrakArsivService();

  final EvrakArsivService _service;

  List<EvrakModel> _evraklar = [];
  List<EvrakModel> get evraklar => _evraklar;

  QueryDocumentSnapshot<Map<String, dynamic>>? _nextCursor;
  static const int _pageSize = 20;

  List<EvrakModel> _aramaSonuclari = [];
  List<EvrakModel> get aramaSonuclari => _aramaSonuclari;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  bool _ocrLoading = false;
  bool get ocrLoading => _ocrLoading;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  bool _aramaAktif = false;
  bool get aramaAktif => _aramaAktif;

  String? _hataMesaji;
  String? get hataMesaji => _hataMesaji;

  String? _basariMesaji;
  String? get basariMesaji => _basariMesaji;

  EvrakOcrSonucu? _sonOcrSonucu;
  EvrakOcrSonucu? get sonOcrSonucu => _sonOcrSonucu;

  /// Tüm evrakları yükler.
  Future<void> evraklariYukle({bool yenile = true}) async {
    _isLoading = true;
    _hataMesaji = null;
    _aramaAktif = false;
    if (yenile) {
      _nextCursor = null;
      _hasMore = true;
    }
    notifyListeners();

    try {
      final page = await _service.getPage(
        limit: _pageSize,
        startAfterDocument: _nextCursor,
      );
      _nextCursor = page.nextCursor;
      _hasMore = page.hasMore;
      _evraklar = yenile ? page.items : [..._evraklar, ...page.items];
    } catch (e) {
      _hataMesaji = 'Evraklar yüklenirken hata: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> dahaFazlaYukle() async {
    if (_isLoading || _isLoadingMore || !_hasMore || _aramaAktif) return;
    _isLoadingMore = true;
    notifyListeners();
    try {
      await evraklariYukle(yenile: false);
    } finally {
      _isLoadingMore = false;
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

  Future<EvrakOcrSonucu?> dosyadanOcrOku({
    required Uint8List dosyaBytes,
    required String dosyaAdi,
  }) async {
    _ocrLoading = true;
    _hataMesaji = null;
    notifyListeners();

    try {
      _sonOcrSonucu = await _service.geminiOcrOku(dosyaBytes, dosyaAdi);
      if (_sonOcrSonucu == null) {
        _hataMesaji =
            'OCR sonucu alınamadı. Gemini anahtarını ve dosya içeriğini kontrol edin.';
      }
      return _sonOcrSonucu;
    } catch (e) {
      _hataMesaji = 'OCR işlemi başarısız oldu: $e';
      return null;
    } finally {
      _ocrLoading = false;
      notifyListeners();
    }
  }

  void ocrSonucunuTemizle() {
    _sonOcrSonucu = null;
    notifyListeners();
  }

  void mesajlariTemizle() {
    _hataMesaji = null;
    _basariMesaji = null;
    notifyListeners();
  }
}
