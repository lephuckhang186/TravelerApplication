import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlannerDetailScreen extends StatefulWidget {
  final Map<String, dynamic> plannerData;

  const PlannerDetailScreen({
    super.key,
    required this.plannerData,
  });

  @override
  State<PlannerDetailScreen> createState() => _PlannerDetailScreenState();
}

class _PlannerDetailScreenState extends State<PlannerDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey[700]),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.plannerData['name'] ?? 'Planner',
          style: GoogleFonts.quattrocento(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.grey[700]),
            onPressed: () {
              _showPlannerOptions();
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[50],
        child: Column(
          children: [
            // Header with trip info and stats
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.plannerData['name'] ?? 'Untitled Planner',
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (widget.plannerData['destination'] != null)
                              Text(
                                widget.plannerData['destination'],
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                      _buildQuickStats(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (widget.plannerData['startDate'] != null || widget.plannerData['endDate'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getDateRangeText(),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Database table header
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  Divider(height: 1, color: Colors.grey[200]),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Financial Tracker',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildViewButton('Table', true),
                            const SizedBox(width: 6),
                            _buildViewButton('Chart', false),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _addNewExpense,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7B61FF),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                elevation: 0,
                                minimumSize: Size.zero,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.add, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    'New',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Table content
            Expanded(
              child: Container(
                color: Colors.white,
                child: _buildNotionTable(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDateRangeText() {
    final startDate = widget.plannerData['startDate'];
    final endDate = widget.plannerData['endDate'];
    
    if (startDate != null && endDate != null) {
      return '${_formatDate(startDate)} - ${_formatDate(endDate)}';
    } else if (startDate != null) {
      return 'From ${_formatDate(startDate)}';
    } else if (endDate != null) {
      return 'Until ${_formatDate(endDate)}';
    }
    
    return 'No dates set';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  int _getDaysCount() {
    if (widget.plannerData['startDate'] != null && widget.plannerData['endDate'] != null) {
      final startDate = widget.plannerData['startDate'] as DateTime;
      final endDate = widget.plannerData['endDate'] as DateTime;
      return endDate.difference(startDate).inDays + 1;
    }
    return 0;
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatItem('Budget', '₫5.0M', Colors.blue),
          Container(
            width: 1,
            height: 16,
            color: Colors.grey[300],
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          _buildStatItem('Spent', '₫1.2M', Colors.orange),
          Container(
            width: 1,
            height: 16,
            color: Colors.grey[300],
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          _buildStatItem('Left', '₫3.8M', Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildViewButton(String text, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? Colors.grey[200] : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isSelected ? Colors.black87 : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildNotionTable() {
    // Sample data for demonstration
    final List<Map<String, dynamic>> expenses = [
      {
        'date': DateTime.now().subtract(const Duration(days: 1)),
        'description': 'Flight tickets',
        'category': 'Transportation',
        'amount': -2500000,
        'type': 'Expense',
      },
      {
        'date': DateTime.now().subtract(const Duration(days: 2)),
        'description': 'Hotel booking',
        'category': 'Accommodation',
        'amount': -1200000,
        'type': 'Expense',
      },
      {
        'date': DateTime.now().subtract(const Duration(days: 3)),
        'description': 'Restaurant dinner',
        'category': 'Food',
        'amount': -450000,
        'type': 'Expense',
      },
    ];

    return Column(
      children: [
        // Table header
        Container(
          color: Colors.grey[50],
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _buildTableHeader('Date', flex: 2),
              _buildTableHeader('Description', flex: 4),
              _buildTableHeader('Category', flex: 3),
              _buildTableHeader('Amount', flex: 3),
            ],
          ),
        ),
        
        // Table rows
        Expanded(
          child: expenses.length == 0
            ? _buildEmptyTableState()
            : ListView.builder(
                itemCount: expenses.length,
                itemBuilder: (context, index) {
                  return _buildTableRow(expenses[index], index);
                },
              ),
        ),
      ],
    );
  }

  Widget _buildTableHeader(String title, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> expense, int index) {
    final isExpense = expense['amount'] < 0;
    
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[100]!, width: 1),
        ),
      ),
      child: InkWell(
        onTap: () => _editExpense(expense),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date
              Expanded(
                flex: 2,
                child: Text(
                  _formatTableDate(expense['date']),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ),
              
              // Description
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    expense['description'],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ),
              
              // Category
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(expense['category']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      expense['category'],
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: _getCategoryColor(expense['category']),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              
              // Amount
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatCurrency(expense['amount'].abs()),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isExpense ? Colors.red[600] : Colors.green[600],
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                          size: 10,
                          color: isExpense ? Colors.red : Colors.green,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          expense['type'],
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyTableState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No expenses yet',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start tracking your travel expenses by adding your first entry',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTableDate(DateTime date) {
    return '${date.day}/${date.month}';
  }

  String _formatCurrency(int amount) {
    return '₫${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'transportation':
        return Colors.blue;
      case 'accommodation':
        return Colors.orange;
      case 'food':
        return Colors.green;
      case 'entertainment':
        return Colors.purple;
      case 'shopping':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  void _addNewExpense() {
    _showMessage('Add new expense functionality coming soon...');
  }

  void _editExpense(Map<String, dynamic> expense) {
    _showMessage('Edit expense functionality coming soon...');
  }

  Widget _buildStatsCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.quattrocento(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.quattrocento(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, String description, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.quattrocento(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.quattrocento(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              Icons.timeline,
              size: 30,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No activity yet',
            style: GoogleFonts.quattrocento(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start planning to see your activity timeline here',
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

  void _showPlannerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Planner'),
              onTap: () {
                Navigator.pop(context);
                _showMessage('Edit functionality coming soon...');
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Planner'),
              onTap: () {
                Navigator.pop(context);
                _showMessage('Share functionality coming soon...');
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Duplicate'),
              onTap: () {
                Navigator.pop(context);
                _showMessage('Duplicate functionality coming soon...');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              textColor: Colors.red,
              iconColor: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _confirmDelete();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showItineraryOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Plan Your Itinerary',
              style: GoogleFonts.quattrocento(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildOptionTile(Icons.place, 'Add Destination', 'Add places you want to visit'),
            _buildOptionTile(Icons.event, 'Add Activity', 'Plan activities and tours'),
            _buildOptionTile(Icons.hotel, 'Add Accommodation', 'Book hotels and stays'),
            _buildOptionTile(Icons.restaurant, 'Add Restaurant', 'Find places to eat'),
            _buildOptionTile(Icons.directions_car, 'Add Transportation', 'Plan your travel routes'),
          ],
        ),
      ),
    );
  }

  void _showBudgetOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Manage Budget',
              style: GoogleFonts.quattrocento(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildOptionTile(Icons.account_balance_wallet, 'Set Budget', 'Set your total trip budget'),
            _buildOptionTile(Icons.receipt, 'Add Expense', 'Track your spending'),
            _buildOptionTile(Icons.pie_chart, 'Budget Categories', 'Organize budget by categories'),
            _buildOptionTile(Icons.trending_up, 'Expense Analytics', 'View spending insights'),
            _buildOptionTile(Icons.currency_exchange, 'Currency Converter', 'Convert currencies'),
          ],
        ),
      ),
    );
  }

  void _showDiscoverOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Discover Places',
              style: GoogleFonts.quattrocento(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildOptionTile(Icons.explore, 'AI Recommendations', 'Get personalized suggestions'),
            _buildOptionTile(Icons.star, 'Top Attractions', 'Popular tourist destinations'),
            _buildOptionTile(Icons.local_dining, 'Local Cuisine', 'Best restaurants and food'),
            _buildOptionTile(Icons.shopping_bag, 'Shopping Areas', 'Markets and shopping centers'),
            _buildOptionTile(Icons.nightlife, 'Nightlife', 'Bars, clubs, and entertainment'),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF7B61FF).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF7B61FF), size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.quattrocento(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.quattrocento(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        _showMessage('$title functionality coming soon...');
      },
    );
  }

  void _showAddOptions() {
    _showItineraryOptions(); // Redirect to itinerary options
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Planner',
          style: GoogleFonts.quattrocento(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${widget.plannerData['name']}"? This action cannot be undone.',
          style: GoogleFonts.quattrocento(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.quattrocento(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to plan screen
              _showMessage('Planner deleted');
            },
            child: Text(
              'Delete',
              style: GoogleFonts.quattrocento(color: Colors.red),
            ),
          ),
        ],
      ),
    );
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