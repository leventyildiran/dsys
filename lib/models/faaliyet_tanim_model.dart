/// Faaliyet tanım modeli.
class FaaliyetTanimModel {
  const FaaliyetTanimModel({
    required this.id,
    required this.ad,
    required this.puan,
    required this.birim,
    this.aktif = true,
  });

  final String id;
  final String ad;
  final int puan;
  final String birim; // "Adet", "Saat"
  final bool aktif;

  factory FaaliyetTanimModel.fromMap(String id, Map<String, dynamic> map) {
    return FaaliyetTanimModel(
      id: id,
      ad: map['ad'] as String? ?? '',
      puan: (map['puan'] as num?)?.toInt() ?? 0,
      birim: map['birim'] as String? ?? 'Adet',
      aktif: map['aktif'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ad': ad,
      'puan': puan,
      'birim': birim,
      'aktif': aktif,
    };
  }
}
