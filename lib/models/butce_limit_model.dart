/// Bütçe Limit / Ödenek Tanım Modeli.
///
/// Birimlerin yıllık bütçe kalemlerini, ödenek limitlerini
/// ve harcama kümülatiflerini takip eder.
/// Firestore yolu: `butceLimitleri/{birimId_yil}`
class ButceLimitModel {
  const ButceLimitModel({
    required this.id,
    required this.birimId,
    required this.birimAd,
    required this.yil,
    required this.kalemler,
    this.toplamOdenek = 0,
    this.toplamHarcama = 0,
    this.olusturmaTarihi,
    this.guncellenmeTarihi,
  });

  final String id;
  final String birimId;
  final String birimAd;
  final int yil;
  final List<ButceKalemi> kalemler;
  final double toplamOdenek;
  final double toplamHarcama;
  final DateTime? olusturmaTarihi;
  final DateTime? guncellenmeTarihi;

  /// Toplam kullanım oranı (0.0 - 1.0+)
  double get kullanimOrani =>
      toplamOdenek == 0 ? 0 : toplamHarcama / toplamOdenek;

  /// %10 sınır aşımı kontrolü.
  /// Herhangi bir kalemde kümülatif harcama, ödenek limitinin %110'unu aşarsa true döner.
  bool get limitAsimi => kalemler.any((k) => k.limitAsildiMi);

  /// Limit aşan kalemleri döner.
  List<ButceKalemi> get limitAsanKalemler =>
      kalemler.where((k) => k.limitAsildiMi).toList();

