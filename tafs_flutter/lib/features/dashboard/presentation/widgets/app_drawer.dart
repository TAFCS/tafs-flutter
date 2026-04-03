import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/student.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/bloc/selected_student_cubit.dart';
import '../../../fee_ledger/presentation/pages/fee_ledger_page.dart';

class AppDrawer extends StatelessWidget {
  final Student student;

  const AppDrawer({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    String parentName = 'Parent / Guardian';
    if (authState is AuthAuthenticated) {
      parentName = authState.parent.householdName;
    }

    return Drawer(
      backgroundColor: AppTheme.background,
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.only(top: 64, bottom: 24, left: 16, right: 16),
            width: double.infinity,
            color: AppTheme.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.surface1,
                  child: Icon(Icons.person, color: AppTheme.primary, size: 36),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Parent Profile',
                  style: TextStyle(
                    color: Color(0xB3FFFFFF), // 70% white
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  parentName,
                  style: const TextStyle(
                    color: AppTheme.textOnPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Parent / Guardian',
                  style: TextStyle(
                    color: Color(0xB3FFFFFF), // 70% white
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Active Student: ${student.fullName}',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<SelectedStudentCubit, Student?>(
              builder: (context, selectedStudent) {
                final siblings = authState is AuthAuthenticated
                    ? authState.parent.students
                    : const <Student>[];
                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                _buildDrawerItem(
                  icon: Icons.dashboard,
                  text: 'Dashboard',
                  onTap: () => Navigator.pop(context),
                  isActive: true,
                ),
                _buildDrawerItem(
                  icon: Icons.account_balance_wallet,
                  text: 'Fee Ledger',
                  onTap: () {
                    Navigator.pop(context); // Close drawer first
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FeeLedgerPage(
                          studentCc: selectedStudent?.cc ?? student.cc,
                          studentName: selectedStudent?.fullName ?? student.fullName,
                        ),
                      ),
                    );
                  },
                ),
                if (siblings.length > 1) ...[
                  const Divider(),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'SWITCH STUDENT',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                    ),
                  ),
                  ...siblings.map(
                    (s) => ListTile(
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            AppTheme.primary.withValues(alpha: 0.1),
                        backgroundImage: s.photographUrl != null
                            ? NetworkImage(s.photographUrl!)
                            : null,
                        child: s.photographUrl == null
                            ? Text(
                                s.fullName[0],
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      title: Text(
                        s.fullName,
                        style: const TextStyle(
                          color: AppTheme.textMain,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${s.className ?? ''} ${s.section ?? ''}'.trim(),
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      trailing: (selectedStudent?.cc ?? student.cc) == s.cc
                          ? const Icon(Icons.check_circle,
                              color: Colors.green, size: 18)
                          : null,
                      onTap: () {
                        context.read<SelectedStudentCubit>().select(s);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
                _buildDrawerItem(
                  icon: Icons.download,
                  text: 'Downloads',
                  onTap: () {
                    // Navigate to Downloads
                  },
                ),
                const Divider(),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'FUTURE MODULES',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                  ),
                ),
                _buildDrawerItem(
                  icon: Icons.calendar_today,
                  text: 'Attendance',
                  isPlaceholder: true,
                ),
                _buildDrawerItem(
                  icon: Icons.assessment,
                  text: 'Report Cards',
                  isPlaceholder: true,
                ),
                _buildDrawerItem(
                  icon: Icons.people,
                  text: 'Staff Directory',
                  isPlaceholder: true,
                ),
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.logout,
                  text: 'Logout',
                  onTap: () {
                    context.read<AuthBloc>().add(AuthLogoutRequested());
                  },
                ),
                  ],
                );
              },
            ),
          ),
          const SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'TAFS App Version 1.0.0',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    VoidCallback? onTap,
    bool isActive = false,
    bool isPlaceholder = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isPlaceholder
            ? AppTheme.textMuted.withValues(alpha: 0.5)
            : (isActive ? AppTheme.primary : AppTheme.textMain),
      ),
      title: Text(
        text,
        style: TextStyle(
          color: isPlaceholder
              ? AppTheme.textMuted.withValues(alpha: 0.5)
              : (isActive ? AppTheme.primary : AppTheme.textMain),
          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      onTap: isPlaceholder ? null : onTap,
      trailing: isPlaceholder
          ? Icon(Icons.lock_outline,
              size: 16, color: AppTheme.textMuted.withValues(alpha: 0.5))
          : null,
    );
  }
}
