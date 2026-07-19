import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:background_downloader/background_downloader.dart';
import 'core/state/app_providers.dart';
import 'ui/core/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local database
  localDb = await SharedPreferences.getInstance();

  // Initialize background downloader — required to recover in-flight downloads
  // after the app is killed or the screen is turned off.
  await FileDownloader().configure(
    globalConfig: [
      (Config.requestTimeout, const Duration(seconds: 60)),
      (Config.checkAvailableSpace, const int.fromEnvironment('DART_VM_OPTIONS', defaultValue: 100)),
    ],
  );

  // Track tasks so that progress events are replayed on app resume
  await FileDownloader().trackTasks();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Immersive status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(const ProviderScope(child: EdgeXApp()));
}

class EdgeXApp extends StatelessWidget {
  const EdgeXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'EdgeX',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5CF6),
          brightness: Brightness.light,
        ),
        fontFamily: 'Inter',
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
      ),
      routerConfig: goRouter,
    );
  }
}