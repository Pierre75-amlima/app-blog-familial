import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:familly_blog/models/chat_model.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _supabase = Supabase.instance.client;
  final _messageController = TextEditingController();
  late final String myUserId;

  @override
  void initState() {
    super.initState();
    myUserId = _supabase.auth.currentUser!.id;
    _markAsRead(); // Marquer comme lu à l'ouverture
  }

  /// Marquer les messages reçus comme lus
  Future<void> _markAsRead() async {
    try {
      await _supabase
          .from('chats')
          .update({'is_read': true})
          .eq('sender_id', widget.receiverId)
          .eq('receiver_id', myUserId)
          .eq('is_read', false);
    } catch (e) {
      print('Erreur mark as read: $e');
    }
  }

  Stream<List<ChatModel>> get _chatStream {
    return _supabase
        .from('chats')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map((data) {
          final all = data.map((json) => ChatModel.fromJson(json)).toList();
          return all.where((msg) =>
            (msg.senderId == myUserId && msg.receiverId == widget.receiverId) ||
            (msg.senderId == widget.receiverId && msg.receiverId == myUserId)
          ).toList();
        });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    try {
      await _supabase.from('chats').insert({
        'sender_id': myUserId,
        'receiver_id': widget.receiverId,
        'message': text,
        'is_read': false,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverName),
        backgroundColor: const Color(0xFF245225),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatModel>>(
              stream: _chatStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Erreur : ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;

                if (messages.isEmpty) {
                  return const Center(
                    child: Text('Aucun message. Dites bonjour ! 👋'),
                  );
                }

                // Quand de nouveaux messages arrivent pendant qu'on est sur l'écran
                _markAsRead();

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final chat = messages[index];
                    final isMyMessage = chat.senderId == myUserId;

                    return Align(
                      alignment: isMyMessage
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isMyMessage
                              ? const Color(0xFF245225)
                              : Colors.grey[300],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isMyMessage
                                ? const Radius.circular(16)
                                : const Radius.circular(0),
                            bottomRight: isMyMessage
                                ? const Radius.circular(0)
                                : const Radius.circular(16),
                          ),
                        ),
                        child: Text(
                          chat.message,
                          style: TextStyle(
                            fontSize: 15,
                            color: isMyMessage ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Écrire un message...',
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF245225),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}