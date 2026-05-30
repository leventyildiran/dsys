import 'package:flutter/foundation.dart';

import '../core/hesaplama_motoru.dart';
import '../core/karar_metni_servisi.dart';
import '../core/turkce_format.dart';
import '../models/danismanlik_model.dart';
import '../models/personel_model.dart';

/// Personel görev atama modeli (form state için).
class PersonelGorevAtama {
  PersonelGorevAtama({
    required this.personel,
    this.payOrani = 100,
    this.faaliyetPuani = 0,
  });

  final PersonelModel personel;
  int payOrani; // %100, %60, %40
  double faaliyetPuani; // toplam faaliyet puanı
}

/// Canlı önizleme hesaplama sonucu.
class OnizlemeSonucu {
  const OnizlemeSonucu({
    required this.kesinti,
    required this.katsayi,
    required this.artikBakiye,
    required this.personelDagitimlari,
    required this.kararMetni,
    required this.sablonDogrulama,
  });

  final KesintiBilgisi kesinti;
  final double katsayi;
  final double artikBakiye;
  final List<PersonelDagitimSonucu> personelDagitimlari;
  final String kararMetni;
  final SablonDogrulamaSonucu sablonDogrulama;
}

/// Personel bazlı dağıtım sonucu.
class PersonelDagitimSonucu {
  const PersonelDagitimSonucu({
    required this.personelId,
    required this.adSoyad,
    required this.unvan,
    required this.unvanKatsayisi,
    required this.faaliyetPuani,
    required this.bireyselPuan,
    required this.brutHakedis,
    required this.tavanAsimi,
  });

  final String personelId;
  final String adSoyad;
  final String unvan;
  final double unvanKatsayisi;
  final double faaliyetPuani;
  final double bireyselPuan;
  final double brutHakedis;
  final bool tavanAsimi;
}

/// Danışmanlık formu state yönetimi.
///
/// Canlı önizleme hesaplamalarını tetikler ve karar metni üretir.
class DanismanlikProvider extends ChangeNotifier {
  // ─────────────────────────────────────────────────────────────
  // FORM STATE
  // ─────────────────────────────────────────────────────────────

  DanismanlikTuru _tur = DanismanlikTuru.standart;
  DanismanlikTuru get tur => _tur;

  double _brutTaksitTutari = 0;
  double get brutTaksitTutari => _brutTaksitTutari;

  int _kdvOrani = 20;
  int get kdvOrani => _kdvOrani;

  int _hazinePayiOrani = 1;
  int get hazinePayiOrani => _hazinePayiOrani;

  int _bapPayiOrani = 5;
  int get bapPayiOrani => _bapPayiOrani;

  int _aracGerecPayiOrani = 45;
  int get aracGerecPayiOrani => _aracGerecPayiOrani;

  int _suresi = 1;
  int get suresi => _suresi;

  String _firmaUnvan = '';
  String get firmaUnvan => _firmaUnvan;

  String _isinKonusu = '';
  String get isinKonusu => _isinKonusu;

  String _birimAd = '';
  String get birimAd => _birimAd;

  // Evrak bilgileri
  String _birimEvrakTarihi = '';
  String _birimEvrakSayisi = '';
  String _birimKurulTarihi = '';
  String _birimToplantiSayisi = '';
  String _birimKararNo = '';
  String _ykKararTarihi = '';
  String _ykKararNo = '';

  String get birimEvrakTarihi => _birimEvrakTarihi;
  String get birimEvrakSayisi => _birimEvrakSayisi;
  String get birimKurulTarihi => _birimKurulTarihi;
  String get birimToplantiSayisi => _birimToplantiSayisi;
  String get birimKararNo => _birimKararNo;
  String get ykKararTarihi => _ykKararTarihi;
  String get ykKararNo => _ykKararNo;

  // Personel listesi
  List<PersonelGorevAtama> _personeller = [];
  List<PersonelGorevAtama> get personeller => _personeller;

  // Önizleme sonucu
  OnizlemeSonucu? _onizleme;
  OnizlemeSonucu? get onizleme => _onizleme;

  // ─────────────────────────────────────────────────────────────
  // SETTER'LAR (her biri hesaplamayı tetikler)
  // ─────────────────────────────────────────────────────────────

  void setTur(DanismanlikTuru value) {
    _tur = value;
    _hesapla();
  }

  void setBrutTaksitTutari(double value) {
    _brutTaksitTutari = value;
    _hesapla();
  }

  void setKdvOrani(int value) {
    _kdvOrani = value;
    _hesapla();
  }

  void setHazinePayiOrani(int value) {
    _hazinePayiOrani = value;
    _hesapla();
  }

  void setBapPayiOrani(int value) {
    _bapPayiOrani = value;
    _hesapla();
  }

