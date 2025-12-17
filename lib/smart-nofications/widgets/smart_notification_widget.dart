import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification_models.dart';
import '../providers/smart_notification_provider.dart';
import '../screens/notification_detail_screen.dart';
import '../../Core/theme/app_theme.dart';

class SmartNotificationWidget extends StatelessWidget {
  final String tripId;
  
  const SmartNotificationWidget({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return Consumer<SmartNotificationProvider>(
      builder: (context, provider, child) {
        final tripNotifications = provider.getNotifications(tripId);
        final tripUnreadCount = provider.getUnreadCount(tripId);
        final hasUnreadForTrip = provider.hasUnreadForTrip(tripId);
        
        debugPrint('SmartNotificationWidget: Building with ${tripNotifications.length} notifications, unread: $tripUnreadCount for trip $tripId');
        
        return Stack(
          children: [
            IconButton(
              icon: Icon(
                hasUnreadForTrip 
                    ? Icons.notifications_active
                    : Icons.notifications_outlined,
                color: hasUnreadForTrip ? Colors.orange : Colors.black,
                size: 24,
              ),
              onPressed: () => _showNotificationPanel(context, provider, tripId),
            ),
            if (hasUnreadForTrip)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$tripUnreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showNotificationPanel(BuildContext context, SmartNotificationProvider provider, String tripId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Notifications',
                      style: TextStyle(
                        fontFamily: 'Urbanist-Regular',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    if (provider.hasUnreadForTrip(tripId))
                      TextButton(
                        onPressed: () => provider.markAllAsRead(tripId),
                        child: Text(
                          'Mark all as read',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Notifications list
              Expanded(
                child: provider.getNotifications(tripId).isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: provider.getNotifications(tripId).length,
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          final notification = provider.getNotifications(tripId)[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: _buildNotificationItem(
                              context, 
                              notification, 
                              provider,
                              tripId
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: TextStyle(
              fontFamily: 'Urbanist-Regular',
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Smart notifications will appear here',
            style: TextStyle(
              fontFamily: 'Urbanist-Regular',
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context, 
    SmartNotification notification, 
    SmartNotificationProvider provider,
    String tripId
  ) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) {
        provider.deleteNotification(notification.id, tripId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification deleted')),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notification.isRead ? Colors.grey[200]! : Colors.blue[200]!,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: notification.color.withValues(alpha: 0.1),
            child: Icon(
              notification.icon,
              color: notification.color,
              size: 20,
            ),
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontFamily: 'Urbanist-Regular',
              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                notification.message,
                style: TextStyle(
                  fontFamily: 'Urbanist-Regular',
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(notification.createdAt),
                style: TextStyle(
                  fontFamily: 'Urbanist-Regular',
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
          trailing: _buildSeverityIndicator(notification.severity),
          onTap: () {
            if (!notification.isRead) {
              provider.markAsRead(notification.id, tripId);
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NotificationDetailScreen(
                  notification: notification,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSeverityIndicator(NotificationSeverity severity) {
    Color color;
    IconData icon;
    
    switch (severity) {
      case NotificationSeverity.critical:
        color = Colors.red;
        icon = Icons.error;
        break;
      case NotificationSeverity.warning:
        color = Colors.orange;
        icon = Icons.warning;
        break;
      case NotificationSeverity.info:
        color = Colors.blue;
        icon = Icons.info;
        break;
    }

    return Icon(icon, color: color, size: 16);
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}

class NotificationBadge extends StatelessWidget {
  final Widget child;
  final int count;

  const NotificationBadge({
    super.key,
    required this.child,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (count > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}