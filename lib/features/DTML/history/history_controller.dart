import 'package:arcgis_app_demo/core/providers/global_providers.dart';
import 'package:arcgis_app_demo/features/DTML/dtml_provider.dart';
import 'package:arcgis_app_demo/features/DTML/history/history_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HistoryController {
  final WidgetRef ref;
  late BuildContext context;

  HistoryController(this.ref);

  void initialize(BuildContext context) {
    this.context = context;
  }

  void dispose() {
    // Clean up any resources if needed
  }
  Future<void> tryFetchWhenTokenReady() async {
    final state = ref.read(historyStateProvider);
    if (state.hasFetched) return;
    
    final token = ref.read(arcgisTokenProvider);
    if (token != null) {
      await fetchFeatures();
      ref.read(historyStateProvider.notifier).setHasFetched(true);
    } else {
      await Future.delayed(const Duration(milliseconds: 300));
      if (context.mounted) {
        tryFetchWhenTokenReady();
      }
    }
  }

  Future<void> fetchFeatures({int? page}) async {
    final state = ref.read(historyStateProvider);
    final currentPage = page ?? state.page;
    
    ref.read(historyStateProvider.notifier).setLoading(true);
    ref.read(historyStateProvider.notifier).setError(null);

    final url = Uri.parse(
      'https://gis.phuwaco.com.vn/server/rest/services/VANHANHVAN/GIS_PHT_VANHANHVAN/FeatureServer/0/query',
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'where': 'IDVHV is not null',
          'outFields': 'IDVHV,DiaChi,NguoiBao,TrangThai,NgayKhoiTao,NgayCapNhat,NoiDung,NguoiXuLy',
          'f': 'json',
          'token': ref.read(arcgisTokenProvider) ?? '',
          'orderByFields': 'NgayKhoiTao DESC,OBJECTID ASC',
          'resultOffset': (currentPage * state.pageSize).toString(),
          'resultRecordCount': state.pageSize.toString(),
          'returnGeometry': 'false',
          'returnCountOnly': 'false',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if(ref.watch(historyStateProvider).fields == null) {
          ref.read(historyStateProvider.notifier).setFields(data['fields'] ?? []);
        }
        ref.read(historyStateProvider.notifier).setFeatures(data['features'] ?? []);
        ref.read(historyStateProvider.notifier).setPage(currentPage);
        ref.read(historyStateProvider.notifier).setLoading(false);
      } else {
        ref.read(historyStateProvider.notifier).setError('Lỗi server: ${response.statusCode}');
        ref.read(historyStateProvider.notifier).setLoading(false);
      }
    } catch (e) {
      ref.read(historyStateProvider.notifier).setError('Lỗi: $e');
      ref.read(historyStateProvider.notifier).setLoading(false);
    }
  }

  String formatDate(dynamic value) {
    if (value is int && value > 100000000000) {
      final date = DateTime.fromMillisecondsSinceEpoch(value);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return value?.toString() ?? '';
  }
  void selectHistoryItem(Map<String, dynamic> attributes, String id, Function(int)? onSelectTab) {
    ref.read(historyStateProvider.notifier).setSelectedItemId(id);
    ref.read(historyItemSelectedProvider.notifier).state = attributes;
    onSelectTab?.call(0); // Navigate to Map tab (index 0)
  }

  void previousPage() {
    final state = ref.read(historyStateProvider);
    if (state.page > 0 && !state.loading) {
      fetchFeatures(page: state.page - 1);
    }
  }

  void nextPage() {
    final state = ref.read(historyStateProvider);
    if (state.features.length == state.pageSize && !state.loading) {
      fetchFeatures(page: state.page + 1);
    }
  }
}