  factory ButceLimitModel.fromMap(String id, Map<String, dynamic> map) {
    final kalemlerData = map['kalemler'] as List<dynamic>? ?? [];
    return ButceLimitModel(
      id: id,
      birimId: map['birimId'] ?? '',
      birimAd: map['birimAd'] ?? '',
      yil: map['yil'] ?? DateTime.now().year,
      kalemler: kalemlerData
          .map((k) => ButceKalemi.fromMap(k as Map<String, dynamic>))
          .toList(),
      toplamOdenek: (map['toplamOdenek'] ?? 0).toDouble(),
      toplamHarcama: (map['toplamHarcama'] ?? 0).toDouble(),
      olusturmaTarihi: map['olusturmaTarihi'] != null
          ? DateTime.tryParse(map['olusturmaTarihi'])
          : null,
      guncellenmeTarihi: map['guncellenmeTarihi'] != null
          ? DateTime.tryParse(map['guncellenmeTarihi'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'birimId': birimId,
      'birimAd': birimAd,
      'yil': yil,
      'kalemler': kalemler.map((k) => k.toMap()).toList(),
      'toplamOdenek': toplamOdenek,
      'toplamHarcama': toplamHarcama,
      'olusturmaTarihi': olusturmaTarihi?.toIso8601String(),
      'guncellenmeTarihi': guncellenmeTarihi?.toIso8601String(),
    };
  }

  ButceLimitModel copyWith({
    String? birimId,
    String? birimAd,
    int? yil,
    List<ButceKalemi>? kalemler,
    double? toplamOdenek,
    double? toplamHarcama,
  }) {
    return ButceLimitModel(
      id: id,
      birimId: birimId ?? this.birimId,
      birimAd: birimAd ?? this.birimAd,
      yil: yil ?? this.yil,
      kalemler: kalemler ?? this.kalemler,
      toplamOdenek: toplamOdenek ?? this.toplamOdenek,
      toplamHarcama: toplamHarcama ?? this.toplamHarcama,
      olusturmaTarihi: olusturmaTarihi,
      guncellenmeTarihi: DateTime.now(),
    );
  }
}

/// Bütçe kalemi (03.02, 03.05, vb.)
class ButceKalemi {
  const ButceKalemi({
    required this.kod,
    required this.ad,
    required this.odenekTutar,
    this.harcamaTutar = 0,
    this.blokeDurum = false,
  });

  /// Bütçe ekonomik kodu (ör: '03.02', '03.05', '06.01')
  final String kod;

  /// Kalem açıklaması (ör: 'Tüketime Yönelik Mal ve Malzeme Alımları')
  final String ad;

  /// Yıllık ödenek tutarı
  final double odenekTutar;

  /// Kümülatif harcama tutarı
  final double harcamaTutar;

  /// YK onayına yönlendirilmiş bloke durumu
  final bool blokeDurum;

  /// Kullanım oranı (0.0 - 1.0+)
  double get kullanimOrani =>
      odenekTutar == 0 ? 0 : harcamaTutar / odenekTutar;

  /// %10 tolerans dahil limit kontrolü.
  /// Harcama, ödenek × 1.10 değerini aşarsa limit aşılmış demektir.
  bool get limitAsildiMi => harcamaTutar > odenekTutar * 1.10;

  /// Kalan ödenek tutarı.
  double get kalanOdenek => odenekTutar - harcamaTutar;

  factory ButceKalemi.fromMap(Map<String, dynamic> map) {
    return ButceKalemi(
      kod: map['kod'] ?? '',
      ad: map['ad'] ?? '',
      odenekTutar: (map['odenekTutar'] ?? 0).toDouble(),
      harcamaTutar: (map['harcamaTutar'] ?? 0).toDouble(),
      blokeDurum: map['blokeDurum'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'kod': kod,
      'ad': ad,
      'odenekTutar': odenekTutar,
      'harcamaTutar': harcamaTutar,
      'blokeDurum': blokeDurum,
    };
  }

  ButceKalemi copyWith({
    String? kod,
    String? ad,
    double? odenekTutar,
    double? harcamaTutar,
    bool? blokeDurum,
  }) {
    return ButceKalemi(
      kod: kod ?? this.kod,
      ad: ad ?? this.ad,
      odenekTutar: odenekTutar ?? this.odenekTutar,
      harcamaTutar: harcamaTutar ?? this.harcamaTutar,
      blokeDurum: blokeDurum ?? this.blokeDurum,
    );
  }
}

/// Harcama talebi (limit kontrol mekanizması için).
class HarcamaTalebi {
  const HarcamaTalebi({
    required this.id,
    required this.birimId,
    required this.birimAd,
    required this.kalemKod,
    required this.tutar,
    required this.aciklama,
    this.durum = HarcamaTalebiDurum.beklemede,
    this.olusturmaTarihi,
  });

  final String id;
  final String birimId;
  final String birimAd;
  final String kalemKod;
  final double tutar;
  final String aciklama;
  final HarcamaTalebiDurum durum;
  final DateTime? olusturmaTarihi;

  factory HarcamaTalebi.fromMap(String id, Map<String, dynamic> map) {
    return HarcamaTalebi(
      id: id,
      birimId: map['birimId'] ?? '',
      birimAd: map['birimAd'] ?? '',
      kalemKod: map['kalemKod'] ?? '',
      tutar: (map['tutar'] ?? 0).toDouble(),
      aciklama: map['aciklama'] ?? '',
      durum: HarcamaTalebiDurum.fromString(map['durum'] ?? 'beklemede'),
      olusturmaTarihi: map['olusturmaTarihi'] != null
          ? DateTime.tryParse(map['olusturmaTarihi'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'birimId': birimId,
      'birimAd': birimAd,
      'kalemKod': kalemKod,
      'tutar': tutar,
      'aciklama': aciklama,
      'durum': durum.value,
      'olusturmaTarihi': olusturmaTarihi?.toIso8601String(),
    };
  }
}

/// Harcama talebi durumları.
enum HarcamaTalebiDurum {
  beklemede('beklemede', 'Beklemede'),
  ykOnayinda('yk_onayinda', 'YK Onayında'),
  onaylandi('onaylandi', 'Onaylandı'),
  reddedildi('reddedildi', 'Reddedildi');

  const HarcamaTalebiDurum(this.value, this.displayName);
  final String value;
  final String displayName;

  static HarcamaTalebiDurum fromString(String value) {
    return HarcamaTalebiDurum.values.firstWhere(
      (e) => e.value == value,
      orElse: () => HarcamaTalebiDurum.beklemede,
    );
  }
}
