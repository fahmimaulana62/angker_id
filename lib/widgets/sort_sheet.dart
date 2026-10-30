import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../models/sort_option.dart';

/// Bottom sheet pilihan urutan (sortBy & order).
Future<SortOption?> showSortSheet(BuildContext context, SortOption current) {
  return showModalBottomSheet<SortOption>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _SortSheet(current: current),
  );
}

class _SortSheet extends StatelessWidget {
  const _SortSheet({required this.current});
  final SortOption current;

  static const _icons = {
    SortOption.none: Icons.auto_awesome_rounded,
    SortOption.ratingDesc: Icons.star_rounded,
    SortOption.priceAsc: Icons.arrow_downward_rounded,
    SortOption.priceDesc: Icons.arrow_upward_rounded,
    SortOption.titleAsc: Icons.sort_by_alpha_rounded,
    SortOption.titleDesc: Icons.sort_by_alpha_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return SheetContainer(
      title: 'Urutkan Produk',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: SortOption.values.map((o) {
          final selected = o == current;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: selected ? AppColors.pinkTint : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.of(context).pop(o),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(_icons[o], color: selected ? AppColors.primary : AppColors.plumMuted, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          o.label,
                          style: AppText.label(14,
                              color: selected ? AppColors.primary : AppColors.plum,
                              weight: selected ? FontWeight.w800 : FontWeight.w600),
                        ),
                      ),
                      AnimatedOpacity(
                        opacity: selected ? 1 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.check_circle_rounded, color: AppColors.pinkDeep),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Wadah bottom sheet: sudut atas 24, grab bar, judul.
class SheetContainer extends StatelessWidget {
  const SheetContainer({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom + MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.plumMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(title, style: AppText.heading(18)),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
