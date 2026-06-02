/// Sistem ayarları modeli.
class SistemAyarlariModel {
  const SistemAyarlariModel({
    required this.memurMaasKatsayisi,
    required this.eydmaGosterge,
    required this.varsayilanKesintiler,
    required this.unvanKatsayilari,
    this.aiApiKey,
    this.aiApiUrl,
    this.aiModel,
    this.kurulUyeleri,
    this.kurumAdi,
    this.antetBasligi,
    this.extractorApiUrl,
    this.extractorApiKey,
    this.extractorProvider,
    this.extractorEnabled,
  });

  final double memurMaasKatsayisi;
  final int eydmaGosterge; // 9500 (1500+8000)
  final VarsayilanKesintiler varsayilanKesintiler;
  final Map<String, double> unvanKatsayilari;
  final String? aiApiKey;
  final String? aiApiUrl;
  final String? aiModel;
  final List<KurulUyesiModel>? kurulUyeleri;
  final String? kurumAdi;
  final String? antetBasligi;
  final String? extractorApiUrl;
  final String? extractorApiKey;
  final String? extractorProvider;
  final bool? extractorEnabled;

  /// Hesaplanan EYDMA değeri.
  double get hesaplananEydma => eydmaGosterge * memurMaasKatsayisi;

  /// Kurum / Üniversite adı (boşsa varsayılanı döner).
  String get kurumAdiGuncel => (kurumAdi == null || kurumAdi!.trim().isEmpty) ? 'UŞAK ÜNİVERSİTESİ' : kurumAdi!;

  /// Karar / Antet başlığı (boşsa varsayılanı döner).
  String get antetBasligiGuncel => (antetBasligi == null || antetBasligi!.trim().isEmpty) ? 'DÖNER SERMAYE YÜRÜTME KURULU KARARLARI' : antetBasligi!;

  /// Kurul üyeleri listesi (boşsa varsayılan listeyi döner).
  List<KurulUyesiModel> get kurulUyeleriListesi =>
      (kurulUyeleri == null || kurulUyeleri!.isEmpty)
          ? varsayilanKurulUyeleri
          : kurulUyeleri!;

      /// Harici tablo extractor aktif mi?
      bool get hasActiveExtractor =>
        (extractorEnabled ?? false) &&
        extractorApiUrl != null &&
        extractorApiUrl!.trim().isNotEmpty;

  /// Varsayılan kurul üyeleri.
  static List<KurulUyesiModel> get varsayilanKurulUyeleri => const [
        KurulUyesiModel(siraNo: '1', gorev: 'Başkan', adSoyad: 'Prof. Dr. Selçuk SAMANLI'),
        KurulUyesiModel(siraNo: '2', gorev: 'Üye', adSoyad: 'Prof. Dr. Mehmet Ali GÜNGÖR'),
        KurulUyesiModel(siraNo: '3', gorev: 'Üye', adSoyad: 'Doç. Dr. Erkan HALAY'),
        KurulUyesiModel(siraNo: '4', gorev: 'Üye', adSoyad: 'Doç. Dr. Mustafa TAYTAK'),
        KurulUyesiModel(siraNo: '5', gorev: 'Üye', adSoyad: 'Ercan BİLGEÇ'),
        KurulUyesiModel(siraNo: '6', gorev: 'Raportör', adSoyad: 'Levent YILDIRAN'),
      ];

  factory SistemAyarlariModel.fromMap(Map<String, dynamic> map) {
    final kesintilerMap =
        map['varsayilanKesintiler'] as Map<String, dynamic>? ?? {};
    final unvanMap = map['unvanKatsayilari'] as Map<String, dynamic>? ?? {};

    return SistemAyarlariModel(
      memurMaasKatsayisi:
          (map['memurMaasKatsayisi'] as num?)?.toDouble() ?? 1.0,
      eydmaGosterge: (map['eydmaGosterge'] as num?)?.toInt() ?? 9500,
      varsayilanKesintiler: VarsayilanKesintiler.fromMap(kesintilerMap),
      unvanKatsayilari: unvanMap.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
      aiApiKey: map['aiApiKey'] as String?,
      aiApiUrl: map['aiApiUrl'] as String?,
      aiModel: map['aiModel'] as String?,
      kurulUyeleri: (map['kurulUyeleri'] as List?)
          ?.map((e) => KurulUyesiModel.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      kurumAdi: map['kurumAdi'] as String?,
      antetBasligi: map['antetBasligi'] as String?,
      extractorApiUrl: map['extractorApiUrl'] as String?,
      extractorApiKey: map['extractorApiKey'] as String?,
      extractorProvider: map['extractorProvider'] as String?,
      extractorEnabled: map['extractorEnabled'] as bool?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memurMaasKatsayisi': memurMaasKatsayisi,
      'eydmaGosterge': eydmaGosterge,
      'hesaplananEydma': hesaplananEydma,
      'varsayilanKesintiler': varsayilanKesintiler.toMap(),
      'unvanKatsayilari': unvanKatsayilari,
      'aiApiKey': aiApiKey,
      'aiApiUrl': aiApiUrl,
      'aiModel': aiModel,
      if (kurulUyeleri != null)
        'kurulUyeleri': kurulUyeleri!.map((e) => e.toMap()).toList(),
      'kurumAdi': kurumAdi,
      'antetBasligi': antetBasligi,
      'extractorApiUrl': extractorApiUrl,
      'extractorApiKey': extractorApiKey,
      'extractorProvider': extractorProvider,
      'extractorEnabled': extractorEnabled,
    };
  }
}

/// Varsayılan kesinti oranları.
class VarsayilanKesintiler {
  const VarsayilanKesintiler({
    this.hazinePayi = 1,
    this.bapPayi = 5,
    this.aracGerecPayi = 45,
    this.dagitilabilir = 49,
  });

  final int hazinePayi;
  final int bapPayi;
  final int aracGerecPayi;
  final int dagitilabilir;

  factory VarsayilanKesintiler.fromMap(Map<String, dynamic> map) {
    return VarsayilanKesintiler(
      hazinePayi: (map['hazinePayi'] as num?)?.toInt() ?? 1,
      bapPayi: (map['bapPayi'] as num?)?.toInt() ?? 5,
      aracGerecPayi: (map['aracGerecPayi'] as num?)?.toInt() ?? 45,
      dagitilabilir: (map['dagitilabilir'] as num?)?.toInt() ?? 49,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hazinePayi': hazinePayi,
      'bapPayi': bapPayi,
      'aracGerecPayi': aracGerecPayi,
      'dagitilabilir': dagitilabilir,
    };
  }
}

/// Kurul üyesi modeli.
class KurulUyesiModel {
  const KurulUyesiModel({
    required this.siraNo,
    required this.gorev,
    required this.adSoyad,
  });

  final String siraNo;
  final String gorev;
  final String adSoyad;

  factory KurulUyesiModel.fromMap(Map<String, dynamic> map) {
    return KurulUyesiModel(
      siraNo: map['siraNo'] as String? ?? '',
      gorev: map['gorev'] as String? ?? '',
      adSoyad: map['adSoyad'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'siraNo': siraNo,
      'gorev': gorev,
      'adSoyad': adSoyad,
    };
  }
}

