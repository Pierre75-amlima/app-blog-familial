import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:familly_blog/models/event_model.dart';
import 'package:familly_blog/models/user_model.dart';
import 'package:familly_blog/screens/add_event_screen.dart';

class EventsScreen extends StatefulWidget {
  final UserModel currentUser;

  const EventsScreen({super.key, required this.currentUser});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  List<EventModel> _events = [];

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    setState(() => _isLoading = true);
    try {
      final res = await _supabase
          .from('events')
          .select('*, author:users(*)')
          .order('event_date', ascending: true);

      final list = (res as List).map((e) => EventModel.fromJson(e)).toList();

      if (mounted) {
        setState(() {
          _events = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Événements Familiaux'),
        backgroundColor: const Color(0xFF245225),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchEvents,
              child: _events.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucun événement prévu pour le moment. 🎈',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _events.length,
                      itemBuilder: (context, index) {
                        final event = _events[index];
                        final isPast = event.eventDate.isBefore(DateTime.now());

                        final day = event.eventDate.day.toString().padLeft(2, '0');
                        final month = _getMonthName(event.eventDate.month);
                        final year = event.eventDate.year;
                        final time =
                            '${event.eventDate.hour}h${event.eventDate.minute.toString().padLeft(2, '0')}';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // BLOC DATE (Gaucher)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isPast
                                        ? Colors.grey[400]
                                        : const Color(0xFF245225),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        day,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        month,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // DÉTAILS DE L'ÉVÉNEMENT
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event.title,
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          decoration: isPast
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time,
                                              size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$year à $time',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (event.location != null &&
                                          event.location!.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on,
                                                size: 14, color: Colors.redAccent),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                event.location!,
                                                style: const TextStyle(
                                                  color: Colors.black87,
                                                  fontSize: 12,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (event.description != null &&
                                          event.description!.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          event.description!,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      // Organisateur
                                      if (event.author != null)
                                        Text(
                                          'Créé par : ${event.author!.fullname}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF245225),
        foregroundColor: Colors.white,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEventScreen(currentUser: widget.currentUser),
            ),
          );
          if (result == true) {
            _fetchEvents();
          }
        },
        child: const Icon(Icons.add_location_alt),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'JAN', 'FÉV', 'MAR', 'AVR', 'MAI', 'JUIN',
      'JUIL', 'AOÛT', 'SEP', 'OCT', 'NOV', 'DÉC'
    ];
    return months[month - 1];
  }
}