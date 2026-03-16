import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:servis_kontrol/core/theme/app_palette.dart';
import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/auth/domain/user_role.dart';
import 'package:servis_kontrol/features/operations_messages/application/operation_message_dock_controller.dart';
import 'package:servis_kontrol/features/operations_messages/domain/operation_message_thread.dart';

class OperationMessageDock extends StatefulWidget {
  const OperationMessageDock({
    super.key,
    required this.user,
    required this.controller,
  });

  final AppUser user;
  final OperationMessageDockController controller;

  @override
  State<OperationMessageDock> createState() => _OperationMessageDockState();
}

class _OperationMessageDockState extends State<OperationMessageDock> {
  final _composer = TextEditingController();

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final sent = await widget.controller.sendMessage(_composer.text);
    if (sent) {
      _composer.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.controller.shouldShow) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final palette = context.rolePalette;
        if (!controller.isOpen) {
          return _CollapsedDockButton(
            palette: palette,
            unreadCount: controller.unreadCount,
            roleLabel: widget.user.role.label,
            onTap: controller.toggleOpen,
          );
        }

        final size = MediaQuery.sizeOf(context);
        final width = math.max(360.0, math.min(size.width - 16, 900.0));
        final height = math.max(520.0, math.min(size.height - 24, 640.0));
        final wide = width >= 760;

