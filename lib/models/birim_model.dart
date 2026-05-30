/// Birim türü enum tanımı.
enum BirimTuru {
  merkez('merkez', 'Merkez'),
  fakulte('fakulte', 'Fakülte'),
  enstitu('enstitu', 'Enstitü'),
  meslekYuksekokulu('meslek_yuksekokulu', 'Meslek Yüksekokulu');

  const BirimTuru(this.value, this.displayName);
  final String value;
  final String displayName;

  static BirimTuru fromString(String value) {
    return BirimTuru.values.firstWhere(
      (t) => t.value == value,
      orElse: () => BirimTuru.merkez,
    );
  }
}

/// Üniversite birimi modeli.
class BirimModel {
  const BirimModel({
    required this.id,
    required this.ad,
    required this.kisaAd,
    required this.tur,
    this.mudurAd,
    this.aktif = true,
  });

  final String id;
  final String ad;
  final String kisaAd;
  final BirimTuru tur;
  final String? mudurAd;
  final bool aktif;

  factory BirimModel.fromMap(String id, Map<String, dynamic> map) {
    return BirimModel(
      id: id,
      ad: map['ad'] as String? ?? '',
      kisaAd: map['kisaAd'] as String? ?? '',
      tur: BirimTuru.fromString(map['tur'] as String? ?? 'merkez'),
      mudurAd: map['mudurAd'] as String?,
      aktif: map['aktif'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ad': ad,
      'kisaAd': kisaAd,
      'tur': tur.value,
      'mudurAd': mudurAd,
      'aktif': aktif,
    };
  }

  BirimModel copyWith({
    String? ad,
    String? kisaAd,
    BirimTuru? tur,
    String? mudurAd,
    bool? aktif,
  }) {
    return BirimModel(
      id: id,
      ad: ad ?? this.ad,
      kisaAd: kisaAd ?? this.kisaAd,
      tur: tur ?? this.tur,
      mudurAd: mudurAd ?? this.mudurAd,
      aktif: aktif ?? this.aktif,
    );
  }
}
