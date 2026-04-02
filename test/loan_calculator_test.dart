import 'package:flutter_test/flutter_test.dart';
import 'package:loan_countdown/loan_calculator.dart';

void main() {
  group('LoanCalculator Tests', () {
    test('Basic repayment calculation', () {
      final calculator = LoanCalculator(
        monthlyIncome: 5000,
        monthlyExpenses: 2000,
        intermediateThreshold: 0, // Pay every month
        totalLoan: 100000,
        repaidSoFar: 20000,
        currentInstallment: 10,
      );

      // Remaining: 80,000. Monthly: 3,000.
      // 80,000 / 3,000 = 26.666 -> 27 months
      expect(calculator.calculateRemainingMonths(), 27);
    });

    test('Threshold repayment calculation', () {
      final calculator = LoanCalculator(
        monthlyIncome: 5000,
        monthlyExpenses: 2000,
        intermediateThreshold: 10000,
        totalLoan: 100000,
        repaidSoFar: 20000,
        currentInstallment: 10,
      );

      // Month 1: 3,000
      // Month 2: 6,000
      // Month 3: 9,000
      // Month 4: 12,000 -> Pay 10,000 (wait, my logic pays the whole pot if >= threshold)
      // Actually, my logic pays 'payment = currentPot' if currentPot >= threshold.
      // So at month 4, it pays 12,000.
      // Month 1-4: Pay 12,000. Remaining: 68,000
      // Month 5-8: Pay 12,000. Remaining: 56,000
      // ...
      // 80,000 / 12,000 = 6.666 -> 7 iterations of 4 months = 28 months?
      // Wait, let's trace:
      // Month 4: Pay 12k, Debt 68k
      // Month 8: Pay 12k, Debt 56k
      // Month 12: Pay 12k, Debt 44k
      // Month 16: Pay 12k, Debt 32k
      // Month 20: Pay 12k, Debt 20k
      // Month 24: Pay 12k, Debt 8k
      // Month 27: Pot 9k >= Debt 8k, Pay 8k, Debt 0.
      // Total months: 27.
      // Threshold 10,000 with monthly 3,000 doesn't change 27 months.
      expect(calculator.calculateRemainingMonths(), 27);
    });

    test('Status thresholds', () {
      final calculator = LoanCalculator(
        monthlyIncome: 0, monthlyExpenses: 0, intermediateThreshold: 0, totalLoan: 0, repaidSoFar: 0, currentInstallment: 0,
      );

      expect(calculator.getStatus(6), RepaymentStatus.low);
      expect(calculator.getStatus(12), RepaymentStatus.medium);
      expect(calculator.getStatus(36), RepaymentStatus.medium);
      expect(calculator.getStatus(48), RepaymentStatus.high);
    });

    test('Negative savings case', () {
      final calculator = LoanCalculator(
        monthlyIncome: 2000,
        monthlyExpenses: 3000,
        intermediateThreshold: 0,
        totalLoan: 100000,
        repaidSoFar: 0,
        currentInstallment: 1,
      );

      expect(calculator.calculateRemainingMonths(), -1);
      expect(calculator.getStatus(-1), RepaymentStatus.high);
    });
  });
}
