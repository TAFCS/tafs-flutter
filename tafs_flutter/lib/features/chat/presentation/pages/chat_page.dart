import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/full_screen_image_viewer.dart';
import '../widgets/swipe_to_reply.dart';
import '../../domain/repositories/chat_repository.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/chat_message.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late ChatBloc _chatBloc;
  ChatMessage? _replyingTo;
  final ItemScrollController _itemScrollController = ItemScrollController();

  @override
  void initState() {
    super.initState();
    _chatBloc = context.read<ChatBloc>();
    _chatBloc.add(ChatEntered());
  }

  @override
  void dispose() {
    _chatBloc.add(ChatLeft());
    super.dispose();
  }

  void _scrollToMessage(List<dynamic> clusters, String messageId) {
    int index = -1;
    for (int i = 0; i < clusters.length; i++) {
      final item = clusters[i];
      if (item is ChatMessage && item.id == messageId) {
        index = i;
        break;
      } else if (item is List<ChatMessage> && item.any((m) => m.id == messageId)) {
        index = i;
        break;
      }
    }

    if (index != -1) {
      _itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  String _formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(date.year, date.month, date.day);

    if (msgDate == today) return 'TODAY';
    if (msgDate == yesterday) return 'YESTERDAY';
    return DateFormat('MMMM d, yyyy').format(date).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[100]!, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TAFS Support',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Online',
                  style: TextStyle(fontSize: 12, color: Colors.greenAccent),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {},
          ),
        ],
      ),
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          if (state is ChatInitial || state is ChatLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ChatError) {
            return Center(child: Text('Error: ${state.message}'));
          }

          if (state is ChatLoaded) {
            final clusters = <dynamic>[];
            for (int i = 0; i < state.messages.length; i++) {
              final msg = state.messages[i];
              if (msg.messageType == ChatMessageType.image) {
                final group = [msg];
                while (i + 1 < state.messages.length &&
                    state.messages[i + 1].messageType == ChatMessageType.image &&
                    state.messages[i + 1].senderType == msg.senderType &&
                    state.messages[i + 1].mediaMetadata?['batchId'] == msg.mediaMetadata?['batchId'] &&
                    msg.mediaMetadata?['batchId'] != null) {
                  group.add(state.messages[i + 1]);
                  i++;
                }
                clusters.add(group);
              } else {
                clusters.add(msg);
              }
            }

            return Column(
              children: [
                Expanded(
                  child: ScrollablePositionedList.builder(
                    itemScrollController: _itemScrollController,
                    reverse: true,
                    itemCount: clusters.length,
                    padding: const EdgeInsets.only(bottom: 24),
                    itemBuilder: (context, index) {
                      final item = clusters[index];
                      final allImageUrls = state.messages
                          .where((m) => m.messageType == ChatMessageType.image)
                          .map((m) => m.mediaMetadata?['url'] as String? ?? m.content)
                          .toList()
                          .reversed
                          .toList();

                      final message = item is List<ChatMessage> ? item.first : item as ChatMessage;
                      bool showDateSeparator = false;
                      if (index == clusters.length - 1) {
                        showDateSeparator = true;
                      } else {
                        final nextItem = clusters[index + 1];
                        final nextMessage = nextItem is List<ChatMessage> ? nextItem.first : nextItem as ChatMessage;
                        if (message.createdAt.day != nextMessage.createdAt.day ||
                            message.createdAt.month != nextMessage.createdAt.month ||
                            message.createdAt.year != nextMessage.createdAt.year) {
                          showDateSeparator = true;
                        }
                      }

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (showDateSeparator)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _formatDateSeparator(message.createdAt),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.grey[600],
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          SwipeToReply(
                            onReply: () {
                              setState(() {
                                _replyingTo = item is List<ChatMessage> ? item.first : item as ChatMessage;
                              });
                            },
                            child: ChatBubble(
                              messages: item is List<ChatMessage> ? item : [item as ChatMessage],
                              onReplyTap: (id) => _scrollToMessage(clusters, id),
                              onImageTap: (url) {
                                final imageIndex = allImageUrls.indexOf(url);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FullScreenImageViewer(
                                      imageUrls: allImageUrls,
                                      initialIndex: imageIndex >= 0 ? imageIndex : 0,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                MessageInput(
                  replyingTo: _replyingTo,
                  onCancelReply: () => setState(() => _replyingTo = null),
                  onSend: (content, type, file, replyTo, metadata) {
                    final fullMetadata = <String, dynamic>{};
                    if (metadata != null) {
                      fullMetadata.addAll(metadata);
                    }
                    
                    if (replyTo != null) {
                      fullMetadata['replyTo'] = {
                        'id': replyTo.id,
                        'content': replyTo.content,
                        'senderName': replyTo.senderType == ChatSenderType.guardian ? 'You' : 'TAFS Support',
                        'type': replyTo.messageType.name,
                      };
                    }

                    context.read<ChatBloc>().add(ChatMessageSent(
                          content: content,
                          type: type,
                          file: file,
                          mediaMetadata: fullMetadata.isNotEmpty ? fullMetadata : null,
                        ));
                    setState(() => _replyingTo = null);
                  },
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
