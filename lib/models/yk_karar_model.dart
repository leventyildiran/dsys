/// Yürütme Kurulu Karar Modeli.
class YkKararModel {
  const YkKararModel({
    required this.id,
    required this.toplantiId,
    required this.toplantiNo,
    required this.kararNo,
    required this.kararTarihi,
    required this.birimId,
    required this.birimAd,
    required this.tur,
    required this.baslik,
    required this.kararMetni,
    required this.iliskiliKayitId,
    this.olusturmaTarihi,
    this.durum = YkKararDurum.taslak,
  });

  final String id;
  final String toplantiId;
  final String toplantiNo;
  final String kararNo;
  final String kararTarihi;
  final String birimId;
  final String birimAd;
  final YkKararTuru tur;
  final String baslik;
  final String kararMetni;
  final String iliskiliKayitId;
  final DateTime? olusturmaTarihi;
  final YkKararDurum durum;

  factory YkKararModel.fromMap(String id, Map<String, dynamic> map) {
    return YkKararModel(
      id: id,
      toplantiId: map['toplantiId'] ?? '',
      toplantiNo: map['toplantiNo'] ?? '',
      kararNo: map['kararNo'] ?? '',
      kararTarihi: map['kararTarihi'] ?? '',
      birimId: map['birimId'] ?? '',
      birimAd: map['birimAd'] ?? '',
      tur: YkKararTuru.fromString(map['tur'] ?? 'diger'),
      baslik: map['baslik'] ?? '',
      kararMetni: map['kararMetni'] ?? '',
      iliskiliKayitId: map['iliskiliKayitId'] ?? '',
      olusturmaTarihi: map['olusturmaTarihi'] != null
          ? DateTime.tryParse(map['olusturmaTarihi'])
          : null,
      durum: YkKararDurum.fromString(map['durum'] ?? 'taslak'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'toplantiId': toplantiId,
      'toplantiNo': toplantiNo,
      'kararNo': kararNo,
      'kararTarihi': kararTarihi,
      'birimId': birimId,
      'birimAd': birimAd,
      'tur': tur.value,
      'baslik': baslik,
      'kararMetni': kararMetni,
      'iliskiliKayitId': iliskiliKayitId,
      'olusturmaTarihi': olusturmaTarihi?.toIso8601String(),
      'durum': durum.value,
    };
  }

  YkKararModel copyWith({
    String? toplantiId,
    String? toplantiNo,
    String? kararNo,
    String? kararTarihi,
    String? birimId,
    String? birimAd,
    YkKararTuru? tur,
    String? baslik,
    String? kararMetni,
    String? iliskiliKayitId,
    DateTime? olusturmaTarihi,
    YkKararDurum? durum,
  }) {
    return YkKararModel(
      id: id,
      toplantiId: toplantiId ?? this.toplantiId,
      toplantiNo: toplantiNo ?? this.toplantiNo,
      kararNo: kararNo ?? this.kararNo,
      kararTarihi: kararTarihi ?? this.kararTarihi,
      birimId: birimId ?? this.birimId,
      birimAd: birimAd ?? this.birimAd,
      tur: tur ?? this.tur,
      baslik: baslik ?? this.baslik,
      kararMetni: kararMetni ?? this.kararMetni,
      iliskiliKayitId: iliskiliKayitId ?? this.iliskiliKayitId,
      olusturmaTarihi: olusturmaTarihi ?? this.olusturmaTarihi,
      durum: durum ?? this.durum,
    );
  }
}

/// Yürütme Kurulu Karar Türleri.
enum YkKararTuru {
  danismanlik('danismanlik', 'Danışmanlık Ödemesi'),
  butceAktarim('butce_aktarim', 'Bütçe Aktarımı'),
  ekOdeme('ek_odeme', 'Ek Ödeme Dağıtımı'),
  disHekimligi('dis_hekimligi', 'Diş Hekimliği Ödemesi'),
  diger('diger', 'Diğer Kararlar');

  const YkKararTuru(this.value, this.displayName);
  final String value;
  final String displayName;

  static YkKararTuru fromString(String value) {
    return YkKararTuru.values.firstWhere(
      (e) => e.value == value,
      orElse: () => YkKararTuru.diger,
    );
  }
}

/// Yürütme Kurulu Karar Durumları.
enum YkKararDurum {
  taslak('taslak', 'Taslak'),
  onaylandi('onaylandi', 'Onaylandı');

  const YkKararDurum(this.value, this.displayName);
  final String value;
  final String displayName;

  static YkKararDurum fromString(String value) {
    return YkKararDurum.values.firstWhere(
      (e) => e.value == value,
      orElse: () => YkKararDurum.taslak,
    );
  }
}
