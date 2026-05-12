import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/domain/entities/parent.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_state.dart';

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

  bool _isLoading = false;

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

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8080/api/v1';
    final dio = Dio();

    try {
      final Map<String, dynamic> requestedData = {};

      void addIfChanged(String key, String? currentValue, String newValue) {
        final normalizedCurrent = (currentValue ?? '').trim();
        final normalizedNew = newValue.trim();
        
        // Skip if values are identical
        if (normalizedCurrent == normalizedNew) return;
        
        // Specifically ignore '+92' if the original was empty (common prefix issue)
        if (normalizedCurrent.isEmpty && normalizedNew == '+92') return;
        
        // Skip if the new value is empty and the current one is also effectively empty
        if (normalizedCurrent.isEmpty && normalizedNew.isEmpty) return;

        requestedData[key] = normalizedNew;
      }

      addIfChanged("primary_phone", widget.guardian.phone, _phoneController.text);
      addIfChanged("whatsapp_number", widget.guardian.whatsapp, _whatsappController.text);
      addIfChanged("email_address", widget.guardian.email, _emailController.text);
      addIfChanged("cnic", widget.guardian.cnic, _cnicController.text);
      addIfChanged("occupation", widget.guardian.occupation, _occupationController.text);
      addIfChanged("job_position", widget.guardian.jobPosition, _jobPositionController.text);
      addIfChanged("organization", widget.guardian.organization, _organizationController.text);
      addIfChanged("education_level", widget.guardian.education, _educationController.text);
      addIfChanged("mailing_address", widget.guardian.address, _addressController.text);

      if (requestedData.isEmpty) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No changes detected.')),
        );
        return;
      }

      final response = await dio.post(
        '$baseUrl/parent-change-requests',
        data: {
          "guardian_id": widget.guardian.id,
          "family_id": authState.parent.id,
          "requested_data": requestedData,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${authState.parent.accessToken}',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request submitted successfully! Admin will review it soon.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit request: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Edit Profile Request'),
        backgroundColor: AppTheme.surface1,
        foregroundColor: AppTheme.textMain,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Editing: ${widget.guardian.name}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your changes will be sent to the admin for approval.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(_phoneController, 'Phone', Icons.phone_outlined),
                    _buildTextField(_whatsappController, 'WhatsApp', Icons.chat_bubble_outline),
                    _buildTextField(_emailController, 'Email', Icons.email_outlined),
                    _buildTextField(_cnicController, 'CNIC', Icons.badge_outlined),
                    _buildTextField(_occupationController, 'Occupation', Icons.work_outline),
                    _buildTextField(_jobPositionController, 'Job Position', Icons.person_pin_circle_outlined),
                    _buildTextField(_organizationController, 'Organization', Icons.business_outlined),
                    _buildTextField(_educationController, 'Education', Icons.school_outlined),
                    _buildTextField(_addressController, 'Home Address', Icons.location_on_outlined, maxLines: 3),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _submitRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Submit Change Request',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
          filled: true,
          fillColor: AppTheme.surface1,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.borderSubtle),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.borderSubtle),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
          ),
          labelStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
        ),
      ),
    );
  }
}
