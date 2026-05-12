import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/chat_message.dart';
import 'package:intl/intl.dart';

class ChatBubble extends StatelessWidget {
  final List<ChatMessage> messages;
  final Function(String) onImageTap;

  final Function(String) onReplyTap;

  const ChatBubble({
    super.key, 
    required this.messages,
    required this.onImageTap,
    required this.onReplyTap,
  });

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) return const SizedBox.shrink();
    final message = messages.first;
    final isMe = message.senderType == ChatSenderType.guardian;
    final theme = Theme.of(context);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe && message.isAnnouncement)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 6, top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.campaign_rounded, size: 14, color: theme.primaryColor),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'TAFS Support',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: theme.primaryColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      'OFFICIAL',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            margin: EdgeInsets.only(
              top: 2,
              bottom: 2,
              left: isMe ? 64 : 12,
              right: isMe ? 12 : 64,
            ),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              gradient: isMe 
                  ? LinearGradient(
                      colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : (message.isAnnouncement 
                      ? LinearGradient(
                          colors: [Colors.white, theme.primaryColor.withOpacity(0.05)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null),
              color: !isMe && !message.isAnnouncement ? Colors.white : null,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 20),
              ),
              border: !isMe && message.isAnnouncement 
                  ? Border.all(color: theme.primaryColor.withOpacity(0.15), width: 1)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.mediaMetadata?['replyTo'] != null)
                  _buildReplyPreview(context, message.mediaMetadata!['replyTo']),
                _buildContent(context),
                Padding(
                  padding: const EdgeInsets.only(right: 12, bottom: 6, left: 12, top: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('h:mm a').format(message.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isMe ? Colors.white.withOpacity(0.7) : Colors.black38,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        if (message.status == MessageStatus.sending)
                          SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.7)),
                            ),
                          )
                        else if (message.status == MessageStatus.error)
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 14,
                            color: Colors.white,
                          )
                        else
                          Icon(
                            message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                            size: 14,
                            color: message.isRead ? Colors.blue[200] : Colors.white.withOpacity(0.7),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview(BuildContext context, Map<String, dynamic> replyTo) {
    final isMe = messages.first.senderType == ChatSenderType.guardian;
    final isImage = replyTo['type'].toString().toUpperCase() == 'IMAGE';

    return InkWell(
      onTap: () => onReplyTap(replyTo['id'] ?? ''),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isMe ? Colors.black.withOpacity(0.1) : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: isMe ? Colors.white70 : Colors.blue,
              width: 4,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    replyTo['senderName'] ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isMe ? Colors.white : Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isImage ? 'Photo' : replyTo['content'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: isMe ? Colors.white.withOpacity(0.9) : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            if (isImage) ...[
              const SizedBox(width: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  replyTo['content'],
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 20),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (messages.length > 1) {
      return _buildImageGrid(context);
    }

    final message = messages.first;
    final isMe = message.senderType == ChatSenderType.guardian;
    
    switch (message.messageType) {
      case ChatMessageType.text:
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            message.content,
            style: TextStyle(
              color: isMe ? Colors.white : Colors.black87,
              fontSize: 15,
            ),
          ),
        );
      case ChatMessageType.image:
        final imageUrl = message.mediaMetadata?['url'] ?? message.content;
        final caption = (message.mediaMetadata?['url'] != null && message.content != message.mediaMetadata?['url']) 
            ? message.content 
            : null;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => onImageTap(imageUrl),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      width: 200,
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ),
            ),
            if (caption != null && caption.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  caption,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        );
      case ChatMessageType.voice:
        return _VoiceNotePlayer(
          key: ValueKey(message.id),
          url: message.content,
          isMe: isMe,
        );
      case ChatMessageType.document:
        final docUrl = message.mediaMetadata?['url'] ?? message.content;
        final caption = (message.mediaMetadata?['url'] != null && message.content != message.mediaMetadata?['url']) 
            ? message.content 
            : null;
        final fileName = docUrl.split('/').last;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () async {
                final uri = Uri.parse(docUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.insert_drive_file,
                      color: isMe ? Colors.white : Colors.black87,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          fileName,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Tap to open',
                          style: TextStyle(
                            color: isMe ? Colors.white70 : Colors.black54,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (caption != null && caption.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Text(
                  caption,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildImageGrid(BuildContext context) {
    final isMe = messages.first.senderType == ChatSenderType.guardian;
    final firstMsg = messages.first;
    final caption = (firstMsg.mediaMetadata?['url'] != null && firstMsg.content != firstMsg.mediaMetadata?['url']) 
        ? firstMsg.content 
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          children: messages.map((m) {
            final url = m.mediaMetadata?['url'] ?? m.content;
            return GestureDetector(
              onTap: () => onImageTap(url),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                ),
              ),
            );
          }).toList(),
        ),
        if (caption != null && caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              caption,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }
}

class _VoiceNotePlayer extends StatefulWidget {
  final String url;
  final bool isMe;

  const _VoiceNotePlayer({super.key, required this.url, required this.isMe});

  @override
  State<_VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends State<_VoiceNotePlayer> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    
    // Set source immediately to fetch duration
    _initPlayer();

    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });

    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  Future<void> _initPlayer() async {
    try {
      await _audioPlayer.setSource(UrlSource(widget.url));
    } catch (e) {
      debugPrint('Error preloading audio: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePlay() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.resume();
      }
      if (mounted) setState(() => _isPlaying = !_isPlaying);
    } catch (e) {
      debugPrint('Audio playback error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not play audio. Format might not be supported.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _togglePlay,
              customBorder: const CircleBorder(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.isMe ? Colors.white.withOpacity(0.2) : Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: widget.isMe ? Colors.white : Theme.of(context).primaryColor,
                  size: 28,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 140,
                height: 24,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                      elevation: 4,
                      pressedElevation: 8,
                    ),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: widget.isMe ? Colors.white : Theme.of(context).primaryColor,
                    inactiveTrackColor: widget.isMe ? Colors.white.withOpacity(0.3) : Colors.grey[300],
                    thumbColor: widget.isMe ? Colors.white : Theme.of(context).primaryColor,
                    trackShape: const RoundedRectSliderTrackShape(),
                  ),
                  child: Slider(
                    value: _position.inMilliseconds.toDouble(),
                    max: _duration.inMilliseconds.toDouble() > 0 
                        ? _duration.inMilliseconds.toDouble() 
                        : 0.1,
                    onChanged: (value) {
                      _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '${_printDuration(_position)} / ${_printDuration(_duration)}',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: widget.isMe ? Colors.white.withOpacity(0.8) : Colors.black45,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  String _printDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
