import 'package:flutter/material.dart';

import '../../models/birim_model.dart';
import '../../services/data_service.dart';
import '../../theme.dart';

/// Birim yönetim ekranı.
///
/// Üniversite birimlerini listeleme, ekleme ve düzenleme.
class BirimYonetimScreen extends StatefulWidget {
  const BirimYonetimScreen({super.key});

  @override
  State<BirimYonetimScreen> createState() => _BirimYonetimScreenState();
}

class _BirimYonetimScreenState extends State<BirimYonetimScreen> {
  final BirimService _birimService = BirimService();
  BirimTuru? _seciliTur;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(DSYSTheme.paddingSayfa),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Birim Yönetimi',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              FilledButton.icon(
                onPressed: () => _birimEkleDialog(context),
                icon: const Icon(Icons.add_business),
                label: const Text('Yeni Birim'),
              ),
            ],
          ),
          const SizedBox(height: DSYSTheme.spacingM),

          // Filtre
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Tümü'),
                selected: _seciliTur == null,
                onSelected: (_) => setState(() => _seciliTur = null),
              ),
              ...BirimTuru.values.map((t) => FilterChip(
                    label: Text(t.displayName),
                    selected: _seciliTur == t,
                    onSelected: (_) => setState(() => _seciliTur = t),
                  )),
            ],
          ),
          const SizedBox(height: DSYSTheme.spacingM),

          Expanded(
            child: StreamBuilder<List<BirimModel>>(
              stream: _birimService.stream(onlyActive: false),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Birim verileri alınamadı.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var birimler = snapshot.data!;
                if (_seciliTur != null) {
                  birimler =
                      birimler.where((b) => b.tur == _seciliTur).toList();
                }

                if (birimler.isEmpty) {
                  return Center(
                    child: Text(
                      'Birim bulunamadı.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: birimler.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: DSYSTheme.spacingS),
                  itemBuilder: (context, index) {
                    return _BirimKarti(
                      birim: birimler[index],
                      onDuzenle: () =>
                          _birimDuzenleDialog(context, birimler[index]),
                      onDurumDegistir: () =>
                          _durumDegistir(birimler[index]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _birimEkleDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    String ad = '';
    String kisaAd = '';
    BirimTuru tur = BirimTuru.merkez;
    String mudurAd = '';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Yeni Birim Ekle'),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Birim Adı',
                      prefixIcon: Icon(Icons.business),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Zorunlu alan' : null,
                    onSaved: (v) => ad = v!.trim(),
                  ),
                  const SizedBox(height: DSYSTheme.spacingM),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Kısa Ad (ör: DTS, UBATAM)',
                      prefixIcon: Icon(Icons.short_text),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Zorunlu alan' : null,
                    onSaved: (v) => kisaAd = v!.trim(),
                  ),
                  const SizedBox(height: DSYSTheme.spacingM),
                  DropdownButtonFormField<BirimTuru>(
                    value: tur,
                    decoration: const InputDecoration(
                      labelText: 'Birim Türü',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: BirimTuru.values
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.displayName),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => tur = v);
                    },
                  ),
                  const SizedBox(height: DSYSTheme.spacingM),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Müdür Adı',
                      prefixIcon: Icon(Icons.person),
                    ),
                    onSaved: (v) => mudurAd = v?.trim() ?? '',
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
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  try {
                    final birim = BirimModel(
                      id: '',
                      ad: ad,
                      kisaAd: kisaAd,
                      tur: tur,
                      mudurAd: mudurAd.isNotEmpty ? mudurAd : null,
                      aktif: true,
                    );
                    await _birimService.create(birim);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Birim başarıyla eklendi.')),
                      );
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('Hata: $e')),
                      );
                    }
                  }
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _birimDuzenleDialog(BuildContext context, BirimModel birim) async {
    final formKey = GlobalKey<FormState>();
    String ad = birim.ad;
    String kisaAd = birim.kisaAd;
    BirimTuru tur = birim.tur;
    String mudurAd = birim.mudurAd ?? '';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Düzenle: ${birim.kisaAd}'),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: ad,
                    decoration: const InputDecoration(
                      labelText: 'Birim Adı',
                      prefixIcon: Icon(Icons.business),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Zorunlu alan' : null,
                    onSaved: (v) => ad = v!.trim(),
                  ),
                  const SizedBox(height: DSYSTheme.spacingM),
                  TextFormField(
                    initialValue: kisaAd,
                    decoration: const InputDecoration(
                      labelText: 'Kısa Ad',
                      prefixIcon: Icon(Icons.short_text),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Zorunlu alan' : null,
                    onSaved: (v) => kisaAd = v!.trim(),
                  ),
                  const SizedBox(height: DSYSTheme.spacingM),
                  DropdownButtonFormField<BirimTuru>(
                    value: tur,
                    decoration: const InputDecoration(
                      labelText: 'Birim Türü',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: BirimTuru.values
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.displayName),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => tur = v);
                    },
                  ),
                  const SizedBox(height: DSYSTheme.spacingM),
                  TextFormField(
                    initialValue: mudurAd,
                    decoration: const InputDecoration(
                      labelText: 'Müdür Adı',
                      prefixIcon: Icon(Icons.person),
                    ),
                    onSaved: (v) => mudurAd = v?.trim() ?? '',
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
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  try {
                    await _birimService.update(birim.id, {
                      'ad': ad,
                      'kisaAd': kisaAd,
                      'tur': tur.value,
                      'mudurAd': mudurAd.isNotEmpty ? mudurAd : null,
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Birim güncellendi.')),
                      );
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('Hata: $e')),
                      );
                    }
                  }
                }
              },
              child: const Text('Güncelle'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _durumDegistir(BirimModel birim) async {
    final yeniDurum = !birim.aktif;
    try {
      await _birimService.update(birim.id, {'aktif': yeniDurum});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(yeniDurum
                ? '${birim.kisaAd} aktif edildi.'
                : '${birim.kisaAd} deaktif edildi.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }
}

class _BirimKarti extends StatelessWidget {
  const _BirimKarti({
    required this.birim,
    required this.onDuzenle,
    required this.onDurumDegistir,
  });

  final BirimModel birim;
  final VoidCallback onDuzenle;
  final VoidCallback onDurumDegistir;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: birim.aktif
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.business_rounded,
            color: birim.aktif
                ? colorScheme.onPrimaryContainer
                : colorScheme.outline,
          ),
        ),
        title: Text(
          birim.ad,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: birim.aktif ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Text(
          '${birim.kisaAd} • ${birim.tur.displayName}${birim.mudurAd != null ? ' • ${birim.mudurAd}' : ''}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: birim.aktif
                    ? DSYSTheme.onayYesili.withAlpha(30)
                    : DSYSTheme.hataKirmizisi.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                birim.aktif ? 'Aktif' : 'Pasif',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: birim.aktif
                      ? DSYSTheme.onayYesili
                      : DSYSTheme.hataKirmizisi,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: 'Düzenle',
              onPressed: onDuzenle,
            ),
            IconButton(
              icon: Icon(
                birim.aktif ? Icons.block : Icons.check_circle_outline,
                size: 20,
              ),
              tooltip: birim.aktif ? 'Deaktif Et' : 'Aktif Et',
              onPressed: onDurumDegistir,
            ),
          ],
        ),
      ),
    );
  }
}
