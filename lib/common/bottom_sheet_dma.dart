import 'dart:convert';
import 'package:arcgis_app_demo/config.dart';
import 'package:arcgis_app_demo/core/providers/global_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class BottomSheetDMA extends ConsumerStatefulWidget {
  final void Function(String) onSelect;
  const BottomSheetDMA({super.key, required this.onSelect});

  @override
  ConsumerState<BottomSheetDMA> createState() => _BottomSheetDMAState();
}

class _BottomSheetDMAState extends ConsumerState<BottomSheetDMA> {
  late Future<List<String>> _dmaFuture;

  Future<List<String>> _fetchDMAList() async {
    final savedList = ref.read(dmaListProvider);
    if (savedList.isNotEmpty) return savedList;

    final token = ref.read(arcgisTokenProvider) ?? '';
    final url = Uri.parse('${ArcGISConfig.dmaUrl}/query');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'where': 'IDDMA is not null',
        'outFields': 'IDDMA',
        'f': 'json',
        'token': token,
        'returnGeometry': 'false',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final features = jsonData['features'] as List;
      final dmaList = features
          .map((e) => e['attributes']['IDDMA']?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();

      ref.read(dmaListProvider.notifier).state = dmaList;
      return dmaList;
    }

    throw Exception('Failed to load DMA list');
  }

  @override
  void initState() {
    super.initState();
    _dmaFuture = _fetchDMAList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _dmaFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Lỗi tải dữ liệu DMA: ${snapshot.error}'),
          );
        }

        final dmaList = snapshot.data ?? [];
        return Container(
          height: 400,
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Danh sách DMA (${dmaList.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: dmaList.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final dmaId = dmaList[index];
                    return ListTile(
                      title: Text(
                        dmaId,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                      onTap: () {
                        widget.onSelect(dmaId);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
