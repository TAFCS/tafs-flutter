import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/repositories/staff_attendance_repository.dart';

class MyObjectionsPage extends StatefulWidget {
  final StaffAttendanceRepository repository;

  const MyObjectionsPage({super.key, required this.repository});

  @override
  State<MyObjectionsPage> createState() => _MyObjectionsPageState();
}

class _MyObjectionsPageState extends State<MyObjectionsPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

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
      final items = await widget.repository.getMyObjections();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM yyyy • h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Objections'),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.navy,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _items.isEmpty
                  ? const Center(child: Text('No objections filed yet.'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final o = _items[index];
                          final status = o['status'] as String? ?? '';
                          final date = o['attendance_date'] as String?;
                          final claimed = o['claimed_time'] as String?;
                          return ExpansionTile(
                            title: Text(date ?? '—'),
                            subtitle: Text(status),
                            children: [
                              if (claimed != null)
                                ListTile(
                                  title: const Text('Claimed time'),
                                  subtitle: Text(
                                    fmt.format(DateTime.parse(claimed).toLocal()),
                                  ),
                                ),
                              if (status == 'REJECTED' && o['admin_notes'] != null)
                                ListTile(
                                  title: const Text('Admin notes'),
                                  subtitle: Text(o['admin_notes'] as String),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
    );
  }
}
