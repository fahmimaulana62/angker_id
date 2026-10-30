import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/product_model.dart';
import '../../models/sort_option.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/api_service_products.dart';
import '../../widgets/animated_entry.dart';
import '../../widgets/product_card.dart';
import '../../widgets/product_grid_shimmer.dart';
import '../../widgets/sort_sheet.dart';
import '../../widgets/state_views.dart';
import 'category_screen.dart' show categoryIcon;

/// Produk per kategori: GET /products/category/{slug} (+ sortBy & order).
class CategoryProductsScreen extends StatefulWidget {
  const CategoryProductsScreen({super.key, required this.slug});

  final String slug;

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  List<Product> _products = [];
  bool _loading = true;
  String? _error;
  SortOption _sort = SortOption.none;

  @override
  void initState() {
    super.initState();
    _load(initial: true);
  }

  Future<void> _load({bool initial = false}) async {
    if (!initial) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final list = await context.read<ProductProvider>().fetchCategoryProducts(widget.slug, _sort);
      if (!mounted) return;
      setState(() {
        _products = list;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _openSort() async {
    final picked = await showSortSheet(context, _sort);
    if (picked == null || picked == _sort) return;
    _sort = picked;
    AnimatedEntry.reset('catp-');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild saat ada perubahan CRUD lokal agar produk yang dihapus/diedit ikut berubah.
    final productProvider = context.watch<ProductProvider>();
    final name = context.read<CategoryProvider>().nameFor(widget.slug);
    final products = productProvider.applyLocalChanges(
      _products,
      includeLocal: (p) => p.category == widget.slug,
    );

    Widget content;
    if (_loading && _products.isEmpty) {
      content = const SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        sliver: ProductGridShimmerSliver(count: 6),
      );
    } else if (_error != null && _products.isEmpty) {
      content = SliverFillRemaining(hasScrollBody: false, child: ErrorState(message: _error!, onRetry: _load));
    } else if (products.isEmpty) {
      content = const SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          icon: Icons.inventory_2_outlined,
          title: 'Kategori ini kosong',
          message: 'Belum ada produk di kategori ini.',
        ),
      );
    } else {
      content = SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        sliver: SliverAnimatedOpacity(
          opacity: _loading ? 0.45 : 1,
          duration: const Duration(milliseconds: 200),
          sliver: SliverGrid(
            gridDelegate: productGridDelegate(context),
            delegate: SliverChildBuilderDelegate(
              (context, i) => AnimatedEntry(
                key: ValueKey('catp-${products[i].id}'),
                id: 'catp-${widget.slug}-${_sort.name}-${products[i].id}',
                index: i,
                child: ProductCard(product: products[i], heroScope: 'cat'),
              ),
              childCount: products.length,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.pinkDeep,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 150,
              backgroundColor: AppColors.background,
              surfaceTintColor: Colors.transparent,
              title: Text(name, style: AppText.heading(18)),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.pinkTint, AppColors.blue],
                    ),
                  ),
                  alignment: Alignment.bottomRight,
                  padding: const EdgeInsets.fromLTRB(16, 0, 20, 16),
                  child: Icon(categoryIcon(widget.slug), size: 64, color: AppColors.primary.withValues(alpha: 0.25)),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: AppColors.mintDeep, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _loading && _products.isEmpty ? 'Memuat...' : '${products.length} produk',
                        style: AppText.body(14, weight: FontWeight.w600),
                      ),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.swap_vert_rounded, size: 16, color: AppColors.primary),
                      label: Text(_sort.label, style: AppText.label(12)),
                      backgroundColor: AppColors.pinkTint,
                      side: BorderSide.none,
                      shape: const StadiumBorder(),
                      onPressed: _openSort,
                    ),
                  ],
                ),
              ),
            ),
            content,
          ],
        ),
      ),
    );
  }
}
