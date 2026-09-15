import 'package:familly_blog/models/user_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentModel {
  final String? id;
  final String messageId;
  final UserModel author;
  final String commentText;
  final DateTime publishedDate;

  CommentModel({
    this.id,
    required this.messageId,
    required this.author,
    required this.commentText,
    required this.publishedDate,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'],
      messageId: json['message_id'],
      author: UserModel.fromJson(json['author']),
      commentText: json['comment_text'] ?? '',
      publishedDate: DateTime.parse(json['published_date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message_id': messageId,
      'author_id': author.id,
      'comment_text': commentText,
      'published_date': publishedDate.toIso8601String(),
    };
  }

  String formateDate() {
    return timeago.format(publishedDate);
  }
}