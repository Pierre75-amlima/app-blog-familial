import 'dart:io';

import 'package:familly_blog/models/message_model.dart';
import 'package:familly_blog/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:image_picker/image_picker.dart';

final _supabase = Supabase.instance.client;

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key, required this.currentUser});
  final UserModel currentUser;

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final TextEditingController _messageController = TextEditingController();

  final List<File> _images = [];
  File? _selectedImage;

  bool _isLoading = false;

  Future<List<String>> _uploadImages() async {
    if (_images.isEmpty) return [];

    final uploadedUrls = <String>[];

    for (final image in _images) {
      try {
        final extension = image.path.split('.').last;
        final fileName =
            '${DateTime.now().microsecondsSinceEpoch}_${uploadedUrls.length}.$extension';
        final filePath = 'public/$fileName';

        await _supabase.storage.from('images').upload(filePath, image);

        uploadedUrls.add(
          _supabase.storage.from('images').getPublicUrl(filePath),
        );
      } catch (e) {
        print('Erreur upload image : $e');
      }
    }

    return uploadedUrls;
  }

  // ─── UPLOAD IMAGE PROFIL ───
  Future<String?> _uploadUserProfil() async {
    if (_selectedImage == null) return widget.currentUser.profil;

    try {
      final extension = _selectedImage!.path.split('.').last;
      final fileName = '${DateTime.now().microsecondsSinceEpoch}.$extension';
      final filePath = 'public/$fileName';

      await _supabase.storage.from('images').upload(filePath, _selectedImage!);

      final imageUrl = _supabase.storage.from('images').getPublicUrl(filePath);

      return imageUrl;
    } catch (e) {
      print('Erreur upload profil : $e');
      return widget.currentUser.profil;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nouvelle publication")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextFormField(
              controller: _messageController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: "Partagez un souvenir...",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            Column(
              children: [
                InkWell(
                  onTap: () async {
                    final pickedFiles = await ImagePicker().pickMultiImage();
                    if (pickedFiles != null) {
                      setState(() {
                        _images.addAll(pickedFiles.map((e) => File(e.path)));
                      });
                    }
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: 10),
                    width: double.infinity,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.add_a_photo,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                SizedBox(
                  height: 50,
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _images.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Stack(
                          children: [
                            Image.file(_images[index]),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _images.removeAt(index);
                                  });
                                },
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () async {
                if (_messageController.text.trim().isNotEmpty) {
                  setState(() {
                    _isLoading = true;
                  });

                  try {
                    final imageUrls = await _uploadImages();
                    final newMessage = MessageModel(
                      author: widget.currentUser,
                      publishedDate: DateTime.now(),
                      messageText: _messageController.text,
                      messageImages: imageUrls,
                    );
                    await _supabase
                        .from('messages')
                        .insert(newMessage.toJson());

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Message envoyé'),
                          backgroundColor: Color.fromARGB(255, 6, 124, 10),
                        ),
                      );
                    }
                    if (mounted) {
                      Navigator.pop(context, true);
                    }
                  } catch (e) {
                    print('Erreur : $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Message non envoyé'),
                          backgroundColor: Color.fromARGB(255, 155, 10, 0),
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  }
                }
              },
              child: (_isLoading == true)
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Publier"),
            ),
          ],
        ),
      ),
    );
  }
}
