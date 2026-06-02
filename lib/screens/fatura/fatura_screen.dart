import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../core/turkce_format.dart';
import '../../models/birim_model.dart';
import '../../models/fatura_model.dart';
import '../../providers/fatura_provider.dart';
import '../../services/data_service.dart';
import '../../services/pdf_service.dart';

/// Otomatik Fatura Basım / PDF Önizleme ekranı.
class FaturaScreen extends StatefulWidget {
  const FaturaScreen({super.key, this.embedded = false});

  /// Dashboard içine embed edildiğinde AppBar gösterilmez.
  final bool embedded;

  @override
  State<FaturaScreen> createState() => _FaturaScreenState();
}

class _FaturaScreenState extends State<FaturaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _metinController = TextEditingController();
  String? _secilenBirimId;
  String? _secilenBirimAd;
  String? _secilenPdfAdi;
  FaturaModel? _geciciFatura;
  bool _arkaPlanGoster = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FaturaProvider>().faturalariYukle();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _metinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<FaturaProvider>();

    if (provider.seciliFatura == null) {
      _geciciFatura = null;
    } else if (_geciciFatura == null || _geciciFatura!.id != provider.seciliFatura!.id) {
      _geciciFatura = provider.seciliFatura;
    }

    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text('Fatura Basım'),
              bottom: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    text: 'Kuyruk (${provider.kuyrukSayisi})',
                    icon: const Icon(Icons.queue),
                  ),
                  const Tab(text: 'Tümü', icon: Icon(Icons.list)),
                  const Tab(text: 'Toplu Yükle', icon: Icon(Icons.upload_file)),
                ],
              ),
            ),
      body: Row(
        children: [
          // Sol panel: Düzenleme Formu veya Fatura Listeleri
          Expanded(
            flex: provider.seciliFatura != null ? 1 : 2,
            child: provider.seciliFatura != null
                ? _buildFaturaDuzenleForm(provider, theme)
                : Column(
                    children: [
                      if (widget.embedded) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Text('Fatura Basım',
                              style: Theme.of(context).textTheme.headlineSmall),
                        ),
                        TabBar(
                          controller: _tabController,
                          tabs: [
                            Tab(
                              text: 'Kuyruk (${provider.kuyrukSayisi})',
                              icon: const Icon(Icons.queue),
                            ),
                            const Tab(text: 'Tümü', icon: Icon(Icons.list)),
                            const Tab(
                                text: 'Toplu Yükle', icon: Icon(Icons.upload_file)),
                          ],
                        ),
                      ],
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildKuyrukTab(provider, theme),
                            _buildTumFaturalarTab(provider, theme),
                            _buildTopluYukleTab(provider, theme),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          // Sağ panel: PDF Önizleme
          if (provider.seciliFatura != null) ...[
            const VerticalDivider(width: 1),
            Expanded(
              flex: 1,
              child: _buildPdfOnizlemePanel(provider, theme),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pdfSecVeAyristir(FaturaProvider provider) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;
    final secilen = result.files.first;
    final bytes = secilen.bytes;
    if (bytes == null) return;

    if (mounted) {
      setState(() {
        _secilenPdfAdi = secilen.name;
      });
    }

    await provider.pdfdenAyristir(bytes);

    if (!mounted) return;
    final message = provider.hataMesaji ??
        '${provider.parseSonuclari.length} kayıt PDF üzerinden ayrıştırıldı.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            provider.hataMesaji == null ? null : Theme.of(context).colorScheme.error,
      ),
    );
  }

  /// Fatura kuyruğu — bekleyen faturaları sırasıyla işler.
  Widget _buildKuyrukTab(FaturaProvider provider, ThemeData theme) {
    if (provider.kuyruk.isEmpty) {
      if (provider.hasMore) {
        return Center(
          child: _buildPaginationFooter(
            onPressed: provider.dahaFazlaYukle,
            isLoading: provider.isLoadingMore,
          ),
        );
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text('Bekleyen fatura yok.', style: theme.textTheme.bodyLarge),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.kuyruk.length + (provider.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= provider.kuyruk.length) {
          return _buildPaginationFooter(
            onPressed: provider.dahaFazlaYukle,
            isLoading: provider.isLoadingMore,
          );
        }
        final fatura = provider.kuyruk[index];
        return _buildFaturaKart(fatura, provider, theme, isKuyruk: true);
      },
    );
  }

  /// Tüm faturalar listesi.
  Widget _buildTumFaturalarTab(FaturaProvider provider, ThemeData theme) {
    if (provider.faturalar.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text('Fatura bulunamadı.', style: theme.textTheme.bodyLarge),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.faturalar.length + (provider.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= provider.faturalar.length) {
          return _buildPaginationFooter(
            onPressed: provider.dahaFazlaYukle,
            isLoading: provider.isLoadingMore,
          );
        }
        final fatura = provider.faturalar[index];
        return _buildFaturaKart(fatura, provider, theme);
      },
    );
  }

  Widget _buildPaginationFooter({
    required Future<void> Function() onPressed,
    required bool isLoading,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      child: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : OutlinedButton.icon(
                onPressed: () {
                  onPressed();
                },
                icon: const Icon(Icons.expand_more),
                label: const Text('20 kayıt daha yükle'),
              ),
      ),
    );
  }

  /// Toplu metin yükleme ve ayrıştırma.
  Widget _buildTopluYukleTab(FaturaProvider provider, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Fatura Metin Ayrıştırma',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Birimlerden gelen fatura taleplerini yapıştırın. '
            'Sistem metni otomatik olarak ayrıştıracaktır.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pdfSecVeAyristir(provider),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF Yükle ve Ayrıştır'),
                ),
              ),
            ],
          ),
          if (_secilenPdfAdi != null) ...[
            const SizedBox(height: 6),
            Text(
              'Seçili PDF: $_secilenPdfAdi',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              'Üst yazı kısmı otomatik atlanır, fatura alanları çıkarılır.',
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          // Birim seçimi
          FutureBuilder<List<BirimModel>>(
            future: BirimService().getAll(onlyActive: true),
            builder: (context, snapshot) {
              final list = snapshot.data ?? [];
              
              String? currentValue;
              if (_secilenBirimId != null && list.any((b) => b.id == _secilenBirimId)) {
                currentValue = _secilenBirimId;
              } else if (list.isNotEmpty && _secilenBirimId == null) {
                currentValue = list.first.id;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _secilenBirimId == null) {
                    setState(() {
                      _secilenBirimId = list.first.id;
                      _secilenBirimAd = list.first.ad;
                    });
                  }
                });
              }

              return DropdownButtonFormField<String>(
                value: currentValue,
                decoration: InputDecoration(
                  labelText: 'Birim',
                  prefixIcon: const Icon(Icons.business_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: list.map((b) => DropdownMenuItem<String>(
                      value: b.id,
                      child: Text('${b.kisaAd} - ${b.ad}'),
                    )).toList(),
                onChanged: (value) {
                  if (value != null) {
                    final selected = list.firstWhere((b) => b.id == value);
                    setState(() {
                      _secilenBirimId = value;
                      _secilenBirimAd = selected.ad;
                    });
                  }
                },
              );
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _metinController,
            maxLines: 10,
            decoration: InputDecoration(
              hintText: 'Firma: ABC Ltd.\nHizmet: Tahlil\nTutar: 1.500,00\n\n'
                  'Firma: XYZ A.Ş.\nHizmet: Analiz\nTutar: 2.300,00',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    await provider.metinAyristir(_metinController.text);
                  },
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text('Ayrıştır'),
                ),
              ),
              const SizedBox(width: 8),
              if (provider.parseSonuclari.isNotEmpty)
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: (_secilenBirimId == null || _secilenBirimId!.isEmpty)
                        ? null
                        : () {
                            provider.topluFaturaOlustur(
                              birimId: _secilenBirimId!,
                              birimAd: _secilenBirimAd!,
                            );
                            _metinController.clear();
                          },
                    icon: const Icon(Icons.save),
                    label: Text(
                        '${provider.parseSonuclari.length} Fatura Oluştur'),
                  ),
                ),
            ],
          ),
          if (provider.parseSonuclari.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            Text(
              'Ayrıştırma Sonuçları (${provider.parseSonuclari.length} fatura)',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ...provider.parseSonuclari.map((sonuc) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(sonuc.firmaUnvan),
                    subtitle: Text(
                      '${sonuc.hizmetDetay}\n'
                      'Kalem Sayısı: ${sonuc.kalemler.length}\n'
                      'Numune No: ${sonuc.numuneNo ?? '-'} | '
                      'MELBES Başvuru No: ${sonuc.melbesBasvuruNo ?? '-'}',
                    ),
                    isThreeLine: true,
                    trailing: Text(
                      TurkceFormat.para(sonuc.tutar),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildFaturaKart(
    FaturaModel fatura,
    FaturaProvider provider,
    ThemeData theme, {
    bool isKuyruk = false,
  }) {
    final isSecili = provider.seciliFatura?.id == fatura.id;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isSecili ? theme.colorScheme.primaryContainer : null,
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
                        fatura.firmaUnvan,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        fatura.hizmetDetay,
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Numune No: ${fatura.numuneNo ?? '-'} | MELBES: ${fatura.melbesBasvuruNo ?? '-'}',
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Kalem: ${fatura.kalemler.length}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      TurkceFormat.para(fatura.toplamTutar),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Chip(
                      label: Text(
                        fatura.durum.displayName,
                        style: const TextStyle(fontSize: 11),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
            if (isKuyruk) ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => provider.faturaSecme(fatura),
                    icon: const Icon(Icons.preview, size: 16),
                    label: const Text('Önizle'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () async {
                      final pdfBytes =
                          await PdfService.matbuFaturaUret(fatura);
                      if (!context.mounted) return;
                      final printer =
                          await Printing.pickPrinter(context: context);
                      if (printer == null) return;
                      await Printing.directPrintPdf(
                        printer: printer,
                        onLayout: (_) async => pdfBytes,
                      );
                      provider.basildiIsaretle(fatura.id);
                    },
                    icon: const Icon(Icons.print, size: 16),
                    label: const Text('Yazdır'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// PDF Önizleme paneli — seçili faturanın gerçek PDF çıktısını gösterir.
  Widget _buildPdfOnizlemePanel(FaturaProvider provider, ThemeData theme) {
    if (_geciciFatura == null) return const SizedBox();
    return Column(
      children: [
        // Önizleme başlık çubuğu
        Container(
          padding: const EdgeInsets.all(12),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              const Icon(Icons.picture_as_pdf, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'PDF Önizleme: ${_geciciFatura!.firmaUnvan}',
                  style: theme.textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Şablonu Göster', style: TextStyle(fontSize: 12)),
                  Switch(
                    value: _arkaPlanGoster,
                    onChanged: (val) {
                      setState(() {
                        _arkaPlanGoster = val;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.print, size: 20),
                onPressed: () async {
                  final pdfBytes = await PdfService.matbuFaturaUret(_geciciFatura!, arkaPlanGoster: false);
                  if (!context.mounted) return;
                  await Printing.layoutPdf(
                    onLayout: (_) async => pdfBytes,
                  );
                },
                tooltip: 'Yazdır',
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () {
                  provider.faturaSecme(_geciciFatura!); // Toggle off
                  setState(() {
                    _geciciFatura = null;
                  });
                },
                tooltip: 'Kapat',
              ),
            ],
          ),
        ),
        // Gerçek PDF önizleme
        Expanded(
          child: PdfPreview(
            build: (_) => PdfService.matbuFaturaUret(_geciciFatura!, arkaPlanGoster: _arkaPlanGoster),
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
            allowPrinting: false, // Print only using our top-bar button which excludes background
            allowSharing: false,
          ),
        ),
      ],
    );
  }

  /// Manuel Düzenleme Formu
  Widget _buildFaturaDuzenleForm(FaturaProvider provider, ThemeData theme) {
    if (_geciciFatura == null) return const SizedBox();

    return ListView(
      key: ValueKey('form_${_geciciFatura!.id}'),
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Fatura Bilgilerini Düzenle', style: theme.textTheme.titleMedium),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                provider.faturaSecme(_geciciFatura!); // Toggle off
                setState(() {
                  _geciciFatura = null;
                });
              },
            ),
          ],
        ),
        const Divider(),
        const SizedBox(height: 8),

        // Firma Ünvanı
        TextFormField(
          key: ValueKey('firma_${_geciciFatura!.id}'),
          initialValue: _geciciFatura!.firmaUnvan,
          decoration: const InputDecoration(
            labelText: 'Firma Ünvanı',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.business),
          ),
          onChanged: (val) {
            setState(() {
              _geciciFatura = _geciciFatura!.copyWith(firmaUnvan: val);
            });
          },
        ),
        const SizedBox(height: 12),

        // Seri ve Sıra No
        Row(
          children: [
            Expanded(
              child: TextFormField(
                key: ValueKey('seri_${_geciciFatura!.id}'),
                initialValue: _geciciFatura!.seriNo ?? '',
                decoration: const InputDecoration(
                  labelText: 'Seri No',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  setState(() {
                    _geciciFatura = _geciciFatura!.copyWith(seriNo: val.isEmpty ? null : val);
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                key: ValueKey('sira_${_geciciFatura!.id}'),
                initialValue: _geciciFatura!.siraNo ?? '',
                decoration: const InputDecoration(
                  labelText: 'Sıra No',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  setState(() {
                    _geciciFatura = _geciciFatura!.copyWith(siraNo: val.isEmpty ? null : val);
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Fatura Tarihi
        TextFormField(
          key: ValueKey('tarih_${_geciciFatura!.id}'),
          initialValue: _geciciFatura!.faturaTarihi ?? '',
          decoration: const InputDecoration(
            labelText: 'Fatura Tarihi',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.calendar_today),
          ),
          onChanged: (val) {
            setState(() {
              _geciciFatura = _geciciFatura!.copyWith(faturaTarihi: val.isEmpty ? null : val);
            });
          },
        ),
        const SizedBox(height: 12),

        // MELBES Başvuru No
        TextFormField(
          key: ValueKey('melbes_${_geciciFatura!.id}'),
          initialValue: _geciciFatura!.melbesBasvuruNo ?? '',
          decoration: const InputDecoration(
            labelText: 'MELBES Başvuru No',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.confirmation_number),
          ),
          onChanged: (val) {
            setState(() {
              _geciciFatura = _geciciFatura!.copyWith(melbesBasvuruNo: val.isEmpty ? null : val);
            });
          },
        ),
        const SizedBox(height: 12),

        // Numune No
        TextFormField(
          key: ValueKey('numune_${_geciciFatura!.id}'),
          initialValue: _geciciFatura!.numuneNo ?? '',
          decoration: const InputDecoration(
            labelText: 'Numune No',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.science),
          ),
          onChanged: (val) {
            setState(() {
              _geciciFatura = _geciciFatura!.copyWith(numuneNo: val.isEmpty ? null : val);
            });
          },
        ),
        const SizedBox(height: 16),

        Text('Fatura Kalemleri', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),

        // Kalemler Listesi
        ..._geciciFatura!.kalemler.asMap().entries.map((entry) {
          final idx = entry.key;
          final kalem = entry.value;

          return Card(
            key: ValueKey('kalem_${_geciciFatura!.id}_$idx'),
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          initialValue: kalem.aciklama,
                          decoration: const InputDecoration(
                            labelText: 'Açıklama',
                            isDense: true,
                          ),
                          onChanged: (val) {
                            _updateKalem(idx, aciklama: val);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _deleteKalem(idx);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: '${kalem.adet}',
                          decoration: const InputDecoration(
                            labelText: 'Adet',
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (val) {
                            final adet = int.tryParse(val) ?? 1;
                            _updateKalem(idx, adet: adet);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: '${kalem.birimFiyat}',
                          decoration: const InputDecoration(
                            labelText: 'Birim Fiyat',
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (val) {
                            final fiyat = double.tryParse(val) ?? 0.0;
                            _updateKalem(idx, birimFiyat: fiyat);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tutar:\n${TurkceFormat.para(kalem.tutar)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),

        OutlinedButton.icon(
          onPressed: _addKalem,
          icon: const Icon(Icons.add),
          label: const Text('Yeni Kalem Ekle'),
        ),
        const SizedBox(height: 20),

        // Toplam Özet
        Card(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildSummaryRow('Ara Toplam', TurkceFormat.para(_geciciFatura!.tutar)),
                _buildSummaryRow('KDV (%${_geciciFatura!.kdvOrani.toInt()})', TurkceFormat.para(_geciciFatura!.kdvTutar)),
                const Divider(),
                _buildSummaryRow('Genel Toplam', TurkceFormat.para(_geciciFatura!.toplamTutar), bold: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // İşlem Butonları
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  provider.faturaSecme(_geciciFatura!); // Toggle off
                  setState(() {
                    _geciciFatura = null;
                  });
                },
                child: const Text('İptal'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () async {
                  final ok = await provider.faturaGuncelle(
                    _geciciFatura!.id,
                    _geciciFatura!.toMap(),
                  );
                  if (ok && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fatura güncellendi.')),
                    );
                  }
                },
                icon: const Icon(Icons.save),
                label: const Text('Kaydet'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  void _recalculateTotals(List<FaturaKalem> kalemler) {
    final araToplam = kalemler.fold<double>(0.0, (sum, item) => sum + item.tutar);
    final kdvTutar = araToplam * (_geciciFatura!.kdvOrani / 100);
    final toplamTutar = araToplam + kdvTutar;

    setState(() {
      _geciciFatura = _geciciFatura!.copyWith(
        kalemler: kalemler,
        tutar: araToplam,
        kdvTutar: kdvTutar,
        toplamTutar: toplamTutar,
        hizmetDetay: kalemler.isNotEmpty ? kalemler.first.aciklama : '',
      );
    });
  }

  void _updateKalem(int index, {String? aciklama, int? adet, double? birimFiyat}) {
    final list = List<FaturaKalem>.from(_geciciFatura!.kalemler);
    final old = list[index];
    final newAdet = adet ?? old.adet;
    final newFiyat = birimFiyat ?? old.birimFiyat;

    list[index] = FaturaKalem(
      aciklama: aciklama ?? old.aciklama,
      adet: newAdet,
      birimFiyat: newFiyat,
      tutar: newAdet * newFiyat,
    );
    _recalculateTotals(list);
  }

  void _addKalem() {
    final list = List<FaturaKalem>.from(_geciciFatura!.kalemler);
    list.add(const FaturaKalem(
      aciklama: 'Yeni Analiz/Hizmet Kalemi',
      adet: 1,
      birimFiyat: 0.0,
      tutar: 0.0,
    ));
    _recalculateTotals(list);
  }

  void _deleteKalem(int index) {
    final list = List<FaturaKalem>.from(_geciciFatura!.kalemler);
    list.removeAt(index);
    _recalculateTotals(list);
  }

  Widget _buildSummaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
