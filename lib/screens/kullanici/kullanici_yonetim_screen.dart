import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../theme.dart';

/// Kullanıcı yönetim ekranı.
///
/// Süper Admin ve YK Sekreteri rollerine özel.
/// Kullanıcı listesi, ekleme, düzenleme ve deaktif etme işlevleri sağlar.
class KullaniciYonetimScreen extends StatefulWidget {
  const KullaniciYonetimScreen({super.key});

  @override
  State<KullaniciYonetimScreen> createState() => _KullaniciYonetimScreenState();
}

class _KullaniciYonetimScreenState extends State<KullaniciYonetimScreen> {
  final UserService _userService = UserService();
  UserRole? _seciliRol;

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
                  'Kullanıcı Yönetimi',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              FilledButton.icon(
                onPressed: () => _kullaniciEkleDialog(context),
                icon: const Icon(Icons.person_add),
                label: const Text('Yeni Kullanıcı'),
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
                selected: _seciliRol == null,
                onSelected: (_) => setState(() => _seciliRol = null),
              ),
              ...UserRole.values.map((rol) => FilterChip(
                    label: Text(rol.displayName),
                    selected: _seciliRol == rol,
                    onSelected: (_) => setState(() => _seciliRol = rol),
                  )),
            ],
          ),
          const SizedBox(height: DSYSTheme.spacingM),

          // Kullanıcı listesi
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _userService.usersStream(onlyActive: false),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Kullanıcı verileri alınamadı.',
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

                var kullanicilar = snapshot.data!;
                if (_seciliRol != null) {
                  kullanicilar = kullanicilar
                      .where((u) => u.role == _seciliRol)
                      .toList();
                }

                if (kullanicilar.isEmpty) {
                  return Center(
                    child: Text(
                      'Bu filtreye uygun kullanıcı bulunamadı.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: kullanicilar.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: DSYSTheme.spacingS),
                  itemBuilder: (context, index) {
                    return _KullaniciKarti(
                      kullanici: kullanicilar[index],
                      onDuzenle: () =>
                          _kullaniciDuzenleDialog(context, kullanicilar[index]),
                      onDurumDegistir: () =>
                          _durumDegistir(kullanicilar[index]),
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

  Future<void> _kullaniciEkleDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    String displayName = '';
    String email = '';
    UserRole role = UserRole.birimSekreteri;
    String? birimId;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Yeni Kullanıcı Ekle'),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Ad Soyad',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Zorunlu alan' : null,
                    onSaved: (v) => displayName = v!.trim(),
                  ),
                  const SizedBox(height: DSYSTheme.spacingM),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'E-posta',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Zorunlu alan';
                      if (!v.contains('@')) return 'Geçerli e-posta girin';
                      return null;
                    },
                    onSaved: (v) => email = v!.trim(),
                  ),
                  const SizedBox(height: DSYSTheme.spacingM),
                  DropdownButtonFormField<UserRole>(
                    value: role,
                    decoration: const InputDecoration(
                      labelText: 'Rol',
                      prefixIcon: Icon(Icons.admin_panel_settings),
                    ),
                    items: UserRole.values
                        .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(r.displayName),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => role = v);
                      }
                    },
                  ),
                  const SizedBox(height: DSYSTheme.spacingM),
                  if (!role.isGlobal)
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Birim ID',
                        prefixIcon: Icon(Icons.business),
                      ),
                      onSaved: (v) => birimId = v?.trim(),
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
                    final user = UserModel(
                      uid: email, // Placeholder - gerçek UID Firebase Auth'tan gelecek
                      displayName: displayName,
                      email: email,
                      role: role,
                      birimId: birimId,
                      aktif: true,
                    );
                    await _userService.createUser(user);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Kullanıcı başarıyla eklendi.')),
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

  Future<void> _kullaniciDuzenleDialog(
      BuildContext context, UserModel kullanici) async {
    final formKey = GlobalKey<FormState>();
    String displayName = kullanici.displayName;
    UserRole role = kullanici.role;
    String? birimId = kullanici.birimId;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Düzenle: ${kullanici.displayName}'),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: displayName,
                    decoration: const InputDecoration(
                      labelText: 'Ad Soyad',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Zorunlu alan' : null,
                    onSaved: (v) => displayName = v!.trim(),
                  ),
                  const SizedBox(height: DSYSTheme.spacingM),
                  DropdownButtonFormField<UserRole>(
                    value: role,
                    decoration: const InputDecoration(
                      labelText: 'Rol',
                      prefixIcon: Icon(Icons.admin_panel_settings),
                    ),
                    items: UserRole.values
                        .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(r.displayName),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => role = v);
                      }
                    },
                  ),
                  const SizedBox(height: DSYSTheme.spacingM),
                  if (!role.isGlobal)
                    TextFormField(
                      initialValue: birimId,
                      decoration: const InputDecoration(
                        labelText: 'Birim ID',
                        prefixIcon: Icon(Icons.business),
                      ),
                      onSaved: (v) => birimId = v?.trim(),
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
                    await _userService.updateUser(kullanici.uid, {
                      'displayName': displayName,
                      'role': role.value,
                      'birimId': role.isGlobal ? null : birimId,
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Kullanıcı güncellendi.')),
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

  Future<void> _durumDegistir(UserModel kullanici) async {
    final yeniDurum = !kullanici.aktif;
    try {
      await _userService.updateUser(kullanici.uid, {'aktif': yeniDurum});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(yeniDurum
                ? '${kullanici.displayName} aktif edildi.'
                : '${kullanici.displayName} deaktif edildi.'),
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

class _KullaniciKarti extends StatelessWidget {
  const _KullaniciKarti({
    required this.kullanici,
    required this.onDuzenle,
    required this.onDurumDegistir,
  });

  final UserModel kullanici;
  final VoidCallback onDuzenle;
  final VoidCallback onDurumDegistir;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: kullanici.aktif
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.person,
            color: kullanici.aktif
                ? colorScheme.onPrimaryContainer
                : colorScheme.outline,
          ),
        ),
        title: Text(
          kullanici.displayName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration:
                kullanici.aktif ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Text(
          '${kullanici.email} • ${kullanici.role.displayName}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: kullanici.aktif
                    ? DSYSTheme.onayYesili.withAlpha(30)
                    : DSYSTheme.hataKirmizisi.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                kullanici.aktif ? 'Aktif' : 'Pasif',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: kullanici.aktif
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
                kullanici.aktif ? Icons.block : Icons.check_circle_outline,
                size: 20,
              ),
              tooltip: kullanici.aktif ? 'Deaktif Et' : 'Aktif Et',
              onPressed: onDurumDegistir,
            ),
          ],
        ),
      ),
    );
  }
}
