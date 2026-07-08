import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../injection_container.dart';
import '../../data/datasources/quick_admission_remote_data_source.dart';
import '../../data/repositories/quick_admission_repository_impl.dart';
import '../cubit/quick_admission_cubit.dart';
import '../cubit/quick_admission_state.dart';
import 'deposit_slip_viewer_page.dart';

class _GuardianInput {
  final nameController = TextEditingController();
  final cnicController = TextEditingController();
  String relation = 'Father';

  void dispose() {
    nameController.dispose();
    cnicController.dispose();
  }
}

class QuickAdmissionFormPage extends StatefulWidget {
  const QuickAdmissionFormPage({super.key});

  @override
  State<QuickAdmissionFormPage> createState() => _QuickAdmissionFormPageState();
}

class _QuickAdmissionFormPageState extends State<QuickAdmissionFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _depositController = TextEditingController();

  // Multiple Guardians details
  bool _addGuardian = false;
  final List<_GuardianInput> _guardians = [];

  DateTime? _selectedDob;
  String _gender = 'Male';
  int? _selectedCampusId;
  File? _selectedImage;

  List<Map<String, dynamic>> _campuses = [];
  bool _loadingCampuses = true;

  @override
  void initState() {
    super.initState();
    _fetchCampuses();
    // Add one default guardian input
    _guardians.add(_GuardianInput());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _depositController.dispose();
    for (final g in _guardians) {
      g.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchCampuses() async {
    try {
      final response = await InjectionContainer.dio.get('/campuses');
      final data = response.data;
      final list = data is List ? data : (data['data'] as List? ?? []);
      setState(() {
        _campuses = list.map((e) => {
          'id': e['id'] as int,
          'name': e['campus_name'] as String,
        }).toList();
        _loadingCampuses = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loadingCampuses = false);
        showAppSnackBar(context, 'Failed to load campuses', type: AppSnackBarType.error);
      }
    }
  }

  String _calculateAge(DateTime dob) {
    final today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return '$age Yrs';
  }

  Future<void> _selectDob(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.navy,
              onPrimary: Colors.white,
              onSurface: AppTheme.navy,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDob) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.navy),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.navy),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final pickedFile = await picker.pickImage(imageQuality: 70, source: source);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    }
  }

  void _submitForm(QuickAdmissionCubit cubit) {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCampusId == null) {
      showAppSnackBar(context, 'Please select a campus', type: AppSnackBarType.error);
      return;
    }

    final List<Map<String, dynamic>> guardiansData = [];
    if (_addGuardian) {
      for (final g in _guardians) {
        if (g.nameController.text.trim().isNotEmpty) {
          guardiansData.add({
            'name': g.nameController.text.trim(),
            'relation': g.relation,
            'cnic': g.cnicController.text.trim().isNotEmpty
                ? g.cnicController.text.trim()
                : null,
          });
        }
      }
    }

    final data = {
      'full_name': _nameController.text.trim().toUpperCase(),
      'date_of_birth': _selectedDob!.toIso8601String(),
      'gender': _gender,
      'address': _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
      'campus_id': _selectedCampusId,
      'deposit_amount': double.parse(_depositController.text.trim()),
      'guardians': guardiansData.isNotEmpty ? guardiansData : null,
    };

    cubit.submitAdmissionForm(data, _selectedImage?.path);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => QuickAdmissionCubit(
        repository: QuickAdmissionRepositoryImpl(
          remoteDataSource: QuickAdmissionRemoteDataSourceImpl(InjectionContainer.dio),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quick Admission Form'),
          centerTitle: true,
        ),
        body: _loadingCampuses
            ? const Center(child: CircularProgressIndicator())
            : BlocConsumer<QuickAdmissionCubit, QuickAdmissionState>(
                listener: (context, state) {
                  if (state is QuickAdmissionSubmitSuccess) {
                    showAppSnackBar(context, 'Admission record saved successfully!', type: AppSnackBarType.success);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DepositSlipViewerPage(cc: state.admission.id),
                      ),
                    );
                  } else if (state is QuickAdmissionSubmitFailure) {
                    showAppSnackBar(context, state.message, type: AppSnackBarType.error);
                  }
                },
                builder: (context, state) {
                  final cubit = context.read<QuickAdmissionCubit>();
                  final isLoading = state is QuickAdmissionSubmitInProgress;

                  return Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(AppTheme.space4),
                      children: [
                        // Card wrapper for aesthetics
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.space4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Candidate Information',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.navy,
                                      ),
                                ),
                                const SizedBox(height: AppTheme.space4),
                                CustomTextField(
                                  label: "CANDIDATE'S FULL NAME (BLOCK LETTERS)",
                                  controller: _nameController,
                                  hint: 'ENTER FULL NAME',
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Full name is required';
                                    }
                                    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(val)) {
                                      return 'Full name must contain only alphabets';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppTheme.space3),
                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => _selectDob(context),
                                        child: AbsorbPointer(
                                          child: CustomTextField(
                                            label: 'DATE OF BIRTH',
                                            controller: _dobController,
                                            hint: 'DD/MM/YYYY',
                                            validator: (val) {
                                              if (_selectedDob == null) {
                                                return 'Date of birth is required';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (_selectedDob != null) ...[
                                      const SizedBox(width: AppTheme.space3),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'AGE AT REGISTRATION',
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme.navy,
                                                  ),
                                            ),
                                            const SizedBox(height: AppTheme.space2),
                                            Container(
                                              height: 52,
                                              alignment: Alignment.centerLeft,
                                              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space4),
                                              decoration: BoxDecoration(
                                                color: AppTheme.surface2,
                                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                                border: Border.all(color: AppTheme.blue200, width: 1.5),
                                              ),
                                              child: Text(
                                                _calculateAge(_selectedDob!),
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navy),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: AppTheme.space3),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'GENDER',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.navy,
                                          ),
                                    ),
                                    Row(
                                      children: [
                                        Radio<String>(
                                          value: 'Male',
                                          groupValue: _gender,
                                          activeColor: AppTheme.navy,
                                          onChanged: (val) => setState(() => _gender = val!),
                                        ),
                                        const Text('Male', style: TextStyle(color: AppTheme.navy)),
                                        const SizedBox(width: AppTheme.space4),
                                        Radio<String>(
                                          value: 'Female',
                                          groupValue: _gender,
                                          activeColor: AppTheme.navy,
                                          onChanged: (val) => setState(() => _gender = val!),
                                        ),
                                        const Text('Female', style: TextStyle(color: AppTheme.navy)),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppTheme.space3),
                                CustomTextField(
                                  label: 'ADDRESS',
                                  controller: _addressController,
                                  hint: 'ENTER RESIDENTIAL ADDRESS',
                                ),
                                const SizedBox(height: AppTheme.space3),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CAMPUS',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.navy,
                                          ),
                                    ),
                                    const SizedBox(height: AppTheme.space2),
                                    DropdownButtonFormField<int>(
                                      value: _selectedCampusId,
                                      hint: const Text('SELECT CAMPUS'),
                                      style: const TextStyle(color: AppTheme.navy),
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.space4, vertical: AppTheme.space3),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                          borderSide: const BorderSide(color: AppTheme.blue200, width: 1.5),
                                        ),
                                      ),
                                      items: _campuses.map((c) {
                                        return DropdownMenuItem<int>(
                                          value: c['id'] as int,
                                          child: Text(c['name'] as String),
                                        );
                                      }).toList(),
                                      onChanged: (val) => setState(() => _selectedCampusId = val),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.space3),
                        
                        // Guardians Collapsible Card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.space4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Guardian Information',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.navy,
                                          ),
                                    ),
                                    Switch(
                                      value: _addGuardian,
                                      activeColor: AppTheme.navy,
                                      onChanged: (val) => setState(() => _addGuardian = val),
                                    ),
                                  ],
                                ),
                                if (_addGuardian) ...[
                                  const Divider(height: AppTheme.space4),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _guardians.length,
                                    itemBuilder: (context, index) {
                                      final guardian = _guardians[index];
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: AppTheme.space4),
                                        padding: const EdgeInsets.all(AppTheme.space3),
                                        decoration: BoxDecoration(
                                          color: AppTheme.surface2,
                                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                          border: Border.all(color: AppTheme.blue100, width: 1),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'Guardian #${index + 1}',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navy),
                                                ),
                                                if (_guardians.length > 1)
                                                  IconButton(
                                                    icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
                                                    onPressed: () {
                                                      setState(() {
                                                        _guardians.removeAt(index);
                                                      });
                                                    },
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: AppTheme.space2),
                                            CustomTextField(
                                              label: 'GUARDIAN NAME',
                                              controller: guardian.nameController,
                                              hint: 'ENTER GUARDIAN NAME',
                                              validator: (val) {
                                                if (_addGuardian && (val == null || val.trim().isEmpty)) {
                                                  return 'Guardian name is required';
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: AppTheme.space3),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'RELATION',
                                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                        fontWeight: FontWeight.w600,
                                                        color: AppTheme.navy,
                                                      ),
                                                ),
                                                const SizedBox(height: AppTheme.space2),
                                                DropdownButtonFormField<String>(
                                                  value: guardian.relation,
                                                  style: const TextStyle(color: AppTheme.navy),
                                                  decoration: InputDecoration(
                                                    contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.space4, vertical: AppTheme.space3),
                                                    border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                                      borderSide: const BorderSide(color: AppTheme.blue200, width: 1.5),
                                                    ),
                                                  ),
                                                  items: const [
                                                    DropdownMenuItem(value: 'Father', child: Text('Father')),
                                                    DropdownMenuItem(value: 'Mother', child: Text('Mother')),
                                                    DropdownMenuItem(value: 'Guardian', child: Text('Other / Guardian')),
                                                  ],
                                                  onChanged: (val) => setState(() => guardian.relation = val!),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: AppTheme.space3),
                                            CustomTextField(
                                              label: 'GUARDIAN CNIC',
                                              controller: guardian.cnicController,
                                              hint: '42101-1234567-1',
                                              keyboardType: TextInputType.number,
                                              inputFormatters: [
                                                FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]')),
                                                LengthLimitingTextInputFormatter(15),
                                              ],
                                              validator: (val) {
                                                if (_addGuardian && (val == null || val.trim().isEmpty)) {
                                                  return 'CNIC is required';
                                                }
                                                if (_addGuardian && !RegExp(r'^[0-9]{5}-[0-9]{7}-[0-9]$').hasMatch(val!)) {
                                                  return 'Invalid CNIC format. Follow 12345-1234567-1';
                                                }
                                                return null;
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: AppTheme.space2),
                                  TextButton.icon(
                                    icon: const Icon(Icons.add, color: AppTheme.navy),
                                    label: const Text('Add Another Guardian', style: TextStyle(color: AppTheme.navy, fontWeight: FontWeight.bold)),
                                    onPressed: () {
                                      setState(() {
                                        _guardians.add(_GuardianInput());
                                      });
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.space3),

                        // Image Upload and Deposit card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.space4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Admission Details & Photo',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.navy,
                                      ),
                                ),
                                const SizedBox(height: AppTheme.space4),
                                CustomTextField(
                                  label: 'DEPOSIT AMOUNT (PKR)',
                                  controller: _depositController,
                                  hint: 'ENTER DEPOSIT AMOUNT',
                                  keyboardType: TextInputType.number,
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Deposit amount is required';
                                    }
                                    if (double.tryParse(val) == null || double.parse(val) < 0) {
                                      return 'Please enter a valid positive amount';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppTheme.space4),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: _pickImage,
                                      child: Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          color: AppTheme.surface2,
                                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                          border: Border.all(color: AppTheme.blue200, width: 1.5),
                                        ),
                                        child: _selectedImage == null
                                            ? const Icon(Icons.add_a_photo, color: AppTheme.blue300, size: 30)
                                            : ClipRRect(
                                                borderRadius: BorderRadius.circular(AppTheme.radiusMd - 1.5),
                                                child: Image.file(_selectedImage!, fit: BoxFit.cover),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: AppTheme.space4),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'CANDIDATE PHOTO',
                                            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navy),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _selectedImage == null
                                                ? 'Tap square to take/upload candidate photograph'
                                                : 'Tap square to replace image',
                                            style: const TextStyle(fontSize: 12, color: AppTheme.blue300),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.space6),
                        
                        CustomButton(
                          text: 'Submit & Generate Deposit Slip',
                          isLoading: isLoading,
                          onPressed: () => _submitForm(cubit),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
