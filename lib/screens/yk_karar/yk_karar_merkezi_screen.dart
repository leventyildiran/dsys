import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_saver/file_saver.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';

import '../../models/birim_model.dart';
import '../../models/gundem_model.dart';
import '../../models/yk_karar_model.dart';
import '../../models/sistem_ayarlari_model.dart';
import '../../providers/gundem_provider.dart';
import '../../providers/yk_karar_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/data_service.dart';
import '../../services/gundem_parser_service.dart';
import '../../services/pdf_service.dart';

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
  
  StreamSubscription<SistemAyarlariModel?>? _ayarlarSubscription;
  SistemAyarlariModel? _ayarlar;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GundemProvider>().toplantilariYukle();
      context.read<YkKararProvider>().toplantiSec(null); // Başta tümü veya atanmamışlar
    });
    _ayarlarSubscription = SistemAyarlariService().stream().listen((ayarlar) {
      if (mounted) {
        setState(() {
          _ayarlar = ayarlar;
        });
      }
    });
  }

  @override
  void dispose() {
    _ayarlarSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gundemProvider = context.watch<GundemProvider>();
    final ykProvider = context.watch<YkKararProvider>();
    final userProvider = context.watch<UserProvider>();
    final hasGlobalAccess = userProvider.hasGlobalAccess;

    // Toplantı listesi ("Atanmamış Kararlar" seçeneğiyle birlikte)
    final toplantilar = gundemProvider.toplantilar;

    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text('YK Karar Merkezi'),
              actions: [
                if (hasGlobalAccess)
                  IconButton(
                    icon: const Icon(Icons.settings_rounded),
                    onPressed: () => _kurulUyeleriDuzenleDialog(context),
                    tooltip: 'Kurul Üyeleri Ayarları',
                  ),
                if (_seciliToplanti != null) ...[
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    onPressed: () => _pdfOnizlemeDialog(context, ykProvider),
                    tooltip: 'PDF Önizle & Yazdır',
                  ),
                  IconButton(
                    icon: const Icon(Icons.download_rounded),
                    onPressed: () => _kararDefteriIndir(context, ykProvider),
                    tooltip: 'Karar Defteri İndir',
                  ),
                ],
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
                  if (hasGlobalAccess)
                    IconButton(
                      icon: const Icon(Icons.settings_rounded),
                      onPressed: () => _kurulUyeleriDuzenleDialog(context),
                      tooltip: 'Kurul Üyeleri Ayarları',
                    ),
                  if (_seciliToplanti != null) ...[
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      onPressed: () => _pdfOnizlemeDialog(context, ykProvider),
                      tooltip: 'PDF Önizle & Yazdır',
                    ),
                    IconButton(
                      icon: const Icon(Icons.download_rounded),
                      onPressed: () => _kararDefteriIndir(context, ykProvider),
                      tooltip: 'Karar Defteri İndir',
                    ),
                  ],
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
                  icon: const Icon(Icons.visibility_rounded, color: Colors.blueGrey),
                  onPressed: () => _kararOnizleDialog(context, karar),
                  tooltip: 'Önizle',
                ),
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
    final birimAdController = TextEditingController(text: karar.birimAd);
    final birimIdController = TextEditingController(text: karar.birimId);

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
                        labelText: 'Birim Seçin',
                        prefixIcon: Icon(Icons.business_rounded),
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
                        final selected = list.firstWhere((b) => b.ad == val, orElse: () => const BirimModel(id: '', ad: '', kisaAd: '', tur: BirimTuru.merkez));
                        birimAdController.text = val ?? '';
                        birimIdController.text = selected.id;
                      },
                    );
                  },
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
              provider.kararGuncelle(
                karar.id,
                baslikController.text,
                metinController.text,
                birimId: birimIdController.text,
                birimAd: birimAdController.text,
              );
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

  void _kararOnizleDialog(BuildContext context, YkKararModel karar) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SizedBox(
          width: 750,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.article_rounded, color: colorScheme.onPrimaryContainer),
                    const SizedBox(width: 12),
                    Text(
                      'Karar Belgesi Önizlemesi',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: colorScheme.onPrimaryContainer),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              // Document mockup body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white, // clean paper color
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // University Header
                        Center(
                          child: Text(
                            'T.C.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            'UŞAK ÜNİVERSİTESİ',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Double bordered box
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black, width: 1),
                          ),
                          padding: const EdgeInsets.all(2), // outer border spacing
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black, width: 1),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            child: Column(
                              children: [
                                Text(
                                  'DÖNER SERMAYE YÜRÜTME KURULU KARARLARI',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Divider(color: Colors.black, height: 1, thickness: 1),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'TOPLANTI SAYISI: ${karar.toplantiNo.isNotEmpty ? karar.toplantiNo : "-"}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 11),
                                    ),
                                    Text(
                                      'KARAR TARİHİ: ${karar.kararTarihi.isNotEmpty ? karar.kararTarihi : "-"}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Preamble / Giriş Metni
                        Builder(
                          builder: (context) {
                            final kurulUyeleri = _ayarlar?.kurulUyeleriListesi ?? SistemAyarlariModel.varsayilanKurulUyeleri;
                            final baskanUye = kurulUyeleri.firstWhere(
                              (u) => u.gorev.toLowerCase().contains('başkan') || u.gorev.toLowerCase().contains('baskan'),
                              orElse: () => kurulUyeleri.isNotEmpty
                                  ? kurulUyeleri.first
                                  : const KurulUyesiModel(siraNo: '1', gorev: 'Başkan', adSoyad: ''),
                            );
                            final baskanAdi = baskanUye.adSoyad;

                            return Text(
                              "Uşak Üniversitesi Döner Sermaye Yürütme Kurulu, $baskanAdi başkanlığında ${karar.kararTarihi.isNotEmpty ? karar.kararTarihi : "-"} tarihinde saat 14:00' te toplandı. Gündem maddeleri görüşülerek aşağıdaki kararlar alındı.",
                              textAlign: TextAlign.justify,
                              style: const TextStyle(color: Colors.black, fontSize: 13, height: 1.5),
                            );
                          }
                        ),
                        const SizedBox(height: 20),

                        // Decision Title
                        Text(
                          'KARAR ${karar.kararNo.isNotEmpty ? karar.kararNo : "Taslak"}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 13),
                        ),
                        const SizedBox(height: 8),

                        // Decision Text
                        Text(
                          karar.kararMetni,
                          textAlign: TextAlign.justify,
                          style: const TextStyle(color: Colors.black, fontSize: 13, height: 1.5),
                        ),
                        const SizedBox(height: 24),

                        // Oy birliği ifadesi
                        Center(
                          child: Text(
                            'Katılanların oy birliği ile karar verildi.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Signature Table
                        Builder(
                          builder: (context) {
                            final kurulUyeleri = _ayarlar?.kurulUyeleriListesi ?? SistemAyarlariModel.varsayilanKurulUyeleri;

                            return Table(
                              border: TableBorder.all(color: Colors.black, width: 0.8),
                              columnWidths: const {
                                0: FixedColumnWidth(55),
                                1: FixedColumnWidth(90),
                                2: FlexColumnWidth(),
                                3: FixedColumnWidth(110),
                              },
                              children: [
                                TableRow(
                                  decoration: BoxDecoration(color: Colors.grey.shade100),
                                  children: const [
                                    Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Text('Sıra No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Text('Görevi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Text('Üyenin Adı Soyadı', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Text('İmzası', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center),
                                    ),
                                  ],
                                ),
                                ...List.generate(kurulUyeleri.length, (index) {
                                  final uye = kurulUyeleri[index];
                                  return _buildDialogSignatureRow(
                                    (index + 1).toString(),
                                    uye.gorev,
                                    uye.adSoyad,
                                  );
                                }),
                              ],
                            );
                          }
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Footer Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Kapat'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static TableRow _buildDialogSignatureRow(String siraNo, String gorev, String adSoyad) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(siraNo, style: const TextStyle(fontSize: 11, color: Colors.black), textAlign: TextAlign.center),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(gorev, style: const TextStyle(fontSize: 11, color: Colors.black)),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(adSoyad, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black)),
        ),
        const Padding(
          padding: EdgeInsets.all(8),
          child: SizedBox(height: 25),
        ),
      ],
    );
  }

  void _pdfOnizlemeDialog(BuildContext context, YkKararProvider provider) {
    if (_seciliToplanti == null) return;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.picture_as_pdf_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text('Karar Defteri PDF Önizleme (Toplantı: ${_seciliToplanti!.toplantiNo})'),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
        content: SizedBox(
          width: 850,
          height: MediaQuery.of(context).size.height * 0.8,
          child: PdfPreview(
            build: (format) => PdfService.ykKararDefteriPdfUret(
              _seciliToplanti!,
              provider.kararlar,
              _ayarlar?.kurulUyeleriListesi ?? SistemAyarlariModel.varsayilanKurulUyeleri,
            ),
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
            allowPrinting: true,
            allowSharing: true,
            pdfFileName: 'karar_defteri_${_seciliToplanti!.toplantiNo.replaceAll('/', '_')}.pdf',
          ),
        ),
      ),
    );
  }

  void _kurulUyeleriDuzenleDialog(BuildContext context) {
    final currentList = _ayarlar?.kurulUyeleriListesi ?? SistemAyarlariModel.varsayilanKurulUyeleri;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return KurulUyeleriDuzenleDialog(
          initialMembers: currentList,
          onSave: (newMembers) async {
            try {
              final service = SistemAyarlariService();
              final currentSettings = await service.get() ?? SistemAyarlariModel(
                memurMaasKatsayisi: 1.387871,
                eydmaGosterge: 9500,
                varsayilanKesintiler: const VarsayilanKesintiler(),
                unvanKatsayilari: const {},
              );
              
              final updatedSettings = SistemAyarlariModel(
                memurMaasKatsayisi: currentSettings.memurMaasKatsayisi,
                eydmaGosterge: currentSettings.eydmaGosterge,
                varsayilanKesintiler: currentSettings.varsayilanKesintiler,
                unvanKatsayilari: currentSettings.unvanKatsayilari,
                aiApiKey: currentSettings.aiApiKey,
                aiApiUrl: currentSettings.aiApiUrl,
                aiModel: currentSettings.aiModel,
                kurulUyeleri: newMembers,
              );
              
              await service.update(updatedSettings.toMap());
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kurul üyeleri başarıyla güncellendi.')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ayarlar güncellenirken hata: $e')),
                );
              }
            }
          },
        );
      },
    );
  }
}

