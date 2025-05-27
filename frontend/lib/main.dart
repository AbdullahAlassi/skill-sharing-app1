import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skill_sharing_app/screens/home/dashboard_screen.dart';

import 'package:skill_sharing_app/screens/onboarding/onboarding_screen.dart';
import 'package:skill_sharing_app/theme/app_theme.dart';
import 'package:skill_sharing_app/utils/token_storage.dart';
import 'config/app_config.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/skill_provider.dart';
import 'providers/friend_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/resource_provider.dart';
import 'providers/social_provider.dart';
import 'providers/progress_provider.dart';
import 'providers/skill_category_provider.dart';
import 'services/auth_service.dart';
import 'services/profile_service.dart';
import 'services/skill_service.dart';
import 'services/friend_service.dart';
import 'services/chat_service.dart';
import 'services/resource_service.dart';
import 'services/social_service.dart';
import 'services/api_client.dart';
import 'screens/splash/splash_screen.dart';
import 'services/progress_service.dart';
import 'providers/notification_provider.dart';
import 'services/notification_service.dart';
import 'screens/notification/notificationScreen.dart';

// Global navigator key for accessing context from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // Initialize API client
  final apiClient = ApiClient(baseUrl: AppConfig.apiBaseUrl);

  // Initialize services
  final authService = AuthService(apiClient);
  final profileService = ProfileService(apiClient);
  final skillService = SkillService(apiClient: apiClient);
  final friendService = FriendService();
  final chatService = ChatService(apiClient: apiClient);
  final resourceService = ResourceService();
  final socialService = SocialService(apiClient: apiClient);
  final progressService = ProgressService(apiClient: apiClient);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AuthProvider(authService, prefs, apiClient),
        ),
        ChangeNotifierProvider(
          create: (context) => UserProvider(profileService, apiClient),
        ),
        ChangeNotifierProvider(
          create: (context) => SkillProvider(skillService, progressService),
        ),
        ChangeNotifierProvider(
          create: (context) => FriendProvider(friendService),
        ),
        ChangeNotifierProvider(
          create: (context) => ChatProvider(chatService),
        ),
        ChangeNotifierProvider(
          create: (context) => ResourceProvider(resourceService),
        ),
        ChangeNotifierProvider(
          create: (context) => SocialProvider(socialService),
        ),
        ChangeNotifierProvider<ProgressProvider>(
          create: (context) => ProgressProvider(progressService),
        ),
        ChangeNotifierProvider(
          create: (context) => NotificationProvider(
            NotificationService(
              baseUrl: AppConfig.apiBaseUrl,
            ),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => SkillCategoryProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
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
    print('\n[AuthWrapper] Initializing...');
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      print('[AuthWrapper] Checking auth status...');
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Wait for auth provider to finish initializing
      while (authProvider.isLoading) {
        print('[AuthWrapper] Waiting for auth provider to initialize...');
        await Future.delayed(const Duration(milliseconds: 100));
      }

      print(
          '[AuthWrapper] Auth provider initialized: ${authProvider.isAuthenticated}');
      print(
          '[AuthWrapper] User provider initialized: ${userProvider.isLoggedIn}');

      if (authProvider.isAuthenticated) {
        print('[AuthWrapper] User is authenticated, loading user data...');
        // User is authenticated, load user data
        await userProvider.loadUser();

        if (mounted) {
          print('[AuthWrapper] Setting state to authenticated');
          setState(() {
            _isAuthenticated = true;
            _isLoading = false;
          });
        }
      } else {
        print('[AuthWrapper] User is not authenticated');
        if (mounted) {
          setState(() {
            _isAuthenticated = false;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('[AuthWrapper] Error checking auth status: $e');
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
    print('[AuthWrapper] Building with state:');
    print('- isLoading: $_isLoading');
    print('- isAuthenticated: $_isAuthenticated');
    print('- errorMessage: $_errorMessage');

    if (_isLoading) {
      print('[AuthWrapper] Showing splash screen');
      return const SplashScreen();
    }

    if (_errorMessage != null) {
      print('[AuthWrapper] Showing error screen');
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

    print(
        '[AuthWrapper] Navigating to: ${_isAuthenticated ? "Dashboard" : "Onboarding"}');
    return _isAuthenticated
        ? const DashboardScreen()
        : const OnboardingScreen();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Skill Sharing App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/home': (context) => const DashboardScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/notifications': (context) => const NotificationScreen(),
      },
    );
  }
}
