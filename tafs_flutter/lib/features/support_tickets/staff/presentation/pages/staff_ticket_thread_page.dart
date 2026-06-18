import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../auth/domain/entities/staff_user.dart';
import '../../../../chat/domain/entities/chat_message.dart';
import '../../../../chat/presentation/widgets/chat_bubble.dart';
import '../../../../chat/presentation/widgets/full_screen_image_viewer.dart';
import '../../../../chat/presentation/widgets/message_input.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../injection_container.dart';
import '../../../domain/entities/ticket_message.dart';
import '../../../presentation/utils/ticket_message_mapper.dart';
import '../../../presentation/widgets/ticket_status_badge.dart';
import '../../support_ticket_staff_access.dart';
import '../bloc/staff_ticket_thread_cubit.dart';
import '../widgets/staff_picker_sheet.dart';

class StaffTicketThreadPage extends StatefulWidget {
  final String ticketId;
  final StaffUser staff;

  const StaffTicketThreadPage({
    super.key,
    required this.ticketId,
    required this.staff,
  });

  @override
  State<StaffTicketThreadPage> createState() => _StaffTicketThreadPageState();
}

class _StaffTicketThreadPageState extends State<StaffTicketThreadPage> {
  late final StaffTicketThreadCubit _cubit;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _cubit = StaffTicketThreadCubit(
      repository: InjectionContainer.staffSupportTicketRepository,
    );
    _cubit.load(widget.ticketId);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _cubit.close();
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

