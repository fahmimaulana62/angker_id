import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../core/theme/app_colors.dart';
import 'product_card.dart';

/// Kerangka loading pastel untuk grid produk (versi sliver).
class ProductGridShimmerSliver extends StatelessWidget {
  const ProductGridShimmerSliver({super.key, this.count = 6});
  final int count;

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: productGridDelegate(context),
      delegate: SliverChildBuilderDelegate(
        (context, index) => const ShimmerProductCard(),
        childCount: count,
      ),
    );
  }
}

class ShimmerProductCard extends StatelessWidget {
  const ShimmerProductCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow,
      ),
      child: Shimmer.fromColors(
        baseColor: AppColors.pinkTint,
        highlightColor: Colors.white,
        period: const Duration(milliseconds: 1300),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: ShimmerBox(radius: 16)),
            SizedBox(height: 12),
            ShimmerBox(width: 60, height: 10),
            SizedBox(height: 8),
            ShimmerBox(height: 14),
            SizedBox(height: 6),
            ShimmerBox(width: 90, height: 14),
            SizedBox(height: 14),
            Row(
              children: [
                ShimmerBox(width: 70, height: 20),
                Spacer(),
                ShimmerBox(width: 36, height: 36, radius: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Kotak abu-pink untuk kerangka shimmer.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({super.key, this.width, this.height, this.radius = 8});

  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.pinkSoft,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
