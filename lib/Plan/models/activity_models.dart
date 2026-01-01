/// Activity Type enum matching backend ActivityType.
///
/// Represents the category of an activity, such as flight, lodging, or restaurant.
enum ActivityType {
  flight('flight'),
  activity('activity'),
  lodging('lodging'),
  carRental('car_rental'),
  concert('concert'),
  cruising('cruising'),
  direction('direction'),
  ferry('ferry'),
  groundTransportation('ground_transportation'),
  map('map'),
  meeting('meeting'),
  note('note'),
  parking('parking'),
  rail('rail'),
  restaurant('restaurant'),
  theater('theater'),
  tour('tour'),
  transportation('transportation');

  const ActivityType(this.value);

  /// String value used for serialization.
  final String value;

  /// Converts a string to an [ActivityType].
  ///
  /// Defaults to [ActivityType.activity] if the string doesn't match.
  static ActivityType fromString(String value) {
    return ActivityType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ActivityType.activity,
    );
  }
}

/// Activity Status enum matching backend ActivityStatus.
///
/// Represents the current lifecycle state of an activity.
enum ActivityStatus {
  planned('planned'),
  confirmed('confirmed'),
  inProgress('in_progress'),
  completed('completed'),
  cancelled('cancelled');

  const ActivityStatus(this.value);

  /// String value used for serialization.
  final String value;

  /// Converts a string to an [ActivityStatus].
  ///
  /// Defaults to [ActivityStatus.planned] if the string doesn't match.
  static ActivityStatus fromString(String value) {
    return ActivityStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ActivityStatus.planned,
    );
  }
}

/// Priority enum matching backend Priority.
///
/// Represents the importance of an activity.
enum Priority {
  low('low'),
  medium('medium'),
  high('high'),
  urgent('urgent');

  const Priority(this.value);

  /// String value used for serialization.
  final String value;

  /// Converts a string to a [Priority].
  ///
  /// Defaults to [Priority.medium] if the string doesn't match.
  static Priority fromString(String value) {
    return Priority.values.firstWhere(
      (e) => e.value == value,
      orElse: () => Priority.medium,
    );
  }
}

/// Location model matching backend Location schema.
///
/// Stores geographical and address information for an activity.
class LocationModel {
  final String name;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? city;
  final String? country;
  final String? postalCode;

  LocationModel({
    required this.name,
    this.address,
    this.latitude,
    this.longitude,
    this.city,
    this.country,
    this.postalCode,
  });

  /// Converts the model to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'country': country,
      'postal_code': postalCode,
    };
  }

  /// Creates a model from a JSON map.
  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      name: json['name'] ?? '',
      address: json['address'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      city: json['city'],
      country: json['country'],
      postalCode: json['postal_code'],
    );
  }
}

/// Budget model matching backend Budget schema.
///
/// Tracks estimated and actual costs for an activity or trip.
class BudgetModel {
  final double estimatedCost;
  final double? actualCost;
  final String currency;
  final String? category;

  BudgetModel({
    required this.estimatedCost,
    this.actualCost,
    this.currency = 'VND',
    this.category,
  });

  /// Get remaining budget (estimated - actual).
  double get remainingBudget => estimatedCost - (actualCost ?? 0);

  /// Get budget usage percentage (0-100).
  double get usagePercentage {
    if (estimatedCost <= 0) return 0.0;
    return ((actualCost ?? 0) / estimatedCost * 100).clamp(0.0, 100.0);
  }

  /// Check if the actual cost exceeds the estimated cost.
  bool get isOverBudget => (actualCost ?? 0) > estimatedCost;

  /// Get descriptive budget status (e.g., 'Critical', 'On Track').
  String get budgetStatus {
    final percentage = usagePercentage;
    if (isOverBudget) return 'Over Budget';
    if (percentage >= 90) return 'Critical';
    if (percentage >= 75) return 'Warning';
    if (percentage >= 50) return 'On Track';
    return 'Under Budget';
  }

  /// Creates a copy of the budget with a new actual cost.
  BudgetModel copyWithActualCost(double newActualCost) {
    return BudgetModel(
      estimatedCost: estimatedCost,
      actualCost: newActualCost,
      currency: currency,
      category: category,
    );
  }

  /// Converts the model to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'estimated_cost': estimatedCost,
      'actual_cost': actualCost,
      'currency': currency,
      'category': category,
    };
  }

  /// Creates a model from a JSON map.
  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      estimatedCost: (json['estimated_cost'] ?? 0).toDouble(),
      actualCost: json['actual_cost']?.toDouble(),
      currency: json['currency'] ?? 'VND',
      category: json['category'],
    );
  }
}

/// Contact model matching backend Contact schema.
///
/// Stores contact information for a venue or service provider.
class ContactModel {
  final String? name;
  final String? phone;
  final String? email;
  final String? website;

  ContactModel({this.name, this.phone, this.email, this.website});

  /// Converts the model to a JSON map.
  Map<String, dynamic> toJson() {
    return {'name': name, 'phone': phone, 'email': email, 'website': website};
  }

  /// Creates a model from a JSON map.
  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      website: json['website'],
    );
  }
}

/// Expense integration information for an activity.
class ExpenseInfo {
  /// ID of the linked expense document.
  final String? expenseId;

  /// Whether this activity has an associated expense.
  final bool hasExpense;

  /// Category name used in the expense module.
  final String? expenseCategory;

  /// Whether the expense was automatically created from the activity.
  final bool autoSynced;

