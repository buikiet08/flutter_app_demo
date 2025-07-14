import 'package:flutter/material.dart';

class HistoryPaginationWidget extends StatelessWidget {
  final int currentPage;
  final bool loading;
  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;

  const HistoryPaginationWidget({
    Key? key,
    required this.currentPage,
    required this.loading,
    required this.canGoBack,
    required this.canGoForward,
    this.onPreviousPage,
    this.onNextPage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: canGoBack && !loading ? onPreviousPage : null,
          ),
          Text('Trang ${currentPage + 1}'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: canGoForward && !loading ? onNextPage : null,
          ),
        ],
      ),
    );
  }
}
