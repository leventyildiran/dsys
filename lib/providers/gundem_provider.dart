import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/gundem_model.dart';
import '../services/gundem_service.dart';

/// Toplantı gündem derleyici state yönetimi.
class GundemProvider extends ChangeNotifier {
  GundemProvider({GundemService? service})
      : _service = service ?? GundemService();

  final GundemService _service;

  List<ToplantiModel> _toplantilar = [];
  List<ToplantiModel> get toplantilar => _toplantilar;

  QueryDocumentSnapshot<Map<String, dynamic>>? _nextCursor;
  static const int _pageSize = 20;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  ToplantiModel? _seciliToplanti;
  ToplantiModel? get seciliToplanti => _seciliToplanti;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _hataMesaji;
  String? get hataMesaji => _hataMesaji;

  String? _basariMesaji;
  String? get basariMesaji => _basariMesaji;

  /// Toplantıları yükler.
  Future<void> toplantilariYukle({bool yenile = true}) async {
    _isLoading = true;
    _hataMesaji = null;
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
      _toplantilar = yenile ? page.items : [..._toplantilar, ...page.items];
    } catch (e) {
      _hataMesaji = 'Toplantılar yüklenirken hata: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> dahaFazlaYukle() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();
    try {
      await toplantilariYukle(yenile: false);
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Toplantı detayını yükler.
  Future<void> toplantiYukle(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      _seciliToplanti = await _service.getById(id);
    } catch (e) {
      _hataMesaji = 'Toplantı yüklenemedi: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Yeni toplantı oluşturur.
  Future<bool> toplantiOlustur(ToplantiModel model) async {
    try {
      await _service.create(model);
      _basariMesaji = 'Toplantı başarıyla oluşturuldu.';
      await toplantilariYukle();
      return true;
    } catch (e) {
      _hataMesaji = 'Toplantı oluşturulamadı: $e';
      notifyListeners();
      return false;
    }
  }

  /// Gündem maddesi ekler.
  Future<bool> gundemMaddesiEkle(
      String toplantiId, GundemMaddesi madde) async {
    if (_seciliToplanti == null) return false;

    try {
      final mevcutMaddeler =
          List<GundemMaddesi>.from(_seciliToplanti!.gundemMaddeleri);
      mevcutMaddeler.add(madde.copyWith(siraNo: mevcutMaddeler.length + 1));
      await _service.gundemGuncelle(toplantiId, mevcutMaddeler);
      await toplantiYukle(toplantiId);
      _basariMesaji = 'Gündem maddesi eklendi.';
      notifyListeners();
      return true;
    } catch (e) {
      _hataMesaji = 'Gündem maddesi eklenemedi: $e';
      notifyListeners();
      return false;
    }
  }

  /// Gündem maddesi sırasını değiştirir (sürükle-bırak).
  Future<void> siraDegistir(
      String toplantiId, int eskiIndex, int yeniIndex) async {
    if (_seciliToplanti == null) return;

    try {
      await _service.siraDegistir(
        toplantiId,
        _seciliToplanti!.gundemMaddeleri,
        eskiIndex,
        yeniIndex,
      );
      await toplantiYukle(toplantiId);
    } catch (e) {
      _hataMesaji = 'Sıra değiştirilemedi: $e';
      notifyListeners();
    }
  }

  /// Gündem belgesi üretir.
  String? gundemBelgesiUret() {
    if (_seciliToplanti == null) return null;
    return _service.gundemBelgesiUret(_seciliToplanti!);
  }

  /// Siler.
  Future<bool> toplantiSil(String id) async {
    try {
      await _service.delete(id);
      _basariMesaji = 'Toplantı silindi.';
      await toplantilariYukle();
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
