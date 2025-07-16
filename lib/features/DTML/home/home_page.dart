import 'package:arcgis_app_demo/common/bottom_sheet_dma.dart';
import 'package:arcgis_app_demo/features/DTML/dtml_provider.dart';
import 'package:arcgis_app_demo/shared/helper.dart';
import 'package:arcgis_app_demo/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/map_view.dart';
import 'home_controller.dart';
import 'home_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({Key? key})
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

          // ========= Action Left =========
          // if(ref.read(isMapCreatedProvider)) 
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
                          heroTag: 'activeTool',
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
                      heroTag: 'myLocation',
                      // ignore: sort_child_properties_last
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
          // ========= Action Right =========
          Container(
            alignment: Alignment.topRight,
            padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Consumer(
                      builder: (context, ref, _) {
                        return FloatingActionButton.small(
                          heroTag: 'dma',
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                              ),
                              builder: (context) => BottomSheetDMA(
                                onSelect: (dmaId) {
                                  print('Selected DMA: $dmaId');
                                  ref.read(activeDMAProvider.notifier).state = dmaId; 
                                  selectDMA(dmaId, ref);
                                },
                              ),
                            );
                          },
                          backgroundColor:AppColors.white70,
                          child: Text("DMA", style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700
                          )),
                          
                        );
                      },
                    ),

                    FloatingActionButton.small(
                      heroTag: 'basse_map',
                      // ignore: sort_child_properties_last
                      child: const Icon(Icons.map_outlined, size: 18, color: Colors.black54),
                      backgroundColor: Colors.white70,
                      onPressed: () async {
                      },
                    )
                  ],
                ),
              ],
            ),
          ),
          // ========= Action Bottom =========
          
        ],
      ),
    );
  }
}
