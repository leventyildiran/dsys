import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/yk_karar_model.dart';
import '../services/yk_karar_service.dart';

/// YK Karar Merkezi state yönetimi.
class YkKararProvider extends ChangeNotifier {
  YkKararProvider({YkKararService? service})
      : _service = service ?? YkKararService();

  final YkKararService _service;

  List<YkKararModel> _kararlar = [];
  List<YkKararModel> get kararlar => _kararlar;

  QueryDocumentSnapshot<Map<String, dynamic>>? _nextCursor;
  static const int _pageSize = 20;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _hataMesaji;
  String? get hataMesaji => _hataMesaji;

  String? _basariMesaji;
  String? get basariMesaji => _basariMesaji;

  String? _seciliToplantiId;
  String? get seciliToplantiId => _seciliToplantiId;

  /// Toplantı ID'ye göre kararları filtreler.
  void toplantiSec(String? toplantiId) {
    _seciliToplantiId = toplantiId;
    kararlariYukle();
  }

  /// Kararları yükler.
  Future<void> kararlariYukle({bool yenile = true}) async {
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
        toplantiId: _seciliToplantiId,
      );
      _nextCursor = page.nextCursor;
      _hasMore = page.hasMore;
      _kararlar = yenile ? page.items : [..._kararlar, ...page.items];
    } catch (e) {
      _hataMesaji = 'Kararlar yüklenirken hata: $e';
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
      await kararlariYukle(yenile: false);
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Yeni karar oluşturur.
  Future<bool> kararOlustur(YkKararModel model) async {
    try {
      // Bir sonraki karar numarasını otomatik üretelim
      final yeniKararNo = await _service.sonrakiKararNoUret(model.toplantiNo);
      final guncelModel = model.copyWith(kararNo: yeniKararNo);
      
      await _service.create(guncelModel);
      _basariMesaji = 'Karar başarıyla oluşturuldu.';
      await kararlariYukle();
      return true;
    } catch (e) {
      _hataMesaji = 'Karar oluşturulamadı: $e';
      notifyListeners();
      return false;
    }
  }

  /// Karar metnini veya başlığını günceller.
  Future<bool> kararGuncelle(
    String id,
    String baslik,
    String kararMetni, {
    String? birimId,
    String? birimAd,
    String? kararNo,
    String? kararTarihi,
    YkKararTuru? tur,
    YkKararDurum? durum,
  }) async {
    try {
      final updates = <String, dynamic>{
        'baslik': baslik,
        'kararMetni': kararMetni,
      };
      if (birimId != null) updates['birimId'] = birimId;
      if (birimAd != null) updates['birimAd'] = birimAd;
      if (kararNo != null) updates['kararNo'] = kararNo;
      if (kararTarihi != null) updates['kararTarihi'] = kararTarihi;
      if (tur != null) updates['tur'] = tur.value;
      if (durum != null) updates['durum'] = durum.value;

      await _service.update(id, updates);
      _basariMesaji = 'Karar başarıyla güncellendi.';
      await kararlariYukle();
      return true;
    } catch (e) {
      _hataMesaji = 'Karar güncellenemedi: $e';
      notifyListeners();
      return false;
    }
  }

  /// Karar durumunu değiştirir.
  Future<bool> durumDegistir(String id, YkKararDurum yeniDurum) async {
    try {
      await _service.update(id, {'durum': yeniDurum.value});
      _basariMesaji = 'Durum güncellendi.';
      await kararlariYukle();
      return true;
    } catch (e) {
      _hataMesaji = 'Durum güncellenemedi: $e';
      notifyListeners();
      return false;
    }
  }

  /// Karar siler.
  Future<bool> kararSil(String id) async {
    try {
      await _service.delete(id);
      _basariMesaji = 'Karar silindi.';
      await kararlariYukle();
      return true;
    } catch (e) {
      _hataMesaji = 'Karar silinemedi: $e';
      notifyListeners();
      return false;
    }
  }

  /// Toplantıya ait Karar Defteri metnini üretir.
  Future<String?> kararDefteriMetniUret(String toplantiId, String toplantiNo, String toplantiTarihi) async {
    try {
      final list = await _service.getByToplanti(toplantiId);
      if (list.isEmpty) return null;
      return _service.kararDefteriUret(toplantiNo, toplantiTarihi, list);
    } catch (e) {
      _hataMesaji = 'Karar defteri üretilirken hata: $e';
      notifyListeners();
      return null;
    }
  }

  void mesajlariTemizle() {
    _hataMesaji = null;
    _basariMesaji = null;
    notifyListeners();
  }
}
