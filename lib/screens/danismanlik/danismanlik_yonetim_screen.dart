import 'package:flutter/material.dart';

import 'danismanlik_dashboard_tab.dart';
import 'danismanlik_form_tab.dart';
import 'danismanlik_liste_tab.dart';

/// Danışmanlık Yönetim Ekranı.
/// Sekmeli (TabBar) yapı ile Dashboard, Liste ve Form ekranlarını tek çatıda toplar.
class DanismanlikYonetimScreen extends StatelessWidget {
  const DanismanlikYonetimScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Danışmanlık Yönetimi'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Genel Bakış', icon: Icon(Icons.dashboard_outlined)),
              Tab(text: 'Proje Listesi', icon: Icon(Icons.list_alt_outlined)),
              Tab(text: 'Yeni Sözleşme Tanımla', icon: Icon(Icons.post_add_outlined)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            DanismanlikDashboardTab(),
            DanismanlikListeTab(),
            DanismanlikFormTab(),
          ],
        ),
      ),
    );
  }
}
