class ChatOtherUser {
  ChatOtherUser({required this.id, required this.name, this.avatarUrl});

  factory ChatOtherUser.fromJson(Map<String, dynamic> json) => ChatOtherUser(
        id: json['id'] as String,
        name: json['name'] as String,
        avatarUrl: json['avatar_url'] as String?,
      );

  final String id;
  final String name;
  final String? avatarUrl;
}

class ChatThread {
  ChatThread({
    required this.id,
    required this.type,
    required this.title,
    this.regionLevel,
    this.regionCode,
    this.otherUser,
    this.updatedAt,
  });

  factory ChatThread.fromJson(Map<String, dynamic> json) => ChatThread(
        id: json['id'] as String,
        type: json['type'] as String,
        title: json['title'] as String,
        regionLevel: json['region_level'] as String?,
        regionCode: json['region_code'] as String?,
        otherUser: json['other_user'] != null
            ? ChatOtherUser.fromJson(json['other_user'] as Map<String, dynamic>)
            : null,
        updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
      );

  final String id;
  final String type;
  final String title;
  final String? regionLevel;
  final String? regionCode;
  final ChatOtherUser? otherUser;
  final DateTime? updatedAt;

  bool get isOfficial => type == 'official';
  bool get isGlobal => type == 'global';
  bool get isRegion => type == 'region';
  bool get isDirectMessage => type == 'dm';
}
