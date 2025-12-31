import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/providers/app_mode_provider.dart';

void main() {
  group('AppModeProvider tests', () {
    late AppModeProvider provider;

    setUp(() {
      provider = AppModeProvider();
    });

    test('initializes with private mode by default', () {
      expect(provider.isPrivateMode, true);
      expect(provider.isCollaborationMode, false);
    });

    test('toggle mode switches between private and collaboration', () {
      expect(provider.isPrivateMode, true);

      provider.toggleMode();
      expect(provider.isPrivateMode, false);
      expect(provider.isCollaborationMode, true);

      provider.toggleMode();
      expect(provider.isPrivateMode, true);
      expect(provider.isCollaborationMode, false);
    });

    test('setPrivateMode sets mode correctly', () {
      provider.setPrivateMode(false);
      expect(provider.isPrivateMode, false);

      provider.setPrivateMode(true);
      expect(provider.isPrivateMode, true);
    });

    test('setPrivateMode does not notify if mode unchanged', () {
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.setPrivateMode(true); // Already true
      expect(notifyCount, 0);

      provider.setPrivateMode(false);
      expect(notifyCount, 1);
    });

    test('switchToPrivateMode sets private mode', () {
      provider.setPrivateMode(false);
      provider.switchToPrivateMode();
      expect(provider.isPrivateMode, true);
    });

    test('switchToCollaborationMode sets collaboration mode', () {
      provider.switchToCollaborationMode();
      expect(provider.isCollaborationMode, true);
      expect(provider.isPrivateMode, false);
    });

    test('currentModeDisplayName returns correct strings', () {
      expect(provider.currentModeDisplayName, 'Private Mode');

      provider.toggleMode();
      expect(provider.currentModeDisplayName, 'Collaboration Mode');
    });

    test('switchToModeDisplayName returns correct strings', () {
      expect(provider.switchToModeDisplayName, 'Switch to Collaboration');

      provider.toggleMode();
      expect(provider.switchToModeDisplayName, 'Switch to Private');
    });

    test('notifies listeners when mode changes', () {
      var notified = false;
      provider.addListener(() => notified = true);

      provider.toggleMode();
      expect(notified, true);
    });
  });
}
