import 'package:arcgis_app_demo/core/providers/global_providers.dart';
import 'package:arcgis_app_demo/features/launcher/launcher.dart';
import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'ArcGIS App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigoAccent),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate>
    implements ArcGISAuthenticationChallengeHandler {
  
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    ArcGISEnvironment.authenticationManager.arcGISAuthenticationChallengeHandler = this;
    _startLogin();
  }

  Future<void> _startLogin() async {
    // Có thể load Portal để trigger login nếu cần
    try {
      final portal = Portal(
        Uri.parse('https://gis.phuwaco.com.vn/portal'),
        connection: PortalConnection.authenticated,
      );
      await portal.load(); // tự trigger ArcGIS login
      ref.read(userProvider.notifier).state = portal.user;
    } catch (_) {}

    setState(() => _loading = false);
  }

  @override
  Future<void> handleArcGISAuthenticationChallenge(
      ArcGISAuthenticationChallenge challenge) async {
    try {
      final credential = await TokenCredential.createWithChallenge(
        challenge,
        username: 'intelli.dev',
        password: 'Intelli.dev.2024',
      );
      final tokenInfo = await credential.getTokenInfo();
      ref.read(arcgisTokenProvider.notifier).state = tokenInfo.accessToken;
      challenge.continueWithCredential(credential);
      setState(() => _loading = false);
    } on ArcGISException {
      challenge.continueAndFail();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return const LauncherScreen(); 
  }
}
