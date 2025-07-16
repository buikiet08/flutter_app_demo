import 'package:arcgis_app_demo/config.dart';
import 'package:arcgis_app_demo/core/providers/global_providers.dart';
import 'package:arcgis_app_demo/router/router.dart';
import 'package:arcgis_app_demo/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.read(userProvider);
    final avatarSize = 134.0;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: IconThemeData(color: Colors.white),
        automaticallyImplyLeading: true,
      ),
      body: Column(
        children: [
          // Header + Avatar
          Container(
            height: 200,
            alignment: Alignment.bottomCenter,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background_profile.png'),
                fit: BoxFit.fill,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: avatarSize / 2,
                      backgroundImage: NetworkImage(noImgae),
                      backgroundColor: AppColors.white,
                    ),
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.white,
                        child: Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    user!.username,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.edit, color: AppColors.textSecondary, size: 18),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'ID123-789155 B',
                style: TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          const SizedBox(height: 30),
          // Thông tin cá nhân
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                  label: 'Họ và tên',
                  value: user.fullName,
                  isBold: true,
                ),
                const SizedBox(height: 16),
                const _InfoRow(
                  label: 'Số điện thoại',
                  value: '0337889629',
                  isBold: true,
                ),
                const SizedBox(height: 16),
                _InfoRow(label: 'Email', value: user.email, isBold: true),
              ],
            ),
          ),

          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.errorBackground,
                  side: BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  ref.read(logoutProvider)();
                  Navigator.pushNamedAndRemoveUntil(context, AppRouter.loginScreen, (_) => false);
                },
                child: const Text(
                  "Đăng xuất",
                  style: TextStyle(color: AppColors.error, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
        Expanded(
          flex: 5,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
