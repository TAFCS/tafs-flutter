import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../domain/entities/staff_notice_post.dart';
import '../bloc/staff_notice_board_cubit.dart';

class StaffNoticeBoardComposePage extends StatefulWidget {
  const StaffNoticeBoardComposePage({super.key});

  @override
  State<StaffNoticeBoardComposePage> createState() =>
      _StaffNoticeBoardComposePageState();
}

class _StaffNoticeBoardComposePageState
    extends State<StaffNoticeBoardComposePage> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _studentSearchController = TextEditingController();
  final _ccPasteController = TextEditingController();
  final List<int> _campusIds = [];
  final List<int> _classIds = [];
  final List<int> _sectionIds = [];
  final List<UploadedNoticeMedia> _uploadedMedia = [];
  bool _isPinned = false;
  bool _notificationOnly = false;
  DateTime? _expiresAt;

  bool _bodyEmpty = true;
  bool _studentTargetOpen = false;
  bool _searchingStudents = false;
  List<Map<String, dynamic>> _studentSearchResults = [];
  final List<Map<String, dynamic>> _selectedStudents = [];
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _bodyController.addListener(() {
      final empty = _bodyController.text.trim().isEmpty;
      if (empty != _bodyEmpty) setState(() => _bodyEmpty = empty);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _studentSearchController.dispose();
    _ccPasteController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _toggleId(List<int> list, int id, VoidCallback onChanged) {
    setState(() {
      if (list.contains(id)) {
        list.remove(id);
      } else {
        list.add(id);
      }
      onChanged();
    });
  }

  List<CampusClassOption> _availableClasses(List<CampusScope> campuses) {
    final filtered = campuses
        .where((c) => _campusIds.isEmpty || _campusIds.contains(c.id));
    final map = <int, CampusClassOption>{};
    for (final campus in filtered) {
      for (final cls in campus.classes) {
        map.putIfAbsent(cls.id, () => cls);
      }
    }
    return map.values.toList();
  }

  List<CampusSectionOption> _availableSections(List<CampusScope> campuses) {
    final filtered = campuses
        .where((c) => _campusIds.isEmpty || _campusIds.contains(c.id));
    final map = <int, CampusSectionOption>{};
    for (final campus in filtered) {
      for (final cls in campus.classes) {
        if (_classIds.isNotEmpty && !_classIds.contains(cls.id)) continue;
        for (final section in cls.sections) {
          map.putIfAbsent(section.id, () => section);
        }
      }
    }
    return map.values.toList();
  }

  String _composeScopeLabel(List<CampusScope> campuses) {
    if (_campusIds.isEmpty && _classIds.isEmpty && _sectionIds.isEmpty) {
      return 'All families (school-wide)';
    }
    final parts = <String>[];
    if (_campusIds.isNotEmpty) {
      final names = campuses
          .where((c) => _campusIds.contains(c.id))
          .map((c) => c.name)
          .toList();
      if (names.isNotEmpty) parts.add(names.join(', '));
    }
    return 'Families in: ${parts.isNotEmpty ? parts.join(' · ') : 'selected scope'}';
  }

  void _onStudentSearch(String query) {
    _searchDebounce?.cancel();
    if (query.length < 2) {
      setState(() => _studentSearchResults = []);
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _searchingStudents = true);
      final cubit = context.read<StaffNoticeBoardCubit>();
      final results = await cubit.searchStudents(query);
      if (mounted) {
        setState(() {
          _studentSearchResults = results;
          _searchingStudents = false;
        });
      }
    });
  }

  void _addStudent(Map<String, dynamic> student) {
    final cc = student['cc'] as int;
    if (_selectedStudents.any((s) => s['cc'] == cc)) return;
    setState(() {
      _selectedStudents.add(student);
      _studentSearchController.clear();
      _studentSearchResults = [];
    });
  }

  void _removeStudent(int cc) {
    setState(() {
      _selectedStudents.removeWhere((s) => s['cc'] == cc);
    });
  }

  Future<void> _parseCcPaste() async {
    final raw = _ccPasteController.text
        .split(RegExp(r'[,\n\r]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final ccs = raw
        .map((s) => int.tryParse(s))
        .where((n) => n != null && n > 0)
        .cast<int>()
        .where((cc) => !_selectedStudents.any((s) => s['cc'] == cc))
        .toList();
    if (ccs.isEmpty) return;
    final cubit = context.read<StaffNoticeBoardCubit>();
    for (final cc in ccs) {
      final results = await cubit.searchStudents(cc.toString());
      final match = results.firstWhere(
        (s) => s['cc'] == cc,
        orElse: () => {'cc': cc, 'full_name': 'CC $cc', 'gr_number': ''},
      );
      if (mounted) {
        setState(() => _selectedStudents.add(match));
      }
    }
    if (mounted) _ccPasteController.clear();
  }

  Future<void> _pickFiles() async {
    final cubit = context.read<StaffNoticeBoardCubit>();
    final picker = ImagePicker();
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo library'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Files (PDF, video)'),
              onTap: () => Navigator.pop(ctx, 'files'),
            ),
          ],
        ),
      ),
    );

    if (!mounted || choice == null) return;

    if (choice == 'gallery') {
      final images = await picker.pickMultiImage();
      for (final image in images) {
        final media = await cubit.uploadMedia(image, image.name);
        if (media != null && mounted) {
          setState(() => _uploadedMedia.add(media));
        }
      }
      return;
    }

    if (choice == 'camera') {
      final image = await picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        final media = await cubit.uploadMedia(image, image.name);
        if (media != null && mounted) {
          setState(() => _uploadedMedia.add(media));
        }
      }
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'mp4', 'mov', 'jpg', 'jpeg', 'png'],
    );
    if (result == null) return;
    for (final file in result.files) {
      if (file.path == null && file.bytes == null) continue;
      final xFile = file.path != null
          ? XFile(file.path!, name: file.name)
          : XFile.fromData(file.bytes!, name: file.name);
      final media = await cubit.uploadMedia(xFile, file.name);
      if (media != null && mounted) {
        setState(() => _uploadedMedia.add(media));
      }
    }
  }

  Future<void> _pickExpiry() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_expiresAt ?? DateTime.now()),
    );
    if (time == null || !mounted) return;
    setState(() {
      _expiresAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    final body = _bodyController.text.trim();
    if (body.isEmpty) return;

    final cubit = context.read<StaffNoticeBoardCubit>();
    final post = await cubit.createPost(
      title: _titleController.text.trim(),
      body: body,
      campusIds: List.from(_campusIds),
      classIds: List.from(_classIds),
      sectionIds: List.from(_sectionIds),
      studentCcs: _selectedStudents.map((s) => s['cc'] as int).toList(),
      mediaUrls: _uploadedMedia.map((m) => m.url).toList(),
      mediaTypes: _uploadedMedia.map((m) => m.type).toList(),
      isPinned: _isPinned,
      notificationOnly: _notificationOnly,
      expiresAt: _expiresAt,
    );
    if (post != null && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface2,
      appBar: AppBar(
        title: const Text('New Post'),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.navy,
        elevation: 0,
      ),
      body: BlocBuilder<StaffNoticeBoardCubit, StaffNoticeBoardState>(
        builder: (context, state) {
          final classes = _availableClasses(state.campuses);
          final sections = _availableSections(state.campuses);

          return Column(
            children: [
              if (state.actionError != null)
                Container(
                  width: double.infinity,
                  color: Colors.red.shade50,
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    state.actionError!,
                    style: TextStyle(color: Colors.red.shade800, fontSize: 12),
                  ),
                ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title (optional)',
                        filled: true,
                        fillColor: AppTheme.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _bodyController,
                      decoration: const InputDecoration(
                        labelText: 'Notice body',
                        hintText: 'Write your notice here…',
                        filled: true,
                        fillColor: AppTheme.white,
                      ),
                      maxLines: 5,
                    ),
                    const SizedBox(height: 20),
                    _sectionLabel('Attachments'),
                    OutlinedButton.icon(
                      onPressed: state.uploading ? null : _pickFiles,
                      icon: state.uploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_file),
                      label: const Text('Add images, videos, or PDFs'),
                    ),
                    if (_uploadedMedia.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _uploadedMedia.asMap().entries.map((entry) {
                          final media = entry.value;
                          return Chip(
                            label: Text(
                              media.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onDeleted: () =>
                                setState(() => _uploadedMedia.removeAt(entry.key)),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 20),
                    _sectionLabel('Scope'),
                    _chipGroup(
                      label: 'Campus',
                      items: state.campuses
                          .map((c) => _ChipItem(c.id, c.name))
                          .toList(),
                      selected: _campusIds,
                      onToggle: (id) => _toggleId(_campusIds, id, () {
                        _classIds.clear();
                        _sectionIds.clear();
                      }),
                    ),
                    if (classes.isNotEmpty)
                      _chipGroup(
                        label: 'Class',
                        items: classes
                            .map((c) => _ChipItem(c.id, c.name))
                            .toList(),
                        selected: _classIds,
                        onToggle: (id) => _toggleId(_classIds, id, () {
                          _sectionIds.clear();
                        }),
                      ),
                    if (sections.isNotEmpty)
                      _chipGroup(
                        label: 'Section',
                        items: sections
                            .map((s) => _ChipItem(s.id, s.name))
                            .toList(),
                        selected: _sectionIds,
                        onToggle: (id) => _toggleId(_sectionIds, id, () {}),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Will be visible to: ${_composeScopeLabel(state.campuses)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.navy,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    InkWell(
                      onTap: () => setState(() => _studentTargetOpen = !_studentTargetOpen),
                      child: Row(
                        children: [
                          const Icon(Icons.person_add_alt_1, size: 16, color: AppTheme.blue300),
                          const SizedBox(width: 6),
                          const Text(
                            'TARGET SPECIFIC STUDENTS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.blue300,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (_selectedStudents.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.navy.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_selectedStudents.length}',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.navy),
                              ),
                            ),
                          ],
                          const Spacer(),
                          Icon(
                            _studentTargetOpen ? Icons.expand_less : Icons.expand_more,
                            size: 20,
                            color: AppTheme.blue300,
                          ),
                        ],
                      ),
                    ),
                    if (_studentTargetOpen) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _studentSearchController,
                        onChanged: _onStudentSearch,
                        decoration: InputDecoration(
                          hintText: 'Search by name or GR number…',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchingStudents
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : null,
                          filled: true,
                          fillColor: AppTheme.white,
                          isDense: true,
                        ),
                      ),
                      if (_studentSearchResults.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _studentSearchResults.length,
                            itemBuilder: (context, index) {
                              final s = _studentSearchResults[index];
                              final cc = s['cc'] as int;
                              final alreadyAdded = _selectedStudents.any((x) => x['cc'] == cc);
                              return ListTile(
                                dense: true,
                                title: Text(
                                  s['full_name']?.toString() ?? 'Unknown',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(
                                  s['gr_number']?.toString().isNotEmpty == true ? 'GR ${s['gr_number']}' : 'CC $cc',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                trailing: alreadyAdded
                                    ? const Icon(Icons.check, color: AppTheme.success, size: 18)
                                    : null,
                                onTap: alreadyAdded ? null : () => _addStudent(s),
                              );
                            },
                          ),
                        ),
                      if (_selectedStudents.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _selectedStudents.map((s) {
                            final cc = s['cc'] as int;
                            final name = s['full_name']?.toString() ?? 'CC $cc';
                            final gr = s['gr_number']?.toString() ?? '';
                            return Chip(
                              label: Text(
                                gr.isNotEmpty ? '$name ($gr)' : name,
                                style: const TextStyle(fontSize: 12),
                              ),
                              onDeleted: () => _removeStudent(cc),
                              deleteIconColor: Colors.red.shade300,
                              backgroundColor: AppTheme.navy.withValues(alpha: 0.08),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _ccPasteController,
                              decoration: const InputDecoration(
                                hintText: 'Paste comma-separated CCs',
                                filled: true,
                                fillColor: AppTheme.white,
                                isDense: true,
                              ),
                              maxLines: 2,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: _parseCcPaste,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.navy,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            child: const Text('Parse', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                    _sectionLabel('Options'),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Pin post'),
                      value: _isPinned,
                      onChanged: (v) => setState(() => _isPinned = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Notification only'),
                      subtitle: const Text('Don\'t show on notice board',
                          style: TextStyle(fontSize: 12)),
                      value: _notificationOnly,
                      onChanged: (v) => setState(() => _notificationOnly = v),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event, color: AppTheme.blue300),
                      title: const Text('Expires'),
                      subtitle: Text(
                        _expiresAt != null
                            ? _expiresAt!.toLocal().toString().substring(0, 16)
                            : 'No expiry',
                      ),
                      trailing: _expiresAt != null
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() => _expiresAt = null),
                            )
                          : null,
                      onTap: _pickExpiry,
                    ),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: state.actionLoading ||
                              state.uploading ||
                              _bodyEmpty
                          ? null
                          : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.navy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: state.actionLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Post to Notice Board',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppTheme.blue300,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _chipGroup({
    required String label,
    required List<_ChipItem> items,
    required List<int> selected,
    required void Function(int id) onToggle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.blue300)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              final isSelected = selected.contains(item.id);
              return FilterChip(
                label: Text(item.label),
                selected: isSelected,
                onSelected: (_) => onToggle(item.id),
                selectedColor: AppTheme.navy.withValues(alpha: 0.15),
                checkmarkColor: AppTheme.navy,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ChipItem {
  final int id;
  final String label;
  const _ChipItem(this.id, this.label);
}
