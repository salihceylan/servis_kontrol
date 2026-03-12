import 'package:flutter/material.dart';
import 'package:servis_kontrol/core/theme/app_palette.dart';

class StatePanel extends StatelessWidget {
  const StatePanel.loading({
    super.key,
    this.title = 'Veri yükleniyor',
    this.message = 'Canlı kayıtlar sunucudan alınıyor.',
  })  : icon = Icons.sync_rounded,
        color = AppPalette.primary,
        onRetry = null;

  const StatePanel.error({
    super.key,
    required this.message,
    this.title = 'Veri alınamadı',
    this.onRetry,
  })  : icon = Icons.error_outline_rounded,
        color = AppPalette.danger;

  const StatePanel.empty({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
  })  : icon = Icons.inbox_outlined,
        color = AppPalette.muted;

  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPalette.border),
        boxShadow: const [
          BoxShadow(
            color: AppPalette.shadow,
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: AppPalette.text,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: AppPalette.muted, height: 1.5),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tekrar dene'),
            ),
          ],
        ],
      ),
    );
  }
}
