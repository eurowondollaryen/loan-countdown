import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          primary: const Color(0xFF6366F1),
          secondary: const Color(0xFF10B981),
        ),
        useMaterial3: true,
        fontFamily: 'Pretendard',
        cardTheme: const CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
            side: BorderSide(color: Color(0xFFE2E8F0)),
          ),
          color: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
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
  final _currencyFormat = NumberFormat.decimalPattern('ko_KR');
  final _screenshotController = ScreenshotController();

  final _incomeController = TextEditingController();
  final _expensesController = TextEditingController();
  final _thresholdController = TextEditingController();
  final _remainingPrincipalController = TextEditingController();
  final _annualInterestRateController = TextEditingController();
  final _remainingTermController = TextEditingController();

  LoanRepaymentType _loanRepaymentType = LoanRepaymentType.equalTotal;

  int? _remainingMonths;
  double? _totalInterestSaved;
  int? _earlyRepaymentCount;
  DateTime? _completionDate;
  RepaymentStatus? _status;
  List<MonthlyDataPoint>? _schedule;

  void _calculate() {
    if (_formKey.currentState!.validate()) {
      final calculator = LoanCalculator(
        monthlyIncome: double.parse(_incomeController.text.replaceAll(',', '')),
        monthlyExpenses: double.parse(_expensesController.text.replaceAll(',', '')),
        intermediateThreshold: double.parse(_thresholdController.text.replaceAll(',', '')),
        annualInterestRate: double.parse(_annualInterestRateController.text) / 100.0,
        loanRepaymentType: _loanRepaymentType,
        remainingPrincipal: double.parse(_remainingPrincipalController.text.replaceAll(',', '')),
        remainingLoanTermInMonths: int.parse(_remainingTermController.text.replaceAll(',', '')),
      );

      final result = calculator.generateRepaymentSchedule();

      setState(() {
        _remainingMonths = result.totalMonths;
        _schedule = result.schedule;
        _totalInterestSaved = result.totalInterestSaved;
        _earlyRepaymentCount = result.earlyRepaymentCount;
        
        if (_remainingMonths != null && _remainingMonths! > 0) {
          _status = calculator.getStatus(_remainingMonths!);
          final now = DateTime.now();
          _completionDate = DateTime(now.year, now.month + _remainingMonths!);
        } else if (_remainingMonths == 0) {
          _completionDate = DateTime.now();
          _status = RepaymentStatus.low;
        } else {
          _completionDate = null;
          _status = null;
        }
      });
    }
  }

  Future<void> _shareScreenshot() async {
    try {
      final image = await _screenshotController.capture();
      if (image != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = await File('${directory.path}/loan_freedom_card.png').create();
        await imagePath.writeAsBytes(image);

        // Share the captured image
        await Share.shareXFiles(
          [XFile(imagePath.path)],
          text: '나의 대출 해방 로드맵! ✨ 아낀 이자만 ${_currencyFormat.format(_totalInterestSaved?.toInt() ?? 0)}원이네요!',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 생성 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('대출 상환 계산기', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('수입 및 지출'),
              _buildInputField(_incomeController, '월 고정 수익', suffix: '원'),
              _buildInputField(_expensesController, '월 고정 지출', suffix: '원'),
              _buildInputField(
                _thresholdController, 
                '중도상환 최소 저축액', 
                hint: '저축액이 이 금액을 넘으면 즉시 상환', 
                suffix: '원',
                description: '누적 저축액이 이 금액 이상 모이면, 이 금액만큼 중도상환해요.',
              ),
              
              const SizedBox(height: 32),
              _buildSectionTitle('대출 정보'),
              _buildInputField(_remainingPrincipalController, '남은 대출 원금', suffix: '원'),
              _buildInputField(_annualInterestRateController, '연 이자율', suffix: '%', isInt: false),
              _buildInputField(_remainingTermController, '남은 대출 기간', suffix: '개월', isInt: true),
              const SizedBox(height: 16),
              _buildLoanTypeSelector(),
              
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _calculate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('상환 시뮬레이션 시작', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              
              if (_remainingMonths != null) ...[
                const SizedBox(height: 48),
                _buildResultPanel(),
                const SizedBox(height: 48),
                _buildChart(),
                const SizedBox(height: 48),
                _buildRepaymentTable(),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
      ),
    );
  }

  Widget _buildLoanTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(child: _buildTypeButton(LoanRepaymentType.equalTotal, '원리금균등')),
          Expanded(child: _buildTypeButton(LoanRepaymentType.equalPrincipal, '원금균등')),
        ],
      ),
    );
  }

  Widget _buildTypeButton(LoanRepaymentType type, String label) {
    final isSelected = _loanRepaymentType == type;
    return GestureDetector(
      onTap: () => setState(() => _loanRepaymentType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade600,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label, {String? hint, String? suffix, bool isInt = false, String? description}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
          ),
          if (description != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(description, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, height: 1.4)),
            ),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              suffixText: suffix,
              suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              if (value.isEmpty) return;
              String plain = value.replaceAll(',', '');
              if (double.tryParse(plain) != null && label != '연 이자율') {
                 String formatted = _currencyFormat.format(double.parse(plain));
                 if (formatted != value) {
                   controller.text = formatted;
                   controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
                 }
              }
            },
            validator: (v) {
              if (v == null || v.isEmpty) return '값을 입력해주세요';
              String plain = v.replaceAll(',', '');
              if (double.tryParse(plain) == null || double.parse(plain) < 0) return '올바른 숫자를 입력하세요';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultPanel() {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (_status) {
      case RepaymentStatus.low:
        statusText = '상환의 신 (갓생 인증)';
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.auto_awesome;
        break;
      case RepaymentStatus.medium:
        statusText = '프로 상환러 (안정권)';
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.directions_run;
        break;
      default:
        statusText = '상환 꿈나무 (계획 필요)';
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.wb_sunny_outlined;
        break;
    }

    if (_remainingMonths == -1) {
      return Card(
        color: const Color(0xFFFEF2F2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Color(0xFFFEE2E2))),
        child: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 48),
              SizedBox(height: 16),
              Text('상환이 불가능한 구조입니다', style: TextStyle(color: Color(0xFF991B1B), fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('수입보다 지출 및 이자가 더 큽니다. 계획을 수정해주세요.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFB91C1C))),
            ],
          ),
        ),
      );
    }

    final years = _remainingMonths! ~/ 12;
    final months = _remainingMonths! % 12;
    String timeText = years > 0 ? '$years년 $months개월' : '$months개월';
    String dateText = _completionDate != null ? DateFormat('yyyy년 M월').format(_completionDate!) : '';

    return Column(
      children: [
        // 공유용 요약 카드
        Screenshot(
          controller: _screenshotController,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Icon(Icons.stars, size: 150, color: Colors.white.withOpacity(0.1)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        const Text('나의 대출 해방 예정일', style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Text(dateText, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white)),
                        const SizedBox(height: 8),
                        Text('앞으로 $timeText 남았습니다!', style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, color: Colors.white, size: 22),
                              const SizedBox(width: 8),
                              Text(statusText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // 생활 밀착형 비용 환산 (비유)
        _buildMetaphorSection(_totalInterestSaved ?? 0),
        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                '절약된 총 이자',
                '${_currencyFormat.format(_totalInterestSaved?.toInt() ?? 0)}원',
                const Color(0xFF10B981),
                Icons.trending_down,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                '중도상환 횟수',
                '${_earlyRepaymentCount ?? 0}회',
                const Color(0xFF6366F1),
                Icons.repeat,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: _shareScreenshot,
          icon: const Icon(Icons.download, size: 18),
          label: const Text('결과 카드 이미지로 저장하기', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildMetaphorSection(double savedAmount) {
    if (savedAmount <= 0) return const SizedBox.shrink();
    
    // 비유 아이템 정의
    final coffeeCount = (savedAmount / 4500).floor();
    final chickenCount = (savedAmount / 20000).floor();
    final phoneCount = (savedAmount / 1550000).floor();
    final tripCount = (savedAmount / 5000000).floor();

    String metaphorText = '';
    IconData metaphorIcon = Icons.celebration;
    
    if (tripCount >= 1) {
      metaphorText = '유럽 여행을 $tripCount번 다녀올 돈을 아꼈어요! ✈️';
      metaphorIcon = Icons.flight_takeoff;
    } else if (phoneCount >= 1) {
      metaphorText = '최신 아이폰을 $phoneCount대 살 수 있는 금액이에요! 📱';
      metaphorIcon = Icons.smartphone;
    } else if (chickenCount >= 1) {
      metaphorText = '치킨을 무려 $chickenCount마리나 더 먹을 수 있어요! 🍗';
      metaphorIcon = Icons.restaurant;
    } else {
      metaphorText = '커피를 $coffeeCount잔이나 아낀 셈이에요! ☕';
      metaphorIcon = Icons.coffee;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFEDD5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFDBA74).withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(metaphorIcon, color: const Color(0xFFEA580C), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('상환 시뮬레이션 결과,', style: TextStyle(fontSize: 13, color: Color(0xFF9A3412), fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(metaphorText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7C2D12))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('상환 시뮬레이션 그래프'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 1.5,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade100, strokeWidth: 1)),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: (_schedule!.length / 5).clamp(1, 100).toDouble())),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _schedule!.map((e) => FlSpot(e.month.toDouble(), e.remainingPrincipal)).toList(),
                          isCurved: true,
                          color: const Color(0xFFEF4444),
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: true, color: const Color(0xFFEF4444).withOpacity(0.05)),
                        ),
                        LineChartBarData(
                          spots: _schedule!.map((e) => FlSpot(e.month.toDouble(), e.savingsPot)).toList(),
                          isCurved: true,
                          color: const Color(0xFF3B82F6),
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: true, color: const Color(0xFF3B82F6).withOpacity(0.05)),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final isPrincipal = spot.bar.color == const Color(0xFFEF4444);
                              final title = isPrincipal ? '대출 잔액' : '저축액';
                              return LineTooltipItem(
                                '$title\n${_currencyFormat.format(spot.y)}원',
                                TextStyle(color: spot.bar.color, fontWeight: FontWeight.bold),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(const Color(0xFFEF4444), '대출 잔액'),
                    const SizedBox(width: 24),
                    _buildLegendItem(const Color(0xFF3B82F6), '저축 항아리'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
      ],
    );
  }

  Widget _buildRepaymentTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('월별 상세 내역'),
        Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)),
              dataTextStyle: const TextStyle(color: Color(0xFF1E293B)),
              horizontalMargin: 20,
              columnSpacing: 28,
              columns: const [
                DataColumn(label: Text('회차')),
                DataColumn(label: Text('저축액')),
                DataColumn(label: Text('누적 저축액')),
                DataColumn(label: Text('중도상환')),
                DataColumn(label: Text('원리금')),
                DataColumn(label: Text('원금')),
                DataColumn(label: Text('이자')),
                DataColumn(label: Text('대출잔액')),
              ],
              rows: [
                ..._schedule!.map((data) {
                  return DataRow(cells: [
                    DataCell(Text('${data.month}회')),
                    DataCell(Text(_currencyFormat.format(data.monthlySavings.toInt()))),
                    DataCell(Text(_currencyFormat.format(data.cumulativeSavings.toInt()))),
                    DataCell(Text(data.earlyRepaymentAmount > 0 ? _currencyFormat.format(data.earlyRepaymentAmount.toInt()) : '-')),
                    DataCell(Text(_currencyFormat.format(data.totalPayment.toInt()))),
                    DataCell(Text(_currencyFormat.format(data.principalPaid.toInt()))),
                    DataCell(Text(_currencyFormat.format(data.interestPaid.toInt()))),
                    DataCell(Text(_currencyFormat.format(data.balanceAfterRepayment.toInt()), style: const TextStyle(fontWeight: FontWeight.bold))),
                  ]);
                }),
                DataRow(
                  color: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                  cells: [
                    const DataCell(Text('합계', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text(_currencyFormat.format(_schedule!.fold<double>(0, (sum, item) => sum + item.monthlySavings).toInt()), style: const TextStyle(fontWeight: FontWeight.bold))),
                    const DataCell(Text('-')),
                    DataCell(Text(_currencyFormat.format(_schedule!.fold<double>(0, (sum, item) => sum + item.earlyRepaymentAmount).toInt()), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6366F1)))),
                    DataCell(Text(_currencyFormat.format(_schedule!.fold<double>(0, (sum, item) => sum + item.totalPayment).toInt()), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text(_currencyFormat.format(_schedule!.fold<double>(0, (sum, item) => sum + item.principalPaid).toInt()), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text(_currencyFormat.format(_schedule!.fold<double>(0, (sum, item) => sum + item.interestPaid).toInt()), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF4444)))),
                    const DataCell(Text('0', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
              ],
            ),
          ),
        ),
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