import 'dart:io';
import 'dart:math';
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
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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

  final _incomeFocus = FocusNode();
  final _expensesFocus = FocusNode();
  final _thresholdFocus = FocusNode();
  final _remainingPrincipalFocus = FocusNode();
  final _annualInterestRateFocus = FocusNode();
  final _remainingTermFocus = FocusNode();

  LoanRepaymentType _loanRepaymentType = LoanRepaymentType.equalTotal;

  int? _remainingMonths;
  double? _totalInterestSaved;
  int? _earlyRepaymentCount;
  DateTime? _completionDate;
  RepaymentStatus? _status;
  List<MonthlyDataPoint>? _schedule;

  Map<String, dynamic>? _selectedMetaphor;

  bool _isCalculating = false;

  void _calculate() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isCalculating = true;
        _remainingMonths = null;
        _selectedMetaphor = null;
      });

      // Brief delay for simulation feel
      await Future.delayed(const Duration(milliseconds: 300));

      final calculator = LoanCalculator(
        monthlyIncome: double.parse(_incomeController.text.replaceAll(',', '')),
        monthlyExpenses:
            double.parse(_expensesController.text.replaceAll(',', '')),
        intermediateThreshold:
            double.parse(_thresholdController.text.replaceAll(',', '')),
        annualInterestRate:
            double.parse(_annualInterestRateController.text) / 100.0,
        loanRepaymentType: _loanRepaymentType,
        remainingPrincipal: double.parse(
            _remainingPrincipalController.text.replaceAll(',', '')),
        remainingLoanTermInMonths:
            int.parse(_remainingTermController.text.replaceAll(',', '')),
      );

      final result = calculator.generateRepaymentSchedule();

      setState(() {
        _isCalculating = false;
        _remainingMonths = result.totalMonths;
        _schedule = result.schedule;
        _totalInterestSaved = result.totalInterestSaved;
        _earlyRepaymentCount = result.earlyRepaymentCount;

        if (_remainingMonths != null && _remainingMonths! > 0) {
          _status = calculator.getStatus(_remainingMonths!);
          final now = DateTime.now();
          _completionDate = DateTime(now.year, now.month + _remainingMonths!);
          _selectedMetaphor = _pickRandomMetaphor(_totalInterestSaved ?? 0);
        } else if (_remainingMonths == 0) {
          _completionDate = DateTime.now();
          _status = RepaymentStatus.level1;
          _selectedMetaphor = _pickRandomMetaphor(_totalInterestSaved ?? 0);
        } else {
          _completionDate = null;
          _status = null;
          _selectedMetaphor = null;
        }
      });
    }
  }

  Map<String, dynamic>? _pickRandomMetaphor(double savedAmount) {
    if (savedAmount <= 0) return null;

    final metaphors = [
      {'label': '커피를 {n}잔이나 아낀 셈이에요! ☕', 'price': 5000.0, 'icon': Icons.coffee},
      {'label': '치킨을 무려 {n}마리나 더 먹을 수 있어요! 🍗', 'price': 25000.0, 'icon': Icons.restaurant},
      {'label': '호텔 뷔페를 {n}번이나 즐길 수 있는 금액이에요! 🍽️', 'price': 150000.0, 'icon': Icons.dining},
      {'label': '최신 아이패드를 {n}대 살 수 있는 돈을 아꼈어요! 🍎', 'price': 1000000.0, 'icon': Icons.tablet_mac},
      {'label': '최신 아이폰 Pro를 {n}대 살 수 있는 금액이에요! 📱', 'price': 1600000.0, 'icon': Icons.smartphone},
      {'label': '최고급 안마의자를 {n}대 들여놓을 수 있어요! 💺', 'price': 5000000.0, 'icon': Icons.chair},
      {'label': '유럽 여행을 {n}번 다녀올 돈을 아꼈어요! ✈️', 'price': 10000000.0, 'icon': Icons.flight_takeoff},
      {'label': '명품 가방을 {n}개나 살 수 있는 큰 금액이에요! 👜', 'price': 12000000.0, 'icon': Icons.shopping_bag},
      {'label': '상태 좋은 경차를 {n}대 살 수 있는 금액이에요! 🚗', 'price': 18000000.0, 'icon': Icons.directions_car},
      {'label': '명품 시계를 {n}개나 장만할 수 있는 금액이에요! ⌚', 'price': 30000000.0, 'icon': Icons.watch},
      {'label': '패밀리 SUV를 {n}대 살 수 있는 엄청난 금액이에요! 🚙', 'price': 50000000.0, 'icon': Icons.airport_shuttle},
      {'label': '고급 세단을 {n}대 뽑을 수 있는 돈을 아꼈어요! 🚘', 'price': 85000000.0, 'icon': Icons.car_rental},
      {'label': '세계 일주 크루즈를 {n}번 즐길 수 있는 금액이에요! 🚢', 'price': 120000000.0, 'icon': Icons.directions_boat},
      {'label': '꿈의 스포츠카를 {n}대 살 수 있는 대단한 금액이에요! 🏎️', 'price': 200000000.0, 'icon': Icons.speed},
      {'label': '수도권 오피스텔 한 채를 {n}채 살 수 있는 돈이에요! 🏠', 'price': 280000000.0, 'icon': Icons.home_work},
    ];

    final available = metaphors.where((m) => savedAmount >= (m['price'] as double)).toList();
    if (available.isEmpty) return null;

    final random = Random();
    final chosen = available[random.nextInt(available.length)];
    final count = (savedAmount / (chosen['price'] as double)).floor();
    
    return {
      'text': (chosen['label'] as String).replaceFirst('{n}', count.toString()),
      'icon': chosen['icon'] as IconData,
    };
  }

  Future<void> _shareScreenshot() async {
    try {
      final image = await _screenshotController.capture();
      if (image != null) {
        final directory = await getTemporaryDirectory();
        final imagePath =
            await File('${directory.path}/loan_freedom_card.png').create();
        await imagePath.writeAsBytes(image);

        // Share the captured image
        await Share.shareXFiles(
          [XFile(imagePath.path)],
          text:
              '나의 대출 해방 로드맵! ✨ 아낀 이자만 ${_currencyFormat.format(_totalInterestSaved?.toInt() ?? 0)}원이네요!',
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_graph,
                  color: Color(0xFF6366F1), size: 24),
            ),
            const SizedBox(width: 12),
            const Text('대출 해방 D-day',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('수입 및 지출'),
              _buildInputField(
                _incomeController,
                '월 고정 수익',
                suffix: '원',
                focusNode: _incomeFocus,
                nextFocusNode: _expensesFocus,
              ),
              _buildInputField(
                _expensesController,
                '월 고정 지출',
                suffix: '원',
                focusNode: _expensesFocus,
                nextFocusNode: _thresholdFocus,
              ),
              _buildInputField(
                _thresholdController,
                '중도상환 최소 저축액',
                hint: '저축액이 이 금액을 넘으면 즉시 상환',
                suffix: '원',
                description: '누적 저축액이 이 금액 이상 모이면, 이 금액만큼 중도상환해요.',
                focusNode: _thresholdFocus,
                nextFocusNode: _remainingPrincipalFocus,
              ),
              const SizedBox(height: 32),
              _buildSectionTitle('대출 정보'),
              _buildInputField(
                _remainingPrincipalController,
                '남은 대출 원금',
                suffix: '원',
                focusNode: _remainingPrincipalFocus,
                nextFocusNode: _annualInterestRateFocus,
              ),
              _buildInputField(
                _annualInterestRateController,
                '연 이자율',
                suffix: '%',
                isInt: false,
                focusNode: _annualInterestRateFocus,
                nextFocusNode: _remainingTermFocus,
              ),
              _buildInputField(
                _remainingTermController,
                '남은 대출 기간',
                suffix: '개월',
                isInt: true,
                focusNode: _remainingTermFocus,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _calculate(),
              ),
              const SizedBox(height: 16),
              _buildLoanTypeSelector(),
              const SizedBox(height: 40),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                height: 64,
                child: ElevatedButton(
                  onPressed: _isCalculating ? null : _calculate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isCalculating
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 3))
                      : const Text('상환 시뮬레이션 시작',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.1),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                          parent: animation, curve: Curves.easeOutBack)),
                      child: child,
                    ),
                  );
                },
                child: _remainingMonths != null
                    ? Column(
                        key: ValueKey('results_$_remainingMonths'),
                        children: [
                          const SizedBox(height: 48),
                          _buildResultPanel(),
                          const SizedBox(height: 48),
                          _buildChart(),
                          const SizedBox(height: 48),
                          _buildRepaymentTable(),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
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
        style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B)),
      ),
    );
  }

  Widget _buildLoanTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
              child: _buildTypeButton(LoanRepaymentType.equalTotal, '원리금균등')),
          Expanded(
              child:
                  _buildTypeButton(LoanRepaymentType.equalPrincipal, '원금균등')),
        ],
      ),
    );
  }

  Widget _buildTypeButton(LoanRepaymentType type, String label) {
    final isSelected = _loanRepaymentType == type;
    return GestureDetector(
      onTap: () => setState(() => _loanRepaymentType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ]
              : null,
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

  Widget _buildInputField(
    TextEditingController controller,
    String label, {
    String? hint,
    String? suffix,
    bool isInt = false,
    String? description,
    FocusNode? focusNode,
    FocusNode? nextFocusNode,
    TextInputAction textInputAction = TextInputAction.next,
    void Function(String)? onFieldSubmitted,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700)),
          ),
          if (description != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(description,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500, height: 1.4)),
            ),
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            textInputAction: textInputAction,
            onFieldSubmitted: (value) {
              if (nextFocusNode != null) {
                FocusScope.of(context).requestFocus(nextFocusNode);
              }
              if (onFieldSubmitted != null) {
                onFieldSubmitted(value);
              }
            },
            decoration: InputDecoration(
              hintText: hint,
              suffixText: suffix,
              suffixStyle: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey),
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
              ),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              if (value.isEmpty) return;
              String plain = value.replaceAll(',', '');
              if (double.tryParse(plain) != null && label != '연 이자율') {
                String formatted = _currencyFormat.format(double.parse(plain));
                if (formatted != value) {
                  controller.text = formatted;
                  controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: controller.text.length));
                }
              }
            },
            validator: (v) {
              if (v == null || v.isEmpty) return '값을 입력해주세요';
              String plain = v.replaceAll(',', '');
              if (double.tryParse(plain) == null || double.parse(plain) < 0)
                return '올바른 숫자를 입력하세요';
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
      case RepaymentStatus.level1:
        statusText = '상환 완료 코앞 (초단기)';
        statusColor = const Color(0xFF10B981); // Emerald
        statusIcon = Icons.auto_awesome;
        break;
      case RepaymentStatus.level2:
        statusText = '곧 자유의 몸 (단기)';
        statusColor = const Color(0xFF22C55E); // Green
        statusIcon = Icons.sentiment_very_satisfied;
        break;
      case RepaymentStatus.level3:
        statusText = '자유를 향한 순항 (중단기)';
        statusColor = const Color(0xFF0EA5E9); // Light Blue
        statusIcon = Icons.sailing;
        break;
      case RepaymentStatus.level4:
        statusText = '안정적인 상환 중 (중기)';
        statusColor = const Color(0xFF3B82F6); // Blue
        statusIcon = Icons.trending_up;
        break;
      case RepaymentStatus.level5:
        statusText = '마라톤의 중반 (중장기)';
        statusColor = const Color(0xFF6366F1); // Indigo
        statusIcon = Icons.directions_run;
        break;
      case RepaymentStatus.level6:
        statusText = '장기전 돌입 (장기)';
        statusColor = const Color(0xFFF59E0B); // Amber
        statusIcon = Icons.timer;
        break;
      case RepaymentStatus.level7:
        statusText = '인생의 동반자 (초장기)';
        statusColor = const Color(0xFFF97316); // Orange
        statusIcon = Icons.favorite_border;
        break;
      case RepaymentStatus.level8:
        statusText = '먼 훗날의 약속 (기약 없음)';
        statusColor = const Color(0xFFEF4444); // Red
        statusIcon = Icons.wb_sunny_outlined;
        break;
      default:
        statusText = '계획 수립 필요';
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        break;
    }

    if (_remainingMonths == -1) {
      return Card(
        color: const Color(0xFFFEF2F2),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFFEE2E2))),
        child: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 48),
              SizedBox(height: 16),
              Text('상환이 불가능한 구조입니다',
                  style: TextStyle(
                      color: Color(0xFF991B1B),
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('수입보다 지출 및 이자가 더 큽니다. 계획을 수정해주세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFB91C1C))),
            ],
          ),
        ),
      );
    }

    final years = _remainingMonths! ~/ 12;
    final months = _remainingMonths! % 12;
    String timeText = years > 0 ? '$years년 $months개월' : '$months개월';
    String dateText = _completionDate != null
        ? DateFormat('yyyy년 M월').format(_completionDate!)
        : '';

    return Column(
      children: [
        Screenshot(
          controller: _screenshotController,
          child: Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFFF8FAFC),
            child: Column(
              children: [
                // 상단 요약 카드
                Container(
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
                          child: Icon(Icons.stars,
                              size: 150, color: Colors.white.withOpacity(0.1)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              const Text('나의 대출 해방 예정일',
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 12),
                              Text(dateText,
                                  style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white)),
                              const SizedBox(height: 8),
                              Text('앞으로 $timeText 남았습니다!',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 32),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(statusIcon,
                                        color: Colors.white, size: 22),
                                    const SizedBox(width: 8),
                                    Text(statusText,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16)),
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
                const SizedBox(height: 24),
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
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: _shareScreenshot,
          icon: const Icon(Icons.download, size: 18),
          label: const Text('결과 카드 이미지로 저장하기',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildMetaphorSection(double savedAmount) {
    if (_selectedMetaphor == null) return const SizedBox.shrink();

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
            decoration: BoxDecoration(
                color: const Color(0xFFFDBA74).withOpacity(0.2),
                shape: BoxShape.circle),
            child: Icon(_selectedMetaphor!['icon'],
                color: const Color(0xFFEA580C), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('상환 시뮬레이션 결과,',
                    style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9A3412),
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(_selectedMetaphor!['text'],
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7C2D12))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String label, String value, Color color, IconData icon) {
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
                Text(label,
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            Text(value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: color)),
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
                      gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) => FlLine(
                              color: Colors.grey.shade100, strokeWidth: 1)),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                interval: (_schedule!.length / 5)
                                    .clamp(1, 100)
                                    .toDouble())),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _schedule!
                              .map((e) => FlSpot(
                                  e.month.toDouble(), e.remainingPrincipal))
                              .toList(),
                          isCurved: true,
                          color: const Color(0xFFEF4444),
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                              show: true,
                              color: const Color(0xFFEF4444).withOpacity(0.05)),
                        ),
                        LineChartBarData(
                          spots: _schedule!
                              .map((e) =>
                                  FlSpot(e.month.toDouble(), e.savingsPot))
                              .toList(),
                          isCurved: true,
                          color: const Color(0xFF3B82F6),
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                              show: true,
                              color: const Color(0xFF3B82F6).withOpacity(0.05)),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final isPrincipal =
                                  spot.bar.color == const Color(0xFFEF4444);
                              final title = isPrincipal ? '대출 잔액' : '저축액';
                              return LineTooltipItem(
                                '$title\n${_currencyFormat.format(spot.y)}원',
                                TextStyle(
                                    color: spot.bar.color,
                                    fontWeight: FontWeight.bold),
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
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700)),
      ],
    );
  }

  Widget _buildRepaymentTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('월별 상세 내역'),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475569),
                    fontSize: 13),
                dataTextStyle:
                    const TextStyle(color: Color(0xFF1E293B), fontSize: 13),
                horizontalMargin: 12,
                columnSpacing: 18,
                columns: const [
                  DataColumn(label: Text('회차')),
                  DataColumn(label: Text('저축액')),
                  DataColumn(label: Text('중도상환')),
                  DataColumn(label: Text('원리금')),
                  DataColumn(label: Text('이자')),
                  DataColumn(label: Text('대출잔액')),
                ],
                rows: [
                  ..._schedule!.map((data) {
                    return DataRow(cells: [
                      DataCell(Text('${data.month}회')),
                      DataCell(Text(
                          _currencyFormat.format(data.monthlySavings.toInt()))),
                      DataCell(Text(data.earlyRepaymentAmount > 0
                          ? _currencyFormat
                              .format(data.earlyRepaymentAmount.toInt())
                          : '-')),
                      DataCell(Text(
                          _currencyFormat.format(data.totalPayment.toInt()))),
                      DataCell(Text(
                          _currencyFormat.format(data.interestPaid.toInt()))),
                      DataCell(Text(
                          _currencyFormat
                              .format(data.balanceAfterRepayment.toInt()),
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                    ]);
                  }),
                  DataRow(
                    color: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                    cells: [
                      const DataCell(Text('합계',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(
                          _currencyFormat.format(_schedule!
                              .fold<double>(
                                  0, (sum, item) => sum + item.monthlySavings)
                              .toInt()),
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(
                          _currencyFormat.format(_schedule!
                              .fold<double>(0,
                                  (sum, item) => sum + item.earlyRepaymentAmount)
                              .toInt()),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6366F1)))),
                      DataCell(Text(
                          _currencyFormat.format(_schedule!
                              .fold<double>(
                                  0, (sum, item) => sum + item.totalPayment)
                              .toInt()),
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(
                          _currencyFormat.format(_schedule!
                              .fold<double>(
                                  0, (sum, item) => sum + item.interestPaid)
                              .toInt()),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFEF4444)))),
                      const DataCell(Text('0',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                ],
              ),
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

    _incomeFocus.dispose();
    _expensesFocus.dispose();
    _thresholdFocus.dispose();
    _remainingPrincipalFocus.dispose();
    _annualInterestRateFocus.dispose();
    _remainingTermFocus.dispose();
    super.dispose();
  }
}
