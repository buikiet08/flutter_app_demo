import 'dart:async';

import 'package:arcgis_app_demo/config.dart';
import 'package:arcgis_app_demo/core/providers/global_providers.dart';
import 'package:arcgis_app_demo/router/router.dart';
import 'package:arcgis_app_demo/shared/constanrs.dart';
import 'package:arcgis_app_demo/shared/helper.dart';
import 'package:arcgis_app_demo/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LauncherScreen extends ConsumerStatefulWidget {
  const LauncherScreen({super.key});

  @override
  ConsumerState<LauncherScreen> createState() => _LauncherScreenState();
}

class _LauncherScreenState extends ConsumerState<LauncherScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchValue = '';
  bool isSearching = false;
  Timer? _debounce;

  List<AppConfig> filteredApps = [];

  @override
  void initState() {
    super.initState();
    filteredApps = AppsConfig.apps;
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    if (value.isEmpty) {
      setState(() {
        isSearching = true;
        searchValue = '';
        filteredApps = AppsConfig.apps;
      });
      return;
    }

    setState(() {
      isSearching = value.isNotEmpty;
    });

    _debounce = Timer(const Duration(seconds: 1), () {
      final result = AppsConfig.apps.where((app) {
        final title = removeDiacritics(app.title.toLowerCase());
        final search = removeDiacritics(value.toLowerCase());
        return title.contains(search);
      }).toList();

      setState(() {
        searchValue = value;
        filteredApps = result;
      });
    });
  }

  void _onClear() {
    _searchController.clear();
    _debounce?.cancel();
    setState(() {
      searchValue = '';
      isSearching = false;
      filteredApps = AppsConfig.apps;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.read(userProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.center,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: 100,
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.only(top: 20),
                alignment: Alignment.center,
                child: isSearching
                  ? SeachTextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    onClear: _onClear,
                  )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Xin chào:",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                            ),
                            Text(
                              user!.fullName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          spacing: 0.0,
                          children: [
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  isSearching = !isSearching;
                                });
                              },
                              icon: const Icon(
                                Icons.search,
                                color: AppColors.white,
                                size: 24,
                              ),
                            ),

                            IconButton(
                              onPressed: () {
                                
                              },
                              icon: const Icon(
                                Icons.settings_outlined,
                                color: AppColors.white,
                                size: 24,
                              ),
                            ),

                            IconButton(
                              onPressed: () {
                                Navigator.pushNamed(context, AppRouter.userProfileScreen);
                              },
                              icon: CircleAvatar(
                                backgroundImage: NetworkImage(noImgae),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ứng dụng của bạn',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Expanded(
                        child: GridView.builder(
                          itemCount: filteredApps.length,
                          gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4, // 3 cột
                              crossAxisSpacing: 0,
                              mainAxisSpacing: 0,
                              childAspectRatio: 0.8, // điều chỉnh chiều cao
                            ),
                          itemBuilder: (context, index) {
                            final app = filteredApps[index];
                            final item = _AppItem(
                              title: app.title,
                              imageUrl: app.iconPath,
                              onTap: () {
                                // xử lý điều hướng theo name
                                switch (app.name) {
                                  case 'DTML': navigateAndClearStack(context, AppRouter.dtmlApp);
                                    break;
                                  case 'QLSC':
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const Text("QLSC"),
                                      ),
                                    );
                                    break;
                                  case 'QLTS':
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const Text("QLTS"),
                                      ),
                                    );
                                    break;
                                }
                              },
                            );
                            return _AppGridCard(item: item);
                          },
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

class _AppItem {
  final String title;
  final String imageUrl;
  final VoidCallback onTap;

  _AppItem({required this.title, required this.imageUrl, required this.onTap});
}
// widget app grid card
class _AppGridCard extends StatelessWidget {
  final _AppItem item;

  const _AppGridCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            height: 71,
            width: 72,
            child: Image.asset(
              item.imageUrl,
              fit: BoxFit.contain,
              width: 72,
              height: 72,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
// widget search
class SeachTextField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;
  final ValueChanged<String> onChanged;

  const SeachTextField({
    super.key,
    required this.controller,
    required this.onClear,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.blue[700], // nền xanh
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                cursorColor: Colors.white,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                  hintText: 'Tìm kiếm ứng dụng',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(left: 12, right: 8),
                    child: Icon(Icons.search, size: 18, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        GestureDetector(
          onTap: () {
            onClear();
            FocusScope.of(context).unfocus();
          },
          child: const Text(
            'Hủy',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

