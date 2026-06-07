import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class McqQuestionCard extends StatelessWidget {
  final String question;
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelected;

  const McqQuestionCard({
    super.key,
    required this.question,
    required this.options,
    required this.onSelected,
    this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...options.map((opt) {
              final isSelected = selected == opt;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => onSelected(opt),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppTheme.navy : AppTheme.blue100,
                        width: isSelected ? 2 : 1,
                      ),
                      color: isSelected ? AppTheme.blue100.withValues(alpha: 0.3) : Colors.white,
                    ),
                    child: Text(opt),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
