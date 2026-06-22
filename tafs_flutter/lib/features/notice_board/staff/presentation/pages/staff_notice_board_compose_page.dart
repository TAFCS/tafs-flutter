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
  final List<int> _campusIds = [];
  final List<int> _classIds = [];
  final List<int> _sectionIds = [];
  final List<UploadedNoticeMedia> _uploadedMedia = [];
  bool _isPinned = false;
  DateTime? _expiresAt;

  bool _bodyEmpty = true;

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
      mediaUrls: _uploadedMedia.map((m) => m.url).toList(),
      mediaTypes: _uploadedMedia.map((m) => m.type).toList(),
      isPinned: _isPinned,
      expiresAt: _expiresAt,
    );
    if (post != null && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
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
                    _sectionLabel('Options'),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Pin post'),
                      value: _isPinned,
                      onChanged: (v) => setState(() => _isPinned = v),
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
                      onPressed: state.actionLoading || _bodyEmpty ? null : _submit,
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
