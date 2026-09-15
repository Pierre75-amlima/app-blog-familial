import 'package:familly_blog/models/comment_model.dart';
import 'package:familly_blog/models/message_model.dart';
import 'package:familly_blog/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _supabase = Supabase.instance.client;

class MessageDetailScreen extends StatefulWidget {
  final MessageModel message;
  final UserModel currentUser;

  const MessageDetailScreen({
    super.key,
    required this.message,
    required this.currentUser,
  });

  @override
  State<MessageDetailScreen> createState() => _MessageDetailScreenState();
}

class _MessageDetailScreenState extends State<MessageDetailScreen> {
  final TextEditingController _commentController = TextEditingController();

  List<CommentModel> _comments = [];
  bool _isLoadingComments = true;
  bool _isPostingComment = false;

  bool _isLiked = false;
  int _likeCount = 15;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // Récupère les commentaires depuis Supabase
  Future<void> _fetchComments() async {
    try {
      if (widget.message.id == null) return;

      final res = await _supabase
          .from('comments')
          .select('*, author:users(*)')
          .eq('message_id', widget.message.id!)
          .order('published_date', ascending: true);

      final commentsList = (res as List)
          .map((e) => CommentModel.fromJson(e))
          .toList();

      if (mounted) {
        setState(() {
          _comments = commentsList;
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingComments = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement : $e')),
        );
      }
    }
  }

  // Insère un commentaire dans Supabase
  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || widget.message.id == null) return;

    setState(() => _isPostingComment = true);

    try {
      await _supabase.from('comments').insert({
        'message_id': widget.message.id,
        'author_id': widget.currentUser.id,
        'comment_text': text,
        'published_date': DateTime.now().toIso8601String(),
      });

      _commentController.clear();
      FocusScope.of(context).unfocus(); // Ferme le clavier

      // Rafraîchit les commentaires
      await _fetchComments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erreur d'envoi : $e")));
      }
    } finally {
      if (mounted) setState(() => _isPostingComment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Publication",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ══ CARTE DU MESSAGE ══
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Auteur & Date
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: const Color(0xFF245225),
                              child: Text(
                                message.author.fullname[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.author.fullname,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  message.formateDate(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Texte intégral
                        if (message.messageText != null &&
                            message.messageText!.trim().isNotEmpty)
                          Text(
                            message.messageText!,
                            style: const TextStyle(fontSize: 16, height: 1.5),
                          ),

                        // Images
                        if (message.messageImages.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildAllImagesGallery(message.messageImages),
                        ],

                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 12),

                        // Boutons d'interaction
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.chat_bubble_outline,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "${_comments.length} Commentaires",
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.share_outlined,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Partager",
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ══ SECTION DES COMMENTAIRES ══
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Commentaires (${_comments.length})",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (_isLoadingComments)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_comments.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text(
                                "Aucun commentaire. Soyez le premier !",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _comments.length,
                            itemBuilder: (context, index) {
                              return _buildCommentItem(_comments[index]);
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ══ BARRE DE SAISIE FIXÉE EN BAS ══
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: "Écrire un commentaire...",
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF245225),
                    child: _isPostingComment
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : IconButton(
                            icon: const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 18,
                            ),
                            onPressed: _addComment,
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

  Widget _buildCommentItem(CommentModel comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF245225),
            child: Text(
              comment.author.fullname[0].toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        comment.author.fullname,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        comment.formateDate(),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    comment.commentText,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllImagesGallery(List<String> images) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: images.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            images[index],
            fit: BoxFit.cover,
            width: double.infinity,
          ),
        );
      },
    );
  }
}
