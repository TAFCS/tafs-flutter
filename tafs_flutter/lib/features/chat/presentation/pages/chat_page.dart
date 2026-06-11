import 'dart:math' show max;
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

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  late ChatBloc _chatBloc;
  ChatMessage? _replyingTo;
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  int _clusterCount = 0;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _chatBloc = context.read<ChatBloc>();
    _chatBloc.add(ChatViewEntered());
    _itemPositionsListener.itemPositions.addListener(_onScrollPositionChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatBloc.add(ChatViewLeft());
    _itemPositionsListener.itemPositions.removeListener(_onScrollPositionChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _chatBloc.add(ChatViewLeft());
    } else if (state == AppLifecycleState.resumed) {
      _chatBloc.add(ChatViewEntered());
    }
  }

  void _onScrollPositionChanged() {
    if (_isLoadingMore) return;
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;
    final maxIndex = positions.map((p) => p.index).reduce(max);
    final s = _chatBloc.state;
    if (s is! ChatLoaded || s.hasReachedMax) return;
    // With reverse:true, high index = oldest messages (top of screen).
    // Trigger when the user scrolls within 3 clusters of the oldest end.
    if (maxIndex >= _clusterCount - 3) {
      setState(() => _isLoadingMore = true);
      _chatBloc.add(ChatHistoryLoaded());
    }
  }

  void _scrollToMessage(List<List<ChatMessage>> clusters, String messageId) {
    int index = -1;
    for (int i = 0; i < clusters.length; i++) {
      if (clusters[i].any((m) => m.id == messageId)) {
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
      backgroundColor: Colors.grey[100],
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
                BlocBuilder<ChatBloc, ChatState>(
                  buildWhen: (prev, next) {
                    final prevConnected = prev is ChatLoaded && prev.isSocketConnected;
                    final nextConnected = next is ChatLoaded && next.isSocketConnected;
                    return prevConnected != nextConnected;
                  },
                  builder: (context, state) {
                    final connected = state is ChatLoaded && state.isSocketConnected;
                    final dotColor = connected ? Colors.green : Colors.orange;
                    final label = connected ? 'ONLINE' : 'RECONNECTING...';
                    return Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          label,
                          style: TextStyle(
                            color: dotColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    );
                  },
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
      body: Column(
        children: [
              Expanded(
                child: BlocConsumer<ChatBloc, ChatState>(
                  listener: (context, state) {
                    if (state is ChatLoaded && _isLoadingMore) {
                      setState(() => _isLoadingMore = false);
                    }
                  },
                  builder: (context, state) {
                    if (state is ChatInitial || state is ChatLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is ChatLoaded) {
                      final List<List<ChatMessage>> clusters = [];
                      for (int i = state.messages.length - 1; i >= 0; i--) {
                        final msg = state.messages[i];
                        if (clusters.isEmpty) {
                          clusters.add([msg]);
                        } else {
                          final lastCluster = clusters.last;
                          final lastMsg = lastCluster.last;
                          final sameSender = lastMsg.senderType == msg.senderType;
                          final timeDiff = msg.createdAt.difference(lastMsg.createdAt).abs();
                          final withinOneHour = timeDiff.inHours < 1;

                          if (sameSender && withinOneHour) {
                            lastCluster.add(msg);
                          } else {
                            clusters.add([msg]);
                          }
                        }
                      }
                      final reversedClusters = clusters.reversed.toList();
                      _clusterCount = reversedClusters.length;

                      return ScrollablePositionedList.builder(
                        itemScrollController: _itemScrollController,
                        itemPositionsListener: _itemPositionsListener,
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                        itemCount: reversedClusters.length + (_isLoadingMore ? 1 : 0),
                        reverse: true,
                        itemBuilder: (context, index) {
                          // Loading spinner at the top (oldest end) while fetching more
                          if (index == reversedClusters.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          }
                          final item = reversedClusters[index];
                          final allImageUrls = state.messages
                              .where((m) => m.messageType == ChatMessageType.image)
                              .map((m) => m.mediaMetadata?['url'] as String? ?? m.content)
                              .toList()
                              .reversed
                              .toList();

                          final message = item.first;
                          bool showDateSeparator = false;
                          if (index == reversedClusters.length - 1) {
                            showDateSeparator = true;
                          } else {
                            final nextItem = reversedClusters[index + 1];
                            final nextMessage = nextItem.first;
                            final currentLocal = message.createdAt.toLocal();
                            final nextLocal = nextMessage.createdAt.toLocal();
                            if (currentLocal.day != nextLocal.day ||
                                currentLocal.month != nextLocal.month ||
                                currentLocal.year != nextLocal.year) {
                              showDateSeparator = true;
                            }
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
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
                                ChatBubble(
                                  messages: item,
                                  onReplyTap: (id) => _scrollToMessage(reversedClusters, id),
                                  onReply: (message) {
                                    setState(() {
                                      _replyingTo = message;
                                    });
                                  },
                                  onRetryTap: (id) {
                                    context.read<ChatBloc>().add(ChatMessageRetry(id));
                                  },
                                  onAcknowledge: (messageId) {
                                    context.read<ChatBloc>().add(ChatMessageAcknowledged(messageId));
                                  },
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
                    students: state is ChatLoaded ? state.students : [],
                    onSend: (content, type, file, replyTo, batchId) {
                      context.read<ChatBloc>().add(ChatMessageSent(
                        content: content,
                        type: type,
                        file: file,
                        replyTo: replyTo,
                        batchId: batchId,
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
    );
  }
}
