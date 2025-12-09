import 'package:flutter/foundation.dart';

/// Provider to manage app mode (Private vs Collaboration)
class AppModeProvider extends ChangeNotifier {
  bool _isPrivateMode = true;

  bool get isPrivateMode => _isPrivateMode;
  bool get isCollaborationMode => !_isPrivateMode;

  void toggleMode() {
    _isPrivateMode = !_isPrivateMode;
    notifyListeners();
  }

  void setPrivateMode(bool isPrivate) {
    _isPrivateMode = isPrivate;
    notifyListeners();
  }
}
