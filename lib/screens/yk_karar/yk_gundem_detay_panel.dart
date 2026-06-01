import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:universal_html/html.dart' as html;

import '../../models/birim_model.dart';
import '../../models/gundem_model.dart';
import '../../models/yk_karar_model.dart';
import '../../models/sistem_ayarlari_model.dart';
import '../../providers/gundem_provider.dart';
import '../../providers/yk_karar_provider.dart';
import '../../services/data_service.dart';
import '../../services/gundem_parser_service.dart';
import '../../services/pdf_service.dart';
import '../../services/belge_uretim_servisi.dart';

/// Yürütme Kurulu Gündem ve Karar Çalışma Alanı (Workspace).
/// Sol tarafta karar ayarları ve evrak ekleri yer alırken,
/// sağ tarafta canlı olarak A4 kağıt formatında karar önizlemesi sunulur.
class YkGundemDetayPanel extends StatefulWidget {
  const YkGundemDetayPanel({
    super.key,
    required this.onGoToToplantilar,
  });

  final VoidCallback onGoToToplantilar;

  @override
  State<YkGundemDetayPanel> createState() => _YkGundemDetayPanelState();
}

class _YkGundemDetayPanelState extends State<YkGundemDetayPanel> {
  bool _isImporting = false;
  String? _sonToplantiId;
  String? _seciliKararId;

  final _baslikController = TextEditingController();
  final _metinController = TextEditingController();
  final _noController = TextEditingController();
  final _tarihController = TextEditingController();
  String? _seciliBirimId;
  String? _seciliBirimAd;
  YkKararTuru? _seciliTur;
  YkKararDurum? _seciliDurum;

  final Map<String, int> _pdfGundemSayilari = {};
  final Set<String> _pdfYuklenenUrls = {};

  StreamSubscription<SistemAyarlariModel?>? _ayarlarSubscription;
  SistemAyarlariModel? _ayarlar;

