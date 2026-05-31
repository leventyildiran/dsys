import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/turkce_format.dart';
import '../../models/dis_hekimligi_model.dart';
import '../../providers/dis_hekimligi_provider.dart';

/// Diş Hekimliği Katkı Payı Dağıtım ekranı.
class DisHekimligiScreen extends StatefulWidget {
  const DisHekimligiScreen({super.key});

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
      appBar: AppBar(
        title: const Text('Diş Hekimliği Katkı Payı'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _yeniDagitimDialog(context),
            tooltip: 'Yeni Dağıtım',
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.dagitimlar.isEmpty
              ? _buildBosEkran(theme)
              : _buildListe(provider, theme),
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

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
                decoration:
                    const InputDecoration(labelText: 'Toplam Brüt Gelir'),
                keyboardType: TextInputType.number,
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
              final brutGelir = double.tryParse(
                      brutGelirController.text.replaceAll(',', '.')) ??
                  0;
              final model = DisHekimligiDagitimModel(
                id: '',
                birimId: '',
                birimAd: birimAdController.text,
                donem: donemController.text,
                toplamBrutGelir: brutGelir,
                akademikIdariTutar: 0,
                yoneticiTutar: 0,
                mesaiDisiTutar: 0,
              );
              context.read<DisHekimligiProvider>().dagitimOlustur(model);
              Navigator.pop(ctx);
            },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }
}
