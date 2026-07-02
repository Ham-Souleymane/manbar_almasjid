import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system navigation/status bars styling
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  // Initialize Firebase with defaults (uses instructions/placeholders or auto-configured ones)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization warning: $e');
    debugPrint(
      'Make sure to set up your Firebase project and run "flutterfire configure" '
      'or add your config files as specified in FIREBASE_SETUP.md.',
    );
  }

  runApp(
    const ProviderScope(
      child: ManbarAlmasjidApp(),
    ),
  );
}

class ManbarAlmasjidApp extends ConsumerWidget {
  const ManbarAlmasjidApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'منبر المسجد',
      debugShowCheckedModeBanner: false,

      // ── RTL & Arabic Localization ─────────────────────────────
      locale: const Locale('ar', 'AE'),
      supportedLocales: const [
        Locale('ar', 'AE'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ── Theming ────────────────────────────────────────────────
      theme: AppTheme.light,

      // ── Router ─────────────────────────────────────────────────
      routerConfig: router,
    );
  }
}
