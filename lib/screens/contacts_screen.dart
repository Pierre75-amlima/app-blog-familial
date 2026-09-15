import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:familly_blog/models/user_model.dart';
import 'package:familly_blog/models/chat_model.dart';
import 'package:familly_blog/models/conversation_model.dart';
import 'package:familly_blog/screens/chat_screen.dart';

class ContactsScreen extends StatefulWidget {
  final List<UserModel> members;
  final UserModel currentUser;

  const ContactsScreen({
    super.key,
    required this.members,
    required this.currentUser,
  });

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _supabase = Supabase.instance.client;

  // Stream qui écoute tous les messages de la table chats en temps réel
  Stream<List<ChatModel>> get _allChatsStream {
    return _supabase
        .from('chats')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => ChatModel.fromJson(json)).toList());
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(messageDay).inDays;

    final hour =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    if (diff == 0) return hour;
    if (diff == 1) return 'Hier';
    if (diff < 7) {
      const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      return days[date.weekday - 1];
    }
    return '${date.day}/${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    final myId = widget.currentUser.id;
    final otherMembers = widget.members.where((m) => m.id != myId).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: const Color(0xFF245225),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<ChatModel>>(
        stream: _allChatsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          final allChats = snapshot.data ?? [];

          // Construire la liste des conversations
          final List<ConversationModel> conversations = [];

          for (final member in otherMembers) {
            final messagesWithMember = allChats.where((c) =>
                (c.senderId == myId && c.receiverId == member.id) ||
                (c.senderId == member.id && c.receiverId == myId)).toList();

            String? lastMsg;
            DateTime? lastTime;
            bool isMine = false;
            int unread = 0;

            if (messagesWithMember.isNotEmpty) {
              final last = messagesWithMember.first; // trié DESC
              lastMsg = last.message;
              lastTime = last.createdAt;
              isMine = last.senderId == myId;

              // Compter les messages non lus
              unread = messagesWithMember
                  .where((c) =>
                      c.receiverId == myId &&
                      c.senderId == member.id &&
                      !c.isRead)
                  .length;
            }

            conversations.add(ConversationModel(
              otherUser: member,
              lastMessage: lastMsg,
              lastMessageTime: lastTime,
              unreadCount: unread,
              isLastMessageMine: isMine,
            ));
          }

          // Trier par date du dernier message (plus récent en haut)
          conversations.sort((a, b) {
            if (a.lastMessageTime == null && b.lastMessageTime == null) {
              return a.otherUser.fullname.compareTo(b.otherUser.fullname);
            }
            if (a.lastMessageTime == null) return 1;
            if (b.lastMessageTime == null) return -1;
            return b.lastMessageTime!.compareTo(a.lastMessageTime!);
          });

          if (conversations.isEmpty) {
            return const Center(child: Text('Aucun membre trouvé.'));
          }

          return ListView.separated(
            itemCount: conversations.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              indent: 76,
              color: Colors.grey[200],
            ),
            itemBuilder: (context, index) {
              final conv = conversations[index];
              final user = conv.otherUser;
              final hasUnread = conv.unreadCount > 0;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                tileColor: hasUnread
                    ? const Color(0xFF245225).withOpacity(0.05)
                    : Colors.transparent,
                leading: CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFF245225),
                  backgroundImage:
                      (user.profil != null && user.profil!.isNotEmpty)
                          ? NetworkImage(user.profil!)
                          : null,
                  child: (user.profil == null || user.profil!.isEmpty)
                      ? Text(
                          user.fullname.isNotEmpty
                              ? user.fullname[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
                title: Text(
                  user.fullname,
                  style: TextStyle(
                    fontWeight:
                        hasUnread ? FontWeight.bold : FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    conv.lastMessage == null
                        ? 'Démarrer une discussion'
                        : (conv.isLastMessageMine
                            ? 'Vous : ${conv.lastMessage}'
                            : conv.lastMessage!),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: hasUnread ? Colors.black87 : Colors.grey[600],
                      fontWeight:
                          hasUnread ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                // ─── TRAILING SANS OVERFLOW ───
                trailing: Column(
                  mainAxisSize: MainAxisSize.min, // ← RÈGLE L'OVERFLOW
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatTime(conv.lastMessageTime),
                      style: TextStyle(
                        fontSize: 12,
                        color: hasUnread
                            ? const Color(0xFF245225)
                            : Colors.grey[500],
                        fontWeight:
                            hasUnread ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (hasUnread) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF245225),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          conv.unreadCount > 99
                              ? '99+'
                              : '${conv.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        receiverId: user.id,
                        receiverName: user.fullname,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}