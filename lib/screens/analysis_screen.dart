import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/theme/app_theme.dart';
import '../features/expense_management/presentation/providers/expense_provider.dart';
import '../features/expense_management/data/models/expense_models.dart';
import '../services/auth_service.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen>
    with TickerProviderStateMixin {
  int _currentViewIndex = 0; // 0: Activities, 1: Statistic
  int _currentMonthIndex = 9; // October (index 9)
  int _currentYear = 2025;
  int _chartTypeIndex = 0; // 0: Pie chart, 1: Bar chart
  int _categoryTabIndex = 0; // 0: Subcategory, 1: Category

  late TabController _mainTabController;
  late TabController _categoryTabController;
  late ExpenseProvider _expenseProvider;

  final List<String> _months = [
    'Tháng 1',
    'Tháng 2',
    'Tháng 3',
    'Tháng 4',
    'Tháng 5',
    'Tháng 6',
    'Tháng 7',
    'Tháng 8',
    'Tháng 9',
    'Tháng 10',
    'Tháng 11',
    'Tháng 12',
  ];

  @override
  void initState() {
    super.initState();
    debugPrint('=== ANALYSIS SCREEN INIT START ===');
    _mainTabController = TabController(length: 2, vsync: this);
    _categoryTabController = TabController(length: 2, vsync: this);
    _expenseProvider = ExpenseProvider();
    debugPrint('ExpenseProvider created, calling _initializeData...');
    _initializeData();
    debugPrint('=== ANALYSIS SCREEN INIT END ===');
  }

  /// Initialize data from backend
  Future<void> _initializeData() async {
    try {
      // Set up authentication first
      final authService = AuthService();
      final token = await authService.getIdToken();

      if (token != null) {
        _expenseProvider.setAuthToken(token);
        debugPrint('Auth token set successfully');
      } else {
        debugPrint('Warning: No auth token found');
        return; // Can't fetch data without auth
      }

      // Get current month date range
      final currentDate = DateTime(_currentYear, _currentMonthIndex + 1, 1);
      final startDate = DateTime(currentDate.year, currentDate.month, 1);
      final endDate = DateTime(currentDate.year, currentDate.month + 1, 0);

      debugPrint('Fetching data for: $startDate to $endDate');

      await Future.wait([
        _expenseProvider.fetchExpenses(startDate: startDate, endDate: endDate),
        _expenseProvider.fetchExpenseSummary(),
      ]);

      debugPrint('Data fetch completed');
    } catch (e) {
      debugPrint('Error loading expense data: $e');
    }
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
    debugPrint('=== ANALYSIS SCREEN BUILD ===');
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Quản lý chi tiêu',
          style: GoogleFonts.quattrocento(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header với search và buttons
            _buildHeader(),

            // Main tabs (Activities/Statistic)
            _buildMainTabs(),

            // Content
            Expanded(child: _buildContent()),
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
                  Expanded(flex: 3, child: _buildCalendarView()),

                  const SizedBox(height: 16),

                  // Expense list - takes remaining space
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(child: _buildExpenseList()),
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
                    child: _chartTypeIndex == 0
                        ? _buildPieChart()
                        : _buildBarChart(),
                  ),

                  // Only show category tabs and list for pie chart
                  if (_chartTypeIndex == 0) ...[
                    const SizedBox(height: 16),

                    // Category tabs
                    _buildCategoryTabs(),

                    const SizedBox(height: 16),

                    // Category list
                    Expanded(child: _buildCategoryList()),
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
        final isSelected =
            day == 6 || day == 8 || day == 9; // Sample selected days
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
          return const Center(child: CircularProgressIndicator());
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
                  onPressed: _initializeData,
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
              onTap: () => _onExpenseTap(
                expense.description.isNotEmpty
                    ? expense.description
                    : expense.category.displayName,
              ),
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
                            expense.description.isNotEmpty
                                ? _extractActivityTitle(expense.description)
                                : expense.category.displayName,
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

  /// Format expense date
  String _formatExpenseDate(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Format money amount
  String _formatMoney(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  /// Pie chart
  Widget _buildPieChart() {
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
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 50,
              sections: _buildPieChartSections(),
            ),
          ),
        ),
      ],
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

        Expanded(child: _buildCustomHorizontalBarChart()),

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
              'CHI TIÊU THÁNG NÀY\n+1.500.000đ',
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

        Text(
          'Hiện không có thông tin gì thêm',
          style: GoogleFonts.quattrocento(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// Custom vertical bar chart
  Widget _buildCustomHorizontalBarChart() {
    final data = [
      {'month': 'T9', 'amount': 700000, 'color': Colors.grey[300]!},
      {'month': 'T10', 'amount': 1300000, 'color': Colors.orange[400]!},
      {'month': 'T11', 'amount': 500000, 'color': Colors.grey[300]!},
    ];

    final maxAmount = 1500000.0; // Maximum value for scaling

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Chart area with Y-axis labels and bars
          Expanded(
            child: Row(
              children: [
                // Y-axis labels
                SizedBox(
                  width: 50,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '1.5M',
                        style: GoogleFonts.quattrocento(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '1M',
                        style: GoogleFonts.quattrocento(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '500K',
                        style: GoogleFonts.quattrocento(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '0',
                        style: GoogleFonts.quattrocento(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Chart area with grid lines
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: Colors.grey[300]!, width: 1),
                        bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Grid lines
                        Column(
                          children: List.generate(4, (index) {
                            return Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: Colors.grey[200]!,
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),

                        // Bars
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: data.map((item) {
                              final percentage =
                                  (item['amount'] as int) / maxAmount;
                              return Container(
                                width: 60,
                                height:
                                    (MediaQuery.of(context).size.height *
                                        0.25) *
                                    percentage,
                                decoration: BoxDecoration(
                                  color: item['color'] as Color,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // X-axis labels (months)
          Padding(
            padding: const EdgeInsets.only(left: 66),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: data.map((item) {
                return Text(
                  item['month'] as String,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quattrocento(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
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

  /// Build pie chart sections from category data
  List<PieChartSectionData> _buildPieChartSections() {
    // Get the same data as category list
    final categories = _getCategoryData();

    // Calculate total for percentages
    final total = categories.fold<double>(
      0,
      (sum, item) => sum + (item['amount'] as int),
    );

    // Color palette
    final colors = [
      Colors.orange[400]!,
      Colors.blue[400]!,
      Colors.green[400]!,
      Colors.purple[400]!,
      Colors.red[400]!,
      Colors.teal[400]!,
      Colors.amber[400]!,
      Colors.indigo[400]!,
      Colors.pink[400]!,
      Colors.cyan[400]!,
    ];

    // Build sections (only show top 8 categories to avoid clutter)
    final topCategories = categories.take(8).toList();

    return topCategories.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value;
      final value = (category['amount'] as int).toDouble();
      final percentage = (value / total * 100);

      return PieChartSectionData(
        value: value,
        title: '${percentage.toStringAsFixed(1)}%\n${category['title']}',
        radius: 50 + (percentage / 100 * 20), // Dynamic radius
        color: colors[index % colors.length],
        titleStyle: GoogleFonts.quattrocento(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  /// Extract clean activity title from expense description
  String _extractActivityTitle(String description) {
    if (description.isEmpty) return description;
    
    // Check if description contains the format "[Activity: xxx] [Trip: xxx]"
    final activityMatch = RegExp(r'^(.+?)\s*\[Activity:').firstMatch(description);
    if (activityMatch != null) {
      return activityMatch.group(1)?.trim() ?? description;
    }
    
    return description;
  }

  /// Get category data for both pie chart and list - now using real data
  List<Map<String, dynamic>> _getCategoryData() {
    final expenses = _expenseProvider.expenses;
    final summary = _expenseProvider.expenseSummary;

    // Debug: Print data status
    debugPrint('=== _getCategoryData Debug ===');
    debugPrint('Tab index: $_categoryTabIndex');
    debugPrint('Expenses count: ${expenses.length}');
    debugPrint('Summary exists: ${summary != null}');
    debugPrint(
      'Summary categoryBreakdown: ${summary?.categoryBreakdown ?? "null"}',
    );

    if (_categoryTabIndex == 0) {
      // Subcategory tab - group expenses by description (activity title)
      final subcategoryBreakdown = <String, double>{};
      for (final expense in expenses) {
        final rawDescription = expense.description.isNotEmpty
            ? expense.description
            : expense.category.displayName;
        final subcategoryName = _extractActivityTitle(rawDescription);
        subcategoryBreakdown[subcategoryName] =
            (subcategoryBreakdown[subcategoryName] ?? 0) + expense.amount;
      }

      if (subcategoryBreakdown.isEmpty) {
        // Fallback to mock data if no real data available
        return [
          {'title': 'Đi ăn', 'amount': 359000, 'icon': Icons.restaurant},
          {'title': 'Ăn tối', 'amount': 150000, 'icon': Icons.restaurant},
          {'title': 'Thuê xe', 'amount': 562000, 'icon': Icons.directions_car},
        ];
      }

      return subcategoryBreakdown.entries.map((entry) {
          // Try to find corresponding expense to get icon
          Expense? expense;
          try {
            expense = expenses.firstWhere(
              (e) => _extractActivityTitle(e.description.isNotEmpty
                      ? e.description
                      : e.category.displayName) == entry.key,
            );
          } catch (e) {
            expense = expenses.isNotEmpty ? expenses.first : null;
          }

          return {
            'title': entry.key,
            'amount': entry.value.toInt(),
            'icon': expense != null
                ? _getCategoryIcon(expense.category)
                : Icons.category,
          };
        }).toList()
        ..sort((a, b) => (b['amount'] as int).compareTo(a['amount'] as int));
    } else {
      // Category tab - use expense summary or fallback to expense grouping
      Map<String, double> categoryBreakdown;

      if (summary != null && summary.categoryBreakdown.isNotEmpty) {
        categoryBreakdown = summary.categoryBreakdown;
      } else {
        // Fallback: group expenses by category
        categoryBreakdown = <String, double>{};
        for (final expense in expenses) {
          final categoryKey = expense.category.value;
          categoryBreakdown[categoryKey] =
              (categoryBreakdown[categoryKey] ?? 0) + expense.amount;
        }
      }

      if (categoryBreakdown.isEmpty) {
        // Fallback to mock data if no real data available
        return [
          {'title': 'Nhà hàng', 'amount': 598000, 'icon': Icons.restaurant},
          {'title': 'Lưu trú', 'amount': 800000, 'icon': Icons.hotel},
          {'title': 'Chuyến bay', 'amount': 2500000, 'icon': Icons.flight},
        ];
      }

      return categoryBreakdown.entries.map((entry) {
          return {
            'title': _getCategoryDisplayName(entry.key),
            'amount': entry.value.toInt(),
            'icon': _getCategoryIconByName(entry.key),
          };
        }).toList()
        ..sort((a, b) => (b['amount'] as int).compareTo(a['amount'] as int));
    }
  }

  /// Get category display name
  String _getCategoryDisplayName(String categoryKey) {
    try {
      final category = ExpenseCategoryExtension.fromString(categoryKey);
      return category.displayName;
    } catch (e) {
      return categoryKey;
    }
  }

  /// Get category icon by category enum
  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.flight:
        return Icons.flight;
      case ExpenseCategory.activity:
        return Icons.local_activity;
      case ExpenseCategory.lodging:
        return Icons.hotel;
      case ExpenseCategory.carRental:
        return Icons.car_rental;
      case ExpenseCategory.restaurant:
        return Icons.restaurant;
      case ExpenseCategory.tour:
        return Icons.tour;
      case ExpenseCategory.transportation:
        return Icons.directions_bus;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag;
      default:
        return Icons.category;
    }
  }

  /// Get category icon by name string
  IconData _getCategoryIconByName(String categoryName) {
    try {
      final category = ExpenseCategoryExtension.fromString(categoryName);
      return _getCategoryIcon(category);
    } catch (e) {
      return Icons.category;
    }
  }

  /// Format currency
  String _formatCurrency(int amount) {
    return '${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}đ';
  }

  /// Category list
  Widget _buildCategoryList() {
    debugPrint('=== BUILDING CATEGORY LIST ===');
    return AnimatedBuilder(
      animation: _expenseProvider,
      builder: (context, child) {
        debugPrint('AnimatedBuilder rebuild triggered');
        final categories = _getCategoryData();
        debugPrint('Categories returned: ${categories.length} items');

        if (_expenseProvider.isLoading) {
          debugPrint('ExpenseProvider is loading...');
          return const Center(child: CircularProgressIndicator());
        }

        if (categories.isEmpty) {
          debugPrint('*** CATEGORIES IS EMPTY - SHOWING NO DATA MESSAGE ***');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.category, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Chưa có dữ liệu chi tiêu',
                  style: GoogleFonts.quattrocento(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'DEBUG: Categories length = ${categories.length}',
                  style: GoogleFonts.quattrocento(
                    fontSize: 12,
                    color: Colors.red,
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
                      child: Text(
                        category['title'] as String,
                        style: GoogleFonts.quattrocento(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      _formatCurrency(category['amount'] as int),
                      style: GoogleFonts.quattrocento(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
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
    debugPrint(
      '=== TAB CHANGED TO: $index (${index == 0 ? "Activities" : "Statistics"}) ===',
    );
    setState(() {
      _currentViewIndex = index;
    });
  }

  void _onCategoryTabChanged(int index) {
    debugPrint(
      '=== CATEGORY TAB CHANGED TO: $index (${index == 0 ? "Subcategory" : "Category"}) ===',
    );
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
  }

  void _toggleChartType() {
    setState(() {
      _chartTypeIndex = _chartTypeIndex == 0 ? 1 : 0;
    });
  }

  void _onFilterTap() {
    // Filter functionality
  }

  void _onGridTap() {
    // Grid view functionality
  }

  void _onDayTap(int day) {
    // Day selection functionality
  }

  void _onExpenseTap(String title) {
    // Expense detail functionality
  }

  void _onCategoryTap(String category) {
    // Category detail functionality
  }

  void _showMessage(String message) {
    // Message display functionality
  }
}
