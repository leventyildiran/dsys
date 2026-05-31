/// Diş Hekimliği Katkı Payı Dağıtım Modeli.
///
/// Merkezin yüksek bütçeli dönemsel ödemelerini yönetir.
/// Firestore yolu: `disHekimligiDagitimlari/{dagitimId}`
class DisHekimligiDagitimModel {
  const DisHekimligiDagitimModel({
    required this.id,
    required this.birimId,
    required this.birimAd,
    required this.donem,
    required this.toplamBrutGelir,
    required this.akademikIdariTutar,
    required this.yoneticiTutar,
    required this.mesaiDisiTutar,
    this.personelListesi = const [],
    this.kararTarihi,
    this.kararNo,
    this.durum = DisHekimligiDurum.taslak,
    this.olusturmaTarihi,
  });

  final String id;
  final String birimId;
  final String birimAd;
  final String donem;
  final double toplamBrutGelir;
  final double akademikIdariTutar;
  final double yoneticiTutar;
  final double mesaiDisiTutar;
  final List<DisHekimligiPersonel> personelListesi;
  final String? kararTarihi;
  final String? kararNo;
  final DisHekimligiDurum durum;
  final DateTime? olusturmaTarihi;

  factory DisHekimligiDagitimModel.fromMap(
      String id, Map<String, dynamic> map) {
    final personelData = map['personelListesi'] as List<dynamic>? ?? [];
    return DisHekimligiDagitimModel(
      id: id,
      birimId: map['birimId'] ?? '',
      birimAd: map['birimAd'] ?? '',
      donem: map['donem'] ?? '',
      toplamBrutGelir: (map['toplamBrutGelir'] ?? 0).toDouble(),
      akademikIdariTutar: (map['akademikIdariTutar'] ?? 0).toDouble(),
      yoneticiTutar: (map['yoneticiTutar'] ?? 0).toDouble(),
      mesaiDisiTutar: (map['mesaiDisiTutar'] ?? 0).toDouble(),
      personelListesi: personelData
          .map((p) => DisHekimligiPersonel.fromMap(p as Map<String, dynamic>))
          .toList(),
      kararTarihi: map['kararTarihi'],
      kararNo: map['kararNo'],
      durum: DisHekimligiDurum.fromString(map['durum'] ?? 'taslak'),
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
      'toplamBrutGelir': toplamBrutGelir,
      'akademikIdariTutar': akademikIdariTutar,
      'yoneticiTutar': yoneticiTutar,
      'mesaiDisiTutar': mesaiDisiTutar,
      'personelListesi': personelListesi.map((p) => p.toMap()).toList(),
      'kararTarihi': kararTarihi,
      'kararNo': kararNo,
      'durum': durum.value,
      'olusturmaTarihi': olusturmaTarihi?.toIso8601String(),
    };
  }

  DisHekimligiDagitimModel copyWith({
    String? birimId,
    String? birimAd,
    String? donem,
    double? toplamBrutGelir,
    double? akademikIdariTutar,
    double? yoneticiTutar,
    double? mesaiDisiTutar,
    List<DisHekimligiPersonel>? personelListesi,
    String? kararTarihi,
    String? kararNo,
    DisHekimligiDurum? durum,
  }) {
    return DisHekimligiDagitimModel(
      id: id,
      birimId: birimId ?? this.birimId,
      birimAd: birimAd ?? this.birimAd,
      donem: donem ?? this.donem,
      toplamBrutGelir: toplamBrutGelir ?? this.toplamBrutGelir,
      akademikIdariTutar: akademikIdariTutar ?? this.akademikIdariTutar,
      yoneticiTutar: yoneticiTutar ?? this.yoneticiTutar,
      mesaiDisiTutar: mesaiDisiTutar ?? this.mesaiDisiTutar,
      personelListesi: personelListesi ?? this.personelListesi,
      kararTarihi: kararTarihi ?? this.kararTarihi,
      kararNo: kararNo ?? this.kararNo,
      durum: durum ?? this.durum,
      olusturmaTarihi: olusturmaTarihi,
    );
  }
}

/// Diş hekimliği dağıtım personel bilgisi.
class DisHekimligiPersonel {
  const DisHekimligiPersonel({
    required this.personelId,
    required this.adSoyad,
    required this.unvan,
    required this.brutHakedis,
    this.kategori = DisHekimligiKategori.akademikIdari,
  });

  final String personelId;
  final String adSoyad;
  final String unvan;
  final double brutHakedis;
  final DisHekimligiKategori kategori;

  factory DisHekimligiPersonel.fromMap(Map<String, dynamic> map) {
    return DisHekimligiPersonel(
      personelId: map['personelId'] ?? '',
      adSoyad: map['adSoyad'] ?? '',
      unvan: map['unvan'] ?? '',
      brutHakedis: (map['brutHakedis'] ?? 0).toDouble(),
      kategori: DisHekimligiKategori.fromString(
          map['kategori'] ?? 'akademik_idari'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'personelId': personelId,
      'adSoyad': adSoyad,
      'unvan': unvan,
      'brutHakedis': brutHakedis,
      'kategori': kategori.value,
    };
  }
}

/// Diş hekimliği personel kategorisi.
enum DisHekimligiKategori {
  akademikIdari('akademik_idari', 'Akademik ve İdari Personel'),
  yonetici('yonetici', 'Yönetici'),
  mesaiDisi('mesai_disi', 'Mesai Dışı Tedavi');

  const DisHekimligiKategori(this.value, this.displayName);
  final String value;
  final String displayName;

  static DisHekimligiKategori fromString(String value) {
    return DisHekimligiKategori.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DisHekimligiKategori.akademikIdari,
    );
  }
}

/// Diş hekimliği dağıtım durumları.
enum DisHekimligiDurum {
  taslak('taslak', 'Taslak'),
  hesaplandi('hesaplandi', 'Hesaplandı'),
  onayBekliyor('onay_bekliyor', 'Onay Bekliyor'),
  onaylandi('onaylandi', 'Onaylandı'),
  odendi('odendi', 'Ödendi');

  const DisHekimligiDurum(this.value, this.displayName);
  final String value;
  final String displayName;

  static DisHekimligiDurum fromString(String value) {
    return DisHekimligiDurum.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DisHekimligiDurum.taslak,
    );
  }
}
