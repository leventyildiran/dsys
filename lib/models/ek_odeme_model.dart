/// Dönemsel ek ödeme dağıtım modeli.
///
/// Birimlerin havuzunda biriken paraların hocalara dönemsel dağıtımı.
/// Firestore yolu: `ekOdemeler/{ekOdemeId}`
class EkOdemeModel {
  const EkOdemeModel({
    required this.id,
    required this.birimId,
    required this.birimAd,
    required this.donem,
    required this.katsayi,
    required this.toplamDagitilanTutar,
    required this.toplamPuan,
    this.personelListesi = const [],
    this.durum = EkOdemeDurum.taslak,
    this.olusturmaTarihi,
  });

  final String id;
  final String birimId;
  final String birimAd;
  final String donem; // "Ocak-Şubat-Mart 2025"
  final double katsayi;
  final double toplamDagitilanTutar;
  final double toplamPuan;
  final List<EkOdemePersonel> personelListesi;
  final EkOdemeDurum durum;
  final DateTime? olusturmaTarihi;

  factory EkOdemeModel.fromMap(String id, Map<String, dynamic> map) {
    final personelData = map['personelListesi'] as List<dynamic>? ?? [];
    return EkOdemeModel(
      id: id,
      birimId: map['birimId'] ?? '',
      birimAd: map['birimAd'] ?? '',
      donem: map['donem'] ?? '',
      katsayi: (map['katsayi'] ?? 0).toDouble(),
      toplamDagitilanTutar: (map['toplamDagitilanTutar'] ?? 0).toDouble(),
      toplamPuan: (map['toplamPuan'] ?? 0).toDouble(),
      personelListesi: personelData
          .map((p) => EkOdemePersonel.fromMap(p as Map<String, dynamic>))
          .toList(),
      durum: EkOdemeDurum.fromString(map['durum'] ?? 'taslak'),
      olusturmaTarihi: map['olusturmaTarihi'] != null
          ? DateTime.tryParse(map['olusturmaTarihi'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'birimId': birimId,
      'birimAd': birimAd,
      'donem': donem,
      'katsayi': katsayi,
      'toplamDagitilanTutar': toplamDagitilanTutar,
      'toplamPuan': toplamPuan,
      'personelListesi': personelListesi.map((p) => p.toMap()).toList(),
      'durum': durum.value,
      'olusturmaTarihi': olusturmaTarihi?.toIso8601String(),
    };
  }

  EkOdemeModel copyWith({
    String? birimId,
    String? birimAd,
    String? donem,
    double? katsayi,
    double? toplamDagitilanTutar,
    double? toplamPuan,
    List<EkOdemePersonel>? personelListesi,
    EkOdemeDurum? durum,
  }) {
    return EkOdemeModel(
      id: id,
      birimId: birimId ?? this.birimId,
      birimAd: birimAd ?? this.birimAd,
      donem: donem ?? this.donem,
      katsayi: katsayi ?? this.katsayi,
      toplamDagitilanTutar: toplamDagitilanTutar ?? this.toplamDagitilanTutar,
      toplamPuan: toplamPuan ?? this.toplamPuan,
      personelListesi: personelListesi ?? this.personelListesi,
      durum: durum ?? this.durum,
      olusturmaTarihi: olusturmaTarihi,
    );
  }
}

/// Ek ödeme personel bilgisi.
class EkOdemePersonel {
  const EkOdemePersonel({
    required this.personelId,
    required this.adSoyad,
    required this.unvan,
    required this.puan,
    required this.unvanKatsayisi,
    required this.hakedis,
  });

  final String personelId;
  final String adSoyad;
  final String unvan;
  final double puan;
  final double unvanKatsayisi;
  final double hakedis;

  factory EkOdemePersonel.fromMap(Map<String, dynamic> map) {
    return EkOdemePersonel(
      personelId: map['personelId'] ?? '',
      adSoyad: map['adSoyad'] ?? '',
      unvan: map['unvan'] ?? '',
      puan: (map['puan'] ?? 0).toDouble(),
      unvanKatsayisi: (map['unvanKatsayisi'] ?? 1).toDouble(),
      hakedis: (map['hakedis'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'personelId': personelId,
      'adSoyad': adSoyad,
      'unvan': unvan,
      'puan': puan,
      'unvanKatsayisi': unvanKatsayisi,
      'hakedis': hakedis,
    };
  }
}

/// Ek ödeme durumları.
enum EkOdemeDurum {
  taslak('taslak', 'Taslak'),
  hesaplandi('hesaplandi', 'Hesaplandı'),
  onaylandi('onaylandi', 'Onaylandı'),
  odendi('odendi', 'Ödendi');

  const EkOdemeDurum(this.value, this.displayName);
  final String value;
  final String displayName;

  static EkOdemeDurum fromString(String value) {
    return EkOdemeDurum.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EkOdemeDurum.taslak,
    );
  }
}
