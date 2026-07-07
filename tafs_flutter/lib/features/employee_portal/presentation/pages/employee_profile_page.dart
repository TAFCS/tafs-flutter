import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/session/session_reset.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/change_password_page.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../data/employee_profile_repository.dart';
import '../../domain/entities/employee_profile.dart';

class EmployeeProfilePage extends StatefulWidget {
  final EmployeeProfileRepository repository;
  final String fallbackName;
  final bool embedded;

  const EmployeeProfilePage({
    super.key,
    required this.repository,
    required this.fallbackName,
    this.embedded = false,
  });

  @override
  State<EmployeeProfilePage> createState() => _EmployeeProfilePageState();
}

class _EmployeeProfilePageState extends State<EmployeeProfilePage> {
  EmployeeProfile? _profile;
  bool _loading = true;
  String? _error;

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
      final profile = await widget.repository.getMyProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is String ? e : 'Could not load profile.';
        _loading = false;
      });
    }
  }

  String _fmtJoinDate(String? iso) {
    if (iso == null) return '—';
    final d = DateTime.parse('${iso}T00:00:00Z');
    return DateFormat('d MMM yyyy').format(d);
  }

  void _logout(BuildContext context) {
    resetStaffSessionState(context);
    context.read<AuthBloc>().add(AuthLogoutRequested());
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final displayName = profile?.fullName ?? widget.fallbackName;

    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textMuted)),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppTheme.navy.withValues(alpha: 0.1),
                      backgroundImage: profile?.photoUrl != null ? NetworkImage(profile!.photoUrl!) : null,
                      child: profile?.photoUrl == null
                          ? Text(
                              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.navy,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      displayName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMain,
                      ),
                    ),
                    if (profile?.employeeCode != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        profile!.employeeCode!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      ),
                    ],
                    if (profile?.jobTitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        profile!.jobTitle!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _section('Work', [
              _row('Campus', profile?.campusName),
              _row('Department', profile?.departmentName),
              _row('Designation', profile?.designationName),
              _row('Category', profile?.staffCategory?.replaceAll('_', ' ')),
              _row('Join date', _fmtJoinDate(profile?.joinDate)),
              _row(
                'Service status',
                profile?.isPermanentEmployee == true ? 'Permanent (14+ months)' : 'Probation / new hire',
              ),
            ]),
            const SizedBox(height: 12),
            _section('Contact', [
              _row('Phone', profile?.personalPhone),
              _row('Email', profile?.personalEmail),
            ]),
            if (widget.embedded) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChangePasswordPage(isStaff: true),
                    ),
                  );
                },
                icon: const Icon(Icons.lock_outline_rounded, size: 18),
                label: const Text(
                  'Change password',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.navy,
                  side: const BorderSide(color: AppTheme.navy),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout),
                label: const Text('Log out', maxLines: 1, overflow: TextOverflow.ellipsis),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.danger,
                  side: const BorderSide(color: AppTheme.danger),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      );
    }

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      backgroundColor: AppTheme.surface2,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.navy,
        elevation: 0,
      ),
      body: body,
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.navy,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value?.trim().isNotEmpty == true ? value! : '—',
              style: const TextStyle(color: AppTheme.textMain, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
