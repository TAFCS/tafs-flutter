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

  @override
  void initState() {
    super.initState();
    _cubit = TicketThreadCubit(repository: InjectionContainer.supportTicketRepository);
    _cubit.load(widget.ticketId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Query'),
          backgroundColor: AppTheme.white,
          foregroundColor: AppTheme.navy,
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
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Close')),
                        ],
                      ),
                    );
                    if (ok == true) await context.read<TicketThreadCubit>().closeTicket();
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
              return const Center(child: CircularProgressIndicator());
            }
            final ticket = state.ticket;
            if (ticket == null) {
              return Center(child: Text(state.error ?? 'Not found'));
            }
            return Column(
              children: [
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
                              '${ticket.category.name} · ${ticket.subtopic ?? ''}',
                              overflow: TextOverflow.ellipsis,
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
                  child: ListView.builder(
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
                  MessageInput(
                    replyingTo: null,
                    onCancelReply: () {},
                    students: const [],
                    onSend: (content, type, file, replyTo, batchId) async {
                      final cubit = context.read<TicketThreadCubit>();
                      if (file != null) {
                        final media = await InjectionContainer.supportTicketRepository.uploadMedia(file);
                        final messageType = type == ChatMessageType.voice
                            ? 'VOICE'
                            : type == ChatMessageType.image
                                ? 'IMAGE'
                                : 'DOCUMENT';
                        await cubit.sendMedia(
                          messageType: messageType,
                          content: content.isEmpty ? file.name : content,
                          mediaMetadata: media,
                        );
                      } else {
                        await cubit.sendText(content);
                      }
                      await cubit.load(ticket.id);
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
