import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../../core/theme/app_theme.dart';
import 'presentation/providers/expense_provider.dart';
import 'data/models/expense_models.dart';
import '../../services/auth_service.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> with TickerProviderStateMixin {
  int _currentViewIndex = 0; // 0: Activities, 1: Statistic
  int _currentMonthIndex = DateTime.now().month - 1; // Current month (0-based)
  int _currentYear = DateTime.now().year;
  int _chartTypeIndex = 0; // 0: Pie chart, 1: Bar chart
  int _categoryTabIndex = 0; // 0: Subcategory, 1: Category
  int? _selectedBarIndex; // Index of selected bar in chart

  late TabController _mainTabController;
  late TabController _categoryTabController;
  late ExpenseProvider _expenseProvider;

  final List<String> _months = [
    'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4', 'Tháng 5', 'Tháng 6',
    'Tháng 7', 'Tháng 8', 'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12'
  ];

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _categoryTabController = TabController(length: 2, vsync: this);
    _expenseProvider = ExpenseProvider();
    _initializeWithAuth();
  }

  /// Initialize with authentication and load data
  Future<void> _initializeWithAuth() async {
    try {
      final authService = AuthService();
      final token = await authService.getIdToken();
      
      if (token != null) {
        _expenseProvider.setAuthToken(token);
        await _loadData();
      } else {
        // User not authenticated, redirect to auth screen
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/auth');
        }
      }
    } catch (e) {
      print('Error initializing with auth: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Load data from backend
  Future<void> _loadData() async {
    // Get current month date range
    final currentDate = DateTime(_currentYear, _currentMonthIndex + 1, 1);
    final startDate = DateTime(currentDate.year, currentDate.month, 1);
    final endDate = DateTime(currentDate.year, currentDate.month + 1, 0);
    
    await Future.wait([
      _expenseProvider.fetchExpenses(
        startDate: startDate,
        endDate: endDate,
      ),
      _expenseProvider.fetchExpenseSummary(),
      _expenseProvider.fetchCategoryStatus(),
      _expenseProvider.fetchSpendingTrends(),
    ]);
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _categoryTabController.dispose();
    _expenseProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header với search và buttons
            _buildHeader(),
            
            // Main tabs (Activities/Statistic)
            _buildMainTabs(),
            
            // Content
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  /// Header with search and filter buttons
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Search field
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.support),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Search for transactions',
                      style: GoogleFonts.quattrocento(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Filter button
          MouseRegion(
            onEnter: (_) => setState(() {}),
            onExit: (_) => setState(() {}),
            child: GestureDetector(
              onTap: () => _onFilterTap(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.filter_alt_outlined,
                    color: Colors.grey[700],
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          // Grid button (4 squares)
          MouseRegion(
            onEnter: (_) => setState(() {}),
            onExit: (_) => setState(() {}),
            child: GestureDetector(
              onTap: () => _onGridTap(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.grid_view,
                    color: Colors.grey[700],
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Main tabs (Activities/Statistic)
  Widget _buildMainTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildTabButton('Activities', 0, Icons.access_time),
          const SizedBox(width: 12),
          _buildTabButton('Statistic', 1, Icons.bar_chart),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index, IconData icon) {
    final isSelected = _currentViewIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabChanged(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.support : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.black87 : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.quattrocento(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.black87 : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Content based on selected tab
  Widget _buildContent() {
    if (_currentViewIndex == 0) {
      return _buildActivitiesContent();
    } else {
      return _buildStatisticContent();
    }
  }

  /// Activities content (Calendar view)
  Widget _buildActivitiesContent() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Month selector
          _buildMonthSelector(),
          const SizedBox(height: 16),
          
          // Calendar or list view
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  // Calendar grid - expanded to show full calendar
                  Expanded(
                    flex: 3,
                    child: _buildCalendarView(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Expense list - takes remaining space
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      child: _buildExpenseList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Statistic content (Charts)
  Widget _buildStatisticContent() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Month selector
          _buildMonthSelector(),
          const SizedBox(height: 16),
          
          // Chart container
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  // Chart area
                  Expanded(
                    flex: _chartTypeIndex == 0 ? 2 : 3,
                    child: _chartTypeIndex == 0 ? _buildPieChart() : _buildBarChart(),
                  ),
                  
                  // Only show category tabs and list for pie chart
                  if (_chartTypeIndex == 0) ...[
                    const SizedBox(height: 16),
                    
                    // Category tabs
                    _buildCategoryTabs(),
                    
                    const SizedBox(height: 16),
                    
                    // Category list
                    Expanded(
                      child: _buildCategoryList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Month selector with arrows
  Widget _buildMonthSelector() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => _changeMonth(-1),
          child: AnimatedScale(
            scale: 1.0,
            duration: const Duration(milliseconds: 150),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.chevron_left, color: Colors.grey[700]),
            ),
          ),
        ),
        const SizedBox(width: 8),
        
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Text(
                  '${_months[_currentMonthIndex]}/$_currentYear',
                  style: GoogleFonts.quattrocento(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _changeMonth(1),
          child: AnimatedScale(
            scale: 1.0,
            duration: const Duration(milliseconds: 150),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.chevron_right, color: Colors.grey[700]),
            ),
          ),
        ),
      ],
    );
  }

  /// Calendar view (simplified)
  Widget _buildCalendarView() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: 35, // 5 weeks
      itemBuilder: (context, index) {
        final day = index + 1;
        final isSelected = ExpenseProvider().selectedDay == day;
        return GestureDetector(
          onTap: () => _onDayTap(day),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected ? Colors.orange[100] : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$day',
                style: GoogleFonts.quattrocento(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.orange[800] : Colors.black87,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Expense list for activities
  Widget _buildExpenseList() {
    return AnimatedBuilder(
      animation: _expenseProvider,
      builder: (context, child) {
        if (_expenseProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (_expenseProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Lỗi tải dữ liệu',
                  style: GoogleFonts.quattrocento(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        final expenses = _expenseProvider.expenses;

        if (expenses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Chưa có giao dịch nào',
                  style: GoogleFonts.quattrocento(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: expenses.map((expense) {
            return GestureDetector(
              onTap: () => _onExpenseTap(expense.description.isNotEmpty ? expense.description : expense.category.displayName),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getCategoryIcon(expense.category),
                        size: 20,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expense.description.isNotEmpty ? expense.description : expense.category.displayName,
                            style: GoogleFonts.quattrocento(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _formatExpenseDate(expense.expenseDate),
                            style: GoogleFonts.quattrocento(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '-${_formatMoney(expense.amount)}₫',
                      style: GoogleFonts.quattrocento(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /// Pie chart
  Widget _buildPieChart() {
    return AnimatedBuilder(
      animation: _expenseProvider,
      builder: (context, child) {
        return Column(
          children: [
            // Chart toggle buttons
            Row(
              children: [
                const Spacer(),
                GestureDetector(
                  onTap: () => _toggleChartType(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.bar_chart, size: 16, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: _buildPieChartContent(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPieChartContent() {
    if (_expenseProvider.isSummaryLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final summary = _expenseProvider.expenseSummary;
    if (summary == null || summary.categoryBreakdown.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa có dữ liệu',
              style: GoogleFonts.quattrocento(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    final categoryData = summary.categoryBreakdown;
    final total = categoryData.values.fold<double>(0, (sum, value) => sum + value);
    
    if (total == 0) {
      return Center(
        child: Text(
          'Chưa có chi tiêu nào',
          style: GoogleFonts.quattrocento(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    final colors = [
      Colors.orange[400]!,
      Colors.blue[400]!,
      Colors.green[400]!,
      Colors.purple[400]!,
      Colors.red[400]!,
      Colors.teal[400]!,
      Colors.amber[400]!,
      Colors.pink[400]!,
      Colors.indigo[400]!,
    ];

    final sections = categoryData.entries.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final categoryEntry = entry.value;
      final percentage = (categoryEntry.value / total * 100);
      
      return PieChartSectionData(
        value: categoryEntry.value,
        title: '${percentage.toStringAsFixed(1)}%\n${_getCategoryDisplayName(categoryEntry.key)}',
        radius: 50 + (percentage / 100 * 20), // Dynamic radius based on percentage
        color: colors[index % colors.length],
        titleStyle: GoogleFonts.quattrocento(
          fontSize: 10, 
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 50,
        sections: sections,
      ),
    );
  }

  /// Bar chart
  Widget _buildBarChart() {
    return Column(
      children: [
        // Chart toggle and spend info
        Row(
          children: [
            const Spacer(),
            GestureDetector(
              onTap: () => _toggleChartType(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.pie_chart, size: 16, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        Expanded(
          child: _buildCustomHorizontalBarChart(),
        ),
        
        const SizedBox(height: 16),
        
        // Spend info button
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.orange[400],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              'CHI TIÊU THÁNG NÀY\n ${_formatMoney(_expenseProvider.expenseSummary?.totalAmount ?? 0)}₫',
              textAlign: TextAlign.center,
              style: GoogleFonts.quattrocento(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
      ],
    );
  }

  /// Advanced animated bar chart with real data and beautiful decorations
  Widget _buildCustomHorizontalBarChart() {
    return AnimatedBuilder(
      animation: _expenseProvider,
      builder: (context, child) {
        // Get real data from spending trends or create mock data based on current month
        List<Map<String, dynamic>> chartData = _generateChartData();
        
        if (chartData.isEmpty) {
          return _buildEmptyBarChart();
        }
        
        return _buildAnimatedBarChart(chartData);
      },
    );
  }

  /// Generate chart data from real backend data or create realistic mock data
  List<Map<String, dynamic>> _generateChartData() {
    final spendingTrends = _expenseProvider.spendingTrends;
    
    if (spendingTrends != null && spendingTrends.dailyTotals.isNotEmpty) {
      // Use real data from backend - aggregate daily totals by month
      final monthlyData = <int, double>{};
      for (final entry in spendingTrends.dailyTotals.entries) {
        final month = entry.key.month;
        monthlyData[month] = (monthlyData[month] ?? 0) + entry.value;
      }
      
      final maxAmount = monthlyData.values.isNotEmpty 
        ? monthlyData.values.reduce((a, b) => a > b ? a : b) 
        : spendingTrends.recentAverage;
        
      return monthlyData.entries.map((entry) {
        return {
          'month': _getShortMonthName(entry.key),
          'amount': entry.value,
          'color': _getGradientColor(entry.value, maxAmount),
          'isCurrentMonth': entry.key == _currentMonthIndex + 1,
        };
      }).toList();
    } else {
      // Generate realistic data based on current expenses
      final currentTotal = _expenseProvider.expenseSummary?.totalAmount ?? 0.0;
      return _generateRealisticChartData(currentTotal);
    }
  }

  /// Generate realistic chart data for demonstration
  List<Map<String, dynamic>> _generateRealisticChartData(double currentTotal) {
    final Random random = Random();
    final baseAmount = currentTotal > 0 ? currentTotal : 500000.0;
    
    return List.generate(6, (index) {
      final monthIndex = (_currentMonthIndex - 5 + index) % 12;
      final isCurrentMonth = monthIndex == _currentMonthIndex;
      final variation = 0.3 + (random.nextDouble() * 0.4); // 30-70% variation
      final amount = baseAmount * variation;
      
      return {
        'month': _getShortMonthName(monthIndex + 1),
        'amount': amount,
        'color': _getGradientColor(amount, baseAmount * 1.2),
        'isCurrentMonth': isCurrentMonth,
      };
    });
  }

  /// Build empty state for bar chart
  Widget _buildEmptyBarChart() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.bar_chart,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có dữ liệu xu hướng chi tiêu',
            style: GoogleFonts.quattrocento(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy thêm một số giao dịch để xem biểu đồ',
            style: GoogleFonts.quattrocento(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build animated bar chart with beautiful decorations
  Widget _buildAnimatedBarChart(List<Map<String, dynamic>> data) {
    final maxAmount = data.map((item) => item['amount'] as double).reduce((a, b) => a > b ? a : b);
    final minAmount = data.map((item) => item['amount'] as double).reduce((a, b) => a < b ? a : b);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[50]!,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Chart title with trend info
          _buildChartHeader(maxAmount, minAmount),
          
          const SizedBox(height: 20),
          
          // Main chart area
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Y-axis with dynamic labels
                _buildYAxis(maxAmount),
                
                const SizedBox(width: 16),
                
                // Chart bars area
                Expanded(
                  child: _buildBarsArea(data, maxAmount),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // X-axis labels with enhanced styling
          _buildXAxis(data),
          
          const SizedBox(height: 12),
          
          // Chart legend
          _buildChartLegend(),
        ],
      ),
    );
  }

  /// Build chart header with trend information
  Widget _buildChartHeader(double maxAmount, double minAmount) {
    final trend = maxAmount > minAmount ? 'tăng' : 'giảm';
    final trendIcon = maxAmount > minAmount ? Icons.trending_up : Icons.trending_down;
    final trendColor = maxAmount > minAmount ? Colors.green[600] : Colors.red[600];
    
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Xu hướng chi tiêu 6 tháng',
                style: GoogleFonts.quattrocento(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(trendIcon, size: 16, color: trendColor),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Xu hướng $trend',
                      style: GoogleFonts.quattrocento(
                        fontSize: 12,
                        color: trendColor,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.insights, size: 14, color: Colors.blue[600]),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Cao nhất: ${_formatMoney(maxAmount)}₫',
                    style: GoogleFonts.quattrocento(
                      fontSize: 11,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build Y-axis with dynamic scaling
  Widget _buildYAxis(double maxAmount) {
    final intervals = _calculateYAxisIntervals(maxAmount);
    
    return SizedBox(
      width: 60,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: intervals.map((amount) {
          return Container(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              _formatMoney(amount),
              style: GoogleFonts.quattrocento(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Build bars area with animations and hover effects
  Widget _buildBarsArea(List<Map<String, dynamic>> data, double maxAmount) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.grey[300]!, width: 1.5),
          bottom: BorderSide(color: Colors.grey[300]!, width: 1.5),
        ),
      ),
      child: Stack(
        children: [
          // Grid lines
          _buildGridLines(),
          
          // Animated bars
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Expanded(
                  child: _buildAnimatedBar(item, maxAmount, index),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Build individual animated bar with hover effect
  Widget _buildAnimatedBar(Map<String, dynamic> item, double maxAmount, int index) {
    final amount = item['amount'] as double;
    final isSelected = _selectedBarIndex == index;
    final percentage = amount / maxAmount;
    
    // Determine colors based on selection state
    final Color barColor;
    if (isSelected) {
      barColor = Colors.blue[600]!; // Blue when selected
    } else {
      barColor = Colors.grey[400]!; // Grey when not selected
    }
    
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + (index * 100)),
      tween: Tween(begin: 0.0, end: percentage),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return MouseRegion(
          onEnter: (_) => _showBarTooltip(item),
          child: GestureDetector(
            onTap: () => _onBarTap(index),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    width: constraints.maxWidth,
                    height: 200 * value,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          barColor,
                          barColor.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: barColor.withValues(alpha: 0.3),
                          blurRadius: isSelected ? 12 : 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: null,
                    ),
                    child: null,
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build grid lines for better readability
  Widget _buildGridLines() {
    return Column(
      children: List.generate(5, (index) {
        return Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.grey[200]!,
                  width: 0.8,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  /// Build X-axis with enhanced month labels
  Widget _buildXAxis(List<Map<String, dynamic>> data) {
    return Padding(
      padding: const EdgeInsets.only(left: 76),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: data.map((item) {
          final isCurrentMonth = item['isCurrentMonth'] as bool;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: isCurrentMonth
              ? BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[300]!),
                )
              : null,
            child: Text(
              item['month'] as String,
              textAlign: TextAlign.center,
              style: GoogleFonts.quattrocento(
                fontSize: 12,
                fontWeight: isCurrentMonth ? FontWeight.w600 : FontWeight.w500,
                color: isCurrentMonth ? Colors.orange[800] : Colors.grey[700],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Build chart legend
  Widget _buildChartLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Tháng hiện tại', Colors.orange[400]!, true),
        const SizedBox(width: 16),
        _buildLegendItem('Tháng khác', Colors.blue[400]!, false),
      ],
    );
  }

  /// Build legend item
  Widget _buildLegendItem(String label, Color color, bool isCurrent) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            border: isCurrent ? Border.all(color: Colors.orange[600]!, width: 1.5) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.quattrocento(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Calculate Y-axis intervals for better scaling
  List<double> _calculateYAxisIntervals(double maxAmount) {
    final roundedMax = (maxAmount * 1.1); // Add 10% padding
    final interval = roundedMax / 4;
    
    return [
      roundedMax,
      roundedMax - interval,
      roundedMax - (interval * 2),
      roundedMax - (interval * 3),
      0,
    ];
  }

  /// Get gradient color based on amount
  Color _getGradientColor(double amount, double maxAmount) {
    final percentage = amount / maxAmount;
    
    if (percentage > 0.8) return Colors.red[400]!;
    if (percentage > 0.6) return Colors.orange[400]!;
    if (percentage > 0.4) return Colors.blue[400]!;
    if (percentage > 0.2) return Colors.green[400]!;
    return Colors.teal[400]!;
  }

  /// Get short month name
  String _getShortMonthName(int monthNumber) {
    const months = [
      'T1', 'T2', 'T3', 'T4', 'T5', 'T6',
      'T7', 'T8', 'T9', 'T10', 'T11', 'T12'
    ];
    return months[(monthNumber - 1) % 12];
  }

  /// Show tooltip for bar hover
  void _showBarTooltip(Map<String, dynamic> item) {
    final amount = item['amount'] as double;
    final month = item['month'] as String;
    _showMessage('$month: ${_formatMoney(amount)}₫');
  }

  /// Handle bar tap to select/deselect
  void _onBarTap(int index) {
    setState(() {
      if (_selectedBarIndex == index) {
        _selectedBarIndex = null; // Deselect if already selected
      } else {
        _selectedBarIndex = index; // Select the tapped bar
      }
    });
  }

  /// Category tabs
  Widget _buildCategoryTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCategoryTab('Subcategory', 0),
        const SizedBox(width: 40),
        _buildCategoryTab('Category', 1),
      ],
    );
  }

  Widget _buildCategoryTab(String title, int index) {
    final isSelected = _categoryTabIndex == index;
    return GestureDetector(
      onTap: () => _onCategoryTabChanged(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: GoogleFonts.quattrocento(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.amber[600] : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: title.length * 8.0, // Dynamic width based on text length
            decoration: BoxDecoration(
              color: isSelected ? Colors.amber[600] : Colors.transparent,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }

  /// Category list
  Widget _buildCategoryList() {
    return AnimatedBuilder(
      animation: _expenseProvider,
      builder: (context, child) {
        if (_expenseProvider.isSummaryLoading || _expenseProvider.isCategoryLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final summary = _expenseProvider.expenseSummary;
        final categoryStatuses = _expenseProvider.categoryStatus;

        List<Map<String, dynamic>> categories = [];

        if (_categoryTabIndex == 0) {
          // Show detailed categories from summary
          if (summary != null && summary.categoryBreakdown.isNotEmpty) {
            categories = summary.categoryBreakdown.entries.map((entry) {
              return {
                'title': _getCategoryDisplayName(entry.key),
                'amount': entry.value,
                'icon': _getCategoryIconByName(entry.key),
                'categoryKey': entry.key,
              };
            }).toList();
            
            // Sort by amount descending
            categories.sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
          }
        } else {
          // Show category status from backend
          if (categoryStatuses.isNotEmpty) {
            categories = categoryStatuses.map((status) {
              return {
                'title': status.category.displayName,
                'amount': status.spent,
                'icon': _getCategoryIcon(status.category),
                'categoryKey': status.category,
                'status': status,
              };
            }).toList();
          }
        }

        if (categories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.category, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Chưa có dữ liệu danh mục',
                  style: GoogleFonts.quattrocento(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final amount = category['amount'] as double;
            
            return GestureDetector(
              onTap: () => _onCategoryTap(category['title'] as String),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      category['icon'] as IconData,
                      size: 20,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category['title'] as String,
                            style: GoogleFonts.quattrocento(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_categoryTabIndex == 1 && category['status'] != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Budget: ${_formatMoney((category['status'] as CategoryStatus).allocated)}₫',
                              style: GoogleFonts.quattrocento(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_formatMoney(amount)}₫',
                          style: GoogleFonts.quattrocento(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_categoryTabIndex == 1 && category['status'] != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${((category['status'] as CategoryStatus).percentageUsed).toStringAsFixed(1)}%',
                            style: GoogleFonts.quattrocento(
                              fontSize: 12,
                              color: (category['status'] as CategoryStatus).isOverBudget 
                                  ? Colors.red[600] 
                                  : Colors.green[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Event handlers
  void _onTabChanged(int index) {
    setState(() {
      _currentViewIndex = index;
    });
    _showMessage(index == 0 ? 'Switched to Activities' : 'Switched to Statistics');
  }

  void _onCategoryTabChanged(int index) {
    setState(() {
      _categoryTabIndex = index;
    });
  }

  void _changeMonth(int direction) {
    setState(() {
      _currentMonthIndex += direction;
      if (_currentMonthIndex > 11) {
        _currentMonthIndex = 0;
        _currentYear++;
      } else if (_currentMonthIndex < 0) {
        _currentMonthIndex = 11;
        _currentYear--;
      }
    });
    _loadData(); // Reload data for new month
  }

  void _toggleChartType() {
    setState(() {
      _chartTypeIndex = _chartTypeIndex == 0 ? 1 : 0;
    });
  }

  void _onFilterTap() {
    _showMessage('Opening filters...');
  }

  void _onGridTap() {
    _showMessage('Opening grid view...');
  }

  void _onDayTap(int day) {
    _showMessage('Selected day $day');
  }

  void _onExpenseTap(String title) {
    _showMessage('Opening expense: $title');
  }

  void _onCategoryTap(String category) {
    _showMessage('Selected category: $category');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF7B61FF),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Get icon for expense category
  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.foodBeverage:
        return Icons.restaurant;
      case ExpenseCategory.transportation:
        return Icons.directions_car;
      case ExpenseCategory.accommodation:
        return Icons.hotel;
      case ExpenseCategory.activities:
        return Icons.local_activity;
      case ExpenseCategory.shopping:
        return Icons.shopping_cart;
      case ExpenseCategory.miscellaneous:
        return Icons.more_horiz;
      case ExpenseCategory.emergency:
        return Icons.emergency;
    }
  }

  /// Format expense date
  String _formatExpenseDate(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Format money amount
  String _formatMoney(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  /// Get category display name from string key (for backward compatibility)
  String _getCategoryDisplayName(String categoryKey) {
    try {
      final category = ExpenseCategoryExtension.fromString(categoryKey);
      return category.displayName;
    } catch (e) {
      return categoryKey;
    }
  }

  /// Get category icon by string name (for backward compatibility)
  IconData _getCategoryIconByName(String categoryName) {
    try {
      final category = ExpenseCategoryExtension.fromString(categoryName);
      return _getCategoryIcon(category);
    } catch (e) {
      return Icons.category;
    }
  }
}

