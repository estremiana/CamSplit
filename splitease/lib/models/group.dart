import 'group_member.dart';

class Group {
  final String id;
  final String name;
  final List<GroupMember> members;
  final DateTime lastUsed;
  final DateTime createdAt;
  final DateTime updatedAt;

  Group({
    required this.id,
    required this.name,
    required this.members,
    required this.lastUsed,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'].toString(),
      name: json['name'],
      members: (json['members'] as List<dynamic>?)
          ?.map((memberJson) => GroupMember.fromJson(memberJson))
          .toList() ?? [],
      lastUsed: DateTime.parse(json['last_used']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'members': members.map((member) => member.toJson()).toList(),
      'last_used': lastUsed.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Validation methods for data integrity
  bool isValid() {
    return id.isNotEmpty && 
           name.isNotEmpty && 
           members.isNotEmpty &&
           members.every((member) => member.isValid());
  }

  bool hasValidTimestamps() {
    return createdAt.isBefore(DateTime.now()) &&
           updatedAt.isBefore(DateTime.now()) &&
           lastUsed.isBefore(DateTime.now()) &&
           !createdAt.isAfter(updatedAt);
  }

  // Helper method to get member count
  int get memberCount => members.length;

  // Helper method to check if current user is in group
  bool get hasCurrentUser => members.any((member) => member.isCurrentUser);

  // Helper method to get current user from group
  GroupMember? get currentUser {
    try {
      return members.firstWhere((member) => member.isCurrentUser);
    } catch (e) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Group && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Group(id: $id, name: $name, memberCount: $memberCount)';
  }
}