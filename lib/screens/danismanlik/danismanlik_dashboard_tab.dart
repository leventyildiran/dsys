import 'package:flutter/material.dart';
import '../../theme.dart';

class DanismanlikDashboardTab extends StatelessWidget {
  const DanismanlikDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(DSYSTheme.paddingSayfa),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Genel Bakış',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: DSYSTheme.spacingL),
          Expanded(
            child: Center(
              child: Text(
                'İstatistikler ve Grafikler Buraya Gelecek',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
