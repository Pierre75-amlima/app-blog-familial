import 'package:familly_blog/models/message_model.dart';
import 'package:familly_blog/models/user_model.dart';
import 'package:familly_blog/screens/widgets/message_card.dart';
import 'package:flutter/material.dart';

class MessageList extends StatelessWidget {
  final List<MessageModel> messages;
  final UserModel currentUser;

  const MessageList({
    super.key,
    required this.messages,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Text(
            "Aucun message pour le moment.",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return MessageCard(
          message: messages[index],
          currentUser: currentUser, 
        );
      },
    );
  }
}