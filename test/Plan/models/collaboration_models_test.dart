import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/Plan/models/collaboration_models.dart';

void main() {
  group('EditRequestStatus enum tests', () {
    test('has correct values', () {
      expect(EditRequestStatus.pending, isNotNull);
      expect(EditRequestStatus.approved, isNotNull);
      expect(EditRequestStatus.rejected, isNotNull);
    });

    test('toJson returns correct string', () {
      expect(EditRequestStatus.pending.toJson(), 'pending');
      expect(EditRequestStatus.approved.toJson(), 'approved');
      expect(EditRequestStatus.rejected.toJson(), 'rejected');
    });

    test('fromJson parses correctly', () {
      expect(EditRequestStatus.fromJson('pending'), EditRequestStatus.pending);
      expect(
        EditRequestStatus.fromJson('approved'),
        EditRequestStatus.approved,
      );
      expect(
        EditRequestStatus.fromJson('rejected'),
        EditRequestStatus.rejected,
      );
      expect(
        EditRequestStatus.fromJson('invalid'),
        EditRequestStatus.pending,
      ); // default
    });

    test('displayName returns formatted text', () {
      expect(EditRequestStatus.pending.displayName, 'Pending');
      expect(EditRequestStatus.approved.displayName, 'Approved');
      expect(EditRequestStatus.rejected.displayName, 'Rejected');
    });
  });

  group('ActivityEditRequestStatus enum tests', () {
    test('has correct values', () {
      expect(ActivityEditRequestStatus.pending, isNotNull);
      expect(ActivityEditRequestStatus.approved, isNotNull);
      expect(ActivityEditRequestStatus.rejected, isNotNull);
    });

    test('toJson and fromJson work correctly', () {
      expect(ActivityEditRequestStatus.approved.toJson(), 'approved');
      expect(
        ActivityEditRequestStatus.fromJson('approved'),
        ActivityEditRequestStatus.approved,
      );
    });
  });

  group('Collaborator model tests', () {
    test('creates collaborator with required fields', () {
      final collab = Collaborator(
        id: 'c1',
        userId: 'u1',
        email: 'test@example.com',
        name: 'Test User',
        role: 'editor',
        addedAt: DateTime(2024, 1, 1),
      );

      expect(collab.id, 'c1');
      expect(collab.userId, 'u1');
      expect(collab.email, 'test@example.com');
      expect(collab.name, 'Test User');
      expect(collab.role, 'editor');
      expect(collab.isActive, true); // default
    });

    test('role getters work correctly', () {
      final owner = Collaborator(
        id: 'c1',
        userId: 'u1',
        email: 'owner@example.com',
        name: 'Owner',
        role: 'owner',
        addedAt: DateTime(2024, 1, 1),
      );

      expect(owner.isOwner, true);
      expect(owner.isEditor, false);
      expect(owner.canEdit, true);

      final editor = Collaborator(
        id: 'c2',
        userId: 'u2',
        email: 'editor@example.com',
        name: 'Editor',
        role: 'editor',
        addedAt: DateTime(2024, 1, 1),
      );

      expect(editor.isEditor, true);
      expect(editor.canEdit, true);

      final viewer = Collaborator(
        id: 'c3',
        userId: 'u3',
        email: 'viewer@example.com',
        name: 'Viewer',
        role: 'viewer',
        addedAt: DateTime(2024, 1, 1),
      );

      expect(viewer.isViewer, true);
      expect(viewer.canOnlyView, true);
      expect(viewer.canEdit, false);
    });

    test('toJson and fromJson work correctly', () {
      final collab = Collaborator(
        id: 'c1',
        userId: 'u1',
        email: 'test@example.com',
        name: 'Test User',
        role: 'editor',
        addedAt: DateTime(2024, 1, 1),
        isActive: true,
      );

      final json = collab.toJson();
      expect(json['id'], 'c1');
      expect(json['userId'], 'u1');
      expect(json['role'], 'editor');

      final decoded = Collaborator.fromJson(json);
      expect(decoded.id, 'c1');
      expect(decoded.userId, 'u1');
      expect(decoded.role, 'editor');
    });
  });
}
