import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'package:frontend/screens/home/home_screen.dart';
import 'screens/skills/skills_screen.dart';
import 'screens/skills/skill_detail_screen.dart';
import 'screens/events/events_screen.dart';
import 'package:frontend/screens/events/event_detail_screen.dart';
import 'utils/token_storage.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final isLoggedIn = await TokenStorage.isLoggedIn();

      if (isLoggedIn) {
        // Load user data
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.loadUser();

        if (mounted) {
          setState(() {
            _isAuthenticated = true;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isAuthenticated = false;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Error checking authentication status: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _checkAuthStatus,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return _isAuthenticated ? const HomeScreen() : const OnboardingScreen();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        // Add other providers here if needed
      ],
      child: MaterialApp(
        title: 'Skill Sharing App',
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
