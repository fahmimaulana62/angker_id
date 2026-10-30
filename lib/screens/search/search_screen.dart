import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/product_model.dart';
import '../../models/sort_option.dart';
import '../../providers/product_provider.dart';
import '../../providers/search_provider.dart';
import '../../widgets/animated_entry.dart';
import '../../widgets/product_card.dart';
import '../../widgets/product_grid_shimmer.dart';
import '../../widgets/search_bar_shell.dart';
import '../../widgets/state_views.dart';

/// Halaman pencarian: GET /products/search?q= (debounce 400 ms).
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final SearchProvider _search;
  late final TextEditingController _controller;
  final FocusNode _focus = FocusNode();
  Animation<double>? _routeAnimation;

  @override
  void initState() {
    super.initState();
    _search = context.read<SearchProvider>();
    _controller = TextEditingController(text: _search.query);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Fokus (buka keyboard) setelah transisi selesai agar animasi tidak tersendat.
    final anim = ModalRoute.of(context)?.animation;
    if (anim != null && anim != _routeAnimation) {
      _routeAnimation?.removeStatusListener(_onRouteStatus);
      _routeAnimation = anim;
      if (anim.status == AnimationStatus.completed) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _requestFocus());
      } else {
        anim.addStatusListener(_onRouteStatus);
      }
    }
  }

  void _onRouteStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _routeAnimation?.removeStatusListener(_onRouteStatus);
      _requestFocus();
    }
  }

  void _requestFocus() {
    if (mounted && _controller.text.isEmpty) _focus.requestFocus();
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_onRouteStatus);
    _controller.dispose();
    _focus.dispose();
    _search.reset();
    super.dispose();
  }

  void _useQuery(String q) {
    _controller.value = TextEditingValue(
      text: q,
      selection: TextSelection.collapsed(offset: q.length),
    );
    _focus.unfocus();
    _search.submit(q);
  }

  void _clear() {
    _controller.clear();
    _search.onQueryChanged('');
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final search = context.watch<SearchProvider>();
    final query = search.query.trim();

    Widget body;
    String stateKey;
    if (query.isEmpty) {
      stateKey = 'idle';
      body = _IdleView(onPick: _useQuery);
    } else if (search.isLoading && !search.hasSearched) {
      stateKey = 'loading';
      body = const _LoadingView();
    } else if (search.error != null) {
      stateKey = 'error';
      body = ErrorState(message: search.error!, onRetry: search.retry);
    } else {
      final products = context.watch<ProductProvider>().applyLocalChanges(
            search.results,
            includeLocal: (p) => p.title.toLowerCase().contains(query.toLowerCase()),
          );
      if (products.isEmpty && !search.isLoading) {
        stateKey = 'empty';
        body = EmptyState(
          icon: Icons.search_off_rounded,
          title: 'Produk tidak ditemukan',
          message: 'Tidak ada hasil untuk "$query". Coba kata kunci lain seperti "phone" atau "perfume".',
        );
      } else {
        stateKey = 'results';
        body = _ResultsView(
          query: query,
          products: products,
          loading: search.isLoading,
          sort: search.sort,
        );
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text('Pencarian', style: AppText.heading(18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Hero(
              tag: kSearchHeroTag,
              flightShuttleBuilder: (context, animation, direction, fromCtx, toCtx) =>
                  SearchBarShell(text: _controller.text.isEmpty ? null : _controller.text),
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  height: 54,
                  padding: const EdgeInsets.only(left: 14, right: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: AppColors.softShadow,
                    border: Border.all(color: AppColors.pinkSoft),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focus,
                          textInputAction: TextInputAction.search,
                          onChanged: _search.onQueryChanged,
                          onSubmitted: _search.submit,
                          cursorColor: AppColors.pinkDeep,
                          style: AppText.body(15, weight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: 'Cari produk (phone, laptop, perfume...)',
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                            hintStyle: AppText.body(14.5, color: AppColors.plumMuted),
                          ),
                        ),
                      ),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _controller,
                        builder: (context, value, _) => AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                          child: value.text.isEmpty
                              ? const SizedBox(key: ValueKey('empty'), width: 8)
                              : IconButton(
                                  key: const ValueKey('clear'),
                                  onPressed: _clear,
                                  icon: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.pinkTint,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close_rounded, size: 18, color: AppColors.plum),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: KeyedSubtree(key: ValueKey(stateKey), child: body),
            ),
          ),
        ],
      ),
    );
  }
}

