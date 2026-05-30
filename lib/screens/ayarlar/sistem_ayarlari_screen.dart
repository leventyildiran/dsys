import 'package:flutter/material.dart';

import '../../core/turkce_format.dart';
import '../../models/sistem_ayarlari_model.dart';
import '../../services/data_service.dart';
import '../../theme.dart';

/// Sistem ayarları ekranı.
///
/// Memur maaş katsayısı, EYDMA gösterge, varsayılan kesinti oranları
/// ve unvan katsayıları yönetimi.
class SistemAyarlariScreen extends StatefulWidget {
  const SistemAyarlariScreen({super.key});

  @override
  State<SistemAyarlariScreen> createState() => _SistemAyarlariScreenState();
}

class _SistemAyarlariScreenState extends State<SistemAyarlariScreen> {
  final SistemAyarlariService _service = SistemAyarlariService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;
  SistemAyarlariModel? _ayarlar;

  // Form controller'ları
  final _maasKatsayisiController = TextEditingController();
  final _eydmaGostergeController = TextEditingController();
  final _hazineController = TextEditingController();
  final _bapController = TextEditingController();
  final _aracGerecController = TextEditingController();
  final _dagitilabilirController = TextEditingController();

  // Ünvan katsayıları
  final Map<String, TextEditingController> _unvanControllers = {};

  static const _varsayilanUnvanlar = {
    'profesor': 'Profesör',
    'docent': 'Doçent',
    'drOgrUyesi': 'Dr. Öğr. Üyesi',
    'ogrGorDr': 'Öğr. Gör. Dr.',
    'ogrGor': 'Öğr. Gör.',
    'arastirmaGorevlisi': 'Araştırma Görevlisi',
  };

  @override
  void initState() {
    super.initState();
    _loadAyarlar();
  }

