import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/turkce_format.dart';
import '../../models/taksit_model.dart';
import '../../providers/taksit_provider.dart';

/// Taksit onay akışı ekranı.
///
/// Danışmanlığa ait taksitleri listeler, durum geçişlerini yönetir
/// ve belge üretimini tetikler.
class TaksitOnayScreen extends StatefulWidget {
  const TaksitOnayScreen({
    super.key,
    required this.danismanlikId,
  });

  final String danismanlikId;

  @override
  State<TaksitOnayScreen> createState() => _TaksitOnayScreenState();
}

class _TaksitOnayScreenState extends State<TaksitOnayScreen> {
  TaksitDurum? _filtre;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaksitProvider>().taksitleriYukle(widget.danismanlikId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<TaksitProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Taksit Onay Akışı'),
        actions: [
          if (provider.isProcessing)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // İstatistik kartları
          if (!provider.isLoading) _buildIstatistikBar(provider, theme),

          // Filtre çipleri
          _buildFiltreBar(theme),

          // Hata/Başarı mesajları
          if (provider.hataMesaji != null)
            _buildMesajBanner(
              provider.hataMesaji!,
              Colors.red,
              Icons.error_outline,
            ),
          if (provider.basariMesaji != null)
            _buildMesajBanner(
              provider.basariMesaji!,
              Colors.green,
              Icons.check_circle_outline,
            ),

          // Taksit listesi
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildTaksitListesi(provider, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildIstatistikBar(TaksitProvider provider, ThemeData theme) {
    final stat = provider.istatistik;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStatCard('Toplam', stat.toplam.toString(), theme.colorScheme.primary, theme),
          const SizedBox(width: 8),
          _buildStatCard('Taslak', stat.taslak.toString(), Colors.grey, theme),
          const SizedBox(width: 8),
          _buildStatCard('Bekleyen', stat.onayBekleyen.toString(), Colors.orange, theme),
          const SizedBox(width: 8),
          _buildStatCard('Onaylı', stat.onaylanan.toString(), Colors.green, theme),
          const SizedBox(width: 8),
          _buildStatCard('Ödenen', stat.odenen.toString(), Colors.blue, theme),
        ],
      ),
    );
  }

