import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../../Core/theme/app_theme.dart';
import '../../Core/providers/app_mode_provider.dart';
import '../../Expense/providers/expense_provider.dart';
import '../../Expense/models/expense_models.dart';
import '../../Login/services/auth_service.dart';
import '../../Plan/providers/trip_planning_provider.dart';
import '../../Plan/providers/collaboration_provider.dart';
import '../../Plan/models/trip_model.dart';

/// Enum for trip date status
enum TripDateStatus { none, upcoming, active, completed }

/// Class for status colors
class StatusColors {
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final Color indicatorColor;

  StatusColors({
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
    required this.indicatorColor,
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
  int _categoryTabIndex = 0; // 0: Subcategory, 1: Category
  String? _selectedTripId; // Selected trip for filtering
  bool _isTripSelectionLoading = false; // Loading state for trip selection
  // Removed unused _budgetStatus field

  final ValueNotifier<String?> _selectedTripNotifier = ValueNotifier<String?>(
    null,
  );

  late TabController _mainTabController;
  late TabController _categoryTabController;
  ExpenseProvider? _expenseProvider;

  // Getter to safely access expense provider
  ExpenseProvider get expenseProvider {
    if (_expenseProvider == null) {
      throw StateError(
        'ExpenseProvider not initialized. Make sure the widget is properly built.',
      );
    }
    return _expenseProvider!;
  }

  /// Get ALL trips from both private and collaboration providers for analysis
  /// This ensures tags show the correct source for each activity regardless of current mode
  List<TripModel> _getTripsForCurrentMode() {
    try {
      final allTrips = <TripModel>[];

      // Always load private trips
      final tripProvider = context.read<TripPlanningProvider>();

      final privateTrips = tripProvider.trips.where((trip) {
        // Ensure trip ID exists
        return trip.id != null;
      }).toList();

      allTrips.addAll(privateTrips);

      // Always load collaboration trips
      final collaborationProvider = context.read<CollaborationProvider>();

      // Add owned trips
      allTrips.addAll(
        collaborationProvider.mySharedTrips.map<TripModel>((sharedTrip) {
          return TripModel(
            id: sharedTrip.id,
            name: sharedTrip.name,
            destination: sharedTrip.destination,
            startDate: sharedTrip.startDate,
            endDate: sharedTrip.endDate,
            description: sharedTrip.description,
            budget: sharedTrip.budget,
            activities: sharedTrip.activities,
          );
        }),
      );

      // Add shared trips
      allTrips.addAll(
        collaborationProvider.sharedWithMeTrips.map<TripModel>((sharedTrip) {
          return TripModel(
            id: sharedTrip.id,
            name: sharedTrip.name,
            destination: sharedTrip.destination,
            startDate: sharedTrip.startDate,
            endDate: sharedTrip.endDate,
            description: sharedTrip.description,
            budget: sharedTrip.budget,
            activities: sharedTrip.activities,
          );
        }),
      );

      // Check if selected trip still exists, if not clear selection and cleanup
      if (_selectedTripId != null) {
        final selectedTripExists = allTrips.any((trip) => trip.id == _selectedTripId);
        if (!selectedTripExists) {
          // Clear selection and notify listeners
          _selectedTripId = null;
          _selectedTripNotifier.value = null;
          // Force refresh data and cleanup orphaned expenses
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (mounted) {
              await _forceRefreshAllData();
              // Clean up expenses that belong to deleted trips
              await _cleanupOrphanedExpenses(allTrips);
            }
          });
        }
      }

      return allTrips;
    } catch (e) {
      // Fallback: try to get trips from TripPlanningProvider as last resort
      try {
        final tripProvider = context.read<TripPlanningProvider>();
        return tripProvider.trips.where((trip) => trip.id != null).toList();
      } catch (fallbackError) {
        return [];
      }
    }
  }

