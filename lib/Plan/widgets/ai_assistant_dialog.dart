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

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    TripModel? currentTrip,
  }) {
    return showGeneralDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'AI Assistant',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: animation, child: child),
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
  final TextEditingController _styleController =
      TextEditingController(); // Travel style input
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  int _peopleCount = 1;

  String _currentChat = 'chat_history_1';
  List<String> _chatHistories = [];

  @override
  void initState() {
    super.initState();
    _loadChatHistories();
  }

  @override
  void dispose() {
    _controller.dispose();
    _styleController.dispose();
    super.dispose();
  }

  Future<void> _loadChatHistories() async {
    final prefs = await SharedPreferences.getInstance();

    if (widget.currentTrip != null) {
      // Use plan-specific chat history
      _currentChat = 'plan_${widget.currentTrip!.id}_chat';
      _chatHistories = [_currentChat]; // Only one chat history per plan
    } else {
      // Fallback to general chat history for backward compatibility
      _chatHistories =
          prefs.getStringList('chat_histories') ?? ['chat_history_1'];
      _currentChat = prefs.getString('current_chat') ?? _chatHistories.first;
    }
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final history = _messages.map((message) => jsonEncode(message)).toList();
    await prefs.setStringList(_currentChat, history);
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
      // Check if this is a comprehensive trip planning request
      if (_isComprehensiveTripPlanning(userMessage)) {
        await _handleTripPlanning(userMessage);
      }
      // Check if we have a current trip - allow Gemini to handle modifications
      else if (widget.currentTrip != null) {
        // Use Gemini AI for intelligent plan modifications based on conversation context
        await _handlePlanModificationWithGemini(userMessage, history);
      } else {
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

      // Build enhanced prompt with trip context if available
      String enhancedPrompt = userMessage;
      if (widget.currentTrip != null) {
        final trip = widget.currentTrip!;
        final startDateStr =
            '${trip.startDate.year}-${trip.startDate.month.toString().padLeft(2, '0')}-${trip.startDate.day.toString().padLeft(2, '0')}';
        final endDateStr =
            '${trip.endDate.year}-${trip.endDate.month.toString().padLeft(2, '0')}-${trip.endDate.day.toString().padLeft(2, '0')}';
        final durationDays = trip.endDate.difference(trip.startDate).inDays + 1;
        final totalBudget = trip.budget?.estimatedCost ?? 0;
        final currency = trip.budget?.currency ?? 'VND';

        // Build structured prompt with trip card information
        enhancedPrompt =
            '''
Thông tin chuyến đi hiện tại (từ Trip Card):
- Tên chuyến đi: "${trip.name}"
- Điểm đến: "${trip.destination}"
- Ngày bắt đầu: "$startDateStr"
- Ngày kết thúc: "$endDateStr"
- Số ngày: $durationDays ngày
- Tổng ngân sách: $totalBudget $currency

Yêu cầu của người dùng: $userMessage

Hãy tạo kế hoạch chi tiết dựa trên thông tin chuyến đi ở trên và yêu cầu của người dùng. Sử dụng CHÍNH XÁC các thông tin về tên, điểm đến, ngày tháng, ngân sách từ Trip Card ở trên.''';

      }

      // Use AI Trip Planner Service
      final aiTripPlanner = AITripPlannerService();
      final result = await aiTripPlanner.generateTripPlan(enhancedPrompt);

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
          'content': '❌ An error occurred while creating the plan: $e',
        });
      });
    }
  }

  /// Add generated activities to the current trip
  Future<void> _addGeneratedActivitiesToCurrentTrip(
    TripModel generatedTrip,
    Map<String, dynamic> planData,
  ) async {
    try {

      // First, collect all existing activities to delete
      final List<Map<String, dynamic>> allChanges = [];

      // Load existing activities from the trip (if any exist)
      // We need to check if there are any existing activities to delete

      // Add delete operations for all existing activities
      // This assumes the parent screen will provide us with existing activities
      // For now, we'll add a flag to indicate all existing activities should be deleted
      allChanges.add({
        'action': 'delete_all',
        'trip_id': widget.currentTrip!.id,
      });

      // Convert generated activities to current trip context
      final dailyPlans = planData['daily_plans'] as List;

      for (final dayPlan in dailyPlans) {
        final day = dayPlan['day'] as int;
        final activities = dayPlan['activities'] as List;

        for (final activityData in activities) {
          // Calculate date for this activity based on current trip start date
          final activityDate = widget.currentTrip!.startDate.add(
            Duration(days: day - 1),
          );

          // Create activity with proper timing
          final startDateTime = DateTime(
            activityDate.year,
            activityDate.month,
            activityDate.day,
            int.tryParse(
                  (activityData['start_time'] as String?)?.split(':')[0] ?? '9',
                ) ??
                9,
            int.tryParse(
                  (activityData['start_time'] as String?)?.split(':')[1] ?? '0',
                ) ??
                0,
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
          if (activityData['location'] != null ||
              activityData['address'] != null) {
            // Parse coordinates if provided
            double? latitude, longitude;
            if (activityData['coordinates'] != null) {
              try {
                final coords = (activityData['coordinates'] as String).split(
                  ',',
                );
                if (coords.length == 2) {
                  latitude = double.tryParse(coords[0].trim());
                  longitude = double.tryParse(coords[1].trim());
                }
              } catch (e) {
                //
              }
            }

            location = LocationModel(
              name:
                  activityData['location'] ??
                  activityData['title'] ??
                  'Unknown Location',
              address: activityData['address'],
              latitude: latitude,
              longitude: longitude,
            );
          }

          // Create activity
          final activity = ActivityModel(
            id: 'ai_gen_${DateTime.now().millisecondsSinceEpoch}_${allChanges.length}',
            title: activityData['title'] as String,
            description: activityData['description'] as String?,
            activityType: activityType,
            startDate: startDateTime,
            tripId: widget.currentTrip!.id,
            budget: budget,
            location: location,
          );

          // Track for UI update
          allChanges.add({'action': 'add', 'activity': activity.toJson()});
        }
      }

      // Return all changes (delete_all + new activities) to the parent screen
      // Note: In dialog mode, we return the changes to the parent screen
      if (mounted) {
        Navigator.of(context).pop({
          'changes': allChanges,
          'trip': generatedTrip,
          'plan_data': planData,
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': '❌ An error occurred while adding an activity to the current plan.: $e',
        });
      });
    }
  }

  /// Handle new trip creation (original flow)
  Future<void> _handleNewTripCreation(
    TripModel generatedTrip,
    Map<String, dynamic> planData,
  ) async {
    // Add success message
    setState(() {
      _messages.add({
        'role': 'assistant',
        'content':
            '✅ Đã tạo kế hoạch du lịch thành công!\n\n'
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
        'content':
            '🔗 **Tùy chọn:**\n'
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
        Navigator.of(
          context,
        ).pop({'new_trip': savedTrip, 'plan_data': planData});
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop({
          'new_trip': generatedTrip,
          'plan_data': planData,
          'error':
              'Kế hoạch được tạo nhưng chưa lưu. Bạn có thể sao chép thông tin để tạo thủ công.',
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
            _messages.add({'role': 'assistant', 'content': message});
          });

          // If Gemini determined it can modify the plan, execute the changes
          if (canModify && actionType != 'none') {

            // Create the activity modifications based on Gemini's response
            final List<Map<String, dynamic>> activityChanges = [];

            if (actionType == 'add' && modifications['activity'] != null) {
              final day = modifications['day'] ?? 1;
              final activityName = modifications['activity'];
              final activityType = modifications['activity_type'] ?? 'activity';

              // Create activity for the specified day
              final activityDate = widget.currentTrip!.startDate.add(
                Duration(days: day - 1),
              );
              final startDateTime = DateTime(
                activityDate.year,
                activityDate.month,
                activityDate.day,
                9,
                0, // Default time
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
            } else if (actionType == 'remove' &&
                modifications['activity'] != null) {
              // For remove operations, we would need to find existing activities
              // This is a simplified version - in practice, Gemini would need to specify which activity to remove
            }

            // If we have changes, return them to the parent screen
            if (activityChanges.isNotEmpty && mounted) {
              Navigator.of(
                context,
              ).pop({'changes': activityChanges, 'message': message});
            }
          }
        } else {
          // Error from backend
          setState(() {
            _messages.add({
              'role': 'assistant',
              'content':
                  responseData['message'] ?? 'Có lỗi xảy ra khi xử lý yêu cầu.',
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
    bool hasPlanningIntent =
        lowerMessage.contains('lên kế hoạch') ||
        lowerMessage.contains('tạo kế hoạch') ||
        lowerMessage.contains('lập kế hoạch') ||
        lowerMessage.contains('plan') ||
        lowerMessage.contains('kế hoạch du lịch') ||
        lowerMessage.contains('trip') ||
        lowerMessage.contains('chuyến đi');

    if (!hasPlanningIntent) return false;

    // If we have a current trip, only need people count (other info from trip card)
    if (widget.currentTrip != null) {
      // When we have current trip context, any planning intent should route to trip planning
      // The trip card already has destination, dates, and budget
      return true; // Always route to trip planning when we have current trip context
    }

    // Without current trip, must contain multiple trip parameters
    int paramCount = 0;

    // Check for duration (days/nights)
    if (lowerMessage.contains('ngày') ||
        lowerMessage.contains('đêm') ||
        lowerMessage.contains('day') ||
        lowerMessage.contains('night')) {
      paramCount++;
    }

    // Check for budget (money terms)
    if (lowerMessage.contains('ngân sách') ||
        lowerMessage.contains('tiền') ||
        lowerMessage.contains('vnd') ||
        lowerMessage.contains('triệu') ||
        lowerMessage.contains('budget') ||
        lowerMessage.contains('cost') ||
        lowerMessage.contains('million') ||
        lowerMessage.contains('\$')) {
      paramCount++;
    }

    // Check for number of people
    if (lowerMessage.contains('người') ||
        lowerMessage.contains('people') ||
        lowerMessage.contains('person')) {
      paramCount++;
    }

    // Check for destination (common destinations or "tại" keyword)
    if (lowerMessage.contains('tại ') ||
        lowerMessage.contains('ở ') ||
        lowerMessage.contains('đến ') ||
        lowerMessage.contains('to ') ||
        lowerMessage.contains('tokyo') ||
        lowerMessage.contains('japan') ||
        lowerMessage.contains('hanoi') ||
        lowerMessage.contains('saigon') ||
        lowerMessage.contains('danang') ||
        lowerMessage.contains('hue') ||
        lowerMessage.contains('paris') ||
        lowerMessage.contains('london') ||
        lowerMessage.contains('singapore') ||
        lowerMessage.contains('thailand')) {
      paramCount++;
    }

    // Comprehensive planning requires at least 2 parameters + planning intent
    return paramCount >= 2;
  }



  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Header
            // Header with gradient matching planner_detail_screen
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.skyBlue.withValues(alpha: 0.9),
                    AppColors.steelBlue.withValues(alpha: 0.8),
                    AppColors.dodgerBlue.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.smart_toy_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'AI Travel Assistant',
                      style: TextStyle(
                        fontFamily: 'Urbanist-Regular',
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            ),

            // Chat content
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _messages.isEmpty && !_isLoading
                    ? _buildWelcomeView()
                    : _messages.isEmpty && _isLoading
                    ? const Center(child: CircularProgressIndicator())
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

            // Loading indicator with gradient accent
            if (_isLoading)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Processing...',
                      style: TextStyle(
                        fontFamily: 'Urbanist-Regular',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

            // People count selector at bottom - show when we have currentTrip and messages exist
            if (widget.currentTrip != null &&
                _messages.isNotEmpty &&
                !_isLoading)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    top: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Try with a different number of people:',
                      style: TextStyle(
                        fontFamily: 'Urbanist-Regular',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Minus button
                        IconButton(
                          onPressed: _peopleCount > 1
                              ? () {
                                  setState(() {
                                    _peopleCount--;
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                          iconSize: 32,
                          color: AppColors.primary,
                          disabledColor: Colors.grey[300],
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 12),
                        // People count display
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.people,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$_peopleCount',
                                style: TextStyle(
                                  fontFamily: 'Urbanist-Regular',
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'people',
                                style: TextStyle(
                                  fontFamily: 'Urbanist-Regular',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Plus button
                        IconButton(
                          onPressed: _peopleCount < 20
                              ? () {
                                  setState(() {
                                    _peopleCount++;
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                          iconSize: 32,
                          color: AppColors.primary,
                          disabledColor: Colors.grey[300],
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 12),
                        // Send button
                        ElevatedButton(
                          onPressed: () => _sendPeopleCount(_peopleCount),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
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
    // Different suggestions based on whether we have a current trip
    final suggestions = widget.currentTrip != null
        ? [
            {
              'icon': Icons.people,
              'text': 'Tạo kế hoạch cho 2 người',
              'query': 'Tạo kế hoạch cho 2 người',
            },
            {
              'icon': Icons.group,
              'text': 'Tạo kế hoạch cho 4 người',
              'query': 'Tạo kế hoạch cho 4 người',
            },
            {
              'icon': Icons.family_restroom,
              'text': 'Tạo kế hoạch cho gia đình 5 người',
              'query': 'Tạo kế hoạch cho gia đình 5 người',
            },
            {
              'icon': Icons.restaurant,
              'text': 'Thêm hoạt động ăn uống',
              'query': 'Thêm các nhà hàng địa phương nổi tiếng vào ngày 1',
            },
            {
              'icon': Icons.tour,
              'text': 'Thêm điểm tham quan',
              'query': 'Thêm các địa điểm tham quan phổ biến vào kế hoạch',
            },
            {
              'icon': Icons.edit_calendar,
              'text': 'Sửa kế hoạch hiện tại',
              'query': 'Tôi muốn thay đổi lịch trình ngày đầu tiên',
            },
          ]
        : [
            {
              'icon': Icons.location_on,
              'text': 'Gợi ý địa điểm du lịch Việt Nam',
              'query':
                  'Bạn có thể gợi ý cho tôi những địa điểm du lịch nổi tiếng ở Việt Nam không?',
            },
            {
              'icon': Icons.flight,
              'text': 'Lên kế hoạch chuyến đi',
              'query':
                  'Tôi muốn lên kế hoạch cho một chuyến du lịch 3 ngày 2 đêm',
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          // Welcome card with AppColors gradient
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.skyBlue.withValues(alpha: 0.9),
                  AppColors.steelBlue.withValues(alpha: 0.85),
                  AppColors.dodgerBlue.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.travel_explore,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Hello! 👋',
                  style: TextStyle(
                    fontFamily: 'Urbanist-Regular',
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.currentTrip != null
                      ? 'I will help you with the planning!'
                      : 'I am your AI travel assistant!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Urbanist-Regular',
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                if (widget.currentTrip != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                widget.currentTrip!.destination,
                                style: const TextStyle(
                                  fontFamily: 'Urbanist-Regular',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.currentTrip!.startDate.day}/${widget.currentTrip!.startDate.month}/${widget.currentTrip!.startDate.year} - ${widget.currentTrip!.endDate.day}/${widget.currentTrip!.endDate.month}/${widget.currentTrip!.endDate.year}',
                              style: TextStyle(
                                fontFamily: 'Urbanist-Regular',
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                        if (widget.currentTrip!.budget != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.account_balance_wallet,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.currentTrip!.budget!.estimatedCost.toStringAsFixed(0)} ${widget.currentTrip!.budget!.currency}',
                                style: TextStyle(
                                  fontFamily: 'Urbanist-Regular',
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.currentTrip != null
                ? 'Just tell me the number of tourists:'
                : 'What do you want to ask?',
            style: TextStyle(
              fontFamily: 'Urbanist-Regular',
              fontSize: 18,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),

          // Show people count selector only when we have a current trip
          if (widget.currentTrip != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Minus button
                  IconButton(
                    onPressed: _peopleCount > 1
                        ? () {
                            setState(() {
                              _peopleCount--;
                            });
                          }
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                    iconSize: 36,
                    color: AppColors.primary,
                    disabledColor: Colors.grey[300],
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  // People count display
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people,
                            color: AppColors.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$_peopleCount',
                            style: TextStyle(
                              fontFamily: 'Urbanist-Regular',
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'people',
                            style: TextStyle(
                              fontFamily: 'Urbanist-Regular',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Plus button
                  IconButton(
                    onPressed: _peopleCount < 20
                        ? () {
                            setState(() {
                              _peopleCount++;
                            });
                          }
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                    iconSize: 36,
                    color: AppColors.primary,
                    disabledColor: Colors.grey[300],
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Travel style input field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _styleController,
                decoration: InputDecoration(
                  labelText: 'Travel style (optional)',
                  hintText: 'Examples: lively, meditative, backpacking...',
                  prefixIcon: Icon(Icons.style, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Confirm button with gradient
            Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isLoading
                      ? null
                      : () => _sendPeopleCount(_peopleCount),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isLoading
                            ? [Colors.grey.shade400, Colors.grey.shade500]
                            : [
                                AppColors.skyBlue.withValues(alpha: 0.9),
                                AppColors.steelBlue.withValues(alpha: 0.85),
                                AppColors.dodgerBlue.withValues(alpha: 0.8),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isLoading ? Icons.hourglass_top : Icons.auto_awesome,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isLoading ? 'Creating...' : 'Creating a plan',
                          style: const TextStyle(
                            fontFamily: 'Urbanist-Regular',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            // Show suggestions grid only when there's no current trip
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _controller.text = suggestion['query'] as String;
                      _sendMessage();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.15),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.skyBlue.withValues(alpha: 0.3),
                                  AppColors.dodgerBlue.withValues(alpha: 0.2),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              suggestion['icon'] as IconData,
                              size: 22,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            suggestion['text'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Urbanist-Regular',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Or enter your question below!',
              style: TextStyle(
                fontFamily: 'Urbanist-Regular',
                fontSize: 13,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _sendPeopleCount(int count) {
    if (_isLoading) return;

    String message = 'Create a plan for $count people';

    // Append travel style if provided
    final style = _styleController.text.trim();
    if (style.isNotEmpty) {
      message += ' with style $style';
    }

    _controller.text = message;
    _sendMessage();
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
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          gradient: isUser
              ? LinearGradient(
                  colors: [
                    AppColors.skyBlue.withValues(alpha: 0.9),
                    AppColors.steelBlue.withValues(alpha: 0.85),
                    AppColors.dodgerBlue.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isUser ? null : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isUser
                ? const Radius.circular(18)
                : const Radius.circular(4),
            bottomRight: isUser
                ? const Radius.circular(4)
                : const Radius.circular(18),
          ),
          border: isUser
              ? null
              : Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: isUser
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Urbanist-Regular',
            color: isUser ? Colors.white : AppColors.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
