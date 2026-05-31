import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/evrak_arsiv_model.dart';
import '../../providers/evrak_arsiv_provider.dart';

/// Dahili Evrak Arşivi ekranı.
class EvrakArsivScreen extends StatefulWidget {
  const EvrakArsivScreen({super.key});

  @override
  State<EvrakArsivScreen> createState() => _EvrakArsivScreenState();
}

class _EvrakArsivScreenState extends State<EvrakArsivScreen> {
  final _aramaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EvrakArsivProvider>().evraklariYukle();
    });
  }

  @override
  void dispose() {
    _aramaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<EvrakArsivProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evrak Arşivi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _yeniEvrakDialog(context),
            tooltip: 'Yeni Evrak',
          ),
        ],
      ),
      body: Column(
        children: [
          // Arama çubuğu
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _aramaController,
              decoration: InputDecoration(
                hintText: 'Evrak ara (başlık, sayı, etiket)...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _aramaController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _aramaController.clear();
                          provider.evraklariYukle();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (value) => provider.ara(value),
            ),
          ),

          // Tür filtreleri
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Tümü'),
                  selected: !provider.aramaAktif,
                  onSelected: (_) => provider.evraklariYukle(),
                ),
                const SizedBox(width: 8),
                ...EvrakTuru.values.map((tur) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(tur.displayName),
                        selected: false,
                        onSelected: (_) => provider.turFiltrele(tur),
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Liste
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildListe(provider, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildListe(EvrakArsivProvider provider, ThemeData theme) {
    final evraklar =
        provider.aramaAktif ? provider.aramaSonuclari : provider.evraklar;

    if (evraklar.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text('Evrak bulunamadı.', style: theme.textTheme.bodyLarge),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: evraklar.length,
      itemBuilder: (context, index) {
        final evrak = evraklar[index];
        return _buildEvrakKart(evrak, provider, theme);
      },
    );
  }

  Widget _buildEvrakKart(
    EvrakModel evrak,
    EvrakArsivProvider provider,
    ThemeData theme,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(_evrakIcon(evrak.evrakTuru)),
        ),
        title: Text(evrak.baslik, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${evrak.evrakTuru.displayName} • ${evrak.evrakTarihi ?? ""}',
            ),
            if (evrak.etiketler.isNotEmpty)
              Wrap(
                spacing: 4,
                children: evrak.etiketler
                    .take(3)
                    .map((e) => Chip(
                          label: Text(e, style: const TextStyle(fontSize: 10)),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'arsivle') provider.arsivle(evrak.id);
            if (value == 'sil') provider.evrakSil(evrak.id);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'arsivle', child: Text('Arşivle')),
            const PopupMenuItem(value: 'sil', child: Text('Sil')),
          ],
        ),
      ),
    );
  }

  IconData _evrakIcon(EvrakTuru tur) {
    switch (tur) {
      case EvrakTuru.ustYazi:
        return Icons.mail;
      case EvrakTuru.kararMetni:
        return Icons.gavel;
      case EvrakTuru.faaliyetCetveli:
        return Icons.table_chart;
      case EvrakTuru.sozlesme:
        return Icons.description;
      case EvrakTuru.fatura:
        return Icons.receipt;
      case EvrakTuru.dilekce:
        return Icons.edit_document;
      case EvrakTuru.diger:
        return Icons.insert_drive_file;
    }
  }

  void _yeniEvrakDialog(BuildContext context) {
    final baslikController = TextEditingController();
    final evrakSayisiController = TextEditingController();
    EvrakTuru secilenTur = EvrakTuru.diger;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Yeni Evrak Kaydı'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: baslikController,
                  decoration: const InputDecoration(labelText: 'Başlık'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: evrakSayisiController,
                  decoration: const InputDecoration(labelText: 'Evrak Sayısı'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<EvrakTuru>(
                  value: secilenTur,
                  decoration: const InputDecoration(labelText: 'Evrak Türü'),
                  items: EvrakTuru.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.displayName),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => secilenTur = value);
                    }
                  },
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
                final model = EvrakModel(
                  id: '',
                  baslik: baslikController.text,
                  evrakTuru: secilenTur,
                  evrakSayisi: evrakSayisiController.text,
                );
                context.read<EvrakArsivProvider>().evrakOlustur(model);
                Navigator.pop(ctx);
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
