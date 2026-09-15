import 'package:familly_blog/main.dart';
import 'package:familly_blog/models/user_model.dart';
import 'package:familly_blog/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:familly_blog/screens/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _supabase = Supabase.instance.client;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
                            Icons.lock_outline,
                            color: Color(0xFF2D6A4F),
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Center(
                        child: Text(
                          'Connexion',
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
                          'Bienvenue de retour',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 28),

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

                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Mot de passe oublié ?',
                            style: TextStyle(color: Color(0xFF2D6A4F)),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_formkey.currentState!.validate() == true) {
                              setState(() {
                                _isLoading = true;
                              });

                              try {
                                final AuthResponse res = await _supabase.auth
                                    .signInWithPassword(
                                      email: _emailController.text.trim(),
                                      password: _passwordController.text.trim(),
                                    );
                                if (res.user != null) {
                                  final currentUserData = await _supabase
                                      .from('users')
                                      .select()
                                      .eq('id', res.user!.id)
                                      .single();

                                  final currentUser = UserModel.fromJson(
                                    currentUserData,
                                  );
                                  await saveSessionState(true);
                                  setState(() {
                                    _isLoading = false;
                                  });
                                  if (context.mounted) {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            HomePage(currentUser: currentUser),
                                      ),
                                      (routes) => false,
                                    );
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  setState(() {
                                    _isLoading = false;
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Erreur de connexion : ${e.toString()}",
                                      ),
                                    ),
                                  );
                                }
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
                          child: (_isLoading)
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Se connecter',
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
                          const Text('Pas encore de compte ? '),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Créer un compte',
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
