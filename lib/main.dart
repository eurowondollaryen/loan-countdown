import 'package:fl_chart/fl_chart.dart';
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
      title: '대출 상환 카운트다운',
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

  final _incomeController = TextEditingController();
  final _expensesController = TextEditingController();
  final _thresholdController = TextEditingController();
  final _remainingPrincipalController = TextEditingController();
  final _annualInterestRateController = TextEditingController();
  final _remainingTermController = TextEditingController();

  LoanRepaymentType _loanRepaymentType = LoanRepaymentType.equalTotal;

  int? _remainingMonths;
  RepaymentStatus? _status;
  List<MonthlyDataPoint>? _schedule;

  void _calculate() {
    if (_formKey.currentState!.validate()) {
      // 매번 새로운 계산을 위해 초기 상태와 동일한 인스턴스 생성
      final calculator = LoanCalculator(
        monthlyIncome: double.parse(_incomeController.text),
        monthlyExpenses: double.parse(_expensesController.text),
        intermediateThreshold: double.parse(_thresholdController.text),
        annualInterestRate: double.parse(_annualInterestRateController.text) / 100.0,
        loanRepaymentType: _loanRepaymentType,
        remainingPrincipal: double.parse(_remainingPrincipalController.text),
        remainingLoanTermInMonths: int.parse(_remainingTermController.text),
      );

      final result = calculator.generateRepaymentSchedule();

      setState(() {
        _remainingMonths = result.totalMonths;
        _schedule = result.schedule;
        if (_remainingMonths != null) {
          _status = calculator.getStatus(_remainingMonths!);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('대출 상환 카운트다운 계산기'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInputField(_incomeController, '월 고정 수익 (원)'),
              _buildInputField(_expensesController, '월 고정 지출 (원)'),
              const SizedBox(height: 24),
              _buildInputField(_remainingPrincipalController, '남은 대출 원금 (원)'),
              _buildInputField(_annualInterestRateController, '연 이자율 (%)'),
              _buildInputField(_remainingTermController, '남은 대출 기간 (개월)', isInt: true),
              const SizedBox(height: 16),
              _buildLoanTypeSelector(),
              const SizedBox(height: 24),
              _buildInputField(_thresholdController, '중도상환 최소 저축액 (원)', hint: '이 금액 이상 저축되면 중도상환 실행'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _calculate,
                child: const Text('계산하기'),
              ),
              if (_remainingMonths != null) ...[
                const SizedBox(height: 32),
                _buildResultPanel(),
              ],
              if (_schedule != null && _schedule!.isNotEmpty) ...[
                const SizedBox(height: 32),
                _buildChart(),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoanTypeSelector() {
    return SegmentedButton<LoanRepaymentType>(
      segments: const <ButtonSegment<LoanRepaymentType>>[
        ButtonSegment<LoanRepaymentType>(value: LoanRepaymentType.equalTotal, label: Text('원리금균등')),
        ButtonSegment<LoanRepaymentType>(value: LoanRepaymentType.equalPrincipal, label: Text('원금균등')),
      ],
      selected: <LoanRepaymentType>{_loanRepaymentType},
      onSelectionChanged: (Set<LoanRepaymentType> newSelection) {
        setState(() {
          _loanRepaymentType = newSelection.first;
        });
      },
    );
  }

  Widget _buildInputField(TextEditingController controller, String label, {String? hint, bool isInt = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder()),
        keyboardType: TextInputType.number,
        validator: (v) => (v == null || v.isEmpty || double.tryParse(v) == null || double.parse(v) < 0) ? '0 이상의 숫자를 입력하세요' : null,
      ),
    );
  }

  Widget _buildResultPanel() {
    // ... (이전과 동일)
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
          child: Text('계산에 실패했습니다. 입력값을 확인해주세요. (100년 이상 소요될 경우 포함)',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        ),
      );
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text('예상 상환 완료까지', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('$_remainingMonths 개월', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)),
              child: Text(statusText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    final principalData = _schedule!.map((e) => FlSpot(e.month.toDouble(), e.remainingPrincipal)).toList();
    final savingsData = _schedule!.map((e) => FlSpot(e.month.toDouble(), e.savingsPot)).toList();

    return Column(
      children: [
        const Text("상환 추이 그래프", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        AspectRatio(
          aspectRatio: 1.5,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 70)),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true, border: Border.all(color: const Color(0xff37434d), width: 1)),
              lineBarsData: [
                LineChartBarData(
                  spots: principalData,
                  isCurved: true,
                  color: Colors.red,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
                LineChartBarData(
                  spots: savingsData,
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final isPrincipal = spot.bar.color == Colors.red;
                      final title = isPrincipal ? '대출 잔액' : '저축액';
                      final value = spot.y.toInt().toString();
                      return LineTooltipItem(
                        '$title\n$value 원',
                        TextStyle(color: spot.bar.color, fontWeight: FontWeight.bold),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(Colors.red, '대출 잔액'),
            const SizedBox(width: 16),
            _buildLegendItem(Colors.blue, '저축 항아리'),
          ],
        )
      ],
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(width: 16, height: 16, color: color),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _expensesController.dispose();
    _thresholdController.dispose();
    _remainingPrincipalController.dispose();
    _annualInterestRateController.dispose();
    _remainingTermController.dispose();
    super.dispose();
  }
}