  @override
  void dispose() {
    _maasKatsayisiController.dispose();
    _eydmaGostergeController.dispose();
    _hazineController.dispose();
    _bapController.dispose();
    _aracGerecController.dispose();
    _dagitilabilirController.dispose();
    for (final c in _unvanControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadAyarlar() async {
    setState(() => _isLoading = true);
    try {
      final ayarlar = await _service.get();
      if (ayarlar != null) {
        _ayarlar = ayarlar;
        _maasKatsayisiController.text =
            ayarlar.memurMaasKatsayisi.toString();
        _eydmaGostergeController.text = ayarlar.eydmaGosterge.toString();
        _hazineController.text =
            ayarlar.varsayilanKesintiler.hazinePayi.toString();
        _bapController.text =
            ayarlar.varsayilanKesintiler.bapPayi.toString();
        _aracGerecController.text =
            ayarlar.varsayilanKesintiler.aracGerecPayi.toString();
        _dagitilabilirController.text =
            ayarlar.varsayilanKesintiler.dagitilabilir.toString();

        for (final entry in _varsayilanUnvanlar.entries) {
          final value = ayarlar.unvanKatsayilari[entry.key] ?? 1.0;
          _unvanControllers[entry.key] =
              TextEditingController(text: value.toString());
        }
      } else {
        // Varsayılan değerlerle başlat
        _maasKatsayisiController.text = '1.387871';
        _eydmaGostergeController.text = '9500';
        _hazineController.text = '1';
        _bapController.text = '5';
        _aracGerecController.text = '45';
        _dagitilabilirController.text = '49';

        for (final entry in _varsayilanUnvanlar.entries) {
          _unvanControllers[entry.key] =
              TextEditingController(text: '1.0');
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ayarlar yüklenirken hata oluştu.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _kaydet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final unvanKatsayilari = <String, double>{};
      for (final entry in _unvanControllers.entries) {
        unvanKatsayilari[entry.key] =
            double.tryParse(entry.value.text) ?? 1.0;
      }

      final model = SistemAyarlariModel(
        memurMaasKatsayisi:
            double.tryParse(_maasKatsayisiController.text) ?? 1.0,
        eydmaGosterge:
            int.tryParse(_eydmaGostergeController.text) ?? 9500,
        varsayilanKesintiler: VarsayilanKesintiler(
          hazinePayi: int.tryParse(_hazineController.text) ?? 1,
          bapPayi: int.tryParse(_bapController.text) ?? 5,
          aracGerecPayi: int.tryParse(_aracGerecController.text) ?? 45,
          dagitilabilir: int.tryParse(_dagitilabilirController.text) ?? 49,
        ),
        unvanKatsayilari: unvanKatsayilari,
      );

      await _service.update(model.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sistem ayarları kaydedildi.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kayıt hatası: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DSYSTheme.paddingSayfa),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: DSYSTheme.formMaxWidth),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Sistem Ayarları',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _kaydet,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: const Text('Kaydet'),
                    ),
                  ],
                ),
                const SizedBox(height: DSYSTheme.spacingL),

                // Genel Katsayılar
                _buildSectionCard(
                  context,
                  title: 'Genel Katsayılar',
                  icon: Icons.calculate,
                  children: [
                    _buildNumberField(
                      controller: _maasKatsayisiController,
                      label: 'Memur Maaş Katsayısı',
                      hint: '1.387871',
                    ),
                    const SizedBox(height: DSYSTheme.spacingM),
                    _buildNumberField(
                      controller: _eydmaGostergeController,
                      label: 'EYDMA Gösterge (Ek + Makam/Temsil)',
                      hint: '9500',
                      isInteger: true,
                    ),
                    const SizedBox(height: DSYSTheme.spacingM),
                    if (_ayarlar != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: DSYSTheme.tabloBaslikBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Hesaplanan EYDMA: ${TurkceFormat.para(_ayarlar!.hesaplananEydma)}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: DSYSTheme.spacingL),

                // Varsayılan Kesinti Oranları
                _buildSectionCard(
                  context,
                  title: 'Varsayılan Kesinti Oranları (%)',
                  icon: Icons.pie_chart,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildNumberField(
                            controller: _hazineController,
                            label: 'Hazine Payı',
                            hint: '1',
                            isInteger: true,
                            suffix: '%',
                          ),
                        ),
                        const SizedBox(width: DSYSTheme.spacingM),
                        Expanded(
                          child: _buildNumberField(
                            controller: _bapController,
                            label: 'BAP Payı',
                            hint: '5',
                            isInteger: true,
                            suffix: '%',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: DSYSTheme.spacingM),
                    Row(
                      children: [
                        Expanded(
                          child: _buildNumberField(
                            controller: _aracGerecController,
                            label: 'Araç Gereç Payı',
                            hint: '45',
                            isInteger: true,
                            suffix: '%',
                          ),
                        ),
                        const SizedBox(width: DSYSTheme.spacingM),
                        Expanded(
                          child: _buildNumberField(
                            controller: _dagitilabilirController,
                            label: 'Dağıtılabilir',
                            hint: '49',
                            isInteger: true,
                            suffix: '%',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: DSYSTheme.spacingL),

                // Ünvan Katsayıları
                _buildSectionCard(
                  context,
                  title: 'Ünvan Katsayıları',
                  icon: Icons.school,
                  children: [
                    ..._varsayilanUnvanlar.entries.map((entry) {
                      final controller = _unvanControllers[entry.key];
                      if (controller == null) return const SizedBox.shrink();
                      return Padding(
                        padding:
                            const EdgeInsets.only(bottom: DSYSTheme.spacingM),
                        child: _buildNumberField(
                          controller: controller,
                          label: entry.value,
                          hint: '2.00',
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: DSYSTheme.spacingXL),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DSYSTheme.paddingKart),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: DSYSTheme.spacingM),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool isInteger = false,
    String? suffix,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Zorunlu alan';
        if (isInteger) {
          if (int.tryParse(v.trim()) == null) return 'Geçerli bir tam sayı girin';
        } else {
          if (double.tryParse(v.trim()) == null) return 'Geçerli bir sayı girin';
        }
        return null;
      },
    );
  }
}
