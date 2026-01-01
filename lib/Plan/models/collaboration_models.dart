import 'trip_model.dart';
import 'activity_models.dart';

/// Collaborator model representing a user participating in a shared trip.
///
/// Stores user identification, contact info, and their assigned permission role.
class Collaborator {
  final String id;
  final String userId;
  final String email;
  final String name;

  /// Assigned role: 'owner', 'editor', or 'viewer'.
  final String role;
  final DateTime addedAt;
  final bool isActive;

  const Collaborator({
    required this.id,
    required this.userId,
    required this.email,
    required this.name,
    required this.role,
    required this.addedAt,
    this.isActive = true,
  });

  /// Creates a [Collaborator] from a JSON map, handling Firestore data types.
  factory Collaborator.fromJson(Map<String, dynamic> json) {
    // Helper function to convert Firestore Timestamp/DateTime
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) return DateTime.parse(value);
      // Handle Firestore Timestamp
      if (value.runtimeType.toString().contains('Timestamp')) {
        return (value as dynamic).toDate();
      }
      return DateTime.now();
    }

    return Collaborator(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'viewer',
      addedAt: parseDateTime(json['addedAt']),
      isActive: json['isActive'] ?? true,
    );
  }

  /// Converts the collaborator to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'email': email,
      'name': name,
      'role': role,
      'addedAt': addedAt.millisecondsSinceEpoch,
      'isActive': isActive,
    };
  }

  /// Creates a copy of the collaborator with modified fields.
  Collaborator copyWith({
    String? id,
    String? userId,
    String? email,
    String? name,
    String? role,
    DateTime? addedAt,
    bool? isActive,
  }) {
    return Collaborator(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      addedAt: addedAt ?? this.addedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Whether the user is the trip owner.
  bool get isOwner => role == 'owner';

  /// Whether the user has editor permissions.
  bool get isEditor => role == 'editor';

  /// Whether the user has viewer permissions.
  bool get isViewer => role == 'viewer';

  /// Check if user can edit the trip (owner or editor).
  bool get canEdit => isOwner || isEditor;

  /// Check if user can only view the trip.
  bool get canOnlyView => isViewer;
}

/// Shared trip model that extends [TripModel] with collaboration features.
///
/// Includes owner information, a list of [Collaborator]s, and real-time syncing status.
class SharedTripModel extends TripModel {
  /// List of additional users participating in the trip.
  final List<Collaborator> sharedCollaborators;
  final String ownerId;
  final String ownerName;
  final String ownerEmail;

  /// Whether the trip supports real-time multi-user updates.
  final bool isRealTimeEnabled;

  /// Timestamp of the most recent activity on this trip.
  final DateTime? lastActivity;

  /// Name or ID of the user who performed the last activity.
  final String? lastActivityBy;

  /// Public URL for sharing the trip access.
  final String? shareableLink;

  /// Mapping of userId to permission level for quick lookup.
  final Map<String, dynamic>? permissions;

  SharedTripModel({
    required super.id,
    required super.name,
    required super.destination,
    required super.startDate,
    required super.endDate,
    super.activities,
    super.description,
    super.budget,
    super.collaborators,
    super.coverImage,
    super.createdBy,
    super.createdAt,
    super.updatedAt,
    super.isActive,
    super.preferences,
    this.sharedCollaborators = const [],
    required this.ownerId,
    required this.ownerName,
    required this.ownerEmail,
    this.isRealTimeEnabled = true,
    this.lastActivity,
    this.lastActivityBy,
    this.shareableLink,
    this.permissions,
  });

  /// Upgrades a regular [TripModel] to a [SharedTripModel].
  factory SharedTripModel.fromTripModel(
    TripModel trip, {
    required String ownerId,
    required String ownerName,
    required String ownerEmail,
    List<Collaborator>? collaborators,
    String? shareableLink,
    Map<String, dynamic>? permissions,
  }) {
    return SharedTripModel(
      id: trip.id,
      name: trip.name,
      destination: trip.destination,
      startDate: trip.startDate,
      endDate: trip.endDate,
      activities: trip.activities,
      description: trip.description,
      budget: trip.budget,
      collaborators: trip.collaborators,
      coverImage: trip.coverImage,
      createdBy: trip.createdBy,
      createdAt: trip.createdAt,
      updatedAt: trip.updatedAt,
      isActive: trip.isActive,
      preferences: trip.preferences,
      ownerId: ownerId,
      ownerName: ownerName,
      ownerEmail: ownerEmail,
      sharedCollaborators: collaborators ?? [],
      shareableLink: shareableLink,
      permissions: permissions,
    );
  }

  /// Creates a [SharedTripModel] from a JSON map.
  factory SharedTripModel.fromJson(Map<String, dynamic> json) {
    final collaboratorsList =
        (json['sharedCollaborators'] as List?)
            ?.map((c) => Collaborator.fromJson(c))
            .toList() ??
        [];

    // Helper function to convert Firestore Timestamp/DateTime
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) return DateTime.parse(value);
      // Handle Firestore Timestamp
      if (value.runtimeType.toString().contains('Timestamp')) {
        return (value as dynamic).toDate();
      }
      return null;
    }

    return SharedTripModel(
      id: json['id'],
      name: json['name'] ?? '',
      destination: json['destination'] ?? '',
      startDate: parseDateTime(json['startDate']) ?? DateTime.now(),
      endDate: parseDateTime(json['endDate']) ?? DateTime.now(),
      activities:
          (json['activities'] as List?)
              ?.map((a) => ActivityModel.fromJson(a))
              .toList() ??
          [],
      description: json['description'],
      budget: json['budget'] != null
          ? BudgetModel.fromJson(json['budget'])
          : null,
      collaborators: List<String>.from(json['collaborators'] ?? []),
      coverImage: json['coverImage'],
      createdBy: json['createdBy'],
      createdAt: parseDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: parseDateTime(json['updatedAt']) ?? DateTime.now(),
      isActive: json['isActive'] ?? true,
      preferences: json['preferences'] as Map<String, dynamic>?,
      sharedCollaborators: collaboratorsList,
      ownerId: json['ownerId'] ?? '',
      ownerName: json['ownerName'] ?? '',
      ownerEmail: json['ownerEmail'] ?? '',
      isRealTimeEnabled: json['isRealTimeEnabled'] ?? true,
      lastActivity: parseDateTime(json['lastActivity']),
      lastActivityBy: json['lastActivityBy'],
      shareableLink: json['shareableLink'],
      permissions: json['permissions'] as Map<String, dynamic>?,
    );
  }

  /// Converts the shared trip to a JSON map.
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'destination': destination,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'activities': activities.map((a) => a.toJson()).toList(),
      'description': description,
      'budget': budget?.toJson(),
      'collaborators': collaborators,
      'coverImage': coverImage,
      'createdBy': createdBy,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'isActive': isActive,
      'preferences': preferences,
      'sharedCollaborators': sharedCollaborators
          .map((c) => c.toJson())
          .toList(),
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerEmail': ownerEmail,
      'isRealTimeEnabled': isRealTimeEnabled,
      'lastActivity': lastActivity?.millisecondsSinceEpoch,
      'lastActivityBy': lastActivityBy,
      'shareableLink': shareableLink,
      'permissions': permissions,
    };
  }

  /// Creates a copy of the shared trip with modified fields.
  @override
  SharedTripModel copyWith({
    String? id,
    String? name,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    List<ActivityModel>? activities,
    String? description,
    BudgetModel? budget,
    List<String>? collaborators,
    String? coverImage,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    Map<String, dynamic>? preferences,
    List<Collaborator>? sharedCollaborators,
    String? ownerId,
    String? ownerName,
    String? ownerEmail,
    bool? isRealTimeEnabled,
    DateTime? lastActivity,
    String? lastActivityBy,
    String? shareableLink,
    Map<String, dynamic>? permissions,
  }) {
    return SharedTripModel(
      id: id ?? this.id,
      name: name ?? this.name,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      activities: activities ?? this.activities,
      description: description ?? this.description,
      budget: budget ?? this.budget,
      collaborators: collaborators ?? this.collaborators,
      coverImage: coverImage ?? this.coverImage,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      preferences: preferences ?? this.preferences,
      sharedCollaborators: sharedCollaborators ?? this.sharedCollaborators,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      isRealTimeEnabled: isRealTimeEnabled ?? this.isRealTimeEnabled,
      lastActivity: lastActivity ?? this.lastActivity,
      lastActivityBy: lastActivityBy ?? this.lastActivityBy,
      shareableLink: shareableLink ?? this.shareableLink,
      permissions: permissions ?? this.permissions,
    );
  }

  /// Check if the specified [userId] is the trip owner.
  bool isOwnerUser(String userId) => ownerId == userId;

  /// Check if the specified [userId] is an active collaborator.
  bool isUserCollaborator(String userId) {
    return sharedCollaborators.any((c) => c.userId == userId && c.isActive);
  }

  /// Check if the specified [userId] has access to this trip.
  bool hasUserAccess(String userId) {
    return isOwnerUser(userId) || isUserCollaborator(userId);
  }

  /// Retrieve collaborator details by user ID.
  Collaborator? getCollaboratorByUserId(String userId) {
    try {
      return sharedCollaborators.firstWhere(
        (c) => c.userId == userId && c.isActive,
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if the specified [userId] can edit this trip.
  bool canUserEdit(String userId) {
    if (isOwnerUser(userId)) return true;
    final collaborator = getCollaboratorByUserId(userId);
    return collaborator?.canEdit ?? false;
  }

  /// Check if the specified [userId] has view-only access.
  bool canUserOnlyView(String userId) {
    if (isOwnerUser(userId)) return false;
    final collaborator = getCollaboratorByUserId(userId);
    return collaborator?.canOnlyView ?? true;
  }

  /// List of all currently active collaborators.
  List<Collaborator> get activeCollaborators =>
      sharedCollaborators.where((c) => c.isActive).toList();

  /// List of all collaborators, including inactive ones.
  List<Collaborator> get allCollaborators => sharedCollaborators;

  /// Downgrades this shared trip to a regular [TripModel].
  TripModel toTripModel() {
    return TripModel(
      id: id,
      name: name,
      destination: destination,
      startDate: startDate,
      endDate: endDate,
      activities: activities,
      description: description,
      budget: budget,
      collaborators: collaborators,
      coverImage: coverImage,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isActive: isActive,
      preferences: preferences,
    );
  }
}

/// Model for a trip invitation sent to another user via email.
class TripInvitation {
  final String id;
  final String tripId;
  final String tripName;

  /// User ID of the person who sent the invitation.
  final String inviterUserId;
  final String inviterName;
  final String inviterEmail;
  final String inviteeEmail;

  /// User ID of the recipient (null if the recipient doesn't have an account yet).
  final String? inviteeUserId;

  /// Status: 'pending', 'accepted', 'declined'.
  final String status;
  final DateTime sentAt;
  final DateTime? respondedAt;

  /// Personal message included in the invitation.
  final String? message;

  /// Level of permission offered: 'editor' or 'viewer'.
  final String permissionLevel;

  const TripInvitation({
    required this.id,
    required this.tripId,
    required this.tripName,
    required this.inviterUserId,
    required this.inviterName,
    required this.inviterEmail,
    required this.inviteeEmail,
    this.inviteeUserId,
    this.status = 'pending',
    required this.sentAt,
    this.respondedAt,
    this.message,
    this.permissionLevel = 'editor',
  });

  /// Creates a [TripInvitation] from a JSON map.
  factory TripInvitation.fromJson(Map<String, dynamic> json) {
    // Helper function to convert Firestore Timestamp/DateTime
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) return DateTime.parse(value);
      // Handle Firestore Timestamp
      if (value.runtimeType.toString().contains('Timestamp')) {
        return (value as dynamic).toDate();
      }
      return null;
    }

    return TripInvitation(
      id: json['id'] ?? '',
      tripId: json['tripId'] ?? '',
      tripName: json['tripName'] ?? '',
      inviterUserId: json['inviterUserId'] ?? '',
      inviterName: json['inviterName'] ?? '',
      inviterEmail: json['inviterEmail'] ?? '',
      inviteeEmail: json['inviteeEmail'] ?? '',
      inviteeUserId: json['inviteeUserId'],
      status: json['status'] ?? 'pending',
      sentAt: parseDateTime(json['sentAt']) ?? DateTime.now(),
      respondedAt: parseDateTime(json['respondedAt']),
      message: json['message'],
      permissionLevel: json['permissionLevel'] ?? 'editor',
    );
  }

  /// Converts the invitation to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tripId': tripId,
      'tripName': tripName,
      'inviterUserId': inviterUserId,
      'inviterName': inviterName,
      'inviterEmail': inviterEmail,
      'inviteeEmail': inviteeEmail,
      'inviteeUserId': inviteeUserId,
      'status': status,
      'sentAt': sentAt.millisecondsSinceEpoch,
      'respondedAt': respondedAt?.millisecondsSinceEpoch,
      'message': message,
      'permissionLevel': permissionLevel,
    };
  }

  /// Creates a copy of the invitation with modified fields.
  TripInvitation copyWith({
    String? id,
    String? tripId,
    String? tripName,
    String? inviterUserId,
    String? inviterName,
    String? inviterEmail,
    String? inviteeEmail,
    String? inviteeUserId,
    String? status,
    DateTime? sentAt,
    DateTime? respondedAt,
    String? message,
    String? permissionLevel,
  }) {
    return TripInvitation(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      tripName: tripName ?? this.tripName,
      inviterUserId: inviterUserId ?? this.inviterUserId,
      inviterName: inviterName ?? this.inviterName,
      inviterEmail: inviterEmail ?? this.inviterEmail,
      inviteeEmail: inviteeEmail ?? this.inviteeEmail,
      inviteeUserId: inviteeUserId ?? this.inviteeUserId,
      status: status ?? this.status,
      sentAt: sentAt ?? this.sentAt,
      respondedAt: respondedAt ?? this.respondedAt,
      message: message ?? this.message,
      permissionLevel: permissionLevel ?? this.permissionLevel,
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isDeclined => status == 'declined';
  bool get isEditor => permissionLevel == 'editor';
  bool get isViewer => permissionLevel == 'viewer';
}

/// Edit Request model for requesting editor access to a shared trip.
class EditRequest {
  final String id;
  final String tripId;
  final String requesterId;
  final String requesterName;
  final String requesterEmail;
  final String ownerId;
  final EditRequestStatus status;
  final DateTime requestedAt;
  final DateTime? respondedAt;
  final String? respondedBy;
  final String? message;
  final String? tripTitle;

  const EditRequest({
    required this.id,
    required this.tripId,
    required this.requesterId,
    required this.requesterName,
    required this.requesterEmail,
    required this.ownerId,
    this.status = EditRequestStatus.pending,
    required this.requestedAt,
    this.respondedAt,
    this.respondedBy,
    this.message,
    this.tripTitle,
  });

  /// Creates an [EditRequest] from a JSON map.
  factory EditRequest.fromJson(Map<String, dynamic> json) {
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) return DateTime.parse(value);
      if (value.runtimeType.toString().contains('Timestamp')) {
        return (value as dynamic).toDate();
      }
      return DateTime.now();
    }

    return EditRequest(
      id: json['id'] ?? '',
      tripId: json['trip_id'] ?? json['tripId'] ?? '',
      requesterId: json['requester_id'] ?? json['requesterId'] ?? '',
      requesterName: json['requester_name'] ?? json['requesterName'] ?? '',
      requesterEmail: json['requester_email'] ?? json['requesterEmail'] ?? '',
      ownerId: json['owner_id'] ?? json['ownerId'] ?? '',
      status: EditRequestStatus.fromJson(json['status'] ?? 'pending'),
      requestedAt: parseDateTime(json['requested_at'] ?? json['requestedAt']),
      respondedAt: json['responded_at'] != null || json['respondedAt'] != null
          ? parseDateTime(json['responded_at'] ?? json['respondedAt'])
          : null,
      respondedBy: json['responded_by'] ?? json['respondedBy'],
      message: json['message'],
      tripTitle: json['trip_title'] ?? json['tripTitle'],
    );
  }

  /// Converts the edit request to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'requester_id': requesterId,
      'requester_name': requesterName,
      'requester_email': requesterEmail,
      'owner_id': ownerId,
      'status': status.toJson(),
      'requested_at': requestedAt.toIso8601String(),
      'responded_at': respondedAt?.toIso8601String(),
      'responded_by': respondedBy,
      'message': message,
      'trip_title': tripTitle,
    };
  }

  /// Creates a copy of the edit request with modified fields.
  EditRequest copyWith({
    String? id,
    String? tripId,
    String? requesterId,
    String? requesterName,
    String? requesterEmail,
    String? ownerId,
    EditRequestStatus? status,
    DateTime? requestedAt,
    DateTime? respondedAt,
    String? respondedBy,
    String? message,
    String? tripTitle,
  }) {
    return EditRequest(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      requesterEmail: requesterEmail ?? this.requesterEmail,
      ownerId: ownerId ?? this.ownerId,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      respondedAt: respondedAt ?? this.respondedAt,
      respondedBy: respondedBy ?? this.respondedBy,
      message: message ?? this.message,
      tripTitle: tripTitle ?? this.tripTitle,
    );
  }

  bool get isPending => status == EditRequestStatus.pending;
  bool get isApproved => status == EditRequestStatus.approved;
  bool get isRejected => status == EditRequestStatus.rejected;
}