  void setAracGerecPayiOrani(int value) {
    _aracGerecPayiOrani = value;
    _hesapla();
  }

  void setSuresi(int value) {
    _suresi = value;
    _hesapla();
  }

  void setFirmaUnvan(String value) {
    _firmaUnvan = value;
    _hesapla();
  }

  void setIsinKonusu(String value) {
    _isinKonusu = value;
    _hesapla();
  }

  void setBirimAd(String value) {
    _birimAd = value;
    _hesapla();
  }

  void setBirimEvrakTarihi(String value) {
    _birimEvrakTarihi = value;
    _hesapla();
  }

  void setBirimEvrakSayisi(String value) {
    _birimEvrakSayisi = value;
    _hesapla();
  }

  void setBirimKurulTarihi(String value) {
    _birimKurulTarihi = value;
    _hesapla();
  }

  void setBirimToplantiSayisi(String value) {
    _birimToplantiSayisi = value;
    _hesapla();
  }

  void setBirimKararNo(String value) {
    _birimKararNo = value;
    _hesapla();
  }

  void setYkKararTarihi(String value) {
    _ykKararTarihi = value;
    _hesapla();
  }

  void setYkKararNo(String value) {
    _ykKararNo = value;
    _hesapla();
  }

  void personelEkle(PersonelModel personel) {
    _personeller.add(PersonelGorevAtama(personel: personel));
    _hesapla();
  }

  void personelCikar(int index) {
    _personeller.removeAt(index);
    _hesapla();
  }

  void personelPuanGuncelle(int index, double puan) {
    _personeller[index].faaliyetPuani = puan;
    _hesapla();
  }

  void personelPayGuncelle(int index, int pay) {
    _personeller[index].payOrani = pay;
    _hesapla();
  }

