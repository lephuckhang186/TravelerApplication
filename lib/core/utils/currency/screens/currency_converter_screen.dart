import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_theme.dart';
import '../models/currency_models.dart';
import '../services/currency_service.dart';

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() =>
      _CurrencyConverterScreenState();
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
      CurvedAnimation(
        parent: _swapAnimationController,
        curve: Curves.easeInOut,
      ),
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
      backgroundColor: const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.skyBlue.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: AppColors.dodgerBlue, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.skyBlue.withValues(alpha: 0.15),
                AppColors.dodgerBlue.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.skyBlue.withValues(alpha: 0.9),
                      AppColors.steelBlue.withValues(alpha: 0.8),
                      AppColors.dodgerBlue.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.currency_exchange_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Currency Exchange',
                style: TextStyle(
                  fontFamily: 'Urbanist-Regular',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1D2E),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.skyBlue.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: _isLoading 
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.dodgerBlue),
                      ),
                    )
                  : Icon(Icons.refresh_rounded, color: AppColors.dodgerBlue),
              onPressed: _isLoading ? null : _loadExchangeRate,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 80, 20, 20),
        child: Column(
          children: [
            _buildCurrencySelector(),
            const SizedBox(height: 24),
            _buildAmountInput(),
            const SizedBox(height: 20),
            _buildResultCard(),
            const SizedBox(height: 20),
            _buildExchangeRateInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencySelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.skyBlue.withValues(alpha: 0.08),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildCurrencyButton(_fromCurrency, true)),
          const SizedBox(width: 12),
          AnimatedBuilder(
            animation: _swapAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _swapAnimation.value * 3.14159,
                child: GestureDetector(
                  onTap: _swapCurrencies,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.skyBlue.withValues(alpha: 0.9),
                          AppColors.steelBlue.withValues(alpha: 0.8),
                          AppColors.dodgerBlue.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.skyBlue.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.swap_horiz_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(child: _buildCurrencyButton(_toCurrency, false)),
        ],
      ),
    );
  }

  Widget _buildCurrencyButton(Currency currency, bool isFrom) {
    return GestureDetector(
      onTap: () => _showCurrencyPicker(isFrom),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.skyBlue.withValues(alpha: 0.05),
              AppColors.dodgerBlue.withValues(alpha: 0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.skyBlue.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.skyBlue.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(currency.flag, style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    currency.code,
                    style: const TextStyle(
                      fontFamily: 'Urbanist-Regular',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1D2E),
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.dodgerBlue,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Text(
                currency.name,
                style: TextStyle(
                  fontFamily: 'Urbanist-Regular',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.steelBlue.withValues(alpha: 0.6),
                ),
                overflow: TextOverflow.ellipsis,
              ),
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
            color: Colors.grey.withValues(alpha: 0.1),
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
            style: TextStyle(fontFamily: 'Urbanist-Regular', 
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
                style: TextStyle(
                  fontFamily: 'Urbanist-Regular',
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dodgerBlue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: TextStyle(fontFamily: 'Urbanist-Regular', 
                      color: Colors.grey[400],
                      fontSize: 24,
                    ),
                    border: InputBorder.none,
                  ),
                  style: TextStyle(fontFamily: 'Urbanist-Regular', 
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.skyBlue.withValues(alpha: 0.08),
            AppColors.dodgerBlue.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.skyBlue.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.skyBlue.withValues(alpha: 0.2),
                      AppColors.dodgerBlue.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.currency_exchange_rounded,
                  color: AppColors.dodgerBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Kết quả chuyển đổi',
                style: TextStyle(
                  fontFamily: 'Urbanist-Regular',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.steelBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                _toCurrency.symbol,
                style: TextStyle(
                  fontFamily: 'Urbanist-Regular',
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dodgerBlue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _currencyService
                      .formatCurrency(_convertedAmount, _toCurrency)
                      .replaceFirst(_toCurrency.symbol, ''),
                  style: TextStyle(
                    fontFamily: 'Urbanist-Regular',
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dodgerBlue,
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
              style: TextStyle(fontFamily: 'Urbanist-Regular', 
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
            color: Colors.grey.withValues(alpha: 0.1),
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
                style: TextStyle(fontFamily: 'Urbanist-Regular', 
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
                style: TextStyle(fontFamily: 'Urbanist-Regular', 
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '1 ${_fromCurrency.code} = ${_exchangeRate.toStringAsFixed(4)} ${_toCurrency.code}',
                style: TextStyle(fontFamily: 'Urbanist-Regular', 
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
                style: TextStyle(fontFamily: 'Urbanist-Regular', 
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                style: TextStyle(fontFamily: 'Urbanist-Regular', 
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
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi tải tỷ giá: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi chuyển đổi: $e')));
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
                style: TextStyle(fontFamily: 'Urbanist-Regular', 
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
                      leading: Text(
                        currency.flag,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Row(
                        children: [
                          Text(
                            currency.code,
                            style: TextStyle(fontFamily: 'Urbanist-Regular', 
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            currency.symbol,
                            style: TextStyle(
                              fontFamily: 'Urbanist-Regular',
                              color: AppColors.dodgerBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        '${currency.name} • ${currency.country}',
                        style: TextStyle(fontFamily: 'Urbanist-Regular', 
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded, color: AppColors.dodgerBlue)
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
}
