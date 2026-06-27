import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/staff_attendance_period.dart';
import '../../domain/repositories/staff_attendance_repository.dart';

class ObjectionSubmitPage extends StatefulWidget {
  final DateTime attendanceDate;
  final List<StaffScan> scans;
  final StaffScan? preselectedScan;
  final StaffAttendanceRepository repository;

  const ObjectionSubmitPage({
    super.key,
    required this.attendanceDate,
    required this.scans,
    this.preselectedScan,
    required this.repository,
  });

  @override
  State<ObjectionSubmitPage> createState() => _ObjectionSubmitPageState();
}

class _ObjectionSubmitPageState extends State<ObjectionSubmitPage> {
  int? _scanId;
  TimeOfDay? _claimedTime;
  final _reasonController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _scanId = widget.preselectedScan?.id;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_claimedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select the claimed time')),
      );
      return;
    }
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reason')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final dayLocal = widget.attendanceDate.toLocal();
      final claimedLocal = DateTime(
        dayLocal.year,
        dayLocal.month,
        dayLocal.day,
        _claimedTime!.hour,
        _claimedTime!.minute,
      );
      final claimed = claimedLocal.toUtc();
      await widget.repository.submitObjection(
        attendanceDate: widget.attendanceDate,
        scanId: _scanId,
        claimedTime: claimed,
        reason: _reasonController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Objection submitted')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Raise Objection'),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.navy,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<int?>(
            value: _scanId,
            decoration: const InputDecoration(labelText: 'Which punch?'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Not a specific punch')),
              ...widget.scans.map(
                (s) => DropdownMenuItem(
                  value: s.id,
                  child: Text(
                    '${fmt.format(s.scanTime.toLocal())} — ${s.direction ?? 'PUNCH'}',
                  ),
                ),
              ),
            ],
            onChanged: (v) => setState(() => _scanId = v),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('I claim the time was'),
            subtitle: Text(
              _claimedTime != null
                  ? _claimedTime!.format(context)
                  : 'Tap to select',
            ),
            trailing: const Icon(Icons.access_time),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _claimedTime ?? TimeOfDay.now(),
              );
              if (picked != null) setState(() => _claimedTime = picked);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            maxLines: 4,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Reason / Explanation',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit Objection'),
          ),
        ],
      ),
    );
  }
}
