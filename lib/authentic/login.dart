import 'package:arcgis_app_demo/config.dart';
import 'package:arcgis_app_demo/core/providers/global_providers.dart';
import 'package:arcgis_app_demo/features/launcher/launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    implements ArcGISAuthenticationChallengeHandler {
  final _usernameController = TextEditingController(text: '');
  final _passwordController = TextEditingController(text: '');
  bool _rememberMe = false;
  bool _loading = false;
  bool _obscureText = true; 
  String? _error;

  @override
  void initState() {
    super.initState();
    ArcGISEnvironment.authenticationManager.arcGISAuthenticationChallengeHandler = this;
    _loadSavedCredentials();
  }

  final storage = FlutterSecureStorage();

  Future<void> saveCredentials(String username, String password) async {
    await storage.write(key: 'username', value: username);
    await storage.write(key: 'password', value: password);
  }

  Future<Map<String, String?>> loadCredentials() async {
    final username = await storage.read(key: 'username');
    final password = await storage.read(key: 'password');
    return {'username': username, 'password': password};
  }

  Future<void> clearCredentials() async {
    await storage.delete(key: 'username');
    await storage.delete(key: 'password');
  }

  @override
  Future<void> handleArcGISAuthenticationChallenge(
      ArcGISAuthenticationChallenge challenge) async {
    try {
      final credential = await TokenCredential.createWithChallenge(
        challenge,
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final tokenInfo = await credential.getTokenInfo();
      ref.read(arcgisTokenProvider.notifier).state = tokenInfo.accessToken;

      // Gán credential để portal tự động load user
      challenge.continueWithCredential(credential);

      if (_rememberMe) {
        await saveCredentials(_usernameController.text, _passwordController.text);
      } else {
        await clearCredentials();
      }

      final portal = Portal(
        Uri.parse(ArcGISConfig.portalUrl),
        connection: PortalConnection.authenticated,
      );
      await portal.load();

      ref.read(userProvider.notifier).state = portal.user;

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LauncherScreen()),
        );
      }
    } on ArcGISException catch (_) {
      setState(() {
        _error = 'Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin.';
        _loading = false;
      });
      challenge.continueAndFail();
    }
  }


  void _loadSavedCredentials() async {
    final creds = await loadCredentials();
    if (creds['username'] != null) {
      _usernameController.text = creds['username']!;
    }
    if (creds['password'] != null) {
      _passwordController.text = creds['password']!;
      setState(() {
        _rememberMe = true;
      });
      _startLogin();
    }
  }

  void _startLogin() async {
    if(_usernameController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() {
        _error = 'Vui lòng nhập tên đăng nhập và mật khẩu.';
      });
      return;
    }
    
    setState(() {
      _error = null;
      _loading = true;
    });

    final portal = Portal(Uri.parse(ArcGISConfig.portalUrl), connection: PortalConnection.authenticated);
    await portal.load(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.center,
            end: Alignment.bottomCenter,
            colors: [Colors.blueAccent, Colors.white],
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 87, top: 90),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Image.asset('assets/images/logo_login.png', height: 80),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Đăng nhập', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 18),
                          TextField(
                            controller: _usernameController,
                            decoration: const InputDecoration(labelText: 'Tên đăng nhập', labelStyle: TextStyle(fontSize: 18)),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscureText,
                            decoration: InputDecoration(
                              labelText: 'Mật khẩu',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureText ? Icons.visibility_off : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureText = !_obscureText; // Toggle trạng thái
                                  });
                                },
                              ),
                              labelStyle: const TextStyle(fontSize: 18)
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Text("Ghi nhớ tài khoản"),
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (val) {
                                  setState(() {
                                    _rememberMe = val ?? false;
                                  });
                                },
                              ),
                            ],
                          ),
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(_error!, style: const TextStyle(color: Colors.red)),
                            ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _startLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                              ),
                              child: const Text("Đăng nhập", style: TextStyle(fontSize: 16, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}
