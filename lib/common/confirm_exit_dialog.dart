import 'package:arcgis_app_demo/theme/app_theme.dart';
import 'package:flutter/material.dart';

Future<bool> showConfirmExitDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Xác nhận thoát'),
      content: const Text('Bạn có chắc chắn muốn thoát không?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Huỷ'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Thoát', style: TextStyle(color: AppColors.white)),
        ),
      ],
    ),
  );

  return result == true;
}
