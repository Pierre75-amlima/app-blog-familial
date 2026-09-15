import 'package:familly_blog/main.dart';
import 'package:familly_blog/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:familly_blog/screens/home_screen.dart';
import 'package:familly_blog/screens/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Instance globale du client Supabase pour accéder à l'auth et à la base de données
final _supabase = Supabase.instance.client;

// Widget d'inscription : StatefulWidget car on gère des contrôleurs et l'état du formulaire
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  // Booléen pour indiquer si une inscription est en cours (pour afficher un loader plus tard)
  bool _isLoading = false;

  @override
  void dispose() {
    // Libération des ressources des contrôleurs quand le widget est détruit (évite les fuites mémoire)
    _fullnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F3),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formkey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEAF5EB),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_add_alt_1_outlined,
                            color: Color(0xFF2D6A4F),
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Center(
                        child: Text(
                          'Inscription',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E2A25),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text(
                          'Crée ton compte',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 28),

                      const Text(
                        'Nom complet',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E2A25),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _fullnameController,
                        decoration: InputDecoration(
                          hintText: 'Votre nom complet',
                          filled: true,
                          fillColor: const Color(0xFFF8FAF8),
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFF2D6A4F),
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veillez entrer votre nom complet';
                          }
                          if (value.length < 3) {
                            return 'Nom trop court';
                          }
                          return null;
                        },
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        'Adresse email',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E2A25),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          hintText: 'exemple@email.com',
                          filled: true,
                          fillColor: const Color(0xFFF8FAF8),
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFF2D6A4F),
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veillez entrer votre email';
                          }
                          if (!value.contains('@')) {
                            return 'Adresse email invalide';
                          }
                          return null;
                        },
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        'Téléphone',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E2A25),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _telephoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: 'Votre numéro',
                          filled: true,
                          fillColor: const Color(0xFFF8FAF8),
                          prefixIcon: const Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFF2D6A4F),
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre numéro de téléphone';
                          }
                          if (value.length != 10) {
                            return 'Le numéro doit contenir 10 chiffres';
                          }
                          return null;
                        },
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        'Mot de passe',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E2A25),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: '********',
                          filled: true,
                          fillColor: const Color(0xFFF8FAF8),
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFF2D6A4F),
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Entrer le mot de passe';
                          }
                          if (value.length < 8) {
                            return 'Le mot de passe doit contenir au moins 8 caractères';
                          }
                          return null;
                        },
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_formkey.currentState!.validate() == true) {
                              try {
                                final AuthResponse response = await _supabase
                                    .auth
                                    .signUp(
                                      password: _passwordController.text.trim(),
                                      email: _emailController.text.trim(),
                                    );
                                if (response.user != null) {
                                  final userId = response.user!.id;

                                  final newUser = UserModel(
                                    id: userId,
                                    fullname: _fullnameController.text,
                                    email: _emailController.text,
                                    telephone: _telephoneController.text,
                                  );
                                  await _supabase
                                      .from("users")
                                      .insert(newUser.toJson());
                                  await saveSessionState(true);
                                  if (context.mounted) {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            HomePage(currentUser: newUser),
                                      ),
                                      (routes) => false,
                                    );
                                  }
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Erreur d'inscription : $e"),
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D6A4F),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            "S'inscrire",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text('Déjà un compte ? '),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Se connecter',
                              style: TextStyle(
                                color: Color(0xFF2D6A4F),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
