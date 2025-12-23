import 'package:flutter/material.dart';
import '../../Core/theme/app_theme.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  String _searchQuery = '';

  final List<Map<String, dynamic>> _helpCategories = [
    {
      'title': 'Getting Started',
      'icon': Icons.rocket_launch,
      'color': Colors.purple,
      'items': [
        {
          'question': 'What features does the app have?',
          'answer':
              'The app has 3 main tabs:\n• Plan: Travel planning, location search, AI Assistant\n• Analysis: Expense management, financial reports\n• Setting: Account settings, utilities, support',
        },
        {
          'question': 'How to navigate in the app?',
          'answer':
              'Use the bottom navigation bar to switch between the 3 main tabs. Each tab has its own features and sub-screens.',
        },
        {
          'question': 'Where should I start?',
          'answer':
              'Recommend starting from the "Plan" tab to create your first travel plan. Then use the "Analysis" tab to track expenses and "Setting" tab to customize the app.',
        },
      ],
    },
    {
      'title': 'Travel Planning',
      'icon': Icons.event_note,
      'color': Colors.blue,
      'items': [
        {
          'question': 'How to create a new travel plan?',
          'answer':
              'Go to "Plan" tab → press "+" button → enter trip name, time, number of participants → select "Save". You can add activities, locations, and notes to your plan.',
        },
        {
          'question': 'Can I share plans with friends?',
          'answer':
              'Yes! Open plan → press "Share" button → choose sharing method (link, email, social media). Friends can view and contribute feedback to your plan.',
        },
        {
          'question': 'How does AI assist with planning?',
          'answer':
              'Use AI Assistant by clicking the chat box "Ask, chat, plan trip with AI...". AI will suggest itineraries and suitable activities based on your preferences and budget.',
        },
      ],
    },
    {
      'title': 'Expense Management',
      'icon': Icons.account_balance_wallet,
      'color': Colors.green,
      'items': [
        {
          'question': 'How to track expenses during trips?',
          'answer':
              'Go to "Analysis" tab → "Expense Management" → press "+" to add expenses. You can categorize by: food, transportation, accommodation, shopping, entertainment.',
        },
        {
          'question': 'Can I set a budget for trips?',
          'answer':
              'Yes! When creating a new plan, you can set a total budget. The app will track and alert when expenses approach the set limit.',
        },
        {
          'question': 'How to view expense reports?',
          'answer':
              'The "Analysis" tab displays expense charts by category, comparison with previous month, and spending trends. You can export reports in PDF or Excel format.',
        },
      ],
    },
    {
      'title': 'Account & Security',
      'icon': Icons.account_circle,
      'color': Colors.orange,
      'items': [
        {
          'question': 'How to change personal information?',
          'answer':
              'Go to "Setting" tab → click on "Personal Profile" or your avatar. Here you can update name, profile picture, and contact information.',
        },
        {
          'question': 'Is my data safe?',
          'answer':
              'We use SSL encryption and store data on secure servers. Personal information is not shared with third parties without your consent.',
        },
        {
          'question': 'What utilities are available in Settings?',
          'answer':
              'The Setting tab provides many useful utilities:\n• Currency Exchange\n• Text Translation\n• Expense Management\n• Travel Stats\n• Notification Settings\n• Change Password',
        },
      ],
    },
  ];

  List<Map<String, dynamic>> get _filteredCategories {
    if (_searchQuery.isEmpty) return _helpCategories;

    return _helpCategories
        .map((category) {
          final filteredItems = category['items']
              .where(
                (item) =>
                    item['question'].toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    item['answer'].toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
              )
              .toList();

          if (filteredItems.isEmpty) return null;

          return {...category, 'items': filteredItems};
        })
        .where((category) => category != null)
        .cast<Map<String, dynamic>>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Help Center',
          style: TextStyle(fontFamily: 'Urbanist-Regular', 
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search questions...',
                  hintStyle: TextStyle(fontFamily: 'Urbanist-Regular', color: Colors.grey[500]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: TextStyle(fontFamily: 'Urbanist-Regular', fontSize: 14),
              ),
            ),
          ),

          // Content
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredCategories.length,
              itemBuilder: (context, index) {
                final category = _filteredCategories[index];
                return _buildCategoryCard(category);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: category['color'].withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(category['icon'], color: category['color'], size: 24),
        ),
        title: Text(
          category['title'],
          style: TextStyle(fontFamily: 'Urbanist-Regular', 
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          '${category['items'].length} questions',
          style: TextStyle(fontFamily: 'Urbanist-Regular',
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        children: (category['items'] as List)
            .map<Widget>(
              (item) => _buildQuestionItem(item['question'], item['answer']),
            )
            .toList(),
      ),
    );
  }

  Widget _buildQuestionItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: TextStyle(fontFamily: 'Urbanist-Regular', 
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: TextStyle(fontFamily: 'Urbanist-Regular', 
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