/// Model for requesting permission to perform specific changes (add/edit/delete) on an activity.
class ActivityEditRequest {
  final String id;
  final String tripId;
  final String requesterId;
  final String requesterName;
  final String requesterEmail;
  final String ownerId;

  /// Type of change: 'edit_activity', 'add_activity', 'delete_activity'.
  final String requestType;

  /// ID of the activity involved (null for 'add_activity').
  final String? activityId;

  /// Map containing the modified activity data.
  final Map<String, dynamic>? proposedChanges;
  final ActivityEditRequestStatus status;
  final DateTime requestedAt;
  final DateTime? respondedAt;
  final String? respondedBy;
  final String? message;
  final String? tripTitle;

  /// Display name of the associated activity.
  final String? activityTitle;

  const ActivityEditRequest({
    required this.id,
    required this.tripId,
    required this.requesterId,
    required this.requesterName,
    required this.requesterEmail,
    required this.ownerId,
    required this.requestType,
    this.activityId,
    this.proposedChanges,
    this.status = ActivityEditRequestStatus.pending,
    required this.requestedAt,
    this.respondedAt,
    this.respondedBy,
    this.message,
    this.tripTitle,
    this.activityTitle,
  });

  /// Creates an [ActivityEditRequest] from a JSON map.
  factory ActivityEditRequest.fromJson(Map<String, dynamic> json) {
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) return DateTime.parse(value);
      if (value.runtimeType.toString().contains('Timestamp')) {
        return (value as dynamic).toDate();
      }
      return DateTime.now();
    }

    return ActivityEditRequest(
      id: json['id'] ?? '',
      tripId: json['trip_id'] ?? json['tripId'] ?? '',
      requesterId: json['requester_id'] ?? json['requesterId'] ?? '',
      requesterName: json['requester_name'] ?? json['requesterName'] ?? '',
      requesterEmail: json['requester_email'] ?? json['requesterEmail'] ?? '',
      ownerId: json['owner_id'] ?? json['ownerId'] ?? '',
      requestType:
          json['request_type'] ?? json['requestType'] ?? 'edit_activity',
      activityId: json['activity_id'] ?? json['activityId'],
      proposedChanges:
          json['proposed_changes'] ??
          json['proposedChanges'] as Map<String, dynamic>?,
      status: ActivityEditRequestStatus.fromJson(json['status'] ?? 'pending'),
      requestedAt: parseDateTime(json['requested_at'] ?? json['requestedAt']),
      respondedAt: json['responded_at'] != null || json['respondedAt'] != null
          ? parseDateTime(json['responded_at'] ?? json['respondedAt'])
          : null,
      respondedBy: json['responded_by'] ?? json['respondedBy'],
      message: json['message'],
      tripTitle: json['trip_title'] ?? json['tripTitle'],
      activityTitle: json['activity_title'] ?? json['activityTitle'],
    );
  }

  /// Converts the activity edit request to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'requester_id': requesterId,
      'requester_name': requesterName,
      'requester_email': requesterEmail,
      'owner_id': ownerId,
      'request_type': requestType,
      'activity_id': activityId,
      'proposed_changes': proposedChanges,
      'status': status.toJson(),
      'requested_at': requestedAt.toIso8601String(),
      'responded_at': respondedAt?.toIso8601String(),
      'responded_by': respondedBy,
      'message': message,
      'trip_title': tripTitle,
      'activity_title': activityTitle,
    };
  }

  /// Creates a copy of the activity edit request with modified fields.
  ActivityEditRequest copyWith({
    String? id,
    String? tripId,
    String? requesterId,
    String? requesterName,
    String? requesterEmail,
    String? ownerId,
    String? requestType,
    String? activityId,
    Map<String, dynamic>? proposedChanges,
    ActivityEditRequestStatus? status,
    DateTime? requestedAt,
    DateTime? respondedAt,
    String? respondedBy,
    String? message,
    String? tripTitle,
    String? activityTitle,
  }) {
    return ActivityEditRequest(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      requesterEmail: requesterEmail ?? this.requesterEmail,
      ownerId: ownerId ?? this.ownerId,
      requestType: requestType ?? this.requestType,
      activityId: activityId ?? this.activityId,
      proposedChanges: proposedChanges ?? this.proposedChanges,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      respondedAt: respondedAt ?? this.respondedAt,
      respondedBy: respondedBy ?? this.respondedBy,
      message: message ?? this.message,
      tripTitle: tripTitle ?? this.tripTitle,
      activityTitle: activityTitle ?? this.activityTitle,
    );
  }

  bool get isPending => status == ActivityEditRequestStatus.pending;
  bool get isApproved => status == ActivityEditRequestStatus.approved;
  bool get isRejected => status == ActivityEditRequestStatus.rejected;

  /// User-friendly name for the request type.
  String get requestTypeDisplay {
    switch (requestType) {
      case 'edit_activity':
        return 'Edit Activity';
      case 'add_activity':
        return 'Add Activity';
      case 'delete_activity':
        return 'Delete Activity';
      default:
        return 'Activity Change';
    }
  }
}

