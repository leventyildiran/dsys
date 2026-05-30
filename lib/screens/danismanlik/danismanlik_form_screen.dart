import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/hesaplama_motoru.dart';
import '../../core/karar_metni_servisi.dart';
import '../../core/turkce_format.dart';
import '../../models/danismanlik_model.dart';
import '../../models/personel_model.dart';
import '../../providers/danismanlik_provider.dart';
import '../../theme.dart';

/// Danışmanlık taksit formu + canlı önizleme ekranı.
///
/// Web'de yan yana (form | önizleme), mobilde sekmeli görünüm.
class DanismanlikFormScreen extends StatelessWidget {
  const DanismanlikFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DanismanlikProvider(),
      child: const _FormBody(),
    );
  }
}

class _FormBody extends StatelessWidget {
  const _FormBody();

  @override
  Widget build(BuildContext context) {
    final isWide =
        MediaQuery.of(context).size.width >= DSYSTheme.breakpointDesktop;

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(flex: 5, child: _FormPanel()),
          const VerticalDivider(width: 1),
          Expanded(flex: 5, child: _OnizlemePanel()),
        ],
      );
    }

    // Mobil: sekmeli
    return const DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(tabs: [
            Tab(text: 'Form'),
            Tab(text: 'Önizleme'),
          ]),
          Expanded(
            child: TabBarView(
              children: [
                _FormPanel(),
                _OnizlemePanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SOL PANEL: FORM
// ─────────────────────────────────────────────────────────────

class _FormPanel extends StatelessWidget {
  const _FormPanel();

  @override
  Widget build(BuildContext context) {
    final provider = context.read<DanismanlikProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DSYSTheme.paddingSayfa),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: DSYSTheme.formMaxWidth / 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Danışmanlık Taksit Formu',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: DSYSTheme.spacingL),

            // Danışmanlık Türü
            _SectionTitle(title: 'Danışmanlık Türü'),
            const SizedBox(height: DSYSTheme.spacingS),
            Selector<DanismanlikProvider, DanismanlikTuru>(
              selector: (_, p) => p.tur,
              builder: (_, tur, __) => SegmentedButton<DanismanlikTuru>(
                segments: const [
                  ButtonSegment(
                    value: DanismanlikTuru.standart,
                    label: Text('Standart'),
                    icon: Icon(Icons.description_outlined),
                  ),
                  ButtonSegment(
                    value: DanismanlikTuru.sanayiIsbirligi58k,
                    label: Text('Sanayi 58/k'),
                    icon: Icon(Icons.factory_outlined),
                  ),
                ],
                selected: {tur},
                onSelectionChanged: (s) => provider.setTur(s.first),
              ),
            ),
            const SizedBox(height: DSYSTheme.spacingL),

            // Firma & Konu
            _SectionTitle(title: 'Firma ve İş Bilgileri'),
            const SizedBox(height: DSYSTheme.spacingS),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Firma Ünvanı',
                hintText: 'Örn: Orhan Şaşmaz Tekstil Ltd. Şti.',
              ),
              onChanged: provider.setFirmaUnvan,
            ),
            const SizedBox(height: DSYSTheme.spacingM),
            TextField(
              decoration: const InputDecoration(
                labelText: 'İşin Konusu',
                hintText: 'Örn: Tasarım danışmanlığı, ürün geliştirme',
              ),
              maxLines: 2,
              onChanged: provider.setIsinKonusu,
            ),
            const SizedBox(height: DSYSTheme.spacingL),

            // Tutar & KDV
            _SectionTitle(title: 'Tutar Bilgileri'),
            const SizedBox(height: DSYSTheme.spacingS),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Brüt Taksit Tutarı (KDV Dahil)',
                      suffixText: '₺',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[\d.,]')),
                    ],
                    onChanged: (v) {
                      final parsed =
                          double.tryParse(v.replaceAll(',', '.')) ?? 0;
                      provider.setBrutTaksitTutari(parsed);
                    },
                  ),
                ),
                const SizedBox(width: DSYSTheme.spacingM),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'KDV %',
                    ),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: '20'),
                    onChanged: (v) {
                      provider.setKdvOrani(int.tryParse(v) ?? 20);
                    },
                  ),
                ),
                const SizedBox(width: DSYSTheme.spacingM),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Süre (ay)',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      provider.setSuresi(int.tryParse(v) ?? 1);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: DSYSTheme.spacingL),

            // Kesinti Oranları (standart türde)
            Selector<DanismanlikProvider, DanismanlikTuru>(
              selector: (_, p) => p.tur,
              builder: (_, tur, __) {
                if (tur != DanismanlikTuru.standart) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: DSYSTheme.spacingL),
                    child: Card(
                      color: Theme.of(context)
                          .colorScheme
                          .secondaryContainer
                          .withAlpha(100),
                      child: const Padding(
                        padding: EdgeInsets.all(DSYSTheme.paddingKart),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Sanayi İşbirliği (58/k) türünde Hazine, BAP '
                                've Araç-Gereç kesintisi uygulanmaz. '
                                'Doğrudan %85 dağıtılır.',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(title: 'Kesinti Oranları (%)'),
                    const SizedBox(height: DSYSTheme.spacingS),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Hazine',
                            ),
                            keyboardType: TextInputType.number,
                            controller: TextEditingController(text: '1'),
                            onChanged: (v) => provider
                                .setHazinePayiOrani(int.tryParse(v) ?? 1),
                          ),
                        ),
                        const SizedBox(width: DSYSTheme.spacingM),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'BAP',
                            ),
                            keyboardType: TextInputType.number,
                            controller: TextEditingController(text: '5'),
                            onChanged: (v) =>
                                provider.setBapPayiOrani(int.tryParse(v) ?? 5),
                          ),
                        ),
                        const SizedBox(width: DSYSTheme.spacingM),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Araç-Gereç',
                            ),
                            keyboardType: TextInputType.number,
                            controller: TextEditingController(text: '45'),
                            onChanged: (v) => provider
                                .setAracGerecPayiOrani(int.tryParse(v) ?? 45),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: DSYSTheme.spacingL),
                  ],
                );
              },
            ),

            // Evrak Bilgileri
            _SectionTitle(title: 'Evrak & Karar Bilgileri'),
            const SizedBox(height: DSYSTheme.spacingS),
            TextField(
              decoration: const InputDecoration(labelText: 'Birim Adı'),
              onChanged: provider.setBirimAd,
            ),
            const SizedBox(height: DSYSTheme.spacingM),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Birim Evrak Tarihi',
                      hintText: '20.04.2026',
                    ),
                    onChanged: provider.setBirimEvrakTarihi,
                  ),
                ),
                const SizedBox(width: DSYSTheme.spacingM),
                Expanded(
                  child: TextField(
                    decoration:
                        const InputDecoration(labelText: 'Birim Evrak Sayısı'),
                    onChanged: provider.setBirimEvrakSayisi,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DSYSTheme.spacingM),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration:
                        const InputDecoration(labelText: 'Birim Kurul Tarihi'),
                    onChanged: provider.setBirimKurulTarihi,
                  ),
                ),
                const SizedBox(width: DSYSTheme.spacingM),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                        labelText: 'Birim Toplantı Sayısı'),
                    onChanged: provider.setBirimToplantiSayisi,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DSYSTheme.spacingM),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration:
                        const InputDecoration(labelText: 'Birim Karar No'),
                    onChanged: provider.setBirimKararNo,
                  ),
                ),
                const SizedBox(width: DSYSTheme.spacingM),
                Expanded(
                  child: TextField(
                    decoration:
                        const InputDecoration(labelText: 'YK Karar Tarihi'),
                    onChanged: provider.setYkKararTarihi,
                  ),
                ),
                const SizedBox(width: DSYSTheme.spacingM),
                Expanded(
                  child: TextField(
                    decoration:
                        const InputDecoration(labelText: 'YK Karar No'),
                    onChanged: provider.setYkKararNo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DSYSTheme.spacingL),

            // Personel Ataması
            _SectionTitle(title: 'Görevli Personel'),
            const SizedBox(height: DSYSTheme.spacingS),
            const _PersonelListesi(),
            const SizedBox(height: DSYSTheme.spacingM),
            OutlinedButton.icon(
              onPressed: () => _personelEkleDialog(context),
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Personel Ekle'),
            ),
            const SizedBox(height: DSYSTheme.spacingXL),
          ],
        ),
      ),
    );
  }

  void _personelEkleDialog(BuildContext context) {
    final provider = context.read<DanismanlikProvider>();
    final adController = TextEditingController();
    final unvanController = TextEditingController();
    final katsayiController = TextEditingController(text: '2.00');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Personel Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: adController,
              decoration: const InputDecoration(labelText: 'Ad Soyad'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: unvanController,
              decoration:
                  const InputDecoration(labelText: 'Ünvan (Öğr. Gör. Dr.)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: katsayiController,
              decoration:
                  const InputDecoration(labelText: 'Ünvan Katsayısı'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              final personel = PersonelModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                tcKimlikNo: '',
                adSoyad: adController.text,
                unvan: unvanController.text,
                unvanKatsayisi: double.tryParse(
                        katsayiController.text.replaceAll(',', '.')) ??
                    2.0,
                birimId: '',
              );
              provider.personelEkle(personel);
              Navigator.of(ctx).pop();
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }
}

class _PersonelListesi extends StatelessWidget {
  const _PersonelListesi();

  @override
  Widget build(BuildContext context) {
    return Selector<DanismanlikProvider, List<PersonelGorevAtama>>(
      selector: (_, p) => p.personeller,
      builder: (context, personeller, _) {
        if (personeller.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(DSYSTheme.paddingKart),
              child: Row(
                children: [
                  Icon(Icons.people_outline,
                      color: Theme.of(context).colorScheme.outline),
                  const SizedBox(width: 12),
                  const Text('Henüz personel atanmadı'),
                ],
              ),
            ),
          );
        }

        final provider = context.read<DanismanlikProvider>();
        return Column(
          children: List.generate(personeller.length, (i) {
            final atama = personeller[i];
            return Card(
              margin: const EdgeInsets.only(bottom: DSYSTheme.spacingS),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${atama.personel.unvan} ${atama.personel.adSoyad}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Katsayı: ${TurkceFormat.katsayi(atama.personel.unvanKatsayisi)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Faaliyet Puanı',
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) {
                          provider.personelPuanGuncelle(
                            i,
                            double.tryParse(v.replaceAll(',', '.')) ?? 0,
                          );
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => provider.personelCikar(i),
                      color: DSYSTheme.hataKirmizisi,
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SAĞ PANEL: CANLI ÖNİZLEME
// ─────────────────────────────────────────────────────────────

class _OnizlemePanel extends StatelessWidget {
  const _OnizlemePanel();

  @override
  Widget build(BuildContext context) {
    return Selector<DanismanlikProvider, OnizlemeSonucu?>(
      selector: (_, p) => p.onizleme,
      builder: (context, onizleme, _) {
        if (onizleme == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.preview_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: DSYSTheme.spacingM),
                Text(
                  'Tutarı girdikçe burada\ncanlı önizleme göreceksiniz',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(DSYSTheme.paddingSayfa),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kesinti Tablosu
              _KesintiBilgiKarti(kesinti: onizleme.kesinti),
              const SizedBox(height: DSYSTheme.spacingL),

              // Katsayı & Artık Bakiye
              if (onizleme.katsayi > 0) ...[
                _KatsayiKarti(
                  katsayi: onizleme.katsayi,
                  artikBakiye: onizleme.artikBakiye,
                ),
                const SizedBox(height: DSYSTheme.spacingL),
              ],

              // Personel Dağıtım Tablosu
              if (onizleme.personelDagitimlari.isNotEmpty) ...[
                _PersonelDagitimTablosu(
                    dagitimlar: onizleme.personelDagitimlari),
                const SizedBox(height: DSYSTheme.spacingL),
              ],

              // Şablon Doğrulama Durumu
              _SablonDurumuKarti(dogrulama: onizleme.sablonDogrulama),
              const SizedBox(height: DSYSTheme.spacingL),

              // Karar Metni Önizleme
              _KararMetniOnizleme(metin: onizleme.kararMetni),
            ],
          ),
        );
      },
    );
  }
}

// ─── Önizleme alt widget'ları ────────────────────────────────

class _KesintiBilgiKarti extends StatelessWidget {
  const _KesintiBilgiKarti({required this.kesinti});
  final KesintiBilgisi kesinti;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DSYSTheme.paddingKart),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calculate_outlined, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Kesinti Tablosu',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: DSYSTheme.spacingM),
            _SatirBilgi(label: 'KDV Hariç Matrah', tutar: kesinti.kdvHaricMatrah),
            _SatirBilgi(
              label: 'Hazine Payı',
              tutar: kesinti.hazinePayi,
              renk: DSYSTheme.hataKirmizisi,
              negatif: true,
            ),
            _SatirBilgi(
              label: 'BAP Payı',
              tutar: kesinti.bapPayi,
              renk: DSYSTheme.hataKirmizisi,
              negatif: true,
            ),
            _SatirBilgi(
              label: 'Araç-Gereç Payı',
              tutar: kesinti.aracGerecPayi,
              renk: DSYSTheme.hataKirmizisi,
              negatif: true,
            ),
            const Divider(),
            _SatirBilgi(
              label: 'Dağıtılabilir Tutar',
              tutar: kesinti.dagitilabilirTutar,
              renk: DSYSTheme.onayYesili,
              kalin: true,
            ),
            if (kesinti.birimKalani != null)
              _SatirBilgi(
                label: 'Birim Kalanı (%15)',
                tutar: kesinti.birimKalani!,
              ),
          ],
        ),
      ),
    );
  }
}

