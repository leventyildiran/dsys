import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/turkce_format.dart';
import '../../providers/raporlama_provider.dart';
import '../../services/raporlama_service.dart';

/// Detaylı Arama, Raporlama ve Arşivleme ekranı.
class RaporlamaScreen extends StatefulWidget {
  const RaporlamaScreen({super.key});

  @override
  State<RaporlamaScreen> createState() => _RaporlamaScreenState();
}

class _RaporlamaScreenState extends State<RaporlamaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RaporlamaProvider>();
      provider.genelIstatistikleriYukle();
      provider.birimRaporuYukle();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<RaporlamaProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Raporlama ve Analiz'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Genel', icon: Icon(Icons.dashboard)),
            Tab(text: 'Birim', icon: Icon(Icons.business)),
            Tab(text: 'Personel', icon: Icon(Icons.people)),
          ],
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGenelTab(provider, theme),
                _buildBirimTab(provider, theme),
                _buildPersonelTab(provider, theme),
              ],
            ),
    );
  }

  Widget _buildGenelTab(RaporlamaProvider provider, ThemeData theme) {
    final istat = provider.genelIstatistik;
    if (istat == null) {
      return const Center(child: Text('İstatistikler yükleniyor...'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              _buildIstatistikKart(
                'Toplam Danışmanlık',
                istat.toplamDanismanlik.toString(),
                Icons.handshake,
                theme.colorScheme.primary,
                theme,
              ),
              const SizedBox(width: 12),
              _buildIstatistikKart(
                'Aktif Danışmanlık',
                istat.aktifDanismanlik.toString(),
                Icons.play_circle,
                Colors.green,
                theme,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildIstatistikKart(
                'Toplam Personel',
                istat.toplamPersonel.toString(),
                Icons.people,
                Colors.blue,
                theme,
              ),
              const SizedBox(width: 12),
              _buildIstatistikKart(
                'Toplam Firma',
                istat.toplamFirma.toString(),
                Icons.business,
                Colors.orange,
                theme,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.monetization_on,
                      size: 48, color: Colors.green),
                  const SizedBox(height: 8),
                  Text('Toplam Gelir', style: theme.textTheme.bodySmall),
                  Text(
                    TurkceFormat.para(istat.toplamGelir),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIstatistikKart(
    String etiket,
    String deger,
    IconData icon,
    Color renk,
    ThemeData theme,
  ) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: renk),
              const SizedBox(height: 8),
              Text(
                deger,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: renk,
                ),
              ),
              Text(etiket, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBirimTab(RaporlamaProvider provider, ThemeData theme) {
    if (provider.birimRaporu.isEmpty) {
      return const Center(child: Text('Birim verisi bulunamadı.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.birimRaporu.length,
      itemBuilder: (context, index) {
        final rapor = provider.birimRaporu[index];
        return _buildBirimKart(rapor, theme);
      },
    );
  }

  Widget _buildBirimKart(BirimGelirRapor rapor, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(rapor.birimAd.isNotEmpty ? rapor.birimAd[0] : '?'),
        ),
        title: Text(rapor.birimAd),
        subtitle: Text('${rapor.danismanlikSayisi} danışmanlık'),
        trailing: Text(
          TurkceFormat.para(rapor.toplamGelir),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ),
    );
  }

  Widget _buildPersonelTab(RaporlamaProvider provider, ThemeData theme) {
    if (provider.personelRaporu.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Personel raporu yükle:'),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => provider.personelRaporuYukle('2026'),
              child: const Text('2026 Raporu'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.personelRaporu.length,
      itemBuilder: (context, index) {
        final rapor = provider.personelRaporu[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(rapor.adSoyad),
            subtitle: Text(rapor.unvan),
            trailing: Text(
              TurkceFormat.para(rapor.yillikToplamGelir),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
