class EvrakOcrSonucu {
  const EvrakOcrSonucu({
    required this.baslik,
    required this.evrakSayisi,
    required this.evrakTarihi,
    required this.icerikOzeti,
    required this.etiketler,
    required this.hamCevap,
  });

  final String baslik;
  final String evrakSayisi;
  final String evrakTarihi;
  final String icerikOzeti;
  final List<String> etiketler;
  final String hamCevap;
}
