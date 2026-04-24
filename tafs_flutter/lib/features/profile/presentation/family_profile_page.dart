import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/domain/entities/parent.dart';
import '../../auth/domain/entities/student.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_state.dart';
import '../../auth/presentation/bloc/selected_student_cubit.dart';
import 'widgets/student_profile_loader.dart';

class FamilyProfilePage extends StatelessWidget {
  const FamilyProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface1,
        foregroundColor: AppTheme.textMain,
        elevation: 0,
        title: const Text(
          'Family Profile',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is! AuthAuthenticated) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Family profile is only available after login.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }

          final Parent parent = authState.parent;

          return BlocBuilder<SelectedStudentCubit, Student?>(
            builder: (context, activeStudent) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ParentHeaderCard(parent: parent),
                    const SizedBox(height: 16),
                    _ParentDetailsCard(parent: parent),
                    if (parent.guardians.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Guardians',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMain,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...parent.guardians.map(
                        (guardian) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _GuardianCard(guardian: guardian),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    const Text(
                      'Children',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMain,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...parent.students.map(
                      (student) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _StudentInfoCard(
                          student: student,
                          isActive: activeStudent?.cc == student.cc,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ParentHeaderCard extends StatelessWidget {
  final Parent parent;

  const _ParentHeaderCard({required this.parent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, Color(0xFF1B436D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
              image: parent.photographUrl != null
                  ? DecorationImage(
                      image: NetworkImage(parent.photographUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: parent.photographUrl == null
                ? const Icon(
                    Icons.family_restroom_rounded,
                    color: Colors.white,
                    size: 30,
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Household',
                  style: TextStyle(
                    color: Color(0xB3FFFFFF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  parent.householdName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  parent.username.isNotEmpty ? parent.username : 'No email',
                  style: const TextStyle(
                    color: Color(0xD9FFFFFF),
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

class _ParentDetailsCard extends StatelessWidget {
  final Parent parent;

  const _ParentDetailsCard({required this.parent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        children: [
          _detailRow('Family ID', '#${parent.id}'),
          const Divider(color: AppTheme.borderSubtle, height: 20),
          _detailRow(
            'Guardian Email',
            parent.username.isNotEmpty ? parent.username : 'Not available',
          ),
          const Divider(color: AppTheme.borderSubtle, height: 20),
          _detailRow('Children Linked', '${parent.students.length}'),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppTheme.textMain,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _StudentInfoCard extends StatelessWidget {
  final Student student;
  final bool isActive;

  const _StudentInfoCard({
    required this.student,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? AppTheme.primary : AppTheme.borderSubtle,
          width: isActive ? 1.3 : 1,
        ),
        boxShadow: AppTheme.shadowL1,
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentProfileLoader(studentCc: student.cc),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                    backgroundImage: student.photographUrl != null
                        ? NetworkImage(student.photographUrl!)
                        : null,
                    child: student.photographUrl == null
                        ? Text(
                            student.fullName.isNotEmpty
                                ? student.fullName[0]
                                : '?',
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      student.fullName,
                      style: const TextStyle(
                        color: AppTheme.textMain,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip('CC ${student.cc}'),
                  _chip(
                    student.grNumber != null ? 'GR ${student.grNumber}' : 'GR -',
                  ),
                  _chip(student.academicYear ?? 'Year -'),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${student.className ?? 'Class -'} • ${student.section ?? 'Section -'}',
                style: const TextStyle(
                  color: AppTheme.textMain,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                student.campus ?? 'Campus not assigned',
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
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
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 45,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
              backgroundImage: guardian.photographUrl != null
                  ? NetworkImage(guardian.photographUrl!)
                  : null,
              child: guardian.photographUrl == null
                  ? const Icon(Icons.person, size: 45, color: AppTheme.primary)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              guardian.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMain,
              ),
            ),
            Text(
              guardian.relationship.toUpperCase(),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
                letterSpacing: 1.2,
              ),
            ),
            if (guardian.isEmergencyContact) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emergency_rounded, size: 14, color: Colors.red),
                    SizedBox(width: 6),
                    Text(
                      'EMERGENCY CONTACT',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            _detailItem(Icons.phone_outlined, 'Phone', guardian.phone ?? 'N/A'),
            _detailItem(
              Icons.chat_bubble_outline_rounded,
              'WhatsApp',
              guardian.whatsapp ?? 'N/A',
            ),
            _detailItem(Icons.email_outlined, 'Email', guardian.email ?? 'N/A'),
            _detailItem(
              Icons.badge_outlined,
              'CNIC',
              guardian.cnic ?? 'N/A',
            ),
            _detailItem(
              Icons.work_outline,
              'Occupation',
              guardian.occupation ?? 'N/A',
            ),
            _detailItem(
              Icons.person_pin_circle_outlined,
              'Job Position',
              guardian.jobPosition ?? 'N/A',
            ),
            _detailItem(
              Icons.business_outlined,
              'Organization',
              guardian.organization ?? 'N/A',
            ),
            _detailItem(
              Icons.school_outlined,
              'Education',
              guardian.education ?? 'N/A',
            ),
            _detailItem(
              Icons.location_on_outlined,
              'Home Address',
              guardian.address ?? 'N/A',
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _detailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surface1,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppTheme.textMuted),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textMain,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: InkWell(
        onTap: () => _showGuardianDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                backgroundImage: guardian.photographUrl != null
                    ? NetworkImage(guardian.photographUrl!)
                    : null,
                child: guardian.photographUrl == null
                    ? const Icon(Icons.person, color: AppTheme.primary)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guardian.name,
                      style: const TextStyle(
                        color: AppTheme.textMain,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      guardian.relationship,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (guardian.isEmergencyContact) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.emergency_rounded, 
                              size: 12, 
                              color: Colors.red,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'EMERGENCY',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
