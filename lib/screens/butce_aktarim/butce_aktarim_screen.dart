import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/turkce_format.dart';
import '../../models/butce_aktarim_model.dart';
import '../../providers/butce_aktarim_provider.dart';

/// Bütçe Aktarımları Modülü ana ekranı.
class ButceAktarimScreen extends StatefulWidget {
  const ButceAktarimScreen({super.key});

  @override
  State<ButceAktarimScreen> createState() => _ButceAktarimScreenState();
}

class _ButceAktarimScreenState extends State<ButceAktarimScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ButceAktarimProvider>().aktarimlariYukle();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<ButceAktarimProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bütçe Aktarımları'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _yeniAktarimDialog(context),
            tooltip: 'Yeni Aktarım',
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.aktarimlar.isEmpty
              ? _buildBosEkran(theme)
              : _buildListe(provider, theme),
    );
  }

  Widget _buildBosEkran(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.swap_horiz, size: 64, color: theme.disabledColor),
          const SizedBox(height: 16),
          Text('Bütçe aktarımı bulunamadı.', style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildListe(ButceAktarimProvider provider, ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.aktarimlar.length,
      itemBuilder: (context, index) {
        final aktarim = provider.aktarimlar[index];
        return _buildAktarimKart(aktarim, provider, theme);
      },
    );
  }

  Widget _buildAktarimKart(
    ButceAktarimModel aktarim,
    ButceAktarimProvider provider,
    ThemeData theme,
  ) {
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
                        aktarim.birimAd,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        'Karar: ${aktarim.kararNo} - ${aktarim.kararTarihi}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    aktarim.durum.displayName,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                _buildTutarBilgi(
                    'Artırılan', aktarim.toplamArtirilan, Colors.green, theme),
                const SizedBox(width: 16),
                _buildTutarBilgi(
                    'Eksiltilen', aktarim.toplamEksiltilen, Colors.red, theme),
              ],
            ),
            if (aktarim.gerekce != null && aktarim.gerekce!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Gerekçe: ${aktarim.gerekce}',
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '${aktarim.satirlar.length} satır',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutarBilgi(
      String etiket, double tutar, Color renk, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiket, style: theme.textTheme.bodySmall),
        Text(
          TurkceFormat.para(tutar),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: renk,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _yeniAktarimDialog(BuildContext context) {
    final birimAdController = TextEditingController();
    final kararNoController = TextEditingController();
    final kararTarihiController = TextEditingController();
    final gerekceController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni Bütçe Aktarımı'),
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
                controller: kararNoController,
                decoration: const InputDecoration(labelText: 'Karar No'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: kararTarihiController,
                decoration:
                    const InputDecoration(labelText: 'Karar Tarihi (dd.MM.yyyy)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: gerekceController,
                decoration: const InputDecoration(labelText: 'Gerekçe'),
                maxLines: 3,
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
              final model = ButceAktarimModel(
                id: '',
                birimId: '',
                birimAd: birimAdController.text,
                kararTarihi: kararTarihiController.text,
                kararNo: kararNoController.text,
                satirlar: [],
                gerekce: gerekceController.text,
              );
              context.read<ButceAktarimProvider>().aktarimOlustur(model);
              Navigator.pop(ctx);
            },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }
}
