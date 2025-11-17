/// TaskModel - Represents a TODO task with all necessary fields
/// 
/// This model includes:
/// - Basic task information (id, title, description, dueDate)
/// - Ownership and sharing data (ownerId, sharedUserIds)
/// - Timestamps for tracking (createdAt, updatedAt)
/// - Completion status (isCompleted)
class TaskModel {
  final String id;
  final String title;
  final String description;
  final DateTime? dueDate;
  final String ownerId;
  final List<String> sharedUserIds;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Constructor with all required and optional parameters
  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    this.dueDate,
    required this.ownerId,
    required this.sharedUserIds,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory constructor to create TaskModel from GraphQL JSON response
  /// Handles null safety and type conversions
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      dueDate: json['due_date'] != null 
          ? DateTime.parse(json['due_date'] as String) 
          : null,
      ownerId: json['owner_id'] as String,
      sharedUserIds: (json['shared_user_ids'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      isCompleted: json['is_completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert TaskModel to JSON for GraphQL mutations
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'due_date': dueDate?.toIso8601String(),
      'owner_id': ownerId,
      'shared_user_ids': sharedUserIds,
      'is_completed': isCompleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of TaskModel with updated fields
  /// Useful for state management and updates
  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    String? ownerId,
    List<String>? sharedUserIds,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      ownerId: ownerId ?? this.ownerId,
      sharedUserIds: sharedUserIds ?? this.sharedUserIds,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
