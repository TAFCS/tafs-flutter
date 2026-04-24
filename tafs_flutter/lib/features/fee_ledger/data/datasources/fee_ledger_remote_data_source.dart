import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/error/failures.dart';
import '../models/fee_month_status_dto.dart';
import '../models/ledger_response_dto.dart';
import '../models/voucher_dto.dart';
import '../models/voucher_resolution_dto.dart';

abstract class FeeLedgerRemoteDataSource {
  Future<List<VoucherDto>> getStudentVouchers(int studentCc);
  Future<List<FeeMonthStatusDto>> getStudentFeeMonths(int studentCc);
  Future<LedgerResponseDto> getLedger(int studentCc);
  Future<VoucherResolutionDto> resolveVoucherForMonth({
    required int studentCc,
    required String academicYear,
    required int targetMonth,
  });
}

class FeeLedgerRemoteDataSourceImpl implements FeeLedgerRemoteDataSource {
  final Dio dio;
  static const _missingVoucherMessage =
      'Challan not yet generated — please contact the school office.';

  FeeLedgerRemoteDataSourceImpl(this.dio);
  
  @override
  Future<LedgerResponseDto> getLedger(int studentCc) async {
    final baseUrl =
        dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8080/api/v1';
    try {
      final response = await dio.get(
        '$baseUrl/app/student/$studentCc/ledger',
      );
      if (response.statusCode == 200 && response.data != null) {
        return LedgerResponseDto.fromJson(response.data as Map<String, dynamic>);
      }
      throw const ServerFailure('Failed to load ledger');
    } on DioException catch (e) {
      throw ServerFailure(e.message ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<List<VoucherDto>> getStudentVouchers(int studentCc) async {
    final baseUrl =
        dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8080/api/v1';
    try {
      final response = await dio.get(
        '$baseUrl/vouchers/parent/student/$studentCc',
      );
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> raw =
            (response.data['data'] as List<dynamic>?) ?? [];
        final vouchers = raw
            .map((e) => VoucherDto.fromJson(e as Map<String, dynamic>))
            .toList();
        // Ensure newest first irrespective of backend default ordering.
        vouchers.sort((a, b) => b.issueDate.compareTo(a.issueDate));
        return vouchers;
      }
      throw const ServerFailure('Failed to load vouchers');
    } on DioException catch (e) {
      throw ServerFailure(e.message ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<List<FeeMonthStatusDto>> getStudentFeeMonths(int studentCc) async {
    final baseUrl =
        dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8080/api/v1';
    try {
      final response = await dio.get(
        '$baseUrl/student-fees/parent/student/$studentCc/monthly-status',
      );

      if (response.statusCode == 200 && response.data != null) {
        final root = response.data;
        final data = root is Map<String, dynamic> ? root['data'] : null;

        final dynamic rawList;
        if (data is List<dynamic>) {
          rawList = data;
        } else if (data is Map<String, dynamic>) {
          rawList =
              data['months'] ??
              data['items'] ??
              data['rows'] ??
              const <dynamic>[];
        } else {
          rawList = const <dynamic>[];
        }

        final months = (rawList as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map(FeeMonthStatusDto.fromJson)
            .toList();

        months.sort((a, b) {
          final yearCmp = _academicYearSortKey(
            a.academicYear,
          ).compareTo(_academicYearSortKey(b.academicYear));
          if (yearCmp != 0) return yearCmp;
          return a.targetMonth.compareTo(b.targetMonth);
        });

        return months;
      }

      throw const ServerFailure('Failed to load month-wise fee status');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Temporary compatibility fallback until the parent monthly endpoint is available.
        final vouchers = await getStudentVouchers(studentCc);
        return _buildFallbackMonths(vouchers);
      }
      throw ServerFailure(e.message ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<VoucherResolutionDto> resolveVoucherForMonth({
    required int studentCc,
    required String academicYear,
    required int targetMonth,
  }) async {
    final baseUrl =
        dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8080/api/v1';
    try {
      final response = await dio.get(
        '$baseUrl/vouchers/parent/student/$studentCc/resolve',
        queryParameters: {
          'academic_year': academicYear,
          'target_month': targetMonth,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final root = response.data;
        final data = root is Map<String, dynamic> ? root['data'] : null;

        if (data is Map<String, dynamic>) {
          if (data.containsKey('exists')) {
            return VoucherResolutionDto.fromJson(data);
          }

          // Some implementations may return a voucher payload directly.
          return VoucherResolutionDto(
            exists: true,
            voucher: VoucherDto.fromJson(data),
          );
        }
      }

      return const VoucherResolutionDto(
        exists: false,
        message: _missingVoucherMessage,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Temporary compatibility fallback until resolve endpoint is available.
        final vouchers = await getStudentVouchers(studentCc);
        final matches = vouchers
            .where(
              (v) =>
                  v.academicYear == academicYear &&
                  v.month == targetMonth &&
                  v.status != 'VOID',
            )
            .toList();

        if (matches.isEmpty) {
          return const VoucherResolutionDto(
            exists: false,
            message: _missingVoucherMessage,
          );
        }

        matches.sort((a, b) => b.issueDate.compareTo(a.issueDate));
        return VoucherResolutionDto(exists: true, voucher: matches.first);
      }
      throw ServerFailure(e.message ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  List<FeeMonthStatusDto> _buildFallbackMonths(List<VoucherDto> vouchers) {
    final grouped = <String, _MonthAccumulator>{};

    for (final voucher in vouchers) {
      if (voucher.status == 'VOID') continue;

      final month = voucher.month;
      final year = voucher.academicYear;
      final hasDirectMonth =
          month != null && year != null && month >= 1 && month <= 12;

      if (hasDirectMonth) {
        final key = '$year|$month';
        final acc = grouped.putIfAbsent(
          key,
          () => _MonthAccumulator(academicYear: year, targetMonth: month),
        );

        final net = voucher.heads.fold<double>(0, (s, h) => s + h.netAmount);
        final paid = voucher.heads.fold<double>(
          0,
          (s, h) => s + h.amountDeposited,
        );
        final outstanding = voucher.heads.fold<double>(
          0,
          (s, h) => s + h.balance,
        );

        acc.totalAmount += net;
        acc.totalPaid += paid;
        acc.outstanding += outstanding;
        acc.status = _pickStrongerStatus(acc.status, voucher.status);
        acc.latestIssueDate =
            acc.latestIssueDate == null ||
                voucher.issueDate.isAfter(acc.latestIssueDate!)
            ? voucher.issueDate
            : acc.latestIssueDate;
        continue;
      }

      // If voucher-level month is missing, derive month buckets from fee-head metadata.
      for (final head in voucher.heads) {
        final headMonth = head.targetMonth;
        final headYear = head.academicYear;
        if (headMonth == null ||
            headYear == null ||
            headMonth < 1 ||
            headMonth > 12) {
          continue;
        }

        final key = '$headYear|$headMonth';
        final acc = grouped.putIfAbsent(
          key,
          () =>
              _MonthAccumulator(academicYear: headYear, targetMonth: headMonth),
        );

        acc.totalAmount += head.netAmount;
        acc.totalPaid += head.amountDeposited;
        acc.outstanding += head.balance;
        acc.status = _pickStrongerStatus(
          acc.status,
          _statusFromHeadTotals(
            paid: head.amountDeposited,
            outstanding: head.balance,
          ),
        );
        acc.latestIssueDate =
            acc.latestIssueDate == null ||
                voucher.issueDate.isAfter(acc.latestIssueDate!)
            ? voucher.issueDate
            : acc.latestIssueDate;
      }
    }

    final months = grouped.values
        .map(
          (acc) => FeeMonthStatusDto(
            academicYear: acc.academicYear,
            targetMonth: acc.targetMonth,
            monthLabel: _monthLabel(acc.targetMonth),
            totalAmount: acc.totalAmount,
            totalPaid: acc.totalPaid,
            outstandingBalance: acc.outstanding,
            runningOutstandingBalance: 0,
            status: acc.status,
            feeDate: acc.latestIssueDate,
          ),
        )
        .toList();

    months.sort((a, b) {
      final yearCmp = _academicYearSortKey(
        a.academicYear,
      ).compareTo(_academicYearSortKey(b.academicYear));
      if (yearCmp != 0) return yearCmp;
      return a.targetMonth.compareTo(b.targetMonth);
    });

    var runningOutstanding = 0.0;
    return months.map((m) {
      runningOutstanding += m.outstandingBalance;
      return FeeMonthStatusDto(
        academicYear: m.academicYear,
        targetMonth: m.targetMonth,
        monthLabel: m.monthLabel,
        totalAmount: m.totalAmount,
        totalPaid: m.totalPaid,
        outstandingBalance: m.outstandingBalance,
        runningOutstandingBalance: runningOutstanding,
        status: m.status,
        feeDate: m.feeDate,
      );
    }).toList();
  }

  int _academicYearSortKey(String year) {
    final parts = year.split('-');
    if (parts.isEmpty) return 0;
    return int.tryParse(parts.first) ?? 0;
  }

  String _monthLabel(int month) {
    const labels = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    if (month < 1 || month > 12) return 'Unknown';
    return labels[month - 1];
  }

  String _pickStrongerStatus(String current, String next) {
    int rank(String status) {
      switch (status) {
        case 'PAID':
          return 4;
        case 'PARTIALLY_PAID':
          return 3;
        case 'OVERDUE':
          return 2;
        case 'UNPAID':
        case 'ISSUED':
          return 1;
        case 'NOT_ISSUED':
          return 0;
        default:
          return 1;
      }
    }

    return rank(next) >= rank(current) ? next : current;
  }

  String _statusFromHeadTotals({
    required double paid,
    required double outstanding,
  }) {
    if (outstanding <= 0) return 'PAID';
    if (paid > 0) return 'PARTIALLY_PAID';
    return 'ISSUED';
  }
}

class _MonthAccumulator {
  final String academicYear;
  final int targetMonth;
  double totalAmount = 0;
  double totalPaid = 0;
  double outstanding = 0;
  String status = 'NOT_ISSUED';
  DateTime? latestIssueDate;

  _MonthAccumulator({required this.academicYear, required this.targetMonth});
}
