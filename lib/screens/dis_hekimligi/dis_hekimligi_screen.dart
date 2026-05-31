import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/turkce_format.dart';
import '../../models/dis_hekimligi_model.dart';
import '../../providers/dis_hekimligi_provider.dart';

/// Diş Hekimliği Katkı Payı Dağıtım ekranı.
class DisHekimligiScreen extends StatefulWidget {
  const DisHekimligiScreen({super.key, this.embedded = false});

  /// Dashboard içine embed edildiğinde AppBar gösterilmez.
  final bool embedded;

  @override
  State<DisHekimligiScreen> createState() => _DisHekimligiScreenState();
}

class _DisHekimligiScreenState extends State<DisHekimligiScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DisHekimligiProvider>().dagitimlariYukle();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<DisHekimligiProvider>();

    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text('Diş Hekimliği Katkı Payı'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _yeniDagitimDialog(context),
                  tooltip: 'Yeni Dağıtım',
                ),
              ],
            ),
      body: Column(
        children: [
          if (widget.embedded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Text('Diş Hekimliği Katkı Payı',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _yeniDagitimDialog(context),
                    tooltip: 'Yeni Dağıtım',
                  ),
                ],
              ),
            ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.dagitimlar.isEmpty
                    ? _buildBosEkran(theme)
                    : _buildListe(provider, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildBosEkran(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medical_services, size: 64, color: theme.disabledColor),
          const SizedBox(height: 16),
          Text('Dağıtım kaydı bulunamadı.', style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildListe(DisHekimligiProvider provider, ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.dagitimlar.length,
      itemBuilder: (context, index) {
        final dagitim = provider.dagitimlar[index];
        return _buildDagitimKart(dagitim, theme);
      },
    );
  }

  Widget _buildDagitimKart(
      DisHekimligiDagitimModel dagitim, ThemeData theme) {
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
                      Text(dagitim.birimAd,
                          style: theme.textTheme.titleMedium),
                      Text(dagitim.donem, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    dagitim.durum.displayName,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const Divider(),
            // Dağıtım kırılımı tablosu
            _buildDagitimTablosu(dagitim, theme),
            const SizedBox(height: 8),
            Text(
              '${dagitim.personelListesi.length} personel',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDagitimTablosu(
      DisHekimligiDagitimModel dagitim, ThemeData theme) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(2),
      },
      children: [
        _buildTabloSatir(
            'Toplam Brüt Gelir', dagitim.toplamBrutGelir, theme),
        _buildTabloSatir(
            'Akademik/İdari Personel', dagitim.akademikIdariTutar, theme),
        _buildTabloSatir('Yönetici Payı', dagitim.yoneticiTutar, theme),
        _buildTabloSatir(
            'Mesai Dışı Tedavi', dagitim.mesaiDisiTutar, theme),
      ],
    );
  }

  TableRow _buildTabloSatir(String etiket, double tutar, ThemeData theme) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(etiket, style: theme.textTheme.bodySmall),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            TurkceFormat.para(tutar),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  void _yeniDagitimDialog(BuildContext context) {
    final birimAdController = TextEditingController();
    final donemController = TextEditingController();
    final brutGelirController = TextEditingController();

    // Varsayılan oranlar
    double akademikOran = 0.70;
    double yoneticiOran = 0.20;
    double mesaiDisiOran = 0.10;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final brutGelir = double.tryParse(
                  brutGelirController.text.replaceAll(',', '.')) ??
              0;
          final akademikTutar = brutGelir * akademikOran;
          final yoneticiTutar = brutGelir * yoneticiOran;
          final mesaiDisiTutar = brutGelir * mesaiDisiOran;

          return AlertDialog(
            title: const Text('Yeni Diş Hekimliği Dağıtımı'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: birimAdController,
                    decoration: const InputDecoration(labelText: 'Birim Adı'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: donemController,
                    decoration: const InputDecoration(labelText: 'Dönem'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: brutGelirController,
                    decoration: const InputDecoration(
                      labelText: 'Toplam Brüt Gelir',
                      helperText: 'Otomatik dağıtım hesaplanacaktır',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 16),
                  // Oran ayarlama
                  Text('Dağıtım Oranları',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  _buildOranSlider(
                    'Akademik/İdari (%${(akademikOran * 100).toInt()})',
                    akademikOran,
                    (v) => setDialogState(() {
                      akademikOran = v;
                      // Diğer oranları yeniden dengelemek için
                      final kalan = 1.0 - akademikOran;
                      yoneticiOran = kalan * 0.667; // 2/3
                      mesaiDisiOran = kalan * 0.333; // 1/3
                    }),
                  ),
                  _buildOranSlider(
                    'Yönetici (%${(yoneticiOran * 100).toInt()})',
                    yoneticiOran,
                    (v) => setDialogState(() {
                      yoneticiOran = v;
                      mesaiDisiOran = (1.0 - akademikOran - yoneticiOran)
                          .clamp(0.0, 1.0);
                    }),
                  ),
                  _buildOranSlider(
                    'Mesai Dışı (%${(mesaiDisiOran * 100).toInt()})',
                    mesaiDisiOran,
                    (v) => setDialogState(() {
                      mesaiDisiOran = v;
                      yoneticiOran = (1.0 - akademikOran - mesaiDisiOran)
                          .clamp(0.0, 1.0);
                    }),
                  ),
                  if (brutGelir > 0) ...[
                    const Divider(),
                    Text('Hesaplanan Dağıtım',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    _buildHesapSatir('Akademik/İdari',
                        TurkceFormat.para(akademikTutar)),
                    _buildHesapSatir(
                        'Yönetici Payı', TurkceFormat.para(yoneticiTutar)),
                    _buildHesapSatir(
                        'Mesai Dışı', TurkceFormat.para(mesaiDisiTutar)),
                  ],
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
                  final model = DisHekimligiDagitimModel(
                    id: '',
                    birimId: '',
                    birimAd: birimAdController.text,
                    donem: donemController.text,
                    toplamBrutGelir: brutGelir,
                    akademikIdariTutar: akademikTutar,
                    yoneticiTutar: yoneticiTutar,
                    mesaiDisiTutar: mesaiDisiTutar,
                  );
                  context.read<DisHekimligiProvider>().dagitimOlustur(model);
                  Navigator.pop(ctx);
                },
                child: const Text('Oluştur'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOranSlider(
      String etiket, double deger, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiket, style: const TextStyle(fontSize: 12)),
        Slider(
          value: deger.clamp(0.0, 1.0),
          min: 0,
          max: 1.0,
          divisions: 20,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildHesapSatir(String etiket, String deger) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiket, style: const TextStyle(fontSize: 13)),
          Text(deger,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
