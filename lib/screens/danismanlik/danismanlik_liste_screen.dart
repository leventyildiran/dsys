import 'package:flutter/material.dart';

import '../../models/danismanlik_model.dart';
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

  // Demo veri (Firebase bağlantısında gerçek veriye dönüşecek)
  final List<_DemoDanismanlik> _demolar = [
    _DemoDanismanlik(
      firmaUnvan: 'Orhan Şaşmaz Tekstil Ltd. Şti.',
      konusu: 'Tasarım, tasarım danışmanlığı, ürün geliştirme',
      birimKisaAd: 'DTS',
      toplamTutar: 48000,
      suresi: 6,
      durum: DanismanlikDurum.aktif,
      tur: DanismanlikTuru.standart,
    ),
    _DemoDanismanlik(
      firmaUnvan: 'ABC Mühendislik A.Ş.',
      konusu: 'Teknik danışmanlık ve eğitim hizmetleri',
      birimKisaAd: 'UBATAM',
      toplamTutar: 120000,
      suresi: 12,
      durum: DanismanlikDurum.bekliyor,
      tur: DanismanlikTuru.sanayiIsbirligi58k,
    ),
    _DemoDanismanlik(
      firmaUnvan: 'Kıvılcım Seramik San.',
      konusu: 'Seramik tasarım ve kalite kontrol danışmanlığı',
      birimKisaAd: 'DTS',
      toplamTutar: 36000,
      suresi: 4,
      durum: DanismanlikDurum.tamamlandi,
      tur: DanismanlikTuru.standart,
    ),
  ];

  List<_DemoDanismanlik> get _filtrelenmis {
    if (_seciliDurum == null) return _demolar;
    return _demolar.where((d) => d.durum == _seciliDurum).toList();
  }

  @override
  Widget build(BuildContext context) {
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
            child: _filtrelenmis.isEmpty
                ? Center(
                    child: Text(
                      'Bu filtreye uygun danışmanlık bulunamadı.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  )
                : ListView.separated(
                    itemCount: _filtrelenmis.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: DSYSTheme.spacingS),
                    itemBuilder: (context, index) {
                      return _DanismanlikKarti(
                          danismanlik: _filtrelenmis[index]);
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
  final _DemoDanismanlik danismanlik;

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
                  danismanlik.tur == DanismanlikTuru.standart
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
                      danismanlik.firmaUnvan,
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
                          text: danismanlik.birimKisaAd,
                        ),
                        const SizedBox(width: 8),
                        _InfoChip(
                          icon: Icons.calendar_today,
                          text: '${danismanlik.suresi} ay',
                        ),
                        const SizedBox(width: 8),
                        _InfoChip(
                          icon: Icons.category,
                          text: danismanlik.tur.displayName,
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
                    _formatTutar(danismanlik.toplamTutar),
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

  String _formatTutar(double tutar) {
    final fixed = tutar.toStringAsFixed(0);
    final buffer = StringBuffer();
    final length = fixed.length;
    for (int i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) buffer.write('.');
      buffer.write(fixed[i]);
    }
    return '${buffer.toString()} ₺';
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

/// Demo veri modeli (Firebase öncesi).
class _DemoDanismanlik {
  const _DemoDanismanlik({
    required this.firmaUnvan,
    required this.konusu,
    required this.birimKisaAd,
    required this.toplamTutar,
    required this.suresi,
    required this.durum,
    required this.tur,
  });

  final String firmaUnvan;
  final String konusu;
  final String birimKisaAd;
  final double toplamTutar;
  final int suresi;
  final DanismanlikDurum durum;
  final DanismanlikTuru tur;
}
