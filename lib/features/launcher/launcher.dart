import 'package:arcgis_app_demo/features/DTML/app.dart';
import 'package:flutter/material.dart';

class LauncherScreen extends StatelessWidget {
  const LauncherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_AppItem> apps = [
      _AppItem(
        title: 'Điều tiết mạng lưới',
        imageUrl: 'https://image.pngaaa.com/700/5273700-middle.png',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DTML_App())),
      ),
      _AppItem(
        title: 'Quản lý sự cố',
        imageUrl: 'https://image.pngaaa.com/700/5273700-middle.png',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Text("QLSC"))),
      ),
      _AppItem(
        title: 'Quản lý tài sản',
        imageUrl: 'https://image.pngaaa.com/700/5273700-middle.png',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Text("QLTS"))),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        title: Text('Chọn ứng dụng', style: TextStyle(fontSize: 22),),
        actions: [
          IconButton(
            color: Colors.white, // White color for the icon
            icon: const Icon(Icons.person),
            tooltip: 'User info',
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemCount: apps.length,
        itemBuilder: (context, index) => _AppCard(item: apps[index]),
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

class _AppCard extends StatelessWidget {
  final _AppItem item;
  const _AppCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image full width, no padding
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              item.imageUrl,
              height: 100,
              width: double.infinity,
              fit: BoxFit.contain,
            ),
          ),
          // Title and Button (horizontal)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                ElevatedButton(
                  onPressed: item.onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Truy cập', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
