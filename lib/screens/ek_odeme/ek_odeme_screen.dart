import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/turkce_format.dart';
import '../../models/ek_odeme_model.dart';
import '../../providers/ek_odeme_provider.dart';

/// Dönemsel Ek Ödeme Dağıtımı ana ekranı.
class EkOdemeScreen extends StatefulWidget {
  const EkOdemeScreen({super.key, this.embedded = false});

  /// Dashboard içine embed edildiğinde AppBar gösterilmez.
  final bool embedded;

  @override
  State<EkOdemeScreen> createState() => _EkOdemeScreenState();
}

class _EkOdemeScreenState extends State<EkOdemeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EkOdemeProvider>().ekOdemeleriYukle();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<EkOdemeProvider>();

    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text('Dönemsel Ek Ödeme Dağıtımı'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _yeniEkOdemeDialog(context),
                  tooltip: 'Yeni Ek Ödeme',
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
                  Text('Dönemsel Ek Ödeme Dağıtımı',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _yeniEkOdemeDialog(context),
                    tooltip: 'Yeni Ek Ödeme',
                  ),
                ],
              ),
            ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.ekOdemeler.isEmpty
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
          Icon(Icons.payments, size: 64, color: theme.disabledColor),
          const SizedBox(height: 16),
          Text('Ek ödeme kaydı bulunamadı.', style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildListe(EkOdemeProvider provider, ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.ekOdemeler.length,
      itemBuilder: (context, index) {
        final ekOdeme = provider.ekOdemeler[index];
        return _buildEkOdemeKart(ekOdeme, theme);
      },
    );
  }

  Widget _buildEkOdemeKart(EkOdemeModel ekOdeme, ThemeData theme) {
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
                      Text(ekOdeme.birimAd,
                          style: theme.textTheme.titleMedium),
                      Text(ekOdeme.donem, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    ekOdeme.durum.displayName,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dağıtılan Tutar', style: theme.textTheme.bodySmall),
                    Text(
                      TurkceFormat.para(ekOdeme.toplamDagitilanTutar),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Katsayı', style: theme.textTheme.bodySmall),
                    Text(
                      TurkceFormat.katsayi(ekOdeme.katsayi),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${ekOdeme.personelListesi.length} personel',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _yeniEkOdemeDialog(BuildContext context) {
    final birimAdController = TextEditingController();
    final donemController = TextEditingController();
    final tutarController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni Ek Ödeme Dağıtımı'),
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
                decoration: const InputDecoration(
                    labelText: 'Dönem (ör: Ocak-Şubat-Mart 2026)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: tutarController,
                decoration:
                    const InputDecoration(labelText: 'Dağıtılacak Tutar'),
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
              final tutar = double.tryParse(
                      tutarController.text.replaceAll(',', '.')) ??
                  0;
              final model = EkOdemeModel(
                id: '',
                birimId: '',
                birimAd: birimAdController.text,
                donem: donemController.text,
                katsayi: 0,
                toplamDagitilanTutar: tutar,
                toplamPuan: 0,
              );
              context.read<EkOdemeProvider>().ekOdemeOlustur(model);
              Navigator.pop(ctx);
            },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }
}
