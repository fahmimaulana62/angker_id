import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Bintang rating 0-5, mendukung setengah bintang.
class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.rating,
    this.size = 16,
    this.color = AppColors.primary,
  });

  final double rating;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final value = rating - i;
        final IconData icon;
        if (value >= 0.75) {
          icon = Icons.star_rounded;
        } else if (value >= 0.25) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_outline_rounded;
        }
        return Icon(icon, size: size, color: color);
      }),
    );
  }
}