class _IdleView extends StatelessWidget {
  const _IdleView({required this.onPick});
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final search = context.watch<SearchProvider>();
    final recent = search.recentSearches;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      physics: const BouncingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        if (recent.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.history_rounded, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text('Pencarian Terakhir', style: AppText.heading(15))),
              GestureDetector(
                onTap: search.clearRecent,
                child: Text('Hapus Semua', style: AppText.label(13, color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < recent.length; i++)
                _RemovableChip(
                  label: recent[i],
                  color: AppColors.pastelCycle[i % 3 == 0 ? 1 : (i % 3 == 1 ? 0 : 2)],
                  onTap: () => onPick(recent[i]),
                  onRemove: () => search.removeRecent(recent[i]),
                ),
            ],
          ),
          const SizedBox(height: 28),
        ],
        Row(
          children: [
            const Icon(Icons.local_fire_department_rounded, size: 20, color: AppColors.pinkDeep),
            const SizedBox(width: 8),
            Text('Saran Populer', style: AppText.heading(15)),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: SearchProvider.suggestions
              .map((s) => ActionChip(
                    label: Text(s, style: AppText.label(13)),
                    avatar: const Icon(Icons.trending_up_rounded, size: 16, color: AppColors.primary),
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.blue),
                    shape: const StadiumBorder(),
                    onPressed: () => onPick(s),
                  ))
              .toList(),
        ),
        const SizedBox(height: 40),
        Center(
          child: Column(
            children: [
              const Text('👻', style: TextStyle(fontSize: 42)),
              const SizedBox(height: 8),
              Text(
                'Ketik nama produk, brand, atau kategori.\nHasil muncul otomatis saat kamu mengetik.',
                textAlign: TextAlign.center,
                style: AppText.body(13, color: AppColors.plumMuted, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RemovableChip extends StatelessWidget {
  const _RemovableChip({
    required this.label,
    required this.color,
    required this.onTap,
    required this.onRemove,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(left: 14, right: 6, top: 6, bottom: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: AppText.label(13, weight: FontWeight.w600)),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onRemove,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded, size: 16, color: AppColors.plum),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const CustomScrollView(
      physics: NeverScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
          sliver: ProductGridShimmerSliver(count: 4),
        ),
      ],
    );
  }
}

class _ResultsView extends StatelessWidget {
  const _ResultsView({
    required this.query,
    required this.products,
    required this.loading,
    required this.sort,
  });

  final String query;
  final List<Product> products;
  final bool loading;
  final SortOption sort;

  static const _sortChips = [
    SortOption.none,
    SortOption.priceAsc,
    SortOption.priceDesc,
    SortOption.ratingDesc,
  ];

  @override
  Widget build(BuildContext context) {
    final search = context.read<SearchProvider>();
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(
                        text: '${products.length}',
                        style: AppText.heading(18, weight: FontWeight.w800, color: AppColors.primary),
                      ),
                      TextSpan(text: " produk ditemukan untuk '$query'", style: AppText.heading(16)),
                    ]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AnimatedOpacity(
                  opacity: loading ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _sortChips.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final option = _sortChips[i];
                final selected = option == sort;
                return GestureDetector(
                  onTap: () => search.setSort(option),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: selected ? AppColors.primary : AppColors.pinkSoft),
                    ),
                    child: Text(
                      option.label,
                      style: AppText.label(12.5, color: selected ? Colors.white : AppColors.plum),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 14)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          sliver: SliverGrid(
            gridDelegate: productGridDelegate(context),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final p = products[index];
                return AnimatedEntry(
                  key: ValueKey('search-${p.id}'),
                  id: 'search-$query-${sort.name}-${p.id}',
                  index: index,
                  child: ProductCard(product: p, heroScope: 'search'),
                );
              },
              childCount: products.length,
            ),
          ),
        ),
      ],
    );
  }
}
