import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/origination_options.dart';

abstract class TicketOriginationEvent extends Equatable {
  const TicketOriginationEvent();
  @override
  List<Object?> get props => [];
}

class TicketOriginationStarted extends TicketOriginationEvent {
  final OriginationOptions options;
  final List<Map<String, dynamic>> students;
  const TicketOriginationStarted(this.options, this.students);
  @override
  List<Object?> get props => [options, students];
}

class TicketOriginationCategorySelected extends TicketOriginationEvent {
  final String category;
  const TicketOriginationCategorySelected(this.category);
  @override
  List<Object?> get props => [category];
}

class TicketOriginationChildSelected extends TicketOriginationEvent {
  final String label;
  final int? studentId;
  const TicketOriginationChildSelected(this.label, this.studentId);
  @override
  List<Object?> get props => [label, studentId];
}

class TicketOriginationTopicSelected extends TicketOriginationEvent {
  final String subtopic;
  const TicketOriginationTopicSelected(this.subtopic);
  @override
  List<Object?> get props => [subtopic];
}

class TicketOriginationDescriptionChanged extends TicketOriginationEvent {
  final String description;
  const TicketOriginationDescriptionChanged(this.description);
  @override
  List<Object?> get props => [description];
}

class TicketOriginationAttachmentSelected extends TicketOriginationEvent {
  final XFile? file;
  const TicketOriginationAttachmentSelected(this.file);
  @override
  List<Object?> get props => [file];
}

class TicketOriginationSubmitted extends TicketOriginationEvent {
  const TicketOriginationSubmitted();
}

class TicketOriginationStepBack extends TicketOriginationEvent {
  const TicketOriginationStepBack();
}

abstract class TicketOriginationState extends Equatable {
  const TicketOriginationState();
  @override
  List<Object?> get props => [];
}

class TicketOriginationInitial extends TicketOriginationState {}

class TicketOriginationReady extends TicketOriginationState {
  final int step;
  final OriginationOptions options;
  final List<Map<String, dynamic>> students;
  final String? category;
  final String? childLabel;
  final int? studentId;
  final String? subtopic;
  final String description;
  final XFile? attachment;
  final bool submitting;
  final String? error;
  final String? createdTicketId;

  const TicketOriginationReady({
    required this.step,
    required this.options,
    required this.students,
    this.category,
    this.childLabel,
    this.studentId,
    this.subtopic,
    this.description = '',
    this.attachment,
    this.submitting = false,
    this.error,
    this.createdTicketId,
  });

  TicketOriginationReady copyWith({
    int? step,
    String? category,
    String? childLabel,
    int? studentId,
    String? subtopic,
    String? description,
    XFile? attachment,
    bool? submitting,
    String? error,
    String? createdTicketId,
  }) =>
      TicketOriginationReady(
        step: step ?? this.step,
        options: options,
        students: students,
        category: category ?? this.category,
        childLabel: childLabel ?? this.childLabel,
        studentId: studentId ?? this.studentId,
        subtopic: subtopic ?? this.subtopic,
        description: description ?? this.description,
        attachment: attachment ?? this.attachment,
        submitting: submitting ?? this.submitting,
        error: error,
        createdTicketId: createdTicketId ?? this.createdTicketId,
      );

  @override
  List<Object?> get props =>
      [step, category, childLabel, studentId, subtopic, description, attachment, submitting, error, createdTicketId];
}
