import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_student.dart';
import 'package:tafs_flutter/core/theme/app_theme.dart';
import 'package:tafs_flutter/core/widgets/app_cached_network_image.dart';

class MentionsController extends TextEditingController {
  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    final List<InlineSpan> children = [];
    final pattern = RegExp(r'(@\[.*?\]\(student:\d+\))');
    
    text.splitMapJoin(
      pattern,
      onMatch: (Match match) {
        children.add(TextSpan(
          text: match.group(0),
          style: style?.copyWith(
            color: Colors.blue, 
            fontWeight: FontWeight.bold,
          ),
        ));
        return "";
      },
      onNonMatch: (String text) {
        children.add(TextSpan(text: text, style: style));
        return "";
      },
    );
    
    return TextSpan(style: style, children: children);
  }
}

class MessageInput extends StatefulWidget {
  final ChatMessage? replyingTo;
  final VoidCallback onCancelReply;
  final Function(String content, ChatMessageType type, XFile? file, ChatMessage? replyTo, String? batchId) onSend;
  final ValueChanged<String>? onTypingChanged;

  const MessageInput({
    super.key, 
    required this.onSend,
    this.replyingTo,
    required this.onCancelReply,
    this.students = const [],
    this.isSending = false,
    this.onTypingChanged,
  });

