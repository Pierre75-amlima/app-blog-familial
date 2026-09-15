import 'package:familly_blog/models/user_model.dart';
import 'package:familly_blog/screens/home_screen.dart';
import 'package:familly_blog/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:familly_blog/screens/splash_screen.dart';

const String _isLoggedInKey = 'is_logged_in';

Future<void> saveSessionState(bool isLoggedIn) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_isLoggedInKey, isLoggedIn);
}

Future<bool> hasSavedSession() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_isLoggedInKey) ?? false;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Charger le fichier .env
  await dotenv.load(fileName: ".env");

  // Initialiser Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  timeago.setLocaleMessages('fi', timeago.FiMessages());
  timeago.setLocaleMessages('fi_short', timeago.FiShortMessages());

  runApp(const MyApp());
}

// Variable globale pour accéder à Supabase facilement
final supabase = Supabase.instance.client;

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoadingSession = true;
  bool _isLoggedIn = false;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _checkSavedSession();
  }

  void _finishSplash() {
    if (mounted) {
      setState(() {
        _showSplash = false;
      });
    }
  }

  Future<void> _checkSavedSession() async {
    final hasSession = await hasSavedSession();

    if (mounted) {
      setState(() {
        _isLoggedIn = hasSession && supabase.auth.currentUser != null;
        _isLoadingSession = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashScreen(onFinished: _finishSplash),
      );
    }

    if (_isLoadingSession) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Family Blog',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2D6A4F),
        useMaterial3: true,
      ),
      home: _isLoggedIn ? const HomeLoader() : const RegisterScreen(),
    );
  }
}

class HomeLoader extends StatefulWidget {
  const HomeLoader({super.key});

  @override
  State<HomeLoader> createState() => _HomeLoaderState();
}

class _HomeLoaderState extends State<HomeLoader> {
  bool _loading = true;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const RegisterScreen()),
          (route) => false,
        );
      }
      return;
    }

    try {
      final response = await supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      if (mounted) {
        setState(() {
          _currentUser = UserModel.fromJson(response);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const RegisterScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_currentUser == null) {
      return const RegisterScreen();
    }

    return HomePage(currentUser: _currentUser!);
  }
}