  @override
  void initState() {
    super.initState();
    _baslikController.addListener(_onTextChanged);
    _metinController.addListener(_onTextChanged);
    _noController.addListener(_onTextChanged);
    _tarihController.addListener(_onTextChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<GundemProvider>();
      if (provider.seciliToplanti != null) {
        context.read<YkKararProvider>().toplantiSec(provider.seciliToplanti!.id);
      }
      _ayarlarSubscription = SistemAyarlariService().stream().listen((ayarlar) {
        if (mounted) {
          setState(() {
            _ayarlar = ayarlar;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _baslikController.dispose();
    _metinController.dispose();
    _noController.dispose();
    _tarihController.dispose();
    _ayarlarSubscription?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {}); // Canlı önizlemeyi yenile
  }

  void _kararSec(YkKararModel? karar) {
    if (karar == null) {
      _seciliKararId = null;
      _baslikController.text = '';
      _metinController.text = '';
      _noController.text = '';
      _tarihController.text = '';
      _seciliBirimId = null;
      _seciliBirimAd = null;
      _seciliTur = null;
      _seciliDurum = null;
      return;
    }
    _seciliKararId = karar.id;
    _baslikController.text = karar.baslik;
    _metinController.text = karar.kararMetni;
    _noController.text = karar.kararNo;
    _tarihController.text = karar.kararTarihi;
    _seciliBirimId = karar.birimId;
    _seciliBirimAd = karar.birimAd;
    _seciliTur = karar.tur;
    _seciliDurum = karar.durum;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<GundemProvider>();
    final ykProvider = context.watch<YkKararProvider>();
    final toplanti = provider.seciliToplanti;

    if (toplanti == null) {
      return _buildBosEkran(theme);
    }

    // Toplantı değiştiğinde kararları yeniden filtrele ve form alanlarını sıfırla
    if (toplanti.id != _sonToplantiId) {
      _sonToplantiId = toplanti.id;
      _seciliKararId = null;
      _kararSec(null);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<YkKararProvider>().toplantiSec(toplanti.id);
      });
    }

    final kararlar = ykProvider.kararlar;

    // Kararlar listesi yüklendiğinde ve henüz seçim yapılmadıysa ilk kararı seç
    if (kararlar.isNotEmpty && _seciliKararId == null) {
      _kararSec(kararlar.first);
    }

    return Scaffold(
      body: Column(
        children: [
          // ÜST BÖLÜM: Yüklenen PDF Dosyaları (Belgeler)
          _buildPdfDosyalariBar(toplanti, provider, theme),
          const Divider(height: 1, thickness: 1),

          // ANA GÖVDE: Sol Karar Ayarları - Sağ Canlı Önizleme
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sol Bölüm: Ayarlar Formu ve Karar Seçici
                      Expanded(
                        flex: 4,
                        child: _buildSolPanel(context, toplanti, kararlar, ykProvider, theme),
                      ),
                      const VerticalDivider(width: 1, thickness: 1),
                      // Sağ Bölüm: Canlı Karar Önizleme (A4)
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
                        _buildSolPanel(context, toplanti, kararlar, ykProvider, theme),
                        const SizedBox(height: 24),
                        _buildSagPanel(toplanti, theme),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Toplantı seçilmediğinde gösterilen boş ekran
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
              'Kararları canlı önizlemek ve düzenlemek için\nlütfen "Toplantılar" sekmesinden bir toplantı seçin.',
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

  /// Üst Bölüm: Toplantının yüklendiği PDF'leri gösteren küçük alan
  Widget _buildPdfDosyalariBar(
    ToplantiModel toplanti,
    GundemProvider provider,
    ThemeData theme,
  ) {
    if (toplanti.pdfUrls.isNotEmpty) {
      _pdfGundemSayilariniHesapla(toplanti.pdfUrls);
    }
    
    final ykProvider = context.read<YkKararProvider>();

    return Container(
      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.attachment_rounded, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Birimlerden Gelen Karar Belgeleri (PDF):',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: _isImporting ? null : () => _pdfDosyaSecVeYukle(context, toplanti.id, provider),
                icon: const Icon(Icons.upload_file_rounded, size: 16),
                label: const Text('Yeni Belge/PDF Yükle', style: TextStyle(fontSize: 12)),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _isImporting
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text('Belgeler işleniyor, lütfen bekleyiniz...', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (toplanti.pdfUrls.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Bu toplantıya eklenmiş herhangi bir PDF belgesi bulunmamaktadır.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      else
                        ...toplanti.pdfUrls.map((url) {
                          String fileName = 'Ek Belge.pdf';
                          try {
                            final uri = Uri.parse(url);
                            final decoded = Uri.decodeComponent(uri.pathSegments.last);
                            fileName = decoded.split('/').last;
                          } catch (_) {}

                          final count = _pdfGundemSayilari[url];
                          final countText = count != null
                              ? '$count Yürütme Kurulu Gündemi'
                              : 'Gündem sayısı hesaplanıyor...';

                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.only(right: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.6)),
                            ),
                            child: Container(
                              width: 320,
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 24),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              fileName,
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              countText,
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: theme.colorScheme.onSurfaceVariant,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => _pdfSilOnayDialog(context, toplanti.id, url, provider),
                                        tooltip: 'Belgeyi Sil',
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          if (kIsWeb) {
                                            html.window.open(url, '_blank');
                                          }
                                        },
                                        icon: const Icon(Icons.search_rounded, size: 16),
                                        label: const Text('Önizle'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                      Tooltip(
                                        message: 'Kararları Kontrol Et & YK Kararı Yaz',
                                        child: FilledButton.icon(
                                          onPressed: () => _pdfKararlariCikar(toplanti, provider, ykProvider, url),
                                          icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                                          label: const Text('Kararları Yaz', style: TextStyle(fontSize: 11)),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: theme.colorScheme.primary,
                                            foregroundColor: theme.colorScheme.onPrimary,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  /// Sol panel: Karar Listesi, Karar Seçimi ve Düzenleme Formu
  Widget _buildSolPanel(
    BuildContext context,
    ToplantiModel toplanti,
    List<YkKararModel> kararlar,
    YkKararProvider ykProvider,
    ThemeData theme,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Karar Seçim Alani
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Düzenlenecek Kararı Seçin',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (kararlar.isEmpty) ...[
                    Text(
                      'Bu toplantıya atanmış karar bulunmuyor.',
                      style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => _yeniKararOlustur(context, toplanti, ykProvider),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Yeni Karar Oluştur'),
                    ),
                  ] else
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _seciliKararId,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: kararlar.map((k) {
                              final label = k.kararNo.isNotEmpty
                                  ? 'Karar No: ${k.kararNo} - ${k.baslik}'
                                  : 'Taslak - ${k.baslik}';
                              return DropdownMenuItem(
                                value: k.id,
                                child: Text(
                                  label.length > 40 ? '${label.substring(0, 37)}...' : label,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (id) {
                              if (id != null) {
                                final karar = kararlar.firstWhere((k) => k.id == id);
                                setState(() {
                                  _kararSec(karar);
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.green),
                          tooltip: 'Yeni Karar Ekle',
                          onPressed: () => _yeniKararOlustur(context, toplanti, ykProvider),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Karar Parametre Düzenleme Formu
          if (_seciliKararId != null) ...[
            Text(
              'Karar Ayarları ve Manuel Müdahale',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _baslikController,
              decoration: const InputDecoration(
                labelText: 'Karar Başlığı',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _noController,
                    decoration: const InputDecoration(
                      labelText: 'Karar No',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _tarihController,
                    decoration: const InputDecoration(
                      labelText: 'Karar Tarihi',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<YkKararTuru>(
                    value: _seciliTur,
                    decoration: const InputDecoration(
                      labelText: 'Karar Türü',
                      border: OutlineInputBorder(),
                    ),
                    items: YkKararTuru.values.map((tur) {
                      return DropdownMenuItem(
                        value: tur,
                        child: Text(tur.displayName),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _seciliTur = val;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FutureBuilder<List<BirimModel>>(
                    future: BirimService().getAll(onlyActive: true),
                    builder: (context, snapshot) {
                      final list = snapshot.data ?? [];
                      String? currentVal;
                      if (list.any((b) => b.id == _seciliBirimId)) {
                        currentVal = _seciliBirimId;
                      }
                      return DropdownButtonFormField<String?>(
                        value: currentVal,
                        decoration: const InputDecoration(
                          labelText: 'Birim',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('Genel')),
                          ...list.map((b) => DropdownMenuItem<String?>(
                                value: b.id,
                                child: Text(b.kisaAd),
                              )),
                        ],
                        onChanged: (val) {
                          final birim = list.firstWhere((b) => b.id == val,
                              orElse: () => BirimModel(id: '', ad: '', kisaAd: 'Genel', tur: BirimTuru.merkez));
                          setState(() {
                            _seciliBirimId = val;
                            _seciliBirimAd = birim.ad;
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<YkKararDurum>(
              value: _seciliDurum,
              decoration: const InputDecoration(
                labelText: 'Karar Durumu',
                border: OutlineInputBorder(),
              ),
              items: YkKararDurum.values.map((durum) {
                return DropdownMenuItem(
                  value: durum,
                  child: Text(durum.displayName),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _seciliDurum = val;
                });
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Karar Metni (Manuel Müdahale Alanı):',
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _metinController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Resmi karar metnini giriniz...',
              ),
              maxLines: 12,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _kararKaydet(ykProvider),
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Değişiklikleri Kaydet'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _tekKararDocxIndir(context, toplanti),
                  icon: const Icon(Icons.description_rounded),
                  label: const Text('Word İndir'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                  tooltip: 'Kararı Tamamen Sil',
                  onPressed: () => _kararSilOnay(context, _seciliKararId!, ykProvider),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Sağ panel: A4 formatında jilet gibi canlı karar önizlemesi
  Widget _buildSagPanel(ToplantiModel toplanti, ThemeData theme) {
    if (_seciliKararId == null) {
      return Center(
        child: Text(
          'Önizlenecek aktif bir karar seçimi yapılmadı.',
          style: theme.textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic),
        ),
      );
    }

    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: _buildCanliOnizlemePaper(toplanti, theme),
          ),
        ),
      ),
    );
  }

  Widget _buildCanliOnizlemePaper(ToplantiModel toplanti, ThemeData theme) {
    final kurulUyeleri = _ayarlar?.kurulUyeleri ?? [];
    final baskanUye = kurulUyeleri.firstWhere(
      (u) => u.gorev.toLowerCase().contains('başkan') || u.gorev.toLowerCase().contains('baskan'),
      orElse: () => kurulUyeleri.isNotEmpty
          ? kurulUyeleri.first
          : const KurulUyesiModel(siraNo: '1', gorev: 'Başkan', adSoyad: ''),
    );
    final baskanAdi = baskanUye.adSoyad;

    return DefaultTextStyle(
      style: const TextStyle(
        fontFamily: 'Times New Roman',
        fontSize: 12,
        color: Colors.black,
        height: 1.4,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // T.C. Uşak Rektörlük Başlığı
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'T.C.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _ayarlar?.kurumAdiGuncel ?? 'UŞAK ÜNİVERSİTESİ',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                _ayarlar?.antetBasligiGuncel ?? 'DÖNER SERMAYE YÜRÜTME KURULU KARARLARI',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(height: 12),
            
            // Single-bordered table header block matching Word/PDF template (no divider)
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 0.8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TOPLANTI SAYISI: ${toplanti.toplantiNo}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'KARAR TARİHİ: ${_tarihController.text}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Preamble
            Text(
              "      Uşak Üniversitesi Döner Sermaye Yürütme Kurulu Rektör Yardımcısı $baskanAdi başkanlığında ${toplanti.toplantiTarihi} tarihinde saat 10:00' da toplandı. Gündem maddeleri görüşülerek aşağıdaki kararlar alındı.",
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 20),

            // Karar No & Metni
            Text(
              'KARAR ${_noController.text.isEmpty ? 'Taslak' : _noController.text}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              "      ${_metinController.text}",
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 24),

            const Center(
              child: Text(
                'Katılanların oy birliği ile karar verildi.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 24),

            // Signature Table
            _buildCanliSignatureTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildCanliSignatureTable() {
    final kurulUyeleri = _ayarlar?.kurulUyeleri ?? [];
    if (kurulUyeleri.isEmpty) return const SizedBox.shrink();

    return Table(
      border: TableBorder.all(color: Colors.black, width: 0.8),
      columnWidths: const {
        0: FixedColumnWidth(40),
        1: FixedColumnWidth(85),
        2: FlexColumnWidth(3),
        3: FixedColumnWidth(80),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade100),
          children: const [
            Padding(
              padding: EdgeInsets.all(6),
              child: Text('Sıra No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.black), textAlign: TextAlign.center),
            ),
            Padding(
              padding: EdgeInsets.all(6),
              child: Text('Görevi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.black), textAlign: TextAlign.center),
            ),
            Padding(
              padding: EdgeInsets.all(6),
              child: Text('Üyenin Adı Soyadı', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.black), textAlign: TextAlign.center),
            ),
            Padding(
              padding: EdgeInsets.all(6),
              child: Text('İmzası', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.black), textAlign: TextAlign.center),
            ),
          ],
        ),
        ...kurulUyeleri.map((uye) {
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(6),
                child: Text(uye.siraNo, style: const TextStyle(fontSize: 9, color: Colors.black), textAlign: TextAlign.center),
              ),
              Padding(
                padding: const EdgeInsets.all(6),
                child: Text(uye.gorev, style: const TextStyle(fontSize: 9, color: Colors.black)),
              ),
              Padding(
                padding: const EdgeInsets.all(6),
                child: Text(uye.adSoyad, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.black)),
              ),
              const Padding(
                padding: EdgeInsets.all(6),
                child: SizedBox(height: 22),
              ),
            ],
          );
        }),
      ],
    );
  }

  /// PDF dosya seçme ve yükleme işlemi
  Future<void> _pdfDosyaSecVeYukle(
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
    final name = result.files.first.name;
    if (bytes == null) return;

    setState(() => _isImporting = true);

    try {
      await provider.toplantiPdfYukle(toplantiId, name, bytes);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF belgesi başarıyla toplantıya eklendi.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Belge yükleme hatası: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  /// PDF Silme Onay Dialogu
  void _pdfSilOnayDialog(
    BuildContext context,
    String toplantiId,
    String url,
    GundemProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Belgeyi Sil'),
        content: const Text('Bu PDF belgesini toplantı eklerinden silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await provider.toplantiPdfSil(toplantiId, url);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  /// Yeni karar oluşturma tetikleyicisi
  void _yeniKararOlustur(
    BuildContext context,
    ToplantiModel toplanti,
    YkKararProvider ykProvider,
  ) async {
    final model = YkKararModel(
      id: '',
      toplantiId: toplanti.id,
      toplantiNo: toplanti.toplantiNo,
      kararNo: '',
      kararTarihi: toplanti.toplantiTarihi,
      birimId: '',
      birimAd: '',
      tur: YkKararTuru.danismanlik,
      baslik: 'Yeni Karar Taslağı',
      kararMetni: 'Yeni karara ait resmi metni buraya giriniz...',
      iliskiliKayitId: '',
    );
    final success = await ykProvider.kararOlustur(model);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yeni karar taslağı oluşturuldu.')),
      );
      setState(() {
        _seciliKararId = null; // Auto-select will choose the new one
      });
    }
  }

  /// Karar silme onay penceresi
  void _kararSilOnay(BuildContext context, String kararId, YkKararProvider ykProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kararı Sil'),
        content: const Text('Bu kararı tamamen silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ykProvider.kararSil(kararId);
              setState(() {
                _seciliKararId = null;
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _tekKararDocxIndir(BuildContext context, ToplantiModel toplanti) async {
    final kurulUyeleri = _ayarlar?.kurulUyeleri ?? [];
    final baskanUye = kurulUyeleri.firstWhere(
      (u) => u.gorev.toLowerCase().contains('başkan') || u.gorev.toLowerCase().contains('baskan'),
      orElse: () => kurulUyeleri.isNotEmpty
          ? kurulUyeleri.first
          : const KurulUyesiModel(siraNo: '1', gorev: 'Başkan', adSoyad: ''),
    );
    final baskanAdi = baskanUye.adSoyad;
    final kurumAdi = _ayarlar?.kurumAdiGuncel ?? 'UŞAK ÜNİVERSİTESİ';
    final antetBasligi = _ayarlar?.antetBasligiGuncel ?? 'DÖNER SERMAYE YÜRÜTME KURULU KARARLARI';

    final buffer = StringBuffer();
    buffer.writeln('T.C.');
    buffer.writeln(kurumAdi.toUpperCase());
    buffer.writeln(antetBasligi.toUpperCase());
    buffer.writeln();
    buffer.writeln('TOPLANTI SAYISI: ${toplanti.toplantiNo}   KARAR TARİHİ: ${toplanti.toplantiTarihi}');
    buffer.writeln();
    buffer.writeln("      Uşak Üniversitesi Döner Sermaye Yürütme Kurulu Rektör Yardımcısı $baskanAdi başkanlığında ${toplanti.toplantiTarihi} tarihinde saat 10:00' da toplandı. Gündem maddeleri görüşülerek aşağıdaki karar alındı.");
    buffer.writeln();
    buffer.writeln('KARAR ${_noController.text.isNotEmpty ? _noController.text : "Taslak"}');
    buffer.writeln('      ${_metinController.text}');
    buffer.writeln();
    buffer.writeln('Katılanların oy birliği ile karar verildi.');
    buffer.writeln();
    buffer.writeln('İMZA TABLOSU');
    buffer.writeln('─' * 80);
    buffer.writeln('Sıra No | Görevi | Üyenin Adı Soyadı | İmzası');
    buffer.writeln('─' * 80);
    for (final uye in kurulUyeleri) {
      buffer.writeln('${uye.siraNo} | ${uye.gorev} | ${uye.adSoyad} | İmza');
    }
    buffer.writeln('─' * 80);

    final bytes = BelgeUretimServisi.metindenDocxOlustur(buffer.toString());
    final kararAdi = _noController.text.isNotEmpty
        ? 'karar_${_noController.text.replaceAll('/', '_')}'
        : 'karar_taslak';

    await FileSaver.instance.saveFile(
      name: kararAdi,
      bytes: bytes,
      ext: 'docx',
      mimeType: MimeType.microsoftWord,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Karar Word (DOCX) olarak başarıyla indirildi.')),
      );
    }
  }

  /// Kararı kaydetme
  Future<void> _kararKaydet(YkKararProvider ykProvider) async {
    if (_seciliKararId == null) return;
    
    final success = await ykProvider.kararGuncelle(
      _seciliKararId!,
      _baslikController.text,
      _metinController.text,
      birimId: _seciliBirimId,
      birimAd: _seciliBirimAd,
      kararNo: _noController.text,
      kararTarihi: _tarihController.text,
      tur: _seciliTur,
      durum: _seciliDurum,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Karar başarıyla güncellendi.')),
      );
    }
  }

  /// PDF dosyasından kararları ve gündem maddelerini çıkarır.
  Future<void> _pdfKararlariCikar(
    ToplantiModel toplanti,
    GundemProvider provider,
    YkKararProvider ykProvider,
    String url,
  ) async {
    setState(() => _isImporting = true);

    // Show a loading snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('PDF belgesi analiz ediliyor ve kararlar çıkarılıyor...'),
          ],
        ),
        duration: Duration(days: 1), // Keep open until finished
      ),
    );

    try {
      final finalUrl = url;
      final bytes = await http.readBytes(Uri.parse(finalUrl));

      final (kararlar, gundemMaddeleri) = await GundemParserService().pdfToplantiyaKararVeGundemAktar(
        toplantiId: toplanti.id,
        toplantiNo: toplanti.toplantiNo,
        toplantiTarihi: toplanti.toplantiTarihi,
        pdfBytes: bytes,
      );

      if (gundemMaddeleri.isNotEmpty) {
        final mevcutMaddeler = List<GundemMaddesi>.from(toplanti.gundemMaddeleri);
        int startSira = mevcutMaddeler.length + 1;
        final yeniMaddeler = [
          ...mevcutMaddeler,
          ...gundemMaddeleri.asMap().entries.map((e) => e.value.copyWith(siraNo: startSira + e.key)),
        ];
        await provider.gundemMaddeleriGuncelle(toplanti.id, yeniMaddeler);
      }

      await ykProvider.kararlariYukle();

      ScaffoldMessenger.of(context).clearSnackBars();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${kararlar.length} adet karar ve gündem başarıyla çıkarıldı.'),
            backgroundColor: Colors.green,
          ),
        );

        // Auto-select the first decision
        if (ykProvider.kararlar.isNotEmpty) {
          setState(() {
            _kararSec(ykProvider.kararlar.first);
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).clearSnackBars();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Karar çıkarma hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  /// PDF içindeki Gündem/Karar sayısını asenkron hesaplar.
  Future<void> _pdfGundemSayilariniHesapla(List<String> urls) async {
    for (final url in urls) {
      if (_pdfGundemSayilari.containsKey(url) || _pdfYuklenenUrls.contains(url)) {
        continue;
      }
      _pdfYuklenenUrls.add(url);

      try {
        final finalUrl = url;
        final bytes = await http.readBytes(Uri.parse(finalUrl));
        final document = PdfDocument(inputBytes: bytes);
        final textExtractor = PdfTextExtractor(document);
        final text = textExtractor.extractText();
        document.dispose();

        final regex = RegExp(r'Gündem\s+\d{1,2}\s*:', caseSensitive: false);
        final matches = regex.allMatches(text);
        final count = matches.isEmpty ? 1 : matches.length;

        if (mounted) {
          setState(() {
            _pdfGundemSayilari[url] = count;
          });
        }
      } catch (e) {
        debugPrint('PDF gundem sayisi hesaplama hatasi ($url): $e');
        if (mounted) {
          setState(() {
            _pdfGundemSayilari[url] = 1; // Default fallback
          });
        }
      }
    }
  }
}
