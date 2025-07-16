import 'package:arcgis_app_demo/common/confirm_exit_dialog.dart';
import 'package:arcgis_app_demo/features/DTML/dtml_provider.dart';
import 'package:arcgis_app_demo/features/DTML/home/home_page.dart';
import 'package:arcgis_app_demo/features/DTML/history/history_page.dart';
import 'package:arcgis_app_demo/router/router.dart';
import 'package:arcgis_app_demo/shared/helper.dart';
import 'package:arcgis_app_demo/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ignore: camel_case_types
class DTML_App extends StatelessWidget {
  const DTML_App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainTabScreen(); 
  }
}

class MainTabScreen extends ConsumerStatefulWidget {
  const MainTabScreen({super.key});

  @override
  ConsumerState<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends ConsumerState<MainTabScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _pages = <Widget>[
    HomePage(),
    HistoryPage(onSelectTab: _onItemTapped),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeTool = ref.watch(activeToolProvider);

    // ignore: deprecated_member_use
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primary,
        // leading: IconButton(
        //   icon: const Icon(Icons.menu, color: AppColors.white),
        //   onPressed: () {
        //     ScaffoldMessenger.of(context).showSnackBar(
        //       const SnackBar(content: Text('Menu button pressed')),
        //     );
        //   },
        // ),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),
        title: const Text('Điều tiết mạng lưới', style: TextStyle(fontSize: 22)),
        actions: [
          IconButton(
            color: AppColors.white,
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirm = await showConfirmExitDialog(context);
              if (confirm) {
                navigateAndClearStack(context, AppRouter.launcherScreen);
              }
            }
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: activeTool == true
          ? _DemoBottomAppBar()
          : NavigationBar(
              destinations: const <NavigationDestination>[
                NavigationDestination(
                  icon: Icon(Icons.map_outlined, size: 24),
                  selectedIcon: Icon(Icons.map_outlined, color: AppColors.white),
                  label: 'Trang chủ',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history, size: 24),
                  selectedIcon: Icon(
                    Icons.history_outlined,
                    color: AppColors.white,
                  ),
                  label: 'Giám sát',
                ),
              ],
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              indicatorColor: AppColors.primary,
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
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
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
                  title: "Flag"
                ),
                _buildToolButton(
                  ref: ref,
                  icon: Icons.warning_rounded,
                  toolType: ToolType.barrier,
                  isActive: activeButton == ToolType.barrier,
                  title: "Barrier"
                ),
                _buildOperationButton(
                  ref: ref,
                  label: 'Vận hành nhanh',
                  operationType: OperationType.quickOperation,
                  isActive: operationType == OperationType.quickOperation,
                  onPressed: () {
                    final checkType = ref.watch(operationTypeProvider);
                    if (checkType == OperationType.normalOperation) {
                      ref.read(operationTypeProvider.notifier).state = OperationType.quickOperation;
                    } else {
                      ref.read(operationTypeProvider.notifier).state = OperationType.normalOperation;
                    }
                    ref.read(activeToolButtonProvider.notifier).state = ToolType.flag;
                  },
                  isEnabled: true
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
                          backgroundColor: AppColors.warning,
                        ),
                      );
                      return;
                    }
                    // Trigger trace operation
                    ref.read(handleTraceTypeProvider.notifier).state = ToolType.flag;
                  },
                  isEnabled: ref.watch(operationTypeProvider) == OperationType.normalOperation
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
    required String title
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll<Color>(
              isActive ? AppColors.primary : AppColors.white,
            ),
            foregroundColor: WidgetStatePropertyAll<Color>(
              isActive ? AppColors.white : AppColors.primary,
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon),
              Text(title)
          ]),
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
    required bool isEnabled,
    required VoidCallback onPressed,
  }) {
    return Opacity(
    opacity: isEnabled ? 1.0 : 0.5,
    child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll<Color>(
            isActive ? AppColors.primary : AppColors.white,
          ),
          foregroundColor: WidgetStatePropertyAll<Color>(
            isActive ? AppColors.white : AppColors.primary,
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
        onPressed: isEnabled ? onPressed : null,
        child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      )
    );
  }
}
