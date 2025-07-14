import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/global_providers.dart';
import 'widgets/map_view.dart';
import 'home_controller.dart';
import 'home_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  final OnLoginCallback? onLogin;
  final OnLayersReadyCallback? onLayersReady;

  const HomePage({Key? key, this.onLogin, this.onLayersReady})
    : super(key: key);

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late HomeController controller;
  @override
  void initState() {
    super.initState();
    controller = HomeController(ref);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    controller.initialize(
      context,
      onLogin: widget.onLogin,
      onLayersReady: widget.onLayersReady,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overlayLoading = ref.watch(
      overlayLoadingProvider,
    ); // Listen to history item changes and trigger map operations only for new items
    ref.listen<Map<String, dynamic>?>(historyItemSelectedProvider, (
      previous,
      next,
    ) {
      if (next != null && mounted) {
        final nextId = next['IDVHV'];
        final previousId = previous?['IDVHV'];

        // Only process if this is a genuinely new selection
        if (nextId != null && nextId != previousId) {
          controller.onHistoryItemSelected();
        } else {
          print("Skipping duplicate history item selection: $nextId");
        }
      }
    });

    ref.listen<ToolType?>(handleTraceTypeProvider, (previous, next) {
      if (next != null) {
        controller.executeTraceOperation();
        // Reset the provider after handling
        ref.read(handleTraceTypeProvider.notifier).state = null;
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          MapViewWidget(
            controller: controller.mapViewController,
            onMapViewReady: controller.onMapViewReady,
            onTap: controller.onMapViewTap,
            overlayLoading: overlayLoading,
          ),

          Container(
            alignment: Alignment.topLeft,
            padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Consumer(
                      builder: (context, ref, _) {
                        final isActive = ref.watch(activeToolProvider);
                        return FloatingActionButton.small(
                          onPressed: () {
                            final current = ref.read(activeToolProvider.notifier).state ?? false;
                            controller.onActiveToolChanged(!current);
                          },
                          backgroundColor: isActive == true
                              ? Colors.red
                              : Colors.white70,
                          child: Icon(
                            isActive == true ? Icons.stop : Icons.ads_click,
                            size: 18,
                            color: isActive == true
                                ? Colors.white
                                : Colors.black54,
                          ),
                          
                        );
                      },
                    ),
                    FloatingActionButton.small(
                      child: const Icon(Icons.my_location, size: 18, color: Colors.black54),
                      backgroundColor: Colors.white70,
                      onPressed: () async {
                        await controller.goToMyLocation();
                      },
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
