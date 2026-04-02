import 'package:flutter/material.dart';
import 'loan_calculator.dart';

void main() {
  runApp(const LoanCountdownApp());
}

class LoanCountdownApp extends StatelessWidget {
  const LoanCountdownApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loan Countdown',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const CalculatorPage(),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for input fields
  final _incomeController = TextEditingController();
  final _expensesController = TextEditingController();
  final _thresholdController = TextEditingController();
  final _totalLoanController = TextEditingController();
  final _repaidSoFarController = TextEditingController();
  final _installmentController = TextEditingController();

  int? _remainingMonths;
  RepaymentStatus? _status;

  void _calculate() {
    if (_formKey.currentState!.validate()) {
      final calculator = LoanCalculator(
        monthlyIncome: double.parse(_incomeController.text),
        monthlyExpenses: double.parse(_expensesController.text),
        intermediateThreshold: double.parse(_thresholdController.text),
        totalLoan: double.parse(_totalLoanController.text),
        repaidSoFar: double.parse(_repaidSoFarController.text),
        currentInstallment: int.parse(_installmentController.text),
      );

      setState(() {
        _remainingMonths = calculator.calculateRemainingMonths();
        _status = calculator.getStatus(_remainingMonths!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Countdown Calculator'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInputField(_incomeController, '월 고정 수익', 'Monthly fixed income'),
              _buildInputField(_expensesController, '월 고정 지출', 'Monthly fixed expenses'),
              _buildInputField(_thresholdController, '중도상환 임계금액', 'Savings threshold for intermediate repayment'),
              _buildInputField(_totalLoanController, '전체 대출 금액', 'Total loan amount'),
              _buildInputField(_repaidSoFarController, '현재까지 상환 금액', 'Amount repaid so far'),
              _buildInputField(_installmentController, '현재 상환 차수', 'Current repayment installment', isInt: true),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _calculate,
                child: const Text('Calculate'),
              ),
              if (_remainingMonths != null) ...[
                const SizedBox(height: 32),
                _buildResultPanel(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label, String hint, {bool isInt = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.isEmpty) return '값을 입력하세요';
          if (double.tryParse(value) == null) return '숫자를 입력하세요';
          return null;
        },
      ),
    );
  }

  Widget _buildResultPanel() {
    String statusText;
    Color statusColor;

    switch (_status) {
      case RepaymentStatus.low:
        statusText = '상태: 상 (빠른 상환 가능)';
        statusColor = Colors.green;
        break;
      case RepaymentStatus.medium:
        statusText = '상태: 중 (평균적인 기간)';
        statusColor = Colors.orange;
        break;
      case RepaymentStatus.high:
      default:
        statusText = '상태: 하 (장기적인 계획 필요)';
        statusColor = Colors.red;
        break;
    }

    if (_remainingMonths == -1) {
      return const Card(
        color: Colors.redAccent,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '월 고정 수익이 지출보다 적거나 같습니다. 상환이 불가능합니다.',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              '대출 상환까지 남은 기간',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '$_remainingMonths 개월',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusText,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _expensesController.dispose();
    _thresholdController.dispose();
    _totalLoanController.dispose();
    _repaidSoFarController.dispose();
    _installmentController.dispose();
    super.dispose();
  }
}
