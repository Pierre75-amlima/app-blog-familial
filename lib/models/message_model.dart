import 'package:timeago/timeago.dart' as timeago;
import 'user_model.dart';

class MessageModel {
  final String? id;
  final UserModel author;
  final String? messageText;
  final List<String> messageImages;
  final List<String> messageVideos;
  final DateTime publishedDate;

  MessageModel({
    this.id,
    required this.author,
    this.messageText,
    this.messageImages = const [],
    this.messageVideos = const [],
    required this.publishedDate,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      author: UserModel.fromJson(json['author']),
      messageText: json['message_text'],
      messageImages: json['message_image'] != null
          ? List<String>.from(json['message_image'])
          : [],
      messageVideos: json['message_videos'] != null
          ? List<String>.from(json['message_videos'])
          : [],
      publishedDate: DateTime.parse(json['published_date']),
    );
  }

  String formateDate() {
    return timeago.format(publishedDate);
  }

  Map<String, dynamic> toJson() {
    return {
      'author_id': author.id,
      'message_text': messageText,
      'message_image': messageImages,
      'message_movie': messageVideos,
      'published_date': publishedDate.toIso8601String(),
    };
  }

  MessageModel copyWith({
    String? id,
    UserModel? author,
    String? messageText,
    List<String>? messageImages,
    List<String>? messageVideos,
    DateTime? publishedDate,
  }) {
    return MessageModel(
      id: id ?? this.id,
      author: author ?? this.author,
      messageText: messageText ?? this.messageText,
      messageImages: messageImages ?? this.messageImages,
      messageVideos: messageVideos ?? this.messageVideos,
      publishedDate: publishedDate ?? this.publishedDate,
    );
  }
}
