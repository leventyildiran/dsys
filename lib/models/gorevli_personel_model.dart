/// Danışmanlığa atanmış görevli personel modeli.
///
/// Firestore yolu: `danismanliklar/{danismanlikId}/gorevliPersonel/{atamaId}`
class GorevliPersonelModel {
  const GorevliPersonelModel({
    required this.id,
    required this.personelId,
    required this.adSoyad,
    required this.unvan,
    required this.unvanKatsayisi,
    this.payOrani = 100,
  });

  final String id;
  final String personelId;
  final String adSoyad;
  final String unvan;
  final double unvanKatsayisi;
  final int payOrani; // %100, %60, %40 vb.

  factory GorevliPersonelModel.fromMap(String id, Map<String, dynamic> map) {
    return GorevliPersonelModel(
      id: id,
      personelId: map['personelId'] as String? ?? '',
      adSoyad: map['adSoyad'] as String? ?? '',
      unvan: map['unvan'] as String? ?? '',
      unvanKatsayisi: (map['unvanKatsayisi'] as num?)?.toDouble() ?? 1.0,
      payOrani: (map['payOrani'] as num?)?.toInt() ?? 100,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'personelId': personelId,
      'adSoyad': adSoyad,
      'unvan': unvan,
      'unvanKatsayisi': unvanKatsayisi,
      'payOrani': payOrani,
    };
  }

  GorevliPersonelModel copyWith({
    String? personelId,
    String? adSoyad,
    String? unvan,
    double? unvanKatsayisi,
    int? payOrani,
  }) {
    return GorevliPersonelModel(
      id: id,
      personelId: personelId ?? this.personelId,
      adSoyad: adSoyad ?? this.adSoyad,
      unvan: unvan ?? this.unvan,
      unvanKatsayisi: unvanKatsayisi ?? this.unvanKatsayisi,
      payOrani: payOrani ?? this.payOrani,
    );
  }
}
