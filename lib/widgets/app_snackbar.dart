import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

/// SnackBar pastel yang konsisten di seluruh aplikasi.
void showAppSnack(
  BuildContext context,
  String message, {
  IconData icon = Icons.check_circle_rounded,
  String? actionLabel,
  VoidCallback? onAction,
  bool isError = false,
  Duration duration = const Duration(milliseconds: 2200),
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: duration,
        backgroundColor: isError ? AppColors.danger : AppColors.plum,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        content: Row(
          children: [
            Icon(icon, color: isError ? Colors.white : AppColors.pink, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppText.body(14, color: Colors.white, weight: FontWeight.w600),
              ),
            ),
          ],
        ),
        action: actionLabel == null
            ? null
            : SnackBarAction(
                label: actionLabel,
                textColor: AppColors.pink,
                onPressed: onAction ?? () {},
              ),
      ),
    );
}

/// Pesan standar untuk operasi tulis DummyJSON (POST/PUT/PATCH/DELETE).
const String kMockNote = 'simulasi DummyJSON, tidak tersimpan permanen di server';
