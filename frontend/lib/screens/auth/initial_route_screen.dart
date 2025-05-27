import 'package:flutter/material.dart';
import 'package:skill_sharing_app/screens/home/dashboard_screen.dart';
import '../../utils/token_storage.dart';
import '../auth/login_screen.dart';

class InitialRouteScreen extends StatefulWidget {
  const InitialRouteScreen({super.key});

  @override
  State<InitialRouteScreen> createState() => _InitialRouteScreenState();
}

class _InitialRouteScreenState extends State<InitialRouteScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkTokenAndNavigate();
  }

  Future<void> _checkTokenAndNavigate() async {
    try {
      // Get the token from storage
      final token = await TokenStorage.getToken();

      if (token == null) {
        // No token found, navigate to login
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
        return;
      }

      // Token exists, check if it's expired
      final isExpired = await TokenStorage.isTokenExpired(token);

      if (isExpired) {
        // Token is expired, clear it and navigate to login
        await TokenStorage.clearToken();
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      } else {
        // Token is valid, navigate to home
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
      }
    } catch (e) {
      print('Error checking token: $e');
      // On error, navigate to login
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : const Text('Loading...'),
      ),
    );
  }
}
