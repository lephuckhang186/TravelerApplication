import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AiAssistantPanel extends StatefulWidget {
  final VoidCallback onClose;

  const AiAssistantPanel({Key? key, required this.onClose}) : super(key: key);

  @override
  State<AiAssistantPanel> createState() => _AiAssistantPanelState();
}

class _AiAssistantPanelState extends State<AiAssistantPanel>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  String? _selectedSuggestion;

  // Chat history management
  final List<List<Map<String, String>>> _chatHistories = [];

  // Backend status
  bool _isBackendOnline = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Check backend status when panel opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBackendStatus();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleSuggestionTap(String text, String query) {
    setState(() {
      _selectedSuggestion = query;
    });
    // Don't navigate away, just show the suggestion text
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final userMessage = _controller.text;

    setState(() {
      _messages.add({'content': userMessage, 'role': 'user'});
      _isLoading = true;
      _selectedSuggestion = null;
    });

    _controller.clear();

    try {
      // Always call backend API - let backend handle greetings
      final response = await _callTravelAgentAPI(userMessage);

      if (mounted) {
        setState(() {
          _messages.add({'content': response, 'role': 'assistant'});
          _isLoading = false;
        });
      }
    } catch (e) {
      // Fallback to error message if API fails
      if (mounted) {
        setState(() {
          _messages.add({
            'content':
                'Xin lỗi, tôi không thể kết nối đến server AI ngay lúc này. Vui lòng thử lại sau. \n\nLỗi: $e',
            'role': 'assistant',
          });
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkBackendStatus() async {
    try {
      const String healthUrl = 'http://localhost:8000/health';
      final response = await http.get(Uri.parse(healthUrl));

      if (mounted) {
        setState(() {
          _isBackendOnline = response.statusCode == 200;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBackendOnline = false;
        });
      }
    }
  }

  Future<String> _callTravelAgentAPI(String userInput) async {
    const String apiUrl = 'http://localhost:8000/invoke';

    try {
      // Prepare message history for API
      final List<Map<String, String>> history = _messages
          .where((msg) => msg['role'] != 'user' || msg['content'] != userInput)
          .toList();

      final Map<String, dynamic> requestBody = {
        'input': userInput,
        'history': history,
      };

      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      // Update backend status
      if (mounted) {
        setState(() {
          _isBackendOnline = response.statusCode == 200;
        });
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData['summary'] ??
            'Xin lỗi, tôi không thể tạo phản hồi.';
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      // Update backend status on error
      if (mounted) {
        setState(() {
          _isBackendOnline = false;
        });
      }
      rethrow;
    }
  }

  void _close() {
    widget.onClose();
  }

  void _showMenuOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Tùy chọn Chat',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            // New Chat option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.add_comment,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
              ),
              title: Text(
                'Chat mới',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                'Bắt đầu cuộc trò chuyện mới',
                style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14),
              ),
              onTap: () {
                Navigator.pop(context);
                _newChat();
              },
            ),

            // Chat History option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.history,
                  color: Colors.green.shade600,
                  size: 20,
                ),
              ),
              title: Text(
                'Lịch sử chat',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                '${_chatHistories.length} cuộc trò chuyện đã lưu',
                style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14),
              ),
              onTap: () {
                Navigator.pop(context);
                _showChatHistory();
              },
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _newChat() {
    // Save current chat if it has messages
    if (_messages.isNotEmpty) {
      setState(() {
        _chatHistories.add(List.from(_messages));
      });
    }

    // Clear current chat
    setState(() {
      _messages.clear();
      _selectedSuggestion = null;
      _isLoading = false;
    });
  }

  void _showChatHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Icon(Icons.history, color: Colors.blue.shade600, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Lịch sử Chat',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_chatHistories.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có lịch sử chat',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _chatHistories.length,
                  itemBuilder: (context, index) {
                    final chatHistory = _chatHistories[index];
                    final firstMessage = chatHistory.isNotEmpty
                        ? chatHistory[0]['content'] ?? ''
                        : '';
                    final preview = firstMessage.length > 50
                        ? '${firstMessage.substring(0, 50)}...'
                        : firstMessage;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          child: Text(
                            '${index + 1}',
                            style: GoogleFonts.inter(
                              color: Colors.blue.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          'Chat ${index + 1}',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          preview.isEmpty ? 'Chat trống' : preview,
                          style: GoogleFonts.inter(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${chatHistory.length}',
                              style: GoogleFonts.inter(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.message,
                              color: Colors.grey[400],
                              size: 16,
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _loadChatHistory(index);
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _loadChatHistory(int index) {
    setState(() {
      _messages.clear();
      _messages.addAll(_chatHistories[index]);
      _selectedSuggestion = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Expanded(child: _buildMainContent()),
            if (_isLoading) _buildLoadingIndicator(),
            _buildInputField(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    // Always show welcome view with messages below if any
    return _buildWelcomeView();
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.travel_explore, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Travel Assistant',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isBackendOnline ? Colors.greenAccent : Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isBackendOnline ? 'Đang hoạt động' : 'Không thể kết nối',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Menu button
          GestureDetector(
            onTap: _showMenuOptions,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.menu, size: 20, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _close,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.close, size: 20, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeView() {
    final suggestions = [
      {
        'icon': Icons.location_on,
        'text': 'Gợi ý địa điểm',
        'query':
            'Bạn có thể gợi ý cho tôi những địa điểm du lịch nổi tiếng ở Việt Nam không?',
      },
      {
        'icon': Icons.flight,
        'text': 'Lên kế hoạch',
        'query': 'Tôi muốn lên kế hoạch cho một chuyến du lịch 3 ngày 2 đêm',
      },
      {
        'icon': Icons.restaurant,
        'text': 'Ẩm thực',
        'query': 'Những món ăn đặc sản nào tôi nên thử khi du lịch?',
      },
      {
        'icon': Icons.hotel,
        'text': 'Chỗ ở',
        'query':
            'Bạn có thể giúp tôi tìm khách sạn với ngân sách hợp lý không?',
      },
      {
        'icon': Icons.directions_car,
        'text': 'Di chuyển',
        'query': 'Cách di chuyển tốt nhất giữa các thành phố là gì?',
      },
      {
        'icon': Icons.attach_money,
        'text': 'Chi phí',
        'query': 'Chi phí cho một chuyến du lịch thường là bao nhiêu?',
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),

          // Welcome message - Compact version
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
                Icon(Icons.travel_explore, size: 36, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  'Xin chào! 👋',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tôi là trợ lý AI du lịch của bạn!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Bạn muốn hỏi gì? 🤔',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),

          const SizedBox(height: 12),

          // Suggestion cards - 3x2 Grid with horizontal layout
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 2.5,
            ),
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = suggestions[index];
              return InkWell(
                onTap: () {
                  _handleSuggestionTap(
                    suggestion['text'] as String,
                    suggestion['query'] as String,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        suggestion['icon'] as IconData,
                        size: 16,
                        color: Colors.blue.shade600,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          suggestion['text'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Show selected suggestion text - BELOW the grid
          if (_selectedSuggestion != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 16,
                        color: Colors.blue.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Câu hỏi của bạn:',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedSuggestion!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.blue.shade800,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedSuggestion = null;
                          });
                        },
                        child: Text(
                          'Hủy',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _controller.text = _selectedSuggestion!;
                          _sendMessage();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        child: const Text('Gửi câu hỏi'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          if (_selectedSuggestion == null && _messages.isEmpty)
            Text(
              'Hoặc nhập câu hỏi của bạn bên dưới! ✨',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),

          // Chat messages section - appears below suggestions
          if (_messages.isNotEmpty) ...[
            const SizedBox(height: 16),

            // Messages - directly without container wrapper
            ...(_messages.map(
              (message) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildMessageBubble(
                  message['content'] as String,
                  message['role'] as String,
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, String role) {
    final bool isUser = role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        padding: const EdgeInsets.all(12.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
          minWidth: 80,
        ),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue[600] : Colors.grey[100],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: SelectableText(
          text,
          style: GoogleFonts.inter(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 14,
            height: 1.4,
          ),
          // Enable text selection and copying
          enableInteractiveSelection: true,
          textAlign: TextAlign.left,
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            'AI đang suy nghĩ...',
            style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: null,
              minLines: 1,
              textInputAction: TextInputAction.newline,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                hintText: 'Nhập câu hỏi của bạn...',
                hintStyle: GoogleFonts.inter(color: Colors.grey[500]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.blue.shade400),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              style: GoogleFonts.inter(fontSize: 14, height: 1.4),
              onSubmitted: (text) {
                // Only send if Shift+Enter is not pressed (single line submit)
                if (!text.contains('\n')) {
                  _sendMessage();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
