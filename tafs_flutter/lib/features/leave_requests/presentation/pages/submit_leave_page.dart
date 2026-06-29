import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/repositories/leave_requests_repository.dart';
import '../../domain/entities/leave_request.dart';

const _leaveTypeOrder = ['SICK', 'CASUAL', 'ANNUAL', 'UNPAID'];

String? _leaveTypeHint(String code) {
  switch (code) {
    case 'SICK':
      return 'Medical certificate or doctor\'s note required';
    case 'CASUAL':
      return 'Available after 14 months of service';
    case 'ANNUAL':
      return 'Paid leave · reason required';
    case 'UNPAID':
      return 'Unpaid · reason required';
    default:
      return null;
  }
}

IconData _leaveTypeIcon(String code) {
  switch (code) {
    case 'SICK':
      return Icons.medical_services_outlined;
    case 'CASUAL':
      return Icons.weekend_outlined;
    case 'ANNUAL':
      return Icons.beach_access_outlined;
    case 'UNPAID':
      return Icons.money_off_outlined;
    default:
      return Icons.event_note_outlined;
  }
}

List<LeaveType> _sortedLeaveTypes(List<LeaveType> types) {
  final byCode = {for (final t in types) t.code: t};
  return _leaveTypeOrder.where(byCode.containsKey).map((c) => byCode[c]!).toList();
}

class SubmitLeavePage extends StatefulWidget {
  final LeaveRequestsRepository repository;

  const SubmitLeavePage({super.key, required this.repository});

  @override
  State<SubmitLeavePage> createState() => _SubmitLeavePageState();
}

class _SubmitLeavePageState extends State<SubmitLeavePage> {
  LeaveSelfContext? _context;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  String? _selectedCode;
  DateTime? _startDate;
  DateTime? _endDate;
  final _reasonController = TextEditingController();
  String? _attachmentUrl;
  String? _attachmentType;
  String? _attachmentName;

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadContext() async {
    try {
      final ctx = await widget.repository.getSelfContext();
      if (!mounted) return;
      setState(() {
        _context = ctx;
        _loading = false;
        final sorted = _sortedLeaveTypes(ctx.leaveTypes);
        _selectedCode = sorted.isNotEmpty ? sorted.first.code : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is String ? e : 'Something went wrong. Please try again.';
        _loading = false;
      });
    }
  }

  String _errorMessage(Object e) => e is String ? e : 'Something went wrong. Please try again.';

  Future<void> _pickAttachment() async {
    final ctx = _context;
    if (ctx == null) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,
    );
    final file = result?.files.single;
    if (file == null) return;

