import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/state/app_providers.dart';

// Import our dedicated router that has the new SettingsScreen
import 'ui/core/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  localDb = await SharedPreferences.getInstance();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ProviderScope(child: VibeMateApp()));
}

class VibeMateApp extends StatelessWidget {
  const VibeMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'VibeMate AI',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent, // Required for our Glass UI
        fontFamily: 'Inter',
      ),
      routerConfig: goRouter, // Uses the router from lib/ui/core/router.dart
    );
  }
}