  final List<ChatStudent> students;
  final bool isSending;

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> with SingleTickerProviderStateMixin {
  final _controller = MentionsController();
  final _focusNode = FocusNode();
  final _record = AudioRecorder();
  bool _isRecording = false;
  bool _isLocked = false;
  bool _isTextEmpty = true;
  double _dragPosition = 0;
  final double _cancelThreshold = -100.0;
  
  bool _showSuggestions = false;
  String _suggestionSearch = "";
  int _suggestionIndex = 0;
  
  Timer? _timer;
  int _recordDuration = 0;
  
  final _picker = ImagePicker();
  List<XFile> _selectedFiles = [];
  // Track the intended file extension so we can name the XFile correctly
  // when the record package returns a blob URL (web) with no extension.
  String _recordingExtension = 'm4a';

  void _removeSelectedFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _isTextEmpty = _controller.text.trim().isEmpty;
      });
      _checkMentions();
      widget.onTypingChanged?.call(_controller.text);
    });
  }

  void _checkMentions() {
    final text = _controller.text;
    final lastAtPos = text.lastIndexOf("@");
    if (lastAtPos != -1) {
      final afterAt = text.substring(lastAtPos + 1);
      if (afterAt.contains(" ")) {
        setState(() => _showSuggestions = false);
      } else {
        setState(() {
          _showSuggestions = true;
          _suggestionSearch = afterAt.toLowerCase();
          _suggestionIndex = 0;
        });
      }
    } else {
      setState(() => _showSuggestions = false);
    }
  }

  void _insertMention(ChatStudent student) {
    final text = _controller.text;
    final lastAtPos = text.lastIndexOf("@");
    final beforeAt = text.substring(0, lastAtPos);
    final tag = "@[${student.fullName}](student:${student.cc}) ";

    _controller.text = beforeAt + tag;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
    
    setState(() => _showSuggestions = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _record.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedFiles.addAll(images);
      });
    }
  }

  Future<void> _takePhoto() async {
    if (kIsWeb) {
      // Camera not available on web; fallback to gallery picker
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() => _selectedFiles.addAll(images));
      }
      return;
    }
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _selectedFiles.add(photo);
      });
    }
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
      allowMultiple: true,
      // On web, withData=true gives us bytes; on native we use paths.
      withData: kIsWeb,
    );

    if (result != null) {
      final xfiles = result.files.map((f) {
        if (kIsWeb && f.bytes != null) {
          // Wrap web bytes into an XFile using a data URI approach via name
          return XFile.fromData(f.bytes!, name: f.name, mimeType: 'application/octet-stream');
        } else if (f.path != null) {
          return XFile(f.path!);
        }
        return null;
      }).whereType<XFile>().toList();

      setState(() {
        _selectedFiles.addAll(xfiles);
      });
    }
  }

  void _showMediaMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMenuItem(
                  icon: Icons.image_rounded,
                  label: 'Photos',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage();
                  },
                ),
                _buildMenuItem(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    _takePhoto();
                  },
                ),
                _buildMenuItem(
                  icon: Icons.description_rounded,
                  label: 'Document',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _pickDocument();
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startRecording() async {
    try {
      if (await _record.hasPermission()) {
        // Web: MediaRecorder only supports WebM/Opus in most browsers.
        // Native: use AAC (m4a) which is widely supported.
        final RecordConfig config;
        final String path;
        if (kIsWeb) {
          _recordingExtension = 'webm';
          config = const RecordConfig(encoder: AudioEncoder.opus);
          // On web the path is ignored by MediaRecorder; provide a dummy name.
          path = 'web-recording.webm';
        } else {
          _recordingExtension = 'm4a';
          config = const RecordConfig(encoder: AudioEncoder.aacLc);
          path = '${Directory.systemTemp.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        }

        if (await _record.isRecording()) {
          await _record.stop();
        }

        // Broad try-catch for the actual hardware / microphone start
        try {
          await _record.start(config, path: path);
        } catch (e) {
          debugPrint('Hardware error: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Microphone not available on this device.')),
            );
          }
          return;
        }

        try {
          await HapticFeedback.heavyImpact();
        } catch (_) {}

        _recordDuration = 0;
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() => _recordDuration++);
        });

        setState(() {
          _isRecording = true;
          _isLocked = false;
          _dragPosition = 0;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission denied.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error starting record: $e');
      if (mounted) {
        setState(() {
          _isRecording = false;
          _isLocked = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not start recording.')),
        );
      }
    }
  }

  Future<void> _stopRecording({bool cancel = false}) async {
    _timer?.cancel();
    final resultPath = await _record.stop();
    setState(() {
      _isRecording = false;
      _isLocked = false;
      _recordDuration = 0;
    });

    if (!cancel && resultPath != null) {
      // On web, resultPath is a blob URL (e.g. blob:http://localhost:.../uuid)
      // which has no meaningful file extension. We create an XFile with the
      // correct name so _getFileType and uploadMedia filename are both right.
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final voiceFile = XFile(resultPath, name: 'voice_$timestamp.$_recordingExtension');
      widget.onSend('', ChatMessageType.voice, voiceFile, widget.replyingTo, null);
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    
    // Send pending files first
    if (_selectedFiles.isNotEmpty) {
      final batchId = _selectedFiles.where((f) => _getFileType(f) == ChatMessageType.image).length > 1 
          ? 'batch-${DateTime.now().millisecondsSinceEpoch}' 
          : null;

      for (final file in _selectedFiles) {
        final type = _getFileType(file);
        final String? fileBatchId = (batchId != null && type == ChatMessageType.image) ? batchId : null;
        widget.onSend('', type, file, widget.replyingTo, fileBatchId);
      }
      setState(() {
        _selectedFiles = [];
      });
    }

    // Send text if not empty
    if (text.isNotEmpty) {
      widget.onSend(text, ChatMessageType.text, null, widget.replyingTo, null); // batchId not applicable for text
      _controller.clear();
      setState(() {
        _isTextEmpty = true;
      });
    }
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Premium Reply Preview (WhatsApp style)
        if (widget.replyingTo != null)
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.navy,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.replyingTo!.senderType == ChatSenderType.guardian
                                ? 'You'
                                : (widget.replyingTo!.senderName ?? 'TAFS Support'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AppTheme.navy,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (widget.replyingTo!.messageType == ChatMessageType.image) ...[
                                const Icon(Icons.photo, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                              ],
                              if (widget.replyingTo!.messageType == ChatMessageType.voice) ...[
                                const Icon(Icons.mic, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                              ],
                              if (widget.replyingTo!.messageType == ChatMessageType.document) ...[
                                const Icon(Icons.insert_drive_file, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                              ],
                              Expanded(
                                child: Text(
                                  widget.replyingTo!.messageType == ChatMessageType.text
                                    ? widget.replyingTo!.content
                                    : widget.replyingTo!.messageType == ChatMessageType.image
                                      ? 'Photo'
                                      : widget.replyingTo!.messageType == ChatMessageType.voice
                                        ? 'Voice Note'
                                        : 'Document',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
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
                  if (widget.replyingTo!.messageType == ChatMessageType.image)
                    Container(
                      width: 45,
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AppCachedNetworkImage(
                          url: widget.replyingTo!.mediaMetadata?['url'] ?? widget.replyingTo!.content,
                          fit: BoxFit.cover,
                          errorWidget: const Icon(Icons.broken_image, size: 20),
                        ),
                      ),
                    ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 20, color: Colors.grey[400]),
                    onPressed: widget.onCancelReply,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),

        // Main Input Bar
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_selectedFiles.isNotEmpty)
                  Container(
                    height: 80,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _selectedFiles.length,
                      itemBuilder: (context, index) {
                        final file = _selectedFiles[index];
                        final isImage = _getFileType(file) == ChatMessageType.image;
                        
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(11),
                                   child: isImage
                                    ? FutureBuilder<Uint8List>(
                                        future: file.readAsBytes(),
                                        builder: (context, snap) {
                                          if (snap.hasData) {
                                            return Image.memory(snap.data!, fit: BoxFit.cover);
                                          }
                                          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                                        },
                                      )
                                    : Center(
                                        child: Icon(Icons.description_rounded, color: Colors.blue[400], size: 32),
                                      ),
                                ),
                              ),
                              Positioned(
                                top: -2,
                                right: -2,
                                child: GestureDetector(
                                  onTap: () => _removeSelectedFile(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                if (_showSuggestions && widget.students.isNotEmpty)
                  Builder(builder: (context) {
                    final filtered = widget.students.where((s) =>
                      s.fullName.toLowerCase().contains(_suggestionSearch) ||
                      s.cc.toString().contains(_suggestionSearch)
                    ).toList();

                    if (filtered.isEmpty) return const SizedBox.shrink();

                    return Container(
                      constraints: const BoxConstraints(maxHeight: 250),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final student = filtered[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.grey[200],
                                backgroundImage: appCachedNetworkImageProvider(student.photographUrl),
                                child: student.photographUrl == null
                                  ? const Icon(Icons.person, size: 20)
                                  : null,
                              ),
                              title: Text(
                                student.fullName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              subtitle: Text(
                                'CC: ${student.cc}',
                                style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              onTap: () => _insertMention(student),
                            );
                          },
                        ),
                      ),
                    );
                  }),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Row(
                      children: [
                        // Unified Pill Container
                        Expanded(
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 54, maxHeight: 120),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(27),
                              border: Border.all(color: Colors.grey[200]!, width: 1),
                            ),
                            child: Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                Row(
                                  children: [
                                    if (!_isRecording)
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: _showMediaMenu,
                                          borderRadius: BorderRadius.circular(27),
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            child: Icon(
                                              Icons.add_circle_outline_rounded,
                                              color: Theme.of(context).primaryColor,
                                              size: 28,
                                            ),
                                          ),
                                        ),
                                      ),
                                    Expanded(
                                      child: KeyboardListener(
                                        focusNode: _focusNode,
                                        onKeyEvent: (event) {
                                          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
                                            final text = _controller.text;
                                            final selection = _controller.selection;
                                            
                                            if (selection.isCollapsed && selection.baseOffset > 0) {
                                              final textBefore = text.substring(0, selection.baseOffset);
                                              
                                              // Find all tags in the text
                                              final tags = RegExp(r'@\[.*?\]\(student:\d+\) ').allMatches(text);
                                              for (final match in tags) {
                                                // If cursor is at the end of this tag OR inside it
                                                if (selection.baseOffset > match.start && selection.baseOffset <= match.end) {
                                                  final newText = text.replaceRange(match.start, match.end, "");
                                                  _controller.value = TextEditingValue(
                                                    text: newText,
                                                    selection: TextSelection.collapsed(offset: match.start),
                                                  );
                                                  return;
                                                }
                                              }
                                            }
                                          }
                                        },
                                        child: TextField(
                                          controller: _controller,
                                          enabled: !_isRecording,
                                          minLines: 1,
                                          maxLines: 5,
                                          keyboardType: TextInputType.multiline,
                                          textInputAction: TextInputAction.newline,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: -0.2,
                                            color: Colors.black87,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: _isRecording ? '' : 'Type a message...',
                                            hintStyle: TextStyle(
                                              color: Colors.grey[400],
                                              fontWeight: FontWeight.w500,
                                            ),
                                            filled: false,
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            isDense: true,
                                            contentPadding: const EdgeInsets.fromLTRB(4, 14, 16, 14),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Recording UI Overlay
                                if (_isRecording)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(27),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Row(
                                        children: [
                                          TweenAnimationBuilder<double>(
                                            tween: Tween(begin: 0.0, end: 1.0),
                                            duration: const Duration(milliseconds: 600),
                                            builder: (context, value, child) {
                                              return Opacity(
                                                opacity: 0.5 + (value * 0.5),
                                                child: Transform.scale(
                                                  scale: 0.8 + (value * 0.4),
                                                  child: const Icon(Icons.circle, color: Colors.red, size: 12),
                                                ),
                                              );
                                            },
                                            onEnd: () => setState(() {}), // Trigger rebuild for pulse loop
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            _formatDuration(_recordDuration),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 16,
                                              fontFeatures: [FontFeature.tabularFigures()],
                                            ),
                                          ),
                                          const Spacer(),
                                          if (!_isLocked)
                                            Row(
                                              children: [
                                                Text(
                                                  'Slide left to cancel',
                                                  style: TextStyle(
                                                    color: Colors.grey[500],
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Colors.grey[400]),
                                              ],
                                            )
                                          else
                                            GestureDetector(
                                              onTap: () => _stopRecording(cancel: true),
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.withOpacity(0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        
                        // Action Button (Send/Mic)
                        GestureDetector(
                          onLongPressStart: (_) => _isTextEmpty ? _startRecording() : null,
                          onLongPressMoveUpdate: (details) {
                            if (_isRecording && !_isLocked) {
                              final dx = details.localOffsetFromOrigin.dx;
                              final dy = details.localOffsetFromOrigin.dy;
                              
                              if (dy < -60.0) {
                                setState(() {
                                  _isLocked = true;
                                });
                                HapticFeedback.mediumImpact();
                              } else if (dx < -60.0 || dx > 60.0) {
                                _stopRecording(cancel: true);
                                HapticFeedback.lightImpact();
                              }
                            }
                          },
                          onLongPressEnd: (_) {
                            if (_isRecording && !_isLocked) {
                              _stopRecording();
                            }
                          },
                          onTap: widget.isSending
                              ? null
                              : () {
                            if (_isLocked) {
                              _stopRecording(cancel: false);
                            } else if (_isTextEmpty && _selectedFiles.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Hold to record voice note'),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            } else {
                              _sendMessage();
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.elasticOut,
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: widget.isSending
                                  ? Theme.of(context).primaryColor.withValues(alpha: 0.7)
                                  : (_isRecording 
                                ? (_isLocked ? Colors.green : Colors.red) 
                                : Theme.of(context).primaryColor),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (_isRecording 
                                    ? (_isLocked ? Colors.green : Colors.red) 
                                    : Theme.of(context).primaryColor).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: widget.isSending
                                    ? const SizedBox(
                                        key: ValueKey('sending'),
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Icon(
                                  _isRecording 
                                    ? (_isLocked ? Icons.send_rounded : Icons.mic_rounded)
                                    : (_isTextEmpty && _selectedFiles.isEmpty ? Icons.mic_rounded : Icons.send_rounded),
                                  key: ValueKey('$_isRecording $_isLocked $_isTextEmpty'),
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_isRecording && !_isLocked)
                      Positioned(
                        bottom: 64,
                        right: 18,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 800),
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, -12 * (1.0 - value)),
                                  child: Opacity(
                                    opacity: value,
                                    child: const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.grey, size: 20),
                                  ),
                                );
                              },
                              onEnd: () => setState(() {}),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey[200]!),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, -2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.lock_outline_rounded, color: Colors.red, size: 16),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
          ],
        ),
      ),
    ),
  ],
);
}

  ChatMessageType _getFileType(XFile file) {
    // Use file.name (works on both web and native) for extension detection.
    // On web, file.path is a blob URL which has no meaningful extension.
    final name = file.name.isNotEmpty ? file.name : file.path;
    final extension = name.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'].contains(extension)) {
      return ChatMessageType.image;
    }
    if (['m4a', 'mp3', 'ogg', 'aac', 'wav', 'webm', 'opus'].contains(extension)) {
      return ChatMessageType.voice;
    }
    return ChatMessageType.document;
  }
}
