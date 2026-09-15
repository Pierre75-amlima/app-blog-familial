class ChatModel {
  final String? id;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime? createdAt;
  final bool isRead;

  ChatModel({
    this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    this.createdAt,
    this.isRead = false,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id']?.toString(),
      senderId: json['sender_id']?.toString() ?? '',
      receiverId: json['receiver_id']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      isRead: json['is_read'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'is_read': isRead,
    };
  }
}