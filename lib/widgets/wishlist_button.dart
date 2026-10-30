import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../models/product_model.dart';
import '../providers/wishlist_provider.dart';
import 'app_snackbar.dart';

/// Tombol hati: scale 1 -> 1.35 -> 1 (elastic) saat ditekan.
/// Hanya rebuild ketika status wishlist produk ini berubah (context.select).
class WishlistButton extends StatefulWidget {
  const WishlistButton({
    super.key,
    required this.product,
    this.size = 36,
    this.showSnack = true,
  });

  final Product product;
  final double size;
  final bool showSnack;

  @override
  State<WishlistButton> createState() => _WishlistButtonState();
}

class _WishlistButtonState extends State<WishlistButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(begin: 1, end: 1.35).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween<double>(begin: 1.35, end: 1).chain(CurveTween(curve: Curves.elasticOut)),
      weight: 65,
    ),
  ]).animate(_controller);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    final added = context.read<WishlistProvider>().toggle(widget.product);
    _controller.forward(from: 0);
    if (widget.showSnack) {
      showAppSnack(
        context,
        added ? 'Ditambahkan ke wishlist' : 'Dihapus dari wishlist',
        icon: added ? Icons.favorite_rounded : Icons.heart_broken_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = context.select<WishlistProvider, bool>((w) => w.isWishlisted(widget.product.id));
    return Semantics(
      button: true,
      label: active ? 'Hapus dari wishlist' : 'Tambah ke wishlist',
      child: GestureDetector(
        onTap: _toggle,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            shape: BoxShape.circle,
            boxShadow: AppColors.softShadow,
          ),
          child: ScaleTransition(
            scale: _scale,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
              child: Icon(
                active ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                key: ValueKey(active),
                size: widget.size * 0.55,
                color: active ? AppColors.pinkDeep : AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
