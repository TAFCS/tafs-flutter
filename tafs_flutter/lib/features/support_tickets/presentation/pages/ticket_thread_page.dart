import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../injection_container.dart';
import '../../../chat/domain/entities/chat_message.dart';
import '../../../chat/presentation/widgets/chat_bubble.dart';
import '../../../chat/presentation/widgets/full_screen_image_viewer.dart';
import '../../../chat/presentation/widgets/message_input.dart';
import '../bloc/ticket_thread_cubit.dart';
import '../utils/ticket_message_mapper.dart';
import '../widgets/ticket_status_badge.dart';

class TicketThreadPage extends StatefulWidget {
  final String ticketId;
  const TicketThreadPage({super.key, required this.ticketId});

  @override
  State<TicketThreadPage> createState() => _TicketThreadPageState();
}

class _TicketThreadPageState extends State<TicketThreadPage> {
  late final TicketThreadCubit _cubit;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _cubit = TicketThreadCubit(repository: InjectionContainer.supportTicketRepository);
    _cubit.load(widget.ticketId);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String _categoryLabel(String name) {
    if (name == 'financial') return 'Financial';
    if (name == 'general') return 'General';
    return name;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<TicketThreadCubit, TicketThreadState>(
        listenWhen: (prev, curr) => curr.messages.length != prev.messages.length,
        listener: (_, __) => _scrollToBottom(),
        child: Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            title: const Text('TAFS Support'),
            backgroundColor: AppTheme.white,
            foregroundColor: AppTheme.navy,
            elevation: 0,
            actions: [
              BlocBuilder<TicketThreadCubit, TicketThreadState>(
                builder: (context, state) {
                  final ticket = state.ticket;
                  if (ticket == null || ticket.status.name == 'closed') {
                    return const SizedBox.shrink();
                  }
                  return TextButton(
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Close query?'),
                          content: const Text(
                            'You will not be able to send more messages on this ticket.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true && context.mounted) {
                        await context.read<TicketThreadCubit>().closeTicket();
                      }
                    },
                    child: const Text('Close'),
                  );
                },
              ),
            ],
          ),
          body: BlocBuilder<TicketThreadCubit, TicketThreadState>(
            builder: (context, state) {
              if (state.loading && state.ticket == null) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.navy));
              }
              final ticket = state.ticket;
              if (ticket == null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          state.error ?? 'Query not found',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.read<TicketThreadCubit>().load(widget.ticketId),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  if (state.error != null)
                    Material(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                state.error!,
                                style: TextStyle(color: Colors.red.shade800, fontSize: 12),
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.read<TicketThreadCubit>().load(widget.ticketId),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            TicketStatusBadge(status: ticket.status),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${_categoryLabel(ticket.category.name)} · ${ticket.subtopic ?? ''}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(ticket.description, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: state.messages.isEmpty
                        ? const Center(
                            child: Text(
                              'No messages yet.\nSend a message to start the conversation.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTheme.blue300),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(12),
                            itemCount: state.messages.length,
                            itemBuilder: (context, i) {
                              final chatMsg = ticketMessageToChatMessage(state.messages[i]);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: ChatBubble(
                                  messages: [chatMsg],
                                  onImageTap: (url) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => FullScreenImageViewer(
                                          imageUrls: [url],
                                          initialIndex: 0,
                                        ),
                                      ),
                                    );
                                  },
                                  onReplyTap: (_) {},
                                  onReply: (_) {},
                                ),
                              );
                            },
                          ),
                  ),
                  if (ticket.status.name != 'closed')
                    Stack(
                      children: [
                        AbsorbPointer(
                          absorbing: state.sending,
                          child: MessageInput(
                            replyingTo: null,
                            onCancelReply: () {},
                            students: const [],
                            onSend: (content, type, file, replyTo, batchId) async {
                            final cubit = context.read<TicketThreadCubit>();
                            if (file != null) {
                              final media = await InjectionContainer.supportTicketRepository.uploadMedia(file);
                              final mediaUrl = media['url'] as String?;
                              final messageType = type == ChatMessageType.voice
                                  ? 'VOICE'
                                  : type == ChatMessageType.image
                                      ? 'IMAGE'
                                      : 'DOCUMENT';
                              await cubit.sendMedia(
                                messageType: messageType,
                                content: mediaUrl ?? (content.isEmpty ? file.name : content),
                                mediaMetadata: media,
                              );
                            } else {
                              await cubit.sendText(content);
                            }
                            _scrollToBottom();
                          },
                        ),
                        ),
                        if (state.sending)
                          const Positioned.fill(
                            child: ColoredBox(
                              color: Color(0x33FFFFFF),
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.navy),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
