class GradeOption {
  final int id;
  final String classCode;
  final String description;

  const GradeOption({
    required this.id,
    required this.classCode,
    required this.description,
  });

  factory GradeOption.fromJson(Map<String, dynamic> json) {
    return GradeOption(
      id: json['id'] as int,
      classCode: json['class_code'] as String? ??
          json['classCode'] as String? ??
          '',
      description: json['description'] as String? ??
          json['class_description'] as String? ??
          'Grade ${json['id']}',
    );
  }
}

class SectionOption {
  final int id;
  final String description;
  final int? classId;

  const SectionOption({
    required this.id,
    required this.description,
    this.classId,
  });

  factory SectionOption.fromJson(Map<String, dynamic> json) {
    return SectionOption(
      id: json['id'] as int,
      description: json['description'] as String? ??
          json['name'] as String? ??
          json['section_name'] as String? ??
          'Section ${json['id']}',
      classId: json['class_id'] as int?,
    );
  }
}
