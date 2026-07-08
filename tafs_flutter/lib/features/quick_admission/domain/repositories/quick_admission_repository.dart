import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/unconfirmed_admission.dart';

abstract class QuickAdmissionRepository {
  Future<Either<Failure, UnconfirmedAdmission>> createQuickAdmission(Map<String, dynamic> data);
  Future<Either<Failure, String>> uploadPhoto(int cc, String filePath);
  Future<Either<Failure, Uint8List>> getDepositSlipPdf(int cc);
}
