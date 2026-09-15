import 'package:familly_blog/models/user_model.dart';
import 'package:flutter/material.dart';

class FamilyCard extends StatelessWidget {
  final List<UserModel> members;
  final int publicationsCount;

  const FamilyCard({
    super.key,
    this.members = const [],
    this.publicationsCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    // On prend les 4 premiers membres
    final displayedMembers = members.take(4).toList();
    // Nombre de membres restants après les 4 premiers
    final remainingCount = members.length - displayedMembers.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: "Notre espace ",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                TextSpan(
                  text: "familial",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 31, 121, 34),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Partagez vos moments, gardez vos\nsouvenirs",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 20),

          // ─── AVATARS ───
          Center(
            child: SizedBox(
              height: 40,
              width: 40.0 + (displayedMembers.length * 30.0) + 10.0,
              child: Stack(
                children: [
                  ...List.generate(displayedMembers.length, (index) {
                    final user = displayedMembers[index];
                    final hasPhoto =
                        user.profil != null && user.profil!.isNotEmpty;

                    return Positioned(
                      left: index * 30.0,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: _avatarColor(index),
                        backgroundImage: hasPhoto
                            ? NetworkImage(user.profil!)
                            : null,
                        child: hasPhoto
                            ? null
                            : Text(
                                user.fullname.isNotEmpty
                                    ? user.fullname[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    );
                  }),

                  // Si des membres restent, on affiche "+X", sinon le bouton "+"
                  Positioned(
                    left: displayedMembers.length * 30.0,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color.fromARGB(232, 179, 178, 178),
                      child: remainingCount > 0
                          ? Text(
                              '+$remainingCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            )
                          : const Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ─── STATS DYNAMIQUES ───
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    '$publicationsCount',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "Publications",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    '${members.length}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "Membres",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _avatarColor(int index) {
    const colors = [
      Color(0xFF245225),
      Colors.purple,
      Colors.blue,
      Colors.orange,
    ];
    return colors[index % colors.length];
  }
}
