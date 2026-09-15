import 'package:familly_blog/models/message_model.dart';
import 'package:familly_blog/models/user_model.dart';
import 'package:familly_blog/screens/message_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _supabase = Supabase.instance.client;

class MessageCard extends StatefulWidget {
  const MessageCard({
    super.key,
    required this.message,
    required this.currentUser,
  });

  final MessageModel message;
  final UserModel currentUser;

  @override
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
  bool _isExpanded = false;
  static const int _maxLength = 120;

  bool get _shouldTruncate =>
      widget.message.messageText != null &&
      widget.message.messageText!.trim().length > _maxLength;

  @override
  Widget build(BuildContext context) {
    final message = widget.message;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MessageDetailScreen(
              message: message,
              currentUser: widget.currentUser,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── PROFIL DE L'AUTEUR ───
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: const Color(0xFF245225).withOpacity(0.1),
                  backgroundImage:
                      (message.author.profil != null &&
                          message.author.profil!.isNotEmpty)
                      ? NetworkImage(message.author.profil!)
                      : null,
                  child:
                      (message.author.profil == null ||
                          message.author.profil!.isEmpty)
                      ? Text(
                          message.author.fullname.isNotEmpty
                              ? message.author.fullname[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Color(0xFF245225),
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
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
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ─── TEXTE DU MESSAGE (VOIR PLUS / VOIR MOINS) ───
            if (message.messageText != null &&
                message.messageText!.trim().isNotEmpty) ...[
              Text(
                _isExpanded || !_shouldTruncate
                    ? message.messageText!
                    : '${message.messageText!.substring(0, _maxLength)}...',
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
              if (_shouldTruncate)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _isExpanded ? 'Voir moins' : 'Voir plus',
                      style: const TextStyle(
                        color: Color(0xFF245225),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
            ],

            // ─── GALERIE D'IMAGES DYNAMIQUE ───
            if (message.messageImages.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildImagesGrid(message.messageImages),
            ],

            const SizedBox(height: 20),

            // ─── BARRE D'INTERACTIONS ───
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // ═══ COMPTEUR DE COMMENTAIRES EN TEMPS RÉEL (STREAM) ═══
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: message.id != null
                      ? _supabase
                            .from('comments')
                            .stream(primaryKey: ['id'])
                            .eq('message_id', message.id!)
                      : const Stream.empty(),
                  builder: (context, snapshot) {
                    final int count = snapshot.hasData
                        ? snapshot.data!.length
                        : 0;

                    return Row(
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          "$count",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(width: 20),

                // Partager
                const Row(
                  children: [
                    Icon(Icons.share_outlined, color: Colors.grey, size: 20),
                    SizedBox(width: 5),
                    Text(
                      "Partager",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── GRILLE D'IMAGES (1, 2, 3, 4+) ───
  Widget _buildImagesGrid(List<String> images) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 220,
        child: Builder(
          builder: (context) {
            if (images.length == 1) {
              return _buildSingleImage(images[0]);
            }

            if (images.length == 2) {
              return Row(
                children: [
                  Expanded(child: _buildSingleImage(images[0])),
                  const SizedBox(width: 4),
                  Expanded(child: _buildSingleImage(images[1])),
                ],
              );
            }

            if (images.length == 3) {
              return Row(
                children: [
                  Expanded(child: _buildSingleImage(images[0])),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(child: _buildSingleImage(images[1])),
                        const SizedBox(height: 4),
                        Expanded(child: _buildSingleImage(images[2])),
                      ],
                    ),
                  ),
                ],
              );
            }

            final int remaining = images.length - 3;
            return Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _buildSingleImage(images[0])),
                      const SizedBox(width: 4),
                      Expanded(child: _buildSingleImage(images[1])),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _buildSingleImage(images[2])),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildSingleImage(images[3]),
                            if (images.length > 4)
                              Container(
                                color: Colors.black.withOpacity(0.55),
                                alignment: Alignment.center,
                                child: Text(
                                  '+$remaining',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSingleImage(String imageUrl) {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey.shade200,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }
}
