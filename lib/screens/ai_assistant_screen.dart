import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AiAssistantScreen extends StatefulWidget {
  @override
  _AiAssistantScreenState createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
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
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/invoke'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'input': userMessage, 'history': history}));

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'AI Travel Assistant',
          style: TextStyle(fontFamily: 'Urbanist-Regular')),
        elevation: 1,
        backgroundColor: Colors.white),
      drawer: Drawer(
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
                    fontSize: 20)))),
            ListTile(
              leading: Icon(Icons.add),
              title: Text('New Chat'),
              onTap: () {
                _newChat();
                Navigator.pop(context);
              }),
            Expanded(
              child: ListView.builder(
                itemCount: _chatHistories.length,
                itemBuilder: (context, index) {
                  final chatHistory = _chatHistories[index];
                  return ListTile(
                    title: Text(
                      'Chat ${_chatHistories.length - index}',
                      overflow: TextOverflow.ellipsis),
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
                      }));
                })),
          ])),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildWelcomeView()
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(
                        message['content']!,
                        message['role']!);
                    })),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircularProgressIndicator()),
          _buildMessageInputField(),
        ]));
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
                end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 4)),
              ]),
            child: Column(
              children: [
                Icon(Icons.travel_explore, size: 48, color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  'Xin chào! 👋',
                  style: TextStyle(
                    fontFamily: 'Urbanist-Regular',
                    fontSize: 28,color: Colors.white)),
                const SizedBox(height: 8),
                Text(
                  'Tôi là trợ lý AI du lịch của bạn!\nSẵn sàng giúp bạn khám phá Việt Nam 🇻🇳',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Urbanist-Regular',
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.5)),
              ])),

          const SizedBox(height: 32),

          Text(
            'Bạn muốn hỏi gì? 🤔',
            style: TextStyle(
              fontFamily: 'Urbanist-Regular',
              fontSize: 20,color: Colors.grey[700])),

          const SizedBox(height: 20),

          // Suggestion cards
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2),
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
                        offset: const Offset(0, 2)),
                    ]),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        suggestion['icon'] as IconData,
                        size: 32,
                        color: Colors.blue.shade600),
                      const SizedBox(height: 12),
                      Text(
                        suggestion['text'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Urbanist-Regular',
                          fontSize: 13,color: Colors.grey[700],
                          height: 1.3)),
                    ])));
            }),

          const SizedBox(height: 24),

          Text(
            'Hoặc nhập câu hỏi của bạn bên dưới! ✨',
            style: TextStyle(
              fontFamily: 'Urbanist-Regular',
              fontSize: 14,
              color: Colors.grey[500],
              fontStyle: FontStyle.italic)),
        ]));
  }

  Widget _buildMessageBubble(String text, String role) {
    final bool isUser = role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue[600] : Colors.grey[200],
          borderRadius: BorderRadius.circular(20.0)),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Urbanist-Regular',
            color: isUser ? Colors.white : Colors.black87))));
  }

  Widget _buildMessageInputField() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, -1)),
        ]),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Ask me anything about your trip...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0)),
              onSubmitted: (_) => _sendMessage())),
          SizedBox(width: 8.0),
          IconButton(
            icon: Icon(Icons.send, color: Colors.blue[600]),
            onPressed: _sendMessage),
        ]));
  }
}
