import 'package:flutter/material.dart';
import '../../Core/theme/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _tripReminders = true;
  bool _expenseAlerts = true;
  bool _planUpdates = false;
  bool _systemUpdates = true;

  String _reminderTime = '1 ngày trước';
  String _expenseLimit = '500,000đ';

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
          'Cài đặt thông báo',
          style: TextStyle(fontFamily: 'Urbanist-Regular', 
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Thông báo chuyến đi'),
          _buildNotificationCard(
            icon: Icons.event,
            title: 'Nhắc nhở chuyến đi',
            subtitle: 'Nhận thông báo trước khi chuyến đi bắt đầu',
            value: _tripReminders,
            onChanged: (value) => setState(() => _tripReminders = value),
            hasSettings: true,
            settingsWidget: _buildReminderTimePicker(),
          ),

          _buildNotificationCard(
            icon: Icons.update,
            title: 'Cập nhật kế hoạch',
            subtitle: 'Thông báo khi có thay đổi trong kế hoạch',
            value: _planUpdates,
            onChanged: (value) => setState(() => _planUpdates = value),
          ),

          const SizedBox(height: 24),
          _buildSectionTitle('Quản lý chi tiêu'),
          _buildNotificationCard(
            icon: Icons.account_balance_wallet,
            title: 'Cảnh báo chi tiêu',
            subtitle: 'Thông báo khi vượt ngân sách đã đặt',
            value: _expenseAlerts,
            onChanged: (value) => setState(() => _expenseAlerts = value),
            hasSettings: true,
            settingsWidget: _buildExpenseLimitPicker(),
          ),

          const SizedBox(height: 24),
          _buildSectionTitle('Hệ thống'),
          _buildNotificationCard(
            icon: Icons.system_update,
            title: 'Cập nhật ứng dụng',
            subtitle: 'Thông báo về các tính năng và cập nhật mới',
            value: _systemUpdates,
            onChanged: (value) => setState(() => _systemUpdates = value),
          ),

          const SizedBox(height: 32),
          _buildQuickSetupButtons(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(fontFamily: 'Urbanist-Regular', 
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    bool hasSettings = false,
    Widget? settingsWidget,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(fontFamily: 'Urbanist-Regular', 
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(fontFamily: 'Urbanist-Regular', 
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: value,
                  onChanged: onChanged,
                  activeColor: AppColors.primary,
                ),
              ],
            ),
            if (hasSettings && value && settingsWidget != null) ...[
              const SizedBox(height: 16),
              settingsWidget,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReminderTimePicker() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            'Nhắc nhở trước:',
            style: TextStyle(fontFamily: 'Urbanist-Regular', 
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _showReminderTimePicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _reminderTime,
                style: TextStyle(fontFamily: 'Urbanist-Regular', 
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseLimitPicker() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, size: 16, color: Colors.orange),
          const SizedBox(width: 8),
          Text(
            'Cảnh báo khi chi tiêu vượt:',
            style: TextStyle(fontFamily: 'Urbanist-Regular', 
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _showExpenseLimitPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _expenseLimit,
                style: TextStyle(fontFamily: 'Urbanist-Regular', 
                  fontSize: 12,
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSetupButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _enableAllNotifications,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              'Bật tất cả',
              style: TextStyle(fontFamily: 'Urbanist-Regular', 
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: _disableAllNotifications,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey[400]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              'Tắt tất cả',
              style: TextStyle(fontFamily: 'Urbanist-Regular', 
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showReminderTimePicker() {
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
              'Nhắc nhở trước chuyến đi',
              style: TextStyle(fontFamily: 'Urbanist-Regular', 
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ...[
                  '1 giờ trước',
                  '6 giờ trước',
                  '1 ngày trước',
                  '3 ngày trước',
                  '1 tuần trước',
                ]
                .map(
                  (time) => ListTile(
                    title: Text(time),
                    trailing: _reminderTime == time
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () {
                      setState(() => _reminderTime = time);
                      Navigator.pop(context);
                    },
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  void _showExpenseLimitPicker() {
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
              'Ngưỡng cảnh báo chi tiêu',
              style: TextStyle(fontFamily: 'Urbanist-Regular', 
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ...[
                  '200,000đ',
                  '500,000đ',
                  '1,000,000đ',
                  '2,000,000đ',
                  '5,000,000đ',
                ]
                .map(
                  (limit) => ListTile(
                    title: Text(limit),
                    trailing: _expenseLimit == limit
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () {
                      setState(() => _expenseLimit = limit);
                      Navigator.pop(context);
                    },
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  void _enableAllNotifications() {
    setState(() {
      _tripReminders = true;
      _expenseAlerts = true;
      _planUpdates = true;
      _systemUpdates = true;
    });
    _showSnackBar('Đã bật tất cả thông báo');
  }

  void _disableAllNotifications() {
    setState(() {
      _tripReminders = false;
      _expenseAlerts = false;
      _planUpdates = false;
      _systemUpdates = false;
    });
    _showSnackBar('Đã tắt tất cả thông báo');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
