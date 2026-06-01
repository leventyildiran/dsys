import 'package:flutter/material.dart';

import '../gundem/gundem_screen.dart';
import 'yk_karar_merkezi_screen.dart';

/// Yürütme Kurulu Yönetim ekranı.
///
/// Gündem ve Karar Merkezi sayfalarını sekmeli (tab) yapıyla
/// tek bir dashboard altında birleştirir.
class YkYonetimScreen extends StatelessWidget {
  const YkYonetimScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              tabs: const [
                Tab(icon: Icon(Icons.event_note_rounded), text: 'Toplantı & Gündem'),
                Tab(icon: Icon(Icons.gavel_rounded), text: 'Karar Merkezi'),
              ],
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
              indicatorColor: Theme.of(context).colorScheme.primary,
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                GundemScreen(embedded: true),
                YkKararMerkeziScreen(embedded: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