    setState(() => _submitting = true);
    try {
      final uploaded = await widget.repository.uploadAttachment(
        employeeId: ctx.employeeId,
        filePath: file.path ?? '',
        bytes: file.bytes,
        filename: file.name,
      );
      if (!mounted) return;
      setState(() {
        _attachmentUrl = uploaded.url;
        _attachmentType = uploaded.type;
        _attachmentName = file.name;
        _submitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _errorMessage(e);
        _submitting = false;
      });
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? _startDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  String _fmt(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  String _fmtDisplay(DateTime d) => DateFormat('d MMM yyyy').format(d);

  bool get _needsReason {
    final code = _selectedCode;
    return code == 'ANNUAL' || code == 'UNPAID';
  }

  bool get _needsAttachment => _selectedCode == 'SICK';

  bool get _casualBlocked =>
      _selectedCode == 'CASUAL' && !(_context?.isPermanentEmployee ?? false);

  Future<void> _submit() async {
    final ctx = _context;
    if (ctx == null || _selectedCode == null || _startDate == null || _endDate == null) {
      setState(() => _error = 'Please complete all required fields');
      return;
    }
    if (_casualBlocked) {
      setState(() => _error = 'Casual leave is available after 14 months of service');
      return;
    }
    if (_needsReason && _reasonController.text.trim().isEmpty) {
      setState(() => _error = 'Reason is required');
      return;
    }
    if (_needsAttachment && (_attachmentUrl == null || _attachmentType == null)) {
      setState(() => _error = 'Sick leave requires an attachment');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await widget.repository.submitRequest(
        leaveTypeCode: _selectedCode!,
        startDate: _fmt(_startDate!),
        endDate: _fmt(_endDate!),
        reason: _reasonController.text.trim().isEmpty ? null : _reasonController.text.trim(),
        attachmentUrl: _attachmentUrl,
        attachmentType: _attachmentType,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _errorMessage(e);
        _submitting = false;
      });
    }
  }

  void _onLeaveTypeChanged(String? code) {
    if (code == null) return;
    setState(() {
      _selectedCode = code;
      if (code != 'SICK') {
        _attachmentUrl = null;
        _attachmentType = null;
        _attachmentName = null;
      }
    });
  }

  Widget _leaveTypeSelector() {
    final types = _sortedLeaveTypes(_context?.leaveTypes ?? []);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Leave type',
          style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...types.map((type) {
          final selected = _selectedCode == type.code;
          final hint = _leaveTypeHint(type.code);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => _onLeaveTypeChanged(type.code),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.navy.withValues(alpha: 0.06) : AppTheme.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: selected ? AppTheme.navy : AppTheme.borderSubtle,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _leaveTypeIcon(type.code),
                      color: selected ? AppTheme.navy : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  type.name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: selected ? AppTheme.navy : AppTheme.textMain,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: type.isPaid ? AppTheme.paidBg : AppTheme.unpaidBg,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                ),
                                child: Text(
                                  type.isPaid ? 'Paid' : 'Unpaid',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: type.isPaid ? AppTheme.paid : AppTheme.danger,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (hint != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              hint,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (selected)
                      const Icon(Icons.check_circle, color: AppTheme.navy, size: 20),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _sickAttachmentSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warningBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.warning, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sick leave requires an attachment',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMain,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Upload a medical certificate, doctor\'s note, or prescription (JPG, PNG, or PDF).',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _submitting ? null : _pickAttachment,
            icon: const Icon(Icons.attach_file),
            label: Text(_attachmentName ?? 'Choose file'),
          ),
          if (_attachmentUrl != null && _attachmentType == 'image') ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              child: Image.network(
                _attachmentUrl!,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dateTile({
    required String title,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.borderSubtle),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          color: AppTheme.white,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  const SizedBox(height: 4),
                  Text(
                    value == null ? 'Tap to select' : _fmtDisplay(value),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: value == null ? AppTheme.textMuted : AppTheme.textMain,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.calendar_today_outlined, color: AppTheme.navy, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface2,
      appBar: AppBar(
        title: const Text('Apply for Leave'),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.navy,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.unpaidBg,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppTheme.danger, fontSize: 13),
                      ),
                    ),
                  _leaveTypeSelector(),
                  if (_casualBlocked)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.warningBg,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: const Text(
                        'Casual leave requires 14 months of service.',
                        style: TextStyle(color: AppTheme.warning, fontSize: 13),
                      ),
                    ),
                  const SizedBox(height: 14),
                  _dateTile(
                    title: 'Start date',
                    value: _startDate,
                    onTap: () => _pickDate(isStart: true),
                  ),
                  const SizedBox(height: 10),
                  _dateTile(
                    title: 'End date',
                    value: _endDate,
                    onTap: () => _pickDate(isStart: false),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _reasonController,
                    decoration: InputDecoration(
                      labelText: _needsReason ? 'Reason *' : 'Reason (optional)',
                    ),
                    maxLines: 3,
                    maxLength: 1000,
                  ),
                  if (_needsAttachment) ...[
                    const SizedBox(height: 14),
                    _sickAttachmentSection(),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _submitting || _casualBlocked ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.navy,
                      foregroundColor: AppTheme.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.white),
                          )
                        : const Text(
                            'Submit request',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
