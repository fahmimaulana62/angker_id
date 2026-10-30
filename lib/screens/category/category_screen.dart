import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/category_model.dart';
import '../../providers/category_provider.dart';
import '../../widgets/animated_entry.dart';
import '../../widgets/product_grid_shimmer.dart' show ShimmerBox;
import '../../widgets/state_views.dart';
import '../shell/main_shell.dart';

/// Ikon Material yang cocok untuk tiap slug kategori DummyJSON.
IconData categoryIcon(String slug) {
  const map = <String, IconData>{
    'beauty': Icons.face_retouching_natural_rounded,
    'fragrances': Icons.spa_rounded,
    'furniture': Icons.chair_rounded,
    'groceries': Icons.local_grocery_store_rounded,
    'home-decoration': Icons.home_rounded,
    'kitchen-accessories': Icons.kitchen_rounded,
    'laptops': Icons.laptop_mac_rounded,
    'mens-shirts': Icons.checkroom_rounded,
    'mens-shoes': Icons.directions_walk_rounded,
    'mens-watches': Icons.watch_rounded,
    'mobile-accessories': Icons.headphones_rounded,
    'motorcycle': Icons.two_wheeler_rounded,
    'skin-care': Icons.water_drop_rounded,
    'smartphones': Icons.smartphone_rounded,
    'sports-accessories': Icons.sports_basketball_rounded,
    'sunglasses': Icons.wb_sunny_rounded,
    'tablets': Icons.tablet_mac_rounded,
    'tops': Icons.dry_cleaning_rounded,
    'vehicle': Icons.directions_car_rounded,
    'womens-bags': Icons.shopping_bag_rounded,
    'womens-dresses': Icons.woman_rounded,
    'womens-jewellery': Icons.diamond_rounded,
    'womens-shoes': Icons.ice_skating_rounded,
    'womens-watches': Icons.watch_later_rounded,
  };
  return map[slug] ?? Icons.category_rounded;
}

/// Tab Kategori: GET /products/categories.
class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CategoryProvider>().fetchCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoryProvider>();
    final categories = provider.categories;
    final topPad = MediaQuery.paddingOf(context).top;

    Widget content;
    if (provider.loadingCategories && categories.isEmpty) {
      content = SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: _delegate,
          delegate: SliverChildBuilderDelegate(
            (_, __) => Shimmer.fromColors(
              baseColor: AppColors.pinkTint,
              highlightColor: Colors.white,
              child: const ShimmerBox(radius: 22),
            ),
            childCount: 8,
          ),
        ),
      );
    } else if (provider.categoriesError != null && categories.isEmpty) {
      content = SliverFillRemaining(
        hasScrollBody: false,
        child: ErrorState(
          message: provider.categoriesError!,
          onRetry: () => provider.fetchCategories(force: true),
        ),
      );
    } else {
      content = SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: _delegate,
          delegate: SliverChildBuilderDelegate(
            (context, i) => AnimatedEntry(
              key: ValueKey('cat-${categories[i].slug}'),
              id: 'cat-${categories[i].slug}',
              index: i,
              staggerMs: 30,
              child: _CategoryCard(category: categories[i], index: i),
            ),
            childCount: categories.length,
          ),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.pinkDeep,
        edgeOffset: topPad,
        onRefresh: () => provider.fetchCategories(force: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, topPad + 16, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOKO HANTU LUCU 👻', style: AppText.label(10.5, color: AppColors.primary).copyWith(letterSpacing: 1.2)),
                    Text('Kategori', style: AppText.heading(26, weight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      categories.isEmpty
                          ? 'Jelajahi produk berdasarkan kategori'
                          : '${categories.length} kategori asli dari DummyJSON',
                      style: AppText.body(14, color: AppColors.plumMuted),
                    ),
                  ],
                ),
              ),
            ),
            content,
            const SliverToBoxAdapter(child: SizedBox(height: kNavBarClearance + 20)),
          ],
        ),
      ),
    );
  }

  static const _delegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
    childAspectRatio: 1.25,
  );
}

class _CategoryCard extends StatefulWidget {
  const _CategoryCard({required this.category, required this.index});

  final ProductCategory category;
  final int index;

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _pressed = false;

  static const _bg = [AppColors.pinkTint, AppColors.blue, AppColors.mint, AppColors.cream];
  static const _fg = [AppColors.primary, AppColors.onBlue, AppColors.onMint, AppColors.warning];

  @override
  Widget build(BuildContext context) {
    final i = widget.index % 4;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () => context.push(AppRoutes.category(widget.category.slug)),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _bg[i],
            borderRadius: BorderRadius.circular(22),
            boxShadow: AppColors.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(14)),
                child: Icon(categoryIcon(widget.category.slug), color: _fg[i]),
              ),
              const Spacer(),
              Text(
                widget.category.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.heading(15, height: 1.2),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text('Lihat produk', style: AppText.label(11.5, color: _fg[i])),
                  Icon(Icons.chevron_right_rounded, size: 16, color: _fg[i]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
