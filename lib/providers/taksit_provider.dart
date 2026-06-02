import 'package:flutter/foundation.dart';

import '../models/dagitim_model.dart';
import '../models/danismanlik_model.dart';
import '../models/gorevli_personel_model.dart';
import '../models/taksit_model.dart';
import '../services/belge_uretim_servisi.dart';
import '../services/data_service.dart';
import '../services/gorevli_personel_service.dart';
import '../services/taksit_onay_servisi.dart';
import '../services/taksit_service.dart';

/// Taksit onay akışı UI state yönetimi.
///
/// Taksitlerin durumlarını takip eder, onay sürecini yönetir,
/// belge üretimini tetikler ve sonuçları UI'a sunar.
class TaksitProvider extends ChangeNotifier {
  TaksitProvider({
    TaksitService? taksitService,
    TaksitOnayServisi? taksitOnayServisi,
    GorevliPersonelService? gorevliPersonelService,
    DanismanlikService? danismanlikService,
  })  : _taksitService = taksitService ?? TaksitService(),
        _onayServisi = taksitOnayServisi ?? TaksitOnayServisi(),
        _gorevliPersonelService =
            gorevliPersonelService ?? GorevliPersonelService(),
        _danismanlikService = danismanlikService ?? DanismanlikService();

  final TaksitService _taksitService;
  final TaksitOnayServisi _onayServisi;
  final GorevliPersonelService _gorevliPersonelService;
  final DanismanlikService _danismanlikService;

  // ─────────────────────────────────────────────────────────────
  // STATE
  // ─────────────────────────────────────────────────────────────

  List<TaksitModel> _taksitler = [];
  List<TaksitModel> get taksitler => _taksitler;

  List<GorevliPersonelModel> _gorevliler = [];
  List<GorevliPersonelModel> get gorevliler => _gorevliler;

  DanismanlikModel? _danismanlik;
  DanismanlikModel? get danismanlik => _danismanlik;

  String? _aktivDanismanlikId;
  String? get aktivDanismanlikId => _aktivDanismanlikId;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  String? _hataMesaji;
  String? get hataMesaji => _hataMesaji;

  String? _basariMesaji;
  String? get basariMesaji => _basariMesaji;

  DagitimSonuc? _sonDagitimSonucu;
  DagitimSonuc? get sonDagitimSonucu => _sonDagitimSonucu;

  KararBelgesi? _sonBelge;
  KararBelgesi? get sonBelge => _sonBelge;

  // ─────────────────────────────────────────────────────────────
  // VERİ YÜKLEME
  // ─────────────────────────────────────────────────────────────

