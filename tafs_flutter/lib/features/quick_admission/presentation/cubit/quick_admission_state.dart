import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import '../../domain/entities/unconfirmed_admission.dart';

abstract class QuickAdmissionState extends Equatable {
  const QuickAdmissionState();

  @override
  List<Object?> get props => [];
}

class QuickAdmissionInitial extends QuickAdmissionState {}

class QuickAdmissionSubmitInProgress extends QuickAdmissionState {}

class QuickAdmissionSubmitSuccess extends QuickAdmissionState {
  final UnconfirmedAdmission admission;

  const QuickAdmissionSubmitSuccess(this.admission);

  @override
  List<Object?> get props => [admission];
}

class QuickAdmissionSubmitFailure extends QuickAdmissionState {
  final String message;

  const QuickAdmissionSubmitFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class QuickAdmissionPdfLoading extends QuickAdmissionState {}

class QuickAdmissionPdfSuccess extends QuickAdmissionState {
  final Uint8List pdfBytes;

  const QuickAdmissionPdfSuccess(this.pdfBytes);

  @override
  List<Object?> get props => [pdfBytes];
}

class QuickAdmissionPdfFailure extends QuickAdmissionState {
  final String message;

  const QuickAdmissionPdfFailure(this.message);

  @override
  List<Object?> get props => [message];
}
