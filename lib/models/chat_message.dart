class ChatMessage {
  ChatMessage({
    required this.id,
    required this.threadId,
    required this.body,
    required this.isOfficial,
    this.senderId,
    this.senderName,
    this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        threadId: json['thread_id'] as String,
        senderId: json['sender_id'] as String?,
        senderName: json['sender_name'] as String?,
        isOfficial: json['is_official'] as bool? ?? false,
        body: json['body'] as String,
        createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      );

  final String id;
  final String threadId;
  final String? senderId;
  final String? senderName;
  final bool isOfficial;
  final String body;
  final DateTime? createdAt;
}
