import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_saver/file_saver.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

import '../../models/gundem_model.dart';
import '../../models/yk_karar_model.dart';
import '../../providers/gundem_provider.dart';
import '../../providers/yk_karar_provider.dart';
import '../../services/gundem_parser_service.dart';

/// Yürütme Kurulu Karar Merkezi ekranı.
class YkKararMerkeziScreen extends StatefulWidget {
  const YkKararMerkeziScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<YkKararMerkeziScreen> createState() => _YkKararMerkeziScreenState();
}

class _YkKararMerkeziScreenState extends State<YkKararMerkeziScreen> {
  String? _seciliToplantiId;
  ToplantiModel? _seciliToplanti;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GundemProvider>().toplantilariYukle();
      context.read<YkKararProvider>().toplantiSec(null); // Başta tümü veya atanmamışlar
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gundemProvider = context.watch<GundemProvider>();
    final ykProvider = context.watch<YkKararProvider>();

    // Toplantı listesi ("Atanmamış Kararlar" seçeneğiyle birlikte)
    final toplantilar = gundemProvider.toplantilar;

    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text('YK Karar Merkezi'),
              actions: [
                if (_seciliToplanti != null)
                  IconButton(
                    icon: const Icon(Icons.download_rounded),
                    onPressed: () => _kararDefteriIndir(context, ykProvider),
                    tooltip: 'Karar Defteri İndir',
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
                  Text('YK Karar Merkezi',
                      style: theme.textTheme.headlineSmall),
                  const Spacer(),
                  if (_seciliToplanti != null)
                    IconButton(
                      icon: const Icon(Icons.download_rounded),
                      onPressed: () => _kararDefteriIndir(context, ykProvider),
                      tooltip: 'Karar Defteri İndir',
                    ),
                ],
              ),
            ),
          // Toplantı Filtreleme Seçici
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.filter_list_rounded),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _seciliToplantiId,
                        hint: const Text('Toplantı Seçin (Tüm Kararlar)'),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Tüm Kararlar'),
                          ),
                          const DropdownMenuItem<String?>(
                            value: '',
                            child: Text('Karar Havuzu (Atanmamış / Gündem Dışı)'),
                          ),
                          ...toplantilar.map((t) => DropdownMenuItem<String?>(
                                value: t.id,
                                child: Text('Toplantı No: ${t.toplantiNo} - ${t.toplantiTarihi}'),
                              )),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _seciliToplantiId = val;
                            if (val != null && val.isNotEmpty) {
                              _seciliToplanti = toplantilar.firstWhere((t) => t.id == val);
                            } else {
                              _seciliToplanti = null;
                            }
                          });
                          ykProvider.toplantiSec(val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_isImporting)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  else
                    FilledButton.icon(
                      onPressed: () => _pdfGundemIceriAktar(context, ykProvider),
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                      label: const Text('PDF İçe Aktar'),
                    ),
                ],
              ),
            ),
          ),
          // Bilgilendirme Mesajları
          if (ykProvider.hataMesaji != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                ykProvider.hataMesaji!,
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
          if (ykProvider.basariMesaji != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                ykProvider.basariMesaji!,
                style: TextStyle(color: Colors.green.shade800),
              ),
            ),
          // Karar Listesi
          Expanded(
            child: ykProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ykProvider.kararlar.isEmpty
                    ? _buildBosEkran(theme)
                    : _buildListe(ykProvider, toplantilar, theme),
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
          Icon(Icons.gavel_rounded, size: 64, color: theme.disabledColor),
          const SizedBox(height: 16),
          Text('Karar bulunamadı.', style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildListe(
    YkKararProvider provider,
    List<ToplantiModel> toplantilar,
    ThemeData theme,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.kararlar.length + (provider.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= provider.kararlar.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: provider.isLoadingMore
                  ? const CircularProgressIndicator()
                  : OutlinedButton.icon(
                      onPressed: provider.dahaFazlaYukle,
                      icon: const Icon(Icons.expand_more_rounded),
                      label: const Text('Daha fazla yükle'),
                    ),
            ),
          );
        }
        final karar = provider.kararlar[index];
        return _buildKararKart(karar, provider, toplantilar, theme);
      },
    );
  }

  Widget _buildKararKart(
    YkKararModel karar,
    YkKararProvider provider,
    List<ToplantiModel> toplantilar,
    ThemeData theme,
  ) {
    final colorScheme = theme.colorScheme;
    final isTaslak = karar.durum == YkKararDurum.taslak;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Karar Numarası veya Taslak Çipi
                if (karar.kararNo.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Karar: ${karar.kararNo}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Karar No Atanmamış',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                // Tür Çipi
                Chip(
                  label: Text(karar.tur.displayName, style: const TextStyle(fontSize: 10)),
                  visualDensity: VisualDensity.compact,
                ),
                const Spacer(),
                // Durum Göstergesi
                Icon(
                  isTaslak ? Icons.edit_attributes_rounded : Icons.check_circle_rounded,
                  color: isTaslak ? Colors.orange : Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(karar.baslik, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Birim: ${karar.birimAd}',
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            if (karar.toplantiNo.isNotEmpty)
              Text(
                'Toplantı No: ${karar.toplantiNo}',
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            const Divider(height: 24),
            Text(
              karar.kararMetni,
              style: theme.textTheme.bodyMedium,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            // Aksiyon Butonları
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Toplantıya Ata Butonu (Eğer atanmamışsa)
                if (karar.toplantiId.isEmpty)
                  TextButton.icon(
                    onPressed: () => _toplantiyaAtaDialog(context, karar, provider, toplantilar),
                    icon: const Icon(Icons.event_note_rounded, size: 18),
                    label: const Text('Toplantıya Ata'),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: Colors.blue),
                  onPressed: () => _kararDuzenleDialog(context, karar, provider),
                  tooltip: 'Düzenle',
                ),
                if (isTaslak)
                  IconButton(
                    icon: const Icon(Icons.check_rounded, color: Colors.green),
                    onPressed: () => provider.durumDegistir(karar.id, YkKararDurum.onaylandi),
                    tooltip: 'Onayla',
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_rounded, color: Colors.red),
                  onPressed: () => provider.kararSil(karar.id),
                  tooltip: 'Sil',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _kararDuzenleDialog(
    BuildContext context,
    YkKararModel karar,
    YkKararProvider provider,
  ) {
    final baslikController = TextEditingController(text: karar.baslik);
    final metinController = TextEditingController(text: karar.kararMetni);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Karar Düzenle'),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: baslikController,
                  decoration: const InputDecoration(labelText: 'Karar Başlığı'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: metinController,
                  decoration: const InputDecoration(labelText: 'Karar Metni'),
                  maxLines: 8,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              provider.kararGuncelle(karar.id, baslikController.text, metinController.text);
              Navigator.pop(ctx);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _toplantiyaAtaDialog(
    BuildContext context,
    YkKararModel karar,
    YkKararProvider provider,
    List<ToplantiModel> toplantilar,
  ) {
    String? seciliToplantiId = toplantilar.isNotEmpty ? toplantilar.first.id : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Kararı Toplantıya Ata'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (toplantilar.isEmpty)
                const Text('Öncelikle Gündem ekranından bir toplantı oluşturmalısınız.')
              else
                DropdownButtonFormField<String>(
                  value: seciliToplantiId,
                  decoration: const InputDecoration(labelText: 'Toplantı Seçin'),
                  items: toplantilar
                      .map((t) => DropdownMenuItem(
                            value: t.id,
                            child: Text('Toplantı No: ${t.toplantiNo} - ${t.toplantiTarihi}'),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setState(() => seciliToplantiId = val);
                  },
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            if (toplantilar.isNotEmpty)
              FilledButton(
                onPressed: () {
                  final toplanti = toplantilar.firstWhere((t) => t.id == seciliToplantiId);
                  provider.durumDegistir(karar.id, YkKararDurum.taslak); // Önce taslak
                  provider.durumDegistir(karar.id, YkKararDurum.taslak);
                  
                  // Toplantı verilerini güncelle
                  FirebaseFirestore.instance.collection('ykKararlari').doc(karar.id).update({
                    'toplantiId': toplanti.id,
                    'toplantiNo': toplanti.toplantiNo,
                    'kararTarihi': toplanti.toplantiTarihi,
                  }).then((_) {
                    provider.kararlariYukle();
                  });

                  Navigator.pop(ctx);
                },
                child: const Text('Ata'),
              ),
          ],
        ),
      ),
    );
  }

  void _kararDefteriIndir(BuildContext context, YkKararProvider provider) async {
    if (_seciliToplanti == null) return;
    final defter = await provider.kararDefteriMetniUret(
      _seciliToplanti!.id,
      _seciliToplanti!.toplantiNo,
      _seciliToplanti!.toplantiTarihi,
    );

    if (defter != null) {
      final bytes = Uint8List.fromList(utf8.encode(defter));
      await FileSaver.instance.saveFile(
        name: 'karar_defteri_${_seciliToplanti!.toplantiNo.replaceAll('/', '_')}',
        bytes: bytes,
        ext: 'txt',
        mimeType: MimeType.text,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Karar Defteri başarıyla indirildi.')),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bu toplantıya ait onaylanmış karar bulunmamaktadır.')),
        );
      }
    }
  }

  Future<void> _pdfGundemIceriAktar(BuildContext context, YkKararProvider provider) async {
    final result = await FilePicker.platform.pickFiles(
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
      final eklenenIdler = await parser.pdfGundemIceriAktar(bytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${eklenenIdler.length} adet gündem maddesi havuza eklendi.')),
        );
      }
      
      // Havuzu yenile
      provider.kararlariYukle();
      
      // Dropdown'da Karar Havuzunu seçili hale getir
      setState(() {
        _seciliToplantiId = '';
        _seciliToplanti = null;
      });
      provider.toplantiSec('');
      
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İçe aktarma hatası: \$e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }
}