/// Enumeration for activity edit request status.
enum ActivityEditRequestStatus {
  pending,
  approved,
  rejected;

  /// Used for JSON serialization.
  String toJson() => name;

  /// Converts string to [ActivityEditRequestStatus].
  static ActivityEditRequestStatus fromJson(String json) {
    return ActivityEditRequestStatus.values.firstWhere(
      (e) => e.name == json,
      orElse: () => ActivityEditRequestStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case ActivityEditRequestStatus.pending:
        return 'Pending';
      case ActivityEditRequestStatus.approved:
        return 'Approved';
      case ActivityEditRequestStatus.rejected:
        return 'Rejected';
    }
  }

  String get icon {
    switch (this) {
      case ActivityEditRequestStatus.pending:
        return '⏳';
      case ActivityEditRequestStatus.approved:
        return '✅';
      case ActivityEditRequestStatus.rejected:
        return '❌';
    }
  }
}

/// Enumeration for edit access request status.
enum EditRequestStatus {
  pending,
  approved,
  rejected;

  /// Used for JSON serialization.
  String toJson() => name;

  /// Converts string to [EditRequestStatus].
  static EditRequestStatus fromJson(String json) {
    return EditRequestStatus.values.firstWhere(
      (e) => e.name == json,
      orElse: () => EditRequestStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case EditRequestStatus.pending:
        return 'Pending';
      case EditRequestStatus.approved:
        return 'Approved';
      case EditRequestStatus.rejected:
        return 'Rejected';
    }
  }

  String get icon {
    switch (this) {
      case EditRequestStatus.pending:
        return '⏳';
      case EditRequestStatus.approved:
        return '✅';
      case EditRequestStatus.rejected:
        return '❌';
    }
  }
}
