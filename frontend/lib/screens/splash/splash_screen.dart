import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skill_sharing_app/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/token_storage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Add a minimum splash duration
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Wait for auth provider to initialize
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      if (authProvider.isAuthenticated) {
        // User is authenticated, load user data
        await userProvider.loadUser();

        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        // User is not authenticated, go to onboarding
        Navigator.of(context).pushReplacementNamed('/onboarding');
      }
    } catch (e) {
      print('Error during app initialization: $e');
      if (!mounted) return;

      // On error, show error message and retry button
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _initializeApp,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Add your app logo here
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading...',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
