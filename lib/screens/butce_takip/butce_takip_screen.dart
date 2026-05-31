import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/turkce_format.dart';
import '../../models/butce_limit_model.dart';
import '../../providers/butce_takip_provider.dart';

/// Bütçe Ödenek Takip ve Konsolide Dashboard ekranı (Modül 9).
class ButceTakipScreen extends StatefulWidget {
  const ButceTakipScreen({super.key, this.embedded = false});

  /// Dashboard içine embed edildiğinde AppBar gösterilmez.
  final bool embedded;

  @override
  State<ButceTakipScreen> createState() => _ButceTakipScreenState();
}

class _ButceTakipScreenState extends State<ButceTakipScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ButceTakipProvider>().limitleriYukle();
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
    final provider = context.watch<ButceTakipProvider>();

    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text('Bütçe Ödenek Takibi'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _yeniLimitDialog(context),
                  tooltip: 'Yeni Bütçe Limiti',
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Konsolide', icon: Icon(Icons.dashboard)),
                  Tab(text: 'Birim Detay', icon: Icon(Icons.account_balance)),
                  Tab(text: 'YK Talepleri', icon: Icon(Icons.approval)),
                ],
              ),
            ),
      body: Column(
        children: [
          if (widget.embedded) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Text('Bütçe Ödenek Takibi',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _yeniLimitDialog(context),
                    tooltip: 'Yeni Bütçe Limiti',
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Konsolide', icon: Icon(Icons.dashboard)),
                Tab(text: 'Birim Detay', icon: Icon(Icons.account_balance)),
                Tab(text: 'YK Talepleri', icon: Icon(Icons.approval)),
              ],
            ),
          ],
          // Yıl seçici
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('Yıl: '),
                DropdownButton<int>(
                  value: provider.seciliYil,
                  items: List.generate(5, (i) => DateTime.now().year - 2 + i)
                      .map((yil) => DropdownMenuItem(
                            value: yil,
                            child: Text('$yil'),
                          ))
                      .toList(),
                  onChanged: (yil) {
                    if (yil != null) provider.yilDegistir(yil);
                  },
                ),
                const Spacer(),
                if (provider.limitAsanBirimSayisi > 0)
                  Chip(
                    avatar: const Icon(Icons.warning, size: 16, color: Colors.white),
                    label: Text(
                      '${provider.limitAsanBirimSayisi} limit aşımı',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    backgroundColor: Colors.red,
                  ),
              ],
            ),
          ),
          // Hata/Başarı mesajları
          if (provider.hataMesaji != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                provider.hataMesaji!,
                style: TextStyle(color: Colors.red.shade800),
              ),
            ),
          if (provider.basariMesaji != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                provider.basariMesaji!,
                style: TextStyle(color: Colors.green.shade800),
              ),
            ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildKonsolideTab(provider, theme),
                      _buildBirimDetayTab(provider, theme),
                      _buildTaleplerTab(provider, theme),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // KONSOLİDE DASHBOARD
  // ─────────────────────────────────────────────────────────────

  Widget _buildKonsolideTab(ButceTakipProvider provider, ThemeData theme) {
    if (provider.limitler.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet,
                size: 64, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text('Bütçe limiti tanımlanmamış.',
                style: theme.textTheme.bodyLarge),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => _yeniLimitDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('İlk Limiti Tanımla'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Özet kartları
          Row(
            children: [
              _buildOzetKart(
                'Toplam Ödenek',
                TurkceFormat.para(provider.toplamOdenek),
                Icons.account_balance_wallet,
                Colors.blue,
                theme,
              ),
              const SizedBox(width: 12),
              _buildOzetKart(
                'Toplam Harcama',
                TurkceFormat.para(provider.toplamHarcama),
                Icons.shopping_cart,
                Colors.orange,
                theme,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildOzetKart(
                'Kullanım Oranı',
                '%${(provider.genelKullanimOrani * 100).toStringAsFixed(1)}',
                Icons.pie_chart,
                provider.genelKullanimOrani > 0.9
                    ? Colors.red
                    : provider.genelKullanimOrani > 0.7
                        ? Colors.orange
                        : Colors.green,
                theme,
              ),
              const SizedBox(width: 12),
              _buildOzetKart(
                'Birim Sayısı',
                '${provider.limitler.length}',
                Icons.business,
                Colors.purple,
                theme,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Birim Bazlı Ödenek Durumu',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          ...provider.limitler.map((limit) => _buildBirimOzetKart(limit, theme)),
        ],
      ),
    );
  }

  Widget _buildOzetKart(
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
              Icon(icon, size: 28, color: renk),
              const SizedBox(height: 8),
              Text(
                deger,
                style: theme.textTheme.titleMedium?.copyWith(
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

  Widget _buildBirimOzetKart(ButceLimitModel limit, ThemeData theme) {
    final oran = limit.kullanimOrani;
    final renkKodu = oran > 1.0
        ? Colors.red
        : oran > 0.9
            ? Colors.orange
            : oran > 0.7
                ? Colors.amber
                : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: renkKodu.withValues(alpha: 0.2),
          child: Icon(Icons.business, color: renkKodu),
        ),
        title: Text(limit.birimAd),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: oran.clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade200,
              color: renkKodu,
            ),
            const SizedBox(height: 4),
            Text(
              '${TurkceFormat.para(limit.toplamHarcama)} / ${TurkceFormat.para(limit.toplamOdenek)}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '%${(oran * 100).toStringAsFixed(0)}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: renkKodu,
              ),
            ),
            if (limit.limitAsimi)
              const Icon(Icons.warning, size: 16, color: Colors.red),
          ],
        ),
        onTap: () {
          provider.limitSec(limit);
          _tabController.animateTo(1);
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // BİRİM DETAY
  // ─────────────────────────────────────────────────────────────

  Widget _buildBirimDetayTab(ButceTakipProvider provider, ThemeData theme) {
    final secili = provider.seciliLimit;
    if (secili == null) {
      if (provider.limitler.isEmpty) {
        return const Center(child: Text('Bütçe limiti bulunamadı.'));
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app, size: 64, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text('Konsolide sekmesinden bir birim seçin.',
                style: theme.textTheme.bodyLarge),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(secili.birimAd, style: theme.textTheme.titleLarge),
                  Text('${secili.yil} Yılı Bütçe Detayı',
                      style: theme.textTheme.bodySmall),
                  const Divider(),
                  _buildDetaySatir(
                      'Toplam Ödenek', secili.toplamOdenek, theme),
                  _buildDetaySatir(
                      'Toplam Harcama', secili.toplamHarcama, theme),
                  _buildDetaySatir('Kalan Ödenek',
                      secili.toplamOdenek - secili.toplamHarcama, theme),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Kalem Bazlı Detay', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ...secili.kalemler.map((kalem) => _buildKalemKart(kalem, theme)),
        ],
      ),
    );
  }

  Widget _buildDetaySatir(String etiket, double tutar, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiket, style: theme.textTheme.bodyMedium),
          Text(
            TurkceFormat.para(tutar),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKalemKart(ButceKalemi kalem, ThemeData theme) {
    final oran = kalem.kullanimOrani;
    final renkKodu = kalem.limitAsildiMi
        ? Colors.red
        : oran > 0.9
            ? Colors.orange
            : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: kalem.blokeDurum ? Colors.red.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: renkKodu.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    kalem.kod,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: renkKodu,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(kalem.ad, style: theme.textTheme.bodySmall),
                ),
                if (kalem.limitAsildiMi)
                  const Chip(
                    label: Text('LİMİT AŞIMI',
                        style: TextStyle(fontSize: 10, color: Colors.white)),
                    backgroundColor: Colors.red,
                    visualDensity: VisualDensity.compact,
                  ),
                if (kalem.blokeDurum)
                  const Chip(
                    label: Text('BLOKE',
                        style: TextStyle(fontSize: 10, color: Colors.white)),
                    backgroundColor: Colors.orange,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: oran.clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade200,
              color: renkKodu,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Harcama: ${TurkceFormat.para(kalem.harcamaTutar)}',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  'Ödenek: ${TurkceFormat.para(kalem.odenekTutar)}',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  '%${(oran * 100).toStringAsFixed(1)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: renkKodu,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // YK ONAYI TALEPLERİ
  // ─────────────────────────────────────────────────────────────

  Widget _buildTaleplerTab(ButceTakipProvider provider, ThemeData theme) {
    if (provider.bekleyenTalepler.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text('Bekleyen harcama talebi yok.',
                style: theme.textTheme.bodyLarge),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.bekleyenTalepler.length,
      itemBuilder: (context, index) {
        final talep = provider.bekleyenTalepler[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: Colors.orange.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(talep.birimAd,
                              style: theme.textTheme.titleMedium),
                          Text('Kalem: ${talep.kalemKod}',
                              style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Text(
                      TurkceFormat.para(talep.tutar),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(talep.aciklama, style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  'Durum: ${talep.durum.displayName}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => provider.talepReddet(talep.id),
                      icon:
                          const Icon(Icons.close, size: 16, color: Colors.red),
                      label: const Text('Reddet',
                          style: TextStyle(color: Colors.red)),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () => provider.talepOnayla(talep.id),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Onayla'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // DİALOGLAR
  // ─────────────────────────────────────────────────────────────

  void _yeniLimitDialog(BuildContext context) {
    final birimAdController = TextEditingController();
    final birimIdController = TextEditingController();

    // Varsayılan bütçe kalemleri
    final varsayilanKalemler = [
      const ButceKalemi(
          kod: '03.02', ad: 'Tüketime Yönelik Mal ve Malzeme Alımları', odenekTutar: 0),
      const ButceKalemi(
          kod: '03.05', ad: 'Hizmet Alımları', odenekTutar: 0),
      const ButceKalemi(
          kod: '03.07', ad: 'Menkul Mal Alımları', odenekTutar: 0),
      const ButceKalemi(
          kod: '06.01', ad: 'Mamul Mal Alımları', odenekTutar: 0),
      const ButceKalemi(
          kod: '06.05', ad: 'Gayrimenkul Sermaye Üretim Giderleri', odenekTutar: 0),
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni Bütçe Limiti'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: birimIdController,
                decoration: const InputDecoration(labelText: 'Birim ID'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: birimAdController,
                decoration: const InputDecoration(labelText: 'Birim Adı'),
              ),
              const SizedBox(height: 8),
              Text(
                'Varsayılan kalemler (03.02, 03.05, 03.07, 06.01, 06.05) '
                'ile oluşturulacak. Ödenek tutarlarını daha sonra düzenleyebilirsiniz.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              final provider = context.read<ButceTakipProvider>();
              final model = ButceLimitModel(
                id: '',
                birimId: birimIdController.text,
                birimAd: birimAdController.text,
                yil: provider.seciliYil,
                kalemler: varsayilanKalemler,
              );
              provider.limitOlustur(model);
              Navigator.pop(ctx);
            },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }
}
