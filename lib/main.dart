import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ButtonWidget.dart';

void main() {
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1C1C1C),
      ),
      home: const CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _expression = '';
  String _result = '0';
  bool _isResultCalculated = false; // Biến trạng thái mới

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  // --- Quản lý Trạng thái ---

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('expression', _expression);
    await prefs.setString('result', _result);
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _expression = prefs.getString('expression') ?? '';
      _result = prefs.getString('result') ?? '0';
    });
  }

  // --- Logic Tính Toán ---

  void _calculate() {
    if (_expression.isEmpty) {
      _result = '0';
      return;
    }

    String originalExpression =
        _expression; // Lưu lại phép tính gốc ở hàng trên , hiển thị kết quả ở bên dưới

    try {
      String finalExpression = _expression;
      finalExpression = finalExpression.replaceAll('×', '*');
      finalExpression = finalExpression.replaceAll('÷', '/');
      finalExpression = finalExpression.replaceAll('%', '/100');

      Parser p = Parser();
      Expression exp = p.parse(finalExpression);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);

      // Định dạng kết quả
      if (eval == eval.toInt()) {
        _result = eval.toInt().toString();
      } else {
        _result = eval.toString();
      }

      _expression = originalExpression;
      _isResultCalculated = true;
    } catch (e) {
      _result = 'Lỗi';
      _expression = originalExpression; // Giữ lại phép tính gốc khi có lỗi
    }
  }

  // Xử lý logic dấu ngoặc () nhận biết khi nào mở "(" và khi nào đóng ")"
  void _handleParenthesis() {
    if (_expression.endsWith('Lỗi') || _result == 'Lỗi') {
      _expression = '(';
      _result = '0';
      return;
    }
    int openParenCount = '('.allMatches(_expression).length;
    int closeParenCount = ')'.allMatches(_expression).length;
    String lastChar = _expression.isEmpty
        ? ''
        : _expression.substring(_expression.length - 1);
    // 1. Thêm ngoặc mở '('
    if (_expression.isEmpty || ['+', '-', '×', '÷', '('].contains(lastChar)) {
      _expression += '(';
    }
    // 2. Thêm ngoặc đóng ')'
    else if (RegExp(r'[0-9)]').hasMatch(lastChar) &&
        openParenCount > closeParenCount) {
      _expression += ')';
    }
    // 3. Tự động thêm phép nhân ngầm '×('
    else if (RegExp(r'[0-9)]').hasMatch(lastChar)) {
      _expression += '×(';
    }
  }

  // --- Xử lý Nút Bấm ---
  void _buttonPressed(String text) {
    setState(() {
      // LOGIC RESET: Xử lý khi nhấn nút sau khi đã tính toán
      if (_isResultCalculated) {
        // Nếu nhấn số hoặc ngoặc, bắt đầu phép tính mới
        if (RegExp(r'[0-9]').hasMatch(text) || text == '( )') {
          _expression = text;
          _result = '0';
        }
        // Nếu nhấn toán tử, tiếp tục phép tính với kết quả là số đầu tiên
        else if (['+', '-', '×', '÷', '%'].contains(text)) {
          _expression = _result + text;
        }
        _isResultCalculated = false; // Reset trạng thái tính toán
      }
      // Xử lý các nút chức năng đặc biệt
      if (text == 'C') {
        _expression = '';
        _result = '0';
        _isResultCalculated = false;
      } else if (text == '=') {
        _calculate();
      } else if (text == '( )') {
        _handleParenthesis();
      } else if (text == '+/-') {
        // Xử lý nút Đổi dấu +/-
        if (_expression.startsWith('-')) {
          _expression = _expression.substring(1);
        } else if (_expression.isNotEmpty && _expression != '0') {
          _expression = '-$_expression';
        }
        _result = _expression; // Cập nhật kết quả hiển thị theo biểu thức
      } else if (_expression.endsWith('Lỗi') || _result == 'Lỗi') {
        // Xử lý sau khi có lỗi
        _expression = text;
        _result = '0';
      }
      // Xử lý nối chuỗi thông thường
      else {
        // Nếu không phải là trạng thái tính toán (đã được xử lý ở trên), nối chuỗi
        if (!_isResultCalculated) {
          _expression += text;
        }
      }
    });
    _saveState();
  }

  // UI của máy tính
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          // Khu vực hiển thị kết quả
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.black,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Biểu thức hiện tại (hàng trên)
                  Padding(
                    padding: const EdgeInsets.only(
                      right: 18.0,
                      left: 18.0,
                      top: 18.0,
                    ),
                    child: Text(
                      _expression,
                      style: const TextStyle(color: Colors.grey, fontSize: 28),
                      textAlign: TextAlign.end,
                    ),
                  ),
                  // Kết quả (hàng dưới)
                  Padding(
                    padding: const EdgeInsets.only(
                      right: 18.0,
                      left: 18.0,
                      bottom: 18.0,
                    ),
                    child: Text(
                      _result,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 60,
                        fontWeight: FontWeight.w300,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Khu vực nút bấm
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.black,
              child: Column(
                children: [
                  _buildButtonRow(['C', '( )', '%', '÷']),
                  _buildButtonRow(['7', '8', '9', '×']),
                  _buildButtonRow(['4', '5', '6', '-']),
                  _buildButtonRow(['1', '2', '3', '+']),
                  _buildButtonRow(['+/-', '0', '.', '=']),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Hàm xây dựng một hàng nút bấm
  Widget _buildButtonRow(List<String> buttons) {
    // Tạo hàng nút bấm
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: buttons
            .map(
              (text) => Expanded(
                child: ButtonWidget(
                  text: text,
                  onPressed: () => _buttonPressed(text),
                  backgroundColor: _getButtonColor(text),
                  textColor: Colors.white,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Color _getButtonColor(String text) {
    // Xác định màu nút dựa vào chức năng
    switch (text) {
      case 'C':
        return const Color(0xFF963E3E);
      case '÷':
      case '×':
      case '-':
      case '+':
        return const Color(0xFF394734);
      case '=':
        return const Color(0xFF076544);
      case '( )':
      case '%':
      case '+/-':
      case '.':
      default:
        return const Color(0xFF272727);
    }
  }
}
