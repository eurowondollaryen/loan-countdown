import 'package:flutter_test/flutter_test.dart';
import 'package:loan_countdown/loan_calculator.dart';

void main() {
  group('LoanCalculator Tests (New Logic)', () {
    test('Case 1: 원리금균등 - 중도상환 없이', () {
      final calculator = LoanCalculator(
        monthlyIncome: 5000000,
        monthlyExpenses: 2000000,
        intermediateThreshold: 1000000000, // 사실상 중도상환 안함
        annualInterestRate: 0.05, // 5%
        loanRepaymentType: LoanRepaymentType.equalTotal,
        remainingPrincipal: 100000000, // 1억
        remainingLoanTermInMonths: 120, // 10년
      );

      final result = calculator.generateRepaymentSchedule();
      expect(result.totalMonths, lessThanOrEqualTo(120));
      expect(result.totalMonths, greaterThan(100)); // 대략적인 예상
    });

    test('Case 2: 원리금균등 - 중도상환 포함', () {
      final calculator = LoanCalculator(
        monthlyIncome: 5000000,
        monthlyExpenses: 2000000,
        intermediateThreshold: 10000000, // 1000만원 모이면 중도상환
        annualInterestRate: 0.05,
        loanRepaymentType: LoanRepaymentType.equalTotal,
        remainingPrincipal: 100000000,
        remainingLoanTermInMonths: 120,
      );

      final result = calculator.generateRepaymentSchedule();
      expect(result.totalMonths, lessThan(120));
    });

    test('Case 3: 원금균등 - 중도상환 포함', () {
      final calculator = LoanCalculator(
        monthlyIncome: 5000000,
        monthlyExpenses: 2000000,
        intermediateThreshold: 10000000,
        annualInterestRate: 0.05,
        loanRepaymentType: LoanRepaymentType.equalPrincipal,
        remainingPrincipal: 100000000,
        remainingLoanTermInMonths: 120,
      );
      
      final result = calculator.generateRepaymentSchedule();
      expect(result.totalMonths, lessThan(120));
    });

    test('Case 4: 소득이 지출+상환금보다 적을 경우', () {
      final calculator = LoanCalculator(
        monthlyIncome: 3000000,
        monthlyExpenses: 2000000,
        intermediateThreshold: 10000000,
        annualInterestRate: 0.05,
        loanRepaymentType: LoanRepaymentType.equalTotal,
        remainingPrincipal: 100000000,
        remainingLoanTermInMonths: 120,
      );

      final result = calculator.generateRepaymentSchedule();
      expect(result.totalMonths, 120);
    });

    test('Case 5: 대출금이 0일 경우', () {
      final calculator = LoanCalculator(
        monthlyIncome: 5000000,
        monthlyExpenses: 2000000,
        intermediateThreshold: 10000000,
        annualInterestRate: 0.05,
        loanRepaymentType: LoanRepaymentType.equalTotal,
        remainingPrincipal: 0,
        remainingLoanTermInMonths: 0,
      );

      final result = calculator.generateRepaymentSchedule();
      expect(result.totalMonths, 0);
    });

    test('Case 6: 원리금균등 vs 원금균등 결과 비교', () {
      final calculatorEqualTotal = LoanCalculator(
        monthlyIncome: 5000000,
        monthlyExpenses: 2000000,
        intermediateThreshold: 10000000,
        annualInterestRate: 0.05,
        loanRepaymentType: LoanRepaymentType.equalTotal,
        remainingPrincipal: 100000000,
        remainingLoanTermInMonths: 120,
      );

      final calculatorEqualPrincipal = LoanCalculator(
        monthlyIncome: 5000000,
        monthlyExpenses: 2000000,
        intermediateThreshold: 10000000,
        annualInterestRate: 0.05,
        loanRepaymentType: LoanRepaymentType.equalPrincipal,
        remainingPrincipal: 100000000,
        remainingLoanTermInMonths: 120,
      );

      final monthsTotal = calculatorEqualTotal.generateRepaymentSchedule().totalMonths;
      final monthsPrincipal = calculatorEqualPrincipal.generateRepaymentSchedule().totalMonths;

      print('원리금균등 예상 개월: $monthsTotal');
      print('원금균등 예상 개월: $monthsPrincipal');
      expect(monthsTotal, isNot(equals(monthsPrincipal)));
    });
  });
}
