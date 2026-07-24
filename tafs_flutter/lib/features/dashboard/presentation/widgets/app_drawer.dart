import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/session/logout_lock.dart';
import '../../../../core/widgets/app_cached_network_image.dart';
import '../../../../core/widgets/app_dialog_actions.dart';
import '../../../auth/domain/entities/student.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/bloc/selected_student_cubit.dart';
import '../../../attendance_history/presentation/pages/attendance_calendar_page.dart';
import '../../../fee_ledger/presentation/pages/fee_ledger_page.dart';
import '../../../profile/presentation/family_profile_page.dart';

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
      backgroundColor: AppTheme.navy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        children: [
          // Premium Header
          Container(
            padding: const EdgeInsets.only(
              top: 80,
              bottom: 32,
              left: 24,
              right: 24,
            ),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.navy,
                  AppTheme.navy.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.blue300.withValues(alpha: 0.3), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: AppTheme.blue100,
                    backgroundImage: (authState is AuthAuthenticated)
                        ? (appCachedNetworkImageProvider(authState.parent.photographUrl) ??
                            (authState.parent.guardians.isNotEmpty
                                ? appCachedNetworkImageProvider(authState.parent.guardians.first.photographUrl)
                                : null))
                        : null,
                    child: (authState is! AuthAuthenticated || 
                            (authState.parent.photographUrl == null && 
                             (authState.parent.guardians.isEmpty || authState.parent.guardians.first.photographUrl == null)))
                        ? const Icon(Icons.person, color: AppTheme.navy, size: 36)
                        : null,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  parentName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Parent Portal Account',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.white.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    border: Border.all(color: AppTheme.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.school_rounded, color: AppTheme.blue100, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        student.fullName,
                        style: const TextStyle(color: AppTheme.white, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: BlocBuilder<SelectedStudentCubit, Student?>(
              builder: (context, selectedStudent) {
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    const SizedBox(height: 12),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.dashboard_rounded,
                      text: 'Dashboard',
                      onTap: () => Navigator.pop(context),
                      isActive: true,
                    ),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.account_balance_wallet_rounded,
                      text: 'Fee Ledger',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FeeLedgerPage(
                              studentCc: selectedStudent?.cc ?? student.cc,
                              studentName:
                                  selectedStudent?.fullName ?? student.fullName,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.family_restroom_rounded,
                      text: 'Family Profile',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FamilyProfilePage(),
                          ),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 32, bottom: 8),
                      child: Text(
                        'RESOURCES',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.white.withValues(alpha: 0.4),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.calendar_today_rounded,
                      text: 'Attendance',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AttendanceCalendarPage(
                              student: selectedStudent ?? student,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.assessment_rounded,
                      text: 'Report Cards',
                      isPlaceholder: true,
                    ),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.people_alt_rounded,
                      text: 'Staff Directory',
                      isPlaceholder: true,
                    ),
                  ],
                );
              },
            ),
          ),
          
          const Divider(color: Colors.white10),
          _buildDrawerItem(
            context: context,
            icon: Icons.delete_forever_rounded,
            text: 'Request Account Deletion',
            onTap: () async {
              Navigator.pop(context);

              final reason = await _showDeleteAccountDialog(context);
              if (reason == null) return;

              if (!context.mounted) return;
              context.read<AuthBloc>().add(AuthDeleteAccountRequested(reason));
            },
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.logout_rounded,
            text: 'Logout',
            onTap: () {
              if (isLoggingOutNotifier.value) return;
              Navigator.pop(context);
              isLoggingOutNotifier.value = true;
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'v1.0.0',
                style: TextStyle(color: AppTheme.white.withValues(alpha: 0.3), fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _showDeleteAccountDialog(BuildContext context) async {
    final controller = TextEditingController();
    final reasonController = TextEditingController();

    return showDialog<String?>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final reasonFilled = reasonController.text.trim().isNotEmpty;
            final deleteTyped = controller.text.trim().toUpperCase() == 'DELETE';

            return AlertDialog(
              title: const Text('Request account deletion?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your request will be sent to the school admin for review. '
                    'Your account stays active until it is approved.',
                  ),
                  const SizedBox(height: 12),
                  const Text('Reason for deletion:'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: reasonController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Please provide a reason',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  const Text('Type DELETE to confirm:'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
              actions: [
                AppDialogActions.cancel(
                  dialogContext,
                  onPressed: () => Navigator.of(dialogContext).pop(null),
                ),
                AppDialogActions.primary(
                  dialogContext,
                  label: 'Submit request',
                  onPressed: (reasonFilled && deleteTyped)
                      ? () => Navigator.of(dialogContext)
                          .pop(reasonController.text.trim())
                      : null,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String text,
    VoidCallback? onTap,
    bool isActive = false,
    bool isPlaceholder = false,
  }) {
    final Color textColor = isPlaceholder 
        ? AppTheme.white.withValues(alpha: 0.3)
        : (isActive ? AppTheme.white : AppTheme.white.withValues(alpha: 0.65));
        
    final Color? bgColor = isActive 
        ? AppTheme.blue300.withValues(alpha: 0.2)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: ListTile(
        dense: true,
        onTap: isPlaceholder ? null : onTap,
        leading: Icon(
          icon,
          color: textColor,
          size: 22,
        ),
        title: Text(
          text,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: textColor,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        trailing: isPlaceholder
            ? Icon(Icons.lock_outline_rounded, size: 14, color: AppTheme.white.withValues(alpha: 0.2))
            : null,
      ),
    );
  }
}


