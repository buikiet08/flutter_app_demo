import 'package:arcgis_app_demo/core/providers/global_providers.dart';
import 'package:arcgis_app_demo/features/home/home_page.dart';
import 'package:arcgis_app_demo/features/home/home_provider.dart';
import 'package:arcgis_app_demo/features/history/history_page.dart';
import 'package:arcgis_app_demo/features/report/report_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ArcGIS App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigoAccent),
      ),
      home: const MainTabScreen(),
    );
  }
}

class MainTabScreen extends ConsumerStatefulWidget {
  const MainTabScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends ConsumerState<MainTabScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _pages = <Widget>[
    HomePage(
      onLogin: (user) {
        ref.read(usernameProvider.notifier).state = user;
      },
      onLayersReady: (layers) => {
        // Handle layers ready if needed
      },
    ),
    HistoryPage(key: const Key('historyPage'), onSelectTab: _onItemTapped),
    ReportPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() async {
    ref.read(logoutProvider)();
    setState(() {
      _selectedIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final username = ref.watch(usernameProvider);
    final activeTool = ref.watch(activeToolProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        title: Text(username != null ? 'Hi, $username' : 'ArcGIS App'),
        actions: [
          if (username != null)
            IconButton(
              color: Colors.white, // White color for the icon
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: _logout,
            ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: activeTool == true
          ? _DemoBottomAppBar()
          : NavigationBar(
              destinations: const <NavigationDestination>[
                NavigationDestination(
                  icon: Icon(Icons.map, size: 20),
                  selectedIcon: Icon(Icons.map_outlined, color: Colors.white),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history, size: 20),
                  selectedIcon: Icon(
                    Icons.history_outlined,
                    color: Colors.white,
                  ),
                  label: 'Giám sát',
                ),
                NavigationDestination(
                  icon: Icon(Icons.report, size: 20),
                  selectedIcon: Icon(
                    Icons.report_outlined,
                    color: Colors.white,
                  ),
                  label: 'Báo cáo',
                ),
              ],
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              indicatorColor: Colors.blueAccent,
              labelPadding: const EdgeInsets.symmetric(
                horizontal: 0.0,
                vertical: 0.0,
              ),
              labelTextStyle: MaterialStateProperty.all(
                const TextStyle(fontSize: 12),
              ),
              height: 60,
            ),
    );
  }
}

class _DemoBottomAppBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeButton = ref.watch(activeToolButtonProvider);
    final operationType = ref.watch(operationTypeProvider);
    
    return BottomAppBar(
      height: 60,
      color: Colors.blueAccent,
      padding: const EdgeInsets.all(4.0),
      child: IconTheme(
        data: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
        child: Column(
          children: [
            // Tool selection row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                _buildToolButton(
                  ref: ref,
                  icon: Icons.flag,
                  toolType: ToolType.flag,
                  isActive: activeButton == ToolType.flag,
                ),
                _buildToolButton(
                  ref: ref,
                  icon: Icons.warning_rounded,
                  toolType: ToolType.barrier,
                  isActive: activeButton == ToolType.barrier,
                ),
                _buildOperationButton(
                  ref: ref,
                  label: 'Vận hành nhanh',
                  operationType: OperationType.quickOperation,
                  isActive: operationType == OperationType.quickOperation,
                  onPressed: () {
                    ref.read(operationTypeProvider.notifier).state = OperationType.quickOperation;
                  },
                ),
                _buildOperationButton(
                  ref: ref,
                  label: 'Vận hành',
                  operationType: OperationType.normalOperation,
                  isActive: operationType == OperationType.normalOperation,
                  onPressed: () {
                    final geometries = ref.read(listGeometryProvider);
                    if (geometries.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng chấm điểm trước khi thực hiện vận hành'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                    // Trigger trace operation
                    ref.read(handleTraceTypeProvider.notifier).state = ToolType.flag;
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required WidgetRef ref,
    required IconData icon,
    required ToolType toolType,
    required bool isActive,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          backgroundColor: isActive ? Colors.green : Colors.white,
          foregroundColor: isActive ? Colors.white : Colors.blueAccent,
          elevation: isActive ? 6.0 : 2.0,
          child: Icon(icon),
          onPressed: () {
            // Toggle the button - if it's already active, deactivate it, otherwise activate it
            if (isActive) {
              ref.read(activeToolButtonProvider.notifier).state = null;
            } else {
              ref.read(activeToolButtonProvider.notifier).state = toolType;
            }
          },
        ),
      ],
    );
  }

  Widget _buildOperationButton({
    required WidgetRef ref,
    required String label,
    required OperationType operationType,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll<Color>(
          isActive ? Colors.green : Colors.white,
        ),
        foregroundColor: WidgetStatePropertyAll<Color>(
          isActive ? Colors.white : Colors.blueAccent,
        ),
        shape: const WidgetStatePropertyAll<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
          ),
        ),
        padding: const WidgetStatePropertyAll<EdgeInsets>(
          EdgeInsets.symmetric(horizontal: 12.0, vertical: 0.0),
        ),
      ),
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
