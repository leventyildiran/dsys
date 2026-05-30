import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';

/// Ana dashboard ekranı.
///
/// Kullanıcı rolüne göre farklı içerik ve navigasyon gösterir.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<UserProvider, (UserModel?, bool)>(
      selector: (_, p) => (p.currentUser, p.isLoading),
      builder: (context, data, _) {
        final (user, isLoading) = data;

        if (isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (user == null) {
          return _buildNoProfileScreen(context);
        }

        return _DashboardLayout(user: user);
      },
    );
  }

  Widget _buildNoProfileScreen(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'Kullanıcı profili bulunamadı.',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text('Lütfen sistem yöneticisi ile iletişime geçin.'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.read<AuthProvider>().signOut(),
              icon: const Icon(Icons.logout),
              label: const Text('Çıkış Yap'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dashboard iç düzeni — NavigationRail (web) veya Drawer (mobil).
class _DashboardLayout extends StatefulWidget {
  const _DashboardLayout({required this.user});

  final UserModel user;

  @override
  State<_DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<_DashboardLayout> {
  int _selectedIndex = 0;

  List<_NavItem> get _navItems {
    final items = <_NavItem>[
      const _NavItem(
        icon: Icons.dashboard_rounded,
        label: 'Genel Bakış',
      ),
      const _NavItem(
        icon: Icons.handshake_rounded,
        label: 'Danışmanlıklar',
      ),
    ];

    // Rol bazlı menü öğeleri
    if (widget.user.role.isGlobal) {
      items.addAll([
        const _NavItem(
          icon: Icons.people_rounded,
          label: 'Kullanıcılar',
        ),
        const _NavItem(
          icon: Icons.business_rounded,
          label: 'Birimler',
        ),
        const _NavItem(
          icon: Icons.settings_rounded,
          label: 'Sistem Ayarları',
        ),
      ]);
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('DSYS'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Chip(
              avatar: const Icon(Icons.person, size: 18),
              label: Text(
                widget.user.role.displayName,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
            onPressed: () => context.read<AuthProvider>().signOut(),
          ),
        ],
      ),
      body: Row(
        children: [
          if (isWideScreen)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              labelType: NavigationRailLabelType.all,
              destinations: _navItems
                  .map((item) => NavigationRailDestination(
                        icon: Icon(item.icon),
                        label: Text(item.label),
                      ))
                  .toList(),
            ),
          if (isWideScreen) const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
      bottomNavigationBar: isWideScreen
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              destinations: _navItems
                  .map((item) => NavigationDestination(
                        icon: Icon(item.icon),
                        label: item.label,
                      ))
                  .toList(),
            ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _OverviewPanel(user: widget.user);
      case 1:
        return const _PlaceholderPanel(title: 'Danışmanlıklar');
      case 2:
        return const _PlaceholderPanel(title: 'Kullanıcı Yönetimi');
      case 3:
        return const _PlaceholderPanel(title: 'Birim Yönetimi');
      case 4:
        return const _PlaceholderPanel(title: 'Sistem Ayarları');
      default:
        return const _PlaceholderPanel(title: '');
    }
  }
}

/// Navigasyon öğesi veri modeli.
class _NavItem {
  const _NavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

/// Genel bakış paneli.
class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hoş Geldiniz, ${user.displayName}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Rol: ${user.role.displayName}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: _buildQuickStats(context),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: const [
            _StatCard(
              icon: Icons.handshake,
              label: 'Aktif Danışmanlıklar',
              value: '—',
            ),
            _StatCard(
              icon: Icons.pending_actions,
              label: 'Bekleyen Taksitler',
              value: '—',
            ),
            _StatCard(
              icon: Icons.check_circle,
              label: 'Onaylanan Kararlar',
              value: '—',
            ),
          ],
        );
      },
    );
  }
}

/// İstatistik kartı widget.
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder panel (henüz geliştirilmemiş modüller için).
class _PlaceholderPanel extends StatelessWidget {
  const _PlaceholderPanel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Bu modül yakında aktif olacak.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
