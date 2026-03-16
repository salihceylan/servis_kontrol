import 'package:flutter/material.dart';
import 'package:servis_kontrol/core/theme/app_palette.dart';
import 'package:servis_kontrol/features/dashboard/domain/dashboard_snapshot.dart';
import 'package:servis_kontrol/features/notifications/application/notification_center_controller.dart';

class NotificationCenterDialog extends StatelessWidget {
  const NotificationCenterDialog({super.key, required this.controller});

  final NotificationCenterController controller;

  @override
  Widget build(BuildContext context) {
    final palette = context.rolePalette;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Container(
            width: 540,
            constraints: const BoxConstraints(maxHeight: 680),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Bildirim Merkezi',
                        style: TextStyle(
                          color: AppPalette.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (controller.unreadCount > 0)
                      TextButton(
                        onPressed: controller.markAllRead,
                        child: const Text('Tumunu okundu yap'),
                      ),
                  ],
                ),
                Text(
                  controller.unreadCount > 0
                      ? '${controller.unreadCount} okunmamis bildirim var'
                      : 'Yeni operasyon bildirimleri burada gorunur.',
                  style: TextStyle(color: palette.muted),
                ),
                const SizedBox(height: 16),
                if (controller.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      controller.errorMessage!,
                      style: const TextStyle(
                        color: AppPalette.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                Flexible(
                  child: controller.isLoading && controller.items.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : controller.items.isEmpty
                      ? Center(
                          child: Text(
                            'Simdilik bekleyen bildirim yok.',
                            style: TextStyle(color: palette.muted),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: controller.items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = controller.items[index];
                            final color = dashboardAccentColor(item.accentKey);
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: item.isRead
                                    ? Colors.white
                                    : color.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: item.isRead ? palette.border : color,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: color.withValues(
                                      alpha: 0.18,
                                    ),
                                    child: Icon(
                                      Icons.notifications_active_rounded,
                                      color: color,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.title,
                                                style: const TextStyle(
                                                  color: AppPalette.text,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              item.createdAtLabel,
                                              style: TextStyle(
                                                color: palette.muted,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          item.body,
                                          style: TextStyle(
                                            color: palette.text,
                                            height: 1.45,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!item.isRead) ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () =>
                                          controller.markRead(item.id),
                                      icon: const Icon(
                                        Icons.done_all_rounded,
                                        size: 20,
                                      ),
                                      tooltip: 'Okundu yap',
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
