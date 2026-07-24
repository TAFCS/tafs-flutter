import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_cached_network_image.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_state.dart';
import '../../fee_ledger/domain/entities/ledger.dart';
import 'bloc/profile_bloc.dart';
import 'bloc/profile_event.dart';
import 'bloc/profile_state.dart';

class EditStudentPage extends StatefulWidget {
  final StudentProfile student;

  const EditStudentPage({super.key, required this.student});

  @override
  State<EditStudentPage> createState() => _EditStudentPageState();
}

class _EditStudentPageState extends State<EditStudentPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  DateTime? _selectedDob;
  String? _selectedGender;
  File? _pickedImageFile;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.student.fullName);
    // Normalize to a local date-only value so timezone never shifts the calendar day.
    _selectedDob = _asLocalDateOnly(widget.student.dob);
    _selectedGender = widget.student.gender?.toUpperCase();
    if (_selectedGender != 'MALE' && _selectedGender != 'FEMALE') {
      _selectedGender = null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Calendar Y/M/D only — ignores time and timezone.
  DateTime? _asLocalDateOnly(DateTime? date) {
    if (date == null) return null;
    return DateTime(date.year, date.month, date.day);
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 500,
      );
      if (pickedFile != null) {
        setState(() {
          _pickedImageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick image.')),
      );
    }
  }

  Future<void> _selectDate() async {
    final initialDate = _selectedDob ?? DateTime(2018);
    // calendarOnly blocks typed MM/dd vs dd/MM ambiguity (common on en_US
    // devices in PK) which was submitting month/day-swapped DOBs
    // (e.g. 2010-07-12 → 2010-12-07).
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2005),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.navy,
              onPrimary: AppTheme.white,
              onSurface: AppTheme.navy,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDob = _asLocalDateOnly(pickedDate);
      });
    }
  }

  /// Match Postgres/Prisma JSON serialization for @db.Date fields:
  /// `YYYY-MM-DDT00:00:00.000Z`
  String? _dobToPostgresIso(DateTime? date) {
    final d = _asLocalDateOnly(date);
    if (d == null) return null;
    return DateTime.utc(d.year, d.month, d.day).toIso8601String();
  }

  void _submitRequest() {
    if (!_formKey.currentState!.validate()) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final changes = <String, dynamic>{};

    void addIfChanged(String key, dynamic current, dynamic next) {
      if (current == next) return;
      if (current == null && next == null) return;
      changes[key] = next;
    }

    addIfChanged('full_name', widget.student.fullName, _nameController.text.trim());

    final originalDob = _dobToPostgresIso(widget.student.dob);
    final nextDob = _dobToPostgresIso(_selectedDob);
    addIfChanged('dob', originalDob, nextDob);

    addIfChanged('gender', widget.student.gender?.toUpperCase(), _selectedGender);

    if (changes.isEmpty && _pickedImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No changes detected.')),
      );
      return;
    }

    context.read<ProfileBloc>().add(StudentChangeSubmitted(
      guardianId: authState.parent.guardians.isNotEmpty ? authState.parent.guardians.first.id : authState.parent.id,
      familyId: authState.parent.id,
      studentCc: widget.student.cc,
      changes: changes,
      localPhotoPath: _pickedImageFile?.path,
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
                        // Profile Image Picker
                        Center(
                          child: Stack(
                            children: [
                              GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppTheme.blue100, width: 3),
                                  ),
                                  child: CircleAvatar(
                                    radius: 60,
                                    backgroundColor: AppTheme.blue100.withValues(alpha: 0.3),
                                    backgroundImage: _pickedImageFile != null
                                        ? FileImage(_pickedImageFile!) as ImageProvider
                                        : appCachedNetworkImageProvider(widget.student.photographUrl),
                                    child: _pickedImageFile == null && widget.student.photographUrl == null
                                        ? const Icon(Icons.person, size: 60, color: AppTheme.navy)
                                        : null,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: AppTheme.navy,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      color: AppTheme.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTheme.space8),
                        
                        Text(
                          'BASIC INFORMATION',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppTheme.blue200,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                        ),
                        const SizedBox(height: AppTheme.space4),
                        
                        // Name
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.navy),
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: const Icon(Icons.person_rounded, color: AppTheme.blue200, size: 20),
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
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppTheme.space4),

                        // Date of Birth
                        GestureDetector(
                          onTap: _selectDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: AppTheme.white,
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              border: Border.all(color: AppTheme.blue100),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.cake_rounded, color: AppTheme.blue200, size: 20),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Date of Birth',
                                      style: TextStyle(color: AppTheme.blue300, fontSize: 11, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _selectedDob != null ? DateFormat('dd MMM yyyy').format(_selectedDob!) : 'Select Date',
                                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.navy, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.space4),

                        // Gender
                        DropdownButtonFormField<String>(
                          value: _selectedGender,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.navy, fontSize: 14),
                          decoration: InputDecoration(
                            labelText: 'Gender',
                            prefixIcon: const Icon(Icons.wc_rounded, color: AppTheme.blue200, size: 20),
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
                          items: const [
                            DropdownMenuItem(value: 'MALE', child: Text('Male')),
                            DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _selectedGender = val;
                            });
                          },
                        ),
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
}
