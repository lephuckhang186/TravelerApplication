import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/user_service.dart';
import 'ai_assistant_screen.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> with AutomaticKeepAliveClientMixin {
  // String _currentUsername = 'User'; // Removed unused field
  String _displayName = 'User';
  
  @override
  bool get wantKeepAlive => false; // Don't keep alive so it refreshes
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  @override
  void didUpdateWidget(PlanScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadUserData(); // Refresh when widget updates
  }
  
  void _loadUserData() async {
    final userService = UserService();
    final profile = userService.getUserProfile();
    final username = await userService.getDisplayName();
    
    setState(() {
      // _currentUsername = username; // Removed unused field
      _displayName = profile['fullName']?.isNotEmpty == true 
          ? profile['fullName']! 
          : username;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            _buildHeader(),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Jump back in section
                    _buildJumpBackInSection(),
                    
                    const SizedBox(height: 24),
                    
                    // Private section
                    _buildPrivateSection(),
                    
                    const SizedBox(height: 24),
                    
                    // Collaborations section
                    _buildCollaborationsSection(),
                    
                    const SizedBox(height: 100), // Space for bottom nav and chat
                  ],
                ),
              ),
            ),
            
            // AI Chat button
            _buildAIChatButton(),
          ],
        ),
      ),
    );
  }

  /// Header with user dropdown and menu
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // User dropdown - Extended
          Expanded(
            child: GestureDetector(
              onTap: () => _showUserMenu(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // User avatar with heart icon
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.favorite,
                          color: Colors.red,
                          size: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _displayName,
                        style: GoogleFonts.quattrocento(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const Spacer(),
          
          // Menu button
          GestureDetector(
            onTap: () => _showMenuOptions(),
            child: AnimatedScale(
              scale: 1.0,
              duration: const Duration(milliseconds: 150),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.more_horiz,
                  color: Colors.grey[600],
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Jump back in section
  Widget _buildJumpBackInSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jump back in',
          style: GoogleFonts.quattrocento(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildPlannerCard(
                'Da Nang Planner',
                'images/danang.jpg',
                Colors.teal,
                () => _onPlannerTap('Da Nang'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPlannerCard(
                'Ho Chi Minh Planner',
                'images/hcmc_skyline.jpg',
                Colors.blue,
                () => _onPlannerTap('Ho Chi Minh'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Planner Card with hover effects - Redesigned with 3/4 image and 1/4 white text area
  Widget _buildPlannerCard(String title, String imagePath, Color fallbackColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        // Add haptic feedback
        _onPlannerTapWithAnimation(onTap);
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: 1.0),
        duration: const Duration(milliseconds: 200),
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  children: [
                    // Image area (3/4 of height = 90px)
                    SizedBox(
                      height: 90,
                      width: double.infinity,
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  fallbackColor,
                                  fallbackColor.withValues(alpha: 0.8),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // Text area (1/4 of height = 30px) with white background
                    Container(
                      height: 30,
                      width: double.infinity,
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Center(
                        child: Text(
                          title,
                          style: GoogleFonts.quattrocento(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Private section
  Widget _buildPrivateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Private',
              style: GoogleFonts.quattrocento(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                GestureDetector(
                  onTap: () => _showPrivateOptions(),
                  child: AnimatedScale(
                    scale: 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(Icons.more_horiz, color: Colors.grey[600], size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _onAddPrivatePlanner(),
                  child: AnimatedScale(
                    scale: 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(Icons.add, color: Colors.grey[600], size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildPrivateItem('Da Nang Planner', Icons.calendar_today),
        const SizedBox(height: 12),
        _buildPrivateItem('Ho Chi Minh Planner', Icons.calendar_today),
      ],
    );
  }

  /// Private item with tap effects
  Widget _buildPrivateItem(String title, IconData icon) {
    return GestureDetector(
      onTap: () => _onPrivateItemTapWithAnimation(title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.chevron_right,
              color: Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 12),
            Icon(
              icon,
              color: Colors.grey[700],
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.quattrocento(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () => _showPrivateItemOptions(title),
                  child: AnimatedScale(
                    scale: 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(Icons.more_horiz, color: Colors.grey[600], size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _addToPrivateItem(title),
                  child: AnimatedScale(
                    scale: 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(Icons.add, color: Colors.grey[600], size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Collaborations section
  Widget _buildCollaborationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Collaborations',
              style: GoogleFonts.quattrocento(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                GestureDetector(
                  onTap: () => _showCollaborationOptions(),
                  child: AnimatedScale(
                    scale: 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(Icons.more_horiz, color: Colors.grey[600], size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _onAddCollaboration(),
                  child: AnimatedScale(
                    scale: 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(Icons.add, color: Colors.grey[600], size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Empty state
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              // Calendar icon with "01"
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.calendar_today_outlined,
                        size: 40,
                        color: Colors.grey[400],
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '01',
                          style: GoogleFonts.quattrocento(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Uh oh! There is not anyone yet!',
                style: GoogleFonts.quattrocento(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// AI Chat button with animation - Extended width and better text positioning
  Widget _buildAIChatButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: () => _onAIChatTapWithAnimation(),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 1.0, end: 1.0),
          duration: const Duration(milliseconds: 200),
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.grey[300]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.smart_toy_outlined,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ask, chat, plan trip with AI...',
                        style: GoogleFonts.quattrocento(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Animated event handlers
  void _onPlannerTapWithAnimation(VoidCallback onTap) {
    // Add ripple effect
    setState(() {});
    Future.delayed(const Duration(milliseconds: 100), onTap);
  }

  void _onPrivateItemTapWithAnimation(String title) {
    setState(() {});
    Future.delayed(const Duration(milliseconds: 100), () {
      _showMessage('Opening $title...');
    });
  }

  void _onAIChatTapWithAnimation() {
    setState(() {});
    Future.delayed(const Duration(milliseconds: 100), () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AiAssistantScreen()),
      );
    });
  }

  // Event handlers with bottom sheet animations
  void _showUserMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile Settings'),
              onTap: () {
                Navigator.pop(context);
                _showMessage('Opening profile...');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                _showMessage('Logging out...');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMenuOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                _showMessage('Opening settings...');
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                _showMessage('Sharing...');
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help'),
              onTap: () {
                Navigator.pop(context);
                _showMessage('Opening help...');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivateOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.sort),
              title: const Text('Sort by'),
              onTap: () {
                Navigator.pop(context);
                _showMessage('Sorting options...');
              },
            ),
            ListTile(
              leading: const Icon(Icons.filter_list),
              title: const Text('Filter'),
              onTap: () {
                Navigator.pop(context);
                _showMessage('Filter options...');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivateItemOptions(String title) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                _showMessage('Editing $title...');
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                _showMessage('Sharing $title...');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              textColor: Colors.red,
              iconColor: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _showMessage('Deleting $title...');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCollaborationOptions() {
    _showMessage('Collaboration options...');
  }

  void _onPlannerTap(String plannerName) {
    _showMessage('Opening $plannerName planner...');
  }

  void _onAddPrivatePlanner() {
    _showMessage('Adding new private planner...');
  }

  void _addToPrivateItem(String title) {
    _showMessage('Adding to $title...');
  }

  void _onAddCollaboration() {
    _showMessage('Adding new collaboration...');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF7B61FF),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}