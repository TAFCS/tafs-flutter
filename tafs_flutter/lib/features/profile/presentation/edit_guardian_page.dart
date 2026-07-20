import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/domain/entities/parent.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_state.dart';
import '../../auth/presentation/bloc/auth_event.dart';
import 'bloc/profile_bloc.dart';
import 'bloc/profile_event.dart';
import 'bloc/profile_state.dart';

class EditGuardianPage extends StatefulWidget {
  final FamilyGuardian guardian;

  const EditGuardianPage({super.key, required this.guardian});

  @override
  State<EditGuardianPage> createState() => _EditGuardianPageState();
}

String _formatPakistaniNumber(String? raw) {
  final trimmed = (raw ?? '').trim();
  if (trimmed.isEmpty) return '+92';

  String formatted = trimmed;
  if (!formatted.startsWith('+92')) {
    String digits = formatted.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('92')) {
      digits = digits.substring(2);
    } else if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    formatted = '+92$digits';
  }
  if (formatted.length > 13) {
    formatted = formatted.substring(0, 13);
  }
  return formatted;
}

String? _validatePakistaniNumber(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty || text == '+92') return null;
  if (!RegExp(r'^\+92\d{10}$').hasMatch(text)) {
    return 'Enter exactly 10 digits after +92';
  }
  return null;
}

