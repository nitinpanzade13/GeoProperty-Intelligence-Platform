import 'package:equatable/equatable.dart';
import '../constants/defaults.dart';

class UserModel extends Equatable {
  final String userId;
  final String name;
  final String email;
  final String? avatarUrl;
  final String role;
  final List<String> savedPropertyIds;
  final String preferredMapType;
  final bool notificationsEnabled;

  const UserModel({
    required this.userId,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.role = 'Land Surveyor / Analyst',
    this.savedPropertyIds = const [],
    this.preferredMapType = 'hybrid',
    this.notificationsEnabled = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? Defaults.userRole,
      savedPropertyIds: (json['saved_property_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      preferredMapType: json['preferred_map_type'] as String? ?? 'hybrid',
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'email': email,
      'avatar_url': avatarUrl,
      'role': role,
      'saved_property_ids': savedPropertyIds,
      'preferred_map_type': preferredMapType,
      'notifications_enabled': notificationsEnabled,
    };
  }

  UserModel copyWith({
    String? userId,
    String? name,
    String? email,
    String? avatarUrl,
    String? role,
    List<String>? savedPropertyIds,
    String? preferredMapType,
    bool? notificationsEnabled,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      savedPropertyIds: savedPropertyIds ?? this.savedPropertyIds,
      preferredMapType: preferredMapType ?? this.preferredMapType,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        name,
        email,
        avatarUrl,
        role,
        savedPropertyIds,
        preferredMapType,
        notificationsEnabled,
      ];
}
