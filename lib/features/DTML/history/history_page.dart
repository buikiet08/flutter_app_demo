import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'history_controller.dart';
import 'history_provider.dart';
import 'widgets/history_item_widget.dart';
import 'widgets/history_pagination_widget.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({Key? key, this.onSelectTab}) : super(key: key);
  final void Function(int)? onSelectTab;

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage>
    with AutomaticKeepAliveClientMixin {
  late HistoryController _controller;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = HistoryController(ref);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.initialize(context);
    _controller.tryFetchWhenTokenReady();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final historyState = ref.watch(historyStateProvider);

    return Scaffold(
      body: historyState.loading
          ? const Center(child: CircularProgressIndicator())
          : historyState.error != null
              ? Center(child: Text(historyState.error!))
              : historyState.features.isEmpty
                  ? const Center(child: Text('Không có dữ liệu'))
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: historyState.features.length,
                            itemBuilder: (context, index) {
                              final feature = historyState.features[index];
                              final fields = historyState.fields ?? [];
                              final attributes = feature['attributes'] ?? {};
                              final id = attributes['IDVHV'] ?? '';
                              final isSelected = historyState.selectedItemId == id.toString();

                              return HistoryItemWidget(
                                fields: fields,
                                attributes: attributes,
                                id: id.toString(),
                                isSelected: isSelected,
                                formatDate: _controller.formatDate,
                                onTap: () {
                                  _controller.selectHistoryItem(
                                    attributes,
                                    id.toString(),
                                    widget.onSelectTab,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        HistoryPaginationWidget(
                          currentPage: historyState.page,
                          loading: historyState.loading,
                          canGoBack: historyState.page > 0,
                          canGoForward: historyState.features.length == historyState.pageSize,
                          onPreviousPage: _controller.previousPage,
                          onNextPage: _controller.nextPage,
                        ),
                      ],
                    ),
    );
  }
}