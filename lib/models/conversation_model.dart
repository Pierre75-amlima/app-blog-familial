import 'package:familly_blog/models/user_model.dart';

class ConversationModel {
  final UserModel otherUser;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool isLastMessageMine;

  ConversationModel({
    required this.otherUser,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isLastMessageMine = false,
  });
}