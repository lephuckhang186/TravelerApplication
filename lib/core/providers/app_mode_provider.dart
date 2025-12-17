import 'package:flutter/foundation.dart';

/// Provider to manage app mode (Private vs Collaboration)
/// COMPLETELY SEPARATE - No shared data between modes
class AppModeProvider extends ChangeNotifier {
  bool _isPrivateMode = true;

  bool get isPrivateMode => _isPrivateMode;
  bool get isCollaborationMode => !_isPrivateMode;
  
  String get currentModeDisplayName => _isPrivateMode ? 'Private Mode' : 'Collaboration Mode';
  String get switchToModeDisplayName => _isPrivateMode ? 'Switch to Collaboration' : 'Switch to Private';

  /// Toggle between Private and Collaboration modes
  /// This completely switches the entire app context
  void toggleMode() {
    _isPrivateMode = !_isPrivateMode;
    debugPrint('DEBUG: AppModeProvider.toggleMode() - Switched to ${currentModeDisplayName}');
    notifyListeners();
  }

  /// Set specific mode
  void setPrivateMode(bool isPrivate) {
    if (_isPrivateMode != isPrivate) {
      _isPrivateMode = isPrivate;
      debugPrint('DEBUG: AppModeProvider.setPrivateMode() - Set to ${currentModeDisplayName}');
      notifyListeners();
    }
  }

  /// Switch to Private mode explicitly
  void switchToPrivateMode() {
    setPrivateMode(true);
  }

  /// Switch to Collaboration mode explicitly
  void switchToCollaborationMode() {
    setPrivateMode(false);
  }
}
