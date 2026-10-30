import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Gambar dari CDN DummyJSON dengan cache, placeholder pastel, dan fallback error.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.contain,
    this.cacheWidth = 400,
    this.background = AppColors.creamSoft,
    this.keepOldImageOnChange = false,
  });

  final String url;
  final BoxFit fit;
  final int cacheWidth;
  final Color background;

  /// Tetap tampilkan gambar lama sampai gambar baru selesai dimuat
  /// (dipakai galeri detail: thumbnail -> gambar resolusi penuh tanpa kedip).
  final bool keepOldImageOnChange;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _Fallback(background: background);
    return ColoredBox(
      color: background,
      child: CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        memCacheWidth: cacheWidth,
        useOldImageOnUrlChange: keepOldImageOnChange,
        fadeInDuration: const Duration(milliseconds: 220),
        fadeOutDuration: const Duration(milliseconds: 120),
        placeholder: (context, _) => const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.pink),
          ),
        ),
        errorWidget: (context, _, __) => _Fallback(background: background),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.background});
  final Color background;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: background,
      child: const Center(
        child: Icon(Icons.image_not_supported_rounded, color: AppColors.pinkDeep, size: 32),
      ),
    );
  }
}
