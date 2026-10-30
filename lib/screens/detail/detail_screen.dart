import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../services/api_service_products.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/cart_actions.dart';
import '../../widgets/product_card.dart' show StockBadge;
import '../../widgets/product_grid_shimmer.dart' show ShimmerBox;
import '../../widgets/quantity_stepper.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/sort_sheet.dart' show SheetContainer;
import '../../widgets/state_views.dart';
import '../../widgets/wishlist_button.dart';

/// Halaman detail produk: GET /products/{id}.
class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.productId, this.heroTag});

  final int productId;
  final String? heroTag;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final ScrollController _scroll = ScrollController();
  final PageController _pageController = PageController();
  final ValueNotifier<int> _page = ValueNotifier<int>(0);
  final ValueNotifier<bool> _collapsed = ValueNotifier<bool>(false);

  Product? _product;
  bool _loadingFull = true;
  String? _error;
  int _qty = 1;
  bool _busy = false;

  static const double _expandedHeight = 380;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ProductProvider>();
    _product = provider.peek(widget.productId);
    _scroll.addListener(() {
      final collapsed = _scroll.hasClients && _scroll.offset > _expandedHeight - 140;
      if (collapsed != _collapsed.value) _collapsed.value = collapsed;
    });
    _load(initial: true);
  }

  Future<void> _load({bool force = false, bool initial = false}) async {
    if (!initial) {
      setState(() {
        _loadingFull = true;
        _error = null;
      });
    }
    try {
      final full = await context.read<ProductProvider>().getProductDetail(widget.productId, forceRefresh: force);
      if (!mounted) return;
      setState(() {
        _product = full;
        _loadingFull = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loadingFull = false;
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _pageController.dispose();
    _page.dispose();
    _collapsed.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Aksi
  // ---------------------------------------------------------------------------

  void _share(Product p) {
    Clipboard.setData(ClipboardData(text: '${p.title} cuma ${Fmt.price(p.price)} di Angker.id 👻'));
    showAppSnack(context, 'Info produk disalin ke clipboard', icon: Icons.copy_rounded);
  }

  Future<void> _onMenu(_MenuAction action, Product p) async {
    switch (action) {
      case _MenuAction.edit:
        await context.push(AppRoutes.editProduct(p.id));
      case _MenuAction.patch:
        await _showPatchSheet(p);
      case _MenuAction.delete:
        await _confirmDelete(p);
    }
  }

  Future<void> _showPatchSheet(Product p) async {
    final result = await showModalBottomSheet<({int stock, double price})>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PatchSheet(product: p),
    );
    if (result == null || !mounted) return;

    setState(() => _busy = true);
    try {
      // PATCH /products/{id}
      final updated = await context.read<ProductProvider>().patchProduct(
            p.id,
            stock: result.stock,
            price: result.price,
          );
      if (!mounted) return;
      context.read<WishlistProvider>().sync(updated);
      context.read<CartProvider>().sync(updated);
      showAppSnack(context, 'Stok & harga diperbarui ($kMockNote)', icon: Icons.inventory_2_rounded);
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.message, isError: true, icon: Icons.error_rounded);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDelete(Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(color: AppColors.dangerSoft, shape: BoxShape.circle),
          child: const Icon(Icons.delete_forever_rounded, color: AppColors.danger, size: 30),
        ),
        title: Text('Hapus produk ini?', style: AppText.heading(18)),
        content: Text(
          '"${p.title}" akan dihapus dari katalog, wishlist, dan keranjang.',
          textAlign: TextAlign.center,
          style: AppText.body(14, color: AppColors.plumMuted),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Batal', style: AppText.label(14, color: AppColors.plum)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Hapus', style: AppText.label(14, color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    try {
      // DELETE /products/{id}
      final deletedOn = await context.read<ProductProvider>().deleteProduct(p.id);
      if (!mounted) return;
      context.read<WishlistProvider>().remove(p.id);
      context.read<CartProvider>().remove(p.id);
      showAppSnack(
        context,
        'Produk dihapus pada ${Fmt.date(deletedOn)} ($kMockNote)',
        icon: Icons.delete_rounded,
        duration: const Duration(seconds: 3),
      );
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showAppSnack(context, e.message, isError: true, icon: Icons.error_rounded);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Ambil versi terbaru bila produk diedit (PUT/PATCH) dari layar lain.
    final latest = context.select<ProductProvider, Product?>((p) => p.fullProduct(widget.productId));
    final deleted = context.select<ProductProvider, bool>((p) => p.isDeleted(widget.productId));
    final product = latest ?? _product;

    if (deleted && !_busy) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.delete_outline_rounded,
          title: 'Produk sudah dihapus',
          message: 'Produk ini tidak tersedia lagi di katalog.',
          actionLabel: 'Kembali',
          onAction: () => context.pop(),
        ),
      );
    }

    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Detail Produk', style: AppText.heading(18))),
        body: _error != null
            ? ErrorState(message: _error!, onRetry: _load)
            : const _DetailSkeleton(),
      );
    }

    final hasFull = latest != null || !_loadingFull;
    final maxQty = product.stock < 1 ? 1 : product.stock;
    if (_qty > maxQty) _qty = maxQty;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scroll,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(product),
              SliverToBoxAdapter(
                child: _DetailContent(
                  product: product,
                  hasFull: hasFull,
                  error: _error,
                  onRetry: () => _load(force: true),
                ),
              ),
            ],
          ),
          if (_busy)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.white.withValues(alpha: 0.5),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _BuyBar(
        product: product,
        quantity: _qty,
        onQuantityChanged: (v) => setState(() => _qty = v),
      ),
    );
  }

  Widget _buildAppBar(Product p) {
    final gallery = p.gallery;
    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: _expandedHeight,
      backgroundColor: AppColors.blue,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: _CircleIconButton(icon: Icons.arrow_back_rounded, onTap: () => context.pop()),
      ),
      title: ValueListenableBuilder<bool>(
        valueListenable: _collapsed,
        builder: (context, collapsed, _) => AnimatedOpacity(
          opacity: collapsed ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.heading(16)),
        ),
      ),
      actions: [
        _CircleIconButton(icon: Icons.share_rounded, onTap: () => _share(p)),
        const SizedBox(width: 8),
        WishlistButton(product: p, size: 40),
        const SizedBox(width: 8),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            shape: BoxShape.circle,
            boxShadow: AppColors.softShadow,
          ),
          child: PopupMenuButton<_MenuAction>(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.plum, size: 22),
            color: AppColors.background,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            onSelected: (a) => _onMenu(a, p),
            itemBuilder: (context) => [
              _menuItem(_MenuAction.edit, Icons.edit_rounded, 'Edit Produk (PUT)'),
              _menuItem(_MenuAction.patch, Icons.inventory_2_rounded, 'Update Stok Cepat (PATCH)'),
              _menuItem(_MenuAction.delete, Icons.delete_rounded, 'Hapus Produk (DELETE)', danger: true),
            ],
          ),
        ),
        const SizedBox(width: 12),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(24),
        child: Container(
          height: 24,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: AppColors.blue),
            Padding(
              padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 56, bottom: 40),
              child: gallery.isEmpty
                  ? const Icon(Icons.image_not_supported_rounded, size: 48, color: AppColors.pinkDeep)
                  : PageView.builder(
                      controller: _pageController,
                      itemCount: gallery.length,
                      onPageChanged: (i) => _page.value = i,
                      itemBuilder: (context, i) {
                        final image = Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: AppNetworkImage(
                            url: gallery[i],
                            cacheWidth: 900,
                            background: Colors.transparent,
                            keepOldImageOnChange: true,
                          ),
                        );
                        if (i == 0 && widget.heroTag != null) {
                          return Hero(tag: widget.heroTag!, child: image);
                        }
                        return image;
                      },
                    ),
            ),
            Positioned(
              left: 16,
              right: 16,
              top: MediaQuery.paddingOf(context).top + 60,
              child: Row(
                children: [
                  if (p.hasDiscount)
                    _GlassChip(
                      icon: Icons.sell_rounded,
                      text: 'HEMAT -${p.discountPercentage.round()}%',
                      color: AppColors.mint,
                    ),
                  const Spacer(),
                  if (gallery.length > 1)
                    ValueListenableBuilder<int>(
                      valueListenable: _page,
                      builder: (context, page, _) => _GlassChip(
                        text: '${page + 1} / ${gallery.length} Foto',
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
            if (gallery.length > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: 38,
                child: ValueListenableBuilder<int>(
                  valueListenable: _page,
                  builder: (context, page, _) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(gallery.length, (i) {
                      final active = i == page;
                      return GestureDetector(
                        onTap: () => _pageController.animateToPage(
                          i,
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: active ? 26 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: active ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<_MenuAction> _menuItem(_MenuAction a, IconData icon, String text, {bool danger = false}) {
    final color = danger ? AppColors.danger : AppColors.plum;
    return PopupMenuItem<_MenuAction>(
      value: a,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Text(text, style: AppText.label(13.5, color: color, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

enum _MenuAction { edit, patch, delete }

// =============================================================================
// Isi detail
// =============================================================================

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.product,
    required this.hasFull,
    required this.error,
    required this.onRetry,
  });

  final Product product;
  final bool hasFull;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final p = product;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Pill(text: Fmt.prettyCategory(p.category), color: AppColors.blue, textColor: AppColors.onBlue),
              if (p.brand.isNotEmpty) _Pill(text: p.brand, color: AppColors.pinkTint, textColor: AppColors.primary),
              const _Pill(
                text: 'Original 100%',
                color: AppColors.mint,
                textColor: AppColors.onMint,
                icon: Icons.verified_rounded,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(p.title, style: AppText.heading(22, weight: FontWeight.w800, height: 1.25)),
          const SizedBox(height: 8),
          Row(
            children: [
              RatingStars(rating: p.rating, size: 18),
              const SizedBox(width: 6),
              Text(Fmt.rating(p.rating), style: AppText.heading(15, weight: FontWeight.w800)),
              if (p.reviews.isNotEmpty) ...[
                _dot(),
                Flexible(
                  child: Text('${p.reviews.length} ulasan pembeli',
                      overflow: TextOverflow.ellipsis, style: AppText.body(13, color: AppColors.plumMuted)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          _PriceBox(product: p),
          const SizedBox(height: 24),
          if (error != null && !hasFull)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded, color: AppColors.danger),
                  const SizedBox(width: 10),
                  Expanded(child: Text(error!, style: AppText.body(13, color: AppColors.danger))),
                  TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
                ],
              ),
            ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: hasFull
                ? _FullSections(key: const ValueKey('full'), product: p)
                : const _SectionsSkeleton(key: ValueKey('skeleton')),
          ),
        ],
      ),
    );
  }

  Widget _dot() => Container(
        width: 4,
        height: 4,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: const BoxDecoration(color: AppColors.outline, shape: BoxShape.circle),
      );
}

class _PriceBox extends StatelessWidget {
  const _PriceBox({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final p = product;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pinkTint,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.pinkSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 6,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(Fmt.price(p.price), key: ValueKey(p.price), style: AppText.price(28)),
              ),
              if (p.hasDiscount)
                Text(
                  Fmt.price(p.originalPrice),
                  style: AppText.body(15, color: AppColors.plumMuted).copyWith(
                    decoration: TextDecoration.lineThrough,
                    decorationColor: AppColors.plumMuted,
                  ),
                ),
              if (p.hasDiscount)
                _Pill(text: 'Hemat ${Fmt.price(p.savings)}', color: AppColors.pink, textColor: AppColors.primary),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (p.inStock)
                StockBadge(product: p, dense: false)
              else
                const _Pill(
                  text: 'Stok Habis',
                  color: AppColors.dangerSoft,
                  textColor: AppColors.danger,
                  icon: Icons.block_rounded,
                ),
              if (p.shippingInformation.isNotEmpty)
                Text(p.shippingInformation, style: AppText.body(13, color: AppColors.plumMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FullSections extends StatelessWidget {
  const _FullSections({super.key, required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final p = product;
    final specs = <_Spec>[
      if (p.warrantyInformation.isNotEmpty) _Spec(Icons.verified_user_outlined, 'Garansi', p.warrantyInformation),
      if (p.shippingInformation.isNotEmpty) _Spec(Icons.local_shipping_outlined, 'Estimasi Kirim', p.shippingInformation),
      if (p.returnPolicy.isNotEmpty) _Spec(Icons.assignment_return_outlined, 'Retur', p.returnPolicy),
      _Spec(Icons.shopping_basket_outlined, 'Min. Order', '${p.minimumOrderQuantity} pcs'),
      if (p.weight > 0) _Spec(Icons.scale_outlined, 'Berat', '${_num(p.weight)} kg'),
      if (!p.dimensions.isEmpty)
        _Spec(
          Icons.straighten_rounded,
          'Dimensi',
          '${_num(p.dimensions.width)} × ${_num(p.dimensions.height)} × ${_num(p.dimensions.depth)} cm',
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Deskripsi Produk', style: AppText.heading(18)),
        const SizedBox(height: 8),
        _ExpandableText(text: p.description.isEmpty ? 'Belum ada deskripsi.' : p.description),
        const SizedBox(height: 24),
        Text('Spesifikasi Detail', style: AppText.heading(18)),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, c) {
            final w = (c.maxWidth - 10) / 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var i = 0; i < specs.length; i++)
                  SizedBox(
                    width: w,
                    child: _SpecTile(spec: specs[i], color: _specColor(i)),
                  ),
              ],
            );
          },
        ),
        if (p.sku.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: AppColors.pinkTint, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Text('Kode Produk (SKU)', style: AppText.label(13, weight: FontWeight.w600)),
                const Spacer(),
                Text(p.sku, style: AppText.label(13.5, weight: FontWeight.w800).copyWith(letterSpacing: 1)),
              ],
            ),
          ),
        ],
        if (p.tags.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Kategori Tag', style: AppText.label(13, color: AppColors.plumMuted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: p.tags.map((t) => _Pill(text: '#$t', color: AppColors.pinkTint, textColor: AppColors.primary)).toList(),
          ),
        ],
        const SizedBox(height: 28),
        _ReviewsSection(product: p),
      ],
    );
  }

  static Color _specColor(int i) {
    const colors = [AppColors.pinkTint, AppColors.blue, AppColors.mint, AppColors.pinkTint, AppColors.pinkTint, AppColors.blue];
    return colors[i % colors.length];
  }

  static String _num(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
}

class _Spec {
  final IconData icon;
  final String label;
  final String value;
  const _Spec(this.icon, this.label, this.value);
}

class _SpecTile extends StatelessWidget {
  const _SpecTile({required this.spec, required this.color});
  final _Spec spec;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 66),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(spec.icon, size: 15, color: AppColors.plumMuted),
              const SizedBox(width: 5),
              Flexible(
                child: Text(spec.label,
                    overflow: TextOverflow.ellipsis, style: AppText.body(12, color: AppColors.plumMuted, weight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(spec.value, style: AppText.label(13.5, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Deskripsi 3 baris dengan "Baca selengkapnya" (AnimatedSize).
class _ExpandableText extends StatefulWidget {
  const _ExpandableText({required this.text});
  final String text;

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final style = AppText.body(14.5, color: AppColors.plum, height: 1.55);
    return LayoutBuilder(builder: (context, constraints) {
      final painter = TextPainter(
        text: TextSpan(text: widget.text, style: style),
        maxLines: 3,
        textDirection: TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: constraints.maxWidth);
      final overflow = painter.didExceedMaxLines;
      painter.dispose();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: Text(
              widget.text,
              maxLines: _expanded ? null : 3,
              overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
              style: style,
            ),
          ),
          if (overflow)
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_expanded ? 'Tutup' : 'Baca selengkapnya', style: AppText.label(13, color: AppColors.primary)),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    });
  }
}

class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final p = product;
    final dist = p.starDistribution;
    final maxCount = dist.fold<int>(0, (m, v) => v > m ? v : m);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Ulasan Pembeli', action: p.reviews.isEmpty ? null : '${p.reviews.length} ulasan'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.pinkTint,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Column(
                children: [
                  Text(p.rating.toStringAsFixed(1), style: AppText.price(40)),
                  RatingStars(rating: p.rating, size: 15),
                  const SizedBox(height: 4),
                  Text('${p.reviews.length} ulasan', style: AppText.body(12, color: AppColors.plumMuted)),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: List.generate(5, (k) {
                    final star = 5 - k;
                    final count = dist[star - 1];
                    final ratio = maxCount == 0 ? 0.0 : count / maxCount;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          SizedBox(width: 12, child: Text('$star', style: AppText.label(12))),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Stack(
                                children: [
                                  Container(height: 8, color: Colors.white),
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0, end: ratio),
                                    duration: Duration(milliseconds: 500 + k * 80),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, v, _) => FractionallySizedBox(
                                      widthFactor: v,
                                      child: Container(height: 8, color: AppColors.primary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 18,
                            child: Text('$count', textAlign: TextAlign.right, style: AppText.body(12, color: AppColors.plumMuted)),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (p.reviews.isEmpty)
          Text('Belum ada ulasan untuk produk ini.', style: AppText.body(14, color: AppColors.plumMuted))
        else
          ...List.generate(p.reviews.length, (i) => _ReviewTile(review: p.reviews[i], index: i)),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review, required this.index});
  final Review review;
  final int index;

  @override
  Widget build(BuildContext context) {
    final r = review;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.pinkSoft),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InitialAvatar(
                text: Fmt.initials(r.reviewerName),
                color: AppColors.pastelCycle[index % AppColors.pastelCycle.length],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.reviewerName.isEmpty ? 'Pembeli' : r.reviewerName,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.heading(15)),
                    if (r.date.isNotEmpty)
                      Text(Fmt.date(r.date), style: AppText.body(12, color: AppColors.plumMuted)),
                  ],
                ),
              ),
              RatingStars(rating: r.rating.toDouble(), size: 15),
            ],
          ),
          const SizedBox(height: 10),
          Text('"${r.comment}"', style: AppText.body(14.5, height: 1.5)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, size: 15, color: AppColors.mintDeep),
              const SizedBox(width: 5),
              Text('Pembelian Terverifikasi', style: AppText.label(11.5, color: AppColors.onMint)),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Bottom bar beli
// =============================================================================

class _BuyBar extends StatefulWidget {
  const _BuyBar({required this.product, required this.quantity, required this.onQuantityChanged});

  final Product product;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;

  @override
  State<_BuyBar> createState() => _BuyBarState();
}

class _BuyBarState extends State<_BuyBar> with SingleTickerProviderStateMixin {
  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.92), weight: 30),
    TweenSequenceItem(
      tween: Tween(begin: 0.92, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)),
      weight: 70,
    ),
  ]).animate(_bounce);

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  void _add() {
    _bounce.forward(from: 0);
    addToCartWithFeedback(context, widget.product, quantity: widget.quantity);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final inCart = context.select<CartProvider, int>((c) => c.quantityOf(p.id));
    final total = p.price * widget.quantity;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: AppColors.plum.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, -6)),
        ],
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            child: inCart > 0
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.shopping_bag_rounded, size: 15, color: AppColors.mintDeep),
                        const SizedBox(width: 6),
                        Text('Sudah ada $inCart di keranjang', style: AppText.body(12.5, color: AppColors.onMint, weight: FontWeight.w700)),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          Row(
            children: [
              QuantityStepper(
                value: widget.quantity,
                max: p.stock < 1 ? 1 : p.stock,
                onChanged: widget.onQuantityChanged,
                onMaxReached: () => showAppSnack(
                  context,
                  p.inStock ? 'Stok hanya tersisa ${p.stock}' : 'Stok produk ini habis',
                  icon: Icons.inventory_2_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ScaleTransition(
                  scale: _scale,
                  child: PrimaryButton(
                    label: p.inStock ? 'Tambah · ${Fmt.price(total)}' : 'Stok Habis',
                    icon: p.inStock ? Icons.shopping_bag_rounded : Icons.block_rounded,
                    onPressed: p.inStock ? _add : null,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Bottom sheet PATCH
// =============================================================================

class _PatchSheet extends StatefulWidget {
  const _PatchSheet({required this.product});
  final Product product;

  @override
  State<_PatchSheet> createState() => _PatchSheetState();
}

class _PatchSheetState extends State<_PatchSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _stock = TextEditingController(text: '${widget.product.stock}');
  late final TextEditingController _price = TextEditingController(text: widget.product.price.toStringAsFixed(2));

  @override
  void dispose() {
    _stock.dispose();
    _price.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop((
      stock: int.parse(_stock.text.trim()),
      price: double.parse(_price.text.trim().replaceAll(',', '.')),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SheetContainer(
      title: 'Update Stok Cepat',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mengirim PATCH /products/${widget.product.id} hanya untuk field stok & harga.',
              style: AppText.body(13, color: AppColors.plumMuted),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _stock,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Stok', prefixIcon: Icon(Icons.inventory_2_outlined)),
              validator: (v) {
                final n = int.tryParse((v ?? '').trim());
                if (n == null) return 'Stok wajib berupa angka';
                if (n < 0) return 'Stok tidak boleh negatif';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Harga (USD)', prefixIcon: Icon(Icons.attach_money_rounded)),
              validator: (v) {
                final n = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
                if (n == null) return 'Harga wajib berupa angka';
                if (n <= 0) return 'Harga harus lebih dari 0';
                return null;
              },
            ),
            const SizedBox(height: 20),
            PrimaryButton(label: 'Simpan Perubahan', icon: Icons.check_rounded, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Komponen kecil
// =============================================================================

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.white.withValues(alpha: 0.92),
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 40, height: 40, child: Icon(icon, color: AppColors.plum, size: 22)),
        ),
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.text, required this.color, this.icon});
  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: AppColors.onMint),
            const SizedBox(width: 4),
          ],
          Text(text, style: AppText.label(11.5)),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color, required this.textColor, this.icon});
  final String text;
  final Color color;
  final Color textColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(50)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(text, style: AppText.label(12, color: textColor)),
        ],
      ),
    );
  }
}

class _SectionsSkeleton extends StatelessWidget {
  const _SectionsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.pinkTint,
      highlightColor: Colors.white,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: 160, height: 18),
          SizedBox(height: 12),
          ShimmerBox(height: 12),
          SizedBox(height: 8),
          ShimmerBox(height: 12),
          SizedBox(height: 8),
          ShimmerBox(width: 220, height: 12),
          SizedBox(height: 24),
          ShimmerBox(width: 160, height: 18),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: ShimmerBox(height: 64, radius: 16)),
              SizedBox(width: 10),
              Expanded(child: ShimmerBox(height: 64, radius: 16)),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: ShimmerBox(height: 64, radius: 16)),
              SizedBox(width: 10),
              Expanded(child: ShimmerBox(height: 64, radius: 16)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.pinkTint,
      highlightColor: Colors.white,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          ShimmerBox(height: 300, radius: 24),
          SizedBox(height: 20),
          ShimmerBox(width: 120, height: 14),
          SizedBox(height: 12),
          ShimmerBox(height: 22),
          SizedBox(height: 8),
          ShimmerBox(width: 200, height: 22),
          SizedBox(height: 16),
          ShimmerBox(height: 90, radius: 20),
        ],
      ),
    );
  }
}
