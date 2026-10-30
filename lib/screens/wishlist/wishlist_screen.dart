import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../widgets/animated_entry.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/cart_actions.dart';
import '../../widgets/state_views.dart';
import '../shell/main_shell.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Kosongkan wishlist?', style: AppText.heading(18)),
        content: Text('Semua produk favoritmu akan dihapus.', style: AppText.body(14, color: AppColors.plumMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.pinkDeep),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) context.read<WishlistProvider>().clear();
  }

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();
    final items = wishlist.items;
    final topPad = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, topPad + 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(color: AppColors.pinkTint, shape: BoxShape.circle),
                  child: const Icon(Icons.favorite_rounded, color: AppColors.pinkDeep),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Wishlist Saya', style: AppText.heading(22, weight: FontWeight.w800)),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          '${items.length} produk favorit',
                          key: ValueKey(items.length),
                          style: AppText.body(13, color: AppColors.plumMuted),
                        ),
                      ),
                    ],
                  ),
                ),
                if (items.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _confirmClear(context),
                    icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.primary, size: 20),
                    label: Text('Hapus Semua', style: AppText.label(12.5, color: AppColors.primary)),
                    style: TextButton.styleFrom(backgroundColor: AppColors.pinkTint, shape: const StadiumBorder()),
                  ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: items.isEmpty
                  ? EmptyState(
                      key: const ValueKey('empty'),
                      icon: Icons.favorite_border_rounded,
                      title: 'Wishlist masih kosong',
                      message: 'Ketuk ikon hati di produk yang kamu suka supaya gampang ditemukan lagi.',
                      actionLabel: 'Jelajahi Produk',
                      onAction: () => context.go(AppRoutes.home),
                    )
                  : ListView.builder(
                      key: const ValueKey('list'),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, kNavBarClearance),
                      physics: const BouncingScrollPhysics(),
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final p = items[i];
                        return AnimatedEntry(
                          key: ValueKey('wish-${p.id}'),
                          id: 'wish-${p.id}',
                          index: i,
                          child: _WishlistTile(product: p),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WishlistTile extends StatelessWidget {
  const _WishlistTile({required this.product});
  final Product product;

  void _remove(BuildContext context) {
    final wishlist = context.read<WishlistProvider>();
    wishlist.remove(product.id);
    showAppSnack(
      context,
      'Dihapus dari wishlist',
      icon: Icons.heart_broken_rounded,
      actionLabel: 'Urungkan',
      onAction: () => wishlist.add(product),
    );
  }

  void _moveToCart(BuildContext context) {
    final wishlist = context.read<WishlistProvider>();
    final ok = addToCartWithFeedback(context, product);
    if (ok) wishlist.remove(product.id);
  }

  @override
  Widget build(BuildContext context) {
    final p = product;
    final inCart = context.select<CartProvider, bool>((c) => c.contains(p.id));

    return Dismissible(
      key: ValueKey('dismiss-wish-${p.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _remove(context),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.delete_rounded, color: AppColors.danger),
      ),
      child: GestureDetector(
        onTap: () => context.push(AppRoutes.detail(p.id, heroScope: 'wish')),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.softShadow,
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 96,
                  height: 96,
                  color: AppColors.pinkTint,
                  child: Hero(
                    tag: 'wish-${p.id}',
                    child: AppNetworkImage(url: p.thumbnail, cacheWidth: 250, background: Colors.transparent),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (p.brand.isNotEmpty ? p.brand : Fmt.prettyCategory(p.category)).toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.label(10.5, color: AppColors.plumMuted),
                    ),
                    Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.heading(14.5, height: 1.25)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 15, color: AppColors.primary),
                        const SizedBox(width: 3),
                        Text(Fmt.rating(p.rating), style: AppText.label(12)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            p.inStock ? 'Stok ${p.stock}' : 'Stok habis',
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body(12, color: p.inStock ? AppColors.plumMuted : AppColors.danger),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (p.hasDiscount)
                                Text(
                                  Fmt.price(p.originalPrice),
                                  style: AppText.body(11.5, color: AppColors.plumMuted)
                                      .copyWith(decoration: TextDecoration.lineThrough),
                                ),
                              Text(Fmt.price(p.price), style: AppText.price(17)),
                            ],
                          ),
                        ),
                        _SmallIconButton(
                          icon: Icons.favorite_rounded,
                          color: AppColors.pinkDeep,
                          bg: AppColors.pinkTint,
                          tooltip: 'Hapus',
                          onTap: () => _remove(context),
                        ),
                        const SizedBox(width: 6),
                        _SmallIconButton(
                          icon: inCart ? Icons.shopping_bag_rounded : Icons.add_shopping_cart_rounded,
                          color: p.inStock ? Colors.white : AppColors.plumMuted,
                          bg: p.inStock ? AppColors.pinkDeep : AppColors.pinkTint,
                          tooltip: 'Pindahkan ke keranjang',
                          onTap: p.inStock ? () => _moveToCart(context) : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  const _SmallIconButton({
    required this.icon,
    required this.color,
    required this.bg,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color bg;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: bg,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 38, height: 38, child: Icon(icon, size: 19, color: color)),
        ),
      ),
    );
  }
}
