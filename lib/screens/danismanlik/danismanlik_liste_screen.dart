import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/turkce_format.dart';
import '../../models/danismanlik_model.dart';
import '../../providers/user_provider.dart';
import '../../services/data_service.dart';
import '../../theme.dart';
import 'danismanlik_form_screen.dart';

/// Danışmanlık listesi ekranı.
///
/// Dashboard'daki "Danışmanlıklar" sekmesinde gösterilir.
/// Durum filtreleri ve yeni danışmanlık ekleme butonu içerir.
class DanismanlikListeScreen extends StatefulWidget {
  const DanismanlikListeScreen({super.key});

  @override
  State<DanismanlikListeScreen> createState() => _DanismanlikListeScreenState();
}

class _DanismanlikListeScreenState extends State<DanismanlikListeScreen> {
  DanismanlikDurum? _seciliDurum;
  final DanismanlikService _danismanlikService = DanismanlikService();

  List<DanismanlikModel> _filtrelenmis(List<DanismanlikModel> liste) {
    final filtreli = _seciliDurum == null
        ? liste
        : liste.where((d) => d.durum == _seciliDurum).toList();
    filtreli.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return filtreli;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().currentUser;
    final birimId =
        (user == null || user.role.isGlobal) ? null : user.birimId;

    return Padding(
      padding: const EdgeInsets.all(DSYSTheme.paddingSayfa),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık + Ekle butonu
          Row(
            children: [
              Expanded(
                child: Text(
                  'Danışmanlıklar',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text('Yeni Taksit')),
                        body: const DanismanlikFormScreen(),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Yeni Danışmanlık'),
              ),
            ],
          ),
          const SizedBox(height: DSYSTheme.spacingM),

          // Filtre Chips
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Tümü'),
                selected: _seciliDurum == null,
                onSelected: (_) => setState(() => _seciliDurum = null),
              ),
              ...DanismanlikDurum.values.map((d) => FilterChip(
                    label: Text(d.displayName),
                    selected: _seciliDurum == d,
                    onSelected: (_) => setState(() => _seciliDurum = d),
                    avatar: CircleAvatar(
                      backgroundColor: DSYSTheme.durumRengi(d.value),
                      radius: 6,
                    ),
                  )),
            ],
          ),
          const SizedBox(height: DSYSTheme.spacingM),

          // Liste
          Expanded(
            child: StreamBuilder<List<DanismanlikModel>>(
              stream: _danismanlikService.stream(birimId: birimId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Danışmanlık verileri alınamadı.',
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

                final filtrelenmis = _filtrelenmis(snapshot.data!);
                if (filtrelenmis.isEmpty) {
                  return Center(
                    child: Text(
                      'Bu filtreye uygun danışmanlık bulunamadı.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filtrelenmis.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: DSYSTheme.spacingS),
                  itemBuilder: (context, index) {
                    return _DanismanlikKarti(danismanlik: filtrelenmis[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DanismanlikKarti extends StatelessWidget {
  const _DanismanlikKarti({required this.danismanlik});
  final DanismanlikModel danismanlik;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Detay sayfasına git
        },
        child: Padding(
          padding: const EdgeInsets.all(DSYSTheme.paddingKart),
          child: Row(
            children: [
              // Sol: İkon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  danismanlik.danismanlikTuru == DanismanlikTuru.standart
                      ? Icons.description_outlined
                      : Icons.factory_outlined,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              // Orta: Bilgi
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      danismanlik.firmaUnvan?.trim().isNotEmpty == true
                          ? danismanlik.firmaUnvan!
                          : 'Firma bilgisi girilmemiş',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      danismanlik.konusu,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _InfoChip(
                          icon: Icons.business,
                          text: danismanlik.birimKisaAd?.trim().isNotEmpty ==
                                  true
                              ? danismanlik.birimKisaAd!
                              : '-',
                        ),
                        const SizedBox(width: 8),
                        _InfoChip(
                          icon: Icons.calendar_today,
                          text: '${danismanlik.suresi} ay',
                        ),
                        const SizedBox(width: 8),
                        _InfoChip(
                          icon: Icons.category,
                          text: danismanlik.danismanlikTuru.displayName,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Sağ: Tutar + Durum
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    TurkceFormat.para(danismanlik.toplamTutar),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: DSYSTheme.paraRengi,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: DSYSTheme.durumRengi(danismanlik.durum.value)
                          .withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      danismanlik.durum.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: DSYSTheme.durumRengi(danismanlik.durum.value),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