  Widget _buildStatCard(String etiket, String deger, Color renk, ThemeData theme) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Text(
                deger,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: renk,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                etiket,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiltreBar(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Tümü'),
            selected: _filtre == null,
            onSelected: (_) => setState(() => _filtre = null),
          ),
          const SizedBox(width: 8),
          ...TaksitDurum.values.map((durum) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(durum.displayName),
                  selected: _filtre == durum,
                  onSelected: (_) => setState(() => _filtre = durum),
                  backgroundColor: _durumRenk(durum).withValues(alpha: 0.1),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildTaksitListesi(TaksitProvider provider, ThemeData theme) {
    final taksitler = provider.taksitFiltrele(_filtre);

    if (taksitler.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text(
              'Taksit bulunamadı.',
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: taksitler.length,
      itemBuilder: (context, index) {
        return _buildTaksitKart(taksitler[index], provider, theme);
      },
    );
  }

  Widget _buildTaksitKart(
    TaksitModel taksit,
    TaksitProvider provider,
    ThemeData theme,
  ) {
    final aksiyonlar = provider.izinVerilenAksiyonlar(taksit);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık satırı
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _durumRenk(taksit.durum),
                  radius: 16,
                  child: Text(
                    '${taksit.ayNo}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${taksit.ayNo}. Ay Taksiti',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        TurkceFormat.para(taksit.brutTutar),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildDurumChip(taksit.durum, theme),
              ],
            ),

            // Evrak bilgileri (varsa)
            if (taksit.birimEvrakTarihi != null) ...[
              const SizedBox(height: 8),
              const Divider(),
              Text(
                'Evrak: ${taksit.birimEvrakTarihi} - ${taksit.birimEvrakSayisi ?? ""}',
                style: theme.textTheme.bodySmall,
              ),
            ],

            // Hesaplama sonuçları (varsa)
            if (taksit.ekOdemeKatsayisi != null) ...[
              const SizedBox(height: 8),
              const Divider(),
              Row(
                children: [
                  _buildBilgiChip('Katsayı: ${TurkceFormat.katsayi(taksit.ekOdemeKatsayisi!)}', theme),
                  const SizedBox(width: 8),
                  if (taksit.dagitilabilirTutar != null)
                    _buildBilgiChip('Dağıtılabilir: ${TurkceFormat.para(taksit.dagitilabilirTutar!)}', theme),
                ],
              ),
            ],

            // Aksiyon butonları
            if (aksiyonlar.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: aksiyonlar.map((aksiyon) {
                  return _buildAksiyonButon(aksiyon, taksit, provider);
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAksiyonButon(
    TaksitAksiyon aksiyon,
    TaksitModel taksit,
    TaksitProvider provider,
  ) {
    switch (aksiyon.tipi) {
      case TaksitAksiyonTipi.ilerlet:
        return FilledButton.icon(
          onPressed: provider.isProcessing
              ? null
              : () => provider.durumIlerlet(taksit),
          icon: const Icon(Icons.arrow_forward, size: 16),
          label: Text(aksiyon.etiket),
        );
      case TaksitAksiyonTipi.geriAl:
        return OutlinedButton.icon(
          onPressed: provider.isProcessing
              ? null
              : () => provider.durumGeriAl(taksit),
          icon: const Icon(Icons.arrow_back, size: 16),
          label: Text(aksiyon.etiket),
        );
      case TaksitAksiyonTipi.belgeUret:
        return FilledButton.tonalIcon(
          onPressed: provider.isProcessing
              ? null
              : () => _belgeUretDialog(taksit, provider),
          icon: const Icon(Icons.description, size: 16),
          label: Text(aksiyon.etiket),
        );
    }
  }

  Future<void> _belgeUretDialog(
    TaksitModel taksit,
    TaksitProvider provider,
  ) async {
    // Null guard: sonDagitimSonucu state'i olmayabilir
    final dagitimSonucu = provider.sonDagitimSonucu;
    if (dagitimSonucu == null || dagitimSonucu.dagitimlar.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dağıtım verisi bulunamadı. Önce taksiti onaylayın.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Karar belgesi oluşturuluyor...'),
        duration: Duration(seconds: 2),
      ),
    );

    final dagitimlar = dagitimSonucu.dagitimlar;
    final belge = await provider.kararBelgesiUret(taksit, dagitimlar);
    if (!mounted) return;
    if (belge != null && belge.uretimHazir) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Karar belgesi başarıyla üretildi.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _buildDurumChip(TaksitDurum durum, ThemeData theme) {
    return Chip(
      label: Text(
        durum.displayName,
        style: TextStyle(
          color: _durumRenk(durum),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: _durumRenk(durum).withValues(alpha: 0.1),
      side: BorderSide(color: _durumRenk(durum).withValues(alpha: 0.3)),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildBilgiChip(String text, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: theme.textTheme.bodySmall),
    );
  }

  Widget _buildMesajBanner(String mesaj, Color renk, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: renk.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: renk, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mesaj,
              style: TextStyle(color: renk, fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () =>
                context.read<TaksitProvider>().hatayiTemizle(),
          ),
        ],
      ),
    );
  }

  Color _durumRenk(TaksitDurum durum) {
    switch (durum) {
      case TaksitDurum.taslak:
        return Colors.grey;
      case TaksitDurum.mudurOnayinda:
        return Colors.orange;
      case TaksitDurum.merkezOnayinda:
        return Colors.deepOrange;
      case TaksitDurum.ykGundeminde:
        return Colors.purple;
      case TaksitDurum.onaylandi:
        return Colors.green;
      case TaksitDurum.odendi:
        return Colors.blue;
      case TaksitDurum.gecikti:
        return Colors.red;
    }
  }
}
