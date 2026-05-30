/// Sistem ayarları modeli.
class SistemAyarlariModel {
  const SistemAyarlariModel({
    required this.memurMaasKatsayisi,
    required this.eydmaGosterge,
    required this.varsayilanKesintiler,
    required this.unvanKatsayilari,
  });

  final double memurMaasKatsayisi;
  final int eydmaGosterge; // 9500 (1500+8000)
  final VarsayilanKesintiler varsayilanKesintiler;
  final Map<String, double> unvanKatsayilari;

  /// Hesaplanan EYDMA değeri.
  double get hesaplananEydma => eydmaGosterge * memurMaasKatsayisi;

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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memurMaasKatsayisi': memurMaasKatsayisi,
      'eydmaGosterge': eydmaGosterge,
      'hesaplananEydma': hesaplananEydma,
      'varsayilanKesintiler': varsayilanKesintiler.toMap(),
      'unvanKatsayilari': unvanKatsayilari,
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
