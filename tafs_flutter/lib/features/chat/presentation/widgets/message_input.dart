import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';
import '../../domain/entities/chat_message.dart';

class MessageInput extends StatefulWidget {
  final ChatMessage? replyingTo;
  final VoidCallback onCancelReply;
  final Function(String content, ChatMessageType type, File? file, ChatMessage? replyTo) onSend;

  const MessageInput({
    super.key, 
    required this.onSend,
    this.replyingTo,
    required this.onCancelReply,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _record = AudioRecorder();
  bool _isRecording = false;
  bool _isTextEmpty = true;
  double _dragPosition = 0;
  final double _cancelThreshold = -100.0;
  
  Timer? _timer;
  int _recordDuration = 0;
  
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _isTextEmpty = _controller.text.trim().isEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _record.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      widget.onSend('', ChatMessageType.image, File(image.path), widget.replyingTo);
    }
  }

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      widget.onSend('', ChatMessageType.image, File(photo.path), widget.replyingTo);
    }
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
    );
    if (result != null && result.files.single.path != null) {
      widget.onSend('', ChatMessageType.document, File(result.files.single.path!), widget.replyingTo);
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
        const config = RecordConfig();
        final path = '${Directory.systemTemp.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        if (await _record.isRecording()) {
          await _record.stop();
        }

        // Broad try-catch for the actual hardware start
        try {
          await _record.start(config, path: path);
        } catch (e) {
          debugPrint('Hardware error: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Microphone hardware not available on this device.')),
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
          _dragPosition = 0;
        });
      }
    } catch (e) {
      debugPrint('Error starting record: $e');
      if (mounted) {
        setState(() => _isRecording = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not start recording.')),
        );
      }
    }
  }

  Future<void> _stopRecording({bool cancel = false}) async {
    _timer?.cancel();
    final path = await _record.stop();
    setState(() {
      _isRecording = false;
      _recordDuration = 0;
    });
    
    if (!cancel && path != null) {
      widget.onSend('', ChatMessageType.voice, File(path), widget.replyingTo);
    }
  }

  void _sendMessage() {
    if (_controller.text.trim().isNotEmpty) {
      widget.onSend(_controller.text.trim(), ChatMessageType.text, null, widget.replyingTo);
      _controller.clear();
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
        if (widget.replyingTo != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(left: BorderSide(color: Theme.of(context).primaryColor, width: 4)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.replyingTo!.senderType == ChatSenderType.guardian ? 'You' : 'TAFS Support',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor, fontSize: 12),
                      ),
                      Text(
                        widget.replyingTo!.messageType == ChatMessageType.text 
                          ? widget.replyingTo!.content 
                          : '[${widget.replyingTo!.messageType.name.toUpperCase()}]',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                  onPressed: widget.onCancelReply,
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                if (!_isRecording)
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.add_rounded, color: Theme.of(context).primaryColor, size: 28),
                    ),
                    onPressed: _showMediaMenu,
                  ),
                Expanded(
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: TextField(
                          controller: _controller,
                          enabled: !_isRecording,
                          style: const TextStyle(fontSize: 15),
                          decoration: InputDecoration(
                            hintText: _isRecording ? '' : 'Type a message...',
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      if (_isRecording)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(28),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                const Icon(Icons.circle, color: Colors.red, size: 10),
                                const SizedBox(width: 8),
                                Text(
                                  _formatDuration(_recordDuration),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const Spacer(),
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 500),
                                  opacity: 0.6,
                                  child: Row(
                                    children: [
                                      Text(
                                        'Slide to cancel',
                                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                      ),
                                      const Icon(Icons.chevron_left_rounded, size: 20),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onLongPressStart: (_) => _isTextEmpty ? _startRecording() : null,
                  onLongPressMoveUpdate: (details) {
                    if (_isRecording) {
                      setState(() {
                        _dragPosition = details.localOffsetFromOrigin.dx;
                      });
                      if (_dragPosition < _cancelThreshold) {
                        _stopRecording(cancel: true);
                      }
                    }
                  },
                  onLongPressEnd: (_) => _isRecording ? _stopRecording() : null,
                  onTap: _isTextEmpty ? null : _sendMessage,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isRecording ? Colors.red : Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording ? Colors.red : Theme.of(context).primaryColor).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isRecording 
                        ? Icons.mic_rounded 
                        : (_isTextEmpty ? Icons.mic_rounded : Icons.send_rounded),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
