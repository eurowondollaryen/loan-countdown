import 'dart:math';

// 데이터 클래스 추가
class MonthlyDataPoint {
  final int month;
  final double savingsPot;
  final double monthlySavings;
  final double cumulativeSavings; // New field: Pot balance before early repayment
  final double remainingPrincipal;
  final double totalPayment;
  final double principalPaid;
  final double interestPaid;
  final double earlyRepaymentAmount;
  final double balanceAfterRepayment;

  MonthlyDataPoint({
    required this.month,
    required this.savingsPot,
    required this.monthlySavings,
    required this.cumulativeSavings, // New field
    required this.remainingPrincipal,
    required this.totalPayment,
    required this.principalPaid,
    required this.interestPaid,
    required this.earlyRepaymentAmount,
    required this.balanceAfterRepayment,
  });
}

class CalculationResult {
  final int totalMonths;
  final List<MonthlyDataPoint> schedule;
  final int earlyRepaymentCount;
  final double totalInterestPaid;
  final double totalInterestSaved;

  CalculationResult({
    required this.totalMonths, 
    required this.schedule,
    required this.earlyRepaymentCount,
    required this.totalInterestPaid,
    required this.totalInterestSaved,
  });
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
  
  final double initialRemainingPrincipal;
  final int initialRemainingTerm;

  LoanCalculator({
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.intermediateThreshold,
    required this.annualInterestRate,
    required this.loanRepaymentType,
    required double remainingPrincipal,
    required int remainingLoanTermInMonths,
  }) : initialRemainingPrincipal = remainingPrincipal,
       initialRemainingTerm = remainingLoanTermInMonths;

  /// 대출 상환 스케줄과 총 개월 수를 계산합니다.
  CalculationResult generateRepaymentSchedule() {
    if (initialRemainingPrincipal <= 0) {
      return CalculationResult(
        totalMonths: 0, 
        schedule: [], 
        earlyRepaymentCount: 0,
        totalInterestPaid: 0,
        totalInterestSaved: 0,
      );
    }

    // 1. 기준 이자 계산 (중도상환 없을 때)
    double baselineInterest = _calculateTotalInterest(initialRemainingPrincipal, initialRemainingTerm);

    // 2. 시뮬레이션
    List<MonthlyDataPoint> schedule = [];
    int monthsElapsed = 0;
    double savingsPot = 0;
    double remainingPrincipal = initialRemainingPrincipal;
    int remainingLoanTermInMonths = initialRemainingTerm;
    double monthlyInterestRate = annualInterestRate / 12;
    int earlyRepaymentCount = 0;
    double totalInterestPaid = 0;

    double fixedPrincipalPayment = (loanRepaymentType == LoanRepaymentType.equalPrincipal && remainingLoanTermInMonths > 0)
        ? remainingPrincipal / remainingLoanTermInMonths
        : 0;

    while (remainingPrincipal > 0) {
      monthsElapsed++;

      double monthlyLoanPayment = _calculateMonthlyLoanPayment(
        principal: remainingPrincipal,
        monthlyRate: monthlyInterestRate,
        remainingMonths: remainingLoanTermInMonths,
        fixedPrincipalPayment: fixedPrincipalPayment,
        type: loanRepaymentType,
      );
      
      double interestForMonth = remainingPrincipal * monthlyInterestRate;
      double principalForMonth = monthlyLoanPayment - interestForMonth;

      if (principalForMonth < 0) principalForMonth = 0;
      totalInterestPaid += interestForMonth;
      
      double earlyPaymentForMonth = 0;
      double monthlySavings = monthlyIncome - monthlyExpenses - monthlyLoanPayment;
      savingsPot += monthlySavings;

      double cumulativeSavingsBeforeRepayment = savingsPot;

      if (savingsPot >= intermediateThreshold && intermediateThreshold > 0 && remainingPrincipal > 0) {
        double earlyPayment = intermediateThreshold;
        if (earlyPayment > remainingPrincipal) {
          earlyPayment = remainingPrincipal;
        }
        remainingPrincipal -= earlyPayment;
        earlyPaymentForMonth = earlyPayment;
        savingsPot -= earlyPayment;
        earlyRepaymentCount++;

        if (loanRepaymentType == LoanRepaymentType.equalPrincipal && remainingLoanTermInMonths > 0) {
            fixedPrincipalPayment = remainingPrincipal / remainingLoanTermInMonths;
        }
      } else if (savingsPot >= remainingPrincipal && remainingPrincipal > 0) {
        double earlyPayment = remainingPrincipal;
        remainingPrincipal = 0;
        earlyPaymentForMonth = earlyPayment;
        savingsPot -= earlyPayment;
        earlyRepaymentCount++;
      }

      remainingPrincipal -= principalForMonth;
      if (remainingLoanTermInMonths > 0) {
        remainingLoanTermInMonths--;
      }

      if (remainingPrincipal < 0) remainingPrincipal = 0;

      schedule.add(MonthlyDataPoint(
        month: monthsElapsed,
        savingsPot: savingsPot,
        monthlySavings: monthlySavings,
        cumulativeSavings: cumulativeSavingsBeforeRepayment,
        remainingPrincipal: remainingPrincipal,
        totalPayment: monthlyLoanPayment,
        principalPaid: principalForMonth,
        interestPaid: interestForMonth,
        earlyRepaymentAmount: earlyPaymentForMonth,
        balanceAfterRepayment: remainingPrincipal,
      ));

      if (remainingPrincipal <= 0) break;

      if (monthsElapsed > 1200) {
        return CalculationResult(
          totalMonths: -1, 
          schedule: [],
          earlyRepaymentCount: 0,
          totalInterestPaid: 0,
          totalInterestSaved: 0,
        );
      }
    }

    return CalculationResult(
      totalMonths: monthsElapsed, 
      schedule: schedule,
      earlyRepaymentCount: earlyRepaymentCount,
      totalInterestPaid: totalInterestPaid,
      totalInterestSaved: (baselineInterest - totalInterestPaid).clamp(0, double.infinity),
    );
  }

  double _calculateTotalInterest(double principal, int terms) {
    if (principal <= 0 || terms <= 0) return 0;
    double totalInterest = 0;
    double tempPrincipal = principal;
    double monthlyRate = annualInterestRate / 12;
    double fixedPrincipal = (loanRepaymentType == LoanRepaymentType.equalPrincipal) ? principal / terms : 0;

    for (int i = 0; i < terms; i++) {
      double interest = tempPrincipal * monthlyRate;
      totalInterest += interest;
      
      double monthlyPayment = _calculateMonthlyLoanPayment(
        principal: tempPrincipal,
        monthlyRate: monthlyRate,
        remainingMonths: terms - i,
        fixedPrincipalPayment: fixedPrincipal,
        type: loanRepaymentType,
      );
      
      double principalPaid = monthlyPayment - interest;
      tempPrincipal -= principalPaid;
      if (tempPrincipal <= 0) break;
    }
    return totalInterest;
  }

  double _calculateMonthlyLoanPayment({
    required double principal,
    required double monthlyRate,
    required int remainingMonths,
    required double fixedPrincipalPayment,
    required LoanRepaymentType type,
  }) {
    if (principal <= 0 || remainingMonths <= 0) return 0;

    if (type == LoanRepaymentType.equalTotal) {
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
