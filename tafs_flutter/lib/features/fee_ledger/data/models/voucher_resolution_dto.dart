import '../../domain/entities/voucher_resolution.dart';
import 'voucher_dto.dart';

class VoucherResolutionDto extends VoucherResolution {
  const VoucherResolutionDto({
    required super.exists,
    super.voucher,
    super.message,
  });

  factory VoucherResolutionDto.fromJson(Map<String, dynamic> json) {
    final voucherJson = json['voucher'];
    return VoucherResolutionDto(
      exists: json['exists'] as bool? ?? false,
      voucher: voucherJson is Map<String, dynamic>
          ? VoucherDto.fromJson(voucherJson)
          : null,
      message: json['message'] as String?,
    );
  }
}
