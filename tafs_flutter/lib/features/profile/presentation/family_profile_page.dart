import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_dialog_actions.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../auth/domain/entities/parent.dart';
import '../../auth/domain/entities/student.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_state.dart';
import '../../auth/presentation/bloc/auth_event.dart';
import '../../auth/presentation/bloc/selected_student_cubit.dart';
import 'widgets/student_profile_loader.dart';
import 'edit_guardian_page.dart';

class FamilyProfilePage extends StatefulWidget {
  final bool showAppBar;
  const FamilyProfilePage({super.key, this.showAppBar = true});

  @override
  State<FamilyProfilePage> createState() => _FamilyProfilePageState();
}

class _FamilyProfilePageState extends State<FamilyProfilePage> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
        context.read<AuthBloc>().add(AuthRefreshRequested());
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (_, current) => current is AuthProfileRefreshFailed,
      listener: (context, state) {
        if (state is AuthProfileRefreshFailed) {
          showAppSnackBar(context, state.message, type: AppSnackBarType.error);
          context.read<AuthBloc>().add(
            AuthProfileRefreshFailureAcknowledged(state.parent),
          );
        }
      },
      child: Scaffold(
      backgroundColor: AppTheme.white,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: AppTheme.white,
              foregroundColor: AppTheme.navy,
              elevation: 0,
              title: const Text(
                'Family Profile',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            )
          : null,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final Parent? parent = switch (authState) {
            AuthAuthenticated(:final parent) => parent,
            AuthProfileRefreshFailed(:final parent) => parent,
            _ => null,
          };

          if (parent == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.space6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 64, color: AppTheme.blue100),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      'Access Restricted',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppTheme.space2),
                    Text(
                      'Please log in to view your family profile.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.blue300),
                    ),
                  ],
                ),
              ),
            );
          }

          return BlocBuilder<SelectedStudentCubit, Student?>(
            builder: (context, activeStudent) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<AuthBloc>().add(AuthRefreshRequested());
                  await Future.delayed(const Duration(milliseconds: 800));
                },
                color: AppTheme.navy,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppTheme.space5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ParentHeaderCard(parent: parent),
                      if (parent.guardians.isNotEmpty) ...[
                        const SizedBox(height: AppTheme.space6),
                        Text(
                          'GUARDIANS',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppTheme.blue300,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                        ),
                        const SizedBox(height: AppTheme.space3),
                        ...parent.guardians.map(
                          (guardian) => Padding(
                            padding: const EdgeInsets.only(bottom: AppTheme.space3),
                            child: _GuardianCard(guardian: guardian),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppTheme.space6),
                      Text(
                        'CHILDREN',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.blue300,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                      ),
                      const SizedBox(height: AppTheme.space3),
                      ...parent.students.map(
                        (student) => Padding(
                          padding: const EdgeInsets.only(bottom: AppTheme.space3),
                          child: _StudentInfoCard(
                            student: student,
                            isActive: activeStudent?.cc == student.cc,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.space10),
                      const Divider(color: AppTheme.blue100),
                      const SizedBox(height: AppTheme.space4),
                      if (!widget.showAppBar) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                context.read<AuthBloc>().add(AuthLogoutRequested()),
                            icon: const Icon(Icons.logout_rounded, size: 18),
                            label: const Text(
                              'Log out',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.navy,
                              side: const BorderSide(color: AppTheme.navy),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.space5),
                      ],
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () async {
                            final reason = await _showDeleteAccountDialog(context);
                            if (reason == null) return;
                            if (!context.mounted) return;
                            context.read<AuthBloc>().add(AuthDeleteAccountRequested(reason));
                          },
                          icon: const Icon(
                            Icons.delete_forever_outlined,
                            size: 14,
                            color: AppTheme.blue300,
                          ),
                          label: const Text(
                            'Request account deletion',
                            style: TextStyle(
                              color: AppTheme.blue300,
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.space2),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    ),
    );
  }
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

class _ParentHeaderCard extends StatelessWidget {
  final Parent parent;
  const _ParentHeaderCard({required this.parent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.navy, Color(0xFF1B436D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowMd,
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.white.withValues(alpha: 0.2)),
              image: parent.photographUrl != null
                  ? DecorationImage(
                      image: NetworkImage(parent.photographUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: parent.photographUrl == null
                ? const Icon(Icons.family_restroom_rounded, color: AppTheme.white, size: 32)
                : null,
          ),
          const SizedBox(width: AppTheme.space5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Family Household',
                  style: TextStyle(
                    color: AppTheme.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  parent.householdName,
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  parent.username.isNotEmpty ? parent.username : 'No primary email',
                  style: TextStyle(
                    color: AppTheme.white.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.blue300, fontSize: 13, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(color: AppTheme.navy, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}

class _StudentInfoCard extends StatelessWidget {
  final Student student;
  final bool isActive;

  const _StudentInfoCard({required this.student, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.blue100, width: 1.0),
        boxShadow: AppTheme.shadowSm,
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => StudentProfileLoader(studentCc: student.cc)),
          );
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.navy.withValues(alpha: 0.05),
                    backgroundImage: student.photographUrl != null
                        ? NetworkImage(student.photographUrl!)
                        : null,
                    child: student.photographUrl == null
                        ? Text(
                            student.fullName[0],
                            style: const TextStyle(color: AppTheme.navy, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  const SizedBox(width: AppTheme.space4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.fullName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.navy),
                        ),
                        Text(
                          '${student.className ?? "N/A"} • Section ${student.section ?? "N/A"}',
                          style: TextStyle(color: AppTheme.blue300, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: AppTheme.space2),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.blue100),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuardianCard extends StatelessWidget {
  final FamilyGuardian guardian;
  const _GuardianCard({required this.guardian});

  void _showGuardianDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _GuardianDetailsSheet(guardian: guardian),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.blue100),
      ),
      child: InkWell(
        onTap: () => _showGuardianDetails(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space4),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.navy.withValues(alpha: 0.05),
                backgroundImage: guardian.photographUrl != null
                    ? NetworkImage(guardian.photographUrl!)
                    : null,
                child: guardian.photographUrl == null
                    ? const Icon(Icons.person_outline, color: AppTheme.navy)
                    : null,
              ),
              const SizedBox(width: AppTheme.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guardian.name,
                      style: const TextStyle(color: AppTheme.navy, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      guardian.relationship,
                      style: const TextStyle(color: AppTheme.blue300, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              if (guardian.isEmergencyContact)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.emergency_rounded, color: AppTheme.danger, size: 18),
                ),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.blue100),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuardianDetailsSheet extends StatelessWidget {
  final FamilyGuardian guardian;
  const _GuardianDetailsSheet({required this.guardian});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(AppTheme.space4, 0, AppTheme.space4, AppTheme.space8),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppTheme.shadowLg,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.blue100, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: AppTheme.space6),
            CircleAvatar(
              radius: 48,
              backgroundColor: AppTheme.navy.withValues(alpha: 0.05),
              backgroundImage: guardian.photographUrl != null ? NetworkImage(guardian.photographUrl!) : null,
              child: guardian.photographUrl == null ? const Icon(Icons.person_outline, size: 48, color: AppTheme.navy) : null,
            ),
            const SizedBox(height: AppTheme.space4),
            Text(guardian.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.navy)),
            Text(guardian.relationship.toUpperCase(), style: const TextStyle(color: AppTheme.blue300, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12)),
            if (guardian.isEmergencyContact) ...[
              const SizedBox(height: AppTheme.space3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppTheme.radiusFull)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.emergency_rounded, size: 14, color: AppTheme.danger),
                  SizedBox(width: 6),
                  Text('EMERGENCY CONTACT', style: TextStyle(color: AppTheme.danger, fontSize: 10, fontWeight: FontWeight.bold)),
                ]),
              ),
            ],
            const SizedBox(height: AppTheme.space6),
            _SheetDetailItem(icon: Icons.phone_rounded, label: 'Phone', value: guardian.phone ?? 'N/A'),
            _SheetDetailItem(icon: Icons.chat_bubble_rounded, label: 'WhatsApp', value: guardian.whatsapp ?? 'N/A'),
            _SheetDetailItem(icon: Icons.email_rounded, label: 'Email', value: guardian.email ?? 'N/A'),
            _SheetDetailItem(icon: Icons.badge_rounded, label: 'CNIC', value: guardian.cnic ?? 'N/A'),
            _SheetDetailItem(icon: Icons.work_rounded, label: 'Occupation', value: guardian.occupation ?? 'N/A'),
            _SheetDetailItem(icon: Icons.location_on_rounded, label: 'Address', value: guardian.address ?? 'N/A'),
            const SizedBox(height: AppTheme.space6),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => EditGuardianPage(guardian: guardian)));
                },
                icon: const Icon(Icons.edit_note_rounded),
                label: const Text('EDIT PROFILE'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.navy, foregroundColor: AppTheme.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusFull))),
              ),
            ),
            const SizedBox(height: AppTheme.space2),
          ],
        ),
      ),
    );
  }
}

class _SheetDetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _SheetDetailItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space4),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(AppTheme.space2), decoration: BoxDecoration(color: AppTheme.navy.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(AppTheme.radiusSm)), child: Icon(icon, size: 18, color: AppTheme.blue300)),
          const SizedBox(width: AppTheme.space4),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.blue200, fontWeight: FontWeight.bold)),
            Text(value, style: const TextStyle(fontSize: 14, color: AppTheme.navy, fontWeight: FontWeight.w600)),
          ])),
        ],
      ),
    );
  }
}
