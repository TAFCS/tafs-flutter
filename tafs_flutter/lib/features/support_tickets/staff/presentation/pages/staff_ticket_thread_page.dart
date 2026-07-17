import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../auth/domain/entities/staff_user.dart';
import '../../../../chat/domain/entities/chat_message.dart';
import '../../../../chat/presentation/widgets/chat_bubble.dart';
import '../../../../chat/presentation/widgets/full_screen_image_viewer.dart';
import '../../../../chat/presentation/widgets/message_input.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/app_dialog_actions.dart';
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
    final note = await showDialog<String?>(
      context: context,
      builder: (ctx) => const _CloseTicketDialog(),
    );
    if (note != null && mounted) {
      await _cubit.closeTicket(note: note.isEmpty ? null : note);
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
          backgroundColor: AppTheme.surface2,
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
                    _CollapsibleInfo(
                      body: 'Assigned to ${ticket.assigneeName ?? 'the routed role'}. Approve staff replies below, send a direct reply, or close the ticket.',
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
                          ticketRequesterLabel(
                            studentName: ticket.studentName,
                            householdName: ticket.householdName,
                            familyId: ticket.familyId,
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${categoryLabel(ticket.category.name)} · ${ticket.subtopic ?? ''}',
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
                            if (!isClosed && (isAssignee || isSuperAdmin))
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
                              final showDateHeader = i == 0 ||
                                  state.messages[i].createdAt.year != state.messages[i - 1].createdAt.year ||
                                  state.messages[i].createdAt.month != state.messages[i - 1].createdAt.month ||
                                  state.messages[i].createdAt.day != state.messages[i - 1].createdAt.day;

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
                                  if (showDateHeader)
                                    Center(
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(vertical: 12),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50.withOpacity(0.8),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _getDateHeaderString(msg.createdAt),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.blue300,
                                          ),
                                        ),
                                      ),
                                    ),
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
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Flexible(
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
                                        if (isSuperAdmin && isIncomingStaff &&
                                            msg.reviewStatus == TicketMessageReviewStatus.pending) ...[
                                          const SizedBox(width: 6),
                                          _ActionChip(
                                            label: 'Approve',
                                            icon: Icons.check_rounded,
                                            color: AppTheme.navy,
                                            filled: true,
                                            onTap: state.actionLoading
                                                ? null
                                                : () => _cubit.reviewMessage(
                                                      messageId: msg.id,
                                                      status: 'APPROVED',
                                                    ),
                                          ),
                                          const SizedBox(width: 4),
                                          _ActionChip(
                                            label: 'Reject',
                                            icon: Icons.close_rounded,
                                            color: Colors.grey.shade500,
                                            filled: false,
                                            onTap: state.actionLoading
                                                ? null
                                                : () => _showRejectDialog(msg.id),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (isOutgoing &&
                                      msg.senderType ==
                                          TicketMessageSenderType.staff)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 8,
                                        right: 8,
                                      ),
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              statusLabel(
                                                  msg.reviewStatus.name),
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: msg.reviewStatus.name ==
                                                        'pending'
                                                    ? Colors.orange.shade800
                                                    : msg.reviewStatus.name ==
                                                            'rejected'
                                                        ? Colors.red.shade700
                                                        : Colors.grey.shade600,
                                              ),
                                            ),
                                            if (msg.reviewStatus ==
                                                    TicketMessageReviewStatus
                                                        .rejected &&
                                                msg.reviewComment != null &&
                                                msg.reviewComment!.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 2),
                                                child: Text(
                                                  'Reason: ${msg.reviewComment}',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.red.shade700,
                                                  ),
                                                  textAlign: TextAlign.right,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                  ),
                  if (canCompose)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (state.parentTyping)
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 0, 16, 6),
                            child: Text(
                              'Parent is typing…',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.blue300,
                              ),
                            ),
                          ),
                        MessageInput(
                      isSending: state.sending,
                      replyingTo: null,
                      onCancelReply: () {},
                      students: const [],
                      onTypingChanged: (text) {
                        context.read<StaffTicketThreadCubit>().onComposerChanged(text);
                      },
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
                      ],
                    )
                  else if (isClosed)
                    SafeArea(
                      top: false,
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'This query is closed',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Messaging is disabled. You can still review the conversation history.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
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
    final comment = await showDialog<String?>(
      context: context,
      builder: (ctx) => const _RejectReplyDialog(),
    );
    if (comment != null && mounted) {
      await _cubit.reviewMessage(
        messageId: messageId,
        status: 'REJECTED',
        comment: comment,
      );
    }
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

  String _getDateHeaderString(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(date.year, date.month, date.day);

    if (msgDate == today) {
      return 'Today';
    } else if (msgDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM d, yyyy').format(date);
    }
  }
}

class _CloseTicketDialog extends StatefulWidget {
  const _CloseTicketDialog();

  @override
  State<_CloseTicketDialog> createState() => _CloseTicketDialogState();
}

class _CloseTicketDialogState extends State<_CloseTicketDialog> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Close ticket?'),
      content: TextField(
        controller: _noteController,
        decoration: const InputDecoration(
          hintText: 'Optional note for audit log',
        ),
        maxLines: 2,
      ),
      actions: [
        AppDialogActions.cancel(context),
        AppDialogActions.primary(
          context,
          label: 'Close',
          onPressed: () => Navigator.pop(context, _noteController.text.trim()),
        ),
      ],
    );
  }
}

class _RejectReplyDialog extends StatefulWidget {
  const _RejectReplyDialog();

  @override
  State<_RejectReplyDialog> createState() => _RejectReplyDialogState();
}

class _RejectReplyDialogState extends State<_RejectReplyDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject reply'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Rejection reason (required)',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a rejection reason';
            }
            return null;
          },
        ),
      ),
      actions: [
        AppDialogActions.cancel(context),
        AppDialogActions.destructive(
          context,
          label: 'Reject',
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.pop(context, _controller.text.trim());
            }
          },
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
  final VoidCallback? onTap;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.filled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: filled ? color : Colors.transparent,
            border: Border.all(color: color, width: 1.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: filled ? Colors.white : color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: filled ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollapsibleInfo extends StatefulWidget {
  final String body;
  const _CollapsibleInfo({required this.body});

  @override
  State<_CollapsibleInfo> createState() => _CollapsibleInfoState();
}

class _CollapsibleInfoState extends State<_CollapsibleInfo> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _expanded ? Icons.info_rounded : Icons.info_outline_rounded,
                  size: 18,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(width: 5),
                Text(
                  'Super Admin oversight',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade700,
                  ),
                ),
                const SizedBox(width: 3),
                Icon(
                  _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  size: 16,
                  color: Colors.amber.shade600,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Text(
                widget.body,
                style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
