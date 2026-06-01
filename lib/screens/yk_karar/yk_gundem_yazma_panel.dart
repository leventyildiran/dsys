import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:printing/printing.dart';

import '../../models/birim_model.dart';
import '../../models/gundem_model.dart';
import '../../providers/gundem_provider.dart';
import '../../services/data_service.dart';
import '../../services/gundem_parser_service.dart';
import '../../services/pdf_service.dart';

/// Yürütme Kurulu Gündem Yazma ve Derleme Çalışma Alanı (Workspace).
/// Sol tarafta reorderable gündem maddeleri ve ekleme butonları yer alırken,
/// sağ tarafta canlı olarak A4 kağıt formatında gündem PDF önizlemesi sunulur.
class YkGundemYazmaPanel extends StatefulWidget {
  const YkGundemYazmaPanel({
    super.key,
    required this.onGoToToplantilar,
  });

  final VoidCallback onGoToToplantilar;

  @override
  State<YkGundemYazmaPanel> createState() => _YkGundemYazmaPanelState();
}

class _YkGundemYazmaPanelState extends State<YkGundemYazmaPanel> {
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<GundemProvider>();
    final toplanti = provider.seciliToplanti;

    if (toplanti == null) {
      return _buildBosEkran(theme);
    }

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: _buildSolPanel(context, toplanti, provider, theme),
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(
                  flex: 5,
                  child: _buildSagPanel(toplanti, theme),
                ),
              ],
            );
          } else {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSolPanel(context, toplanti, provider, theme),
                  const SizedBox(height: 24),
                  _buildSagPanel(toplanti, theme),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildBosEkran(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_note_rounded,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Gündem / Toplantı Seçilmedi',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Gündem maddelerini düzenlemek ve canlı önizlemek için\nlütfen "Toplantılar" sekmesinden bir toplantı seçin.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: widget.onGoToToplantilar,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Toplantılara Git'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSolPanel(
    BuildContext context,
    ToplantiModel toplanti,
    GundemProvider provider,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toplantı Bilgi Barı
        Container(
          padding: const EdgeInsets.all(16),
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          child: Row(
            children: [
              Icon(Icons.event_note_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Toplantı No: ${toplanti.toplantiNo}',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Tarih: ${toplanti.toplantiTarihi}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Text(
                '${toplanti.gundemMaddeleri.length} Madde',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        
        // Eylem Butonları
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => _yeniMaddeDialog(context, toplanti.id, provider),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Yeni Madde Ekle'),
              ),
              OutlinedButton.icon(
                onPressed: _isImporting ? null : () => _pdfGundemMaddeleriEkle(context, toplanti.id, provider),
                icon: _isImporting 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.upload_file_rounded),
                label: const Text('PDF\'ten Maddeleri Yükle'),
              ),
              OutlinedButton.icon(
                onPressed: () => _gundemBelgesiIndir(context, provider, toplanti),
                icon: const Icon(Icons.download_rounded),
                label: const Text('Belgeyi (TXT) İndir'),
              ),
            ],
          ),
        ),
        
        const Divider(height: 1),
        
        // Maddeler Listesi
        Expanded(
          child: toplanti.gundemMaddeleri.isEmpty
              ? Center(
                  child: Text(
                    'Henüz gündem maddesi eklenmemiş.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : Theme(
                  data: theme.copyWith(
                    canvasColor: Colors.transparent, 
                  ),
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: toplanti.gundemMaddeleri.length,
                    onReorder: (oldIndex, newIndex) {
                      if (newIndex > oldIndex) newIndex--;
                      provider.siraDegistir(toplanti.id, oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final madde = toplanti.gundemMaddeleri[index];
                      return Card(
                        key: ValueKey('${madde.siraNo}_${madde.baslik}'),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Text(
                              '${madde.siraNo}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          title: Text(
                            madde.baslik,
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.secondaryContainer,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      madde.tur.displayName,
                                      style: TextStyle(fontSize: 10, color: theme.colorScheme.onSecondaryContainer),
                                    ),
                                  ),
                                  if (madde.birimAd != null && madde.birimAd!.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        madde.birimAd!,
                                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                onPressed: () => _maddeSilOnayDialog(context, toplanti.id, index, provider),
                                tooltip: 'Maddeyi Sil',
                              ),
                              const Icon(Icons.drag_handle_rounded, color: Colors.grey),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSagPanel(ToplantiModel toplanti, ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceVariant.withOpacity(0.1),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.picture_as_pdf_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Gündem Canlı Önizleme (A4)',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.antiAlias,
              child: PdfPreview(
                build: (format) => PdfService.ykGundemPdfUret(toplanti),
                canChangeOrientation: false,
                canChangePageFormat: false,
                canDebug: false,
                allowPrinting: true,
                allowSharing: true,
                pdfFileName: 'gundem_${toplanti.toplantiNo.replaceAll('/', '_')}.pdf',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pdfGundemMaddeleriEkle(
    BuildContext context,
    String toplantiId,
    GundemProvider provider,
  ) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final bytes = result.files.first.bytes;
    if (bytes == null) return;

    setState(() => _isImporting = true);

    try {
      final parser = GundemParserService();
      final pdfDoc = parser.pdfMetniCikar(bytes);
      final maddeler = parser.metniGundemMaddelerineAyristir(pdfDoc);

      for (final madde in maddeler) {
        await provider.gundemMaddesiEkle(toplantiId, madde);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${maddeler.length} adet gündem maddesi PDF\'ten eklendi.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF okuma hatası: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isImporting = false);
    }
  }

  void _yeniMaddeDialog(
    BuildContext context,
    String toplantiId,
    GundemProvider provider,
  ) {
    final baslikController = TextEditingController();
    final aciklamaController = TextEditingController();
    final birimAdController = TextEditingController();
    GundemTuru seciliTur = GundemTuru.diger;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Yeni Gündem Maddesi'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: baslikController,
                  decoration: const InputDecoration(
                    labelText: 'Gündem Başlığı',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<GundemTuru>(
                  value: seciliTur,
                  decoration: const InputDecoration(
                    labelText: 'Gündem Türü',
                    border: OutlineInputBorder(),
                  ),
                  items: GundemTuru.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.displayName),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => seciliTur = val);
                    }
                  },
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<BirimModel>>(
                  future: BirimService().getAll(onlyActive: true),
                  builder: (context, snapshot) {
                    final list = snapshot.data ?? [];
                    String? currentValue;
                    if (list.any((b) => b.ad == birimAdController.text)) {
                      currentValue = birimAdController.text;
                    }
                    return DropdownButtonFormField<String?>(
                      value: currentValue,
                      decoration: const InputDecoration(
                        labelText: 'Birim Seçin (Opsiyonel)',
                        prefixIcon: Icon(Icons.business_rounded),
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Genel / Birim Yok'),
                        ),
                        ...list.map((b) => DropdownMenuItem<String?>(
                              value: b.ad,
                              child: Text('${b.kisaAd} - ${b.ad}'),
                            )),
                      ],
                      onChanged: (val) {
                        setState(() {
                          birimAdController.text = val ?? '';
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: aciklamaController,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama (Opsiyonel)',
                    border: OutlineInputBorder(),
                  ),
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
              onPressed: () async {
                if (baslikController.text.trim().isEmpty) return;
                final yeniMadde = GundemMaddesi(
                  siraNo: 0,
                  baslik: baslikController.text,
                  tur: seciliTur,
                  aciklama: aciklamaController.text,
                  birimAd: birimAdController.text,
                );
                await provider.gundemMaddesiEkle(toplantiId, yeniMadde);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  void _maddeSilOnayDialog(
    BuildContext context,
    String toplantiId,
    int index,
    GundemProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gündem Maddesini Sil'),
        content: const Text('Bu gündem maddesini silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () async {
              await provider.gundemMaddesiSil(toplantiId, index);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  Future<void> _gundemBelgesiIndir(
    BuildContext context,
    GundemProvider provider,
    ToplantiModel toplanti,
  ) async {
    final belge = provider.gundemBelgesiUret();
    if (belge != null) {
      final bytes = Uint8List.fromList(utf8.encode(belge));
      await FileSaver.instance.saveFile(
        name: 'gundem_${toplanti.toplantiNo.replaceAll('/', '_')}_${toplanti.toplantiTarihi}',
        bytes: bytes,
        ext: 'txt',
        mimeType: MimeType.text,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gündem belgesi başarıyla indirildi.'), backgroundColor: Colors.green),
        );
      }
    }
  }
}
