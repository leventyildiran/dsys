import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/butce_aktarim_model.dart';
import '../models/yk_karar_model.dart';
import '../services/butce_aktarim_service.dart';
import '../services/yk_karar_service.dart';

/// Bütçe aktarımları state yönetimi.
class ButceAktarimProvider extends ChangeNotifier {
  ButceAktarimProvider({ButceAktarimService? service, YkKararService? ykKararService})
      : _service = service ?? ButceAktarimService(),
        _ykKararService = ykKararService ?? YkKararService();

  final ButceAktarimService _service;
  final YkKararService _ykKararService;
  List<ButceAktarimModel> _aktarimlar = [];
  List<ButceAktarimModel> get aktarimlar => _aktarimlar;

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

  /// Tüm aktarımları yükler.
  Future<void> aktarimlariYukle({bool yenile = true}) async {
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
      _aktarimlar = yenile ? page.items : [..._aktarimlar, ...page.items];
    } catch (e) {
      _hataMesaji = 'Aktarımlar yüklenirken hata: $e';
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
      await aktarimlariYukle(yenile: false);
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Yeni aktarım oluşturur.
  Future<bool> aktarimOlustur(ButceAktarimModel model) async {
    try {
      final newId = await _service.create(model);
      
      // Otomatik YK Taslak Kararı Oluştur
      try {
        final ykKarar = YkKararModel(
          id: '',
          toplantiId: '',
          toplantiNo: '',
          kararNo: '',
          kararTarihi: '',
          birimId: model.birimId,
          birimAd: model.birimAd,
          tur: YkKararTuru.butceAktarim,
          baslik: '${model.birimAd} Bütçe Aktarım Kararı (Karar No: ${model.kararNo})',
          kararMetni: 'Üniversitemiz ${model.birimAd} Müdürlüğü’nün bütçe kalemleri arasında aktarım yapılması talebine ilişkin kurul kararı doğrultusunda; ${model.birimAd} bütçesinden artırılan ve eksiltilen bütçe kalemleri tablosuna istinaden bütçe aktarımının gerçekleştirilmesine ve kararının Yürütme Kurulu\'nca onaylanmasına karar verilmiştir.\n\nGerekçe: ${model.gerekce ?? ""}',
          iliskiliKayitId: newId,
          olusturmaTarihi: DateTime.now(),
          durum: YkKararDurum.taslak,
        );
        
        await _ykKararService.create(ykKarar);
      } catch (e) {
        debugPrint('[ButceAktarimProvider.aktarimOlustur] YK Kararı oluşturulurken hata: $e');
      }

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
