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

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skill Sharing App',
      theme: AppTheme.lightTheme,
      home: const OnboardingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
