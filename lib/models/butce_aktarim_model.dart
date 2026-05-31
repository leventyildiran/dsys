/// Bütçe aktarım karar modeli.
///
/// Birimlerin bütçe kalemleri arasındaki aktarımları temsil eder.
/// Firestore yolu: `butceAktarimlari/{aktarimId}`
class ButceAktarimModel {
  const ButceAktarimModel({
    required this.id,
    required this.birimId,
    required this.birimAd,
    required this.kararTarihi,
    required this.kararNo,
    required this.satirlar,
    this.toplamArtirilan = 0,
    this.toplamEksiltilen = 0,
    this.gerekce,
    this.durum = ButceAktarimDurum.taslak,
    this.olusturmaTarihi,
  });

  final String id;
  final String birimId;
  final String birimAd;
  final String kararTarihi;
  final String kararNo;
  final List<ButceAktarimSatir> satirlar;
  final double toplamArtirilan;
  final double toplamEksiltilen;
  final String? gerekce;
  final ButceAktarimDurum durum;
  final DateTime? olusturmaTarihi;

  factory ButceAktarimModel.fromMap(String id, Map<String, dynamic> map) {
    final satirlarData = map['satirlar'] as List<dynamic>? ?? [];
    return ButceAktarimModel(
      id: id,
      birimId: map['birimId'] ?? '',
      birimAd: map['birimAd'] ?? '',
      kararTarihi: map['kararTarihi'] ?? '',
      kararNo: map['kararNo'] ?? '',
      satirlar: satirlarData
          .map((s) => ButceAktarimSatir.fromMap(s as Map<String, dynamic>))
          .toList(),
      toplamArtirilan: (map['toplamArtirilan'] ?? 0).toDouble(),
      toplamEksiltilen: (map['toplamEksiltilen'] ?? 0).toDouble(),
      gerekce: map['gerekce'],
      durum: ButceAktarimDurum.fromString(map['durum'] ?? 'taslak'),
      olusturmaTarihi: map['olusturmaTarihi'] != null
          ? DateTime.tryParse(map['olusturmaTarihi'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'birimId': birimId,
      'birimAd': birimAd,
      'kararTarihi': kararTarihi,
      'kararNo': kararNo,
      'satirlar': satirlar.map((s) => s.toMap()).toList(),
      'toplamArtirilan': toplamArtirilan,
      'toplamEksiltilen': toplamEksiltilen,
      'gerekce': gerekce,
      'durum': durum.value,
      'olusturmaTarihi': olusturmaTarihi?.toIso8601String(),
    };
  }

  ButceAktarimModel copyWith({
    String? birimId,
    String? birimAd,
    String? kararTarihi,
    String? kararNo,
    List<ButceAktarimSatir>? satirlar,
    double? toplamArtirilan,
    double? toplamEksiltilen,
    String? gerekce,
    ButceAktarimDurum? durum,
  }) {
    return ButceAktarimModel(
      id: id,
      birimId: birimId ?? this.birimId,
      birimAd: birimAd ?? this.birimAd,
      kararTarihi: kararTarihi ?? this.kararTarihi,
      kararNo: kararNo ?? this.kararNo,
      satirlar: satirlar ?? this.satirlar,
      toplamArtirilan: toplamArtirilan ?? this.toplamArtirilan,
      toplamEksiltilen: toplamEksiltilen ?? this.toplamEksiltilen,
      gerekce: gerekce ?? this.gerekce,
      durum: durum ?? this.durum,
      olusturmaTarihi: olusturmaTarihi,
    );
  }
}

/// Bütçe aktarım tablo satırı.
class ButceAktarimSatir {
  const ButceAktarimSatir({
    required this.bolum,
    required this.madde,
    this.kabulEdilenGider = 0,
    this.artirilanTutar = 0,
    this.eksiltilenTutar = 0,
    this.gerekce = '',
  });

  final String bolum;
  final String madde;
  final double kabulEdilenGider;
  final double artirilanTutar;
  final double eksiltilenTutar;
  final String gerekce;

  factory ButceAktarimSatir.fromMap(Map<String, dynamic> map) {
    return ButceAktarimSatir(
      bolum: map['bolum'] ?? '',
      madde: map['madde'] ?? '',
      kabulEdilenGider: (map['kabulEdilenGider'] ?? 0).toDouble(),
      artirilanTutar: (map['artirilanTutar'] ?? 0).toDouble(),
      eksiltilenTutar: (map['eksiltilenTutar'] ?? 0).toDouble(),
      gerekce: map['gerekce'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bolum': bolum,
      'madde': madde,
      'kabulEdilenGider': kabulEdilenGider,
      'artirilanTutar': artirilanTutar,
      'eksiltilenTutar': eksiltilenTutar,
      'gerekce': gerekce,
    };
  }
}

/// Bütçe aktarım durumları.
enum ButceAktarimDurum {
  taslak('taslak', 'Taslak'),
  onayBekliyor('onay_bekliyor', 'Onay Bekliyor'),
  onaylandi('onaylandi', 'Onaylandı'),
  reddedildi('reddedildi', 'Reddedildi');

  const ButceAktarimDurum(this.value, this.displayName);
  final String value;
  final String displayName;

  static ButceAktarimDurum fromString(String value) {
    return ButceAktarimDurum.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ButceAktarimDurum.taslak,
    );
  }
}
