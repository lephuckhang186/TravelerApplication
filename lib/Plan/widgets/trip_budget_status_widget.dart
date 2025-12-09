import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/trip_model.dart';
import '../providers/trip_planning_provider.dart';

class TripBudgetStatusWidget extends StatefulWidget {
  final TripModel trip;
  final bool showDetails;

  const TripBudgetStatusWidget({
    super.key,
    required this.trip,
    this.showDetails = true,
  });

  @override
  State<TripBudgetStatusWidget> createState() => _TripBudgetStatusWidgetState();
}

class _TripBudgetStatusWidgetState extends State<TripBudgetStatusWidget> {
  Map<String, dynamic>? _budgetStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBudgetStatus();
  }

  @override
  void didUpdateWidget(TripBudgetStatusWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trip.id != widget.trip.id) {
      _loadBudgetStatus();
    }
  }

  Future<void> _loadBudgetStatus() async {
    if (widget.trip.id == null) return;

    setState(() => _isLoading = true);
    
    try {
      final tripProvider = Provider.of<TripPlanningProvider>(context, listen: false);
      final status = await tripProvider.getTripBudgetStatus(widget.trip.id!);
      
      if (mounted) {
        setState(() {
          _budgetStatus = status;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_budgetStatus == null && widget.trip.budget == null) {
      return const SizedBox.shrink();
    }

    return Consumer<TripPlanningProvider>(
      builder: (context, tripProvider, child) {
        final budget = widget.trip.budget;
        final status = _budgetStatus ?? {};
        
        final totalBudget = status['totalBudget']?.toDouble() ?? budget?.estimatedCost ?? 0.0;
        final totalSpent = status['totalSpent']?.toDouble() ?? budget?.actualCost ?? 0.0;
        final usagePercentage = status['usagePercentage']?.toDouble() ?? 0.0;
        final isOverBudget = status['isOverBudget'] ?? false;
        final remainingBudget = status['remainingBudget']?.toDouble() ?? (totalBudget - totalSpent);
        final daysRemaining = status['daysRemaining'] ?? 0;
        final recommendedDaily = status['recommendedDailySpending']?.toDouble() ?? 0.0;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: isOverBudget ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Budget Status',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadBudgetStatus,
                      tooltip: 'Refresh budget status',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Budget overview
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Budget',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            '${totalBudget.toStringAsFixed(0)} VND',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Spent',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            '${totalSpent.toStringAsFixed(0)} VND',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isOverBudget ? Colors.red[600] : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Remaining',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            '${remainingBudget.toStringAsFixed(0)} VND',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: remainingBudget < 0 ? Colors.red[600] : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
                          'Usage Progress',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '${usagePercentage.toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isOverBudget ? Colors.red[600] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: (usagePercentage / 100).clamp(0.0, 1.0),
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        usagePercentage > 100 ? Colors.red[400]! :
                        usagePercentage > 80 ? Colors.orange[400]! : Colors.blue[400]!,
                      ),
                    ),
                  ],
                ),
                
                if (widget.showDetails) ...[
                  const SizedBox(height: 16),
                  
                  // Additional details
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailCard(
                          context,
                          'Days Left',
                          daysRemaining.toString(),
                          Icons.calendar_today,
                          daysRemaining <= 0 ? Colors.red[400]! : Colors.grey[600]!,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDetailCard(
                          context,
                          'Recommended Daily',
                          '${recommendedDaily.toStringAsFixed(0)} VND',
                          Icons.trending_down,
                          recommendedDaily > (totalBudget / 10) ? Colors.orange[400]! : Colors.grey[600]!,
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Warning messages
                if (isOverBudget) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3), width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red[400], size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Over budget by ${(totalSpent - totalBudget).toStringAsFixed(0)} VND',
                            style: TextStyle(color: Colors.red[600], fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (usagePercentage > 80) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3), width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.orange[400], size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Warning: ${usagePercentage.toStringAsFixed(1)}% of budget used',
                            style: TextStyle(color: Colors.orange[600], fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}