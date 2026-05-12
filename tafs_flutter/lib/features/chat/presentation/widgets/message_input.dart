import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'dart:io';
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

class _MessageInputState extends State<MessageInput> {
  final _controller = TextEditingController();
  final _record = AudioRecorder();
  bool _isRecording = false;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _controller.dispose();
    _record.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      widget.onSend('', ChatMessageType.image, File(image.path), widget.replyingTo);
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _record.hasPermission()) {
        const config = RecordConfig();
        final path = '${Directory.systemTemp.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _record.start(config, path: path);
        setState(() => _isRecording = true);
      }
    } catch (e) {
      print('Error starting record: $e');
    }
  }

  Future<void> _stopRecording() async {
    final path = await _record.stop();
    setState(() => _isRecording = false);
    if (path != null) {
      widget.onSend('', ChatMessageType.voice, File(path), widget.replyingTo);
    }
  }

  void _sendMessage() {
    if (_controller.text.trim().isNotEmpty) {
      widget.onSend(_controller.text.trim(), ChatMessageType.text, null, widget.replyingTo);
      _controller.clear();
    }
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
              color: Colors.grey[200],
              border: const Border(left: BorderSide(color: Colors.blue, width: 4)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.replyingTo!.senderType == ChatSenderType.guardian ? 'You' : 'TAFS Support',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 12),
                      ),
                      Text(
                        widget.replyingTo!.messageType == ChatMessageType.text 
                          ? widget.replyingTo!.content 
                          : '[${widget.replyingTo!.messageType.name.toUpperCase()}]',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: widget.onCancelReply,
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.blue),
                  onPressed: _pickImage,
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onLongPressStart: (_) => _startRecording(),
                  onLongPressEnd: (_) => _stopRecording(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isRecording ? Colors.red : Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isRecording ? Icons.mic : Icons.send_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  onTap: _isRecording ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
