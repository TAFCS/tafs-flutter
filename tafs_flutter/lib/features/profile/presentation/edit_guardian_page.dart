import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_cached_network_image.dart';
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

/// Splits a stored phone into dialling code + national digits.
/// Handles legacy rows where the country code was embedded in the number field.
/// Strips the trunk prefix that is not part of the national number.
/// Legacy rows arrive in several shapes — `+923001234567`, `03001234567`,
/// `+9203001234567` and plain `3001234567` — and all must land in the field as
/// the same 10 digits, otherwise the +92 length rule rejects a number the
/// parent never mistyped.
String _stripTrunkPrefix(String digits, String code) {
  if (code.trim() != '+92') return digits;
  var d = digits;
  while (d.startsWith('0') && d.length > 1) {
    d = d.substring(1);
  }
  return d;
}

({String code, String national}) _splitPhone(String? raw, String? storedCode) {
  final fallbackCode = (storedCode ?? '+92').trim().isEmpty ? '+92' : (storedCode ?? '+92').trim();
  final trimmed = (raw ?? '').trim();
  if (trimmed.isEmpty || trimmed.toUpperCase() == 'N/A') {
    return (code: fallbackCode, national: '');
  }

  if (trimmed.startsWith('+')) {
    final match = RegExp(r'^(\+\d{1,4})(.*)$').firstMatch(trimmed);
    if (match != null) {
      final code = match.group(1)!;
      final rest = (match.group(2) ?? '').replaceAll(RegExp(r'\D'), '');
      // Prefer stored code when present and number doesn't embed a different one.
      if (storedCode != null &&
          storedCode.trim().isNotEmpty &&
          !trimmed.startsWith(storedCode.trim())) {
        // Number embeds a different dialling code — trust the number's prefix.
        return (code: code, national: _stripTrunkPrefix(rest, code));
      }
      if (storedCode != null &&
          storedCode.trim().isNotEmpty &&
          trimmed.startsWith(storedCode.trim())) {
        final resolved = storedCode.trim();
        final national = trimmed.substring(resolved.length).replaceAll(RegExp(r'\D'), '');
        return (code: resolved, national: _stripTrunkPrefix(national, resolved));
      }
      return (code: code, national: _stripTrunkPrefix(rest, code));
    }
  }

  final digits = trimmed.replaceAll(RegExp(r'\D'), '');
  return (code: fallbackCode, national: _stripTrunkPrefix(digits, fallbackCode));
}

/// Digits required after a given dialling code. Pakistani numbers are always a
/// 10-digit national number (e.g. +92 3001234567 / +92 2134567890) — the
/// leading trunk `0` is not part of it. Other countries vary too much to pin
/// down, so they keep a permissive range.
int? _requiredNationalLength(String countryCode) {
  return countryCode.trim() == '+92' ? 10 : null;
}

String? _validateNationalNumber(String? value, String countryCode) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return null;
  final digits = text.replaceAll(RegExp(r'\D'), '');

  final exact = _requiredNationalLength(countryCode);
  if (exact != null) {
    // Typed with the trunk prefix (03001234567) — tell them precisely what's
    // wrong instead of a bare length error, since this is the common mistake.
    if (digits.startsWith('0')) {
      return 'Drop the leading 0 — enter $exact digits (e.g. 3001234567)';
    }
    if (digits.length != exact) {
      return 'Enter exactly $exact digits after ${countryCode.trim()}';
    }
    return null;
  }

  if (digits.length < 6 || digits.length > 15) {
    return 'Enter 6–15 digits';
  }
  return null;
}