        return Align(
          alignment: Alignment.bottomRight,
          child: Container(
            width: width,
            height: height,
            margin: const EdgeInsets.only(right: 14, bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: palette.border),
              boxShadow: [
                BoxShadow(
                  color: palette.shadow,
                  blurRadius: 40,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              children: [
                _DockHeader(
                  palette: palette,
                  unreadCount: controller.unreadCount,
                  roleLabel: widget.user.role.label,
                  onClose: controller.toggleOpen,
                ),
                Expanded(
                  child: controller.isLoading && controller.threads.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : wide
                      ? Row(
                          children: [
                            SizedBox(
                              width: 312,
                              child: _LeftPane(
                                palette: palette,
                                contacts: controller.contacts,
                                broadcastTargets: controller.broadcastTargets,
                                threads: controller.threads,
                                selectedThreadId:
                                    controller.selectedThread?.id,
                                onContactTap:
                                    controller.openThreadWithContact,
                                onBroadcastTap:
                                    controller.openBroadcastTarget,
                                onThreadTap: controller.selectThread,
                              ),
                            ),
                            Expanded(
                              child: _RightPane(
                                palette: palette,
                                thread: controller.selectedThread,
                                errorMessage: controller.errorMessage,
                                controller: _composer,
                                isSending: controller.isSending,
                                onSend: _send,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: _LeftPane(
                                palette: palette,
                                contacts: controller.contacts,
                                broadcastTargets: controller.broadcastTargets,
                                threads: controller.threads,
                                selectedThreadId:
                                    controller.selectedThread?.id,
                                onContactTap:
                                    controller.openThreadWithContact,
                                onBroadcastTap:
                                    controller.openBroadcastTarget,
                                onThreadTap: controller.selectThread,
                              ),
                            ),
                            SizedBox(
                              height: height * 0.46,
                              child: _RightPane(
                                palette: palette,
                                thread: controller.selectedThread,
                                errorMessage: controller.errorMessage,
                                controller: _composer,
                                isSending: controller.isSending,
                                onSend: _send,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CollapsedDockButton extends StatelessWidget {
  const _CollapsedDockButton({
    required this.palette,
    required this.unreadCount,
    required this.roleLabel,
    required this.onTap,
  });

  final AppRolePalette palette;
  final int unreadCount;
  final String roleLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 18, bottom: 18),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(22),
              child: Ink(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    colors: [palette.sidebar, palette.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.campaign_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Operasyon Mesajları',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          unreadCount > 0
                              ? '$unreadCount yeni mesaj'
                              : '$roleLabel kanalı',
                          style: const TextStyle(
                            color: Color(0xCCFFFFFF),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                top: -4,
                right: -4,
                child: _UnreadBadge(count: unreadCount),
              ),
          ],
        ),
      ),
    );
  }
}

class _DockHeader extends StatelessWidget {
  const _DockHeader({
    required this.palette,
    required this.unreadCount,
    required this.roleLabel,
    required this.onClose,
  });

  final AppRolePalette palette;
  final int unreadCount;
  final String roleLabel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 14, 18),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        gradient: LinearGradient(
          colors: [palette.sidebar, palette.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.forum_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mesaj Merkezi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  unreadCount > 0
                      ? '$unreadCount okunmamış mesaj · $roleLabel'
                      : '$roleLabel için yayın ve koordinasyon akışı',
                  style: const TextStyle(
                    color: Color(0xCCFFFFFF),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _LeftPane extends StatelessWidget {
  const _LeftPane({
    required this.palette,
    required this.contacts,
    required this.broadcastTargets,
    required this.threads,
    required this.selectedThreadId,
    required this.onContactTap,
    required this.onBroadcastTap,
    required this.onThreadTap,
  });

  final AppRolePalette palette;
  final List<OperationMessageContact> contacts;
  final List<OperationMessageBroadcastTarget> broadcastTargets;
  final List<OperationMessageThread> threads;
  final String? selectedThreadId;
  final ValueChanged<OperationMessageContact> onContactTap;
  final ValueChanged<OperationMessageBroadcastTarget> onBroadcastTap;
  final ValueChanged<String> onThreadTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
        ),
        border: Border(right: BorderSide(color: palette.border)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: palette.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hızlı Başlat',
                  style: TextStyle(
                    color: AppPalette.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (broadcastTargets.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final target in broadcastTargets)
                        _ActionCard(
                          palette: palette,
                          icon: target.isCompanyWide
                              ? Icons.campaign_rounded
                              : Icons.groups_rounded,
                          title: target.label,
                          subtitle: '${target.participantCount} kisi',
                          onTap: () => onBroadcastTap(target),
                        ),
                    ],
                  ),
                ],
                if (contacts.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Direkt Hat',
                    style: TextStyle(
                      color: palette.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final contact in contacts)
                        ActionChip(
                          label: Text(contact.name),
                          onPressed: () => onContactTap(contact),
                        ),
                    ],
                  ),
                ],
                if (broadcastTargets.isEmpty && contacts.isEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Bu rolde yeni kanal acma yetkisi yok. Size gelen mesajlar asagida gorunur.',
                    style: TextStyle(color: palette.muted, height: 1.45),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: threads.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Henüz açık bir operasyon konusu yok.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: palette.muted, height: 1.45),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: threads.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final thread = threads[index];
                      return _ThreadTile(
                        palette: palette,
                        thread: thread,
                        selected: thread.id == selectedThreadId,
                        onTap: () => onThreadTap(thread.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.palette,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final AppRolePalette palette;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 126,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: palette.primarySoft,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: palette.primary),
              const SizedBox(height: 10),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppPalette.text,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  color: palette.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({
    required this.palette,
    required this.thread,
    required this.selected,
    required this.onTap,
  });

  final AppRolePalette palette;
  final OperationMessageThread thread;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? Colors.white : palette.surfaceMuted,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? palette.primary : palette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  switch (thread.threadType) {
                    'company_broadcast' => Icons.campaign_rounded,
                    'team_broadcast' => Icons.groups_rounded,
                    _ => Icons.forum_rounded,
                  },
                  color: palette.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    thread.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppPalette.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (thread.unreadCount > 0)
                  _UnreadBadge(count: thread.unreadCount),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              thread.lastMessagePreview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: palette.text, height: 1.4),
            ),
            const SizedBox(height: 8),
            Text(
              '${thread.channelLabel} · ${thread.participantCount} kisi',
              style: TextStyle(
                color: palette.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RightPane extends StatelessWidget {
  const _RightPane({
    required this.palette,
    required this.thread,
    required this.errorMessage,
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final AppRolePalette palette;
  final OperationMessageThread? thread;
  final String? errorMessage;
  final TextEditingController controller;
  final bool isSending;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) {
    if (thread == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(
            errorMessage ?? 'Soldan bir kanal secildiginde mesaj akisi burada acilir.',
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.muted, height: 1.5),
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: palette.border)),
          ),
          child: Row(
            children: [
              Icon(
                thread!.isBroadcast
                    ? Icons.campaign_rounded
                    : Icons.support_agent_rounded,
                color: palette.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      thread!.title,
                      style: const TextStyle(
                        color: AppPalette.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${thread!.channelLabel} · ${thread!.participantCount} kisi',
                      style: TextStyle(
                        color: palette.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                errorMessage!,
                style: const TextStyle(
                  color: AppPalette.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        Expanded(
          child: Container(
            color: palette.surfaceMuted,
            child: ListView.separated(
              padding: const EdgeInsets.all(18),
              itemCount: thread!.messages.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final message = thread!.messages[index];
                final mine = message.isMine;
                return Align(
                  alignment:
                      mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 420),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: mine ? palette.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: mine ? null : Border.all(color: palette.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!mine)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              message.senderName,
                              style: TextStyle(
                                color: palette.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        Text(
                          message.body,
                          style: TextStyle(
                            color: mine ? Colors.white : palette.text,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _formatStamp(message.createdAt),
                          style: TextStyle(
                            color: mine
                                ? const Color(0xD9FFFFFF)
                                : palette.muted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: palette.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!thread!.canReply)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Bu kanal salt okunur. Duyurulari gorebilirsiniz.',
                    style: TextStyle(
                      color: palette.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      enabled: thread!.canReply && !isSending,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) async {
                        if (thread!.canReply && !isSending) {
                          await onSend();
                        }
                      },
                      decoration: InputDecoration(
                        hintText: thread!.canReply
                            ? 'Mesajini yaz...'
                            : 'Bu kanalda mesaj gonderemezsin',
                        fillColor: palette.surfaceMuted,
                        filled: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: !thread!.canReply || isSending ? null : onSend,
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.primary,
                      foregroundColor: Colors.white,
                    ),
                    icon: Icon(
                      isSending
                          ? Icons.hourglass_top_rounded
                          : Icons.send_rounded,
                    ),
                    label: Text(isSending ? 'Gonderiliyor' : 'Gonder'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppPalette.danger,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _formatStamp(DateTime value) {
  final now = DateTime.now();
  if (DateUtils.isSameDay(now, value)) {
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }
  return '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
