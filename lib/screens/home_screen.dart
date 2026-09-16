import 'package:familly_blog/models/message_model.dart';
import 'package:familly_blog/models/user_model.dart';
import 'package:familly_blog/screens/add_post_screen.dart';
import 'package:familly_blog/screens/edit_profile_screen.dart';
import 'package:familly_blog/screens/login_screen.dart';
import 'package:familly_blog/screens/widgets/family_card.dart';
import 'package:familly_blog/screens/widgets/message_list.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:familly_blog/screens/chat_screen.dart';
import 'package:familly_blog/screens/contacts_screen.dart';
import 'package:familly_blog/screens/events_screen.dart';
import 'package:familly_blog/services/push_service.dart';
import 'package:timeago/timeago.dart' as timeago;

final _supabase = Supabase.instance.client;
const String _isLoggedInKey = 'is_logged_in';

Future<void> _saveSessionState(bool isLoggedIn) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_isLoggedInKey, isLoggedIn);
}

class HomePage extends StatefulWidget {
  final UserModel currentUser;

  const HomePage({super.key, required this.currentUser});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late UserModel _currentUser; // Utilisateur local dynamique
  var _isLoading = false;
  List<MessageModel> _message = [];
  List<UserModel> _members = [];
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.currentUser;
    _getMessage();
    _loadUnreadCount();
  }

  Future<void> _getMessage() async {
    try {
      setState(() => _isLoading = true);
      final res = await _supabase
          .from('messages')
          .select('''*, author:users(*)''')
          .order('published_date', ascending: false);

      final messagesList = (res as List)
          .map((e) => MessageModel.fromJson(e))
          .toList();

      final usersRes = await _supabase
          .from('users')
          .select('id, fullname, email, profil');

      final membersList = usersRes
          .map((json) => UserModel.fromJson(json))
          .toList();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _message = messagesList;
          _members = membersList;
        });
      }
      _loadUnreadCount();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        print('Une erreur est survenue : $e');
      }
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final rows = await _supabase
          .from('notifications')
          .select('id, read_at')
          .eq('user_id', _currentUser.id)
          .order('created_at', ascending: false)
          .limit(200);
      if (mounted) {
        setState(() =>
            _unreadCount = rows.where((r) => r['read_at'] == null).length);
      }
    } catch (_) {
      // Table "notifications" pas encore créée ? On ne bloque pas l'app.
    }
  }

  Future<void> _showNotificationsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => _NotificationsSheet(
        supabase: _supabase,
        currentUser: _currentUser,
        onClosed: _loadUnreadCount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Color.fromARGB(255, 36, 82, 37),
              child: Icon(Icons.auto_stories, color: Colors.white),
            ),
            SizedBox(width: 10),
            Text(
              'Family Blog',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.black,
                ),
                onPressed: _showNotificationsSheet,
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minHeight: 16,
                      minWidth: 16,
                    ),
                    child: Text(
                      _unreadCount > 99 ? '99+' : '$_unreadCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),

      // ─── DRAWER AVEC PHOTO DYNAMIQUE ET ÉDITION ───
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 60,
                left: 16,
                right: 16,
                bottom: 24,
              ),
              color: const Color(0xFF245225),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        (_currentUser.profil != null &&
                            _currentUser.profil!.isNotEmpty)
                        ? NetworkImage(_currentUser.profil!)
                        : null,
                    child:
                        (_currentUser.profil == null ||
                            _currentUser.profil!.isEmpty)
                        ? Text(
                            _currentUser.fullname.isNotEmpty
                                ? _currentUser.fullname[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF245225),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentUser.fullname,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentUser.email,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // BOUTON MODIFIER LE PROFIL (DYNAMIQUE)
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    tooltip: "Modifier mon profil",
                    onPressed: () async {
                      Navigator.pop(context); // Fermer le drawer

                      final updatedUser = await Navigator.push<UserModel>(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditProfileScreen(currentUser: _currentUser),
                        ),
                      );

                      // Si l'utilisateur a modifié ses données, on met à jour HomePage
                      if (updatedUser != null && mounted) {
                        setState(() {
                          _currentUser = updatedUser;
                        });
                        _getMessage();
                      }
                    },
                  ),
                ],
              ),
            ),

            const Spacer(),
            const Divider(height: 1),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Déconnexion',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () async {
                try {
                  Navigator.of(context).pop();
                  await _saveSessionState(false);
                  await _supabase.auth.signOut();
                  PushService.instance.unsubscribe();

                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur lors de la déconnexion : $e'),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),

      body: RefreshIndicator(
        onRefresh: _getMessage,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              FamilyCard(members: _members, publicationsCount: _message.length),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Fil d'actualité",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 25),
              _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : MessageList(messages: _message, currentUser: _currentUser),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 36, 82, 37),
        foregroundColor: Colors.white,
        onPressed: () async {
          final postAdded = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddPostScreen(currentUser: _currentUser),
            ),
          );

          if (postAdded == true) {
            _getMessage();
          }
        },
        child: const Icon(Icons.add, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        backgroundColor: Colors.white,
        selectedItemColor: const Color.fromARGB(255, 36, 82, 37),
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        unselectedItemColor: Colors.grey,
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          // Index 2 = Events (Événements)
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventsScreen(currentUser: _currentUser),
              ),
            );
          }
          if (index == 3) {
            // Ouvre la liste des contacts → puis le chat privé
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ContactsScreen(
                  members: _members,
                  currentUser: _currentUser,
                ),
              ),
            );
          }
          // Plus tard : index 1 = Photos, index 2 = Events
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Accueil"),
          BottomNavigationBarItem(icon: Icon(Icons.image), label: "Photos"),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: "Events"),
          BottomNavigationBarItem(
            icon: Icon(Icons.message_outlined),
            label: "Messages",
          ),
        ],
      ),
    );
  }
}

// ─── FEUILLE DE NOTIFICATIONS (badge de la cloche) ────────────────────────

class _NotificationsSheet extends StatefulWidget {
  const _NotificationsSheet({
    required this.supabase,
    required this.currentUser,
    required this.onClosed,
  });

  final SupabaseClient supabase;
  final UserModel currentUser;
  final Future<void> Function() onClosed;

  @override
  State<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<_NotificationsSheet> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await widget.supabase
          .from('notifications')
          .select('*')
          .eq('user_id', widget.currentUser.id)
          .order('created_at', ascending: false)
          .limit(20);
      if (mounted) {
        setState(() {
          _items = rows;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markRead(String id) async {
    try {
      await widget.supabase
          .from('notifications')
          .update({'read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
      await _load();
      await widget.onClosed();
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      await widget.supabase
          .from('notifications')
          .update({'read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('user_id', widget.currentUser.id);
      await _load();
      await widget.onClosed();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _markAllRead,
                  child: const Text('Tout marquer lu'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _loading
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                )
              : _items.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('Aucune notification'),
                    )
                  : Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final n = _items[index];
                          final isRead = n['read_at'] != null;
                          final body = (n['body'] as String?) ?? '';
                          return ListTile(
                            leading: isRead
                                ? null
                                : Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                            title: Text(
                              (n['title'] as String?) ?? '',
                              style: TextStyle(
                                fontWeight: isRead
                                    ? FontWeight.w400
                                    : FontWeight.bold,
                              ),
                            ),
                            subtitle: body.isNotEmpty
                                ? Text(
                                    body,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            trailing: Text(
                              timeago.format(
                                DateTime.parse(n['created_at'] as String),
                              ),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            onTap: () => _markRead(n['id'] as String),
                          );
                        },
                      ),
                    ),
        ],
      ),
    );
  }
}