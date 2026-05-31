/// Evrak arşiv modeli.
///
/// Dahili evrak arşivi ve EBYS özelliklerini destekler.
/// Firestore yolu: `evraklar/{evrakId}`
class EvrakModel {
  const EvrakModel({
    required this.id,
    required this.baslik,
    required this.evrakTuru,
    this.birimId,
    this.birimAd,
    this.evrakTarihi,
    this.evrakSayisi,
    this.dosyaUrl,
    this.dosyaAdi,
    this.icerikOzeti,
    this.etiketler = const [],
    this.olusturanKullanici,
    this.olusturmaTarihi,
    this.durum = EvrakDurum.aktif,
  });

  final String id;
  final String baslik;
  final EvrakTuru evrakTuru;
  final String? birimId;
  final String? birimAd;
  final String? evrakTarihi;
  final String? evrakSayisi;
  final String? dosyaUrl;
  final String? dosyaAdi;
  final String? icerikOzeti;
  final List<String> etiketler;
  final String? olusturanKullanici;
  final DateTime? olusturmaTarihi;
  final EvrakDurum durum;

  factory EvrakModel.fromMap(String id, Map<String, dynamic> map) {
    return EvrakModel(
      id: id,
      baslik: map['baslik'] ?? '',
      evrakTuru: EvrakTuru.fromString(map['evrakTuru'] ?? 'diger'),
      birimId: map['birimId'],
      birimAd: map['birimAd'],
      evrakTarihi: map['evrakTarihi'],
      evrakSayisi: map['evrakSayisi'],
      dosyaUrl: map['dosyaUrl'],
      dosyaAdi: map['dosyaAdi'],
      icerikOzeti: map['icerikOzeti'],
      etiketler: List<String>.from(map['etiketler'] ?? []),
      olusturanKullanici: map['olusturanKullanici'],
      olusturmaTarihi: map['olusturmaTarihi'] != null
          ? DateTime.tryParse(map['olusturmaTarihi'])
          : null,
      durum: EvrakDurum.fromString(map['durum'] ?? 'aktif'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'baslik': baslik,
      'evrakTuru': evrakTuru.value,
      'birimId': birimId,
      'birimAd': birimAd,
      'evrakTarihi': evrakTarihi,
      'evrakSayisi': evrakSayisi,
      'dosyaUrl': dosyaUrl,
      'dosyaAdi': dosyaAdi,
      'icerikOzeti': icerikOzeti,
      'etiketler': etiketler,
      'olusturanKullanici': olusturanKullanici,
      'olusturmaTarihi': olusturmaTarihi?.toIso8601String(),
      'durum': durum.value,
    };
  }
}

/// Evrak türleri.
enum EvrakTuru {
  ustYazi('ust_yazi', 'Üst Yazı'),
  kararMetni('karar_metni', 'Karar Metni'),
  faaliyetCetveli('faaliyet_cetveli', 'Faaliyet Cetveli'),
  sozlesme('sozlesme', 'Sözleşme'),
  fatura('fatura', 'Fatura'),
  dilekce('dilekce', 'Dilekçe'),
  diger('diger', 'Diğer');

  const EvrakTuru(this.value, this.displayName);
  final String value;
  final String displayName;

  static EvrakTuru fromString(String value) {
    return EvrakTuru.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EvrakTuru.diger,
    );
  }
}

/// Evrak durumu.
enum EvrakDurum {
  aktif('aktif', 'Aktif'),
  arsivlendi('arsivlendi', 'Arşivlendi'),
  silindi('silindi', 'Silindi');

  const EvrakDurum(this.value, this.displayName);
  final String value;
  final String displayName;

  static EvrakDurum fromString(String value) {
    return EvrakDurum.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EvrakDurum.aktif,
    );
  }
}