  /// Check if user has any trips at all
  bool _hasAnyTrips() {
    try {
      final tripProvider = context.read<TripPlanningProvider>();
      final collaborationProvider = context.read<CollaborationProvider>();

      return tripProvider.trips.isNotEmpty ||
             collaborationProvider.mySharedTrips.isNotEmpty ||
             collaborationProvider.sharedWithMeTrips.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

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
    _selectedTripNotifier.value = _selectedTripId;
  }

  bool _hasInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize providers when dependencies are ready - ONLY ONCE
    if (_expenseProvider == null && mounted && !_hasInitialized) {
      _hasInitialized = true;
      _expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
      // Schedule initialization for next frame to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _initializeWithAuth();
          _initializeTripProvider();
        }
      });
    }
  }

  /// Initialize with authentication and load data
  Future<void> _initializeWithAuth() async {
    try {
      final authService = AuthService();
      final token = await authService.getIdToken();

      if (token != null && _expenseProvider != null) {
        expenseProvider.setAuthToken(token);
        // Load trips first to get the selected trip ID
        await _refreshTripData();

        // Set default trip if none selected and trips exist
        if (mounted) {
          final tripProvider = Provider.of<TripPlanningProvider>(
            context,
            listen: false,
          );
          // Keep _selectedTripId as null to show "All Trip" by default
          if (tripProvider.trips.isEmpty) {
          } else {
          }
        }

        // IMPORTANT: Only load data AFTER trip selection is done
        await _loadData();
      } else {
        // User not authenticated, redirect to auth screen
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/auth');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Initialize both trip providers for analysis (always load all trips)
  Future<void> _initializeTripProvider() async {
    try {
      if (!mounted) return;

      // Always initialize both providers for analysis to show all trips
      final appModeProvider = Provider.of<AppModeProvider>(context, listen: false);

      if (appModeProvider.isCollaborationMode) {
        // In collaboration mode, initialize collaboration provider first
        final collaborationProvider = context.read<CollaborationProvider>();
        if (!collaborationProvider.hasSharedTrips && !collaborationProvider.isLoading) {
          await collaborationProvider.initialize();
        }
      } else {
        // In private mode, initialize trip planning provider
        final tripProvider = Provider.of<TripPlanningProvider>(
          context,
          listen: false,
        );

        if (tripProvider.trips.isEmpty && !tripProvider.isLoading) {
          await tripProvider.initialize();

          if (tripProvider.trips.isNotEmpty) {
            // Only run cleanup after successful trip loading
            await _cleanupOrphanedExpenses(tripProvider.trips);
          }
        }
      }
    } catch (e) {
      //
    }
  }

  /// Load data from backend
  Future<void> _loadData({bool forceRefresh = false}) async {
    if (_expenseProvider == null) return;

    // Get current month date range
    final currentDate = DateTime(_currentYear, _currentMonthIndex + 1, 1);
    final startDate = DateTime(currentDate.year, currentDate.month, 1);
    final endDate = DateTime(currentDate.year, currentDate.month + 1, 0);


    // Fetch data with trip-specific filtering where applicable
    await Future.wait([
      expenseProvider.fetchExpenses(
        startDate: startDate,
        endDate: endDate,
        tripId: _selectedTripId, // null = all trips, specific id = one trip
      ),
      expenseProvider.fetchExpenseSummary(tripId: _selectedTripId),
      expenseProvider.fetchCategoryStatus(),
      expenseProvider.fetchSpendingTrends(),
      expenseProvider.fetchBudgetStatus(tripId: _selectedTripId),
    ]);
  }

  /// Refresh trip data with better error handling
  Future<void> _refreshTripData() async {
    try {
      if (!mounted) return;

      final appModeProvider = Provider.of<AppModeProvider>(context, listen: false);

      if (appModeProvider.isCollaborationMode) {
        // In collaboration mode, refresh collaboration provider
        final collaborationProvider = Provider.of<CollaborationProvider>(
          context,
          listen: false,
        );

        try {
          await collaborationProvider.ensureInitialized().timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              throw Exception('Collaboration loading timed out');
            },
          );

        } catch (timeoutError) {
          // Show a subtle error message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Unable to load collaboration trips. Showing all expenses.',
                ),
                backgroundColor: Colors.orange[700],
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } else {
        // In private mode, refresh trip planning provider
        final tripProvider = Provider.of<TripPlanningProvider>(
          context,
          listen: false,
        );

        // Try to initialize trips with timeout protection
        try {
          await tripProvider.initialize().timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              throw Exception('Trip loading timed out');
            },
          );

          // DON'T auto-select trip - let user choose or default to "All Trips"
          // This prevents filtering out expenses without tripId
          if (tripProvider.trips.isNotEmpty) {
            //
          }

          // Always run cleanup if trip initialization completed successfully (even if result is 0 trips)
          // This ensures orphaned expenses from deleted trips get cleaned up
          if (!tripProvider.isLoading && tripProvider.error == null) {
            await _cleanupOrphanedExpenses(tripProvider.trips);
          } else if (tripProvider.error != null) {
            //
          } else {
            //
          }
        } catch (timeoutError) {
          // Don't crash the app - use cached trips if available
          if (tripProvider.trips.isNotEmpty) {
            // Don't auto-select - let user choose
          } else {
          // Show a subtle error message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Unable to load collaboration trips. Showing all expenses.',
                ),
                backgroundColor: Colors.orange[700],
                duration: const Duration(seconds: 2),
              ),
            );
          }
          }
        }
      }
    } catch (e) {
      //
    }
  }

  /// Enhanced cleanup for expenses associated with deleted trips
  Future<void> _cleanupOrphanedExpenses(List<TripModel> validTrips) async {
    if (_expenseProvider == null || !mounted) return;

    try {
      // Get trip provider from context
      final tripProvider = Provider.of<TripPlanningProvider>(
        context,
        listen: false,
      );

      // Note: validTrips can be empty if user legitimately has no trips
      // This is now safe because we only call this after confirming trip loading was successful
      final allExpenses = expenseProvider.expenses;
      final validTripIds = validTrips.map((trip) => trip.id).toSet();

      // Find expenses that have tripIds but the trip no longer exists
      final orphanedExpenses = allExpenses.where((expense) {
        final isOrphaned =
            expense.tripId != null && !validTripIds.contains(expense.tripId);
        if (isOrphaned) {
          //
        }
        return isOrphaned;
      }).toList();

      // Also find expenses from old trips that might not have proper tripId but are from deleted trips
      final expensesFromDeletedTrips = allExpenses.where((expense) {
        if (expense.tripId != null) return false; // Already handled above

        // Check if expense description contains a trip that no longer exists
        final tripFromDesc = _extractTripFromDescription(expense.description);
        if (tripFromDesc != null) {
          final matchesValidTrip = validTrips.any(
            (trip) =>
                trip.name == tripFromDesc ||
                trip.destination == tripFromDesc ||
                '${trip.name} (${trip.destination})' == tripFromDesc,
          );

          if (!matchesValidTrip) {
            return true;
          }
        }
        return false;
      }).toList();

      final allOrphanedExpenses = [
        ...orphanedExpenses,
        ...expensesFromDeletedTrips,
      ];

      if (allOrphanedExpenses.isNotEmpty) {
        // Force reload from server to get fresh data

        // Update the selected trip if it was deleted
        if (_selectedTripId != null &&
            !validTripIds.contains(_selectedTripId)) {
          if (mounted) {
            setState(() {
              _selectedTripId = tripProvider.trips.isNotEmpty
                  ? tripProvider.trips.first.id
                  : null;
            });
          }
        } else if (_selectedTripId == null && tripProvider.trips.isNotEmpty) {
          // Keep All Trip selected (null) - don't auto-select first trip
        }

        // Reload all data to ensure consistency - this should fetch fresh data from server
        await Future.wait([
          expenseProvider.fetchExpenses(
            startDate: DateTime(_currentYear, _currentMonthIndex + 1, 1),
            endDate: DateTime(_currentYear, _currentMonthIndex + 2, 0),
            tripId: _selectedTripId,
          ),
          expenseProvider.fetchExpenseSummary(tripId: _selectedTripId),
          expenseProvider.fetchBudgetStatus(tripId: _selectedTripId),
          expenseProvider.fetchCategoryStatus(),
          expenseProvider.fetchSpendingTrends(),
        ]);

        // Show completion notification
        if (!mounted) {
          //
        }
      } else {}
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Error cleaning up data. Please try again.'),
                ),
              ],
            ),
            backgroundColor: Colors.red[600],
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _cleanupOrphanedExpenses(validTrips),
            ),
          ),
        );
      }
    }
  }

  /// Force refresh all chart and list data
  Future<void> _forceRefreshAllData() async {
    if (_expenseProvider == null || !mounted) return;

    try {
      final appModeProvider = Provider.of<AppModeProvider>(context, listen: false);

      if (appModeProvider.isCollaborationMode) {
        // In collaboration mode, refresh collaboration provider
        final collaborationProvider = Provider.of<CollaborationProvider>(
          context,
          listen: false,
        );
        await collaborationProvider.ensureInitialized();
      } else {
        // In private mode, refresh trip planning provider
        final tripProvider = Provider.of<TripPlanningProvider>(
          context,
          listen: false,
        );

        // Force refresh trip data
        await tripProvider.initialize();

        // Always run cleanup if trip initialization was successful (even with 0 trips)
        if (!tripProvider.isLoading && tripProvider.error == null) {
          await _cleanupOrphanedExpenses(tripProvider.trips);
        }
      }

      // Then reload all expense data
      await _loadData();

      // Also refresh additional data
      await Future.wait([
        expenseProvider.fetchSpendingTrends(),
        expenseProvider.fetchCategoryStatus(),
      ]);

      if (mounted) {
        setState(() {
          // Force UI refresh
        });
      }
    } catch (e) {
      //
    }
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _categoryTabController.dispose();
    _selectedTripNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to both expense provider and collaboration provider changes
    return Consumer2<ExpenseProvider, CollaborationProvider>(
      builder: (context, expenseProvider, collaborationProvider, child) {
        // Show loading state until providers are initialized
        if (!_hasInitialized) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: const SafeArea(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        // Check if user has any trips at all
        final hasAnyTrips = _hasAnyTrips();

        if (!hasAnyTrips) {
          // Show empty state when no trips exist
          return Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.flight_takeoff,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No trips yet',
                        style: TextStyle(
                          fontFamily: 'Urbanist-Regular',
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Create your first trip to start tracking expenses and analyzing your travel spending patterns.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Urbanist-Regular',
                          fontSize: 16,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Navigate to trip creation screen
                          Navigator.pushReplacementNamed(context, '/home');
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Create Your First Trip'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                // Main tabs (Activities/Statistic)
                _buildMainTabs(),

                // Content
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Main tabs (Activities/Statistic)
  Widget _buildMainTabs() {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 2),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTabButton('Activities', 0, 'images/activities.png'),
          const SizedBox(width: 12),
          _buildTabButton('Statistic', 1, 'images/analytics.png'),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index, String imagePath) {
    final isSelected = _currentViewIndex == index;
    final scale = isSelected ? 1.4 : 1.0;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabChanged(index),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 200),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: EdgeInsets.symmetric(horizontal: isSelected ? 18 : 0),
            padding: EdgeInsets.symmetric(vertical: isSelected ? 14 : 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        AppColors.skyBlue.withValues(alpha: 0.9),
                        AppColors.steelBlue.withValues(alpha: 0.8),
                        AppColors.dodgerBlue.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: isSelected ? 0.9 : 0.0),
                  blurRadius: isSelected ? 15 : 10,
                  offset: const Offset(0, 3),
                  spreadRadius: isSelected ? 2 : 1,
                ),
              ],
            ),
            child: Transform.scale(
              scale: 1 / scale, // Inverse scale to keep text original size
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    imagePath,
                    width: 18,
                    height: 18,
                    color: isSelected ? Colors.white : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Urbanist-Regular',
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
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

          // Calendar or list view - Entire box scrollable
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        children: [
                          // Calendar with fixed height
                          SizedBox(
                            height: 305, // Fixed height for calendar (reduced)
                            child: _buildCalendarViewScrollable(),
                          ),

                          // Legend - with negative margin to bring closer
                          Transform.translate(
                            offset: const Offset(0, 3),
                            child: _buildCalendarLegend(),
                          ),

                          // Budget Status - between legend and expense list (only for specific trip)
                          if (_selectedTripId != null)
                            Transform.translate(
                              offset: const Offset(0, 3),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  top: 8,
                                  bottom: 8,
                                ),
                                child: _buildBudgetStatus(),
                              ),
                            ),

                          // Expense list - closer to legend
                          Transform.translate(
                            offset: Offset(0, _selectedTripId != null ? 3 : 6),
                            child: _buildExpenseList(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
                  // Chart area - Pie chart only
                  Expanded(
                    flex: 2,
                    child: Transform.translate(
                      offset: const Offset(
                        0,
                        -50,
                      ), // Move pie chart up 20px
                      child: _buildPieChart(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Category tabs - pushed up
                  Transform.translate(
                    offset: const Offset(0, -90),
                    child: _buildCategoryTabs(),
                  ),

                  // Category list - pushed up
                  Expanded(
                    child: Transform.translate(
                      offset: const Offset(0, -70),
                      child: _buildCategoryList(),
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

  /// Month selector with arrows and trip filter
  Widget _buildMonthSelector() {
    return Consumer4<TripPlanningProvider, ExpenseProvider, AppModeProvider, CollaborationProvider>(
      builder: (context, tripProvider, expenseProvider, appModeProvider, collaborationProvider, child) {
        // Ensure collaboration provider is initialized in collaboration mode
        if (appModeProvider.isCollaborationMode && !collaborationProvider.hasSharedTrips && !collaborationProvider.isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            collaborationProvider.ensureInitialized();
          });
          // Return loading state while initializing
          return Container(
            padding: const EdgeInsets.all(16),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        // Get trips based on current mode
        final trips = _getTripsForCurrentMode();
        final modeLabel = appModeProvider.isCollaborationMode ? ' (Collab)' : '';
        
        return Column(
          children: [
            // Trip Filter Row - DropdownButtonFormField2
            DropdownButtonHideUnderline(
              child: DropdownButton2<String?>(
                isExpanded: true,
                hint: Text(
                  'All Trips$modeLabel',
                  style: TextStyle(
                    fontFamily: 'Urbanist-Regular',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                items: [
                  // "All Trips" option
                  DropdownItem<String?>(
                    value: null,
                    child: Text(
                      'All Trips$modeLabel',
                      style: TextStyle(
                        fontFamily: 'Urbanist-Regular',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  // Individual trips from current mode
                  ...trips.map((trip) {
                    // Determine trip tag (P for Private, C for Collaboration, S for Shared)
                    String tag;
                    final collaborationProvider = context.read<CollaborationProvider>();

                    // Check if this trip is in the shared trips list (someone shared with me)
                    final isSharedTrip = collaborationProvider.sharedWithMeTrips.any(
                      (sharedTrip) => sharedTrip.id == trip.id,
                    );

                    if (isSharedTrip) {
                      tag = '(S)'; // Shared trip
                    } else {
                      // Check if this trip is in my owned trips list
                      final isOwnedCollabTrip = collaborationProvider.mySharedTrips.any(
                        (ownedTrip) => ownedTrip.id == trip.id,
                      );

                      if (isOwnedCollabTrip) {
                        tag = '(C)'; // Owned collaboration trip
                      } else {
                        tag = '(P)'; // Private trip
                      }
                    }

                    return DropdownItem<String?>(
                      value: trip.id,
                      child: Text(
                        '${trip.name} $tag',
                        style: TextStyle(
                          fontFamily: 'Urbanist-Regular',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }),
                ],
                valueListenable: _selectedTripNotifier,
                onChanged: (String? newValue) async {
                  if (newValue != _selectedTripId) {
                    setState(() {
                      _isTripSelectionLoading = true;
                      _selectedTripId = newValue;
                      _selectedTripNotifier.value = newValue;
                    });

                    try {
                      // Ensure collaboration provider is initialized first
                      final collaborationProvider = context.read<CollaborationProvider>();
                      if (!collaborationProvider.hasSharedTrips) {
                        await collaborationProvider.ensureInitialized();
                      }

                      // Small delay to ensure UI updates before heavy data loading
                      await Future.delayed(const Duration(milliseconds: 100));

                      await _forceRefreshAllData();

                      // Additional delay to ensure data is properly loaded
                      await Future.delayed(const Duration(milliseconds: 200));

                    } catch (e) {
                      // Show error but don't crash
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error loading trip data: $e'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isTripSelectionLoading = false;
                        });
                      }
                    }
                  }
                },
                selectedItemBuilder: (context) {
                  return [
                    Text(
                      'All Trips$modeLabel',
                      style: TextStyle(
                        fontFamily: 'Urbanist-Regular',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    ...trips.map((trip) {
                      return Text(
                        trip.name,
                        style: TextStyle(
                          fontFamily: 'Urbanist-Regular',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                        overflow: TextOverflow.ellipsis,
                      );
                    }),
                  ];
                },
                buttonStyleData: ButtonStyleData(
                  height: 50,
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                iconStyleData: IconStyleData(
                  icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                  iconSize: 24,
                ),
                dropdownStyleData: DropdownStyleData(
                  maxHeight: 150, // 3 items * ~50px per item = 150px
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  scrollbarTheme: ScrollbarThemeData(
                    thickness: WidgetStateProperty.all(0),
                    thumbVisibility: WidgetStateProperty.all(false),
                  ),
                ),
                menuItemStyleData: const MenuItemStyleData(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),

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
                  child: GestureDetector(
                    onTap: () => _showYearPicker(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_months[_currentMonthIndex]}/$_currentYear',
                            style: TextStyle(
                              fontFamily: 'Urbanist-Regular',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
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

  /// Calendar view with trip status colors (for scrollable version)
  Widget _buildCalendarViewScrollable() {
    return Consumer4<TripPlanningProvider, CollaborationProvider, AppModeProvider, ExpenseProvider>(
      builder: (context, tripProvider, collaborationProvider, appModeProvider, expenseProvider, child) {
        // Use the same trip source as the rest of the analysis screen
        final trips = _getTripsForCurrentMode();

        // Calculate the first day of the current month
        final currentMonthDate = DateTime(
          _currentYear,
          _currentMonthIndex + 1,
          1,
        );
        final firstDayOfMonth =
            currentMonthDate.weekday % 7; // Adjust for Sunday start
        final daysInMonth = DateTime(
          _currentYear,
          _currentMonthIndex + 2,
          0,
        ).day;

        return Column(
          children: [
            // Weekday headers
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
              ),
              child: Row(
                children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                    .map(
                      (day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(
                              fontFamily: 'Urbanist-Regular',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

            // Calendar grid - takes remaining space in SizedBox
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
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

                  final currentDate = DateTime(
                    _currentYear,
                    _currentMonthIndex + 1,
                    dayOffset,
                  );
                  final isSelected = expenseProvider.selectedDay == dayOffset;

                  // Get trip status for this date using the correct trips
                  final tripStatus = _getTripStatusForDate(
                    trips,
                    currentDate,
                  );
                  final statusColors = _getStatusColors(tripStatus);

                  return GestureDetector(
                    onTap: () => _onDayTap(dayOffset),
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.orange[100]
                            : statusColors.backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: statusColors.borderColor != null
                            ? Border.all(
                                color: statusColors.borderColor!,
                                width: 2,
                              )
                            : null,
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Text(
                              '$dayOffset',
                              style: TextStyle(
                                fontFamily: 'Urbanist-Regular',
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Colors.orange[800]
                                    : statusColors.textColor,
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
          ],
        );
      },
    );
  }

  /// Expense list for activities grouped by trip - Enhanced with proper deletion handling
  Widget _buildExpenseList() {
    return Consumer4<TripPlanningProvider, CollaborationProvider, ExpenseProvider, AppModeProvider>(
      builder: (context, tripProvider, collaborationProvider, expenseProvider, appModeProvider, child) {
        if (_expenseProvider == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // In collaboration mode, ensure trips are loaded before displaying
        if (appModeProvider.isCollaborationMode) {
          if (!collaborationProvider.hasSharedTrips && !collaborationProvider.isLoading) {
            // Force initialize collaboration provider
            WidgetsBinding.instance.addPostFrameCallback((_) {
              collaborationProvider.ensureInitialized();
            });
            return const Center(child: CircularProgressIndicator());
          }
          // If provider is loading, show loading indicator
          if (collaborationProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
        }

        return AnimatedBuilder(
          animation: expenseProvider,
          builder: (context, child) {
            if (expenseProvider.isLoading || _isTripSelectionLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (expenseProvider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Data loading error',
                      style: TextStyle(
                        fontFamily: 'Urbanist-Regular',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _loadData,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              );
            }

            final expenses = expenseProvider.expenses;

            if (expenses.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No transactions yet',
                        style: TextStyle(
                          fontFamily: 'Urbanist-Regular',
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Use the same trip list as the dropdown for consistency
            final availableTrips = _getTripsForCurrentMode();

            // Group expenses by trip with enhanced filtering - PASS THE CORRECT TRIPS
            final groupedExpenses = _groupExpensesByTripWithCleanup(
              expenses,
              availableTrips, // Use the correct trip list based on mode
            );

            if (groupedExpenses.isEmpty) {
              return Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.filter_alt_off,
                        size: 48,
                        color: Colors.orange[600],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No matching transactions',
                        style: TextStyle(
                          fontFamily: 'Urbanist-Regular',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedTripId != null
                            ? 'Selected trip has no transactions'
                            : 'Try changing filters or adding new transactions',
                        style: TextStyle(
                          fontFamily: 'Urbanist-Regular',
                          fontSize: 14,
                          color: Colors.orange[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

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
                    // Expenses for this trip
                    ...tripExpenses.map((expense) {
                      return GestureDetector(
                        onTap: () => _onExpenseTap(
                          expense.description.isNotEmpty == true
                              ? expense.description
                              : expense.category.displayName,
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: tripName == 'Other Expenses'
                                ? Colors.grey[50]
                                : Colors.blue[25],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: tripName == 'Other Expenses'
                                  ? Colors.grey[200]!
                                  : Colors.blue[100]!,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(
                                    expense.category,
                                  ).withValues(alpha: 0.2),
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
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            expense.description.isNotEmpty == true
                                                ? _extractActivityTitle(
                                                    expense.description,
                                                  )
                                                : expense.category.displayName,
                                            style: TextStyle(
                                              fontFamily: 'Urbanist-Regular',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
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
                                          _formatExpenseDate(
                                            expense.expenseDate,
                                          ),
                                          style: TextStyle(
                                            fontFamily: 'Urbanist-Regular',
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        if (_extractTripFromDescription(
                                              expense.description,
                                            ) !=
                                            null) ...[
                                          const SizedBox(width: 12),
                                          Icon(
                                            Icons.location_on,
                                            size: 12,
                                            color: Colors.blue[500],
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              _extractTripFromDescription(
                                                expense.description,
                                              )!,
                                              style: TextStyle(
                                                fontFamily: 'Urbanist-Regular',
                                                fontSize: 12,
                                                color: Colors.blue[600],
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '-${_formatMoney(expense.amount)}₫',
                                    style: TextStyle(
                                      fontFamily: 'Urbanist-Regular',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red[700],
                                    ),
                                  ),
                                  // Trip source badge below price (only show in All Trips mode)
                                  if (tripName != 'Other Expenses' && _selectedTripId == null) ...[
                                    const SizedBox(height: 4),
                                    _buildTripSourceBadge(tripName),
                                  ],
                                ],
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

  /// Enhanced group expenses by trip with cleanup
  Map<String, List<Expense>> _groupExpensesByTripWithCleanup(
    List<Expense> expenses,
    List<TripModel> trips,
  ) {
    // Use the same trip list that the dropdown uses for consistency
    final availableTrips = _getTripsForCurrentMode();

    // Determine trip source for tagging
    context.read<AppModeProvider>();

    final Map<String, List<Expense>> grouped = {};
    final validTripIds = trips.map((trip) => trip.id).toSet();

    // Filter expenses by current month/year AND valid trip IDs
    final validExpenses = expenses.where((expense) {
      // Filter by current month and year
      final expenseMonth = expense.expenseDate.month;
      final expenseYear = expense.expenseDate.year;
      final isCurrentMonth =
          expenseMonth == (_currentMonthIndex + 1) &&
          expenseYear == _currentYear;

      if (!isCurrentMonth) return false;

      // If expense has a tripId, it must be in the valid trips list
      if (expense.tripId != null) {
        return validTripIds.contains(expense.tripId);
      }
      // Expenses without tripId are considered valid (will be categorized as "Other Expenses")
      return true;
    }).toList();

    for (final expense in validExpenses) {
      String tripName = 'Other Expenses';
      String? associatedTripId;

      // First priority: Use expense tripId to find matching trip
      if (expense.tripId != null && validTripIds.contains(expense.tripId)) {
        final matchingTrip = availableTrips.firstWhere(
          (trip) => trip.id == expense.tripId,
          orElse: () =>
              availableTrips.first, // This should not happen due to filtering above
        );

        // Add tag to identify trip source (P for Private, C for Collaboration, S for Shared)
        String tag;
        final collaborationProvider = context.read<CollaborationProvider>();

        // Check if this trip is in the shared trips list (someone shared with me)
        final isSharedTrip = collaborationProvider.sharedWithMeTrips.any(
          (trip) => trip.id == matchingTrip.id,
        );

        if (isSharedTrip) {
          tag = 'S'; // Shared trip
        } else {
          // Check if this trip is in my owned trips list
          final isOwnedCollabTrip = collaborationProvider.mySharedTrips.any(
            (trip) => trip.id == matchingTrip.id,
          );

          if (isOwnedCollabTrip) {
            tag = 'C'; // Owned collaboration trip
          } else {
            tag = 'P'; // Private trip
          }
        }

        tripName = '${matchingTrip.name} (${matchingTrip.destination}) [$tag]';
        associatedTripId = matchingTrip.id;
      }

      // Second priority: Try to find trip from expense description
      if (associatedTripId == null) {
        final tripIdFromDesc = _extractTripFromDescription(expense.description);
        if (tripIdFromDesc != null) {
          // Find matching trip by ID (since descriptions contain trip IDs, not names)
          TripModel? matchingTrip;
          try {
            matchingTrip = availableTrips.firstWhere(
              (trip) => trip.id == tripIdFromDesc,
            );
          } catch (e) {
            matchingTrip = null;
          }

          if (matchingTrip != null) {
            // Add tag to identify trip source (P for Private, C for Collaboration, S for Shared)
            String tag;
            final collaborationProvider = context.read<CollaborationProvider>();

            // Check if this trip is in the shared trips list (someone shared with me)
            final isSharedTrip = collaborationProvider.sharedWithMeTrips.any(
              (trip) => trip.id == matchingTrip!.id,
            );

            if (isSharedTrip) {
              tag = 'S'; // Shared trip
            } else {
              // Check if this trip is in my owned trips list
              final isOwnedCollabTrip = collaborationProvider.mySharedTrips.any(
                (trip) => trip.id == matchingTrip!.id,
              );

              if (isOwnedCollabTrip) {
                tag = 'C'; // Owned collaboration trip
              } else {
                tag = 'P'; // Private trip
              }
            }

            tripName = '${matchingTrip.name} (${matchingTrip.destination}) [$tag]';
            associatedTripId = matchingTrip.id;
          } else {
            tripName =
                tripIdFromDesc; // Keep trip ID as name if no trip found
          }
        }
      }

      // Third priority: Try to match expense date with trip dates
      if (associatedTripId == null) {
        for (final trip in availableTrips) {
          if (expense.expenseDate.isAfter(
                trip.startDate.subtract(const Duration(days: 1)),
              ) &&
              expense.expenseDate.isBefore(
                trip.endDate.add(const Duration(days: 2)),
              )) {
            // Add tag to identify trip source (P for Private, C for Collaboration, S for Shared)
            String tag;
            final collaborationProvider = context.read<CollaborationProvider>();

            // Check if this trip is in the shared trips list (someone shared with me)
            final isSharedTrip = collaborationProvider.sharedWithMeTrips.any(
              (sharedTrip) => sharedTrip.id == trip.id,
            );

            if (isSharedTrip) {
              tag = 'S'; // Shared trip
            } else {
              // Check if this trip is in my owned trips list
              final isOwnedCollabTrip = collaborationProvider.mySharedTrips.any(
                (ownedTrip) => ownedTrip.id == trip.id,
              );

              if (isOwnedCollabTrip) {
                tag = 'C'; // Owned collaboration trip
              } else {
                tag = 'P'; // Private trip
              }
            }

            tripName = '${trip.name} (${trip.destination}) [$tag]';
            associatedTripId = trip.id;
            break;
          }
        }
      }

      // Filter by selected trip if one is selected
      if (_selectedTripId != null) {
        // Only include expenses associated with the selected trip
        if (associatedTripId != _selectedTripId) {
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
    if (_expenseProvider == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return AnimatedBuilder(
      animation: expenseProvider,
      builder: (context, child) {
        return _buildPieChartContent();
      },
    );
  }

  Widget _buildPieChartContent() {
    if (expenseProvider.isSummaryLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Get data based on selected tab
    Map<String, double> chartData;

    if (_categoryTabIndex == 0) {
      // Subcategory tab - group by expense description (activity title)
      final subcategoryBreakdown = <String, double>{};

      // Filter expenses by current month/year AND selected trip
      final filteredExpenses = expenseProvider.expenses.where((expense) {
        // Filter by current month and year
        final expenseMonth = expense.expenseDate.month;
        final expenseYear = expense.expenseDate.year;
        final isCurrentMonth =
            expenseMonth == (_currentMonthIndex + 1) &&
            expenseYear == _currentYear;

        if (!isCurrentMonth) return false;

        // Filter by selected trip (null = all trips)
        if (_selectedTripId != null && expense.tripId != _selectedTripId) {
          return false;
        }

        return true;
      });

      for (final expense in filteredExpenses) {
        final rawDescription = expense.description.isNotEmpty
            ? expense.description
            : expense.category.displayName;
        final subcategoryName = _extractActivityTitle(rawDescription);
        subcategoryBreakdown[subcategoryName] =
            (subcategoryBreakdown[subcategoryName] ?? 0) + expense.amount;
      }
      chartData = subcategoryBreakdown;
    } else {
      // Category tab - group by category with filtering
      final categoryBreakdown = <String, double>{};

      // Filter expenses by current month/year AND selected trip
      final filteredExpenses = expenseProvider.expenses.where((expense) {
        // Filter by current month and year
        final expenseMonth = expense.expenseDate.month;
        final expenseYear = expense.expenseDate.year;
        final isCurrentMonth =
            expenseMonth == (_currentMonthIndex + 1) &&
            expenseYear == _currentYear;

        if (!isCurrentMonth) return false;

        // Filter by selected trip (null = all trips)
        if (_selectedTripId != null && expense.tripId != _selectedTripId) {
          return false;
        }

        return true;
      });

      for (final expense in filteredExpenses) {
        final categoryName = expense.category.displayName;
        categoryBreakdown[categoryName] =
            (categoryBreakdown[categoryName] ?? 0) + expense.amount;
      }

      chartData = categoryBreakdown;
    }

    if (chartData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No data available',
              style: TextStyle(
                fontFamily: 'Urbanist-Regular',
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
          'No expenses have been incurred yet.',
          style: TextStyle(
            fontFamily: 'Urbanist-Regular',
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
      // Both tabs now have displayName as key, no need for conversion
      final displayName = categoryEntry.key;

      return PieChartSectionData(
        value: categoryEntry.value,
        title: displayName.length > 15
            ? '${percentage.toStringAsFixed(0)}%'
            : displayName, // Show name or % based on length
        radius: 80, // Increase radius to 100 to make pie chart bigger
        color: colors[index % colors.length],
        titleStyle: TextStyle(
          fontFamily: 'Urbanist-Regular',
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
                  'Total Expenses',
                  style: TextStyle(
                    fontFamily: 'Urbanist-Regular',
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatMoney(total),
                  style: TextStyle(
                    fontFamily: 'Urbanist-Regular',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'VND',
                  style: TextStyle(
                    fontFamily: 'Urbanist-Regular',
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
            style: TextStyle(
              fontFamily: 'Urbanist-Regular',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.skyBlue : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 3,
            width: title.length * 8.0, // Dynamic width based on text length
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        AppColors.skyBlue.withValues(alpha: 0.9),
                        AppColors.steelBlue.withValues(alpha: 0.8),
                        AppColors.dodgerBlue.withValues(alpha: 0.7),
                      ],
                    )
                  : null,
              color: isSelected ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ],
      ),
    );
  }

  /// Category list
  Widget _buildCategoryList() {
    return AnimatedBuilder(
      animation: expenseProvider,
      builder: (context, child) {
        if (expenseProvider.isSummaryLoading ||
            expenseProvider.isCategoryLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        List<Map<String, dynamic>> categories = [];

        if (_categoryTabIndex == 0) {
          // Subcategory tab - group expenses by description (activity title)
          final subcategoryBreakdown = <String, double>{};

          // Filter expenses by current month/year AND selected trip
          final filteredExpenses = expenseProvider.expenses.where((expense) {
            // Filter by current month and year
            final expenseMonth = expense.expenseDate.month;
            final expenseYear = expense.expenseDate.year;
            final isCurrentMonth =
                expenseMonth == (_currentMonthIndex + 1) &&
                expenseYear == _currentYear;

            if (!isCurrentMonth) return false;

            // Filter by selected trip (null = all trips)
            if (_selectedTripId != null && expense.tripId != _selectedTripId) {
              return false;
            }

            return true;
          });

          for (final expense in filteredExpenses) {
            final rawDescription = expense.description.isNotEmpty
                ? expense.description
                : expense.category.displayName;
            final subcategoryName = _extractActivityTitle(rawDescription);
            subcategoryBreakdown[subcategoryName] =
                (subcategoryBreakdown[subcategoryName] ?? 0) + expense.amount;
          }

          if (subcategoryBreakdown.isNotEmpty) {
            // Define colors first
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

            var colorIndex = 0;
            categories =
                subcategoryBreakdown.entries.map((entry) {
                  // Try to find corresponding expense to get icon
                  Expense? expense;
                  try {
                    expense = expenseProvider.expenses.firstWhere(
                      (e) =>
                          _extractActivityTitle(
                            e.description.isNotEmpty
                                ? e.description
                                : e.category.displayName,
                          ) ==
                          entry.key,
                    );
                  } catch (e) {
                    expense = expenseProvider.expenses.isNotEmpty
                        ? expenseProvider.expenses.first
                        : null;
                  }

                  final categoryData = {
                    'title': entry.key,
                    'amount': entry.value,
                    'icon': _getCategoryIcon(
                      expense?.category ?? ExpenseCategory.miscellaneous,
                    ),
                    'categoryKey': entry.key,
                    'color':
                        colors[colorIndex %
                            colors.length], // Assign color before sorting
                  };
                  colorIndex++;
                  return categoryData;
                }).toList()..sort(
                  (a, b) =>
                      (b['amount'] as double).compareTo(a['amount'] as double),
                );
          }
        } else {
          // Category tab - group by category with filtering (same as pie chart)
          final categoryBreakdown = <String, double>{};

          // Filter expenses by current month/year AND selected trip
          final filteredExpenses = expenseProvider.expenses.where((expense) {
            // Filter by current month and year
            final expenseMonth = expense.expenseDate.month;
            final expenseYear = expense.expenseDate.year;
            final isCurrentMonth =
                expenseMonth == (_currentMonthIndex + 1) &&
                expenseYear == _currentYear;

            if (!isCurrentMonth) return false;

            // Filter by selected trip (null = all trips)
            if (_selectedTripId != null && expense.tripId != _selectedTripId) {
              return false;
            }

            return true;
          });

          for (final expense in filteredExpenses) {
            final categoryName = expense.category.displayName;
            categoryBreakdown[categoryName] =
                (categoryBreakdown[categoryName] ?? 0) + expense.amount;
          }

          if (categoryBreakdown.isNotEmpty) {
            // Define colors first
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

            var colorIndex = 0;
            final expensesList = filteredExpenses.toList();

            categories = categoryBreakdown.entries.map((entry) {
              // Find a representative expense to get icon
              Expense? expense;
              try {
                expense = expensesList.firstWhere(
                  (e) => e.category.displayName == entry.key,
                );
              } catch (e) {
                expense = expensesList.isNotEmpty ? expensesList.first : null;
              }

              final categoryData = {
                'title': entry.key,
                'amount': entry.value,
                'icon': expense != null
                    ? _getCategoryIcon(expense.category)
                    : Icons.category,
                'categoryKey': entry.key,
                'color':
                    colors[colorIndex %
                        colors.length], // Assign color before sorting
              };
              colorIndex++;
              return categoryData;
            }).toList();

            // Sort by amount descending
            categories.sort(
              (a, b) =>
                  (b['amount'] as double).compareTo(a['amount'] as double),
            );
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
                  'No category data yet',
                  style: TextStyle(
                    fontFamily: 'Urbanist-Regular',
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

            // Get color from category data (assigned before sorting)
            final categoryColor = category['color'] as Color;

            return GestureDetector(
              onTap: () => _onCategoryTap(category['title'] as String),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: categoryColor.withValues(
                      alpha: 0.3,
                    ), // Border màu nhẹ
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

  /// Show month and year picker dialog with animated gradient style
  Future<void> _showYearPicker() async {
    int tempMonth = _currentMonthIndex;
    int tempYear = _currentYear;

    // Create scroll controllers for auto-scrolling
    final monthScrollController = ScrollController(
      initialScrollOffset:
          _currentMonthIndex * 52.0, // 52 = item height + margin
    );
    final yearScrollController = ScrollController(
      initialScrollOffset: (_currentYear - 2000) * 52.0,
    );

    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              alignment: Alignment.center,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
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
                  ),
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Select Month & Year',
                                style: TextStyle(
                                  fontFamily: 'Urbanist-Regular',
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ),
                      // Two columns: Month and Year
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 350),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Month column
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Text(
                                          'Month',
                                          style: TextStyle(
                                            fontFamily: 'Urbanist-Regular',
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: ListView.builder(
                                          controller: monthScrollController,
                                          itemCount: 12,
                                          itemBuilder: (context, index) {
                                            final isSelected =
                                                tempMonth == index;
                                            return GestureDetector(
                                              onTap: () {
                                                setDialogState(() {
                                                  tempMonth = index;
                                                });
                                              },
                                              child: Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? Colors.white
                                                      : Colors.transparent,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    _months[index],
                                                    style: TextStyle(
                                                      fontFamily:
                                                          'Urbanist-Regular',
                                                      fontSize: 14,
                                                      fontWeight: isSelected
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                      color: isSelected
                                                          ? AppColors.steelBlue
                                                          : Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Year column
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Text(
                                          'Year',
                                          style: TextStyle(
                                            fontFamily: 'Urbanist-Regular',
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: ListView.builder(
                                          controller: yearScrollController,
                                          itemCount: 101, // 2000-2100
                                          itemBuilder: (context, index) {
                                            final year = 2000 + index;
                                            final isSelected = tempYear == year;
                                            return GestureDetector(
                                              onTap: () {
                                                setDialogState(() {
                                                  tempYear = year;
                                                });
                                              },
                                              child: Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? Colors.white
                                                      : Colors.transparent,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    year.toString(),
                                                    style: TextStyle(
                                                      fontFamily:
                                                          'Urbanist-Regular',
                                                      fontSize: 14,
                                                      fontWeight: isSelected
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                      color: isSelected
                                                          ? AppColors.steelBlue
                                                          : Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // OK Button
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: 16,
                          left: 16,
                          right: 16,
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context, {
                              'month': tempMonth,
                              'year': tempYear,
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.steelBlue,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'OK',
                            style: TextStyle(
                              fontFamily: 'Urbanist-Regular',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    // Dispose controllers
    monthScrollController.dispose();
    yearScrollController.dispose();

    if (result != null) {
      setState(() {
        _currentMonthIndex = result['month']!;
        _currentYear = result['year']!;
      });
      _loadData();
      _refreshTripData();
    }
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

  /// Get trip status for a specific date
  TripDateStatus _getTripStatusForDate(List<TripModel> trips, DateTime date) {
    for (final trip in trips) {
      // Check if date falls within trip duration
      final tripStart = DateTime(
        trip.startDate.year,
        trip.startDate.month,
        trip.startDate.day,
      );
      final tripEnd = DateTime(
        trip.endDate.year,
        trip.endDate.month,
        trip.endDate.day,
      );
      final checkDate = DateTime(date.year, date.month, date.day);

      if (checkDate.isAtSameMomentAs(tripStart) ||
          checkDate.isAtSameMomentAs(tripEnd) ||
          (checkDate.isAfter(tripStart) && checkDate.isBefore(tripEnd))) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        if (checkDate.isAfter(today)) {
          return TripDateStatus.upcoming;
        } else if (checkDate.isAtSameMomentAs(today) ||
            (checkDate.isAfter(tripStart) &&
                checkDate.isBefore(tripEnd.add(const Duration(days: 1))))) {
          return TripDateStatus.active;
        } else {
          return TripDateStatus.completed;
        }
      }
    }
    return TripDateStatus.none;
  }

  /// Get colors for trip status
  StatusColors _getStatusColors(TripDateStatus status) {
    switch (status) {
      case TripDateStatus.upcoming:
        return StatusColors(
          backgroundColor: Colors.blue[50]!,
          textColor: Colors.blue[800]!,
          borderColor: Colors.blue[200],
          indicatorColor: Colors.blue[600]!,
        );
      case TripDateStatus.active:
        return StatusColors(
          backgroundColor: Colors.green[50]!,
          textColor: Colors.green[800]!,
          borderColor: Colors.green[300],
          indicatorColor: Colors.green[600]!,
        );
      case TripDateStatus.completed:
        return StatusColors(
          backgroundColor: Colors.grey[100]!,
          textColor: Colors.grey[700]!,
          borderColor: null,
          indicatorColor: Colors.grey[500]!,
        );
      case TripDateStatus.none:
        return StatusColors(
          backgroundColor: Colors.transparent,
          textColor: Colors.black87,
          borderColor: null,
          indicatorColor: Colors.transparent,
        );
    }
  }

  /// Build calendar legend
  Widget _buildCalendarLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCalendarLegendItem(
            'Upcoming',
            Colors.blue[600]!,
            Colors.blue[50]!,
          ),
          _buildCalendarLegendItem(
            'Active',
            Colors.green[600]!,
            Colors.green[50]!,
          ),
          _buildCalendarLegendItem(
            'Completed',
            Colors.grey[500]!,
            Colors.grey[100]!,
          ),
        ],
      ),
    );
  }

  /// Build individual calendar legend item
  Widget _buildCalendarLegendItem(
    String label,
    Color indicatorColor,
    Color backgroundColor,
  ) {
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
          style: TextStyle(
            fontFamily: 'Urbanist-Regular',
            fontSize: 10,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  /// Build compact budget status for calendar view
  Widget _buildBudgetStatus() {
    return Consumer4<TripPlanningProvider, CollaborationProvider, ExpenseProvider, AppModeProvider>(
      builder: (context, tripProvider, collaborationProvider, expenseProvider, appModeProvider, child) {
        if (_selectedTripId == null) return Container();

        // Get the correct trip based on mode
        final availableTrips = _getTripsForCurrentMode();
        final selectedTrip = availableTrips.firstWhere(
          (trip) => trip.id == _selectedTripId,
          orElse: () => availableTrips.isNotEmpty ? availableTrips.first : TripModel(
            id: 'dummy',
            name: 'Unknown Trip',
            destination: 'Unknown',
            startDate: DateTime.now(),
            endDate: DateTime.now(),
          ),
        );

        // Calculate actual spent from current expenses for this specific trip AND current month
        double actualSpent = expenseProvider.expenses
            .where((expense) {
              // Filter by trip ID
              if (expense.tripId != _selectedTripId) return false;

              // Filter by current month and year
              final expenseMonth = expense.expenseDate.month;
              final expenseYear = expense.expenseDate.year;
              final isCurrentMonth =
                  expenseMonth == (_currentMonthIndex + 1) &&
                  expenseYear == _currentYear;

              return isCurrentMonth;
            })
            .fold(0.0, (sum, expense) => sum + expense.amount);

        final totalBudget = selectedTrip.budget?.estimatedCost ?? 0.0;
        final remaining = totalBudget - actualSpent;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Budget metrics row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCompactBudgetMetric('Total', totalBudget, Colors.white),
                  Container(
                    width: 1,
                    height: 20,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  _buildCompactBudgetMetric('Spent', actualSpent, Colors.white),
                  Container(
                    width: 1,
                    height: 20,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  _buildCompactBudgetMetric(
                    'Remaining',
                    remaining,
                    Colors.white,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Budget usage progress bar
              _buildBudgetUsageBar(totalBudget, actualSpent),
            ],
          ),
        );
      },
    );
  }

  /// Build compact budget metric
  Widget _buildCompactBudgetMetric(String label, double amount, Color color) {
    // Determine if amount is negative for special formatting
    final isNegative = amount < 0;
    final displayAmount = isNegative ? amount.abs() : amount;
    
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Urbanist-Regular',
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${isNegative ? '-' : ''}${_formatMoney(displayAmount)}',
          style: TextStyle(
            fontFamily: 'Urbanist-Regular',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isNegative ? Colors.red[300] : color,
          ),
        ),
      ],
    );
  }

  /// Build budget usage progress bar
  Widget _buildBudgetUsageBar(double totalBudget, double actualSpent) {
    final percentage = totalBudget > 0
        ? (actualSpent / totalBudget * 100)
        : 0.0;
    
    // Determine if over budget
    final isOverBudget = percentage > 100;
    final displayPercentage = percentage.clamp(0, 100);

    return Column(
      children: [
        // Progress bar
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (displayPercentage / 100).clamp(0, 1),
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverBudget ? Colors.red[300]! : Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Percentage text
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Budget Usage',
              style: TextStyle(
                fontFamily: 'Urbanist-Regular',
                fontSize: 9,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            Row(
              children: [
                if (isOverBudget)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.warning,
                      size: 10,
                      color: Colors.red[300],
                    ),
                  ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontFamily: 'Urbanist-Regular',
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isOverBudget ? Colors.red[300] : Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Build budget status card

  /// Build budget warning indicator

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

  /// Build trip source badge (P for Private, C for Collaboration, S for Shared)
  Widget _buildTripSourceBadge(String tripName) {
    // Extract the tag from trip name (format: "Trip Name (Destination) [P|C|S]")
    final tagMatch = RegExp(r'\[([PCS])\]$').firstMatch(tripName);
    if (tagMatch == null) return const SizedBox.shrink();

    final tag = tagMatch.group(1)!;

    // Define colors for each tag type
    Color backgroundColor;
    Color borderColor;
    Color textColor;

    switch (tag) {
      case 'P':
        backgroundColor = Colors.red[100]!;
        borderColor = Colors.red[300]!;
        textColor = Colors.red[700]!;
        break;
      case 'C':
        backgroundColor = Colors.green[100]!;
        borderColor = Colors.green[300]!;
        textColor = Colors.green[700]!;
        break;
      case 'S':
        backgroundColor = Colors.blue[100]!;
        borderColor = Colors.blue[300]!;
        textColor = Colors.blue[700]!;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontFamily: 'Urbanist-Regular',
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
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
}

/// Budget creation dialog widget
class _BudgetCreationDialog extends StatefulWidget {
  final TripModel trip;
  final VoidCallback onBudgetCreated;

  const _BudgetCreationDialog({
    required this.trip,
    required this.onBudgetCreated,
  });

  @override
  State<_BudgetCreationDialog> createState() => _BudgetCreationDialogState();
}

class _BudgetCreationDialogState extends State<_BudgetCreationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _totalBudgetController = TextEditingController();
  final _dailyLimitController = TextEditingController();

  bool _isCreating = false;

  // Category allocations
  // Removed unused _categoryAllocations field

  @override
  void initState() {
    super.initState();
    // Pre-fill with trip budget if available
    if (widget.trip.budget != null) {
      _totalBudgetController.text = widget.trip.budget!.estimatedCost
          .toString();
    }
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
                    Icon(
                      Icons.account_balance_wallet,
                      color: Colors.blue[600],
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Create Budget for ${widget.trip.name}',
                        style: TextStyle(
                          fontFamily: 'Urbanist-Regular',
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
                              widget.trip.destination,
                              style: TextStyle(
                                fontFamily: 'Urbanist-Regular',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[800],
                              ),
                            ),
                            Text(
                              '${widget.trip.durationDays} days trip',
                              style: TextStyle(
                                fontFamily: 'Urbanist-Regular',
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
                    prefixIcon: Icon(
                      Icons.monetization_on,
                      color: Colors.green[600],
                    ),
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
                        onPressed: _isCreating
                            ? null
                            : () => Navigator.pop(context),
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
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
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
      // Parse budget values and create budget through expense service
      final budgetAmount = double.parse(_totalBudgetController.text);
      final dailyLimitAmount = _dailyLimitController.text.isNotEmpty
          ? double.parse(_dailyLimitController.text)
          : null;

      // Get expense provider
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);

      // Create budget through expense provider
      final success = await expenseProvider.createBudget(
        budgetAmount,
        dailyLimit: dailyLimitAmount,
      );

      if (!success) {
        throw Exception(expenseProvider.error ?? 'Failed to create budget');
      }

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
