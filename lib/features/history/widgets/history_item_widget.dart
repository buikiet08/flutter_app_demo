import 'package:arcgis_app_demo/shared/constanrs.dart';
import 'package:flutter/material.dart';

class HistoryItemWidget extends StatelessWidget {
  final List? fields; // Assuming fields is a list of field names or metadata
  final Map<String, dynamic> attributes;
  final String id;
  final bool isSelected;
  final VoidCallback onTap;
  final String Function(dynamic) formatDate;

  const HistoryItemWidget({
    Key? key,
    required this.fields,
    required this.attributes,
    required this.id,
    required this.isSelected,
    required this.onTap,
    required this.formatDate,
  }) : super(key: key);

  String getFields(String key) {
    if (fields != null) {
      final field = fields?.toList().where((i) => i['name'] == key).first;
      return field['alias'] ?? key;
    }
    return key; // Return the key itself if fields is null
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isSelected ? Colors.blue.withOpacity(0.08) : null,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        children: [
          ListTile(
          selected: isSelected,
          title: Text(
            'IDVHV: $id',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ...attributes.entries
              .where((e) => e.key != 'IDVHV' && e.key != 'TrangThai' && e.key != 'NoiDung')
              .map((e) {
              final isNgay = e.key.toLowerCase().startsWith('ngay');
              final value = isNgay ? formatDate(e.value) : (e.value ?? '');
              return Text('${getFields(e.key)}: $value');
            }),
            if (attributes.containsKey('NoiDung'))
              Text('${getFields('NoiDung')}: ${_getContentStatus(attributes['NoiDung']?.toString())}'),
            ],
          ),
          ),
          Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
            Text(
              _getStatus(attributes['TrangThai']?.toString()),
              style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: _getStatusColor(attributes['TrangThai']?.toString()),
              ),
            ),
            FilledButton(
              onPressed: onTap,
              child: const Text('Chi tiết'),
            ),
            ],
          ),
          ),
        ],
      ),
    );
    }

    String _getStatus(String? status) {
      return statusHistory[status] ?? 'Không xác định';
    }

    String _getContentStatus(String? content) {
      return statusContent[content] ?? 'Không xác định';
    }

    Color _getStatusColor(String? status) {
    switch (status) {
      case "0": return Colors.red;
      case "1": return Colors.orange;
      case "2": return Colors.green;
      default: return Colors.grey;
    }
  }
}
