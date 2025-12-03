import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../Expense/models/expense_models.dart';
import '../../Expense/providers/expense_provider.dart';
import '../../Expense/services/expense_service.dart';
import '../../Plan/models/trip_model.dart';
import '../../Plan/providers/trip_planning_provider.dart';
import '../../Login/services/auth_service.dart';

// Trip date status enum for calendar
enum TripDateStatus {
  none,
  beforeTrip,
  duringTrip,
  afterTrip,
}

// Status colors model for calendar
class StatusColors {
  final Color? backgroundColor;
  final Color? borderColor;
  final Color textColor;
  final Color? indicatorColor;

  const StatusColors({
    this.backgroundColor,
    this.borderColor,
    required this.textColor,
    this.indicatorColor,
  });
}

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen>
    with TickerProviderStateMixin {
  int _currentViewIndex = 0; // 0: Activities, 1: Statistic
  int _currentMonthIndex = DateTime.now().month - 1; // Current month (0-based)
  int _currentYear = DateTime.now().year;
  int _chartTypeIndex = 0; // 0: Pie chart, 1: Bar chart
  int _categoryTabIndex = 0; // 0: Subcategory, 1: Category
  int? _selectedBarIndex; // Index of selected bar in chart
  String? _selectedTripId; // Selected trip for filtering
  BudgetStatus? _budgetStatus; // Current budget status

  late TabController _mainTabController;
  late TabController _categoryTabController;
  late ExpenseProvider _expenseProvider;

  final List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _categoryTabController = TabController(length: 2, vsync: this);
    _expenseProvider = ExpenseProvider();
    _initializeWithAuth();
    
    // Initialize trip provider when this screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTripProvider();
    });
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
      debugPrint('Error initializing with auth: $e');
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

  /// Initialize trip provider
  Future<void> _initializeTripProvider() async {
    try {
      final tripProvider = Provider.of<TripPlanningProvider>(context, listen: false);
      if (tripProvider.trips.isEmpty && !tripProvider.isLoading) {
        await tripProvider.initialize();
      }
    } catch (e) {
      debugPrint('Error initializing trip provider: $e');
    }
  }

  /// Get trip status for a specific date
  TripDateStatus _getTripStatusForDate(List<TripModel> trips, DateTime date) {
    for (final trip in trips) {
      if (date.isBefore(trip.startDate)) {
        return TripDateStatus.beforeTrip;
      } else if (date.isAfter(trip.endDate)) {
        return TripDateStatus.afterTrip;
      } else if (!date.isBefore(trip.startDate) && !date.isAfter(trip.endDate)) {
        return TripDateStatus.duringTrip;
      }
    }
    return TripDateStatus.none;
  }

  /// Get status colors based on trip status
  StatusColors _getStatusColors(TripDateStatus status) {
    switch (status) {
      case TripDateStatus.beforeTrip:
        return StatusColors(
          backgroundColor: Colors.blue[50],
          borderColor: Colors.blue[200],
          textColor: Colors.blue[800]!,
          indicatorColor: Colors.blue[600],
        );
      case TripDateStatus.duringTrip:
        return StatusColors(
          backgroundColor: Colors.green[50],
          borderColor: Colors.green[200],
          textColor: Colors.green[800]!,
          indicatorColor: Colors.green[600],
        );
      case TripDateStatus.afterTrip:
        return StatusColors(
          backgroundColor: Colors.grey[50],
          borderColor: Colors.grey[200],
          textColor: Colors.grey[600]!,
          indicatorColor: Colors.grey[400],
        );
      case TripDateStatus.none:
        return StatusColors(
          textColor: Colors.black87,
        );
    }
  }

  /// Build calendar legend
  Widget _buildCalendarLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem('Before Trip', Colors.blue[200]!),
        _buildLegendItem('During Trip', Colors.green[200]!),
        _buildLegendItem('After Trip', Colors.grey[200]!),
      ],
    );
  }

  /// Build legend item
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.quattrocento(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// Build budget status card
  Widget _buildBudgetStatusCard(TripPlanningProvider tripProvider) {
    if (_budgetStatus == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _budgetStatus!.isOverBudget ? Colors.red[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _budgetStatus!.isOverBudget ? Colors.red[200]! : Colors.green[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _budgetStatus!.isOverBudget ? Icons.warning : Icons.check_circle,
                size: 16,
                color: _budgetStatus!.isOverBudget ? Colors.red[600] : Colors.green[600],
              ),
              const SizedBox(width: 8),
              Text(
                'Budget Status',
                style: GoogleFonts.quattrocento(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _budgetStatus!.isOverBudget ? Colors.red[800] : Colors.green[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatMoney(_budgetStatus!.totalSpent)} / ${_formatMoney(_budgetStatus!.totalBudget)}',
            style: GoogleFonts.quattrocento(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Load data from backend
  Future<void> _loadData() async {
    // Get current month date range
    final currentDate = DateTime(_currentYear, _currentMonthIndex + 1, 1);
    final startDate = DateTime(currentDate.year, currentDate.month, 1);
    final endDate = DateTime(currentDate.year, currentDate.month + 1, 0);

    await Future.wait([
      _expenseProvider.fetchExpenses(startDate: startDate, endDate: endDate),
      _expenseProvider.fetchExpenseSummary(),
      _expenseProvider.fetchCategoryStatus(),
      _expenseProvider.fetchSpendingTrends(),
      _expenseProvider.fetchBudgetStatus(tripId: _selectedTripId),
    ]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh trip data when returning to this screen
    _refreshTripData();
  }

  /// Refresh trip data
  Future<void> _refreshTripData() async {
    try {
      final tripProvider = Provider.of<TripPlanningProvider>(context, listen: false);
      // Only refresh if we're not currently loading
      if (!tripProvider.isLoading) {
        await tripProvider.initialize();
      }
    } catch (e) {
      debugPrint('Error refreshing trip data: $e');
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
                  const Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
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

          // Refresh button
          MouseRegion(
            onEnter: (_) => setState(() {}),
            onExit: (_) => setState(() {}),
            child: GestureDetector(
              onTap: () => _onRefreshTap(),
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
                    Icons.refresh,
                    color: Colors.grey[700],
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Budget button
          MouseRegion(
            onEnter: (_) => setState(() {}),
            onExit: (_) => setState(() {}),
            child: GestureDetector(
              onTap: () => _showBudgetDialog(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _selectedTripId != null ? Colors.blue[50] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedTripId != null ? Colors.blue[200]! : Colors.grey[200]!
                  ),
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
                    Icons.account_balance_wallet,
                    color: _selectedTripId != null ? Colors.blue[600] : Colors.grey[700],
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

  /// Month selector with arrows and trip filter
  Widget _buildMonthSelector() {
    return Consumer<TripPlanningProvider>(
      builder: (context, tripProvider, child) {
        return Column(
          children: [
            // Trip Filter Row
            Row(
              children: [
                Icon(Icons.trip_origin, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedTripId,
                        hint: Text(
                          'All Trips',
                          style: GoogleFonts.quattrocento(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text(
                              'All Trips',
                              style: GoogleFonts.quattrocento(fontSize: 14),
                            ),
                          ),
                          ...tripProvider.trips.map((trip) => DropdownMenuItem(
                            value: trip.id,
                            child: Text(
                              '${trip.name} (${trip.destination})',
                              style: GoogleFonts.quattrocento(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          )),
                        ],
                        onChanged: (String? tripId) {
                          setState(() {
                            _selectedTripId = tripId;
                          });
                          _loadData(); // Reload data when trip filter changes
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Budget Status Card (if trip selected)
            if (_selectedTripId != null) ...[
              _buildBudgetStatusCard(tripProvider),
              const SizedBox(height: 12),
            ],
            
            // Month Selector Row  
            Row(
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
            ),
          ],
        );
      },
    );
  }

  /// Calendar view with trip status colors
  Widget _buildCalendarView() {
    return Consumer<TripPlanningProvider>(
      builder: (context, tripProvider, child) {
        // Calculate the first day of the current month
        final currentMonthDate = DateTime(_currentYear, _currentMonthIndex + 1, 1);
        final firstDayOfMonth = currentMonthDate.weekday % 7; // Adjust for Sunday start
        final daysInMonth = DateTime(_currentYear, _currentMonthIndex + 2, 0).day;
        
        return Column(
          children: [
            // Weekday headers
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                    .map((day) => Expanded(
                          child: Center(
                            child: Text(
                              day,
                              style: GoogleFonts.quattrocento(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
            
            // Calendar grid
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1,
                ),
                itemCount: 42, // 6 weeks to ensure full month display
                itemBuilder: (context, index) {
                  final dayOffset = index - firstDayOfMonth + 1;
                  
                  // Skip days outside current month
                  if (dayOffset < 1 || dayOffset > daysInMonth) {
                    return Container();
                  }
                  
                  final currentDate = DateTime(_currentYear, _currentMonthIndex + 1, dayOffset);
                  final isSelected = _expenseProvider.selectedDay == dayOffset;
                  
                  // Get trip status for this date
                  final tripStatus = _getTripStatusForDate(tripProvider.trips, currentDate);
                  final statusColors = _getStatusColors(tripStatus);
                  
                  return GestureDetector(
                    onTap: () => _onDayTap(dayOffset),
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.orange[100] : statusColors.backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: statusColors.borderColor != null 
                            ? Border.all(color: statusColors.borderColor!, width: 2)
                            : null,
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Text(
                              '$dayOffset',
                              style: GoogleFonts.quattrocento(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: isSelected ? Colors.orange[800] : statusColors.textColor,
                              ),
                            ),
                          ),
                          // Status indicator dot
                          if (tripStatus != TripDateStatus.none)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: statusColors.indicatorColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Legend
            const SizedBox(height: 8),
            _buildCalendarLegend(),
          ],
        );
      },
    );
  }

  /// Expense list for activities grouped by trip
  Widget _buildExpenseList() {
    return Consumer<TripPlanningProvider>(
      builder: (context, tripProvider, child) {
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

            // Group expenses by trip
            final groupedExpenses = _groupExpensesByTrip(expenses, tripProvider.trips);
            
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: groupedExpenses.keys.length,
              itemBuilder: (context, groupIndex) {
                final tripName = groupedExpenses.keys.elementAt(groupIndex);
                final tripExpenses = groupedExpenses[tripName]!;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Trip header
                    if (tripName != 'Other Expenses') ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.flight, color: Colors.blue[600], size: 16),
                            const SizedBox(width: 8),
                            Text(
                              tripName,
                              style: GoogleFonts.quattrocento(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[800],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${tripExpenses.length} activities',
                              style: GoogleFonts.quattrocento(
                                fontSize: 12,
                                color: Colors.blue[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // Expenses for this trip
                    ...tripExpenses.map((expense) {
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
                            color: tripName == 'Other Expenses' ? Colors.grey[50] : Colors.blue[25],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: tripName == 'Other Expenses' 
                                  ? Colors.grey[200]! 
                                  : Colors.blue[100]!
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(expense.category).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getCategoryIcon(expense.category),
                                  size: 20,
                                  color: _getCategoryColor(expense.category),
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
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 12,
                                          color: Colors.grey[500],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatExpenseDate(expense.expenseDate),
                                          style: GoogleFonts.quattrocento(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        if (_extractTripFromDescription(expense.description) != null) ...[
                                          const SizedBox(width: 12),
                                          Icon(
                                            Icons.location_on,
                                            size: 12,
                                            color: Colors.blue[500],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _extractTripFromDescription(expense.description)!,
                                            style: GoogleFonts.quattrocento(
                                              fontSize: 12,
                                              color: Colors.blue[600],
                                            ),
                                          ),
                                        ],
                                      ],
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
                    }),
                    
                    const SizedBox(height: 16),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  /// Extract clean activity title from expense description
  String _extractActivityTitle(String description) {
    if (description.isEmpty) return description;

    // Check if description contains the format "[Activity: xxx] [Trip: xxx]"
    final activityMatch = RegExp(
      r'^(.+?)\s*\[Activity:',
    ).firstMatch(description);
    if (activityMatch != null) {
      return activityMatch.group(1)?.trim() ?? description;
    }

    return description;
  }

  /// Extract trip information from expense description
  String? _extractTripFromDescription(String description) {
    if (description.isEmpty) return null;
    
    // Check for pattern [Trip: xxx]
    final tripMatch = RegExp(r'\[Trip:\s*([^\]]+)\]').firstMatch(description);
    if (tripMatch != null) {
      return tripMatch.group(1)?.trim();
    }
    
    return null;
  }

  /// Group expenses by trip
  Map<String, List<Expense>> _groupExpensesByTrip(List<Expense> expenses, List<TripModel> trips) {
    final Map<String, List<Expense>> grouped = {};
    
    for (final expense in expenses) {
      String tripName = 'Other Expenses';
      
      // Try to find trip from expense description first
      final tripFromDesc = _extractTripFromDescription(expense.description);
      if (tripFromDesc != null) {
        tripName = tripFromDesc;
      } else {
        // Try to match expense date with trip dates
        for (final trip in trips) {
          if (expense.expenseDate.isAfter(trip.startDate) && 
              expense.expenseDate.isBefore(trip.endDate.add(const Duration(days: 1)))) {
            tripName = '${trip.name} (${trip.destination})';
            break;
          }
        }
      }
      
      // Filter by selected trip if one is selected
      if (_selectedTripId != null) {
        final selectedTrip = trips.firstWhere(
          (trip) => trip.id == _selectedTripId,
          orElse: () => trips.first,
        );
        final expectedTripName = '${selectedTrip.name} (${selectedTrip.destination})';
        
        // Only include expenses from selected trip
        if (tripName != expectedTripName && tripFromDesc != selectedTrip.name) {
          continue;
        }
      }
      
      grouped.putIfAbsent(tripName, () => []).add(expense);
    }
    
    return grouped;
  }

  /// Get category color for visual distinction
  Color _getCategoryColor(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.flight:
        return Colors.blue[600]!;
      case ExpenseCategory.activity:
        return Colors.green[600]!;
      case ExpenseCategory.lodging:
        return Colors.purple[600]!;
      case ExpenseCategory.restaurant:
        return Colors.orange[600]!;
      case ExpenseCategory.transportation:
        return Colors.teal[600]!;
      case ExpenseCategory.shopping:
        return Colors.pink[600]!;
      case ExpenseCategory.tour:
        return Colors.amber[600]!;
      default:
        return Colors.grey[600]!;
    }
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
                    child: Icon(
                      Icons.bar_chart,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Expanded(
              child: Transform.translate(
                offset: const Offset(0, -20), // Dịch pie chart lên trên 20px
                child: _buildPieChartContent(),
              ),
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

    // Get data based on selected tab
    Map<String, double> chartData;

    if (_categoryTabIndex == 0) {
      // Subcategory tab - group by expense description (activity title)
      final subcategoryBreakdown = <String, double>{};
      for (final expense in _expenseProvider.expenses) {
        final rawDescription = expense.description.isNotEmpty
            ? expense.description
            : expense.category.displayName;
        final subcategoryName = _extractActivityTitle(rawDescription);
        subcategoryBreakdown[subcategoryName] =
            (subcategoryBreakdown[subcategoryName] ?? 0) + expense.amount;
      }
      chartData = subcategoryBreakdown;
    } else {
      // Category tab - use existing category breakdown
      final summary = _expenseProvider.expenseSummary;
      chartData = summary?.categoryBreakdown ?? {};
    }

    if (chartData.isEmpty) {
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

    final categoryData = chartData;
    final total = categoryData.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );

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

      // Get display name based on current tab
      String displayName;
      if (_categoryTabIndex == 0) {
        // Subcategory tab - use the key as is (activity title)
        displayName = categoryEntry.key;
      } else {
        // Category tab - use category display name
        displayName = _getCategoryDisplayName(categoryEntry.key);
      }

      return PieChartSectionData(
        value: categoryEntry.value,
        title: displayName.length > 15 ? '${percentage.toStringAsFixed(0)}%' : displayName, // Show name or % based on length
        radius: 80, // Tăng radius lên 100 để pie chart to hơn
        color: colors[index % colors.length],
        titleStyle: GoogleFonts.quattrocento(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      );
    }).toList();

    return Stack(
      children: [
        PieChart(
          PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 50,
            sections: sections,
          ),
        ),
        // Text ở giữa pie chart
        Positioned.fill(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Tổng chi tiêu',
                  style: GoogleFonts.quattrocento(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatMoney(total),
                  style: GoogleFonts.quattrocento(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'VND',
                  style: GoogleFonts.quattrocento(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
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
              '${_formatMoney(_expenseProvider.expenseSummary?.totalAmount ?? 0)}₫',
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

  /// Generate chart data from real expense data
  List<Map<String, dynamic>> _generateChartData() {
    // Use real expense data from provider
    final expenses = _expenseProvider.expenses;

    if (expenses.isEmpty) {
      return [];
    }

    // Group expenses by month
    final monthlyData = <int, double>{};
    for (final expense in expenses) {
      final month = expense.date.month;
      monthlyData[month] = (monthlyData[month] ?? 0) + expense.amount;
    }

    // If no monthly data, just return current month total
    if (monthlyData.isEmpty) {
      final currentTotal = _expenseProvider.expenseSummary?.totalAmount ?? 0.0;
      if (currentTotal > 0) {
        return [
          {
            'month': _getShortMonthName(DateTime.now().month),
            'amount': currentTotal,
            'color': _getGradientColor(currentTotal, currentTotal),
            'isCurrentMonth': true,
          },
        ];
      }
      return [];
    }

    final maxAmount = monthlyData.values.isNotEmpty
        ? monthlyData.values.reduce((a, b) => a > b ? a : b)
        : 1000000.0;

    // Convert to chart data
    return monthlyData.entries.map((entry) {
      return {
        'month': _getShortMonthName(entry.key),
        'amount': entry.value,
        'color': _getGradientColor(entry.value, maxAmount),
        'isCurrentMonth': entry.key == DateTime.now().month,
      };
    }).toList()..sort(
      (a, b) => _getMonthNumber(
        a['month'] as String,
      ).compareTo(_getMonthNumber(b['month'] as String)),
    );
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
            child: Icon(Icons.bar_chart, size: 48, color: Colors.grey[400]),
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
    final maxAmount = data
        .map((item) => item['amount'] as double)
        .reduce((a, b) => a > b ? a : b);
    final minAmount = data
        .map((item) => item['amount'] as double)
        .reduce((a, b) => a < b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[50]!, Colors.white],
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
            flex: 2,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Y-axis with dynamic labels
                _buildYAxis(maxAmount),

                const SizedBox(width: 16),

                // Chart bars area
                Expanded(child: _buildBarsArea(data, maxAmount)),
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
    final trendIcon = maxAmount > minAmount
        ? Icons.trending_up
        : Icons.trending_down;
    final trendColor = maxAmount > minAmount
        ? Colors.green[600]
        : Colors.red[600];

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
  Widget _buildAnimatedBar(
    Map<String, dynamic> item,
    double maxAmount,
    int index,
  ) {
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
                        colors: [barColor, barColor.withValues(alpha: 0.7)],
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
                top: BorderSide(color: Colors.grey[200]!, width: 0.8),
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
        _buildLegendItem('Tháng hiện tại', Colors.orange[400]!),
        const SizedBox(width: 16),
        _buildLegendItem('Tháng khác', Colors.blue[400]!),
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
      'T1',
      'T2',
      'T3',
      'T4',
      'T5',
      'T6',
      'T7',
      'T8',
      'T9',
      'T10',
      'T11',
      'T12',
    ];
    return months[(monthNumber - 1) % 12];
  }

  /// Get month number from short month name (T1 -> 1, T2 -> 2, etc.)
  int _getMonthNumber(String shortName) {
    const months = [
      'T1',
      'T2',
      'T3',
      'T4',
      'T5',
      'T6',
      'T7',
      'T8',
      'T9',
      'T10',
      'T11',
      'T12',
    ];
    return months.indexOf(shortName) + 1;
  }

  /// Show tooltip for bar hover
  void _showBarTooltip(Map<String, dynamic> item) {
    // Tooltip disabled - no more showing month amount messages
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
        if (_expenseProvider.isSummaryLoading ||
            _expenseProvider.isCategoryLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final summary = _expenseProvider.expenseSummary;
        final categoryStatuses = _expenseProvider.categoryStatus;

        List<Map<String, dynamic>> categories = [];

        if (_categoryTabIndex == 0) {
          // Subcategory tab - group expenses by description (activity title)
          final subcategoryBreakdown = <String, double>{};
          for (final expense in _expenseProvider.expenses) {
            final rawDescription = expense.description.isNotEmpty
                ? expense.description
                : expense.category.displayName;
            final subcategoryName = _extractActivityTitle(rawDescription);
            subcategoryBreakdown[subcategoryName] =
                (subcategoryBreakdown[subcategoryName] ?? 0) + expense.amount;
          }

          if (subcategoryBreakdown.isNotEmpty) {
            categories =
                subcategoryBreakdown.entries.map((entry) {
                  // Try to find corresponding expense to get icon
                  Expense? expense;
                  try {
                    expense = _expenseProvider.expenses.firstWhere(
                      (e) =>
                          _extractActivityTitle(
                            e.description.isNotEmpty
                                ? e.description
                                : e.category.displayName,
                          ) ==
                          entry.key,
                    );
                  } catch (e) {
                    expense = _expenseProvider.expenses.isNotEmpty
                        ? _expenseProvider.expenses.first
                        : null;
                  }

                  return {
                    'title': entry.key,
                    'amount': entry.value,
                    'icon': expense != null
                        ? _getCategoryIcon(expense.category)
                        : Icons.category,
                    'categoryKey': entry.key,
                  };
                }).toList()..sort(
                  (a, b) =>
                      (b['amount'] as double).compareTo(a['amount'] as double),
                );
          }
        } else {
          // Category tab - show expense categories grouped
          if (summary != null && summary.categoryBreakdown.isNotEmpty) {
            categories = summary.categoryBreakdown.entries.map((entry) {
              final displayName = _getCategoryDisplayName(entry.key);
              return {
                'title': displayName,
                'amount': entry.value,
                'icon': _getCategoryIconByName(entry.key),
                'categoryKey': entry.key,
              };
            }).toList();

            // Sort by amount descending
            categories.sort(
              (a, b) =>
                  (b['amount'] as double).compareTo(a['amount'] as double),
            );
          }
        }

        if (_categoryTabIndex == 0) {
          // Show subcategories - group expenses by description (activity title)
          final subcategoryBreakdown = <String, double>{};
          for (final expense in _expenseProvider.expenses) {
            final rawDescription = expense.description.isNotEmpty
                ? expense.description
                : expense.category.displayName;
            final subcategoryName = _extractActivityTitle(rawDescription);
            subcategoryBreakdown[subcategoryName] =
                (subcategoryBreakdown[subcategoryName] ?? 0) + expense.amount;
          }

          if (subcategoryBreakdown.isNotEmpty) {
            categories = subcategoryBreakdown.entries.map((entry) {
              // Try to find corresponding expense to get icon
              final expense = _expenseProvider.expenses.firstWhere(
                (e) =>
                    _extractActivityTitle(
                      e.description.isNotEmpty
                          ? e.description
                          : e.category.displayName,
                    ) ==
                    entry.key,
                orElse: () => _expenseProvider.expenses.first,
              );

              return {
                'title': entry.key,
                'amount': entry.value,
                'icon': _getCategoryIcon(expense.category),
                'categoryKey': entry.key,
              };
            }).toList();

            // Sort by amount descending
            categories.sort(
              (a, b) =>
                  (b['amount'] as double).compareTo(a['amount'] as double),
            );
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

        // Định nghĩa màu sắc giống như pie chart
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

        return ListView.builder(
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final amount = category['amount'] as double;
            final categoryColor =
                colors[index % colors.length]; // Màu tương ứng với pie chart

            return GestureDetector(
              onTap: () => _onCategoryTap(category['title'] as String),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: categoryColor.withOpacity(0.3), // Border màu nhẹ
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Dot màu tương ứng với pie chart
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: categoryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Icon(
                      category['icon'] as IconData,
                      size: 20,
                      color: Colors.grey[700], // Icon màu xám mặc định
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category['title'] as String,
                            style: const TextStyle(
                              fontFamily: 'Urbanist-Regular',
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: Colors.black87, // Chữ màu đen mặc định
                            ),
                          ),
                          if (_categoryTabIndex == 1 &&
                              category['status'] != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Budget: ${_formatMoney((category['status'] as CategoryStatus).allocated)}₫',
                              style: const TextStyle(
                                fontFamily: 'Urbanist-Regular',
                                fontSize: 12,
                                color:
                                    Colors.grey, // Màu xám mặc định cho budget
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
                          style: const TextStyle(
                            fontFamily: 'Urbanist-Regular',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87, // Số tiền màu đen mặc định
                          ),
                        ),
                        if (_categoryTabIndex == 1 &&
                            category['status'] != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${((category['status'] as CategoryStatus).percentageUsed).toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontFamily: 'Urbanist-Regular',
                              fontSize: 12,
                              color:
                                  (category['status'] as CategoryStatus)
                                      .isOverBudget
                                  ? Colors.red[600]
                                  : Colors
                                        .grey[600], // Màu xám mặc định hoặc đỏ nếu over budget
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
    _showMessage(
      index == 0 ? 'Switched to Activities' : 'Switched to Statistics',
    );
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
    _loadData(); // Reload expense data for new month
    _refreshTripData(); // Also refresh trip data to ensure calendar is up-to-date
  }

  void _toggleChartType() {
    setState(() {
      _chartTypeIndex = _chartTypeIndex == 0 ? 1 : 0;
    });
  }

  void _onFilterTap() {
    _showMessage('Opening filters...');
  }

  void _onRefreshTap() async {
    _showMessage('Refreshing data...');
    await Future.wait([
      _loadData(),
      _refreshTripData(),
    ]);
    _showMessage('Data refreshed!');
  }

  void _onGridTap() {
    _showMessage('Opening grid view...');
  }

  /// Show budget creation dialog
  void _showBudgetDialog() {
    if (_selectedTripId == null) {
      _showMessage('Please select a trip first');
      return;
    }
    
    final tripProvider = Provider.of<TripPlanningProvider>(context, listen: false);
    final selectedTrip = tripProvider.trips.firstWhere(
      (trip) => trip.id == _selectedTripId,
      orElse: () => tripProvider.trips.first,
    );
    
    showDialog(
      context: context,
      builder: (context) => BudgetCreationDialog(
        tripId: selectedTrip.id ?? '',
        onBudgetCreated: () {
          _loadData(); // Refresh data after budget creation
        },
      ),
    );
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


  
  /// Build individual calendar legend item
  Widget _buildCalendarLegendItem(String label, Color indicatorColor, Color backgroundColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            border: Border.all(color: indicatorColor.withValues(alpha: 0.5)),
          ),
          child: Center(
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: indicatorColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.quattrocento(
            fontSize: 10,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }



  /// Get icon for expense category
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
      case ExpenseCategory.concert:
        return Icons.music_note;
      case ExpenseCategory.cruising:
        return Icons.directions_boat;
      case ExpenseCategory.ferry:
        return Icons.directions_ferry;
      case ExpenseCategory.groundTransportation:
        return Icons.directions_bus;
      case ExpenseCategory.rail:
        return Icons.train;
      case ExpenseCategory.restaurant:
        return Icons.restaurant;
      case ExpenseCategory.theater:
        return Icons.theater_comedy;
      case ExpenseCategory.tour:
        return Icons.tour;
      case ExpenseCategory.transportation:
        return Icons.directions_car;
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

/// Budget creation dialog widget
class BudgetCreationDialog extends StatefulWidget {
  final String tripId;
  final VoidCallback onBudgetCreated;

  const BudgetCreationDialog({
    super.key,
    required this.tripId,
    required this.onBudgetCreated,
  });

  @override
  State<BudgetCreationDialog> createState() => _BudgetCreationDialogState();
}

class _BudgetCreationDialogState extends State<BudgetCreationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _totalBudgetController = TextEditingController();
  final _dailyLimitController = TextEditingController();
  
  bool _isCreating = false;
  
  // Category allocations
  final Map<ExpenseCategory, double> _categoryAllocations = {};
  
  @override
  void initState() {
    super.initState();
    // Pre-fill with default budget if needed
    // Note: Trip budget info would need to be fetched separately with tripId
  }
  
  @override
  void dispose() {
    _totalBudgetController.dispose();
    _dailyLimitController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Header
              Row(
                children: [
                  Icon(Icons.account_balance_wallet, 
                       color: Colors.blue[600], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Create Budget',
                      style: GoogleFonts.quattrocento(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Trip info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.flight, color: Colors.blue[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trip Budget',
                            style: GoogleFonts.quattrocento(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[800],
                            ),
                          ),
                          Text(
                            'Set your budget limits',
                            style: GoogleFonts.quattrocento(
                              fontSize: 12,
                              color: Colors.blue[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Total budget field
              TextFormField(
                controller: _totalBudgetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Total Budget (VND)',
                  prefixIcon: Icon(Icons.monetization_on, color: Colors.green[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blue[600]!),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter total budget';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Daily limit field
              TextFormField(
                controller: _dailyLimitController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Daily Limit (Optional)',
                  prefixIcon: Icon(Icons.today, color: Colors.orange[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blue[600]!),
                  ),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid amount';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isCreating ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isCreating ? null : _createBudget,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                      ),
                      child: _isCreating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Create Budget'),
                    ),
                  ),
                ],
              ), // Close the Row children
            ], // Close the Column children  
          ), // Close the Form
        ), // Close the Container padding
      ), // Close the ConstrainedBox child
    ), // Close the Dialog
    );
  }
  
  Future<void> _createBudget() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isCreating = true;
    });
    
    try {
      final totalBudget = double.parse(_totalBudgetController.text);
      final dailyLimit = _dailyLimitController.text.isNotEmpty 
          ? double.parse(_dailyLimitController.text) 
          : null;
      
      // Create budget through expense service
      final expenseService = ExpenseService();
      
      final budget = Budget(
        totalBudget: totalBudget,
        dailyLimit: dailyLimit,
      );
      
      await expenseService.createBudget(budget);
      
      if (mounted) {
        Navigator.pop(context);
        widget.onBudgetCreated();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Budget created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create budget: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }
}
