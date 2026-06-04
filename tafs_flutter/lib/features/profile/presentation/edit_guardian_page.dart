import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/domain/entities/parent.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_state.dart';
import 'bloc/profile_bloc.dart';
import 'bloc/profile_event.dart';
import 'bloc/profile_state.dart';

class EditGuardianPage extends StatefulWidget {
  final FamilyGuardian guardian;

  const EditGuardianPage({super.key, required this.guardian});

  @override
  State<EditGuardianPage> createState() => _EditGuardianPageState();
}

class _EditGuardianPageState extends State<EditGuardianPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _phoneController;
  late TextEditingController _whatsappController;
  late TextEditingController _emailController;
  late TextEditingController _cnicController;
  late TextEditingController _occupationController;
  late TextEditingController _jobPositionController;
  late TextEditingController _organizationController;
  late TextEditingController _educationController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.guardian.phone);
    _whatsappController = TextEditingController(text: widget.guardian.whatsapp);
    _emailController = TextEditingController(text: widget.guardian.email);
    _cnicController = TextEditingController(text: widget.guardian.cnic);
    _occupationController = TextEditingController(text: widget.guardian.occupation);
    _jobPositionController = TextEditingController(text: widget.guardian.jobPosition);
    _organizationController = TextEditingController(text: widget.guardian.organization);
    _educationController = TextEditingController(text: widget.guardian.education);
    _addressController = TextEditingController(text: widget.guardian.address);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _cnicController.dispose();
    _occupationController.dispose();
    _jobPositionController.dispose();
    _organizationController.dispose();
    _educationController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _submitRequest() {
    if (!_formKey.currentState!.validate()) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final changes = <String, String>{};

    void addIfChanged(String key, String? current, String next) {
      final normalizedCurrent = (current ?? '').trim();
      final normalizedNext = next.trim();
      if (normalizedCurrent == normalizedNext) return;
      if (normalizedCurrent.isEmpty && normalizedNext == '+92') return;
      if (normalizedCurrent.isEmpty && normalizedNext.isEmpty) return;
      changes[key] = normalizedNext;
    }

    addIfChanged('primary_phone', widget.guardian.phone, _phoneController.text);
    addIfChanged('whatsapp_number', widget.guardian.whatsapp, _whatsappController.text);
    addIfChanged('email_address', widget.guardian.email, _emailController.text);
    addIfChanged('cnic', widget.guardian.cnic, _cnicController.text);
    addIfChanged('occupation', widget.guardian.occupation, _occupationController.text);
    addIfChanged('job_position', widget.guardian.jobPosition, _jobPositionController.text);
    addIfChanged('organization', widget.guardian.organization, _organizationController.text);
    addIfChanged('education_level', widget.guardian.education, _educationController.text);
    addIfChanged('mailing_address', widget.guardian.address, _addressController.text);

    if (changes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No changes detected.')),
      );
      return;
    }

    context.read<ProfileBloc>().add(GuardianChangeSubmitted(
      guardianId: widget.guardian.id,
      familyId: authState.parent.id,
      changes: changes,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request submitted! Admin will review it soon.'),
              backgroundColor: AppTheme.success,
            ),
          );
          Navigator.pop(context);
        } else if (state is ProfileError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is ProfileLoading;
        return Scaffold(
          backgroundColor: AppTheme.white,
          appBar: AppBar(
            title: const Text('Edit Profile'),
            backgroundColor: AppTheme.white,
            foregroundColor: AppTheme.navy,
            elevation: 0,
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.navy))
              : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.space5),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.space5),
                      decoration: BoxDecoration(
                        color: AppTheme.navy.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        border: Border.all(color: AppTheme.blue100),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: AppTheme.navy,
                            child: Icon(Icons.person_outline, color: AppTheme.white),
                          ),
                          const SizedBox(width: AppTheme.space4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.guardian.name,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.navy,
                                      ),
                                ),
                                Text(
                                  'Profile Update Request',
                                  style: TextStyle(color: AppTheme.blue300, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.space6),
                    Text(
                      'CONTACT INFORMATION',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.blue200,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                    ),
                    const SizedBox(height: AppTheme.space4),
                    _buildTextField(_phoneController, 'Primary Phone', Icons.phone_rounded),
                    _buildTextField(_whatsappController, 'WhatsApp Number', Icons.chat_bubble_rounded),
                    _buildTextField(_emailController, 'Email Address', Icons.email_rounded),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      'PROFESSIONAL DETAILS',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.blue200,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                    ),
                    const SizedBox(height: AppTheme.space4),
                    _buildTextField(_occupationController, 'Occupation', Icons.work_rounded),
                    _buildTextField(_jobPositionController, 'Job Position', Icons.person_pin_rounded),
                    _buildTextField(_organizationController, 'Organization', Icons.business_rounded),
                    _buildTextField(_educationController, 'Education Level', Icons.school_rounded),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      'OTHER INFORMATION',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.blue200,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                    ),
                    const SizedBox(height: AppTheme.space4),
                    _buildTextField(_cnicController, 'CNIC Number', Icons.badge_rounded),
                    _buildTextField(_addressController, 'Home Address', Icons.location_on_rounded, maxLines: 2),
                    const SizedBox(height: AppTheme.space8),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _submitRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.navy,
                          foregroundColor: AppTheme.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'SUBMIT CHANGES',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.space10),
                  ],
                ),
              ),
            ),
        );
      },
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space4),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.navy),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.blue200, size: 20),
          filled: true,
          fillColor: AppTheme.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            borderSide: const BorderSide(color: AppTheme.blue100),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            borderSide: const BorderSide(color: AppTheme.blue100),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            borderSide: const BorderSide(color: AppTheme.navy, width: 1.5),
          ),
          labelStyle: const TextStyle(color: AppTheme.blue300, fontSize: 13, fontWeight: FontWeight.w500),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
