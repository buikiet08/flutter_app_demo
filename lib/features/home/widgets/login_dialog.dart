import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';

class LoginDialog extends StatefulWidget {
  const LoginDialog({required this.challenge, required this.onLogin});

  final ArcGISAuthenticationChallenge challenge;
  final void Function(String username) onLogin;

  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Đăng nhập ArcGIS Portal', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: _usernameController, decoration: const InputDecoration(hintText: 'Username')),
            TextField(controller: _passwordController, decoration: const InputDecoration(hintText: 'Password'), obscureText: true),
            Row(
              children: [
                ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                const Spacer(),
                ElevatedButton(onPressed: _login, child: const Text('Login')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    try {
      final credential = await TokenCredential.createWithChallenge(
        widget.challenge,
        username: username,
        password: password,
      );
      widget.challenge.continueWithCredential(credential);
      widget.onLogin(username);
      Navigator.pop(context);
    } on ArcGISException catch (e) {
      // handle error
    }
  }
}