  /// Whether the synchronization with the expense module was successful.
  final bool expenseSynced;

  ExpenseInfo({
    this.expenseId,
    this.hasExpense = false,
    this.expenseCategory,
    this.autoSynced = false,
    this.expenseSynced = false,
  });

  /// Converts the model to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'expense_id': expenseId,
      'has_expense': hasExpense,
      'expense_category': expenseCategory,
      'auto_synced': autoSynced,
      'expense_synced': expenseSynced,
    };
  }

  /// Creates a model from a JSON map.
  factory ExpenseInfo.fromJson(Map<String, dynamic> json) {
    return ExpenseInfo(
      expenseId: json['expense_id'],
      hasExpense: json['has_expense'] ?? false,
      expenseCategory: json['expense_category'],
      autoSynced: json['auto_synced'] ?? false,
      expenseSynced: json['expense_synced'] ?? false,
    );
  }

  /// Creates a copy of the info with modified fields.
  ExpenseInfo copyWith({
    String? expenseId,
    bool? hasExpense,
    String? expenseCategory,
    bool? autoSynced,
    bool? expenseSynced,
  }) {
    return ExpenseInfo(
      expenseId: expenseId ?? this.expenseId,
      hasExpense: hasExpense ?? this.hasExpense,
      expenseCategory: expenseCategory ?? this.expenseCategory,
      autoSynced: autoSynced ?? this.autoSynced,
      expenseSynced: expenseSynced ?? this.expenseSynced,
    );
  }
}

/// Core Activity model matching backend Activity schema.
///
/// Represents an individual item in a trip itinerary, with timing, location,
/// budget, and status tracking.
class ActivityModel {
  final String? id;
  final String title;
  final String? description;
  final ActivityType activityType;
  final ActivityStatus status;
  final Priority priority;
  final DateTime? startDate;
  final DateTime? endDate;

  /// Estimated duration of the activity in minutes.
  final int? durationMinutes;
  final LocationModel? location;
  final BudgetModel? budget;
  final ContactModel? contact;
  final String? notes;
  final List<String> tags;
  final List<String> attachments;
  final String? tripId;

  /// Whether the user has checked in to this activity.
  final bool checkIn;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Integration data for the Expense module.
  final ExpenseInfo expenseInfo;

  ActivityModel({
    this.id,
    required this.title,
    this.description,
    required this.activityType,
    this.status = ActivityStatus.planned,
    this.priority = Priority.medium,
    this.startDate,
    this.endDate,
    this.durationMinutes,
    this.location,
    this.budget,
    this.contact,
    this.notes,
    this.tags = const [],
    this.attachments = const [],
    this.tripId,
    this.checkIn = false,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    ExpenseInfo? expenseInfo,
  }) : expenseInfo = expenseInfo ?? ExpenseInfo();

  /// Converts the model to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'activity_type': activityType.value,
      'status': status.value,
      'priority': priority.value,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'duration_minutes': durationMinutes,
      'location': location?.toJson(),
      'budget': budget?.toJson(),
      'contact': contact?.toJson(),
      'notes': notes,
      'tags': tags,
      'attachments': attachments,
      'trip_id': tripId,
      'check_in': checkIn,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'expense_info': expenseInfo.toJson(),
    };
  }

  /// Creates a model from a JSON map.
  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'],
      activityType: ActivityType.fromString(
        json['activity_type'] ?? json['activityType'] ?? 'activity',
      ),
      status: ActivityStatus.fromString(json['status'] ?? 'planned'),
      priority: Priority.fromString(json['priority'] ?? 'medium'),
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : json['endDate'] != null
          ? DateTime.parse(json['endDate'])
          : null,
      durationMinutes: json['duration_minutes'],
      location: json['location'] != null
          ? LocationModel.fromJson(json['location'])
          : null,
      budget: json['budget'] != null
          ? BudgetModel.fromJson(json['budget'])
          : null,
      contact: json['contact'] != null
          ? ContactModel.fromJson(json['contact'])
          : null,
      notes: json['notes'],
      tags: List<String>.from(json['tags'] ?? []),
      attachments: List<String>.from(json['attachments'] ?? []),
      tripId: json['trip_id'] ?? json['tripId'],
      checkIn: json['check_in'] ?? json['checkIn'] ?? false,
      createdBy: json['created_by'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      expenseInfo: json['expense_info'] != null
          ? ExpenseInfo.fromJson(json['expense_info'])
          : ExpenseInfo(),
    );
  }

  /// Creates a copy of the activity with modified fields.
  ActivityModel copyWith({
    String? id,
    String? title,
    String? description,
    ActivityType? activityType,
    ActivityStatus? status,
    Priority? priority,
    DateTime? startDate,
    DateTime? endDate,
    int? durationMinutes,
    LocationModel? location,
    BudgetModel? budget,
    ContactModel? contact,
    String? notes,
    List<String>? tags,
    List<String>? attachments,
    String? tripId,
    bool? checkIn,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    ExpenseInfo? expenseInfo,
  }) {
    return ActivityModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      activityType: activityType ?? this.activityType,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      location: location ?? this.location,
      budget: budget ?? this.budget,
      contact: contact ?? this.contact,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      attachments: attachments ?? this.attachments,
      tripId: tripId ?? this.tripId,
      checkIn: checkIn ?? this.checkIn,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expenseInfo: expenseInfo ?? this.expenseInfo,
    );
  }
}
