/// UserModel - Represents a user in the application
/// 
/// This model includes:
/// - Basic user information (id, email, displayName)
/// - Authentication metadata
class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final DateTime? createdAt;

  /// Constructor with required and optional parameters
  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.createdAt,
  });

  /// Factory constructor to create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  /// Convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  /// Create a copy of UserModel with updated fields
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
