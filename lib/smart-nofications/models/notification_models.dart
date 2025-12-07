import 'package:flutter/material.dart';

enum NotificationType {
  weather,
  budget,
  activity,
}

enum NotificationSeverity {
  info,
  warning,
  critical,
}

class SmartNotification {
  final String id;
  final NotificationType type;
  final NotificationSeverity severity;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data;
  final IconData icon;
  final Color color;

  SmartNotification({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.data,
    required this.icon,
    required this.color,
  });

  SmartNotification copyWith({
    String? id,
    NotificationType? type,
    NotificationSeverity? severity,
    String? title,
    String? message,
    DateTime? createdAt,
    bool? isRead,
    Map<String, dynamic>? data,
    IconData? icon,
    Color? color,
  }) {
    return SmartNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'severity': severity.name,
      'title': title,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'data': data,
    };
  }

  static SmartNotification fromJson(Map<String, dynamic> json) {
    final type = NotificationType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => NotificationType.activity,
    );
    final severity = NotificationSeverity.values.firstWhere(
      (e) => e.name == json['severity'],
      orElse: () => NotificationSeverity.info,
    );

    IconData icon;
    Color color;
    
    switch (type) {
      case NotificationType.weather:
        icon = Icons.wb_cloudy;
        color = Colors.blue;
        break;
      case NotificationType.budget:
        icon = Icons.account_balance_wallet;
        color = Colors.orange;
        break;
      case NotificationType.activity:
        icon = Icons.schedule;
        color = Colors.green;
        break;
    }

    return SmartNotification(
      id: json['id'],
      type: type,
      severity: severity,
      title: json['title'],
      message: json['message'],
      createdAt: DateTime.parse(json['createdAt']),
      isRead: json['isRead'] ?? false,
      data: json['data'],
      icon: icon,
      color: color,
    );
  }
}

// Weather Alert Models
class WeatherAlert {
  final String condition;
  final String description;
  final double temperature;
  final String location;
  final DateTime alertTime;

  WeatherAlert({
    required this.condition,
    required this.description,
    required this.temperature,
    required this.location,
    required this.alertTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'condition': condition,
      'description': description,
      'temperature': temperature,
      'location': location,
      'alertTime': alertTime.toIso8601String(),
    };
  }

  static WeatherAlert fromJson(Map<String, dynamic> json) {
    return WeatherAlert(
      condition: json['condition'],
      description: json['description'],
      temperature: json['temperature'],
      location: json['location'],
      alertTime: DateTime.parse(json['alertTime']),
    );
  }
}

// Budget Warning Models
class BudgetWarning {
  final String activityTitle;
  final double estimatedCost;
  final double actualCost;
  final double overageAmount;
  final double overagePercentage;
  final String currency;

  BudgetWarning({
    required this.activityTitle,
    required this.estimatedCost,
    required this.actualCost,
    required this.overageAmount,
    required this.overagePercentage,
    this.currency = 'VND',
  });

  Map<String, dynamic> toJson() {
    return {
      'activityTitle': activityTitle,
      'estimatedCost': estimatedCost,
      'actualCost': actualCost,
      'overageAmount': overageAmount,
      'overagePercentage': overagePercentage,
      'currency': currency,
    };
  }

  static BudgetWarning fromJson(Map<String, dynamic> json) {
    return BudgetWarning(
      activityTitle: json['activityTitle'],
      estimatedCost: json['estimatedCost'],
      actualCost: json['actualCost'],
      overageAmount: json['overageAmount'],
      overagePercentage: json['overagePercentage'],
      currency: json['currency'] ?? 'VND',
    );
  }
}

// Activity Reminder Models
class ActivityReminder {
  final String activityId;
  final String activityTitle;
  final String location;
  final DateTime startTime;
  final int minutesUntilStart;

  ActivityReminder({
    required this.activityId,
    required this.activityTitle,
    required this.location,
    required this.startTime,
    required this.minutesUntilStart,
  });

  Map<String, dynamic> toJson() {
    return {
      'activityId': activityId,
      'activityTitle': activityTitle,
      'location': location,
      'startTime': startTime.toIso8601String(),
      'minutesUntilStart': minutesUntilStart,
    };
  }

  static ActivityReminder fromJson(Map<String, dynamic> json) {
    return ActivityReminder(
      activityId: json['activityId'],
      activityTitle: json['activityTitle'],
      location: json['location'],
      startTime: DateTime.parse(json['startTime']),
      minutesUntilStart: json['minutesUntilStart'],
    );
  }
}