/// Fatura modeli.
///
/// Otomatik fatura basım ve PDF önizleme modülü için.
/// Firestore yolu: `faturalar/{faturaId}`
class FaturaModel {
  const FaturaModel({
    required this.id,
    required this.birimId,
    required this.birimAd,
    required this.firmaUnvan,
    required this.hizmetDetay,
    required this.tutar,
    this.kdvOrani = 20,
    this.kdvTutar = 0,
    this.toplamTutar = 0,
    this.seriNo,
    this.siraNo,
    this.faturaTarihi,
    this.durum = FaturaDurum.bekleyen,
    this.olusturmaTarihi,
  });

  final String id;
  final String birimId;
  final String birimAd;
  final String firmaUnvan;
  final String hizmetDetay;
  final double tutar;
  final double kdvOrani;
  final double kdvTutar;
  final double toplamTutar;
  final String? seriNo;
  final String? siraNo;
  final String? faturaTarihi;
  final FaturaDurum durum;
  final DateTime? olusturmaTarihi;

  factory FaturaModel.fromMap(String id, Map<String, dynamic> map) {
    return FaturaModel(
      id: id,
      birimId: map['birimId'] ?? '',
      birimAd: map['birimAd'] ?? '',
      firmaUnvan: map['firmaUnvan'] ?? '',
      hizmetDetay: map['hizmetDetay'] ?? '',
      tutar: (map['tutar'] ?? 0).toDouble(),
      kdvOrani: (map['kdvOrani'] ?? 20).toDouble(),
      kdvTutar: (map['kdvTutar'] ?? 0).toDouble(),
      toplamTutar: (map['toplamTutar'] ?? 0).toDouble(),
      seriNo: map['seriNo'],
      siraNo: map['siraNo'],
      faturaTarihi: map['faturaTarihi'],
      durum: FaturaDurum.fromString(map['durum'] ?? 'bekleyen'),
      olusturmaTarihi: map['olusturmaTarihi'] != null
          ? DateTime.tryParse(map['olusturmaTarihi'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'birimId': birimId,
      'birimAd': birimAd,
      'firmaUnvan': firmaUnvan,
      'hizmetDetay': hizmetDetay,
      'tutar': tutar,
      'kdvOrani': kdvOrani,
      'kdvTutar': kdvTutar,
      'toplamTutar': toplamTutar,
      'seriNo': seriNo,
      'siraNo': siraNo,
      'faturaTarihi': faturaTarihi,
      'durum': durum.value,
      'olusturmaTarihi': olusturmaTarihi?.toIso8601String(),
    };
  }

  FaturaModel copyWith({
    String? birimId,
    String? birimAd,
    String? firmaUnvan,
    String? hizmetDetay,
    double? tutar,
    double? kdvOrani,
    double? kdvTutar,
    double? toplamTutar,
    String? seriNo,
    String? siraNo,
    String? faturaTarihi,
    FaturaDurum? durum,
  }) {
    return FaturaModel(
      id: id,
      birimId: birimId ?? this.birimId,
      birimAd: birimAd ?? this.birimAd,
      firmaUnvan: firmaUnvan ?? this.firmaUnvan,
      hizmetDetay: hizmetDetay ?? this.hizmetDetay,
      tutar: tutar ?? this.tutar,
      kdvOrani: kdvOrani ?? this.kdvOrani,
      kdvTutar: kdvTutar ?? this.kdvTutar,
      toplamTutar: toplamTutar ?? this.toplamTutar,
      seriNo: seriNo ?? this.seriNo,
      siraNo: siraNo ?? this.siraNo,
      faturaTarihi: faturaTarihi ?? this.faturaTarihi,
      durum: durum ?? this.durum,
      olusturmaTarihi: olusturmaTarihi,
    );
  }
}

/// Fatura durumları.
enum FaturaDurum {
  bekleyen('bekleyen', 'Bekleyen'),
  hazirlandi('hazirlandi', 'Hazırlandı'),
  onizlendi('onizlendi', 'Önizlendi'),
  basildi('basildi', 'Basıldı'),
  iptal('iptal', 'İptal');

  const FaturaDurum(this.value, this.displayName);
  final String value;
  final String displayName;

  static FaturaDurum fromString(String value) {
    return FaturaDurum.values.firstWhere(
      (e) => e.value == value,
      orElse: () => FaturaDurum.bekleyen,
    );
  }
}
