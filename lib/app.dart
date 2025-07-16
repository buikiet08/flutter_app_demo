import 'package:arcgis_app_demo/authentic/login.dart';
import 'package:arcgis_app_demo/features/DTML/app.dart';
import 'package:arcgis_app_demo/features/launcher/launcher.dart';
import 'package:arcgis_app_demo/features/launcher/user_profile.dart';
import 'package:arcgis_app_demo/router/router.dart';
import 'package:arcgis_app_demo/splash_screen/splash_screen.dart';
import 'package:arcgis_app_demo/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'ArcGIS App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      ),
      initialRoute: AppRouter.splashScreen,
      routes: {
        AppRouter.splashScreen: (_) => const SplashScreen(),
        AppRouter.loginScreen: (_) => const LoginScreen(),
        AppRouter.launcherScreen: (_) => const LauncherScreen(),
        AppRouter.userProfileScreen: (_) => const UserProfileScreen(),
        // Feature apps
        AppRouter.dtmlApp: (_) => const DTML_App(),
      },
    );
  }
}

