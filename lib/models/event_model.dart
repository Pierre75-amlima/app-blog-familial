import 'package:familly_blog/models/user_model.dart';

class EventModel {
  final String? id;
  final String title;
  final String? description;
  final DateTime eventDate;
  final String? location;
  final String createdBy;
  final DateTime? createdAt;
  final UserModel? author; 

  EventModel({
    this.id,
    required this.title,
    this.description,
    required this.eventDate,
    this.location,
    required this.createdBy,
    this.createdAt,
    this.author,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      eventDate: DateTime.parse(json['event_date'].toString()),
      location: json['location'] as String?,
      createdBy: json['created_by'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      author: json['author'] != null
          ? UserModel.fromJson(json['author'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'event_date': eventDate.toIso8601String(),
      'location': location,
      'created_by': createdBy,
    };
  }
}