import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../Core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/ai_trip_planner_service.dart';
import '../models/trip_model.dart';
import '../models/activity_models.dart';

class AiAssistantDialog extends StatefulWidget {
  final TripModel? currentTrip;

  const AiAssistantDialog({super.key, this.currentTrip});

  @override
  State<AiAssistantDialog> createState() => _AiAssistantDialogState();

  static Future<Map<String, dynamic>?> show(BuildContext context, {TripModel? currentTrip}) {
    return showGeneralDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'AI Assistant',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return AiAssistantDialog(currentTrip: currentTrip);
      },
    );
  }
}

class _AiAssistantDialogState extends State<AiAssistantDialog> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  String _currentChat = 'chat_history_1';
  List<String> _chatHistories = [];

  @override
  void initState() {
    super.initState();
    _loadChatHistories();
  }

  Future<void> _loadChatHistories() async {
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

  // ignore: unused_element
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
      if (_isComprehensiveTripPlanning(userMessage)) {
        debugPrint('  → Route: Comprehensive Trip Planning');
        await _handleTripPlanning(userMessage);
      }
      // Check if we have a current trip - allow Gemini to handle modifications
      else if (widget.currentTrip != null) {
        debugPrint('  → Route: Plan Modification with Gemini');
        // Use Gemini AI for intelligent plan modifications based on conversation context
        await _handlePlanModificationWithGemini(userMessage, history);
      } else {
        debugPrint('  → Route: General AI Query (/invoke)');
        // Use regular AI assistant for other queries
        final response = await http.post(
          Uri.parse('http://127.0.0.1:5000/invoke'),
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
          if (typeString == 'restaurant') {
            activityType = ActivityType.restaurant;
          } else if (typeString == 'lodging') {
            activityType = ActivityType.lodging;
          } else if (typeString == 'flight') {
            activityType = ActivityType.flight;
          } else if (typeString == 'tour') {
            activityType = ActivityType.tour;
          }

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
      // Note: In dialog mode, we return the changes to the parent screen
      if (mounted) {
        Navigator.of(context).pop({
          'changes': addedActivities,
          'trip': generatedTrip,
          'plan_data': planData,
        });
      }
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

  /// Handle new trip creation (original flow)
  Future<void> _handleNewTripCreation(TripModel generatedTrip, Map<String, dynamic> planData) async {
    // Add success message
    setState(() {
      _messages.add({
        'role': 'assistant',
        'content': '✅ Đã tạo kế hoạch du lịch thành công!\n\n'
            '📋 **${generatedTrip.name}**\n'
            '📍 **Điểm đến:** ${generatedTrip.destination}\n'
            '📅 **Thời gian:** ${generatedTrip.startDate.day}/${generatedTrip.startDate.month} - ${generatedTrip.endDate.day}/${generatedTrip.endDate.month}/${generatedTrip.endDate.year}\n'
            '👥 **Số người:** ${planData['trip_info']['travelers_count'] ?? 1}\n'
            '💰 **Ngân sách dự kiến:** ${planData['summary']['total_estimated_cost']?.toStringAsFixed(0) ?? 'N/A'} VND\n\n'
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
        'content': '🔗 **Tùy chọn:**\n'
            '• Nhấn "Xem chi tiết" để xem kế hoạch đầy đủ\n'
            '• Nhấn "Lưu kế hoạch" để lưu vào tài khoản\n'
            '• Tiếp tục chat để chỉnh sửa kế hoạch',
      });
    });

    // Save the trip automatically - but in dialog mode, return to parent
    await Future.delayed(const Duration(seconds: 1));

    try {
      final aiTripPlanner = AITripPlannerService();
      final savedTrip = await aiTripPlanner.saveGeneratedTrip(generatedTrip);
      if (mounted) {
        Navigator.of(context).pop({
          'new_trip': savedTrip,
          'plan_data': planData,
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop({
          'new_trip': generatedTrip,
          'plan_data': planData,
          'error': 'Kế hoạch được tạo nhưng chưa lưu. Bạn có thể sao chép thông tin để tạo thủ công.',
        });
      }
    }
  }

  /// Handle intelligent plan modifications using Gemini AI with conversation context
  Future<void> _handlePlanModificationWithGemini(
    String userMessage,
    List<Map<String, String>> conversationHistory,
  ) async {
    try {
      debugPrint('🤖 AI Plan Modification: Processing with Gemini');

      // Call the backend /edit-plan endpoint with conversation context
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/edit-plan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'command': userMessage,
          'trip_id': widget.currentTrip!.id,
          'conversation_history': conversationHistory,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          final canModify = responseData['can_modify'] ?? false;
          final actionType = responseData['action_type'];
          final message = responseData['message'];
          final modifications = responseData['modifications'] ?? {};

          // Add AI response
          setState(() {
            _messages.add({
              'role': 'assistant',
              'content': message,
            });
          });

          // If Gemini determined it can modify the plan, execute the changes
          if (canModify && actionType != 'none') {
            debugPrint('🤖 AI determined plan can be modified: $actionType');

            // Create the activity modifications based on Gemini's response
            final List<Map<String, dynamic>> activityChanges = [];

            if (actionType == 'add' && modifications['activity'] != null) {
              final day = modifications['day'] ?? 1;
              final activityName = modifications['activity'];
              final activityType = modifications['activity_type'] ?? 'activity';

              // Create activity for the specified day
              final activityDate = widget.currentTrip!.startDate.add(Duration(days: day - 1));
              final startDateTime = DateTime(
                activityDate.year,
                activityDate.month,
                activityDate.day,
                9, 0, // Default time
              );

              // Map activity type
              ActivityType mappedType = ActivityType.activity;
              if (activityType == 'restaurant') {
                mappedType = ActivityType.restaurant;
              } else if (activityType == 'lodging') {
                mappedType = ActivityType.lodging;
              } else if (activityType == 'flight') {
                mappedType = ActivityType.flight;
              } else if (activityType == 'tour') {
                mappedType = ActivityType.tour;
              }

              final newActivity = ActivityModel(
                id: 'ai_mod_${DateTime.now().millisecondsSinceEpoch}',
                title: activityName,
                activityType: mappedType,
                startDate: startDateTime,
                tripId: widget.currentTrip!.id,
              );

              activityChanges.add({
                'action': 'add',
                'activity': newActivity.toJson(),
              });

            } else if (actionType == 'remove' && modifications['activity'] != null) {
              // For remove operations, we would need to find existing activities
              // This is a simplified version - in practice, Gemini would need to specify which activity to remove
              debugPrint('🤖 Remove operation detected but not implemented in detail');
            }

            // If we have changes, return them to the parent screen
            if (activityChanges.isNotEmpty && mounted) {
              Navigator.of(context).pop({
                'changes': activityChanges,
                'message': message,
              });
            }
          }
        } else {
          // Error from backend
          setState(() {
            _messages.add({
              'role': 'assistant',
              'content': responseData['message'] ?? 'Có lỗi xảy ra khi xử lý yêu cầu.',
            });
          });
        }
      } else {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': 'Lỗi kết nối đến máy chủ AI.',
          });
        });
      }
    } catch (e) {
      debugPrint('Error in plan modification: $e');
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': 'Có lỗi xảy ra khi xử lý yêu cầu chỉnh sửa kế hoạch.',
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
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.smart_toy_outlined, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    'AI Travel Assistant',
                    style: TextStyle(
                      fontFamily: 'Urbanist-Regular',
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Chat content
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _messages.isEmpty
                    ? _buildWelcomeView()
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 16, bottom: 16),
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

            // Loading indicator
            if (_isLoading)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: const CircularProgressIndicator(),
              ),

            // Message input
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(24),
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
                            horizontal: 20,
                            vertical: 14,
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
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      onPressed: _isLoading ? null : _sendMessage,
                      iconSize: 22,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeView() {
    final suggestions = [
      {
        'icon': Icons.location_on,
        'text': 'Gợi ý địa điểm du lịch Việt Nam',
        'query': 'Bạn có thể gợi ý cho tôi những địa điểm du lịch nổi tiếng ở Việt Nam không?',
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
        'query': 'Bạn có thể giúp tôi tìm khách sạn với ngân sách hợp lý không?',
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.travel_explore, size: 40, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  'Xin chào! 👋',
                  style: TextStyle(
                    fontFamily: 'Urbanist-Regular',
                    fontSize: 24,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tôi là trợ lý AI du lịch của bạn!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Urbanist-Regular',
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Bạn muốn hỏi gì?',
            style: TextStyle(
              fontFamily: 'Urbanist-Regular',
              fontSize: 18,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.1,
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        suggestion['icon'] as IconData,
                        size: 24,
                        color: Colors.blue.shade600,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        suggestion['text'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Urbanist-Regular',
                          fontSize: 12,
                          color: Colors.grey[700],
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Hoặc nhập câu hỏi của bạn bên dưới!',
            style: TextStyle(
              fontFamily: 'Urbanist-Regular',
              fontSize: 12,
              color: Colors.grey[500],
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
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.green.shade600, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'Urbanist-Regular',
                  color: Colors.green.shade800,
                  fontSize: 13,
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
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue[600] : Colors.grey[200],
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Urbanist-Regular',
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
