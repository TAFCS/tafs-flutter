import 'package:flutter/material.dart';

import '../data/country_dial_codes.dart';
import '../theme/app_theme.dart';

/// A tappable field that looks like the app's other inputs but opens a
/// searchable country list instead of a keyboard. Writes the chosen dial
/// code (e.g. `+92`) into [controller] so it drops into existing
/// validators/submit logic unchanged.
class CountryCodePickerField extends StatelessWidget {
  final TextEditingController controller;
  final GlobalKey<FormFieldState<String>>? fieldKey;
  final String? Function(String?)? validator;
  final bool readOnly;
  final ValueChanged<CountryDialCode>? onSelected;
  final Color? fillColor;
  final Color? textColor;

  const CountryCodePickerField({
    super.key,
    required this.controller,
    this.fieldKey,
    this.validator,
    this.readOnly = false,
    this.onSelected,
    this.fillColor,
    this.textColor,
  });

  CountryDialCode? get _selected {
    final code = controller.text.trim();
    for (final c in kCountryDialCodes) {
      if (c.dialCode == code) return c;
    }
    return null;
  }

  Future<void> _openPicker(BuildContext context) async {
    if (readOnly) return;
    final chosen = await showModalBottomSheet<CountryDialCode>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
      ),
      builder: (context) => const _CountryCodeSheet(),
    );
    if (chosen != null) {
      controller.text = chosen.dialCode;
      onSelected?.call(chosen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return FormField<String>(
      key: fieldKey,
      initialValue: controller.text,
      validator: validator,
      builder: (state) {
        // Keep the FormField's error text in sync as the controller changes
        // externally (e.g. via _openPicker) without rebuilding the whole tree.
        if (state.value != controller.text) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            state.didChange(controller.text);
          });
        }
        return InkWell(
          onTap: () => _openPicker(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Code',
              errorText: state.errorText,
              filled: true,
              fillColor: fillColor ?? AppTheme.white,
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
              labelStyle: const TextStyle(
                color: AppTheme.blue300,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected != null) ...[
                  Text(selected.flagEmoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    controller.text.isEmpty ? '+--' : controller.text,
                    overflow: TextOverflow.clip,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textColor ?? AppTheme.navy,
                    ),
                  ),
                ),
                if (!readOnly) ...[
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.blue200, size: 18),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CountryCodeSheet extends StatefulWidget {
  const _CountryCodeSheet();

  @override
  State<_CountryCodeSheet> createState() => _CountryCodeSheetState();
}

class _CountryCodeSheetState extends State<_CountryCodeSheet> {
  final _searchController = TextEditingController();
  late List<CountryDialCode> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = kCountryDialCodes;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filtered = kCountryDialCodes;
        return;
      }
      _filtered = kCountryDialCodes.where((c) {
        return c.name.toLowerCase().contains(query) ||
            c.dialCode.contains(query) ||
            c.iso2.toLowerCase() == query;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              children: [
                const SizedBox(height: AppTheme.space3),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.blue100,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.space5,
                    AppTheme.space4,
                    AppTheme.space5,
                    AppTheme.space3,
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: false,
                    decoration: InputDecoration(
                      hintText: 'Search country or code',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.blue200),
                      filled: true,
                      fillColor: AppTheme.background,
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
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                Expanded(
                  child: _filtered.isEmpty
                      ? const Center(
                          child: Text(
                            'No matching country',
                            style: TextStyle(color: AppTheme.textMuted),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.blue100),
                          itemBuilder: (context, index) {
                            final country = _filtered[index];
                            return ListTile(
                              leading: Text(country.flagEmoji, style: const TextStyle(fontSize: 22)),
                              title: Text(
                                country.name,
                                style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.navy),
                              ),
                              trailing: Text(
                                country.dialCode,
                                style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.blue300),
                              ),
                              onTap: () => Navigator.of(context).pop(country),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
