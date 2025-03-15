import 'package:flutter/material.dart';
import 'package:frontend/screens/welcome_screen.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/skillTestScreen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Skill Sharing App",
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AuthGate(),
    );
  }
}

// Decides which screen to show (Login or Home)
class AuthGate extends StatefulWidget {
  @override
  _AuthGateState createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Provider.of<AuthProvider>(context, listen: false).checkLoginStatus();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Scaffold(body: Center(child: CircularProgressIndicator()))
        : Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return authProvider.isAuthenticated ? HomeScreen() : WelcomePage();
          },
        );
  }
}
