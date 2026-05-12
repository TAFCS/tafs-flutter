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
import '../../domain/entities/chat_message.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  ChatMessage? _replyingTo;
  final ItemScrollController _itemScrollController = ItemScrollController();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.school, color: Colors.white),
            ),
            SizedBox(width: 12),
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
                    itemBuilder: (context, index) {
                      final item = clusters[index];
                      final allImageUrls = state.messages
                          .where((m) => m.messageType == ChatMessageType.image)
                          .map((m) => m.mediaMetadata?['url'] as String? ?? m.content)
                          .toList()
                          .reversed
                          .toList();

                      return SwipeToReply(
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
                      );
                    },
                  ),
                ),
                MessageInput(
                  replyingTo: _replyingTo,
                  onCancelReply: () => setState(() => _replyingTo = null),
                  onSend: (content, type, file, replyTo) {
                    Map<String, dynamic>? metadata;
                    if (replyTo != null) {
                      metadata = {
                        'replyTo': {
                          'id': replyTo.id,
                          'content': replyTo.content,
                          'senderName': replyTo.senderType == ChatSenderType.guardian ? 'You' : 'TAFS Support',
                          'type': replyTo.messageType.name,
                        }
                      };
                    }

                    context.read<ChatBloc>().add(ChatMessageSent(
                          content: content,
                          type: type,
                          file: file,
                          mediaMetadata: metadata,
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
