import 'package:flutter/material.dart';

import '../gundem/gundem_screen.dart';
import 'yk_gundem_detay_panel.dart';
import 'yk_gundem_yazma_panel.dart';
import 'yk_karar_merkezi_screen.dart';

/// Yürütme Kurulu Yönetim ekranı.
///
/// Gündem, Toplantı ve Karar Merkezi sayfalarını sekmeli (tab) yapıyla
/// tek bir dashboard altında birleştirir.
class YkYonetimScreen extends StatefulWidget {
  const YkYonetimScreen({super.key});

  @override
  State<YkYonetimScreen> createState() => _YkYonetimScreenState();
}

class _YkYonetimScreenState extends State<YkYonetimScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Theme.of(context).colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.event_rounded), text: 'Toplantılar'),
              Tab(icon: Icon(Icons.event_note_rounded), text: 'Gündem'),
              Tab(icon: Icon(Icons.edit_note_rounded), text: 'Karar Yazma'),
              Tab(icon: Icon(Icons.gavel_rounded), text: 'Karar Merkezi'),
            ],
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
            indicatorColor: Theme.of(context).colorScheme.primary,
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              GundemScreen(
                embedded: true,
                onToplantiSecildi: () {
                  _tabController.animateTo(2); // Karar Yazma sekmesine geç
                },
              ),
              YkGundemYazmaPanel(
                onGoToToplantilar: () {
                  _tabController.animateTo(0); // Toplantılar sekmesine geç
                },
              ),
              YkGundemDetayPanel(
                onGoToToplantilar: () {
                  _tabController.animateTo(0); // Toplantılar sekmesine geç
                },
              ),
              const YkKararMerkeziScreen(embedded: true),
            ],
          ),
        ),
      ],
    );
  }
}