  Future<void> _showCloseDialog() async {
    final noteController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close ticket?'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            hintText: 'Optional note for audit log',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Close')),
        ],
      ),
    );
    if (ok == true && mounted) {
      await _cubit.closeTicket(note: noteController.text.trim());
      noteController.dispose();
    } else {
      noteController.dispose();
    }
  }

  void _showPicker({
    required String title,
    required String description,
    required List<String>? roleFilter,
    required void Function(String userId) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => StaffPickerSheet(
        repository: InjectionContainer.staffSupportTicketRepository,
        title: title,
        description: description,
        roleFilter: roleFilter,
        excludeUserId: widget.staff.id,
        onSelect: (user) => onSelect(user.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<StaffTicketThreadCubit, StaffTicketThreadState>(
        listenWhen: (p, c) => c.messages.length != p.messages.length,
        listener: (_, __) => _scrollToBottom(),
        child: Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            title: const Text('Support Ticket'),
            backgroundColor: AppTheme.white,
            foregroundColor: AppTheme.navy,
            elevation: 0,
          ),
          body: BlocBuilder<StaffTicketThreadCubit, StaffTicketThreadState>(
            builder: (context, state) {
              if (state.loading && state.ticket == null) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.navy));
              }
              final ticket = state.ticket;
              if (ticket == null) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(state.error ?? 'Ticket not found'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => _cubit.reload(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final isClosed = ticket.status.name == 'closed';
              final isFinance = ticket.category.name == 'financial';
              final isUnclaimedFinance = isFinance && ticket.currentAssigneeId == null;
              final isAssignee = ticket.currentAssigneeId == widget.staff.id;
              final isSuperAdmin = widget.staff.role == 'SUPER_ADMIN';
              final isReadOnly = !isClosed && !isAssignee;
              final canCompose = !isClosed && (isAssignee || isSuperAdmin);

              return Column(
                children: [
                  if (state.error != null)
                    _banner(state.error!, Colors.red.shade50, Colors.red.shade800),
                  if (state.actionError != null)
                    _banner(state.actionError!, Colors.red.shade50, Colors.red.shade800),
                  if (isSuperAdmin && isReadOnly)
                    _infoBanner(
                      'Super Admin oversight',
                      'Assigned to ${ticket.assigneeName ?? 'the routed role'}. Approve staff replies below, or send a direct reply to the parent.',
                      Colors.amber.shade50,
                    ),
                  if (!isSuperAdmin && isReadOnly)
                    _infoBanner(
                      'Read-only view',
                      'You are not the assigned responder on this ticket.',
                      Colors.grey.shade200,
                    ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.householdName ?? 'Family #${ticket.familyId}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${categoryLabel(ticket.category.name)} · ${ticket.subtopic ?? ''}'
                          '${ticket.studentName != null ? ' · ${ticket.studentName}' : ''}',
                          style: const TextStyle(fontSize: 13, color: AppTheme.blue300),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            TicketStatusBadge(status: ticket.status),
                            const SizedBox(width: 8),
                            if (ticket.assigneeName != null)
                              Expanded(
                                child: Text(
                                  'Assignee: ${ticket.assigneeName}',
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            if (isUnclaimedFinance && widget.staff.role == 'FINANCE_CLERK')
                              _actionChip('Claim', state.actionLoading, () => _cubit.claim()),
                            if (isFinance && isAssignee && widget.staff.role == 'FINANCE_CLERK' && !isClosed)
                              _actionChip('Transfer', state.actionLoading, () {
                                _showPicker(
                                  title: 'Transfer ticket',
                                  description: 'Select a finance clerk to transfer to.',
                                  roleFilter: const ['FINANCE_CLERK'],
                                  onSelect: (id) => _cubit.transfer(id),
                                );
                              }),
                            if (widget.staff.role == 'GENERAL_RESPONDENT' && isAssignee && !isClosed)
                              _actionChip('Forward', state.actionLoading, () {
                                _showPicker(
                                  title: 'Forward ticket',
                                  description: 'Select a staff member to forward to.',
                                  roleFilter: null,
                                  onSelect: (id) => _cubit.forward(id),
                                );
                              }),
                            if (!isClosed && isAssignee)
                              _actionChip('Close', state.actionLoading, _showCloseDialog,
                                  danger: true),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(ticket.description, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: state.messages.isEmpty
                        ? const Center(child: Text('No messages yet'))
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(12),
                            itemCount: state.messages.length,
                            itemBuilder: (context, i) {
                              final msg = state.messages[i];
                              final viewerStaffId = widget.staff.id;
                              final isOutgoing = isOwnStaffMessage(msg, viewerStaffId);
                              final isIncomingStaff = msg.senderType ==
                                      TicketMessageSenderType.staff &&
                                  !isOutgoing;
                              final chatMsg = staffTicketMessageToChatMessage(
                                msg,
                                viewerStaffId: viewerStaffId,
                              );

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(
                                      bottom: 4,
                                      left: isOutgoing ? 0 : 8,
                                      right: isOutgoing ? 8 : 0,
                                    ),
                                    child: Align(
                                      alignment: isOutgoing
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                      child: isOutgoing
                                          ? Wrap(
                                              spacing: 6,
                                              crossAxisAlignment:
                                                  WrapCrossAlignment.center,
                                              alignment: WrapAlignment.end,
                                              children: [
                                                Text(
                                                  msg.senderName ?? 'You',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.blue300,
                                                  ),
                                                ),
                                                if (isSuperAdminTicketMessage(msg))
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.amber.shade200,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    child: Text(
                                                      'SUPER ADMIN',
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Colors.amber.shade900,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            )
                                          : Text(
                                              staffViewMessageLabel(
                                                msg,
                                                viewerStaffId: viewerStaffId,
                                              ),
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.blue300,
                                              ),
                                              textAlign: TextAlign.left,
                                            ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: ChatBubble(
                                      messages: [chatMsg],
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
                                  ),
                                  if (isIncomingStaff)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 8,
                                        left: 8,
                                      ),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          statusLabel(msg.reviewStatus.name),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: msg.reviewStatus.name ==
                                                    'pending'
                                                ? Colors.orange.shade800
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (isSuperAdmin && isIncomingStaff &&
                                      msg.reviewStatus ==
                                          TicketMessageReviewStatus.pending)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        children: [
                                          TextButton(
                                            onPressed: state.actionLoading
                                                ? null
                                                : () => _cubit.reviewMessage(
                                                      messageId: msg.id,
                                                      status: 'APPROVED',
                                                    ),
                                            child: const Text('Approve'),
                                          ),
                                          TextButton(
                                            onPressed: state.actionLoading
                                                ? null
                                                : () => _showRejectDialog(msg.id),
                                            child: const Text('Reject'),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                  ),
                  if (canCompose)
                    Stack(
                      children: [
                        AbsorbPointer(
                          absorbing: !state.isSocketConnected,
                          child: MessageInput(
                            isSending: state.sending,
                            replyingTo: null,
                            onCancelReply: () {},
                            students: const [],
                            onSend: (content, type, file, replyTo, batchId) async {
                              final cubit = context.read<StaffTicketThreadCubit>();
                              if (file != null) {
                                final media = await InjectionContainer
                                    .staffSupportTicketRepository
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
                                await cubit.sendMessage(content);
                              }
                              _scrollToBottom();
                            },
                          ),
                          ),
                        if (!state.isSocketConnected)
                          Positioned.fill(
                            child: ColoredBox(
                              color: Colors.white.withValues(alpha: 0.6),
                              child: Center(
                                child: Text(
                                  'OFFLINE — RECONNECTING',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade700,
                                    letterSpacing: 0.5,
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
          ),
        ),
      ),
    );
  }

  Future<void> _showRejectDialog(String messageId) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject reply'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Reason (optional)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reject')),
        ],
      ),
    );
    if (ok == true && mounted) {
      await _cubit.reviewMessage(
        messageId: messageId,
        status: 'REJECTED',
        comment: controller.text.trim().isEmpty ? null : controller.text.trim(),
      );
    }
    controller.dispose();
  }

  Widget _banner(String text, Color bg, Color fg) {
    return Material(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(text, style: TextStyle(color: fg, fontSize: 12)),
      ),
    );
  }

  Widget _infoBanner(String title, String body, Color bg) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _actionChip(String label, bool loading, VoidCallback onTap, {bool danger = false}) {
    return ActionChip(
      label: loading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
      backgroundColor: danger ? Colors.red.shade50 : null,
      onPressed: loading ? null : onTap,
    );
  }
}
