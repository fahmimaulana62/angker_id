import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/sort_option.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/animated_entry.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/product_card.dart';
import '../../widgets/product_grid_shimmer.dart';
import '../../widgets/search_bar_shell.dart';
import '../../widgets/sort_sheet.dart';
import '../../widgets/state_views.dart';
import '../shell/main_shell.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scroll = ScrollController();
  bool _fabExtended = true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final products = context.read<ProductProvider>();
      if (!products.initialized && !products.isLoading) products.fetchInitial();
      context.read<CategoryProvider>().fetchCategoryList();
    });
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scroll.position;
    // Infinite scroll: muat halaman berikutnya saat mendekati bawah (>= 85%).
    if (pos.maxScrollExtent > 0 && pos.pixels >= pos.maxScrollExtent * 0.85) {
      context.read<ProductProvider>().loadMore();
    }
    // FAB menyusut saat scroll ke bawah, melebar lagi saat scroll ke atas.
    final dir = pos.userScrollDirection;
    if (dir == ScrollDirection.reverse && _fabExtended && pos.pixels > 80) {
      setState(() => _fabExtended = false);
    } else if (dir == ScrollDirection.forward && !_fabExtended) {
      setState(() => _fabExtended = true);
    }
  }

  Future<void> _refresh() async {
    AnimatedEntry.reset('home-');
    await context.read<ProductProvider>().refresh();
  }

  Future<void> _openSort() async {
    final provider = context.read<ProductProvider>();
    final picked = await showSortSheet(context, provider.sort);
    if (picked != null) {
      provider.setSort(picked);
      if (_scroll.hasClients && _scroll.offset > 600) {
        _scroll.animateTo(520, duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final products = provider.products;
    final topPad = MediaQuery.paddingOf(context).top;
    final animKey = '${provider.selectedCategory ?? 'all'}-${provider.sort.name}';

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 84),
        child: _AddProductFab(extended: _fabExtended),
      ),
      body: RefreshIndicator(
        color: AppColors.pinkDeep,
        backgroundColor: Colors.white,
        edgeOffset: topPad,
        onRefresh: _refresh,
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: topPad + 8)),
            const SliverToBoxAdapter(child: _HomeHeader()),
            const SliverToBoxAdapter(child: _GreetingCard()),
            const SliverToBoxAdapter(child: _PromoBanner()),
            const SliverToBoxAdapter(child: _CategoryChips()),
            SliverToBoxAdapter(
              child: _InfoRow(
                total: provider.displayTotal,
                loading: provider.isLoading && products.isEmpty,
                sort: provider.sort,
                onSort: _openSort,
              ),
            ),
            if (provider.isLoading && products.isEmpty)
              const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                sliver: ProductGridShimmerSliver(),
              )
            else if (provider.error != null && products.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: ErrorState(message: provider.error!, onRetry: provider.fetchInitial),
                ),
              )
            else if (products.isEmpty)
              const SliverToBoxAdapter(
                child: EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'Belum ada produk',
                  message: 'Coba pilih kategori lain atau tarik ke bawah untuk memuat ulang.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverAnimatedOpacity(
                  opacity: provider.isLoading ? 0.45 : 1,
                  duration: const Duration(milliseconds: 200),
                  sliver: SliverGrid(
                    gridDelegate: productGridDelegate(context),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final p = products[index];
                        return AnimatedEntry(
                          key: ValueKey('home-${p.id}'),
                          id: 'home-$animKey-${p.id}',
                          index: index % ProductProvider.pageSize,
                          child: ProductCard(product: p, heroScope: 'home'),
                        );
                      },
                      childCount: products.length,
                      findChildIndexCallback: (key) {
                        if (key is ValueKey<String>) {
                          final id = int.tryParse(key.value.substring(5));
                          final i = products.indexWhere((p) => p.id == id);
                          return i == -1 ? null : i;
                        }
                        return null;
                      },
                    ),
                  ),
                ),
              ),
            SliverToBoxAdapter(child: _ListFooter(provider: provider)),
            const SliverToBoxAdapter(child: SizedBox(height: kNavBarClearance + 40)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 12, 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.pink, AppColors.blue]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text('👻', style: TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TOKO HANTU LUCU', style: AppText.label(10.5, color: AppColors.primary).copyWith(letterSpacing: 1.2)),
                Text('Angker.id', style: AppText.heading(22, weight: FontWeight.w800)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => showAppSnack(context, 'Belum ada notifikasi baru 👻', icon: Icons.notifications_none_rounded),
            icon: const Icon(Icons.notifications_none_rounded, color: AppColors.plum),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  const _GreetingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.pink.withValues(alpha: 0.75), AppColors.pinkTint, AppColors.blue],
        ),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SPOOKY CUTE SHOPPING',
                        style: AppText.label(10.5, color: AppColors.primary).copyWith(letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text('Halo, mau cari apa hari ini? ✨', style: AppText.heading(19, height: 1.25)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const _BobbingGhost(),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => context.push(AppRoutes.search),
            child: const Hero(
              tag: kSearchHeroTag,
              child: SearchBarShell(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hantu kecil yang mengambang naik-turun (animasi loop ringan).
class _BobbingGhost extends StatefulWidget {
  const _BobbingGhost();

  @override
  State<_BobbingGhost> createState() => _BobbingGhostState();
}

class _BobbingGhostState extends State<_BobbingGhost> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);
  late final Animation<double> _y = _c.drive(CurveTween(curve: Curves.easeInOutSine));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _y,
        builder: (context, child) => Transform.translate(offset: Offset(0, -4 + 8 * _y.value), child: child),
        child: Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: AppColors.softShadow,
          ),
          child: const Text('👻', style: TextStyle(fontSize: 26)),
        ),
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    final deal = context.select<ProductProvider, ({int id, String title, double discount})?>((p) {
      final d = p.bestDeal;
      return d == null ? null : (id: d.id, title: d.title, discount: d.discountPercentage);
    });

    return GestureDetector(
      onTap: deal == null ? null : () => context.push(AppRoutes.detail(deal.id)),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.mint,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.mintDeep.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department_rounded, size: 14, color: AppColors.onMint),
                        const SizedBox(width: 4),
                        Text(
                          deal == null ? 'Diskon Merinding' : 'Diskon Merinding s.d ${deal.discount.round()}%',
                          style: AppText.label(11, color: AppColors.onMint),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('Promo Hantu Imut Akhir Pekan! 🎃', style: AppText.heading(18, height: 1.25)),
                  const SizedBox(height: 4),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      deal == null ? 'Beli kosmetik & gadget, dapet voucher mistis.' : 'Paling hemat: ${deal.title}',
                      key: ValueKey(deal?.id),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(13, color: AppColors.onMint, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Transform.rotate(
              angle: 0.12,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: AppColors.softShadow,
                ),
                child: const Icon(Icons.card_giftcard_rounded, color: AppColors.primary, size: 32),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips();

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>();
    final selected = context.select<ProductProvider, String?>((p) => p.selectedCategory);
    final list = categories.categoryList;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
          child: SectionHeader(
            title: 'Kategori Pilihan',
            action: 'Lihat Semua',
            onAction: () => context.go(AppRoutes.categories),
          ),
        ),
        SizedBox(
          height: 42,
          child: categories.loadingList && list.isEmpty
              ? ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 5,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, __) => Container(
                    width: 90,
                    decoration: BoxDecoration(color: AppColors.pinkTint, borderRadius: BorderRadius.circular(50)),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final slug = i == 0 ? null : list[i - 1];
                    return PastelChip(
                      label: slug == null ? 'Semua' : Fmt.prettyCategory(slug),
                      icon: slug == null ? Icons.auto_awesome_rounded : null,
                      selected: selected == slug,
                      onTap: () => context.read<ProductProvider>().filterByCategory(slug),
                    );
                  },
                ),
        ),
        if (categories.listError != null && list.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: GestureDetector(
              onTap: () => context.read<CategoryProvider>().fetchCategoryList(force: true),
              child: Text('Gagal memuat kategori. Ketuk untuk coba lagi.',
                  style: AppText.body(12, color: AppColors.danger)),
            ),
          ),
      ],
    );
  }
}

