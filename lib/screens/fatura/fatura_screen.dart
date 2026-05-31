import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/turkce_format.dart';
import '../../models/fatura_model.dart';
import '../../providers/fatura_provider.dart';

/// Otomatik Fatura Basım / PDF Önizleme ekranı.
class FaturaScreen extends StatefulWidget {
  const FaturaScreen({super.key, this.embedded = false});

  /// Dashboard içine embed edildiğinde AppBar gösterilmez.
  final bool embedded;

  @override
  State<FaturaScreen> createState() => _FaturaScreenState();
}

class _FaturaScreenState extends State<FaturaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _metinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FaturaProvider>().faturalariYukle();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _metinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<FaturaProvider>();

    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text('Fatura Basım'),
              bottom: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    text: 'Kuyruk (${provider.kuyrukSayisi})',
                    icon: const Icon(Icons.queue),
                  ),
                  const Tab(text: 'Tümü', icon: Icon(Icons.list)),
                  const Tab(text: 'Toplu Yükle', icon: Icon(Icons.upload_file)),
                ],
              ),
            ),
      body: Column(
        children: [
          if (widget.embedded) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text('Fatura Basım',
                  style: Theme.of(context).textTheme.headlineSmall),
            ),
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  text: 'Kuyruk (${provider.kuyrukSayisi})',
                  icon: const Icon(Icons.queue),
                ),
                const Tab(text: 'Tümü', icon: Icon(Icons.list)),
                const Tab(text: 'Toplu Yükle', icon: Icon(Icons.upload_file)),
              ],
            ),
          ],
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildKuyrukTab(provider, theme),
                _buildTumFaturalarTab(provider, theme),
                _buildTopluYukleTab(provider, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Fatura kuyruğu — bekleyen faturaları sırasıyla işler.
  Widget _buildKuyrukTab(FaturaProvider provider, ThemeData theme) {
    if (provider.kuyruk.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text('Bekleyen fatura yok.', style: theme.textTheme.bodyLarge),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.kuyruk.length,
      itemBuilder: (context, index) {
        final fatura = provider.kuyruk[index];
        return _buildFaturaKart(fatura, provider, theme, isKuyruk: true);
      },
    );
  }

  /// Tüm faturalar listesi.
  Widget _buildTumFaturalarTab(FaturaProvider provider, ThemeData theme) {
    if (provider.faturalar.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text('Fatura bulunamadı.', style: theme.textTheme.bodyLarge),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.faturalar.length,
      itemBuilder: (context, index) {
        final fatura = provider.faturalar[index];
        return _buildFaturaKart(fatura, provider, theme);
      },
    );
  }

  /// Toplu metin yükleme ve ayrıştırma.
  Widget _buildTopluYukleTab(FaturaProvider provider, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Fatura Metin Ayrıştırma',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Birimlerden gelen fatura taleplerini yapıştırın. '
            'Sistem metni otomatik olarak ayrıştıracaktır.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _metinController,
            maxLines: 10,
            decoration: InputDecoration(
              hintText: 'Firma: ABC Ltd.\nHizmet: Tahlil\nTutar: 1.500,00\n\n'
                  'Firma: XYZ A.Ş.\nHizmet: Analiz\nTutar: 2.300,00',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    provider.metinAyristir(_metinController.text);
                  },
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text('Ayrıştır'),
                ),
              ),
              const SizedBox(width: 8),
              if (provider.parseSonuclari.isNotEmpty)
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      provider.topluFaturaOlustur(
                        birimId: '',
                        birimAd: 'UBATAM',
                      );
                      _metinController.clear();
                    },
                    icon: const Icon(Icons.save),
                    label: Text(
                        '${provider.parseSonuclari.length} Fatura Oluştur'),
                  ),
                ),
            ],
          ),
          if (provider.parseSonuclari.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            Text(
              'Ayrıştırma Sonuçları (${provider.parseSonuclari.length} fatura)',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ...provider.parseSonuclari.map((sonuc) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(sonuc.firmaUnvan),
                    subtitle: Text(sonuc.hizmetDetay),
                    trailing: Text(
                      TurkceFormat.para(sonuc.tutar),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildFaturaKart(
    FaturaModel fatura,
    FaturaProvider provider,
    ThemeData theme, {
    bool isKuyruk = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fatura.firmaUnvan,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        fatura.hizmetDetay,
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      TurkceFormat.para(fatura.toplamTutar),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Chip(
                      label: Text(
                        fatura.durum.displayName,
                        style: const TextStyle(fontSize: 11),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
            if (isKuyruk) ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () =>
                        provider.faturaSecme(fatura),
                    icon: const Icon(Icons.preview, size: 16),
                    label: const Text('Önizle'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () =>
                        provider.basildiIsaretle(fatura.id),
                    icon: const Icon(Icons.print, size: 16),
                    label: const Text('Yazdır'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
