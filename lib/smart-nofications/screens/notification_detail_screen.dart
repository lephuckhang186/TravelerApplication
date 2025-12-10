import 'package:flutter/material.dart';
import '../models/notification_models.dart';
import '../../core/theme/app_theme.dart';

class NotificationDetailScreen extends StatelessWidget {
  final SmartNotification notification;

  const NotificationDetailScreen({
    super.key,
    required this.notification,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Chi tiết thông báo',
          style: TextStyle(
            fontFamily: 'Urbanist-Regular',
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: notification.color.withValues(alpha: 0.1),
                    child: Icon(
                      notification.icon,
                      color: notification.color,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: TextStyle(
                            fontFamily: 'Urbanist-Regular',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDateTime(notification.createdAt),
                          style: TextStyle(
                            fontFamily: 'Urbanist-Regular',
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildSeverityChip(notification.severity),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Message content
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nội dung',
                    style: TextStyle(
                      fontFamily: 'Urbanist-Regular',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontFamily: 'Urbanist-Regular',
                      fontSize: 15,
                      height: 1.5,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),

            // Type-specific details
            if (notification.data != null) ...[
              const SizedBox(height: 20),
              _buildTypeSpecificDetails(),
            ],

            const SizedBox(height: 20),

            // Actions
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityChip(NotificationSeverity severity) {
    String label;
    Color color;

    switch (severity) {
      case NotificationSeverity.critical:
        label = 'Khẩn cấp';
        color = Colors.red;
        break;
      case NotificationSeverity.warning:
        label = 'Cảnh báo';
        color = Colors.orange;
        break;
      case NotificationSeverity.info:
        label = 'Thông tin';
        color = Colors.blue;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Urbanist-Regular',
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTypeSpecificDetails() {
    switch (notification.type) {
      case NotificationType.weather:
        return _buildWeatherDetails();
      case NotificationType.budget:
        return _buildBudgetDetails();
      case NotificationType.activity:
        return _buildActivityDetails();
    }
  }

  Widget _buildWeatherDetails() {
    if (notification.data == null) return const SizedBox();
    
    final data = notification.data!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wb_cloudy, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Chi tiết thời tiết',
                style: TextStyle(
                  fontFamily: 'Urbanist-Regular',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Vị trí', data['location'] ?? 'Không xác định'),
          _buildDetailRow('Tình trạng', data['condition'] ?? 'Không xác định'),
          _buildDetailRow('Nhiệt độ', '${data['temperature'] ?? 0}°C'),
          _buildDetailRow('Mô tả', data['description'] ?? 'Không có mô tả'),
        ],
      ),
    );
  }

  Widget _buildBudgetDetails() {
    if (notification.data == null) return const SizedBox();
    
    final data = notification.data!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.orange[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Chi tiết ngân sách',
                style: TextStyle(
                  fontFamily: 'Urbanist-Regular',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Handle both backend response format and BudgetWarning model format
          if (data['activityTitle'] != null)
            _buildDetailRow('Hoạt động', data['activityTitle']),
          
          // Backend format (from expense response)
          if (data['total_budget'] != null)
            _buildDetailRow('Ngân sách', '${_formatCurrency(data['total_budget'])} ${data['currency'] ?? 'VND'}'),
          if (data['total_spent'] != null)
            _buildDetailRow('Đã chi', '${_formatCurrency(data['total_spent'])} ${data['currency'] ?? 'VND'}'),
          if (data['overage'] != null)
            _buildDetailRow('Vượt quá', '${_formatCurrency(data['overage'])} ${data['currency'] ?? 'VND'}'),
          if (data['remaining'] != null)
            _buildDetailRow('Còn lại', '${_formatCurrency(data['remaining'])} ${data['currency'] ?? 'VND'}'),
          if (data['percentage_used'] != null)
            _buildDetailRow('Đã sử dụng', '${(data['percentage_used'] as num).round()}%'),
          
          // BudgetWarning model format
          if (data['estimatedCost'] != null)
            _buildDetailRow('Dự kiến', '${_formatCurrency(data['estimatedCost'])} ${data['currency'] ?? 'VND'}'),
          if (data['actualCost'] != null)
            _buildDetailRow('Thực tế', '${_formatCurrency(data['actualCost'])} ${data['currency'] ?? 'VND'}'),
          if (data['overageAmount'] != null && data['overagePercentage'] != null)
            _buildDetailRow('Vượt quá', '${_formatCurrency(data['overageAmount'])} (${(data['overagePercentage'] as num).round()}%)'),
        ],
      ),
    );
  }

  Widget _buildActivityDetails() {
    if (notification.data == null) return const SizedBox();
    
    final data = notification.data!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: Colors.green[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Chi tiết hoạt động',
                style: TextStyle(
                  fontFamily: 'Urbanist-Regular',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Hoạt động', data['activityTitle'] ?? 'Không xác định'),
          _buildDetailRow('Địa điểm', data['location'] ?? 'Không xác định'),
          _buildDetailRow('Thời gian bắt đầu', _formatDateTime(DateTime.parse(data['startTime']))),
          _buildDetailRow('Còn lại', '${data['minutesUntilStart']} phút'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontFamily: 'Urbanist-Regular',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Urbanist-Regular',
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Đóng'),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0';
    final num = amount is String ? double.tryParse(amount) ?? 0 : amount;
    return num.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}