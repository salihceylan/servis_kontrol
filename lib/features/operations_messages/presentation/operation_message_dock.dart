import 'package:flutter/material.dart';
import 'package:servis_kontrol/core/theme/app_palette.dart';
import 'package:servis_kontrol/features/auth/domain/app_user.dart';
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
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
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
        if (!controller.isOpen) {
          return _CollapsedDockButton(
            unreadCount: controller.unreadCount,
            onTap: controller.toggleOpen,
          );
        }

        return Align(
          alignment: Alignment.bottomRight,
          child: Container(
            width: 380,
            height: 560,
            margin: const EdgeInsets.only(right: 20, bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppPalette.border),
              boxShadow: const [
                BoxShadow(
                  color: AppPalette.shadow,
                  blurRadius: 32,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              children: [
                _DockHeader(
                  unreadCount: controller.unreadCount,
                  onClose: controller.toggleOpen,
                ),
                Expanded(
                  child: controller.isLoading && controller.threads.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            _ContactStrip(
                              contacts: controller.contacts,
                              onTap: controller.openThreadWithContact,
                            ),
                            _ThreadList(
                              threads: controller.threads,
                              selectedThreadId: controller.selectedThread?.id,
                              onTap: controller.selectThread,
                            ),
                            Expanded(
                              child: _ActiveThreadPanel(
                                thread: controller.selectedThread,
                                errorMessage: controller.errorMessage,
                              ),
                            ),
                            _ComposerBar(
                              controller: _messageController,
                              sending: controller.isSending,
                              onSend: () async {
                                final success = await controller.sendMessage(
                                  _messageController.text,
                                );
                                if (success) {
                                  _messageController.clear();
                                }
                              },
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
  const _CollapsedDockButton({required this.unreadCount, required this.onTap});

  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 20, bottom: 20),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            FloatingActionButton.extended(
              onPressed: onTap,
              backgroundColor: AppPalette.text,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.forum_rounded),
              label: const Text('Operasyon Mesajları'),
            ),
            if (unreadCount > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppPalette.danger,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DockHeader extends StatelessWidget {
  const _DockHeader({required this.unreadCount, required this.onClose});

  final int unreadCount;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppPalette.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.forum_rounded, color: AppPalette.text),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Operasyon Mesajları',
                  style: TextStyle(
                    color: AppPalette.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  unreadCount > 0
                      ? '$unreadCount okunmamış mesaj var'
                      : 'Manager ve ekip lideri akışı',
                  style: const TextStyle(color: AppPalette.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded)),
        ],
      ),
    );
  }
}

class _ContactStrip extends StatelessWidget {
  const _ContactStrip({required this.contacts, required this.onTap});

  final List<OperationMessageContact> contacts;
  final ValueChanged<OperationMessageContact> onTap;

  @override
  Widget build(BuildContext context) {
    if (contacts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppPalette.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Yeni konuşma başlat',
            style: TextStyle(
              color: AppPalette.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: contacts.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final contact = contacts[index];
                final detail = contact.teamName.isEmpty
                    ? contact.roleLabel
                    : '${contact.roleLabel} • ${contact.teamName}';
                return ActionChip(
                  label: Text('${contact.name} · $detail'),
                  onPressed: () => onTap(contact),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreadList extends StatelessWidget {
  const _ThreadList({
    required this.threads,
    required this.selectedThreadId,
    required this.onTap,
  });

  final List<OperationMessageThread> threads;
  final String? selectedThreadId;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    if (threads.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        child: const Text(
          'Henüz operasyon konuşması yok. Üstten bir ekip lideri veya yönetici seçerek ilk konuşmayı aç.',
          style: TextStyle(color: AppPalette.muted, height: 1.5),
        ),
      );
    }

    return SizedBox(
      height: 132,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        scrollDirection: Axis.horizontal,
        itemCount: threads.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final thread = threads[index];
          final selected = thread.id == selectedThreadId;
          return GestureDetector(
            onTap: () => onTap(thread.id),
            child: Container(
              width: 214,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected
                    ? AppPalette.primarySoft
                    : AppPalette.background,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? AppPalette.primary : AppPalette.border,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          thread.counterpartName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppPalette.text,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (thread.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppPalette.danger,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${thread.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    thread.counterpartTeamName.isEmpty
                        ? thread.counterpartRoleLabel
                        : '${thread.counterpartRoleLabel} • ${thread.counterpartTeamName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppPalette.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    thread.lastMessagePreview,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppPalette.text, height: 1.4),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ActiveThreadPanel extends StatelessWidget {
  const _ActiveThreadPanel({required this.thread, required this.errorMessage});

  final OperationMessageThread? thread;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (thread == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Text(
            'Bir konuşma seçildiğinde mesaj akışı burada açılır.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppPalette.muted, height: 1.5),
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppPalette.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                thread!.counterpartName,
                style: const TextStyle(
                  color: AppPalette.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                thread!.counterpartTeamName.isEmpty
                    ? thread!.counterpartRoleLabel
                    : '${thread!.counterpartRoleLabel} • ${thread!.counterpartTeamName}',
                style: const TextStyle(color: AppPalette.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
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
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: thread!.messages.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final message = thread!.messages[index];
              final mine = message.isMine;
              return Align(
                alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 250),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: mine ? AppPalette.text : AppPalette.background,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!mine)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            message.senderName,
                            style: const TextStyle(
                              color: AppPalette.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      Text(
                        message.body,
                        style: TextStyle(
                          color: mine ? Colors.white : AppPalette.text,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(
                          color: mine ? Colors.white70 : AppPalette.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }
}

class _ComposerBar extends StatelessWidget {
  const _ComposerBar({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppPalette.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'Mesaj yaz...'),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: sending ? null : onSend,
            icon: const Icon(Icons.send_rounded),
            label: Text(sending ? '...' : 'Gönder'),
          ),
        ],
      ),
    );
  }
}
