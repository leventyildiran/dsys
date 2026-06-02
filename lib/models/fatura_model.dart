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
    this.kalemler = const [],
    this.seriNo,
    this.siraNo,
    this.numuneNo,
    this.melbesBasvuruNo,
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
  final List<FaturaKalem> kalemler;
  final String? seriNo;
  final String? siraNo;
  final String? numuneNo;
  final String? melbesBasvuruNo;
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
        kalemler: (map['kalemler'] as List?)
            ?.whereType<Map>()
            .map((e) => FaturaKalem.fromMap(Map<String, dynamic>.from(e)))
            .toList() ??
          const [],
      seriNo: map['seriNo'],
      siraNo: map['siraNo'],
      numuneNo: map['numuneNo'],
      melbesBasvuruNo: map['melbesBasvuruNo'],
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
      'kalemler': kalemler.map((e) => e.toMap()).toList(),
      'seriNo': seriNo,
      'siraNo': siraNo,
      'numuneNo': numuneNo,
      'melbesBasvuruNo': melbesBasvuruNo,
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
    List<FaturaKalem>? kalemler,
    String? seriNo,
    String? siraNo,
    String? numuneNo,
    String? melbesBasvuruNo,
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
      kalemler: kalemler ?? this.kalemler,
      seriNo: seriNo ?? this.seriNo,
      siraNo: siraNo ?? this.siraNo,
      numuneNo: numuneNo ?? this.numuneNo,
      melbesBasvuruNo: melbesBasvuruNo ?? this.melbesBasvuruNo,
      faturaTarihi: faturaTarihi ?? this.faturaTarihi,
      durum: durum ?? this.durum,
      olusturmaTarihi: olusturmaTarihi,
    );
  }
}

class FaturaKalem {
  const FaturaKalem({
    required this.aciklama,
    this.adet = 1,
    this.birimFiyat = 0,
    this.tutar = 0,
  });

  final String aciklama;
  final int adet;
  final double birimFiyat;
  final double tutar;

  factory FaturaKalem.fromMap(Map<String, dynamic> map) {
    return FaturaKalem(
      aciklama: map['aciklama']?.toString() ?? '',
      adet: (map['adet'] as num?)?.toInt() ?? 1,
      birimFiyat: (map['birimFiyat'] as num?)?.toDouble() ?? 0,
      tutar: (map['tutar'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'aciklama': aciklama,
      'adet': adet,
      'birimFiyat': birimFiyat,
      'tutar': tutar,
    };
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
