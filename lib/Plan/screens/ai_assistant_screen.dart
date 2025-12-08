import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../Core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ai_plan_editor_service.dart';
import '../services/ai_trip_planner_service.dart';
import '../models/trip_model.dart';
import '../models/activity_models.dart';

class AiAssistantScreen extends StatefulWidget {
  final TripModel? currentTrip;

  const AiAssistantScreen({Key? key, this.currentTrip}) : super(key: key);

  @override
  _AiAssistantScreenState createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  String _currentChat = '';
  List<String> _chatHistories = [];

  // Track changes made during this session
  final List<Map<String, dynamic>> _sessionChanges = [];

  @override
  void initState() {
    super.initState();
    _initializePlanChat();
  }

  /// Initialize chat history for the current plan
  Future<void> _initializePlanChat() async {
    final prefs = await SharedPreferences.getInstance();

    if (widget.currentTrip != null) {
      // Use plan-specific chat history
      _currentChat = 'plan_${widget.currentTrip!.id}_chat';
      _chatHistories = [_currentChat]; // Only one chat history per plan
    } else {
      // Fallback to general chat history for backward compatibility
      _chatHistories = prefs.getStringList('chat_histories') ?? ['chat_history_1'];
      _currentChat = prefs.getString('current_chat') ?? _chatHistories.first;
    }

    _loadMessages();
  }