String? _validateCountryCode(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return 'Required';
  if (!RegExp(r'^\+\d{1,4}$').hasMatch(text)) {
    return 'Use + and digits (e.g. +92)';
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
  late TextEditingController _phoneCountryCodeController;
  late TextEditingController _phoneController;
  late TextEditingController _whatsappCountryCodeController;
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
    final phoneParts = _splitPhone(widget.guardian.phone, widget.guardian.phoneCountryCode);
    final whatsappParts = _splitPhone(widget.guardian.whatsapp, widget.guardian.whatsappCountryCode);
    _phoneCountryCodeController = TextEditingController(text: phoneParts.code);
    _phoneController = TextEditingController(text: phoneParts.national);
    _whatsappCountryCodeController = TextEditingController(text: whatsappParts.code);
    _whatsappController = TextEditingController(text: whatsappParts.national);
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
    _phoneCountryCodeController.dispose();
    _phoneController.dispose();
    _whatsappCountryCodeController.dispose();
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
      if (normalizedCurrent.isEmpty && normalizedNext.isEmpty) return;
      changes[key] = normalizedNext;
    }

    final initialPhone = _splitPhone(widget.guardian.phone, widget.guardian.phoneCountryCode);
    final initialWhatsapp = _splitPhone(widget.guardian.whatsapp, widget.guardian.whatsappCountryCode);

    addIfChanged('full_name', widget.guardian.name, _nameController.text);
    addIfChanged('primary_phone', initialPhone.national, _phoneController.text);
    addIfChanged(
      'primary_phone_country_code',
      initialPhone.code,
      _phoneCountryCodeController.text,
    );
    addIfChanged('whatsapp_number', initialWhatsapp.national, _whatsappController.text);
    addIfChanged(
      'whatsapp_country_code',
      initialWhatsapp.code,
      _whatsappCountryCodeController.text,
    );
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
                                    : appCachedNetworkImageProvider(widget.guardian.photographUrl),
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
                    _buildPhoneField(
                      countryCodeController: _phoneCountryCodeController,
                      numberController: _phoneController,
                      label: 'Primary Phone',
                      icon: Icons.phone_rounded,
                      countryCodeApiKey: 'primary_phone_country_code',
                      numberApiKey: 'primary_phone',
                    ),
                    _buildPhoneField(
                      countryCodeController: _whatsappCountryCodeController,
                      numberController: _whatsappController,
                      label: 'WhatsApp Number',
                      icon: Icons.chat_bubble_rounded,
                      countryCodeApiKey: 'whatsapp_country_code',
                      numberApiKey: 'whatsapp_number',
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

  Widget _buildPhoneField({
    required TextEditingController countryCodeController,
    required TextEditingController numberController,
    required String label,
    required IconData icon,
    required String countryCodeApiKey,
    required String numberApiKey,
  }) {
    final isPending = widget.guardian.pendingFields.contains(numberApiKey) ||
        widget.guardian.pendingFields.contains(countryCodeApiKey);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 88,
                child: TextFormField(
                  key: _keyFor(countryCodeApiKey),
                  controller: countryCodeController,
                  keyboardType: TextInputType.phone,
                  readOnly: isPending,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                    LengthLimitingTextInputFormatter(5),
                  ],
                  validator: _validateCountryCode,
                  // Changing the code changes the number field's rules (digit cap,
                  // required length, hint), so rebuild and re-check it immediately
                  // rather than leaving a stale error from the previous country.
                  onChanged: (_) {
                    setState(() {});
                    _keyFor(numberApiKey)?.currentState?.validate();
                  },
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isPending ? AppTheme.blue300 : AppTheme.navy,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Code',
                    prefixIcon: Icon(icon, color: AppTheme.blue200, size: 18),
                    prefixIconConstraints: const BoxConstraints(minWidth: 36),
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
                      borderSide: BorderSide(
                        color: isPending ? AppTheme.blue100 : AppTheme.navy,
                        width: isPending ? 1.0 : 1.5,
                      ),
                    ),
                    labelStyle: const TextStyle(
                      color: AppTheme.blue300,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  key: _keyFor(numberApiKey),
                  controller: numberController,
                  keyboardType: TextInputType.phone,
                  readOnly: isPending,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    // Cap at the exact length for codes we know (+92 → 10) so the
                    // field physically cannot hold an invalid number; fall back to
                    // a permissive cap for everywhere else.
                    LengthLimitingTextInputFormatter(
                      _requiredNationalLength(countryCodeController.text) ?? 15,
                    ),
                  ],
                  validator: (v) =>
                      _validateNationalNumber(v, countryCodeController.text),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isPending ? AppTheme.blue300 : AppTheme.navy,
                  ),
                  decoration: InputDecoration(
                    labelText: label,
                    // Makes the +92 rule discoverable before they hit Save.
                    hintText: countryCodeController.text.trim() == '+92'
                        ? '3001234567'
                        : null,
                    suffixIcon: isPending
                        ? const Icon(Icons.lock_rounded, color: AppTheme.blue200, size: 16)
                        : null,
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
                      borderSide: BorderSide(
                        color: isPending ? AppTheme.blue100 : AppTheme.navy,
                        width: isPending ? 1.0 : 1.5,
                      ),
                    ),
                    labelStyle: const TextStyle(
                      color: AppTheme.blue300,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
            ],
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
