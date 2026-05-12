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
  final Function(String content, ChatMessageType type, File? file, ChatMessage? replyTo, Map<String, dynamic>? metadata) onSend;

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
  List<File> _selectedFiles = [];

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
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedFiles.addAll(images.map((image) => File(image.path)));
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _selectedFiles.add(File(photo.path));
      });
    }
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
      allowMultiple: true,
    );
    
    if (result != null) {
      setState(() {
        _selectedFiles.addAll(result.paths.whereType<String>().map((path) => File(path)));
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
      widget.onSend('', ChatMessageType.voice, File(path), widget.replyingTo, null);
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
        final metadata = <String, dynamic>{};
        if (batchId != null && type == ChatMessageType.image) {
          metadata['batchId'] = batchId;
        }
        
        widget.onSend('', type, file, widget.replyingTo, metadata);
      }
      setState(() {
        _selectedFiles = [];
      });
    }

    // Send text if not empty
    if (text.isNotEmpty) {
      widget.onSend(text, ChatMessageType.text, null, widget.replyingTo, null);
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
        // Premium Reply Preview
        if (widget.replyingTo != null)
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 35,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.replyingTo!.senderType == ChatSenderType.guardian ? 'You' : 'TAFS Support',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).primaryColor,
                          fontSize: 12,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.replyingTo!.messageType == ChatMessageType.text 
                          ? widget.replyingTo!.content 
                          : '[${widget.replyingTo!.messageType.name.toUpperCase()}]',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, size: 20, color: Colors.grey[400]),
                  onPressed: widget.onCancelReply,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
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
                                    ? Image.file(file, fit: BoxFit.cover)
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
                Row(
                  children: [
                    // Unified Pill Container
                    Expanded(
                      child: Container(
                        height: 54,
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
                              child: TextField(
                                controller: _controller,
                                enabled: !_isRecording,
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
                                onSubmitted: (_) => _sendMessage(),
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
                                  Row(
                                    children: [
                                      Text(
                                        'Slide to cancel',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Colors.grey[400]),
                                    ],
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
                    if (_isRecording) {
                      setState(() {
                        _dragPosition = details.localOffsetFromOrigin.dx;
                      });
                      if (_dragPosition < _cancelThreshold) {
                        _stopRecording(cancel: true);
                        HapticFeedback.lightImpact();
                      }
                    }
                  },
                  onLongPressEnd: (_) => _isRecording ? _stopRecording() : null,
                  onTap: () {
                    if (_isTextEmpty && _selectedFiles.isEmpty) {
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
                      color: _isRecording ? Colors.red : Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording ? Colors.red : Theme.of(context).primaryColor).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          _isRecording 
                            ? Icons.mic_rounded 
                            : (_isTextEmpty && _selectedFiles.isEmpty ? Icons.mic_rounded : Icons.send_rounded),
                          key: ValueKey(_isRecording || (_isTextEmpty && _selectedFiles.isEmpty)),
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
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

  ChatMessageType _getFileType(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
      return ChatMessageType.image;
    }
    return ChatMessageType.document;
  }
}
