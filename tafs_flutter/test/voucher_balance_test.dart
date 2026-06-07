import 'package:flutter_test/flutter_test.dart';
import 'package:tafs_flutter/features/fee_ledger/data/models/voucher_dto.dart';
import 'package:tafs_flutter/features/fee_ledger/domain/entities/voucher.dart';

Voucher _buildVoucher({
  required List<VoucherHead> heads,
  double totalPayableBeforeDue = 21000,
  double totalPayableAfterDue = 22000,
  bool lateFeeCharge = true,
  DateTime? dueDate,
  String status = 'UNPAID',
  double? serverTotalBalance,
  double? surchargeBalance,
  double? headBalance,
  double? serverTotalDeposited,
  List<VoucherArrearSurcharge> arrearSurcharges = const [],
}) {
  return Voucher(
    id: 4983,
    status: status,
    issueDate: DateTime(2026, 6, 1),
    dueDate: dueDate ?? DateTime(2026, 9, 30),
    totalPayableBeforeDue: totalPayableBeforeDue,
    totalPayableAfterDue: totalPayableAfterDue,
    lateFeeDeposited: 0,
    lateFeeCharge: lateFeeCharge,
    heads: heads,
    arrearSurcharges: arrearSurcharges,
    serverTotalBalance: serverTotalBalance,
    surchargeBalance: surchargeBalance,
    headBalance: headBalance,
    serverTotalDeposited: serverTotalDeposited,
  );
}

void main() {
  group('Voucher.totalBalance', () {
    final heads = [
      const VoucherHead(
        id: 1,
        feeType: 'ARREARS (MAY 25)',
        netAmount: 10000,
        amountDeposited: 0,
        balance: 10000,
        discountAmount: 0,
        isArrear: true,
      ),
      const VoucherHead(
        id: 2,
        feeType: 'MONTHLY TUITION FEE (JUN 25)',
        netAmount: 10000,
        amountDeposited: 0,
        balance: 10000,
        discountAmount: 0,
      ),
    ];

    test('uses server total_balance when provided', () {
      final voucher = _buildVoucher(
        heads: heads,
        serverTotalBalance: 21000,
        surchargeBalance: 1000,
      );

      expect(voucher.totalBalance, 21000);
    });

    test('includes arrear surcharge balance in client fallback', () {
      final voucher = _buildVoucher(
        heads: heads,
        surchargeBalance: 1000,
      );

      expect(voucher.totalBalance, 21000);
    });

    test('includes arrear surcharge rows in client fallback', () {
      final voucher = _buildVoucher(
        heads: heads,
        arrearSurcharges: const [
          VoucherArrearSurcharge(
            id: 1,
            arrearMonth: 5,
            arrearYear: '2025-26',
            amount: 1000,
            amountPaid: 0,
          ),
        ],
      );

      expect(voucher.totalBalance, 21000);
    });

    test('uses server total_balance after partial surcharge payment', () {
      final voucher = _buildVoucher(
        heads: heads,
        serverTotalBalance: 20500,
        serverTotalDeposited: 500,
      );

      expect(voucher.totalBalance, 20500);
      expect(voucher.totalPaid, 500);
    });

    test('head-only fallback when no surcharge fields (older backend)', () {
      final voucher = _buildVoucher(heads: heads);

      expect(voucher.totalBalance, 20000);
    });

    test('adds overdue late fee when past due date', () {
      final voucher = _buildVoucher(
        heads: heads,
        surchargeBalance: 1000,
        dueDate: DateTime(2020, 1, 1),
      );

      expect(voucher.totalBalance, 22000);
    });
  });

  group('VoucherDto.fromJson', () {
    test('parses normalized voucher with arrear surcharge totals', () {
      final dto = VoucherDto.fromJson({
        'id': 4983,
        'status': 'UNPAID',
        'issue_date': '2026-06-01',
        'due_date': '2026-09-30',
        'total_payable_before_due': 21000,
        'total_payable_after_due': 22000,
        'late_fee_charge': true,
        'late_fee_deposited': 0,
        'total_balance': '21000.00',
        'surcharge_balance': '1000.00',
        'head_balance': '20000.00',
        'total_deposited': '0.00',
        'voucher_heads': [
          {
            'id': 1,
            'net_amount': 10000,
            'amount_deposited': 0,
            'balance': '10000',
            'description': 'ARREARS (MAY 25)',
          },
          {
            'id': 2,
            'net_amount': 10000,
            'amount_deposited': 0,
            'balance': '10000',
            'description': 'MONTHLY TUITION FEE (JUN 25)',
          },
        ],
        'voucher_arrear_surcharges': [
          {
            'id': 1,
            'arrear_month': 5,
            'arrear_year': '2025-26',
            'amount': '1000',
            'amount_paid': '0',
            'waived': false,
          },
        ],
      });

      expect(dto.totalPayableBeforeDue, 21000);
      expect(dto.totalBalance, 21000);
      expect(dto.activeArrearSurcharges.length, 1);
    });
  });
}
