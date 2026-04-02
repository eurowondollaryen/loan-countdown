enum RepaymentStatus { high, medium, low }

class LoanCalculator {
  /// Monthly fixed income
  final double monthlyIncome;

  /// Monthly fixed expenses
  final double monthlyExpenses;

  /// Savings threshold for intermediate repayment
  final double intermediateThreshold;

  /// Total loan amount
  final double totalLoan;

  /// Amount repaid so far
  final double repaidSoFar;

  /// Current repayment installment
  final int currentInstallment;

  LoanCalculator({
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.intermediateThreshold,
    required this.totalLoan,
    required this.repaidSoFar,
    required this.currentInstallment,
  });

  /// Calculates the remaining months until the loan is fully repaid.
  int calculateRemainingMonths() {
    double monthlySavings = monthlyIncome - monthlyExpenses;
    if (monthlySavings <= 0) {
      // If savings are zero or negative, the loan will never be repaid.
      // We return -1 or a large number, but -1 is clearer for "never".
      return -1;
    }

    double remainingDebt = totalLoan - repaidSoFar;
    if (remainingDebt <= 0) return 0;

    int months = 0;
    double currentPot = 0;

    // Simulation loop
    while (remainingDebt > 0) {
      months++;
      currentPot += monthlySavings;

      // Check if threshold for repayment is reached or if pot covers remaining debt
      if (currentPot >= intermediateThreshold || currentPot >= remainingDebt) {
        double payment = currentPot;
        if (payment > remainingDebt) {
          payment = remainingDebt;
        }
        remainingDebt -= payment;
        currentPot -= payment; // Keep remaining savings for next month
      }
      
      // Safety break to prevent infinite loop
      if (months > 1200) break; // 100 years
    }

    return months;
  }

  /// Returns the repayment status based on remaining months.
  /// Low: < 12 months
  /// Medium: 12-36 months
  /// High: > 36 months
  RepaymentStatus getStatus(int months) {
    if (months < 0) return RepaymentStatus.high;
    if (months < 12) return RepaymentStatus.low;
    if (months <= 36) return RepaymentStatus.medium;
    return RepaymentStatus.high;
  }
}
