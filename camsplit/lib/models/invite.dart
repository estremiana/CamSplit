class Invite {
  final int id;
  final int groupId;
  final String inviteCode;
  final int createdBy;
  final DateTime? expiresAt;
  final int maxUses;
  final int currentUses;
  final bool isActive;
  final DateTime createdAt;
  final String? groupName;
  final String? groupDescription;
  final String? creatorEmail;
  final String? creatorName;
  final String? inviteUrl;

  Invite({
    required this.id,
    required this.groupId,
    required this.inviteCode,
    required this.createdBy,
    this.expiresAt,
    required this.maxUses,
    required this.currentUses,
    required this.isActive,
    required this.createdAt,
    this.groupName,
    this.groupDescription,
    this.creatorEmail,
    this.creatorName,
    this.inviteUrl,
  });

  factory Invite.fromJson(Map<String, dynamic> json) {
    return Invite(
      id: json['id'],
      groupId: json['group_id'],
      inviteCode: json['invite_code'],
      createdBy: json['created_by'],
      expiresAt: json['expires_at'] != null 
          ? DateTime.parse(json['expires_at']) 
          : null,
      maxUses: json['max_uses'] ?? 1,
      currentUses: json['current_uses'] ?? 0,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      groupName: json['group_name'],
      groupDescription: json['group_description'],
      creatorEmail: json['creator_email'],
      creatorName: json['creator_name'],
      inviteUrl: json['invite_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'invite_code': inviteCode,
      'created_by': createdBy,
      'expires_at': expiresAt?.toIso8601String(),
      'max_uses': maxUses,
      'current_uses': currentUses,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'group_name': groupName,
      'group_description': groupDescription,
      'creator_email': creatorEmail,
      'creator_name': creatorName,
      'invite_url': inviteUrl,
    };
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get isUsageLimitReached {
    return currentUses >= maxUses;
  }

  bool get isValid {
    return isActive && !isExpired && !isUsageLimitReached;
  }

  String get statusText {
    if (!isActive) return 'Inactive';
    if (isExpired) return 'Expired';
    if (isUsageLimitReached) return 'Usage limit reached';
    return 'Active';
  }
}

class AvailableMember {
  final int id;
  final String nickname;
  final String? email;
  final DateTime joinedAt;

  AvailableMember({
    required this.id,
    required this.nickname,
    this.email,
    required this.joinedAt,
  });

  factory AvailableMember.fromJson(Map<String, dynamic> json) {
    return AvailableMember(
      id: json['id'],
      nickname: json['nickname'],
      email: json['email'],
      joinedAt: DateTime.parse(json['joined_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'email': email,
      'joined_at': joinedAt.toIso8601String(),
    };
  }
}

class InviteDetails {
  final Invite invite;
  final bool isValid;
  final String groupName;
  final String? groupDescription;

  InviteDetails({
    required this.invite,
    required this.isValid,
    required this.groupName,
    this.groupDescription,
  });

  factory InviteDetails.fromJson(Map<String, dynamic> json) {
    return InviteDetails(
      invite: Invite.fromJson(json['invite']),
      isValid: json['isValid'] ?? false,
      groupName: json['groupName'] ?? '',
      groupDescription: json['groupDescription'],
    );
  }
} 