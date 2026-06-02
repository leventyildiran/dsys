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
  final _aiApiUrlController = TextEditingController();
  final _aiApiKeyController = TextEditingController();
  final _aiModelController = TextEditingController();
  final _kurumAdiController = TextEditingController();
  final _antetBasligiController = TextEditingController();

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
    _aiApiUrlController.dispose();
    _aiApiKeyController.dispose();
    _aiModelController.dispose();
    _kurumAdiController.dispose();
    _antetBasligiController.dispose();
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
        _aiApiUrlController.text = ayarlar.aiApiUrl ?? '';
        _aiApiKeyController.text = ayarlar.aiApiKey ?? '';
        _aiModelController.text = ayarlar.aiModel ?? '';
        _kurumAdiController.text = ayarlar.kurumAdi ?? 'UŞAK ÜNİVERSİTESİ';
        _antetBasligiController.text = ayarlar.antetBasligi ?? 'DÖNER SERMAYE YÜRÜTME KURULU KARARLARI';

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
        _kurumAdiController.text = 'UŞAK ÜNİVERSİTESİ';
        _antetBasligiController.text = 'DÖNER SERMAYE YÜRÜTME KURULU KARARLARI';

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
        aiApiUrl: _aiApiUrlController.text.trim().isEmpty ? null : _aiApiUrlController.text.trim(),
        aiApiKey: _aiApiKeyController.text.trim().isEmpty ? null : _aiApiKeyController.text.trim(),
        aiModel: _aiModelController.text.trim().isEmpty ? null : _aiModelController.text.trim(),
        kurulUyeleri: _ayarlar?.kurulUyeleri,
        kurumAdi: _kurumAdiController.text.trim().isEmpty ? null : _kurumAdiController.text.trim(),
        antetBasligi: _antetBasligiController.text.trim().isEmpty ? null : _antetBasligiController.text.trim(),
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

                // Kurum ve Antet Şablon Ayarları
                _buildSectionCard(
                  context,
                  title: 'Kurum ve Antet Şablon Ayarları (Karar Başlığı)',
                  icon: Icons.title_rounded,
                  children: [
                    TextFormField(
                      controller: _kurumAdiController,
                      decoration: const InputDecoration(
                        labelText: 'Kurum / Üniversite Adı',
                        hintText: 'UŞAK ÜNİVERSİTESİ',
                        helperText: 'Belge antetinde yer alacak kurum adı.',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Zorunlu alan' : null,
                    ),
                    const SizedBox(height: DSYSTheme.spacingM),
                    TextFormField(
                      controller: _antetBasligiController,
                      decoration: const InputDecoration(
                        labelText: 'Karar / Antet Başlığı',
                        hintText: 'DÖNER SERMAYE YÜRÜTME KURULU KARARLARI',
                        helperText: 'Karar belgesinin ana başlığı.',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Zorunlu alan' : null,
                    ),
                  ],
                ),
                 const SizedBox(height: DSYSTheme.spacingL),

                // Yapay Zeka API Ayarları (AI OCR Fallback)
                _buildSectionCard(
                  context,
                  title: 'Yapay Zeka API Ayarları (Gündem Ayrıştırma Fallback)',
                  icon: Icons.psychology,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade200, width: 0.8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.amber.shade800, size: 20),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Sistem öncelikli olarak ücretsiz Gemini API kullanır. Kota aşımı veya bağlantı hatası durumunda aşağıda belirttiğiniz yedek (DeepSeek / Özel) API otomatik olarak devreye girer.',
                                style: TextStyle(fontSize: 12, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    TextFormField(
                      controller: _aiApiUrlController,
                      decoration: const InputDecoration(
                        labelText: 'API Base URL (Örn: https://api.deepseek.com/v1)',
                        hintText: 'https://api.deepseek.com/v1',
                        helperText: 'Boş bırakılırsa varsayılan Gemini API kullanılır.',
                      ),
                    ),
                    const SizedBox(height: DSYSTheme.spacingM),
                    TextFormField(
                      controller: _aiApiKeyController,
                      decoration: const InputDecoration(
                        labelText: 'API Anahtarı (API Key)',
                        hintText: 'sk-...',
                        helperText: 'Boş bırakılırsa varsayılan Gemini API Key kullanılır.',
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: DSYSTheme.spacingM),
                    TextFormField(
                      controller: _aiModelController,
                      decoration: const InputDecoration(
                        labelText: 'Model Adı (Örn: deepseek-chat, gpt-4o-mini)',
                        hintText: 'deepseek-chat',
                      ),
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