/// Kurul üyelerini dynamic olarak düzenleme, artırma/azaltma formu diyalogu.
class KurulUyeleriDuzenleDialog extends StatefulWidget {
  const KurulUyeleriDuzenleDialog({
    super.key,
    required this.initialMembers,
    required this.onSave,
  });

  final List<KurulUyesiModel> initialMembers;
  final Function(List<KurulUyesiModel>) onSave;

  @override
  State<KurulUyeleriDuzenleDialog> createState() => _KurulUyeleriDuzenleDialogState();
}

class _KurulUyeleriDuzenleDialogState extends State<KurulUyeleriDuzenleDialog> {
  final List<TextEditingController> _gorevControllers = [];
  final List<TextEditingController> _adSoyadControllers = [];
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    for (final member in widget.initialMembers) {
      _gorevControllers.add(TextEditingController(text: member.gorev));
      _adSoyadControllers.add(TextEditingController(text: member.adSoyad));
    }
  }

  @override
  void dispose() {
    for (final c in _gorevControllers) {
      c.dispose();
    }
    for (final c in _adSoyadControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _uyeEkle() {
    setState(() {
      _gorevControllers.add(TextEditingController(text: 'Üye'));
      _adSoyadControllers.add(TextEditingController());
    });
  }

  void _uyeSil(int index) {
    setState(() {
      final gc = _gorevControllers.removeAt(index);
      final ac = _adSoyadControllers.removeAt(index);
      gc.dispose();
      ac.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.manage_accounts_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Kurul Üyeleri Ayarları'),
        ],
      ),
      content: SizedBox(
        width: 600,
        height: 450,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: _gorevControllers.isEmpty
                    ? Center(
                        child: Text(
                          'Kurulda kayıtlı üye bulunmamaktadır.\nYeni üye ekleyebilirsiniz.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.disabledColor),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _gorevControllers.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: theme.colorScheme.secondaryContainer,
                                  child: Text(
                                    (index + 1).toString(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _gorevControllers[index],
                                    decoration: const InputDecoration(
                                      labelText: 'Görevi',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                    validator: (val) => val == null || val.trim().isEmpty ? 'Gerekli' : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: _adSoyadControllers[index],
                                    decoration: const InputDecoration(
                                      labelText: 'Adı Soyadı',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                    validator: (val) => val == null || val.trim().isEmpty ? 'Gerekli' : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                  onPressed: () => _uyeSil(index),
                                  tooltip: 'Üyeyi Sil',
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _uyeEkle,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Yeni Üye Ekle'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            
            final List<KurulUyesiModel> list = [];
            for (int i = 0; i < _gorevControllers.length; i++) {
              list.add(KurulUyesiModel(
                siraNo: (i + 1).toString(),
                gorev: _gorevControllers[i].text.trim(),
                adSoyad: _adSoyadControllers[i].text.trim(),
              ));
            }
            widget.onSave(list);
            Navigator.pop(context);
          },
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}
