import 'package:flutter/material.dart';

import '../../models/personel_model.dart';
import '../../services/data_service.dart';
import '../../theme.dart';

/// Personel yönetim ekranı.
///
/// Akademik personel listesi, ekleme ve düzenleme.
class PersonelYonetimScreen extends StatefulWidget {
  const PersonelYonetimScreen({super.key});

  @override
  State<PersonelYonetimScreen> createState() => _PersonelYonetimScreenState();
}

class _PersonelYonetimScreenState extends State<PersonelYonetimScreen> {
  final PersonelService _personelService = PersonelService();
  final BirimService _birimService = BirimService();
  String? _seciliBirimId;
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
                  'Personel Yönetimi',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              FilledButton.icon(
                onPressed: () => _personelEkleDialog(context),
                icon: const Icon(Icons.person_add),
                label: const Text('Yeni Personel'),
              ),
            ],
          ),
          const SizedBox(height: DSYSTheme.spacingM),

          // Arama + Birim filtre
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'İsim veya TC ile ara...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => _aramaMetni = v.trim().toLowerCase()),
                ),
              ),
              const SizedBox(width: DSYSTheme.spacingM),
              Expanded(
                child: FutureBuilder(
                  future: _birimService.getAll(),
                  builder: (context, snapshot) {
                    final birimler = snapshot.data ?? [];
                    return DropdownButtonFormField<String?>(
                      value: _seciliBirimId,
                      decoration: const InputDecoration(
                        labelText: 'Birim Filtre',
                        prefixIcon: Icon(Icons.business),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Tüm Birimler'),
                        ),
                        ...birimler.map((b) => DropdownMenuItem(
                              value: b.id,
                              child: Text(b.kisaAd),
                            )),
                      ],
                      onChanged: (v) => setState(() => _seciliBirimId = v),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: DSYSTheme.spacingM),

          // Liste
          Expanded(
            child: StreamBuilder<List<PersonelModel>>(
              stream: _personelService.stream(birimId: _seciliBirimId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Personel verileri alınamadı.',
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

                var personeller = snapshot.data!;

                // Arama filtresi
                if (_aramaMetni.isNotEmpty) {
                  personeller = personeller.where((p) {
                    return p.adSoyad.toLowerCase().contains(_aramaMetni) ||
                        p.tcKimlikNo.contains(_aramaMetni);
                  }).toList();
                }

                if (personeller.isEmpty) {
                  return Center(
                    child: Text(
                      'Personel bulunamadı.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: personeller.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: DSYSTheme.spacingS),
                  itemBuilder: (context, index) {
                    return _PersonelKarti(
                      personel: personeller[index],
                      onDuzenle: () =>
                          _personelDuzenleDialog(context, personeller[index]),
                      onDurumDegistir: () =>
                          _durumDegistir(personeller[index]),
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

  Future<void> _personelEkleDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    String tcKimlikNo = '';
    String adSoyad = '';
    String unvan = '';
    double unvanKatsayisi = 1.0;
    String birimId = '';
    String iban = '';

    final birimler = await _birimService.getAll();

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni Personel Ekle'),
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
                      labelText: 'TC Kimlik No',
                      prefixIcon: Icon(Icons.badge),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 11,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Zorunlu alan';
                      if (v.trim().length != 11) return '11 haneli olmalı';
                      return null;
                    },
                    onSaved: (v) => tcKimlikNo = v!.trim(),
                  ),
                  const SizedBox(height: DSYSTheme.spacingM),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Ad Soyad',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Zorunlu alan' : null,
                    onSaved: (v) => adSoyad = v!.trim(),
                  ),
                  const SizedBox(height: DSYSTheme.spacingM),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Ünvan (ör: Prof. Dr., Doç. Dr.)',
                      prefixIcon: Icon(Icons.school),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Zorunlu alan' : null,
                    onSaved: (v) => unvan = v!.trim(),
                  ),
                  const SizedBox(height: DSYSTheme.spacingM),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Ünvan Katsayısı',
                      prefixIcon: Icon(Icons.calculate),
                      hintText: '2.00',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Zorunlu alan';
                      if (double.tryParse(v.trim()) == null) {
                        return 'Geçerli bir sayı girin';
                      }
                      return null;
                    },
                    onSaved: (v) => unvanKatsayisi = double.parse(v!.trim()),
                  ),
                  const SizedBox(height: DSYSTheme.spacingM),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Birim',
                      prefixIcon: Icon(Icons.business),
                    ),
                    items: birimler
                        .map((b) => DropdownMenuItem(
                              value: b.id,
                              child: Text('${b.kisaAd} - ${b.ad}'),
                            ))
                        .toList(),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Birim seçin' : null,
                    onChanged: (v) => birimId = v ?? '',
                    onSaved: (v) => birimId = v ?? '',
                  ),
                  const SizedBox(height: DSYSTheme.spacingM),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'IBAN (Opsiyonel)',
                      prefixIcon: Icon(Icons.account_balance),
                    ),
                    onSaved: (v) => iban = v?.trim() ?? '',
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
                  final personel = PersonelModel(
                    id: '',
                    tcKimlikNo: tcKimlikNo,
                    adSoyad: adSoyad,
                    unvan: unvan,
                    unvanKatsayisi: unvanKatsayisi,
                    birimId: birimId,
                    iban: iban.isNotEmpty ? iban : null,
                    aktif: true,
                  );
                  await _personelService.create(personel);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Personel başarıyla eklendi.')),
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

  Future<void> _personelDuzenleDialog(
      BuildContext context, PersonelModel personel) async {
    final formKey = GlobalKey<FormState>();
    String adSoyad = personel.adSoyad;
    String unvan = personel.unvan;
    double unvanKatsayisi = personel.unvanKatsayisi;
    String iban = personel.iban ?? '';

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Düzenle: ${personel.adSoyad}'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: personel.tcKimlikNo,
                    decoration: const InputDecoration(
                      labelText: 'TC Kimlik No',
                      prefixIcon: Icon(Icons.badge),
                    ),
                    enabled: false,
                  ),
                  const SizedBox(height: DSYSTheme.spacingM),
                  TextFormField(
                    initialValue: adSoyad,
                    decoration: const InputDecoration(
                      labelText: 'Ad Soyad',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Zorunlu alan' : null,
                    onSaved: (v) => adSoyad = v!.trim(),
                  ),
                  const SizedBox(height: DSYSTheme.spacingM),
                  TextFormField(
                    initialValue: unvan,
                    decoration: const InputDecoration(
                      labelText: 'Ünvan',
                      prefixIcon: Icon(Icons.school),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Zorunlu alan' : null,
                    onSaved: (v) => unvan = v!.trim(),
                  ),
                  const SizedBox(height: DSYSTheme.spacingM),
                  TextFormField(
                    initialValue: unvanKatsayisi.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Ünvan Katsayısı',
                      prefixIcon: Icon(Icons.calculate),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Zorunlu alan';
                      if (double.tryParse(v.trim()) == null) {
                        return 'Geçerli bir sayı girin';
                      }
                      return null;
                    },
                    onSaved: (v) => unvanKatsayisi = double.parse(v!.trim()),
                  ),
                  const SizedBox(height: DSYSTheme.spacingM),
                  TextFormField(
                    initialValue: iban,
                    decoration: const InputDecoration(
                      labelText: 'IBAN',
                      prefixIcon: Icon(Icons.account_balance),
                    ),
                    onSaved: (v) => iban = v?.trim() ?? '',
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
                  await _personelService.update(personel.id, {
                    'adSoyad': adSoyad,
                    'unvan': unvan,
                    'unvanKatsayisi': unvanKatsayisi,
                    'iban': iban.isNotEmpty ? iban : null,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Personel güncellendi.')),
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

  Future<void> _durumDegistir(PersonelModel personel) async {
    final yeniDurum = !personel.aktif;
    try {
      await _personelService.update(personel.id, {'aktif': yeniDurum});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(yeniDurum
                ? '${personel.adSoyad} aktif edildi.'
                : '${personel.adSoyad} deaktif edildi.'),
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

class _PersonelKarti extends StatelessWidget {
  const _PersonelKarti({
    required this.personel,
    required this.onDuzenle,
    required this.onDurumDegistir,
  });

  final PersonelModel personel;
  final VoidCallback onDuzenle;
  final VoidCallback onDurumDegistir;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: personel.aktif
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.school,
            color: personel.aktif
                ? colorScheme.onPrimaryContainer
                : colorScheme.outline,
          ),
        ),
        title: Text(
          '${personel.unvan} ${personel.adSoyad}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: personel.aktif ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Text(
          'Katsayı: ${personel.unvanKatsayisi} • TC: ${personel.tcKimlikNo}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: personel.aktif
                    ? DSYSTheme.onayYesili.withAlpha(30)
                    : DSYSTheme.hataKirmizisi.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                personel.aktif ? 'Aktif' : 'Pasif',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: personel.aktif
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
                personel.aktif ? Icons.block : Icons.check_circle_outline,
                size: 20,
              ),
              tooltip: personel.aktif ? 'Deaktif Et' : 'Aktif Et',
              onPressed: onDurumDegistir,
            ),
          ],
        ),
      ),
    );
  }
}
