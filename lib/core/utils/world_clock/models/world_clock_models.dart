class WorldTimeZone {
  final String name;
  final String timeZone;
  final String country;
  final String flag;
  final double utcOffset;

  const WorldTimeZone({
    required this.name,
    required this.timeZone,
    required this.country,
    required this.flag,
    required this.utcOffset,
  });

  factory WorldTimeZone.fromJson(Map<String, dynamic> json) {
    return WorldTimeZone(
      name: json['name'] ?? '',
      timeZone: json['timeZone'] ?? '',
      country: json['country'] ?? '',
      flag: json['flag'] ?? '',
      utcOffset: (json['utcOffset'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'timeZone': timeZone,
      'country': country,
      'flag': flag,
      'utcOffset': utcOffset,
    };
  }
}

class WorldClockData {
  final WorldTimeZone timeZone;
  final DateTime currentTime;
  final bool isDayTime;

  const WorldClockData({
    required this.timeZone,
    required this.currentTime,
    required this.isDayTime,
  });

  String get formattedTime {
    final hour = currentTime.hour;
    final minute = currentTime.minute.toString().padLeft(2, '0');
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $amPm';
  }

  String get formattedTime24 {
    final hour = currentTime.hour.toString().padLeft(2, '0');
    final minute = currentTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get formattedDate {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[currentTime.month - 1];
    return '${currentTime.day} $month';
  }

  String get dayOfWeek {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[currentTime.weekday - 1];
  }
}