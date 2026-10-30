import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/product_model.dart';
import 'app_network_image.dart';
import 'cart_actions.dart';
import 'wishlist_button.dart';

/// Rasio kartu untuk grid 2 kolom. Gambar mengisi sisa ruang, jadi aman di
/// berbagai ukuran layar & skala teks.
const double kProductCardAspect = 0.56;

SliverGridDelegate productGridDelegate(BuildContext context) {
  final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.3);
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
    childAspectRatio: kProductCardAspect / scale,
  );
}

class ProductCard extends StatefulWidget {
  const ProductCard({super.key, required this.product, required this.heroScope});

  final Product product;

  /// Prefix tag Hero (home/search/category) supaya unik antar halaman.
  final String heroScope;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  void _open() {
    context.push(AppRoutes.detail(widget.product.id, heroScope: widget.heroScope));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final soldOut = !p.inStock;

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: _open,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: RepaintBoundary(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppColors.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _ImageArea(product: p, heroScope: widget.heroScope)),
                const SizedBox(height: 10),
                Text(
                  (p.brand.isNotEmpty ? p.brand : Fmt.prettyCategory(p.category)).toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label(10.5, color: AppColors.plumMuted),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  height: 38,
                  child: Text(
                    p.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.heading(
                      14.5,
                      weight: FontWeight.w700,
                      height: 1.25,
                      color: soldOut ? AppColors.plumMuted : AppColors.plum,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 15,
                      color: soldOut ? AppColors.plumMuted : AppColors.primary,
                    ),
                    const SizedBox(width: 3),
                    Text(Fmt.rating(p.rating), style: AppText.label(12)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '· Stok ${p.stock}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(11.5, color: AppColors.plumMuted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            p.hasDiscount ? Fmt.price(p.originalPrice) : ' ',
                            maxLines: 1,
                            style: AppText.body(11.5, color: AppColors.plumMuted).copyWith(
                              decoration: TextDecoration.lineThrough,
                              decorationColor: AppColors.plumMuted,
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              Fmt.price(p.price),
                              style: AppText.price(18, color: soldOut ? AppColors.plumMuted : AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    _AddButton(product: p),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageArea extends StatelessWidget {
  const _ImageArea({required this.product, required this.heroScope});

  final Product product;
  final String heroScope;

  @override
  Widget build(BuildContext context) {
    final p = product;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: p.id.isEven ? AppColors.pinkTint : AppColors.creamSoft,
            child: Hero(
              tag: '$heroScope-${p.id}',
              child: AppNetworkImage(url: p.thumbnail, background: Colors.transparent),
            ),
          ),
          if (!p.inStock)
            Container(
              color: Colors.white.withValues(alpha: 0.6),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.sentiment_dissatisfied_rounded, color: AppColors.plumMuted),
                  ),
                  const SizedBox(height: 6),
                  Text('Stok Habis', style: AppText.label(12, color: AppColors.plumMuted)),
                ],
              ),
            ),
          Positioned(top: 8, left: 8, right: 48, child: Align(alignment: Alignment.centerLeft, child: StockBadge(product: p))),
          Positioned(top: 6, right: 6, child: WishlistButton(product: p, size: 34)),
          if (p.hasDiscount && p.inStock)
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.pink,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  '-${p.discountPercentage.round()}%',
                  style: AppText.label(11, color: Colors.white, weight: FontWeight.w800),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Badge stok: "Tersedia (5)", "Stok Menipis", "Stok Habis".
class StockBadge extends StatelessWidget {
  const StockBadge({super.key, required this.product, this.dense = true});

  final Product product;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final p = product;
    late final Color bg;
    late final Color fg;
    late final String text;
    IconData? icon;

    if (!p.inStock) {
      return const SizedBox.shrink();
    } else if (p.stockStatus == 'Low Stock' || p.stock < 10) {
      bg = AppColors.dangerSoft;
      fg = AppColors.danger;
      text = dense ? 'Stok Menipis' : 'Stok Menipis · ${p.stock}';
      icon = Icons.schedule_rounded;
    } else {
      bg = AppColors.mint;
      fg = AppColors.onMint;
      text = dense ? 'Tersedia' : 'Tersedia · ${p.stock} Stok';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: dense ? 3 : 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(50)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 11 : 14, color: fg),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.label(dense ? 10.5 : 12, color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final enabled = product.inStock;
    return Material(
      color: enabled ? AppColors.pinkDeep : AppColors.pinkTint,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? () => addToCartWithFeedback(context, product) : null,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            enabled ? Icons.add_rounded : Icons.block_rounded,
            color: enabled ? Colors.white : AppColors.plumMuted,
            size: 22,
          ),
        ),
      ),
    );
  }
}
