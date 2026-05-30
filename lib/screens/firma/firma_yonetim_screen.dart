import 'package:flutter/material.dart';

import '../../models/firma_model.dart';
import '../../services/data_service.dart';
import '../../theme.dart';

/// Firma yönetim ekranı.
///
/// Hizmet alan firmaların listesi, ekleme ve düzenleme.
class FirmaYonetimScreen extends StatefulWidget {
  const FirmaYonetimScreen({super.key});

  @override
  State<FirmaYonetimScreen> createState() => _FirmaYonetimScreenState();
}

class _FirmaYonetimScreenState extends State<FirmaYonetimScreen> {
  final FirmaService _firmaService = FirmaService();
  String _aramaMetni = '';

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
                  'Firma Yönetimi',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              FilledButton.icon(
                onPressed: () => _firmaEkleDialog(context),
                icon: const Icon(Icons.add_business),
                label: const Text('Yeni Firma'),
              ),
            ],
          ),
          const SizedBox(height: DSYSTheme.spacingM),

          // Arama
          TextField(
            decoration: const InputDecoration(
              hintText: 'Firma ünvanı veya vergi no ile ara...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) =>
                setState(() => _aramaMetni = v.trim().toLowerCase()),
          ),
          const SizedBox(height: DSYSTheme.spacingM),

          // Liste
          Expanded(
            child: StreamBuilder<List<FirmaModel>>(
              stream: _firmaService.stream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Firma verileri alınamadı.',
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

                var firmalar = snapshot.data!;

                if (_aramaMetni.isNotEmpty) {
                  firmalar = firmalar.where((f) {
                    return f.unvan.toLowerCase().contains(_aramaMetni) ||
                        (f.vergiNo?.contains(_aramaMetni) ?? false);
                  }).toList();
                }

                if (firmalar.isEmpty) {
                  return Center(
                    child: Text(
                      'Firma bulunamadı.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: firmalar.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: DSYSTheme.spacingS),
                  itemBuilder: (context, index) {
                    return _FirmaKarti(
                      firma: firmalar[index],
                      onDuzenle: () =>
                          _firmaDuzenleDialog(context, firmalar[index]),
                      onDurumDegistir: () =>
                          _durumDegistir(firmalar[index]),
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

  Future<void> _firmaEkleDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    String unvan = '';
    String vergiNo = '';
    String vergiDairesi = '';
    String adres = '';
    String telefon = '';
    String yetkiliKisi = '';

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni Firma Ekle'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Firma Ünvanı',
                      prefixIcon: Icon(Icons.business),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Zorunlu alan' : null,
                    onSaved: (v) => unvan = v!.trim(),
                  ),
                  const SizedBox(height: DSYSTheme.spacingM),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Vergi No',
                            prefixIcon: Icon(Icons.numbers),
                          ),
                          onSaved: (v) => vergiNo = v?.trim() ?? '',
                        ),
                      ),
                      const SizedBox(width: DSYSTheme.spacingM),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Vergi Dairesi',
                            prefixIcon: Icon(Icons.account_balance),
                          ),
                          onSaved: (v) => vergiDairesi = v?.trim() ?? '',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DSYSTheme.spacingM),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Adres',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    maxLines: 2,
                    onSaved: (v) => adres = v?.trim() ?? '',
                  ),
                  const SizedBox(height: DSYSTheme.spacingM),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Telefon',
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                          onSaved: (v) => telefon = v?.trim() ?? '',
                        ),
                      ),
                      const SizedBox(width: DSYSTheme.spacingM),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Yetkili Kişi',
                            prefixIcon: Icon(Icons.person),
                          ),
                          onSaved: (v) => yetkiliKisi = v?.trim() ?? '',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
                  final firma = FirmaModel(
                    id: '',
                    unvan: unvan,
                    vergiNo: vergiNo.isNotEmpty ? vergiNo : null,
                    vergiDairesi:
                        vergiDairesi.isNotEmpty ? vergiDairesi : null,
                    adres: adres.isNotEmpty ? adres : null,
                    telefon: telefon.isNotEmpty ? telefon : null,
                    yetkiliKisi:
                        yetkiliKisi.isNotEmpty ? yetkiliKisi : null,
                    aktif: true,
                  );
                  await _firmaService.create(firma);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Firma başarıyla eklendi.')),
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
    );
  }

  Future<void> _firmaDuzenleDialog(
      BuildContext context, FirmaModel firma) async {
    final formKey = GlobalKey<FormState>();
    String unvan = firma.unvan;
    String vergiNo = firma.vergiNo ?? '';
    String vergiDairesi = firma.vergiDairesi ?? '';
    String adres = firma.adres ?? '';
    String telefon = firma.telefon ?? '';
    String yetkiliKisi = firma.yetkiliKisi ?? '';

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Düzenle: ${firma.unvan}'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: unvan,
                    decoration: const InputDecoration(
                      labelText: 'Firma Ünvanı',
                      prefixIcon: Icon(Icons.business),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Zorunlu alan' : null,
                    onSaved: (v) => unvan = v!.trim(),
                  ),
                  const SizedBox(height: DSYSTheme.spacingM),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: vergiNo,
                          decoration: const InputDecoration(
                            labelText: 'Vergi No',
                            prefixIcon: Icon(Icons.numbers),
                          ),
                          onSaved: (v) => vergiNo = v?.trim() ?? '',
                        ),
                      ),
                      const SizedBox(width: DSYSTheme.spacingM),
                      Expanded(
                        child: TextFormField(
                          initialValue: vergiDairesi,
                          decoration: const InputDecoration(
                            labelText: 'Vergi Dairesi',
                            prefixIcon: Icon(Icons.account_balance),
                          ),
                          onSaved: (v) => vergiDairesi = v?.trim() ?? '',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DSYSTheme.spacingM),
                  TextFormField(
                    initialValue: adres,
                    decoration: const InputDecoration(
                      labelText: 'Adres',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    maxLines: 2,
                    onSaved: (v) => adres = v?.trim() ?? '',
                  ),
                  const SizedBox(height: DSYSTheme.spacingM),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: telefon,
                          decoration: const InputDecoration(
                            labelText: 'Telefon',
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                          onSaved: (v) => telefon = v?.trim() ?? '',
                        ),
                      ),
                      const SizedBox(width: DSYSTheme.spacingM),
                      Expanded(
                        child: TextFormField(
                          initialValue: yetkiliKisi,
                          decoration: const InputDecoration(
                            labelText: 'Yetkili Kişi',
                            prefixIcon: Icon(Icons.person),
                          ),
                          onSaved: (v) => yetkiliKisi = v?.trim() ?? '',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
                  await _firmaService.update(firma.id, {
                    'unvan': unvan,
                    'vergiNo': vergiNo.isNotEmpty ? vergiNo : null,
                    'vergiDairesi':
                        vergiDairesi.isNotEmpty ? vergiDairesi : null,
                    'adres': adres.isNotEmpty ? adres : null,
                    'telefon': telefon.isNotEmpty ? telefon : null,
                    'yetkiliKisi':
                        yetkiliKisi.isNotEmpty ? yetkiliKisi : null,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Firma güncellendi.')),
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
    );
  }

  Future<void> _durumDegistir(FirmaModel firma) async {
    final yeniDurum = !firma.aktif;
    try {
      await _firmaService.update(firma.id, {'aktif': yeniDurum});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(yeniDurum
                ? '${firma.unvan} aktif edildi.'
                : '${firma.unvan} deaktif edildi.'),
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

class _FirmaKarti extends StatelessWidget {
  const _FirmaKarti({
    required this.firma,
    required this.onDuzenle,
    required this.onDurumDegistir,
  });

  final FirmaModel firma;
  final VoidCallback onDuzenle;
  final VoidCallback onDurumDegistir;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: firma.aktif
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.store,
            color: firma.aktif
                ? colorScheme.onPrimaryContainer
                : colorScheme.outline,
          ),
        ),
        title: Text(
          firma.unvan,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: firma.aktif ? null : TextDecoration.lineThrough,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          [
            if (firma.vergiNo != null) 'VN: ${firma.vergiNo}',
            if (firma.yetkiliKisi != null) firma.yetkiliKisi!,
            if (firma.telefon != null) firma.telefon!,
          ].join(' • '),
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: firma.aktif
                    ? DSYSTheme.onayYesili.withAlpha(30)
                    : DSYSTheme.hataKirmizisi.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                firma.aktif ? 'Aktif' : 'Pasif',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: firma.aktif
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
                firma.aktif ? Icons.block : Icons.check_circle_outline,
                size: 20,
              ),
              tooltip: firma.aktif ? 'Deaktif Et' : 'Aktif Et',
              onPressed: onDurumDegistir,
            ),
          ],
        ),
      ),
    );
  }
}
