import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/chat_message.dart';
import 'dart:io';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:tafs_flutter/core/theme/app_theme.dart';
import 'package:tafs_flutter/core/utils/cdn_utils.dart';
import 'swipe_to_reply.dart';

class ChatBubble extends StatelessWidget {
  final List<ChatMessage> messages;
  final Function(String) onImageTap;

  final Function(String) onReplyTap;
  final void Function(ChatMessage) onReply;
  final void Function(String clientMessageId)? onRetryTap;
  final void Function(String messageId)? onAcknowledge;

  const ChatBubble({
    super.key,
    required this.messages,
    required this.onImageTap,
    required this.onReplyTap,
    required this.onReply,
    this.onRetryTap,
    this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) return const SizedBox.shrink();
    final firstMsg = messages.first;
    final isMe = firstMsg.senderType == ChatSenderType.guardian;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isMe && firstMsg.isAnnouncement)
            _buildAnnouncementHeader(context, firstMsg),
          ...List.generate(messages.length, (index) {
            final message = messages[index];
            final isFirst = index == 0;

            final borderRadius = BorderRadius.only(
              topLeft: Radius.circular(isFirst && !isMe ? 4 : 8),
              topRight: Radius.circular(isFirst && isMe ? 4 : 8),
              bottomLeft: const Radius.circular(8),
              bottomRight: const Radius.circular(8),
            );

            return _buildIndividualBubble(context, message, borderRadius);
          }),
        ],
      ),
    );
  }

  Widget _buildAnnouncementHeader(BuildContext context, ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 6, top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.navy.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.campaign_rounded, size: 14, color: AppTheme.navy),
          ),
          const SizedBox(width: 8),
          const Text(
            'TAFS Support',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppTheme.navy,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.navy, AppTheme.navy.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.navy.withOpacity(0.3),
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
    );
  }

  Widget _buildReplyPreview(BuildContext context, Map<String, dynamic> replyTo, bool isMe) {
    final type = replyTo['type']?.toString().toUpperCase() ?? 'TEXT';
    final isImage = type == 'IMAGE';
    final isVoice = type == 'VOICE';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      decoration: BoxDecoration(
        color: isMe ? Colors.black.withOpacity(0.15) : Colors.black.withOpacity(0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12), bottom: Radius.circular(4)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: isMe ? Colors.white70 : AppTheme.navy,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () => onReplyTap(replyTo['id'] ?? ''),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        replyTo['senderName'] ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: isMe ? Colors.white : AppTheme.navy,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (isVoice) ...[
                            Icon(Icons.mic, size: 14, color: isMe ? Colors.white70 : Colors.black54),
                            const SizedBox(width: 4),
                          ],
                          if (isImage) ...[
                            Icon(Icons.photo, size: 14, color: isMe ? Colors.white70 : Colors.black54),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              isImage ? 'Photo' : isVoice ? 'Voice Note' : (replyTo['content'] ?? ''),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: isMe ? Colors.white.withOpacity(0.8) : Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (isImage)
              Container(
                width: 50,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.horizontal(right: Radius.circular(4)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                  child: _renderImage(
                    replyTo['content'],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndividualBubble(BuildContext context, ChatMessage message, BorderRadius borderRadius) {
    final isMe = message.senderType == ChatSenderType.guardian;
    final needsAck = !isMe && message.requiresAcknowledgment && !message.isAcknowledged;

    final bubble = SwipeToReply(
      onReply: () => onReply(message),
      child: Container(
        margin: EdgeInsets.only(
          top: 1,
          bottom: 1,
          left: isMe ? 0 : 12,
          right: isMe ? 12 : 0,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.navy : Colors.white,
          borderRadius: borderRadius,
          border: !isMe && message.isAnnouncement
              ? Border.all(color: AppTheme.navy.withOpacity(0.15), width: 1)
              : null,
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.mediaMetadata?['replyTo'] != null)
                _buildReplyPreview(context, message.mediaMetadata!['replyTo'], isMe),
              _buildIndividualContent(context, message),
              if (message.messageType != ChatMessageType.text)
                Padding(
                  padding: const EdgeInsets.only(right: 12, bottom: 8, left: 12, top: 0),
                  child: _buildTimeAndChecksRow(message),
                ),
            ],
          ),
        ),
      ),
    );

    if (!needsAck) return bubble;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        bubble,
        Padding(
          padding: const EdgeInsets.only(left: 12, top: 4, bottom: 2),
          child: FilledButton.tonal(
            onPressed: onAcknowledge != null ? () => onAcknowledge!(message.id) : null,
            style: FilledButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Acknowledge', style: TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeAndChecksRow(ChatMessage message) {
    final isMe = message.senderType == ChatSenderType.guardian;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          DateFormat('h:mm a').format(message.createdAt.toLocal()),
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
          else if (message.status == MessageStatus.queued)
            Icon(
              Icons.schedule_rounded,
              size: 14,
              color: Colors.white.withOpacity(0.7),
            )
          else if (message.status == MessageStatus.error)
            GestureDetector(
              onTap: onRetryTap != null
                  ? () => onRetryTap!(message.id)
                  : null,
              child: const Icon(
                Icons.error_outline_rounded,
                size: 14,
                color: Colors.white,
              ),
            )
          else
            Icon(
              message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
              size: 14,
              color: Colors.white.withOpacity(0.7),
            ),
        ],
      ],
    );
  }

  Widget _buildIndividualContent(BuildContext context, ChatMessage message) {
    final isMe = message.senderType == ChatSenderType.guardian;

    switch (message.messageType) {
      case ChatMessageType.text:
        final maxBubbleWidth = MediaQuery.of(context).size.width * 0.7 - 32; // subtracting horizontal padding
        
        final textStyle = TextStyle(
          color: isMe ? Colors.white : Colors.black87,
          fontSize: 16,
          height: 1.3,
          fontFamily: 'Inter',
        );

        final timeWidget = _buildTimeAndChecksRow(message);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: buildTextAndTimeLayout(
            context: context,
            textContent: message.content,
            textStyle: textStyle,
            timeWidget: timeWidget,
            maxBubbleWidth: maxBubbleWidth,
            parseMentions: _parseMentions,
            isMe: isMe,
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
                child: _renderImage(
                  imageUrl,
                  localPath: message.mediaMetadata?['localPath'],
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
          url: message.mediaMetadata?['url'] as String? ?? message.content,
          localPath: message.mediaMetadata?['localPath'] as String?,
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

  Widget buildTextAndTimeLayout({
    required BuildContext context,
    required String textContent,
    required TextStyle textStyle,
    required Widget timeWidget,
    required double maxBubbleWidth,
    required List<InlineSpan> Function(String, bool) parseMentions,
    required bool isMe,
  }) {
    final double timeWidth = isMe ? 80.0 : 60.0;
    const double spacing = 6.0;

    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        children: parseMentions(textContent, isMe),
        style: textStyle,
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxBubbleWidth);

    final bool fitsOnOneLine = textPainter.width + timeWidth + spacing <= maxBubbleWidth &&
        textPainter.height <= textPainter.preferredLineHeight;

    if (fitsOnOneLine) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: RichText(
              text: TextSpan(
                children: parseMentions(textContent, isMe),
                style: textStyle,
              ),
            ),
          ),
          const SizedBox(width: spacing),
          timeWidget,
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: textPainter.width,
            child: RichText(
              textAlign: isMe ? TextAlign.right : TextAlign.left,
              text: TextSpan(
                children: parseMentions(textContent, isMe),
                style: textStyle,
              ),
            ),
          ),
          const SizedBox(height: 2),
          timeWidget,
        ],
      );
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
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          children: messages.map((m) {
            final url = m.mediaMetadata?['url'] ?? m.content;
            final localPath = m.mediaMetadata?['localPath'];
            return GestureDetector(
              onTap: () => onImageTap(url),
              child: _renderImage(
                url,
                localPath: localPath,
                fit: BoxFit.cover,
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

  Widget _renderImage(String url, {String? localPath, double? width, double? height, BoxFit fit = BoxFit.contain}) {
    // On web, dart:io File is not available. Always use the network URL.
    if (!kIsWeb && localPath != null && File(localPath).existsSync()) {
      return Image.file(
        File(localPath),
        width: width,
        height: height,
        fit: fit,
      );
    }
    
    if (url.isEmpty) {
      return Container(
        width: width ?? 200,
        height: height ?? 200,
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    // On web, route CDN URLs through backend proxy to avoid CORS errors.
    final effectiveUrl = CdnUtils.resolve(url);

    return Image.network(
      effectiveUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return SizedBox(
          width: width ?? 200,
          height: height ?? 200,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        width: width ?? 200,
        height: height ?? 200,
        color: Colors.grey[100],
        child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
      ),
    );
  }

  List<InlineSpan> _parseMentions(String text, bool isMe) {
    final List<InlineSpan> spans = [];
    final regex = RegExp(r'(@\[.*?\]\(student:\d+\))');
    final matches = regex.allMatches(text);
    
    int lastMatchEnd = 0;
    for (final match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
      }
      
      final tagMatch = RegExp(r'@\[(.*?)\]\(student:(\d+)\)').firstMatch(match.group(0)!);
      if (tagMatch != null) {
        final name = tagMatch.group(1);
        spans.add(TextSpan(
          text: '@$name',
          style: TextStyle(
            color: isMe ? Colors.white : AppTheme.navy,
            fontWeight: FontWeight.w900,
            backgroundColor: isMe ? Colors.white.withOpacity(0.25) : AppTheme.navy.withOpacity(0.12),
          ),
        ));
      }
      lastMatchEnd = match.end;
    }
    
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd)));
    }
    
    return spans;
  }
}

class _VoiceNotePlayer extends StatefulWidget {
  final String url;
  final String? localPath;
  final bool isMe;

  const _VoiceNotePlayer({
    super.key, 
    required this.url, 
    this.localPath,
    required this.isMe,
  });

  @override
  State<_VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends State<_VoiceNotePlayer> {
  late AudioPlayer _audioPlayer;
  bool _isSourceSet = false;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  static AudioPlayer? _activePlayer;
  static String? _activeUrl;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    
    _initPlayer();
    
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });

    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) {
        setState(() {
          _position = p;
          // Safety: if we reach the end, stop playing
          if (_duration > Duration.zero && p >= _duration) {
            _isPlaying = false;
          }
        });
      }
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          // Keep _position at the end so the UI shows it's finished.
          // It will be reset to zero in _togglePlay when played again.
          _position = _duration; 
          if (_activePlayer == _audioPlayer) {
            _activePlayer = null;
            _activeUrl = null;
          }
        });
      }
    });
  }

  Future<void> _initPlayer() async {
    try {
      Source? source;
      // DeviceFileSource only works on native (mobile/desktop) where files live
      // on disk. On web the browser's <audio> element only accepts URLs.
      if (!kIsWeb && widget.localPath != null && File(widget.localPath!).existsSync()) {
        source = DeviceFileSource(widget.localPath!);
      } else if (widget.url.isNotEmpty) {
        // On web, route through backend proxy to avoid CDN CORS blocking.
        final audioUrl = CdnUtils.resolve(widget.url);
        source = UrlSource(audioUrl);
      }

      if (source != null) {
        await _audioPlayer.setSource(source);
        if (mounted) setState(() => _isSourceSet = true);
      }
    } catch (e) {
      debugPrint('Error initializing audio: $e');
    }
  }

  @override
  void didUpdateWidget(covariant _VoiceNotePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.localPath != widget.localPath) {
      _initPlayer();
    }
  }

  @override
  void dispose() {
    if (_activePlayer == _audioPlayer) {
      _activePlayer = null;
      _activeUrl = null;
    }
    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePlay() async {
    try {
      if (_activePlayer != null && _activePlayer != _audioPlayer) {
        await _activePlayer!.pause();
      }

      if (_isPlaying) {
        await _audioPlayer.pause();
        _activePlayer = null;
        _activeUrl = null;
      } else {
        // If we are at the end, seek to beginning before playing
        if (_position >= _duration && _duration > Duration.zero) {
          await _audioPlayer.seek(Duration.zero);
        }
        
        _activePlayer = _audioPlayer;
        _activeUrl = widget.url;
        await _audioPlayer.resume();
      }
      
      if (mounted) {
        setState(() {
          _isPlaying = _audioPlayer.state == PlayerState.playing;
        });
      }
    } catch (e) {
      debugPrint('Audio playback error: $e');
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
                  color: widget.isMe ? Colors.white.withOpacity(0.2) : AppTheme.navy.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: widget.isMe ? Colors.white : AppTheme.navy,
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
                    activeTrackColor: widget.isMe ? Colors.white : AppTheme.navy,
                    inactiveTrackColor: widget.isMe ? Colors.white.withOpacity(0.3) : Colors.grey[300],
                    thumbColor: widget.isMe ? Colors.white : AppTheme.navy,
                    trackShape: const RoundedRectSliderTrackShape(),
                  ),
                  child: Slider(
                    value: _position.inMilliseconds.toDouble().clamp(0.0, _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 0.0),
                    max: _duration.inMilliseconds.toDouble() > 0 
                        ? _duration.inMilliseconds.toDouble() 
                        : 0.0,
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
