import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../domain/entities/staff_support_ticket.dart';
import '../../domain/repositories/staff_support_ticket_repository.dart';

class StaffPickerSheet extends StatefulWidget {
  final StaffSupportTicketRepository repository;
  final String title;
  final String description;
  final List<String>? roleFilter;
  final String? excludeUserId;
  final void Function(StaffOption user) onSelect;

  const StaffPickerSheet({
    super.key,
    required this.repository,
    required this.title,
    required this.description,
    required this.onSelect,
    this.roleFilter,
    this.excludeUserId,
  });

  @override
  State<StaffPickerSheet> createState() => _StaffPickerSheetState();
}

class _StaffPickerSheetState extends State<StaffPickerSheet> {
  List<StaffOption> _staff = [];
  bool _loading = true;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await widget.repository.fetchStaffList();
      if (mounted) setState(() => _staff = list);
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to load staff list');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<StaffOption> get _filtered {
    final roles = widget.roleFilter;
    final q = _search.trim().toLowerCase();
    return _staff.where((s) {
      if (widget.excludeUserId != null && s.id == widget.excludeUserId) {
        return false;
      }
      if (roles != null && !roles.contains(s.role)) return false;
      if (q.isEmpty) return true;
      return s.fullName.toLowerCase().contains(q) ||
          s.username.toLowerCase().contains(q) ||
          s.role.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    widget.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.blue300,
                        ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search by name or username…',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 320,
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.navy))
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!, style: const TextStyle(color: AppTheme.danger)),
                              TextButton(onPressed: _load, child: const Text('Retry')),
                            ],
                          ),
                        )
                      : _filtered.isEmpty
                          ? const Center(child: Text('No matching staff found'))
                          : ListView.builder(
                              itemCount: _filtered.length,
                              itemBuilder: (context, i) {
                                final user = _filtered[i];
                                return ListTile(
                                  title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Text('${user.username} · ${user.role.replaceAll('_', ' ')}'),
                                  onTap: () {
                                    widget.onSelect(user);
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
