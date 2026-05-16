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
  final bool isTab;
  const ChatPage({super.key, this.isTab = false});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late ChatBloc _chatBloc;
  ChatMessage? _replyingTo;
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

  @override
  void initState() {
    super.initState();
    _chatBloc = context.read<ChatBloc>();
  }

  @override
  void dispose() {
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

  String _formatDateSeparator(DateTime dateUtc) {
    final date = dateUtc.toLocal();
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: widget.isTab
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[100],
              backgroundImage: const AssetImage('assets/logo.png'),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TAFS Support',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'ONLINE',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.grey[600]),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          // Watermark Background
          Center(
            child: Opacity(
              opacity: 0.05,
              child: Image.asset(
                'assets/logo.png',
                width: MediaQuery.of(context).size.width * 0.7,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: BlocBuilder<ChatBloc, ChatState>(
                  builder: (context, state) {
                    if (state is ChatInitial || state is ChatLoading) {
                      return const Center(child: CircularProgressIndicator());
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

                      return ScrollablePositionedList.builder(
                        itemScrollController: _itemScrollController,
                        itemPositionsListener: _itemPositionsListener,
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                        itemCount: clusters.length,
                        reverse: true,
                        itemBuilder: (context, index) {
                          final item = clusters[index];
                          final allImageUrls = state.messages
                              .where((m) => m.messageType == ChatMessageType.image)
                              .map((m) => m.mediaMetadata?['url'] as String? ?? m.content)
                              .toList()
                              .reversed
                              .toList();

                          final message = item is List<ChatMessage> 
                              ? (item.isNotEmpty ? item.first : (item as dynamic)[0]) // Safety
                              : item as ChatMessage;
                          bool showDateSeparator = false;
                          if (index == clusters.length - 1) {
                            showDateSeparator = true;
                          } else {
                            final nextItem = clusters[index + 1];
                            final nextMessage = nextItem is List<ChatMessage> 
                                ? (nextItem.isNotEmpty ? nextItem.first : (nextItem as dynamic)[0]) // Safety
                                : nextItem as ChatMessage;
                            final currentLocal = message.createdAt.toLocal();
                            final nextLocal = nextMessage.createdAt.toLocal();
                            if (currentLocal.day != nextLocal.day ||
                                currentLocal.month != nextLocal.month ||
                                currentLocal.year != nextLocal.year) {
                              showDateSeparator = true;
                            }
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 24.0),
                            child: Column(
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
                            ),
                          );
                        },
                      );
                    }
                    return const Center(child: Text('Something went wrong'));
                  },
                ),
              ),
              BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  return MessageInput(
                    replyingTo: _replyingTo,
                    onCancelReply: () => setState(() => _replyingTo = null),
                    students: state is ChatLoaded ? (state as ChatLoaded).students : [],
                    onSend: (content, type, file, replyTo, metadata) {
                      context.read<ChatBloc>().add(ChatMessageSent(
                        content: content,
                        type: type,
                        file: file,
                        replyTo: replyTo,
                        mediaMetadata: metadata,
                      ));
                      // Clear reply after sending
                      if (_replyingTo != null) {
                        setState(() => _replyingTo = null);
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
