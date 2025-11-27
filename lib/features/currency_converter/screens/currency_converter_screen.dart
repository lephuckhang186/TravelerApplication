import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../models/currency_models.dart';
import '../services/currency_service.dart';

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() => _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen>
    with TickerProviderStateMixin {
  final TextEditingController _amountController = TextEditingController();
  final CurrencyService _currencyService = CurrencyService();
  
  Currency _fromCurrency = Currency.popularCurrencies[0]; // VND
  Currency _toCurrency = Currency.popularCurrencies[1]; // USD
  
  bool _isLoading = false;
  double _convertedAmount = 0.0;
  double _exchangeRate = 0.0;
  List<ConversionResult> _history = [];
  
  late AnimationController _swapAnimationController;
  late Animation<double> _swapAnimation;

  @override
  void initState() {
    super.initState();
    _swapAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _swapAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _swapAnimationController, curve: Curves.easeInOut),
    );
    _loadExchangeRate();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _swapAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Chuyển đổi tiền tệ',
          style: GoogleFonts.quattrocento(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.black54),
            onPressed: _showHistory,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: _loadExchangeRate,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildCurrencySelector(),
                  const SizedBox(height: 16),
                  _buildAmountInput(),
                  const SizedBox(height: 16),
                  _buildResultCard(),
                  const SizedBox(height: 16),
                  _buildExchangeRateInfo(),
                  const SizedBox(height: 16),
                  _buildQuickAmounts(),
                ],
              ),
            ),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildCurrencySelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildCurrencyButton(_fromCurrency, true),
          ),
          const SizedBox(width: 16),
          AnimatedBuilder(
            animation: _swapAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _swapAnimation.value * 3.14159,
                child: GestureDetector(
                  onTap: _swapCurrencies,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B61FF),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.swap_horiz,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildCurrencyButton(_toCurrency, false),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyButton(Currency currency, bool isFrom) {
    return GestureDetector(
      onTap: () => _showCurrencyPicker(isFrom),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(currency.flag, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    currency.code,
                    style: GoogleFonts.quattrocento(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: Colors.grey[600], size: 18),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              currency.name,
              style: GoogleFonts.quattrocento(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Số tiền cần chuyển đổi',
            style: GoogleFonts.quattrocento(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                _fromCurrency.symbol,
                style: GoogleFonts.quattrocento(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7B61FF),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: GoogleFonts.quattrocento(
                      color: Colors.grey[400],
                      fontSize: 24,
                    ),
                    border: InputBorder.none,
                  ),
                  style: GoogleFonts.quattrocento(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  onChanged: (value) {
                    _convertCurrency();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF7B61FF).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF7B61FF).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.currency_exchange, color: const Color(0xFF7B61FF), size: 20),
              const SizedBox(width: 8),
              Text(
                'Kết quả chuyển đổi',
                style: GoogleFonts.quattrocento(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7B61FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                _toCurrency.symbol,
                style: GoogleFonts.quattrocento(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF7B61FF),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _currencyService.formatCurrency(_convertedAmount, _toCurrency)
                      .replaceFirst(_toCurrency.symbol, ''),
                  style: GoogleFonts.quattrocento(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF7B61FF),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (_exchangeRate > 0) ...[
            const SizedBox(height: 8),
            Text(
              '1 ${_fromCurrency.code} = ${_exchangeRate.toStringAsFixed(4)} ${_toCurrency.code}',
              style: GoogleFonts.quattrocento(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExchangeRateInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Thông tin tỷ giá',
                style: GoogleFonts.quattrocento(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tỷ giá hiện tại:',
                style: GoogleFonts.quattrocento(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '1 ${_fromCurrency.code} = ${_exchangeRate.toStringAsFixed(4)} ${_toCurrency.code}',
                style: GoogleFonts.quattrocento(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cập nhật lúc:',
                style: GoogleFonts.quattrocento(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                style: GoogleFonts.quattrocento(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmounts() {
    final quickAmounts = [100, 500, 1000, 5000, 10000, 50000];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Số tiền thông dụng',
            style: GoogleFonts.quattrocento(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickAmounts.map((amount) => 
              _buildQuickAmountChip(amount)
            ).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountChip(int amount) {
    return GestureDetector(
      onTap: () {
        _amountController.text = amount.toString();
        _convertCurrency();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF7B61FF).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF7B61FF).withOpacity(0.3)),
        ),
        child: Text(
          '${_fromCurrency.symbol}$amount',
          style: GoogleFonts.quattrocento(
            fontSize: 12,
            color: const Color(0xFF7B61FF),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                _amountController.clear();
                setState(() {
                  _convertedAmount = 0.0;
                });
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey[300]!),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Xóa',
                style: GoogleFonts.quattrocento(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _convertCurrency,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B61FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Chuyển đổi',
                      style: GoogleFonts.quattrocento(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadExchangeRate() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final rate = await _currencyService.getExchangeRate(
        _fromCurrency.code,
        _toCurrency.code,
      );
      
      setState(() {
        _exchangeRate = rate;
      });
      
      if (_amountController.text.isNotEmpty) {
        _convertCurrency();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải tỷ giá: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _convertCurrency() async {
    if (_amountController.text.isEmpty) {
      setState(() {
        _convertedAmount = 0.0;
      });
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null) return;

    try {
      final result = await _currencyService.convertCurrency(
        amount: amount,
        fromCurrency: _fromCurrency,
        toCurrency: _toCurrency,
      );

      setState(() {
        _convertedAmount = result.convertedAmount;
        _exchangeRate = result.exchangeRate;
        _history = [result, ..._history.take(19).toList()]; // Keep last 20
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi chuyển đổi: $e')),
      );
    }
  }

  void _swapCurrencies() {
    _swapAnimationController.forward().then((_) {
      setState(() {
        final temp = _fromCurrency;
        _fromCurrency = _toCurrency;
        _toCurrency = temp;
      });
      _swapAnimationController.reset();
      _loadExchangeRate();
    });
  }

  void _showCurrencyPicker(bool isFrom) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Chọn tiền tệ',
                style: GoogleFonts.quattrocento(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: Currency.popularCurrencies.length,
                  itemBuilder: (context, index) {
                    final currency = Currency.popularCurrencies[index];
                    final isSelected = isFrom 
                        ? currency.code == _fromCurrency.code
                        : currency.code == _toCurrency.code;
                    
                    return ListTile(
                      leading: Text(currency.flag, style: const TextStyle(fontSize: 24)),
                      title: Row(
                        children: [
                          Text(
                            currency.code,
                            style: GoogleFonts.quattrocento(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            currency.symbol,
                            style: GoogleFonts.quattrocento(
                              color: const Color(0xFF7B61FF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        '${currency.name} • ${currency.country}',
                        style: GoogleFonts.quattrocento(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      trailing: isSelected 
                          ? Icon(Icons.check, color: const Color(0xFF7B61FF))
                          : null,
                      onTap: () {
                        setState(() {
                          if (isFrom) {
                            _fromCurrency = currency;
                          } else {
                            _toCurrency = currency;
                          }
                        });
                        Navigator.pop(context);
                        _loadExchangeRate();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHistory() {
    if (_history.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có lịch sử chuyển đổi')),
      );
      return;
    }
    // Show history implementation
  }
}