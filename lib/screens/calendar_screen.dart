import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

/// Calendar Screen - Lịch du lịch với chi tiêu theo ngày
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  // Sample travel expense data by date
  final Map<DateTime, Map<String, dynamic>> _travelExpenses = {
    // Tháng 12/2024 - Chuyến đi Đà Nẵng - Hội An
    DateTime(2024, 12, 14): {
      'total': 3500,
      'location': 'Bay đến Đà Nẵng',
      'expenses': {
        'Transportation': 2200, // Vé máy bay
        'Food': 350,           // Ăn sáng
        'Beverage': 150,       // Café sân bay
        'Car Rental': 800,     // Thuê xe
      },
    },
    DateTime(2024, 12, 15): {
      'total': 2850,
      'location': 'Đà Nẵng City',
      'expenses': {
        'Food': 1200,      // Hải sản, mì quảng
        'Beverage': 300,   // Bia, nước dừa
        'Transportation': 350, // Taxi, Grab
        'Hotel': 1000,     // Resort 4 sao
      },
    },
    DateTime(2024, 12, 16): {
      'total': 1950,
      'location': 'Hội An Ancient Town',
      'expenses': {
        'Food': 800,       // Cao lầu, bánh mì
        'Beverage': 250,   // Trà đá, nước mía
        'Transportation': 400, // Xe đò, taxi
        'Shopping': 500,   // Áo dài, lụa
      },
    },
    DateTime(2024, 12, 17): {
      'total': 3200,
      'location': 'Bà Nà Hills',
      'expenses': {
        'Food': 900,       // Buffet trên núi
        'Beverage': 400,   // Coffee, cocktail
        'Cable Car': 1200, // Vé cáp treo
        'Souvenir': 700,   // Quà lưu niệm
      },
    },
    
    // Tháng 11/2024 - Chuyến đi Sapa
    DateTime(2024, 11, 20): {
      'total': 1800,
      'location': 'Lên Sapa',
      'expenses': {
        'Transportation': 600, // Xe limousine
        'Food': 400,          // Cơm trưa
        'Beverage': 200,      // Nước uống
        'Homestay': 600,      // Check-in homestay
      },
    },
    DateTime(2024, 11, 21): {
      'total': 2400,
      'location': 'Sapa Town',
      'expenses': {
        'Food': 800,       // Thịt nướng, rau rừng
        'Beverage': 300,   // Rượu cần, trà
        'Car Rental': 900, // Tour xe máy
        'Shopping': 400,   // Thổ cẩm
      },
    },
    DateTime(2024, 11, 22): {
      'total': 3500,
      'location': 'Fansipan Peak',
      'expenses': {
        'Food': 600,       // Ăn trưa trên đỉnh
        'Cable Car': 2200, // Cáp treo lên Fansipan
        'Souvenir': 400,   // Ảnh kỷ niệm
        'Transportation': 300, // Về lại thị trấn
      },
    },
    
    // Tháng 10/2024 - Weekend Hà Nội
    DateTime(2024, 10, 26): {
      'total': 1600,
      'location': 'Hà Nội Old Quarter',
      'expenses': {
        'Food': 650,       // Phở, bún chả
        'Beverage': 200,   // Café Cộng
        'Transportation': 300, // Xe buýt, taxi
        'Museum': 450,     // Bảo tàng Dân tộc
      },
    },
    DateTime(2024, 10, 27): {
      'total': 2200,
      'location': 'Hà Nội',
      'expenses': {
        'Food': 800,       // Bún bò Huế, chả cá
        'Shopping': 900,   // Quà ở Hàng Ma
        'Beverage': 250,   // Bia hơi Tạ Hiện
        'Transportation': 250, // Grab, xe ôm
      },
    },
    
    // Tháng 1/2025 - Kế hoạch Phú Quốc (future)
    DateTime(2025, 1, 5): {
      'total': 4500,
      'location': 'Phú Quốc Airport',
      'expenses': {
        'Transportation': 2500, // Vé máy bay
        'Food': 800,           // Hải sản
        'Hotel': 1000,         // Resort view biển
        'Beverage': 200,       // Welcome drink
      },
    },
    DateTime(2025, 1, 6): {
      'total': 3200,
      'location': 'Nam đảo Phú Quốc',
      'expenses': {
        'Food': 1200,      // Tour câu cá nướng
        'Cable Car': 1500, // Hòn Thơm cable car
        'Beverage': 300,   // Cocktail sunset
        'Transportation': 200, // Taxi biển
      },
    },
    DateTime(2025, 1, 7): {
      'total': 2800,
      'location': 'Bắc đảo Phú Quốc',
      'expenses': {
        'Food': 900,       // Safari restaurant
        'Shopping': 1200,  // Nước mắm, tiêu
        'Transportation': 400, // Tour xe máy
        'Beverage': 300,   // Sim wine tasting
      },
    },
    
    // Thêm một số ngày tháng 12 để test
    DateTime(2024, 12, 22): {
      'total': 1800,
      'location': 'Hà Nội',
      'expenses': {
        'Food': 650,
        'Beverage': 200,
        'Transportation': 400,
        'Museum': 550,
      },
    },
    DateTime(2024, 12, 23): {
      'total': 2100,
      'location': 'Sapa',
      'expenses': {'Food': 800, 'Car Rental': 900, 'Homestay': 400},
    },
    DateTime(2024, 12, 28): {
      'total': 950,
      'location': 'Đà Lạt',
      'expenses': {
        'Food': 400,       // Bánh tráng nướng
        'Beverage': 150,   // Café Terrace
        'Transportation': 400, // Easy Rider tour
      },
    },
    DateTime(2024, 12, 30): {
      'total': 650,
      'location': 'Vũng Tàu',
      'expenses': {
        'Food': 350,       // Bánh khọt
        'Beverage': 100,   // Nước dừa
        'Transportation': 200, // Xe máy
      },
    },
    
    // Thêm data cho tháng hiện tại để test dễ hơn
    DateTime.now(): {
      'total': 1200,
      'location': 'Test Location Today',
      'expenses': {
        'Food': 500,
        'Beverage': 200,
        'Transportation': 300,
        'Shopping': 200,
      },
    },
    DateTime.now().subtract(const Duration(days: 1)): {
      'total': 800,
      'location': 'Yesterday Trip',
      'expenses': {
        'Food': 400,
        'Beverage': 150,
        'Transportation': 250,
      },
    },
    DateTime.now().add(const Duration(days: 1)): {
      'total': 950,
      'location': 'Tomorrow Plan',
      'expenses': {
        'Food': 450,
        'Transportation': 300,
        'Shopping': 200,
      },
    },
    DateTime.now().add(const Duration(days: 2)): {
      'total': 1500,
      'location': 'Day After Tomorrow',
      'expenses': {
        'Food': 600,
        'Hotel': 500,
        'Transportation': 400,
      },
    },
  };

  // Category icons and colors
  final Map<String, Map<String, dynamic>> _categoryConfig = {
    'Food': {'icon': Icons.restaurant, 'color': Color(0xFFE91E63)},
    'Beverage': {'icon': Icons.local_drink, 'color': Color(0xFF2196F3)},
    'Car Rental': {'icon': Icons.directions_car, 'color': Color(0xFFFF9800)},
    'Transportation': {'icon': Icons.train, 'color': Color(0xFF9C27B0)},
    'Hotel': {'icon': Icons.hotel, 'color': Color(0xFF4CAF50)},
    'Homestay': {'icon': Icons.home, 'color': Color(0xFF795548)},
    'Cable Car': {'icon': Icons.car_rental, 'color': Color(0xFFFF5722)},
    'Shopping': {'icon': Icons.shopping_bag, 'color': Color(0xFF607D8B)},
    'Souvenir': {'icon': Icons.card_giftcard, 'color': Color(0xFFE91E63)},
    'Museum': {'icon': Icons.museum, 'color': Color(0xFF3F51B5)},
  };

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime(2024, 12); // Focus tháng 12/2024 để xem data
    _selectedDay = DateTime(2024, 12, 15); // Select ngày có data
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light grey background
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),

              // Calendar
              _buildCalendar(),

              const SizedBox(height: 12),
              // Selected Day Expenses
              _buildExpenseDetails(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const SizedBox(width: 48), // Spacer để căn giữa title
          const Expanded(
            child: Text(
              'Calendar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Color(0xFF7B61FF)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TableCalendar<Map<String, dynamic>>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        eventLoader: (day) {
          return _travelExpenses[day] != null ? [_travelExpenses[day]!] : [];
        },
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onPageChanged: (focusedDay) {
          setState(() {
            _focusedDay = focusedDay;
          });
        },
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          selectedDecoration: const BoxDecoration(
            color: Color(0xFFE91E63),
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: const Color(0xFFFF5A00).withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          markersMaxCount: 1,
          markerDecoration: const BoxDecoration(
            color: Color(0xFF4CAF50),
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          leftChevronIcon: Icon(Icons.chevron_left, color: Color(0xFFE91E63)),
          rightChevronIcon: Icon(Icons.chevron_right, color: Color(0xFFE91E63)),
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, date, focusedDay) {
            // Kiểm tra ngày có travel expense không
            final normalizedDate = DateTime(date.year, date.month, date.day);
            final hasExpense = _travelExpenses.keys.any((expenseDate) => 
              expenseDate.year == normalizedDate.year &&
              expenseDate.month == normalizedDate.month &&
              expenseDate.day == normalizedDate.day
            );
            
            if (hasExpense) {
              return Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.3), // Màu vàng kim với alpha
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.6),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${date.day}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              );
            }
            return null; // Sử dụng default style cho ngày thường
          },
          selectedBuilder: (context, date, focusedDay) {
            // Style cho ngày được chọn
            final normalizedDate = DateTime(date.year, date.month, date.day);
            final hasExpense = _travelExpenses.keys.any((expenseDate) => 
              expenseDate.year == normalizedDate.year &&
              expenseDate.month == normalizedDate.month &&
              expenseDate.day == normalizedDate.day
            );
            
            return Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: hasExpense 
                    ? Colors.amber.withValues(alpha: 0.8)  // Vàng đậm hơn khi selected + có expense
                    : const Color(0xFFE91E63),       // Pink khi selected không có expense
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFFFF5A00),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: hasExpense ? Colors.black87 : Colors.white,
                  ),
                ),
              ),
            );
          },
          todayBuilder: (context, date, focusedDay) {
            // Style cho ngày hôm nay
            final normalizedDate = DateTime(date.year, date.month, date.day);
            final hasExpense = _travelExpenses.keys.any((expenseDate) => 
              expenseDate.year == normalizedDate.year &&
              expenseDate.month == normalizedDate.month &&
              expenseDate.day == normalizedDate.day
            );
            
            return Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: hasExpense 
                    ? Colors.amber.withValues(alpha: 0.5)     // Vàng nhạt cho today + expense
                    : const Color(0xFFE91E63).withValues(alpha: 0.3), // Pink nhạt cho today
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: hasExpense 
                      ? Colors.amber 
                      : const Color(0xFFE91E63),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  '${date.day}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildExpenseDetails() {
    if (_selectedDay == null) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Chọn ngày để xem chi tiêu du lịch',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Find matching expense data with normalized date
    final selectedDate = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    final matchingEntry = _travelExpenses.entries.firstWhere(
      (entry) {
        final expenseDate = DateTime(entry.key.year, entry.key.month, entry.key.day);
        return expenseDate.year == selectedDate.year &&
               expenseDate.month == selectedDate.month &&
               expenseDate.day == selectedDate.day;
      },
      orElse: () => MapEntry(DateTime.now(), {}),
    );

    if (matchingEntry.value.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Chọn ngày để xem chi tiêu du lịch',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final expenseData = matchingEntry.value;
    final expenses = expenseData['expenses'] as Map<String, dynamic>;
    final total = expenseData['total'] as int;
    final location = expenseData['location'] as String;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF7A00), Color(0xFFFF9E00)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE91E63).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      location,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Tổng chi tiêu',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${total.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}₫',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Expense Categories
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chi tiêu theo danh mục',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  itemCount: expenses.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final category = expenses.keys.elementAt(index);
                    final amount = expenses[category] as int;
                    final percentage = (amount / total * 100).round();

                    return _buildExpenseItem(
                      category: category,
                      amount: amount,
                      percentage: percentage,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseItem({
    required String category,
    required int amount,
    required int percentage,
  }) {
    final config =
        _categoryConfig[category] ??
        {'icon': Icons.help_outline, 'color': const Color(0xFF9E9E9E)};

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (config['color'] as Color).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              config['icon'] as IconData,
              color: config['color'] as Color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          config['color'] as Color,
                        ),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}₫',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: config['color'] as Color,
            ),
          ),
        ],
      ),
    );
  }
}