class _EditGuardianPageState extends State<EditGuardianPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final Map<String, GlobalKey<FormFieldState<String>>> _fieldKeys = {};
  final List<String> _fieldOrder = [];
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _whatsappController;
  late TextEditingController _emailController;
  late TextEditingController _cnicController;
  late TextEditingController _occupationController;
  late TextEditingController _jobPositionController;
  late TextEditingController _organizationController;
  late TextEditingController _educationController;
  late TextEditingController _addressController;
  late TextEditingController _houseApptController;
  late TextEditingController _areaBlockController;
  late TextEditingController _postalCodeController;
  File? _pickedImageFile;
  File? _pickedCnicImageFile;
  final ImagePicker _imagePicker = ImagePicker();

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

  Future<void> _pickCnicImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
      );
      if (pickedFile != null) {
        setState(() {
          _pickedCnicImageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick CNIC image.')),
      );
    }
  }

  void _showCnicSourcePicker() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppTheme.blue300),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  _pickCnicImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.blue300),
                title: const Text('Take Photo (Camera)', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  _pickCnicImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(_shakeController);
    _nameController = TextEditingController(text: widget.guardian.name);
    _phoneController = TextEditingController(text: _formatPakistaniNumber(widget.guardian.phone));
    _whatsappController = TextEditingController(text: _formatPakistaniNumber(widget.guardian.whatsapp));
    _emailController = TextEditingController(text: widget.guardian.email);
    _cnicController = TextEditingController(text: widget.guardian.cnic);
    _occupationController = TextEditingController(text: widget.guardian.occupation);
    _jobPositionController = TextEditingController(text: widget.guardian.jobPosition);
    _organizationController = TextEditingController(text: widget.guardian.organization);
    _educationController = TextEditingController(text: widget.guardian.education);
    _addressController = TextEditingController(text: widget.guardian.address);
    final initialHouseAppt = widget.guardian.houseApptName?.isNotEmpty == true
        ? widget.guardian.houseApptName
        : widget.guardian.address;
    _houseApptController = TextEditingController(text: initialHouseAppt);
    _areaBlockController = TextEditingController(text: widget.guardian.areaBlock);
    _postalCodeController = TextEditingController(text: widget.guardian.postalCode);
    _cnicController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _cnicController.dispose();
    _occupationController.dispose();
    _jobPositionController.dispose();
    _organizationController.dispose();
    _educationController.dispose();
    _addressController.dispose();
    _houseApptController.dispose();
    _areaBlockController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  GlobalKey<FormFieldState<String>>? _keyFor(String? apiKey) {
    if (apiKey == null) return null;
    return _fieldKeys.putIfAbsent(apiKey, () {
      _fieldOrder.add(apiKey);
      return GlobalKey<FormFieldState<String>>();
    });
  }

  void _scrollToFirstError() {
    HapticFeedback.mediumImpact();
    _shakeController.forward(from: 0);

    for (final apiKey in _fieldOrder) {
      final fieldState = _fieldKeys[apiKey]?.currentState;
      if (fieldState != null && fieldState.hasError) {
        Scrollable.ensureVisible(
          fieldState.context,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.2,
        );
        return;
      }
    }
  }

  void _submitRequest() {
    if (!_formKey.currentState!.validate()) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToFirstError());
      return;
    }

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

    addIfChanged('full_name', widget.guardian.name, _nameController.text);
    addIfChanged('primary_phone', widget.guardian.phone, _phoneController.text);
    addIfChanged('whatsapp_number', widget.guardian.whatsapp, _whatsappController.text);
    addIfChanged('email_address', widget.guardian.email, _emailController.text);
    addIfChanged('cnic', widget.guardian.cnic, _cnicController.text);
    addIfChanged('occupation', widget.guardian.occupation, _occupationController.text);
    addIfChanged('job_position', widget.guardian.jobPosition, _jobPositionController.text);
    addIfChanged('organization', widget.guardian.organization, _organizationController.text);
    addIfChanged('education_level', widget.guardian.education, _educationController.text);
    addIfChanged('house_appt_name', widget.guardian.houseApptName, _houseApptController.text);
    addIfChanged('area_block', widget.guardian.areaBlock, _areaBlockController.text);
    addIfChanged('postal_code', widget.guardian.postalCode, _postalCodeController.text);

    final cnicChanged = _cnicController.text.trim() != (widget.guardian.cnic ?? '').trim();
    if (cnicChanged && _pickedCnicImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a photo of your CNIC card to request a CNIC change.'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    if (changes.isEmpty && _pickedImageFile == null && _pickedCnicImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No changes detected.')),
      );
      return;
    }

    context.read<ProfileBloc>().add(GuardianChangeSubmitted(
      guardianId: widget.guardian.id,
      familyId: authState.parent.id,
      changes: changes,
      localPhotoPath: _pickedImageFile?.path,
      localCnicPhotoPath: _pickedCnicImageFile?.path,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileSuccess) {
          context.read<AuthBloc>().add(AuthRefreshRequested());
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
                                    : (widget.guardian.photographUrl != null
                                        ? NetworkImage(widget.guardian.photographUrl!) as ImageProvider
                                        : null),
                                child: _pickedImageFile == null && widget.guardian.photographUrl == null
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
                    _buildTextField(_nameController, 'Full Name', Icons.person_rounded, apiKey: 'full_name'),
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
                    _buildTextField(
                      _phoneController,
                      'Primary Phone',
                      Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                        PakistaniPhoneFormatter(),
                      ],
                      validator: _validatePakistaniNumber,
                      apiKey: 'primary_phone',
                    ),
                    _buildTextField(
                      _whatsappController,
                      'WhatsApp Number',
                      Icons.chat_bubble_rounded,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                        PakistaniPhoneFormatter(),
                      ],
                      validator: _validatePakistaniNumber,
                      apiKey: 'whatsapp_number',
                    ),
                    _buildTextField(_emailController, 'Email Address', Icons.email_rounded, apiKey: 'email_address'),
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
                    _buildTextField(_occupationController, 'Occupation', Icons.work_rounded, apiKey: 'occupation'),
                    _buildTextField(_jobPositionController, 'Job Position', Icons.person_pin_rounded, apiKey: 'job_position'),
                    _buildTextField(_organizationController, 'Organization', Icons.business_rounded, apiKey: 'organization'),
                    _buildTextField(_educationController, 'Education Level', Icons.school_rounded, apiKey: 'education_level'),
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
                    _buildTextField(
                      _cnicController,
                      'CNIC Number',
                      Icons.badge_rounded,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        CnicFormatter(),
                      ],
                      apiKey: 'cnic',
                    ),
                    if (_cnicController.text.trim() != (widget.guardian.cnic ?? '').trim()) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppTheme.space4),
                        child: InkWell(
                          onTap: _showCnicSourcePicker,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.white,
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              border: Border.all(
                                color: _pickedCnicImageFile != null ? AppTheme.blue100 : AppTheme.danger.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _pickedCnicImageFile != null ? Icons.check_circle_rounded : Icons.add_photo_alternate_rounded,
                                  color: _pickedCnicImageFile != null ? AppTheme.success : AppTheme.danger,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _pickedCnicImageFile != null ? 'CNIC Card Image Selected' : 'Upload CNIC Card Photo *',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: _pickedCnicImageFile != null ? AppTheme.navy : AppTheme.danger,
                                        ),
                                      ),
                                      if (_pickedCnicImageFile == null) ...[
                                        const SizedBox(height: 2),
                                        const Text(
                                          'A photo of the CNIC is required for CNIC changes',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textMuted,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (_pickedCnicImageFile != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                    child: Image.file(
                                      _pickedCnicImageFile!,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                else
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.blue200),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    _buildTextField(_houseApptController, 'House / Apartment Name and No.', Icons.home_rounded, apiKey: 'house_appt_name'),
                    _buildTextField(_areaBlockController, 'Area and Block #', Icons.grid_view_rounded, apiKey: 'area_block'),
                    _buildTextField(_postalCodeController, 'Postal Code', Icons.markunread_mailbox_rounded, apiKey: 'postal_code'),
                    const SizedBox(height: AppTheme.space8),
                    AnimatedBuilder(
                      animation: _shakeAnimation,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(_shakeAnimation.value, 0),
                        child: child,
                      ),
                      child: SizedBox(
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
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    String? apiKey,
  }) {
    final isPending = apiKey != null && widget.guardian.pendingFields.contains(apiKey);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            key: validator != null ? _keyFor(apiKey) : null,
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            validator: validator,
            readOnly: isPending,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isPending ? AppTheme.blue300 : AppTheme.navy,
            ),
            decoration: InputDecoration(
              labelText: label,
              alignLabelWithHint: maxLines > 1,
              prefixIcon: Icon(icon, color: AppTheme.blue200, size: 20),
              suffixIcon: isPending ? const Icon(Icons.lock_rounded, color: AppTheme.blue200, size: 16) : null,
              filled: true,
              fillColor: isPending ? AppTheme.blue100.withValues(alpha: 0.15) : AppTheme.white,
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
                borderSide: BorderSide(color: isPending ? AppTheme.blue100 : AppTheme.navy, width: isPending ? 1.0 : 1.5),
              ),
              labelStyle: const TextStyle(color: AppTheme.blue300, fontSize: 13, fontWeight: FontWeight.w500),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
          if (isPending) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Row(
                children: [
                  const Icon(Icons.pending_actions_rounded, color: AppTheme.blue300, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Pending admin approval',
                    style: TextStyle(
                      color: AppTheme.blue300.withValues(alpha: 0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PakistaniPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text;

    // Do not allow deleting the +92 prefix
    if (!text.startsWith('+92')) {
      if (text.startsWith('+9') || text.startsWith('+') || text.startsWith('9') || text.startsWith('2')) {
        text = '+92';
      } else {
        String digits = text.replaceAll(RegExp(r'\D'), '');
        if (digits.startsWith('92')) {
          digits = digits.substring(2);
        } else if (digits.startsWith('0')) {
          digits = digits.substring(1);
        }
        text = '+92$digits';
      }
    }

    // Enforce max 10 digits after +92 (total 13 characters)
    if (text.length > 13) {
      text = text.substring(0, 13);
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class CnicFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // If backspacing a dash, delete the preceding character too
    String newText = newValue.text;
    if (oldValue.text.length - newText.length == 1) {
      final oldSelectionEnd = oldValue.selection.end;
      if (oldSelectionEnd > 0 && oldValue.text[oldSelectionEnd - 1] == '-') {
        // Find position of deleted dash in newText and remove character before it
        final deletedDashIndex = oldSelectionEnd - 2;
        if (deletedDashIndex >= 0 && deletedDashIndex < newText.length) {
          newText = newText.substring(0, deletedDashIndex) + newText.substring(deletedDashIndex + 1);
        }
      }
    }

    final raw = newText.replaceAll(RegExp(r'\D'), '');
    
    String digits = raw;
    if (digits.length > 13) {
      digits = digits.substring(0, 13);
    }
    
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 5 || i == 12) {
        buffer.write('-');
      }
      buffer.write(digits[i]);
    }
    
    final formatted = buffer.toString();
    
    // Position cursor at the correct position
    int rawCursorPos = 0;
    for (int i = 0; i < newValue.selection.end && i < newValue.text.length; i++) {
      if (newValue.text[i] != '-') {
        rawCursorPos++;
      }
    }
    
    // Adjust cursor position based on backspacing dash behavior
    if (oldValue.text.length - newValue.text.length == 1) {
      final oldSelectionEnd = oldValue.selection.end;
      if (oldSelectionEnd > 0 && oldValue.text[oldSelectionEnd - 1] == '-') {
        rawCursorPos = (rawCursorPos > 0) ? rawCursorPos - 1 : 0;
      }
    }
    
    int formattedCursorPos = 0;
    int rawCount = 0;
    while (rawCount < rawCursorPos && formattedCursorPos < formatted.length) {
      if (formatted[formattedCursorPos] != '-') {
        rawCount++;
      }
      formattedCursorPos++;
    }
    
    if (formattedCursorPos < formatted.length && formatted[formattedCursorPos] == '-') {
      formattedCursorPos++;
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formattedCursorPos),
    );
  }
}
