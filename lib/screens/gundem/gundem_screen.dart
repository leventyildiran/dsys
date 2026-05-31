import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/gundem_model.dart';
import '../../providers/gundem_provider.dart';

/// Toplantı Gündem Derleyici ekranı.
class GundemScreen extends StatefulWidget {
  const GundemScreen({super.key});

  @override
  State<GundemScreen> createState() => _GundemScreenState();
}

class _GundemScreenState extends State<GundemScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GundemProvider>().toplantilariYukle();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<GundemProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Toplantı Gündem Derleyici'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _yeniToplantiDialog(context),
            tooltip: 'Yeni Toplantı',
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.toplantilar.isEmpty
              ? _buildBosEkran(theme)
              : _buildListe(provider, theme),
    );
  }

  Widget _buildBosEkran(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note, size: 64, color: theme.disabledColor),
          const SizedBox(height: 16),
          Text('Toplantı kaydı bulunamadı.', style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildListe(GundemProvider provider, ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.toplantilar.length,
      itemBuilder: (context, index) {
        final toplanti = provider.toplantilar[index];
        return _buildToplantiKart(toplanti, provider, theme);
      },
    );
  }

  Widget _buildToplantiKart(
    ToplantiModel toplanti,
    GundemProvider provider,
    ThemeData theme,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _gundemDetayDialog(context, toplanti, provider),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.event, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Toplantı No: ${toplanti.toplantiNo}',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Chip(
                    label: Text(
                      toplanti.durum.displayName,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Tarih: ${toplanti.toplantiTarihi}',
                style: theme.textTheme.bodySmall,
              ),
              const Divider(),
              Text(
                '${toplanti.gundemMaddeleri.length} gündem maddesi',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              if (toplanti.gundemMaddeleri.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...toplanti.gundemMaddeleri.take(3).map((madde) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Text(
                            '${madde.siraNo}.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              madde.baslik,
                              style: theme.textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )),
                if (toplanti.gundemMaddeleri.length > 3)
                  Text(
                    '... ve ${toplanti.gundemMaddeleri.length - 3} madde daha',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _gundemDetayDialog(
    BuildContext context,
    ToplantiModel toplanti,
    GundemProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Toplantı ${toplanti.toplantiNo}'),
        content: SizedBox(
          width: double.maxFinite,
          child: toplanti.gundemMaddeleri.isEmpty
              ? const Text('Henüz gündem maddesi eklenmemiş.')
              : ReorderableListView.builder(
                  shrinkWrap: true,
                  itemCount: toplanti.gundemMaddeleri.length,
                  onReorder: (oldIndex, newIndex) {
                    if (newIndex > oldIndex) newIndex--;
                    provider.siraDegistir(toplanti.id, oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final madde = toplanti.gundemMaddeleri[index];
                    return ListTile(
                      key: ValueKey('${madde.siraNo}_${madde.baslik}'),
                      leading: CircleAvatar(
                        radius: 14,
                        child: Text(
                          '${madde.siraNo}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      title: Text(madde.baslik),
                      subtitle: Text(madde.tur.displayName),
                      trailing: const Icon(Icons.drag_handle),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final belge = provider.gundemBelgesiUret();
              if (belge != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gündem belgesi üretildi.')),
                );
              }
              Navigator.pop(ctx);
            },
            child: const Text('Belge Üret'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _yeniToplantiDialog(BuildContext context) {
    final toplantiNoController = TextEditingController();
    final tarihController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni Toplantı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: toplantiNoController,
              decoration: const InputDecoration(labelText: 'Toplantı No'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: tarihController,
              decoration:
                  const InputDecoration(labelText: 'Tarih (dd.MM.yyyy)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              final model = ToplantiModel(
                id: '',
                toplantiTarihi: tarihController.text,
                toplantiNo: toplantiNoController.text,
              );
              context.read<GundemProvider>().toplantiOlustur(model);
              Navigator.pop(ctx);
            },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }
}