class _SatirBilgi extends StatelessWidget {
  const _SatirBilgi({
    required this.label,
    required this.tutar,
    this.renk,
    this.negatif = false,
    this.kalin = false,
  });

  final String label;
  final double tutar;
  final Color? renk;
  final bool negatif;
  final bool kalin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '${negatif ? "- " : ""}${TurkceFormat.para(tutar)}',
            style: TextStyle(
              color: renk ?? DSYSTheme.paraRengi,
              fontWeight: kalin ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _KatsayiKarti extends StatelessWidget {
  const _KatsayiKarti({required this.katsayi, required this.artikBakiye});
  final double katsayi;
  final double artikBakiye;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DSYSTheme.paddingKart),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ek Ödeme Katsayısı',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    TurkceFormat.katsayi(katsayi),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: DSYSTheme.paraRengi,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Artık Bakiye',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    TurkceFormat.para(artikBakiye),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonelDagitimTablosu extends StatelessWidget {
  const _PersonelDagitimTablosu({required this.dagitimlar});
  final List<PersonelDagitimSonucu> dagitimlar;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DSYSTheme.paddingKart),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people_outlined, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Kişi Bazlı Dağıtım',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: DSYSTheme.spacingM),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Ad Soyad')),
                  DataColumn(label: Text('Ünvan Kts.')),
                  DataColumn(label: Text('Puan')),
                  DataColumn(label: Text('Bireysel P.')),
                  DataColumn(label: Text('Brüt Hakediş')),
                  DataColumn(label: Text('Durum')),
                ],
                rows: dagitimlar.map((d) {
                  return DataRow(
                    color: d.tavanAsimi
                        ? WidgetStateProperty.all(DSYSTheme.tavanAsimiBg)
                        : null,
                    cells: [
                      DataCell(Text(d.adSoyad)),
                      DataCell(Text(TurkceFormat.katsayi(d.unvanKatsayisi))),
                      DataCell(Text(d.faaliyetPuani.toStringAsFixed(0))),
                      DataCell(Text(d.bireyselPuan.toStringAsFixed(2))),
                      DataCell(Text(
                        TurkceFormat.para(d.brutHakedis),
                        style: TextStyle(
                          color: d.tavanAsimi
                              ? DSYSTheme.hataKirmizisi
                              : DSYSTheme.paraRengi,
                          fontWeight: FontWeight.w600,
                        ),
                      )),
                      DataCell(
                        d.tavanAsimi
                            ? const Icon(Icons.warning_amber,
                                color: DSYSTheme.hataKirmizisi, size: 18)
                            : const Icon(Icons.check_circle_outline,
                                color: DSYSTheme.onayYesili, size: 18),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SablonDurumuKarti extends StatelessWidget {
  const _SablonDurumuKarti({required this.dogrulama});
  final SablonDogrulamaSonucu dogrulama;

  @override
  Widget build(BuildContext context) {
    final oran = (dogrulama.tamamlanmaOrani * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DSYSTheme.paddingKart),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  dogrulama.gecerli
                      ? Icons.check_circle
                      : Icons.pending_outlined,
                  color: dogrulama.gecerli
                      ? DSYSTheme.onayYesili
                      : DSYSTheme.bekleyorSarisi,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Şablon Uyumu: %$oran',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            if (dogrulama.eksikAlanlar.isNotEmpty) ...[
              const SizedBox(height: DSYSTheme.spacingS),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: dogrulama.eksikAlanlar.map((alan) {
                  return Chip(
                    label: Text(
                      KararMetniServisi.alanEtiketi(alan),
                      style: const TextStyle(fontSize: 11),
                    ),
                    backgroundColor: DSYSTheme.tavanAsimiBg,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _KararMetniOnizleme extends StatelessWidget {
  const _KararMetniOnizleme({required this.metin});
  final String metin;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DSYSTheme.paddingKart),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.article_outlined, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Karar Metni Önizleme',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: DSYSTheme.spacingM),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withAlpha(60),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withAlpha(50),
                ),
              ),
              child: SelectableText(
                metin,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