/// Chip pill pastel: aktif = pink, tidak aktif = putih dengan border biru.
class PastelChip extends StatelessWidget {
  const PastelChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.pink.withValues(alpha: 0.55) : AppColors.surface,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: selected ? AppColors.pink : AppColors.blue, width: 1.2),
          boxShadow: selected ? AppColors.softShadow : const [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: selected ? AppColors.primary : AppColors.plumMuted),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppText.label(13,
                  color: selected ? AppColors.primary : AppColors.plum,
                  weight: selected ? FontWeight.w800 : FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.total, required this.loading, required this.sort, required this.onSort});

  final int total;
  final bool loading;
  final SortOption sort;
  final VoidCallback onSort;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: AppColors.mintDeep, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                loading ? 'Memuat produk...' : '$total produk tersedia',
                key: ValueKey('$loading-$total'),
                style: AppText.body(14, weight: FontWeight.w600),
              ),
            ),
          ),
          GestureDetector(
            onTap: onSort,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.pinkTint,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.swap_vert_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 140),
                    child: Text(
                      'Urutkan: ${sort.label}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.label(12, color: AppColors.plum),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.plum),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListFooter extends StatelessWidget {
  const _ListFooter({required this.provider});
  final ProductProvider provider;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (provider.isLoadingMore) {
      child = Row(
        key: const ValueKey('loading'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.pinkDeep),
          ),
          const SizedBox(width: 10),
          Text('Memuat produk lainnya...', style: AppText.body(13, color: AppColors.plumMuted)),
        ],
      );
    } else if (provider.loadMoreError != null) {
      child = TextButton.icon(
        key: const ValueKey('error'),
        onPressed: provider.loadMore,
        icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
        label: Text('${provider.loadMoreError} Ketuk untuk coba lagi.',
            textAlign: TextAlign.center, style: AppText.body(13, color: AppColors.primary)),
      );
    } else if (!provider.hasMore && provider.products.isNotEmpty && !provider.isLoading) {
      child = Container(
        key: const ValueKey('end'),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.pinkTint,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(color: AppColors.pink, shape: BoxShape.circle),
              child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
            ),
            const SizedBox(height: 10),
            Text('Semua produk sudah ditampilkan!', style: AppText.heading(15)),
            const SizedBox(height: 4),
            Text(
              'Gunakan pencarian atau kategori untuk menemukan harta karun lainnya.',
              textAlign: TextAlign.center,
              style: AppText.body(13, color: AppColors.plumMuted),
            ),
          ],
        ),
      );
    } else {
      child = const SizedBox(key: ValueKey('none'), height: 8);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: child),
    );
  }
}

class _AddProductFab extends StatelessWidget {
  const _AddProductFab({required this.extended});
  final bool extended;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.pinkDeep,
      borderRadius: BorderRadius.circular(28),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => context.push(AppRoutes.addProduct),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: AppColors.buttonShadow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, color: Colors.white, size: 26),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: extended
                    ? Padding(
                        padding: const EdgeInsets.only(left: 6, right: 4),
                        child: Text('Tambah Produk', style: AppText.label(15, color: Colors.white)),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
