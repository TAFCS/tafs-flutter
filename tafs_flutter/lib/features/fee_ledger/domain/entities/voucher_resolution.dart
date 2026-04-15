import 'package:equatable/equatable.dart';

import 'voucher.dart';

class VoucherResolution extends Equatable {
  final bool exists;
  final Voucher? voucher;
  final String? message;

  const VoucherResolution({required this.exists, this.voucher, this.message});

  @override
  List<Object?> get props => [exists, voucher, message];
}
