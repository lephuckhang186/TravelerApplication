import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../features/expense_management/presentation/providers/expense_provider.dart';
import '../features/expense_management/data/models/expense_models.dart';

/// Financial Center Screen - Màn hình Trung Tâm Tài Chính
class FinancialCenterScreen extends StatefulWidget {
  const FinancialCenterScreen({super.key});

  @override
  State<FinancialCenterScreen> createState() => _FinancialCenterScreenState();
}

class _FinancialCenterScreenState extends State<FinancialCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ExpenseProvider _expenseProvider;
  bool _isAmountVisible = true;
  final String _selectedPeriod = '7 ngày'; // Mặc định hiển thị 7 ngày

  // Dữ liệu mẫu cho biểu đồ
  final List<Map<String, dynamic>> _weeklyData = [
    {'day': 'T2', 'income': 2500, 'expense': 1200, 'date': '27/10'},
    {'day': 'T3', 'income': 1800, 'expense': 800, 'date': '28/10'},
    {'day': 'T4', 'income': 3200, 'expense': 1500, 'date': '29/10'},
    {'day': 'T5', 'income': 1500, 'expense': 2200, 'date': '30/10'},
    {'day': 'T6', 'income': 4100, 'expense': 1800, 'date': '31/10'},
    {'day': 'T7', 'income': 2800, 'expense': 1300, 'date': '01/11'},
    {'day': 'CN', 'income': 1900, 'expense': 900, 'date': '02/11'},
  ];

  final List<Map<String, dynamic>> _monthlyData = [
    {'day': 'T1', 'income': 45000, 'expense': 32000, 'date': 'Tuần 1'},
    {'day': 'T2', 'income': 52000, 'expense': 28000, 'date': 'Tuần 2'},
    {'day': 'T3', 'income': 38000, 'expense': 41000, 'date': 'Tuần 3'},
    {'day': 'T4', 'income': 63000, 'expense': 35000, 'date': 'Tuần 4'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _expenseProvider = ExpenseProvider();
    _loadData();
  }

  void _loadData() {
    _expenseProvider.fetchBudgetStatus();
    _expenseProvider.fetchExpenseSummary();
    _expenseProvider.refreshAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _expenseProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Gradient nền: Tím hồng nhạt → Trắng/xanh nhạt
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF3E5F5), // Tím hồng nhạt
              const Color(0xFFE1F5FE), // Xanh nhạt
              Colors.white,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header với tiêu đề "Tổng Quan"
              _buildHeader(),
              // Tabs: Tài sản và Phải trả
              _buildTabs(),
              // Nội dung tab - chỉ hiển thị tab Tài sản
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildAssetsTab()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Header với tiêu đề "Tổng Quan"
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tổng Quan',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Quản lý tài chính cá nhân hiệu quả',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Tabs: Tài sản và Phải trả
  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 0),
      // Không có nền cho container (trong suốt)
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white, // Nền trắng khi được chọn
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
            bottomLeft: Radius.zero,
            bottomRight: Radius.zero,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize:
            TabBarIndicatorSize.tab, // Indicator chỉ bao quanh tab được chọn
        dividerColor: Colors.transparent, // Ẩn divider
        labelColor: const Color(0xFFE91E63), // Hồng đậm cho text khi selected
        unselectedLabelColor:
            Colors.black87, // Màu đen cho text khi chưa selected
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 16,
        ),
        tabs: const [
          Tab(text: 'Tài sản'),
        ],
      ),
    );
  }

  /// Tab Tài sản
  Widget _buildAssetsTab() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 16),
      child: Transform.translate(
        offset: const Offset(0, -8), // Kết nối card với tab
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card hiển thị tài sản - kết nối trực tiếp với tab
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.zero,
                    topRight: Radius.zero,
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tài sản của bạn',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        IconButton(
                          icon: Icon(
                            _isAmountVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _isAmountVisible = !_isAmountVisible;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AnimatedBuilder(
                      animation: _expenseProvider,
                      builder: (context, child) {
                        if (_expenseProvider.isSummaryLoading) {
                          return const SizedBox(
                            height: 32,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        
                        final summary = _expenseProvider.expenseSummary;
                        final totalAssets = summary != null ? summary.totalAmount : 0.0;
                        
                        return Text(
                          _isAmountVisible ? '${_formatMoney(totalAssets)}₫' : '•••••',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'So với 08:34 - 02/11/2025',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          '--',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        _showIncomeExpenseDialog();
                      },
                      child: const Row(
                        children: [
                          Text(
                            'Bấm để xem chi tiết',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFFE91E63),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: Color(0xFFE91E63),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Card hạn mức chi
              _buildSpendingLimitCard(),
              const SizedBox(height: 16),
              // Card du lịch thông minh AI
              _buildSmartTravelCard(),
              const SizedBox(height: 24), // Thêm đệm dưới để tránh bị che bởi navbar
            ],
          ),
        ),
      ),
    );
  }

  /// Card hạn mức chi
  Widget _buildSpendingLimitCard() {
    return AnimatedBuilder(
      animation: _expenseProvider,
      builder: (context, child) {
        if (_expenseProvider.isBudgetLoading) {
          return Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final budgetStatus = _expenseProvider.budgetStatus;
        
        // Default values if no budget data
        final double monthlyLimit = budgetStatus?.totalBudget ?? 15000.0;
        final double currentSpent = budgetStatus?.totalSpent ?? 0.0;
        final double remainingLimit = budgetStatus?.remainingBudget ?? monthlyLimit;
        final double progressPercentage = budgetStatus?.percentageUsed ?? 0.0;
        
        return _buildSpendingLimitContent(monthlyLimit, currentSpent, remainingLimit, progressPercentage);
      },
    );
  }

  Widget _buildSpendingLimitContent(double monthlyLimit, double currentSpent, double remainingLimit, double progressPercentage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Hạn mức chi tháng này',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(
                Icons.credit_card,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isAmountVisible ? '${_formatMoney(currentSpent)}₫' : '•••••',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: progressPercentage > 80 
                          ? const Color(0xFFE91E63) 
                          : progressPercentage > 60
                              ? const Color(0xFFFF9800)
                              : const Color(0xFF4CAF50),
                    ),
                  ),
                  Text(
                    _isAmountVisible ? '/ ${_formatMoney(monthlyLimit)}₫' : '/ •••••',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Progress bar
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Stack(
                  children: [
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 800),
                      height: 8,
                      width: (MediaQuery.of(context).size.width - 72) * (currentSpent / monthlyLimit),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: progressPercentage > 80
                              ? [const Color(0xFFE91E63), const Color(0xFFE91E63).withValues(alpha: 0.8)]
                              : progressPercentage > 60
                                  ? [const Color(0xFFFF9800), const Color(0xFFFF9800).withValues(alpha: 0.8)]
                                  : [const Color(0xFF4CAF50), const Color(0xFF4CAF50).withValues(alpha: 0.8)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${progressPercentage.toStringAsFixed(1)}% đã sử dụng',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    _isAmountVisible 
                        ? 'Còn lại: ${_formatMoney(remainingLimit)}₫'
                        : 'Còn lại: •••••',
                    style: TextStyle(
                      fontSize: 12,
                      color: remainingLimit > 0 
                          ? const Color(0xFF4CAF50) 
                          : const Color(0xFFE91E63),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Action button
          GestureDetector(
            onTap: () {
              _showSpendingLimitDialog();
            },
            child: Row(
              children: [
                const Text(
                  'Quản lý hạn mức',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFE91E63),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.settings,
                  color: Color(0xFFE91E63),
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Dialog quản lý hạn mức chi
  void _showSpendingLimitDialog() {
    double currentLimit = 15000.0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.95,
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Quản lý Hạn mức Chi',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hạn mức hiện tại',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_formatMoney(currentLimit)}₫ / tháng',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE91E63),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Gợi ý hạn mức phổ biến:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [5000.0, 10000.0, 15000.0, 20000.0, 30000.0, 50000.0]
                          .map((amount) {
                        final bool selected = currentLimit == amount;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              currentLimit = amount;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: selected ? const Color(0xFFE91E63) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFFE91E63)
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Text(
                              '${_formatMoney(amount)}₫',
                              style: TextStyle(
                                fontSize: 14,
                                color: selected ? Colors.white : Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Hoặc nhập số tiền tùy chỉnh:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Nhập số tiền (VND)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        prefixText: '₫ ',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final amount = double.tryParse(value.replaceAll(',', ''));
                        if (amount != null) {
                          setDialogState(() {
                            currentLimit = amount;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Hủy',
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              // Update spending limit functionality
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE91E63),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Lưu',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Card gợi ý AI đơn giản
  Widget _buildSmartTravelCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF7A00),
            Color(0xFFFF9E00),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 24,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(width: 16),
          
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gợi ý AI hôm nay',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Hỏi chatbot để lên kế hoạch du lịch thông minh',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          
          const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.white70,
          ),
        ],
      ),
    );
  }



  /// Format tiền tệ
  String _formatMoney(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  /// Format tiền tệ cho biểu đồ
  String _formatChartMoney(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(0)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }

  /// Dialog hiển thị tình hình thu chi chi tiết
  void _showIncomeExpenseDialog() {
    String dialogPeriod = _selectedPeriod;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Use real data from backend
          final summary = _expenseProvider.expenseSummary;
          final spendingTrends = _expenseProvider.spendingTrends;
          
          // For now, use mock data structure but with real totals
          final data = dialogPeriod == '7 ngày' ? _weeklyData : _monthlyData;
          final totalExpense = summary?.totalAmount ?? 0.0;
          final totalIncome = totalExpense * 1.2; // Mock income as 20% more than expenses
          final balance = totalIncome - totalExpense;

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              padding: const EdgeInsets.all(20),
              // Use a fixed max height and internal Expanded widgets for layout and scrolling
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header với dropdown
                  Row(
                    children: [
                      const Text(
                        'Tình hình Thu Chi',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: dialogPeriod,
                            isDense: true,
                            items: ['7 ngày', 'Tháng'].map((period) {
                              return DropdownMenuItem(
                                value: period,
                                child: Text(
                                  period,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setDialogState(() {
                                dialogPeriod = value!;
                              });
                            },
                            icon: const Icon(Icons.arrow_drop_down, size: 20),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Content layout: Chart bên trái, Categories bên phải
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Biểu đồ cột bên trái (nhỏ hơn)
                        Expanded(
                          flex: 2,
                          child: _buildCompactChart(data),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Categories bên phải
                        Expanded(
                          flex: 3,
                          child: _buildCategoryList(totalIncome, totalExpense, balance),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Biểu đồ cột compact cho dialog
  Widget _buildCompactChart(List<Map<String, dynamic>> data) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          const Text(
            'Biểu đồ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: data.map((e) => [e['income'], e['expense']]).expand((e) => e).reduce((a, b) => a > b ? a : b).toDouble() * 1.2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < data.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              data[index]['day'],
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          _formatChartMoney(value),
                          style: const TextStyle(
                            fontSize: 8,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[300],
                      strokeWidth: 0.5,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: data.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: item['income'].toDouble(),
                        color: const Color(0xFF4CAF50),
                        width: 8,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                      ),
                      BarChartRodData(
                        toY: item['expense'].toDouble(),
                        color: const Color(0xFFE91E63),
                        width: 8,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                      ),
                    ],
                    barsSpace: 2,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCompactLegendItem('Thu', const Color(0xFF4CAF50)),
              const SizedBox(width: 12),
              _buildCompactLegendItem('Chi', const Color(0xFFE91E63)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  /// Danh sách categories cho dialog
  Widget _buildCategoryList(double totalIncome, double totalExpense, double balance) {
    final summary = _expenseProvider.expenseSummary;
    final categoryBreakdown = summary?.categoryBreakdown ?? <String, double>{};
    
    // Convert backend category data to display format
    final expenseSubcategories = categoryBreakdown.entries.map((entry) {
      return {
        'name': _getCategoryDisplayName(entry.key),
        'amount': entry.value,
      };
    }).toList();
    
    final categories = [
      {
        'title': 'Tổng Thu Nhập',
        'amount': totalIncome,
        'color': const Color(0xFF4CAF50),
        'icon': Icons.arrow_downward,
        'subcategories': [
          {'name': 'Lương cơ bản', 'amount': totalIncome * 0.7},
          {'name': 'Thu nhập phụ', 'amount': totalIncome * 0.2},
          {'name': 'Đầu tư', 'amount': totalIncome * 0.1},
        ]
      },
      {
        'title': 'Tổng Chi Phí',
        'amount': totalExpense,
        'color': const Color(0xFFE91E63),
        'icon': Icons.arrow_upward,
        'subcategories': expenseSubcategories.isNotEmpty ? expenseSubcategories : [
          {'name': 'Chưa có dữ liệu', 'amount': 0.0},
        ]
      },
      {
        'title': 'Tích Lũy',
        'amount': balance,
        'color': balance >= 0 ? const Color(0xFF2196F3) : const Color(0xFFFF9800),
        'icon': balance >= 0 ? Icons.trending_up : Icons.trending_down,
        'subcategories': []
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categories',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: categories.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final category = categories[index];
              return _buildCategoryCard(category);
            },
          ),
        ),
      ],
    );
  }

  /// Card hiển thị category
  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header của category
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (category['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  category['icon'] as IconData,
                  size: 16,
                  color: category['color'] as Color,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category['title'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatMoney(category['amount'] as double)}₫',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: category['color'] as Color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Subcategories nếu có
          if ((category['subcategories'] as List).isNotEmpty) ...[
            const SizedBox(height: 8),
            ...((category['subcategories'] as List).map((sub) {
              return Padding(
                padding: const EdgeInsets.only(left: 30, top: 4),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sub['name'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    Text(
                      '${_formatMoney(sub['amount'] as double)}₫',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              );
            }).toList()),
          ],
        ],
      ),
    );
  }

  /// Get category display name from string key
  String _getCategoryDisplayName(String categoryKey) {
    try {
      final category = ExpenseCategoryExtension.fromString(categoryKey);
      return category.displayName;
    } catch (e) {
      return categoryKey;
    }
  }
}

