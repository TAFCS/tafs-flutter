import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/repositories/leave_requests_repository_impl.dart';
import '../../domain/entities/leave_request.dart';

class SubmitLeavePage extends StatefulWidget {
  final LeaveRequestsRepositoryImpl repository;

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
        _selectedCode = ctx.leaveTypes.isNotEmpty ? ctx.leaveTypes.first.code : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

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
        _error = e.toString();
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
        _error = e.toString();
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apply for Leave')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_error!, style: const TextStyle(color: Colors.red)),
                    ),
                  DropdownButtonFormField<String>(
                    value: _selectedCode,
                    decoration: const InputDecoration(labelText: 'Leave type', border: OutlineInputBorder()),
                    items: (_context?.leaveTypes ?? [])
                        .map((t) => DropdownMenuItem(value: t.code, child: Text(t.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCode = v),
                  ),
                  if (_casualBlocked)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Casual leave requires 14 months of service.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Start date'),
                    subtitle: Text(_startDate == null ? 'Select' : _fmt(_startDate!)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _pickDate(isStart: true),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('End date'),
                    subtitle: Text(_endDate == null ? 'Select' : _fmt(_endDate!)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _pickDate(isStart: false),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _reasonController,
                    decoration: InputDecoration(
                      labelText: _needsReason ? 'Reason *' : 'Reason (optional)',
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  if (_needsAttachment) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _submitting ? null : _pickAttachment,
                      icon: const Icon(Icons.attach_file),
                      label: Text(_attachmentName ?? 'Upload attachment (image/PDF)'),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _submitting || _casualBlocked ? null : _submit,
                    style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Submit'),
                  ),
                ],
              ),
            ),
    );
  }
}
