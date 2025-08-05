import 'group_member.dart';

class Group {
  final int id;
  final String name;
  final String currency;
  final String? description;
  final int createdBy;
  final List<GroupMember> members;
  final int? memberCountFromApi; // Member count from API when members list is not populated
  final DateTime lastUsed;
  final DateTime createdAt;
  final DateTime updatedAt;

  Group({
    required this.id,
    required this.name,
    required this.currency,
    this.description,
    required this.createdBy,
    required this.members,
    this.memberCountFromApi,
    required this.lastUsed,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    // Parse members if available, otherwise create empty list
    List<GroupMember> members = [];
    if (json['members'] != null) {
      members = (json['members'] as List<dynamic>)
          .map((memberJson) => GroupMember.fromJson(memberJson, groupId: int.tryParse(json['id']?.toString() ?? '0') ?? 0))
          .toList();
    }
    
    // Get member count from API if provided (for cases where members list is not populated)
    int? memberCountFromApi;
    if (json['member_count'] != null) {
      memberCountFromApi = int.tryParse(json['member_count'].toString());
    }
    
    return Group(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      currency: json['currency']?.toString() ?? 'USD',
      description: json['description']?.toString(),
      createdBy: int.tryParse(json['created_by']?.toString() ?? '0') ?? 0,
      members: members,
      memberCountFromApi: memberCountFromApi,
      lastUsed: DateTime.tryParse(json['last_used']?.toString() ?? json['updated_at']?.toString() ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'currency': currency,
      'description': description,
      'created_by': createdBy,
      'members': members.map((member) => member.toJson()).toList(),
      'member_count': memberCountFromApi,
      'last_used': lastUsed.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Validation methods for data integrity
  bool isValid() {
    return id > 0 && 
           name.isNotEmpty && 
           currency.isNotEmpty &&
           createdBy > 0 &&
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
  // Use memberCountFromApi if available and members list is empty, otherwise use members.length
  int get memberCount => memberCountFromApi ?? members.length;

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

  // Helper method to check if user is admin
  bool isUserAdmin(int userId) {
    return members.any((member) => 
      member.userId == userId && member.role == 'admin');
  }

  // Helper method to get admin members
  List<GroupMember> get adminMembers {
    return members.where((member) => member.role == 'admin').toList();
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
    return 'Group(id: $id, name: $name, currency: $currency, memberCount: $memberCount)';
  }
}