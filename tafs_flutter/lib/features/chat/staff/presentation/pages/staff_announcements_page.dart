import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../injection_container.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../presentation/widgets/chat_bubble.dart';
import '../../../presentation/widgets/full_screen_image_viewer.dart';
import '../../../presentation/widgets/message_input.dart';
import '../bloc/staff_announcements_cubit.dart';

class StaffAnnouncementsPage extends StatefulWidget {
  /// When true, loads history and socket on first mount (announcements-only staff).
  final bool loadOnMount;

  const StaffAnnouncementsPage({super.key, this.loadOnMount = false});

  @override
  State<StaffAnnouncementsPage> createState() => _StaffAnnouncementsPageState();
}

class _StaffAnnouncementsPageState extends State<StaffAnnouncementsPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.loadOnMount) {
      context.read<StaffAnnouncementsCubit>().load();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String _targetLabel(ChatMessage message, StaffAnnouncementsState state) {
    if (message.targetGrade == null && message.targetSection == null) {
      return 'All parents';
    }
    final gradeLabel = message.targetGrade == null
        ? null
        : state.gradeOptions
                .where((g) => g.classCode == message.targetGrade)
                .map((g) => g.description)
                .firstOrNull ??
            message.targetGrade;
    if (gradeLabel != null && message.targetSection != null) {
      return '$gradeLabel · ${message.targetSection}';
    }
    if (gradeLabel != null) return gradeLabel;
    return message.targetSection ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StaffAnnouncementsCubit, StaffAnnouncementsState>(
      listenWhen: (p, c) => c.messages.length != p.messages.length,
      listener: (_, __) => _scrollToBottom(),
      builder: (context, state) {
        return Column(
          children: [
            _TargetSelectors(state: state),
            if (!state.isSocketConnected)
              Container(
                width: double.infinity,
                color: Colors.amber.shade50,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off, size: 16, color: Colors.amber.shade900),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Offline — announcements can only be sent while connected.',
                        style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            if (state.targetingWarning != null)
              Container(
                width: double.infinity,
                color: Colors.orange.shade50,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  state.targetingWarning!,
                  style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                ),
              ),
            if (state.error != null)
              Container(
                width: double.infinity,
                color: Colors.red.shade50,
                padding: const EdgeInsets.all(8),
                child: Text(
                  state.error!,
                  style: TextStyle(fontSize: 12, color: Colors.red.shade800),
                ),
              ),
            Expanded(
              child: state.loading && state.messages.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.navy),
                    )
                  : state.messages.isEmpty
                      ? const Center(
                          child: Text(
                            'No announcements yet.\nSend a broadcast below.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.blue300),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(12),
                          itemCount: state.messages.length,
                          itemBuilder: (context, i) {
                            final msg = state.messages[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ChatBubble(
                                    messages: [msg],
                                    onImageTap: (url) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => FullScreenImageViewer(
                                            imageUrls: [url],
                                            initialIndex: 0,
                                          ),
                                        ),
                                      );
                                    },
                                    onReplyTap: (_) {},
                                    onReply: (_) {},
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4, left: 8),
                                    child: Text(
                                      'To: ${_targetLabel(msg, state)}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
            if (state.isSocketConnected)
              Stack(
                children: [
                  AbsorbPointer(
                    absorbing: state.sending,
                    child: MessageInput(
                      replyingTo: null,
                      onCancelReply: () {},
                      students: const [],
                      onSend: (content, type, file, replyTo, batchId) async {
                        final cubit = context.read<StaffAnnouncementsCubit>();
                        if (file != null) {
                          final media = await InjectionContainer
                              .staffAnnouncementsRepository
                              .uploadMedia(file);
                          final mediaUrl = media['url'] as String?;
                          final messageType = type == ChatMessageType.voice
                              ? 'VOICE'
                              : type == ChatMessageType.image
                                  ? 'IMAGE'
                                  : 'DOCUMENT';
                          await cubit.sendMedia(
                            messageType: messageType,
                            content: mediaUrl ?? content,
                            mediaMetadata: media,
                          );
                        } else {
                          await cubit.sendText(content);
                        }
                        _scrollToBottom();
                      },
                    ),
                  ),
                  if (state.sending)
                    const Positioned.fill(
                      child: ColoredBox(
                        color: Color(0x33FFFFFF),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.navy,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _TargetSelectors extends StatelessWidget {
  final StaffAnnouncementsState state;

  const _TargetSelectors({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<StaffAnnouncementsCubit>();
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: AppTheme.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.campaign_outlined, size: 16, color: AppTheme.navy),
              SizedBox(width: 6),
              Text(
                'Announcement target',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: state.targetGrade,
                  decoration: const InputDecoration(
                    labelText: 'Grade',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All parents'),
                    ),
                    ...state.gradeOptions
                        .where((g) => g.classCode.isNotEmpty)
                        .map(
                      (g) => DropdownMenuItem(
                        value: g.classCode,
                        child: Text(g.description),
                      ),
                    ),
                  ],
                  onChanged: cubit.setTargetGrade,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: state.targetSection,
                  decoration: const InputDecoration(
                    labelText: 'Section',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All sections'),
                    ),
                    ...state.sectionOptions.map(
                      (s) => DropdownMenuItem(
                        value: s.description,
                        child: Text(s.description),
                      ),
                    ),
                  ],
                  onChanged: state.targetGrade == null ? null : cubit.setTargetSection,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