  /// Formu sıfırlar.
  void temizle() {
    _tur = DanismanlikTuru.standart;
    _brutTaksitTutari = 0;
    _kdvOrani = 20;
    _hazinePayiOrani = 1;
    _bapPayiOrani = 5;
    _aracGerecPayiOrani = 45;
    _suresi = 1;
    _firmaUnvan = '';
    _isinKonusu = '';
    _birimAd = '';
    _birimEvrakTarihi = '';
    _birimEvrakSayisi = '';
    _birimKurulTarihi = '';
    _birimToplantiSayisi = '';
    _birimKararNo = '';
    _ykKararTarihi = '';
    _ykKararNo = '';
    _personeller = [];
    _onizleme = null;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────
  // HESAPLAMA MOTORU (Canlı Önizleme)
  // ─────────────────────────────────────────────────────────────

  void _hesapla() {
    if (_brutTaksitTutari <= 0) {
      _onizleme = null;
      notifyListeners();
      return;
    }

    // 1. Kesinti hesapla
    final KesintiBilgisi kesinti;
    if (_tur == DanismanlikTuru.standart) {
      kesinti = HesaplamaMotoru.standartKesintiler(
        brutTutar: _brutTaksitTutari,
        kdvOrani: _kdvOrani,
        hazinePayiOrani: _hazinePayiOrani,
        bapPayiOrani: _bapPayiOrani,
        aracGerecPayiOrani: _aracGerecPayiOrani,
      );
    } else {
      kesinti = HesaplamaMotoru.sanayiIsbirligiKesintiler(
        brutTutar: _brutTaksitTutari,
        kdvOrani: _kdvOrani,
      );
    }

    // 2. Personel puan hesapla
    final personelPuanlar = _personeller
        .where((p) => p.faaliyetPuani > 0)
        .map((p) => PersonelPuanModel(
              personelId: p.personel.id,
              faaliyetPuani: p.faaliyetPuani,
              unvanKatsayisi: p.personel.unvanKatsayisi,
            ))
        .toList();

    double toplamPuan = 0;
    for (final p in personelPuanlar) {
      toplamPuan += p.bireyselPuan;
    }

    // 3. Katsayı simülasyonu
    double katsayi = 0;
    double artikBakiye = 0;
    if (toplamPuan > 0 && kesinti.dagitilabilirTutar > 0) {
      katsayi = HesaplamaMotoru.katsayiSimulasyonu(
        kesinti.dagitilabilirTutar,
        toplamPuan,
        personelPuanlar,
      );
      artikBakiye = HesaplamaMotoru.artikBakiyeHesapla(
        kesinti.dagitilabilirTutar,
        katsayi,
        personelPuanlar,
      );
    }

    // 4. Personel dağıtım tablosu
    final dagitimlar = _personeller.map((p) {
      final bireyselPuan = p.faaliyetPuani * p.personel.unvanKatsayisi;
      final brutHakedis = toplamPuan > 0
          ? double.parse((bireyselPuan * katsayi).toStringAsFixed(2))
          : 0.0;

      return PersonelDagitimSonucu(
        personelId: p.personel.id,
        adSoyad: p.personel.adSoyad,
        unvan: p.personel.unvan,
        unvanKatsayisi: p.personel.unvanKatsayisi,
        faaliyetPuani: p.faaliyetPuani,
        bireyselPuan: bireyselPuan,
        brutHakedis: brutHakedis,
        tavanAsimi: false, // Tavan kontrolü Firebase bağlantısında aktifleşecek
      );
    }).toList();

    // 5. Karar metni
    final isStandart = _tur == DanismanlikTuru.standart;
    final veriler = _kararMetniVerileriHazirla(katsayi);
    final dogrulama = KararMetniServisi.dogrula(
      isStandart: isStandart,
      veriler: veriler,
    );
    final kararMetni = KararMetniServisi.metinUret(
      isStandart: isStandart,
      veriler: veriler,
    );

    _onizleme = OnizlemeSonucu(
      kesinti: kesinti,
      katsayi: katsayi,
      artikBakiye: artikBakiye,
      personelDagitimlari: dagitimlar,
      kararMetni: kararMetni,
      sablonDogrulama: dogrulama,
    );
    notifyListeners();
  }

  Map<String, String?> _kararMetniVerileriHazirla(double katsayi) {
    final isStandart = _tur == DanismanlikTuru.standart;

    // İlk personelin bilgilerini al (birden fazla personel varsa ilkini kullanır)
    final hocaUnvan =
        _personeller.isNotEmpty ? _personeller.first.personel.unvan : '';
    final hocaAdSoyad =
        _personeller.isNotEmpty ? _personeller.first.personel.adSoyad : '';

    if (isStandart) {
      return {
        'BIRIM_AD': _birimAd.isNotEmpty ? _birimAd : null,
        'BIRIM_EVRAK_TARIHI':
            _birimEvrakTarihi.isNotEmpty ? _birimEvrakTarihi : null,
        'BIRIM_EVRAK_SAYISI':
            _birimEvrakSayisi.isNotEmpty ? _birimEvrakSayisi : null,
        'BIRIM_KURUL_TARIHI':
            _birimKurulTarihi.isNotEmpty ? _birimKurulTarihi : null,
        'BIRIM_TOPLANTI_SAYI':
            _birimToplantiSayisi.isNotEmpty ? _birimToplantiSayisi : null,
        'BIRIM_KARAR_NO': _birimKararNo.isNotEmpty ? _birimKararNo : null,
        'YK_KARAR_TARIHI':
            _ykKararTarihi.isNotEmpty ? _ykKararTarihi : null,
        'YK_KARAR_NO': _ykKararNo.isNotEmpty ? _ykKararNo : null,
        'FIRMA_UNVAN': _firmaUnvan.isNotEmpty ? _firmaUnvan : null,
        'ISIN_KONUSU': _isinKonusu.isNotEmpty ? _isinKonusu : null,
        'DANISMANLIK_SURESI': _suresi > 0 ? _suresi.toString() : null,
        'HOCA_UNVAN': hocaUnvan.isNotEmpty ? hocaUnvan : null,
        'HOCA_AD_SOYAD': hocaAdSoyad.isNotEmpty ? hocaAdSoyad : null,
        'KATSAYI': katsayi > 0 ? TurkceFormat.katsayi(katsayi) : null,
      };
    } else {
      return {
        'UYK_KARAR_TARIHI':
            _ykKararTarihi.isNotEmpty ? _ykKararTarihi : null,
        'UYK_TOPLANTI_SAYI':
            _birimToplantiSayisi.isNotEmpty ? _birimToplantiSayisi : null,
        'UYK_KARAR_NO': _ykKararNo.isNotEmpty ? _ykKararNo : null,
        'FIRMA_UNVAN': _firmaUnvan.isNotEmpty ? _firmaUnvan : null,
        'HOCA_UNVAN': hocaUnvan.isNotEmpty ? hocaUnvan : null,
        'HOCA_AD_SOYAD': hocaAdSoyad.isNotEmpty ? hocaAdSoyad : null,
        'HIZMET_BASLANGIC_TARIHI': null, // Form'dan girilecek
        'HIZMET_BITIS_TARIHI': null,
        'DANISMANLIK_SURESI': _suresi > 0 ? _suresi.toString() : null,
        'GELIR_TUTARI': _brutTaksitTutari > 0
            ? TurkceFormat.para(_brutTaksitTutari).replaceAll(' TL', '')
            : null,
        'KATKI_PAYI_TUTARI': null, // Hesaplama sonrası doldurulacak
      };
    }
  }
}
