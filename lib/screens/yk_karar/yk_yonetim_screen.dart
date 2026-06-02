import 'package:flutter/material.dart';
import 'yk_gundem_detay_panel.dart';

/// Yürütme Kurulu Yönetim Ekranı.
///
/// Eski sekmeli (tab) yapıyı kaldırıp doğrudan tümleşik karar yazma,
/// A4 önizleme ve yan çekmeceli (drawer) iş akışını içeren
/// YkGundemDetayPanel'i yükler.
class YkYonetimScreen extends StatelessWidget {
  const YkYonetimScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const YkGundemDetayPanel();
  }
}
