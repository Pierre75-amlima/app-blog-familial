import 'dart:io';
import 'package:familly_blog/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _supabase = Supabase.instance.client;

class EditProfileScreen extends StatefulWidget {
  final UserModel currentUser;

  const EditProfileScreen({super.key, required this.currentUser});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullnameController;
  late TextEditingController _telephoneController;

  File? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fullnameController =
        TextEditingController(text: widget.currentUser.fullname);
    _telephoneController =
        TextEditingController(text: widget.currentUser.telephone ?? '');
  }

  @override
  void dispose() {
    _fullnameController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  // ─── SÉLECTION D'IMAGE DEPUIS LA GALERIE ───
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Compresse l'image pour un upload rapide
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection : $e')),
      );
    }
  }

    // ─── UPLOAD DE L'IMAGE DE PROFIL ───
  Future<String?> _uploadUserProfil() async {
    if (_selectedImage == null) return widget.currentUser.profil;

    try {
      final extension = _selectedImage!.path.split('.').last;
      final fileName =
          '${DateTime.now().microsecondsSinceEpoch}.$extension';
      final filePath = 'public/$fileName';

      await _supabase.storage.from('images').upload(filePath, _selectedImage!);

      final imageUrl =
          _supabase.storage.from('images').getPublicUrl(filePath);

      return imageUrl;
    } catch (e) {
      print('Erreur upload profil : $e');
      return widget.currentUser.profil;
    }
  }

    Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final String? photoUrl = await _uploadUserProfil();

      final updatedFullname = _fullnameController.text.trim();
      final updatedTelephone = _telephoneController.text.trim();

      final userId = widget.currentUser.id; 

      await _supabase.from('users').update({
        'fullname': updatedFullname,
        'telephone': updatedTelephone,
        'profil': photoUrl, 
      }).eq('id', userId);

      final updatedUser = widget.currentUser.copyWith(
        fullname: updatedFullname,
        telephone: updatedTelephone,
        profil: photoUrl,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil mis à jour avec succès !'),
          backgroundColor: Color(0xFF245225),
        ),
      );

      Navigator.pop(context, updatedUser);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sauvegarde : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Modifier mon profil",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ─── PHOTO DE PROFIL DYNAMIQUE + CAMÉRA ───
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor:
                          const Color(0xFF245225).withOpacity(0.1),
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : (widget.currentUser.profil != null &&
                                  widget.currentUser.profil!.isNotEmpty)
                              ? NetworkImage(widget.currentUser.profil!)
                                  as ImageProvider
                              : null,
                      child: (_selectedImage == null &&
                              (widget.currentUser.profil == null ||
                                  widget.currentUser.profil!.isEmpty))
                          ? Text(
                              widget.currentUser.fullname.isNotEmpty
                                  ? widget.currentUser.fullname[0]
                                      .toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF245225),
                              ),
                            )
                          : null,
                    ),

                    // Bouton Caméra (Cliquable)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _isLoading ? null : _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF245225),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ─── CHAMP NOM COMPLET ───
              TextFormField(
                controller: _fullnameController,
                decoration: InputDecoration(
                  labelText: "Nom complet",
                  prefixIcon: const Icon(Icons.person_outline,
                      color: Color(0xFF245225)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFF245225), width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Veuillez renseigner votre nom";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // ─── CHAMP EMAIL (LECTURE SEULE) ───
              TextFormField(
                initialValue: widget.currentUser.email,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Adresse email (non modifiable)",
                  prefixIcon:
                      const Icon(Icons.email_outlined, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ─── CHAMP TÉLÉPHONE ───
              TextFormField(
                controller: _telephoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "Numéro de téléphone",
                  prefixIcon: const Icon(Icons.phone_outlined,
                      color: Color(0xFF245225)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFF245225), width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // ─── BOUTON ENREGISTRER ───
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF245225),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isLoading ? null : _saveProfile,
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          "Enregistrer les modifications",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}