import 'dart:async';
import '../models/world_clock_models.dart';

class WorldClockService {
  static const List<WorldTimeZone> popularTimeZones = [
    // Việt Nam và khu vực Đông Nam Á
    WorldTimeZone(
      name: 'Hồ Chí Minh City',
      timeZone: 'Asia/Ho_Chi_Minh',
      country: 'Vietnam',
      flag: '🇻🇳',
      utcOffset: 7,
    ),
    WorldTimeZone(
      name: 'Bangkok',
      timeZone: 'Asia/Bangkok',
      country: 'Thailand',
      flag: '🇹🇭',
      utcOffset: 7,
    ),
    WorldTimeZone(
      name: 'Singapore',
      timeZone: 'Asia/Singapore',
      country: 'Singapore',
      flag: '🇸🇬',
      utcOffset: 8,
    ),
    WorldTimeZone(
      name: 'Kuala Lumpur',
      timeZone: 'Asia/Kuala_Lumpur',
      country: 'Malaysia',
      flag: '🇲🇾',
      utcOffset: 8,
    ),
    WorldTimeZone(
      name: 'Jakarta',
      timeZone: 'Asia/Jakarta',
      country: 'Indonesia',
      flag: '🇮🇩',
      utcOffset: 7,
    ),
    WorldTimeZone(
      name: 'Manila',
      timeZone: 'Asia/Manila',
      country: 'Philippines',
      flag: '🇵🇭',
      utcOffset: 8,
    ),
    
    // Các thành phố lớn trên thế giới
    WorldTimeZone(
      name: 'Tokyo',
      timeZone: 'Asia/Tokyo',
      country: 'Japan',
      flag: '🇯🇵',
      utcOffset: 9,
    ),
    WorldTimeZone(
      name: 'Seoul',
      timeZone: 'Asia/Seoul',
      country: 'South Korea',
      flag: '🇰🇷',
      utcOffset: 9,
    ),
    WorldTimeZone(
      name: 'Beijing',
      timeZone: 'Asia/Shanghai',
      country: 'China',
      flag: '🇨🇳',
      utcOffset: 8,
    ),
    WorldTimeZone(
      name: 'Hong Kong',
      timeZone: 'Asia/Hong_Kong',
      country: 'Hong Kong',
      flag: '🇭🇰',
      utcOffset: 8,
    ),
    WorldTimeZone(
      name: 'Sydney',
      timeZone: 'Australia/Sydney',
      country: 'Australia',
      flag: '🇦🇺',
      utcOffset: 11,
    ),
    WorldTimeZone(
      name: 'London',
      timeZone: 'Europe/London',
      country: 'United Kingdom',
      flag: '🇬🇧',
      utcOffset: 0,
    ),
    WorldTimeZone(
      name: 'Paris',
      timeZone: 'Europe/Paris',
      country: 'France',
      flag: '🇫🇷',
      utcOffset: 1,
    ),
    WorldTimeZone(
      name: 'New York',
      timeZone: 'America/New_York',
      country: 'United States',
      flag: '🇺🇸',
      utcOffset: -5,
    ),
    WorldTimeZone(
      name: 'Los Angeles',
      timeZone: 'America/Los_Angeles',
      country: 'United States',
      flag: '🇺🇸',
      utcOffset: -8,
    ),
    WorldTimeZone(
      name: 'Dubai',
      timeZone: 'Asia/Dubai',
      country: 'UAE',
      flag: '🇦🇪',
      utcOffset: 4,
    ),
  ];

  /// Lấy thời gian hiện tại cho một múi giờ
  static DateTime getCurrentTimeInTimeZone(String timeZoneId) {
    try {
      final now = DateTime.now().toUtc();
      final timeZone = popularTimeZones.firstWhere(
        (tz) => tz.timeZone == timeZoneId,
        orElse: () => popularTimeZones.first,
      );
      
      return now.add(Duration(hours: timeZone.utcOffset.round()));
    } catch (e) {
      return DateTime.now();
    }
  }

  /// Lấy dữ liệu world clock cho một múi giờ
  static WorldClockData getWorldClockData(WorldTimeZone timeZone) {
    final currentTime = getCurrentTimeInTimeZone(timeZone.timeZone);
    final isDayTime = currentTime.hour >= 6 && currentTime.hour < 18;
    
    return WorldClockData(
      timeZone: timeZone,
      currentTime: currentTime,
      isDayTime: isDayTime,
    );
  }

  /// Lấy danh sách world clock data cho tất cả múi giờ
  static List<WorldClockData> getAllWorldClockData() {
    return popularTimeZones.map((timeZone) => getWorldClockData(timeZone)).toList();
  }

  /// Tìm kiếm múi giờ theo tên
  static List<WorldTimeZone> searchTimeZones(String query) {
    if (query.isEmpty) return popularTimeZones;
    
    final lowerQuery = query.toLowerCase();
    return popularTimeZones.where((timeZone) {
      return timeZone.name.toLowerCase().contains(lowerQuery) ||
             timeZone.country.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Stream để cập nhật thời gian realtime
  static Stream<List<WorldClockData>> getWorldClockStream() {
    return Stream.periodic(const Duration(seconds: 1), (_) {
      return getAllWorldClockData();
    });
  }

  /// Tính chênh lệch thời gian so với Việt Nam
  static String getTimeDifferenceFromVietnam(WorldTimeZone timeZone) {
    const vietnamOffset = 7.0;
    final difference = timeZone.utcOffset - vietnamOffset;
    
    if (difference == 0) {
      return 'Cùng múi giờ';
    } else if (difference > 0) {
      return '+${difference.toInt()}h';
    } else {
      return '${difference.toInt()}h';
    }
  }
}