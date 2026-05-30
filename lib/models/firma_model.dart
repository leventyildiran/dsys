/// Firma (müşteri) modeli.
class FirmaModel {
  const FirmaModel({
    required this.id,
    required this.unvan,
    this.vergiNo,
    this.vergiDairesi,
    this.adres,
    this.telefon,
    this.yetkiliKisi,
    this.aktif = true,
  });

  final String id;
  final String unvan;
  final String? vergiNo;
  final String? vergiDairesi;
  final String? adres;
  final String? telefon;
  final String? yetkiliKisi;
  final bool aktif;

  factory FirmaModel.fromMap(String id, Map<String, dynamic> map) {
    return FirmaModel(
      id: id,
      unvan: map['unvan'] as String? ?? '',
      vergiNo: map['vergiNo'] as String?,
      vergiDairesi: map['vergiDairesi'] as String?,
      adres: map['adres'] as String?,
      telefon: map['telefon'] as String?,
      yetkiliKisi: map['yetkiliKisi'] as String?,
      aktif: map['aktif'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'unvan': unvan,
      'vergiNo': vergiNo,
      'vergiDairesi': vergiDairesi,
      'adres': adres,
      'telefon': telefon,
      'yetkiliKisi': yetkiliKisi,
      'aktif': aktif,
    };
  }

  FirmaModel copyWith({
    String? unvan,
    String? vergiNo,
    String? vergiDairesi,
    String? adres,
    String? telefon,
    String? yetkiliKisi,
    bool? aktif,
  }) {
    return FirmaModel(
      id: id,
      unvan: unvan ?? this.unvan,
      vergiNo: vergiNo ?? this.vergiNo,
      vergiDairesi: vergiDairesi ?? this.vergiDairesi,
      adres: adres ?? this.adres,
      telefon: telefon ?? this.telefon,
      yetkiliKisi: yetkiliKisi ?? this.yetkiliKisi,
      aktif: aktif ?? this.aktif,
    );
  }
}