  Future<void> _loadChatHistories() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _chatHistories =
          prefs.getStringList('chat_histories') ?? ['chat_history_1'];
      _currentChat = prefs.getString('current_chat') ?? _chatHistories.first;
    });
    _loadMessages();
  }

  Future<void> _saveChatHistories() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('chat_histories', _chatHistories);
    await prefs.setString('current_chat', _currentChat);
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_currentChat) ?? [];
    setState(() {
      _messages.clear();
      for (var item in history) {
        _messages.add(Map<String, String>.from(jsonDecode(item)));
      }
    });
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final history = _messages.map((message) => jsonEncode(message)).toList();
    await prefs.setStringList(_currentChat, history);
  }

  void _newChat() {
    setState(() {
      _currentChat = 'chat_history_${DateTime.now().millisecondsSinceEpoch}';
      _chatHistories.add(_currentChat);
      _messages.clear();
    });
    _saveChatHistories();
    _saveMessages();
  }

  Future<void> _deleteChatHistory(String chatHistory) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(chatHistory);
    setState(() {
      _chatHistories.remove(chatHistory);
      if (_currentChat == chatHistory) {
        if (_chatHistories.isNotEmpty) {
          _currentChat = _chatHistories.first;
          _loadMessages();
        } else {
          _newChat();
        }
      }
    });
    _saveChatHistories();
  }

  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty) {
      return;
    }

    final userMessage = _controller.text;
    final history = List<Map<String, String>>.from(_messages);

    setState(() {
      _messages.add({'role': 'user', 'content': userMessage});
      _isLoading = true;
    });
    _controller.clear();
    await _saveMessages();

    try {
      // Debug logging
      debugPrint('🤖 AI Assistant Debug:');
      debugPrint('  - Message: "$userMessage"');
      debugPrint('  - Has current trip: ${widget.currentTrip != null}');
      debugPrint('  - Is trip planning: ${_isTripPlanningRequest(userMessage)}');
      debugPrint('  - Is comprehensive planning: ${_isComprehensiveTripPlanning(userMessage)}');
      debugPrint('  - Is plan editing: ${_isPlanEditingCommand(userMessage)}');

      // Check if this is a comprehensive trip planning request
      // Can work with or without current trip context
      if (_isComprehensiveTripPlanning(userMessage)) {
        debugPrint('  → Route: Comprehensive Trip Planning');
        await _handleTripPlanning(userMessage);
      }
      // Check if this is a plan editing command and we have a current trip
      else if (widget.currentTrip != null && _isPlanEditingCommand(userMessage)) {
        debugPrint('  → Route: Plan Editing');
        // Use new plan editing endpoint that generates complete new plans
        await _handlePlanEditing(userMessage);
      } else {
        debugPrint('  → Route: General AI Query (/invoke)');
        // Use regular AI assistant for other queries
        final response = await http.post(
          Uri.parse('http://127.0.0.1:8000/invoke'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'input': userMessage, 'history': history}),
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          setState(() {
            _messages.add({
              'role': 'assistant',
              'content': responseData['summary'],
            });
          });
        } else {
          setState(() {
            _messages.add({
              'role': 'assistant',
              'content': 'Error: ${response.reasonPhrase}',
            });
          });
        }
      }
    } catch (e) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': 'Error: $e'});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      await _saveMessages();
    }
  }

  /// Handle trip planning requests
  Future<void> _handleTripPlanning(String userMessage) async {
    try {
      // Show planning in progress
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': '🎯 Đang phân tích yêu cầu và tạo kế hoạch du lịch...',
        });
      });

      // Use AI Trip Planner Service
      final aiTripPlanner = AITripPlannerService();
      final result = await aiTripPlanner.generateTripPlan(userMessage);

      if (result['success'] == true) {
        final TripModel generatedTrip = result['trip'];
        final planData = result['plan_data'];

        // Check if we have a current trip context - if so, add activities to current trip
        if (widget.currentTrip != null) {
          await _addGeneratedActivitiesToCurrentTrip(generatedTrip, planData);
        } else {
          // No current trip - create new trip (original flow)
          await _handleNewTripCreation(generatedTrip, planData);
        }

      } else {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': '❌ ${result['message']}',
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': '❌ Có lỗi xảy ra khi tạo kế hoạch: $e',
        });
      });
    }
  }

  /// Add generated activities to the current trip
  Future<void> _addGeneratedActivitiesToCurrentTrip(TripModel generatedTrip, Map<String, dynamic> planData) async {
    try {
      debugPrint('Adding generated activities to current trip: ${widget.currentTrip!.id}');

      // Convert generated activities to current trip context
      final List<Map<String, dynamic>> addedActivities = [];
      final dailyPlans = planData['daily_plans'] as List;

      for (final dayPlan in dailyPlans) {
        final day = dayPlan['day'] as int;
        final activities = dayPlan['activities'] as List;

        for (final activityData in activities) {
          // Calculate date for this activity based on current trip start date
          final activityDate = widget.currentTrip!.startDate.add(Duration(days: day - 1));

          // Create activity with proper timing
          final startDateTime = DateTime(
            activityDate.year,
            activityDate.month,
            activityDate.day,
            int.tryParse((activityData['start_time'] as String?)?.split(':')[0] ?? '9') ?? 9,
            int.tryParse((activityData['start_time'] as String?)?.split(':')[1] ?? '0') ?? 0,
          );

          // Determine activity type
          ActivityType activityType = ActivityType.activity;
          final typeString = activityData['activity_type'] as String?;
          if (typeString == 'restaurant') activityType = ActivityType.restaurant;
          else if (typeString == 'lodging') activityType = ActivityType.lodging;
          else if (typeString == 'flight') activityType = ActivityType.flight;
          else if (typeString == 'tour') activityType = ActivityType.tour;

          // Create budget
          BudgetModel? budget;
          final cost = activityData['estimated_cost'];
          if (cost != null) {
            budget = BudgetModel(
              estimatedCost: (cost as num).toDouble(),
              currency: planData['trip_info']['currency'] ?? 'VND',
            );
          }

          // Parse location data from AI response
          LocationModel? location;
          if (activityData['location'] != null || activityData['address'] != null) {
            // Parse coordinates if provided
            double? latitude, longitude;
            if (activityData['coordinates'] != null) {
              try {
                final coords = (activityData['coordinates'] as String).split(',');
                if (coords.length == 2) {
                  latitude = double.tryParse(coords[0].trim());
                  longitude = double.tryParse(coords[1].trim());
                }
              } catch (e) {
                debugPrint('Error parsing coordinates: $e');
              }
            }

            location = LocationModel(
              name: activityData['location'] ?? activityData['title'] ?? 'Unknown Location',
              address: activityData['address'],
              latitude: latitude,
              longitude: longitude,
            );
          }

          // Create activity
          final activity = ActivityModel(
            id: 'ai_gen_${DateTime.now().millisecondsSinceEpoch}_${addedActivities.length}',
            title: activityData['title'] as String,
            description: activityData['description'] as String?,
            activityType: activityType,
            startDate: startDateTime,
            tripId: widget.currentTrip!.id,
            budget: budget,
            location: location,
          );

          // Track for UI update
          addedActivities.add({
            'action': 'add',
            'activity': activity.toJson(),
          });
        }
      }

      // Add activities to session changes for UI update
      _sessionChanges.addAll(addedActivities);

      // Show success message with activity count
      final totalActivities = addedActivities.length;
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': '✅ Đã thêm **$totalActivities hoạt động** vào kế hoạch hiện tại!\n\n' +
              '📋 **Kế hoạch đã được cập nhật:**\n' +
              '📍 **Điểm đến:** ${generatedTrip.destination}\n' +
              '👥 **Dành cho:** ${planData['trip_info']['travelers_count'] ?? 1} người\n' +
              '💰 **Ngân sách dự kiến:** ${planData['summary']['total_estimated_cost']?.toStringAsFixed(0) ?? 'N/A'} VND',
        });
      });

      // Show activity breakdown by day
      for (final dayPlan in dailyPlans) {
        final day = dayPlan['day'];
        final activities = dayPlan['activities'] as List;
        final activityCount = activities.length;

        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': '📅 **Ngày $day:** $activityCount hoạt động đã thêm',
          });
        });
      }

      // Confirm UI update
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _messages.add({
          'role': 'system',
          'content': '✨ Các hoạt động đã được thêm vào trang kế hoạch! Quay lại để xem.',
        });
      });

    } catch (e) {
      debugPrint('Error adding activities to current trip: $e');
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': '❌ Có lỗi khi thêm hoạt động vào kế hoạch hiện tại: $e',
        });
      });
    }
  }

  /// Handle plan editing using the new /edit-plan endpoint
  Future<void> _handlePlanEditing(String userMessage) async {
    try {
      debugPrint('Handling plan editing for trip: ${widget.currentTrip!.id}');

      // Show planning in progress
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': '🔄 Đang phân tích yêu cầu và tạo lại kế hoạch hoàn toàn mới...',
        });
      });

      // Call the new /edit-plan endpoint
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/edit-plan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'command': userMessage,
          'trip_id': widget.currentTrip!.id,
          'conversation_history': _messages.map((msg) => {
            'role': msg['role'],
            'content': msg['content']
          }).toList(),
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['success'] == true && result['action_type'] == 'full_replace') {
          final newPlan = result['new_plan'];
          final message = result['message'];

          // Replace the entire current trip with the new plan
          await _replaceCurrentTripWithNewPlan(newPlan, message);
        } else {
          setState(() {
            _messages.add({
              'role': 'assistant',
              'content': '❌ ${result['message'] ?? 'Không thể chỉnh sửa kế hoạch'}',
            });
          });
        }
      } else {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': '❌ Lỗi kết nối đến dịch vụ AI: ${response.reasonPhrase}',
          });
        });
      }
    } catch (e) {
      debugPrint('Error in plan editing: $e');
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': '❌ Có lỗi xảy ra khi chỉnh sửa kế hoạch: $e',
        });
      });
    }
  }

  /// Replace current trip with completely new plan
  Future<void> _replaceCurrentTripWithNewPlan(Map<String, dynamic> newPlan, String aiMessage) async {
    try {
      debugPrint('Replacing current trip with new plan');

      // Clear existing session changes since we're replacing everything
      _sessionChanges.clear();

      final tripInfo = newPlan['trip_info'];
      final dailyPlans = newPlan['daily_plans'] as List;

      // Create new activities list for the replacement
      final List<Map<String, dynamic>> newActivities = [];

      for (final dayPlan in dailyPlans) {
        final day = dayPlan['day'] as int;
        final activities = dayPlan['activities'] as List;

        for (final activityData in activities) {
          // Calculate date for this activity based on current trip start date
          final activityDate = widget.currentTrip!.startDate.add(Duration(days: day - 1));

          // Create activity with proper timing
          final startDateTime = DateTime(
            activityDate.year,
            activityDate.month,
            activityDate.day,
            int.tryParse((activityData['start_time'] as String?)?.split(':')[0] ?? '9') ?? 9,
            int.tryParse((activityData['start_time'] as String?)?.split(':')[1] ?? '0') ?? 0,
          );

          // Determine activity type
          ActivityType activityType = ActivityType.activity;
          final typeString = activityData['activity_type'] as String?;
          if (typeString == 'restaurant') activityType = ActivityType.restaurant;
          else if (typeString == 'lodging') activityType = ActivityType.lodging;
          else if (typeString == 'flight') activityType = ActivityType.flight;
          else if (typeString == 'tour') activityType = ActivityType.tour;

          // Create budget
          BudgetModel? budget;
          final cost = activityData['estimated_cost'];
          if (cost != null) {
            budget = BudgetModel(
              estimatedCost: (cost as num).toDouble(),
              currency: tripInfo['currency'] ?? 'VND',
            );
          }

          // Parse location data from AI response
          LocationModel? location;
          if (activityData['location'] != null || activityData['address'] != null) {
            // Parse coordinates if provided
            double? latitude, longitude;
            if (activityData['coordinates'] != null) {
              try {
                final coords = (activityData['coordinates'] as String).split(',');
                if (coords.length == 2) {
                  latitude = double.tryParse(coords[0].trim());
                  longitude = double.tryParse(coords[1].trim());
                }
              } catch (e) {
                debugPrint('Error parsing coordinates: $e');
              }
            }

            location = LocationModel(
              name: activityData['location'] ?? activityData['title'] ?? 'Unknown Location',
              address: activityData['address'],
              latitude: latitude,
              longitude: longitude,
            );
          }

          // Create activity
          final activity = ActivityModel(
            id: 'ai_replaced_${DateTime.now().millisecondsSinceEpoch}_${newActivities.length}',
            title: activityData['title'] as String,
            description: activityData['description'] as String?,
            activityType: activityType,
            startDate: startDateTime,
            tripId: widget.currentTrip!.id,
            budget: budget,
            location: location,
          );

          // Track for replacement (remove old + add new)
          newActivities.add({
            'action': 'replace_all', // Special action to indicate full replacement
            'activity': activity.toJson(),
          });
        }
      }

      // Add new activities to session changes
      _sessionChanges.addAll(newActivities);

      // Show success message
      final totalActivities = newActivities.length;
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': '✅ **Đã tạo lại hoàn toàn kế hoạch du lịch!**\n\n'
              '$aiMessage\n\n'
              '📋 **Kế hoạch mới:**\n'
              '📍 **Điểm đến:** ${tripInfo['destination'] ?? widget.currentTrip!.destination}\n'
              '👥 **Dành cho:** ${tripInfo['travelers_count'] ?? 1} người\n'
              '💰 **Ngân sách dự kiến:** ${newPlan['summary']['total_estimated_cost']?.toStringAsFixed(0) ?? 'N/A'} VND\n'
              '🎯 **Tổng số hoạt động:** $totalActivities',
        });
      });

      // Show activity breakdown by day
      for (final dayPlan in dailyPlans) {
        final day = dayPlan['day'];
        final activities = dayPlan['activities'] as List;
        final activityCount = activities.length;

        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': '📅 **Ngày $day:** $activityCount hoạt động mới',
          });
        });
      }

      // Confirm UI update
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _messages.add({
          'role': 'system',
          'content': '🔄 **Kế hoạch đã được thay thế hoàn toàn!** Quay lại trang kế hoạch để xem phiên bản mới.',
        });
      });

    } catch (e) {
      debugPrint('Error replacing trip with new plan: $e');
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': '❌ Có lỗi khi thay thế kế hoạch: $e',
        });
      });
    }
  }

  /// Handle new trip creation (original flow)
  Future<void> _handleNewTripCreation(TripModel generatedTrip, Map<String, dynamic> planData) async {
    // Add success message
    setState(() {
      _messages.add({
        'role': 'assistant',
        'content': '✅ Đã tạo kế hoạch du lịch thành công!\n\n' +
            '📋 **${generatedTrip.name}**\n' +
            '📍 **Điểm đến:** ${generatedTrip.destination}\n' +
            '📅 **Thời gian:** ${generatedTrip.startDate.day}/${generatedTrip.startDate.month} - ${generatedTrip.endDate.day}/${generatedTrip.endDate.month}/${generatedTrip.endDate.year}\n' +
            '👥 **Số người:** ${planData['trip_info']['travelers_count'] ?? 1}\n' +
            '💰 **Ngân sách dự kiến:** ${planData['summary']['total_estimated_cost']?.toStringAsFixed(0) ?? 'N/A'} VND\n\n' +
            '🎯 **Các hoạt động chính:**',
      });
    });

    // Add activity summary
    final dailyPlans = planData['daily_plans'] as List;
    for (final dayPlan in dailyPlans) {
      final day = dayPlan['day'];
      final activities = dayPlan['activities'] as List;
      final activityCount = activities.length;

      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': '📅 **Ngày $day:** $activityCount hoạt động',
        });
      });
    }

    // Add action buttons
    setState(() {
      _messages.add({
        'role': 'assistant',
        'content': '🔗 **Tùy chọn:**\n' +
            '• Nhấn "Xem chi tiết" để xem kế hoạch đầy đủ\n' +
            '• Nhấn "Lưu kế hoạch" để lưu vào tài khoản\n' +
            '• Tiếp tục chat để chỉnh sửa kế hoạch',
      });
    });

    // Save the trip automatically
    await Future.delayed(const Duration(seconds: 1));

    try {
      final aiTripPlanner = AITripPlannerService();
      final savedTrip = await aiTripPlanner.saveGeneratedTrip(generatedTrip);
      setState(() {
        _messages.add({
          'role': 'system',
          'content': '💾 Kế hoạch đã được lưu tự động! Bạn có thể tìm thấy nó trong danh sách chuyến đi.',
        });
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'system',
          'content': '⚠️ Kế hoạch được tạo nhưng chưa lưu. Bạn có thể sao chép thông tin để tạo thủ công.',
        });
      });
    }
  }

  /// Detect comprehensive trip planning requests that create new trips
  bool _isComprehensiveTripPlanning(String message) {
    final lowerMessage = message.toLowerCase();

    // Must contain planning keywords
    bool hasPlanningIntent = lowerMessage.contains('lên kế hoạch') ||
                            lowerMessage.contains('tạo kế hoạch') ||
                            lowerMessage.contains('lập kế hoạch') ||
                            lowerMessage.contains('plan') ||
                            lowerMessage.contains('kế hoạch du lịch') ||
                            lowerMessage.contains('trip') ||
                            lowerMessage.contains('chuyến đi');

    if (!hasPlanningIntent) return false;

    // Must contain multiple trip parameters (destination + duration OR budget OR people)
    int paramCount = 0;

    // Check for duration (days/nights)
    if (lowerMessage.contains('ngày') || lowerMessage.contains('đêm') || lowerMessage.contains('day') || lowerMessage.contains('night')) {
      paramCount++;
    }

    // Check for budget (money terms)
    if (lowerMessage.contains('ngân sách') || lowerMessage.contains('tiền') ||
        lowerMessage.contains('vnd') || lowerMessage.contains('triệu') ||
        lowerMessage.contains('budget') || lowerMessage.contains('cost') ||
        lowerMessage.contains('million') || lowerMessage.contains('\$')) {
      paramCount++;
    }

    // Check for number of people
    if (lowerMessage.contains('người') || lowerMessage.contains('people') ||
        lowerMessage.contains('person')) {
      paramCount++;
    }

    // Check for destination (common destinations or "tại" keyword)
    if (lowerMessage.contains('tại ') || lowerMessage.contains('ở ') ||
        lowerMessage.contains('đến ') || lowerMessage.contains('to ') ||
        lowerMessage.contains('tokyo') || lowerMessage.contains('japan') ||
        lowerMessage.contains('hanoi') || lowerMessage.contains('saigon') ||
        lowerMessage.contains('danang') || lowerMessage.contains('hue') ||
        lowerMessage.contains('paris') || lowerMessage.contains('london') ||
        lowerMessage.contains('singapore') || lowerMessage.contains('thailand')) {
      paramCount++;
    }

    // Comprehensive planning requires at least 2 parameters + planning intent
    return paramCount >= 2;
  }

  bool _isTripPlanningRequest(String message) {
    final lowerMessage = message.toLowerCase();
    return (lowerMessage.contains('lên kế hoạch') ||
            lowerMessage.contains('tạo kế hoạch') ||
            lowerMessage.contains('plan') ||
            lowerMessage.contains('kế hoạch du lịch')) &&
           (lowerMessage.contains('ngày') ||
            lowerMessage.contains('đêm') ||
            lowerMessage.contains('trip') ||
            lowerMessage.contains('chuyến đi'));
  }

  bool _isPlanEditingCommand(String message) {
    final lowerMessage = message.toLowerCase();

    // Check for explicit edit commands with day reference
    bool hasEditAction = lowerMessage.contains('thêm') ||
                        lowerMessage.contains('xóa') ||
                        lowerMessage.contains('xoá') ||
                        lowerMessage.contains('thay') ||
                        lowerMessage.contains('đổi') ||
                        lowerMessage.contains('add') ||
                        lowerMessage.contains('remove') ||
                        lowerMessage.contains('update') ||
                        lowerMessage.contains('delete') ||
                        lowerMessage.contains('sửa') ||
                        lowerMessage.contains('chỉnh sửa') ||
                        lowerMessage.contains('edit');

    bool hasDayReference = lowerMessage.contains('ngày') ||
                          lowerMessage.contains('day') ||
                          lowerMessage.contains('hôm') ||
                          lowerMessage.contains('buổi');

    // If both edit action and day reference exist, it's a plan editing command
    if (hasEditAction && hasDayReference) {
      return true;
    }

    // Also check for activity mentions (add/remove specific activities)
    bool hasActivityKeywords = lowerMessage.contains('hoạt động') ||
                              lowerMessage.contains('activity') ||
                              lowerMessage.contains('món ăn') ||
                              lowerMessage.contains('đi') ||
                              lowerMessage.contains('tham quan') ||
                              lowerMessage.contains('ăn') ||
                              lowerMessage.contains('ở') ||
                              lowerMessage.contains('bay');

    return hasEditAction && hasActivityKeywords;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context, {
            'changes': _sessionChanges,
          }),
        ),
        title: const Text(
          'AI Travel Assistant',
          style: TextStyle(
            fontFamily: 'Urbanist-Regular',
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      drawer: widget.currentTrip != null ? _buildPlanChatDrawer() : _buildGeneralChatDrawer(),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: _messages.isEmpty
                  ? _buildWelcomeView()
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return _buildMessageBubble(
                          message['content']!,
                          message['role']!,
                        );
                      },
                    ),
            ),
          ),
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: const CircularProgressIndicator(),
            ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(top: false, child: _buildMessageInputField()),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeView() {
    final suggestions = [
      {
        'icon': Icons.location_on,
        'text': 'Gợi ý địa điểm du lịch Việt Nam',
        'query':
            'Bạn có thể gợi ý cho tôi những địa điểm du lịch nổi tiếng ở Việt Nam không?',
      },
      {
        'icon': Icons.flight,
        'text': 'Lên kế hoạch chuyến đi',
        'query': 'Tôi muốn lên kế hoạch cho một chuyến du lịch 3 ngày 2 đêm',
      },
      {
        'icon': Icons.restaurant,
        'text': 'Khám phá ẩm thực địa phương',
        'query': 'Những món ăn đặc sản nào tôi nên thử khi du lịch?',
      },
      {
        'icon': Icons.hotel,
        'text': 'Tìm chỗ ở phù hợp',
        'query':
            'Bạn có thể giúp tôi tìm khách sạn với ngân sách hợp lý không?',
      },
      {
        'icon': Icons.directions_car,
        'text': 'Phương tiện di chuyển',
        'query': 'Cách di chuyển tốt nhất giữa các thành phố là gì?',
      },
      {
        'icon': Icons.attach_money,
        'text': 'Ước tính chi phí',
        'query': 'Chi phí cho một chuyến du lịch thường là bao nhiêu?',
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),

          // Welcome message
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(Icons.travel_explore, size: 48, color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  'Xin chào! 👋',
                  style: TextStyle(
                    fontFamily: 'Urbanist-Regular',
                    fontSize: 28,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tôi là trợ lý AI du lịch của bạn!\nSẵn sàng giúp bạn khám phá Việt Nam 🇻🇳',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Urbanist-Regular',
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          Text(
            'Bạn muốn hỏi gì? 🤔',
            style: TextStyle(
              fontFamily: 'Urbanist-Regular',
              fontSize: 20,
              color: Colors.grey[700],
            ),
          ),

          const SizedBox(height: 20),

          // Suggestion cards
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = suggestions[index];
              return InkWell(
                onTap: () {
                  _controller.text = suggestion['query'] as String;
                  _sendMessage();
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        suggestion['icon'] as IconData,
                        size: 32,
                        color: Colors.blue.shade600,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        suggestion['text'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Urbanist-Regular',
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          Text(
            'Hoặc nhập câu hỏi của bạn bên dưới! ✨',
            style: TextStyle(
              fontFamily: 'Urbanist-Regular',
              fontSize: 14,
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, String role) {
    final bool isUser = role == 'user';
    final bool isSystem = role == 'system';

    if (isSystem) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.green.shade600, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'Urbanist-Regular',
                  color: Colors.green.shade800,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue[600] : Colors.grey[200],
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Urbanist-Regular',
            color: isUser ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  /// Build drawer for plan-specific chat
  Widget _buildPlanChatDrawer() {
    return Drawer(
      child: Column(
        children: [
          Container(
            height: 120,
            color: Colors.blue,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble, color: Colors.white, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'Chat với kế hoạch',
                    style: TextStyle(
                      fontFamily: 'Urbanist-Regular',
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    widget.currentTrip?.name ?? 'Chuyến đi',
                    style: TextStyle(
                      fontFamily: 'Urbanist-Regular',
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 Mẹo sử dụng:',
                    style: TextStyle(
                      fontFamily: 'Urbanist-Regular',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTipItem(
                    '✏️ Chỉnh sửa kế hoạch',
                    'Nói "thay đổi kế hoạch thành..." để tạo lại hoàn toàn',
                  ),
                  _buildTipItem(
                    '➕ Thêm hoạt động',
                    'Nói "thêm hoạt động..." để mở rộng kế hoạch',
                  ),
                  _buildTipItem(
                    '❓ Hỏi về kế hoạch',
                    'Hỏi bất kỳ câu hỏi nào về chuyến đi của bạn',
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '⚠️ Lưu ý:',
                    style: TextStyle(
                      fontFamily: 'Urbanist-Regular',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Khi bạn chỉnh sửa kế hoạch, toàn bộ kế hoạch sẽ được tạo lại từ đầu với các yêu cầu mới của bạn.',
                    style: TextStyle(
                      fontFamily: 'Urbanist-Regular',
                      fontSize: 12,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '📝 Lịch sử chat:',
                    style: TextStyle(
                      fontFamily: 'Urbanist-Regular',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.chat, color: Colors.blue.shade600, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Chat riêng cho kế hoạch này\n(${_messages.length} tin nhắn)',
                            style: TextStyle(
                              fontFamily: 'Urbanist-Regular',
                              color: Colors.blue.shade800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '🔄 Chat này sẽ được lưu riêng cho kế hoạch "${widget.currentTrip?.name ?? 'này'}" và không ảnh hưởng đến các kế hoạch khác.',
                    style: TextStyle(
                      fontFamily: 'Urbanist-Regular',
                      fontSize: 12,
                      color: Colors.grey[600],
                      height: 1.4,
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

  /// Build drawer for general chat history management
  Widget _buildGeneralChatDrawer() {
    return Drawer(
      child: Column(
        children: [
          Container(
            height: 100,
            color: Colors.blue,
            child: Center(
              child: Text(
                'Chat History',
                style: TextStyle(
                  fontFamily: 'Urbanist-Regular',
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.add),
            title: Text('New Chat'),
            onTap: () {
              _newChat();
              Navigator.pop(context);
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _chatHistories.length,
              itemBuilder: (context, index) {
                final chatHistory = _chatHistories[index];
                return ListTile(
                  title: Text(
                    'Chat ${_chatHistories.length - index}',
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    setState(() {
                      _currentChat = chatHistory;
                    });
                    _loadMessages();
                    Navigator.pop(context);
                  },
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline),
                    onPressed: () {
                      _deleteChatHistory(chatHistory);
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build a tip item for the plan chat drawer
  Widget _buildTipItem(String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Urbanist-Regular',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          Text(
            description,
            style: TextStyle(
              fontFamily: 'Urbanist-Regular',
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInputField() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Ask me anything about your trip...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                    fontFamily: 'Urbanist-Regular',
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 14.0,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Urbanist-Regular',
                ),
                onSubmitted: (_) => _sendMessage(),
                maxLines: null,
                textInputAction: TextInputAction.send,
              ),
            ),
          ),
          const SizedBox(width: 12.0),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(24.0),
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white),
              onPressed: _isLoading ? null : _sendMessage,
              iconSize: 22,
            ),
          ),
        ],
      ),
    );
  }
}
