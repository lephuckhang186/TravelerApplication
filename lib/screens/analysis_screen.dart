import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/theme/app_theme.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> with TickerProviderStateMixin {
  int _currentViewIndex = 0; // 0: Activities, 1: Statistic
  int _currentMonthIndex = 9; // October (index 9)
  int _currentYear = 2025;
  int _chartTypeIndex = 0; // 0: Pie chart, 1: Bar chart
  int _categoryTabIndex = 0; // 0: Subcategory, 1: Category

  late TabController _mainTabController;
  late TabController _categoryTabController;

  final List<String> _months = [
    'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4', 'Tháng 5', 'Tháng 6',
    'Tháng 7', 'Tháng 8', 'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12'
  ];

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _categoryTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _categoryTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          style: GoogleFonts.inter(
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
        final isSelected = day == 6 || day == 8 || day == 9; // Sample selected days
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
    final expenses = [
      {'title': 'Spend on car rentals', 'date': '14:32 07/10/2025', 'amount': '-562.000đ', 'icon': Icons.directions_car},
      {'title': 'Spend on hamburger', 'date': '15:01 02/10/2025', 'amount': '-126.000đ', 'icon': Icons.restaurant},
      {'title': 'Money to Alisa', 'date': '19:21 02/10/2025', 'amount': '-1.500.000đ', 'icon': Icons.person},
      {'title': 'Spend on beverage', 'date': '21:18 02/10/2025', 'amount': '-89.000đ', 'icon': Icons.local_drink},
    ];

    return Column(
      children: expenses.map((expense) {
        return GestureDetector(
          onTap: () => _onExpenseTap(expense['title'] as String),
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
                    expense['icon'] as IconData,
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
                        expense['title'] as String,
                        style: GoogleFonts.quattrocento(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        expense['date'] as String,
                        style: GoogleFonts.quattrocento(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  expense['amount'] as String,
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
              sections: [
                PieChartSectionData(
                  value: 85,
                  title: '85%\nFixed Cost',
                  radius: 50,
                  color: Colors.grey[300]!,
                  titleStyle: GoogleFonts.quattrocento(fontSize: 10, fontWeight: FontWeight.w600),
                ),
                PieChartSectionData(
                  value: 509,
                  title: '509%\nLiving Exp',
                  radius: 60,
                  color: Colors.orange[400]!,
                  titleStyle: GoogleFonts.quattrocento(fontSize: 10, fontWeight: FontWeight.w600),
                ),
                PieChartSectionData(
                  value: 22,
                  title: '22%\nOthers',
                  radius: 45,
                  color: Colors.grey[400]!,
                  titleStyle: GoogleFonts.quattrocento(fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ],
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
                      Text('1.5M', style: GoogleFonts.quattrocento(fontSize: 12, color: Colors.grey[600])),
                      Text('1M', style: GoogleFonts.quattrocento(fontSize: 12, color: Colors.grey[600])),
                      Text('500K', style: GoogleFonts.quattrocento(fontSize: 12, color: Colors.grey[600])),
                      Text('0', style: GoogleFonts.quattrocento(fontSize: 12, color: Colors.grey[600])),
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
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: data.map((item) {
                              final percentage = (item['amount'] as int) / maxAmount;
                              return Container(
                                width: 60,
                                height: (MediaQuery.of(context).size.height * 0.25) * percentage,
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

  /// Category list
  Widget _buildCategoryList() {
    final categories = _categoryTabIndex == 0 ? [
      {'title': 'Living expenses', 'amount': '509.000đ', 'icon': Icons.home},
      {'title': 'Others', 'amount': '22.000đ', 'icon': Icons.more_horiz},
      {'title': 'Fixed Cost', 'amount': '85.000đ', 'icon': Icons.attach_money},
    ] : [
      {'title': 'Foods & Drinks', 'amount': '359.000đ', 'icon': Icons.restaurant},
      {'title': 'Others', 'amount': '213.000đ', 'icon': Icons.more_horiz},
      {'title': 'Transportations', 'amount': '93.000đ', 'icon': Icons.directions_bus},
    ];

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
                  category['amount'] as String,
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
}

