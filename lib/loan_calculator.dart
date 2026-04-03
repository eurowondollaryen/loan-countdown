import 'dart:math';

// 데이터 클래스 추가
class MonthlyDataPoint {
  final int month;
  final double savingsPot;
  final double remainingPrincipal;

  MonthlyDataPoint({
    required this.month,
    required this.savingsPot,
    required this.remainingPrincipal,
  });
}

class CalculationResult {
  final int totalMonths;
  final List<MonthlyDataPoint> schedule;

  CalculationResult({required this.totalMonths, required this.schedule});
}


enum RepaymentStatus { high, medium, low }

enum LoanRepaymentType {
  equalTotal, // 원리금균등
  equalPrincipal, // 원금균등
}

class LoanCalculator {
  final double monthlyIncome;
  final double monthlyExpenses;
  final double intermediateThreshold;
  final double annualInterestRate;
  final LoanRepaymentType loanRepaymentType;
  
  double remainingPrincipal;
  int remainingLoanTermInMonths;

  LoanCalculator({
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.intermediateThreshold,
    required this.annualInterestRate,
    required this.loanRepaymentType,
    required this.remainingPrincipal,
    required this.remainingLoanTermInMonths,
  });

  /// 대출 상환 스케줄과 총 개월 수를 계산합니다.
  CalculationResult generateRepaymentSchedule() {
    if (remainingPrincipal <= 0) {
      return CalculationResult(totalMonths: 0, schedule: []);
    }

    List<MonthlyDataPoint> schedule = [];
    int monthsElapsed = 0;
    double savingsPot = 0;
    double monthlyInterestRate = annualInterestRate / 12;

    double fixedPrincipalPayment = (loanRepaymentType == LoanRepaymentType.equalPrincipal && remainingLoanTermInMonths > 0)
        ? remainingPrincipal / remainingLoanTermInMonths
        : 0;

    while (remainingPrincipal > 0) {
      monthsElapsed++;

      double monthlyLoanPayment = _calculateMonthlyLoanPayment(
        principal: remainingPrincipal,
        monthlyRate: monthlyInterestRate,
        remainingMonths: remainingLoanTermInMonths,
        fixedPrincipalPayment: fixedPrincipalPayment
      );

      double monthlySavings = monthlyIncome - monthlyExpenses - monthlyLoanPayment;
      savingsPot += monthlySavings;

      double interestForMonth = remainingPrincipal * monthlyInterestRate;
      double principalForMonth = monthlyLoanPayment - interestForMonth;
      
      if (principalForMonth < 0) {
          principalForMonth = 0;
      }

      remainingPrincipal -= principalForMonth;
      if (remainingLoanTermInMonths > 0) {
        remainingLoanTermInMonths--;
      }

      if (savingsPot >= intermediateThreshold && savingsPot > 0) {
        double earlyPayment = savingsPot;
        if (earlyPayment > remainingPrincipal) {
          earlyPayment = remainingPrincipal;
        }
        remainingPrincipal -= earlyPayment;
        savingsPot = 0;

        if (loanRepaymentType == LoanRepaymentType.equalPrincipal && remainingLoanTermInMonths > 0) {
            fixedPrincipalPayment = remainingPrincipal / remainingLoanTermInMonths;
        }
      }

      if (remainingPrincipal < 0) remainingPrincipal = 0;

      schedule.add(MonthlyDataPoint(
        month: monthsElapsed,
        savingsPot: savingsPot,
        remainingPrincipal: remainingPrincipal,
      ));

      if (remainingPrincipal <= 0) {
        break;
      }

      if (monthsElapsed > 1200) { // 100년 이상
        return CalculationResult(totalMonths: -1, schedule: []);
      }
    }

    return CalculationResult(totalMonths: monthsElapsed, schedule: schedule);
  }

  double _calculateMonthlyLoanPayment({
    required double principal,
    required double monthlyRate,
    required int remainingMonths,
    required double fixedPrincipalPayment,
  }) {
    if (principal <= 0 || remainingMonths <= 0) return 0;

    if (loanRepaymentType == LoanRepaymentType.equalTotal) {
      if (monthlyRate == 0) return principal / remainingMonths;
      double rateFactor = pow(1 + monthlyRate, remainingMonths).toDouble();
      return principal * (monthlyRate * rateFactor) / (rateFactor - 1);
    } else {
      double interestPayment = principal * monthlyRate;
      return fixedPrincipalPayment + interestPayment;
    }
  }

  RepaymentStatus getStatus(int months) {
    if (months < 0) return RepaymentStatus.high;
    if (months < 12) return RepaymentStatus.low;
    if (months <= 36) return RepaymentStatus.medium;
    return RepaymentStatus.high;
  }
}
