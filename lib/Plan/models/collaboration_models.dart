import 'trip_model.dart';
import 'activity_models.dart';

/// Collaborator model for shared trips
class Collaborator {
  final String id;
  final String userId;
  final String email;
  final String name;
  final String role; // 'owner', 'editor', or 'viewer'
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

  factory Collaborator.fromJson(Map<String, dynamic> json) {
    // Helper function to convert Firestore Timestamp/DateTime
    DateTime _parseDateTime(dynamic value) {
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
      addedAt: _parseDateTime(json['addedAt']),
      isActive: json['isActive'] ?? true,
    );
  }

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

  bool get isOwner => role == 'owner';
  bool get isEditor => role == 'editor';
  bool get isViewer => role == 'viewer';

  /// Check if user can edit the trip
  bool get canEdit => isOwner || isEditor;

  /// Check if user can only view the trip
  bool get canOnlyView => isViewer;
}

/// Shared trip model that extends regular trip with collaboration features
class SharedTripModel extends TripModel {
  final List<Collaborator> sharedCollaborators; // Renamed to avoid conflict
  final String ownerId;
  final String ownerName;
  final String ownerEmail;
  final bool isRealTimeEnabled;
  final DateTime? lastActivity;
  final String? lastActivityBy;
  final String? shareableLink; // Add shareable link
  final Map<String, dynamic>? permissions; // userId -> permission level

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

  factory SharedTripModel.fromJson(Map<String, dynamic> json) {
    final collaboratorsList = (json['sharedCollaborators'] as List?)
        ?.map((c) => Collaborator.fromJson(c))
        .toList() ?? [];

    // Helper function to convert Firestore Timestamp/DateTime
    DateTime? _parseDateTime(dynamic value) {
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
      startDate: _parseDateTime(json['startDate']) ?? DateTime.now(),
      endDate: _parseDateTime(json['endDate']) ?? DateTime.now(),
      activities: (json['activities'] as List?)
          ?.map((a) => ActivityModel.fromJson(a))
          .toList() ?? [],
      description: json['description'],
      budget: json['budget'] != null ? BudgetModel.fromJson(json['budget']) : null,
      collaborators: List<String>.from(json['collaborators'] ?? []),
      coverImage: json['coverImage'],
      createdBy: json['createdBy'],
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updatedAt']) ?? DateTime.now(),
      isActive: json['isActive'] ?? true,
      preferences: json['preferences'] as Map<String, dynamic>?,
      sharedCollaborators: collaboratorsList,
      ownerId: json['ownerId'] ?? '',
      ownerName: json['ownerName'] ?? '',
      ownerEmail: json['ownerEmail'] ?? '',
      isRealTimeEnabled: json['isRealTimeEnabled'] ?? true,
      lastActivity: _parseDateTime(json['lastActivity']),
      lastActivityBy: json['lastActivityBy'],
      shareableLink: json['shareableLink'],
      permissions: json['permissions'] as Map<String, dynamic>?,
    );
  }

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
      'sharedCollaborators': sharedCollaborators.map((c) => c.toJson()).toList(),
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

  /// Check if current user is owner
  bool isOwnerUser(String userId) => ownerId == userId;

  /// Check if user is collaborator
  bool isUserCollaborator(String userId) {
    return sharedCollaborators.any((c) => c.userId == userId && c.isActive);
  }

  /// Check if user has access to this trip
  bool hasUserAccess(String userId) {
    return isOwnerUser(userId) || isUserCollaborator(userId);
  }