  /// Danışmanlığa ait taksitleri yükler.
  Future<void> taksitleriYukle(String danismanlikId) async {
    _aktivDanismanlikId = danismanlikId;
    _isLoading = true;
    _hataMesaji = null;
    notifyListeners();

    try {
      _danismanlik = await _danismanlikService.getById(danismanlikId);
      _taksitler = await _taksitService.getAll(danismanlikId);
      _gorevliler = await _gorevliPersonelService.getAll(danismanlikId);
    } catch (e) {
      _hataMesaji = 'Taksitler yüklenirken hata oluştu: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Taksitleri gerçek zamanlı dinle.
  void taksitleriDinle(String danismanlikId) {
    _aktivDanismanlikId = danismanlikId;
    _taksitService.stream(danismanlikId).listen((taksitler) {
      _taksitler = taksitler;
      notifyListeners();
    });
  }

  // ─────────────────────────────────────────────────────────────
  // DURUM GEÇİŞLERİ
  // ─────────────────────────────────────────────────────────────

  /// Taksiti bir sonraki onay aşamasına geçirir.
  Future<bool> durumIlerlet(TaksitModel taksit) async {
    final hedef = _sonrakiDurum(taksit.durum);
    if (hedef == null) {
      _hataMesaji = 'Bu taksit için ilerletilebilecek bir durum bulunmuyor.';
      notifyListeners();
      return false;
    }

    return await _durumDegistir(taksit, hedef);
  }

  /// Taksiti bir önceki onay aşamasına geri alır.
  Future<bool> durumGeriAl(TaksitModel taksit) async {
    final hedef = _oncekiDurum(taksit.durum);
    if (hedef == null) {
      _hataMesaji = 'Bu taksit geri alınamaz.';
      notifyListeners();
      return false;
    }

    return await _durumDegistir(taksit, hedef);
  }

  /// Belirli bir duruma geçiş yapar.
  Future<bool> durumDegistir(TaksitModel taksit, TaksitDurum yeniDurum) async {
    return await _durumDegistir(taksit, yeniDurum);
  }

  Future<bool> _durumDegistir(TaksitModel taksit, TaksitDurum yeniDurum) async {
    if (_aktivDanismanlikId == null) return false;

    _isProcessing = true;
    _hataMesaji = null;
    _basariMesaji = null;
    notifyListeners();

    try {
      final sonuc = await _onayServisi.durumGecisi(
        danismanlikId: _aktivDanismanlikId!,
        taksitId: taksit.id,
        yeniDurum: yeniDurum,
        mevcutDurum: taksit.durum,
      );

      if (sonuc != null) {
        _sonDagitimSonucu = sonuc;
        _basariMesaji =
            'Taksit onaylandı. ${sonuc.dagitimlar.length} personele dağıtım hesaplandı.';
      } else {
        _basariMesaji =
            'Taksit durumu "${yeniDurum.displayName}" olarak güncellendi.';
      }

      // Listeyi yenile
      await taksitleriYukle(_aktivDanismanlikId!);
      return true;
    } on TaksitOnayHatasi catch (e) {
      _hataMesaji = e.mesaj;
      return false;
    } catch (e) {
      _hataMesaji = 'İşlem sırasında hata oluştu: $e';
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // BELGE ÜRETİMİ
  // ─────────────────────────────────────────────────────────────

  /// Onaylanmış taksit için karar belgesi üretir.
  Future<KararBelgesi?> kararBelgesiUret(
    TaksitModel taksit,
    List<DagitimModel> dagitimlar, {
    String? birimAd,
  }) async {
    if (_danismanlik == null || _aktivDanismanlikId == null) {
      _hataMesaji = 'Danışmanlık bilgileri yüklenmemiş.';
      notifyListeners();
      return null;
    }

    try {
      final belge = BelgeUretimServisi.kararBelgesiOlustur(
        danismanlik: _danismanlik!,
        taksit: taksit,
        gorevliler: _gorevliler,
        dagitimlar: dagitimlar,
        katsayi: taksit.ekOdemeKatsayisi ?? 0,
        birimAd: birimAd,
      );

      _sonBelge = belge;
      notifyListeners();
      return belge;
    } catch (e) {
      _hataMesaji = 'Belge üretimi sırasında hata oluştu: $e';
      notifyListeners();
      return null;
    }
  }

  /// DOCX dosyası olarak indir.
  Future<List<int>?> docxIndir(KararBelgesi belge) async {
    try {
      return await BelgeUretimServisi.docxOlustur(belge);
    } catch (e) {
      _hataMesaji = 'DOCX oluşturma sırasında hata: $e';
      notifyListeners();
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // YARDIMCI
  // ─────────────────────────────────────────────────────────────

  /// Mevcut durumun bir sonraki aşamasını döner.
  TaksitDurum? _sonrakiDurum(TaksitDurum mevcut) {
    switch (mevcut) {
      case TaksitDurum.taslak:
        return TaksitDurum.mudurOnayinda;
      case TaksitDurum.mudurOnayinda:
        return TaksitDurum.merkezOnayinda;
      case TaksitDurum.merkezOnayinda:
        return TaksitDurum.ykGundeminde;
      case TaksitDurum.ykGundeminde:
        return TaksitDurum.onaylandi;
      case TaksitDurum.onaylandi:
        return TaksitDurum.odendi;
      case TaksitDurum.gecikti:
        return TaksitDurum.odendi;
      case TaksitDurum.odendi:
        return null;
    }
  }

  /// Mevcut durumun bir önceki aşamasını döner (geri alma için).
  TaksitDurum? _oncekiDurum(TaksitDurum mevcut) {
    switch (mevcut) {
      case TaksitDurum.mudurOnayinda:
        return TaksitDurum.taslak;
      case TaksitDurum.merkezOnayinda:
        return TaksitDurum.mudurOnayinda;
      case TaksitDurum.ykGundeminde:
        return TaksitDurum.merkezOnayinda;
      default:
        return null;
    }
  }

  /// Taksit durumuna göre izin verilen aksiyonları döner.
  List<TaksitAksiyon> izinVerilenAksiyonlar(TaksitModel taksit) {
    final aksiyonlar = <TaksitAksiyon>[];

    final sonraki = _sonrakiDurum(taksit.durum);
    if (sonraki != null) {
      aksiyonlar.add(TaksitAksiyon(
        etiket: _aksiyonEtiketi(taksit.durum),
        hedefDurum: sonraki,
        tipi: TaksitAksiyonTipi.ilerlet,
      ));
    }

    final onceki = _oncekiDurum(taksit.durum);
    if (onceki != null) {
      aksiyonlar.add(TaksitAksiyon(
        etiket: 'Geri Al',
        hedefDurum: onceki,
        tipi: TaksitAksiyonTipi.geriAl,
      ));
    }

    // Onaylanmış taksitler için belge üret aksiyonu
    if (taksit.durum == TaksitDurum.onaylandi ||
        taksit.durum == TaksitDurum.odendi) {
      aksiyonlar.add(TaksitAksiyon(
        etiket: 'Karar Belgesi Üret',
        hedefDurum: taksit.durum,
        tipi: TaksitAksiyonTipi.belgeUret,
      ));
    }

    return aksiyonlar;
  }

  String _aksiyonEtiketi(TaksitDurum mevcut) {
    switch (mevcut) {
      case TaksitDurum.taslak:
        return 'Müdür Onayına Sun';
      case TaksitDurum.mudurOnayinda:
        return 'Merkeze Gönder';
      case TaksitDurum.merkezOnayinda:
        return 'YK Gündemine Al';
      case TaksitDurum.ykGundeminde:
        return 'Onayla';
      case TaksitDurum.onaylandi:
        return 'Ödendi İşaretle';
      case TaksitDurum.gecikti:
        return 'Ödendi İşaretle';
      case TaksitDurum.odendi:
        return '';
    }
  }

  /// Durum bazlı taksitleri filtreler.
  List<TaksitModel> taksitFiltrele(TaksitDurum? durum) {
    if (durum == null) return _taksitler;
    return _taksitler.where((t) => t.durum == durum).toList();
  }

  /// İstatistik verileri.
  TaksitIstatistik get istatistik {
    int taslak = 0, onayBekleyen = 0, onaylanan = 0, odenen = 0;
    double toplamTutar = 0;

    for (final t in _taksitler) {
      toplamTutar += t.brutTutar;
      switch (t.durum) {
        case TaksitDurum.taslak:
          taslak++;
          break;
        case TaksitDurum.mudurOnayinda:
        case TaksitDurum.merkezOnayinda:
        case TaksitDurum.ykGundeminde:
          onayBekleyen++;
          break;
        case TaksitDurum.onaylandi:
          onaylanan++;
          break;
        case TaksitDurum.odendi:
          odenen++;
          break;
        case TaksitDurum.gecikti:
          onayBekleyen++;
          break;
      }
    }

    return TaksitIstatistik(
      toplam: _taksitler.length,
      taslak: taslak,
      onayBekleyen: onayBekleyen,
      onaylanan: onaylanan,
      odenen: odenen,
      toplamTutar: toplamTutar,
    );
  }

  /// Hata mesajını temizler.
  void hatayiTemizle() {
    _hataMesaji = null;
    _basariMesaji = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────
// YARDIMCI MODELLERİ
// ─────────────────────────────────────────────────────────────

/// Taksit aksiyon tipi.
enum TaksitAksiyonTipi { ilerlet, geriAl, belgeUret }

/// Taksit için kullanılabilir aksiyon.
class TaksitAksiyon {
  const TaksitAksiyon({
    required this.etiket,
    required this.hedefDurum,
    required this.tipi,
  });

  final String etiket;
  final TaksitDurum hedefDurum;
  final TaksitAksiyonTipi tipi;
}

/// Taksit istatistik özeti.
class TaksitIstatistik {
  const TaksitIstatistik({
    required this.toplam,
    required this.taslak,
    required this.onayBekleyen,
    required this.onaylanan,
    required this.odenen,
    required this.toplamTutar,
  });

  final int toplam;
  final int taslak;
  final int onayBekleyen;
  final int onaylanan;
  final int odenen;
  final double toplamTutar;

  double get tamamlanmaOrani =>
      toplam == 0 ? 0 : (onaylanan + odenen) / toplam;
}