  /// Get collaborator by user ID
  Collaborator? getCollaboratorByUserId(String userId) {
    try {
      return sharedCollaborators.firstWhere(
        (c) => c.userId == userId && c.isActive,
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if user can edit this trip
  bool canUserEdit(String userId) {
    if (isOwnerUser(userId)) return true;
    final collaborator = getCollaboratorByUserId(userId);
    return collaborator?.canEdit ?? false;
  }

  /// Check if user can only view this trip
  bool canUserOnlyView(String userId) {
    if (isOwnerUser(userId)) return false;
    final collaborator = getCollaboratorByUserId(userId);
    return collaborator?.canOnlyView ?? true;
  }

  /// Get all active collaborators (convenience getter)
  List<Collaborator> get activeCollaborators => sharedCollaborators.where((c) => c.isActive).toList();

  /// Get all collaborators including inactive ones (convenience getter)
  List<Collaborator> get allCollaborators => sharedCollaborators;

  /// Convert to regular TripModel
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

/// Model for invitation
class TripInvitation {
  final String id;
  final String tripId;
  final String tripName;
  final String inviterUserId;
  final String inviterName;
  final String inviterEmail;
  final String inviteeEmail;
  final String? inviteeUserId; // null if user doesn't exist yet
  final String status; // 'pending', 'accepted', 'declined'
  final DateTime sentAt;
  final DateTime? respondedAt;
  final String? message;
  final String permissionLevel; // 'editor' or 'viewer'

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
    this.permissionLevel = 'editor', // default to editor
  });

  factory TripInvitation.fromJson(Map<String, dynamic> json) {
    // Helper function to convert Firestore Timestamp/DateTime
    DateTime? _parseDateTime(dynamic value) {
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
      sentAt: _parseDateTime(json['sentAt']) ?? DateTime.now(),
      respondedAt: _parseDateTime(json['respondedAt']),
      message: json['message'],
      permissionLevel: json['permissionLevel'] ?? 'editor',
    );
  }

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

/// Edit Request model for requesting edit access
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

  factory EditRequest.fromJson(Map<String, dynamic> json) {
    DateTime _parseDateTime(dynamic value) {
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
      requestedAt: _parseDateTime(json['requested_at'] ?? json['requestedAt']),
      respondedAt: json['responded_at'] != null || json['respondedAt'] != null
          ? _parseDateTime(json['responded_at'] ?? json['respondedAt'])
          : null,
      respondedBy: json['responded_by'] ?? json['respondedBy'],
      message: json['message'],
      tripTitle: json['trip_title'] ?? json['tripTitle'],
    );
  }

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

/// Activity Edit Request model for requesting permission to edit specific activities
class ActivityEditRequest {
  final String id;
  final String tripId;
  final String requesterId;
  final String requesterName;
  final String requesterEmail;
  final String ownerId;
  final String requestType; // 'edit_activity', 'add_activity', 'delete_activity'
  final String? activityId; // ID of the activity being edited/deleted, null for add
  final Map<String, dynamic>? proposedChanges; // The proposed changes
  final ActivityEditRequestStatus status;
  final DateTime requestedAt;
  final DateTime? respondedAt;
  final String? respondedBy;
  final String? message;
  final String? tripTitle;
  final String? activityTitle; // Title of the activity for display

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

  factory ActivityEditRequest.fromJson(Map<String, dynamic> json) {
    DateTime _parseDateTime(dynamic value) {
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
      requestType: json['request_type'] ?? json['requestType'] ?? 'edit_activity',
      activityId: json['activity_id'] ?? json['activityId'],
      proposedChanges: json['proposed_changes'] ?? json['proposedChanges'] as Map<String, dynamic>?,
      status: ActivityEditRequestStatus.fromJson(json['status'] ?? 'pending'),
      requestedAt: _parseDateTime(json['requested_at'] ?? json['requestedAt']),
      respondedAt: json['responded_at'] != null || json['respondedAt'] != null
          ? _parseDateTime(json['responded_at'] ?? json['respondedAt'])
          : null,
      respondedBy: json['responded_by'] ?? json['respondedBy'],
      message: json['message'],
      tripTitle: json['trip_title'] ?? json['tripTitle'],
      activityTitle: json['activity_title'] ?? json['activityTitle'],
    );
  }

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

// Activity edit request status enum
enum ActivityEditRequestStatus {
  pending,
  approved,
  rejected;

  String toJson() => name;

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

// Edit request status enum
enum EditRequestStatus {
  pending,
  approved,
  rejected;

  String toJson() => name;

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
