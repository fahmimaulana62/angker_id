import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

const String kSearchHeroTag = 'search-bar';

/// Tampilan search bar statis (dipakai di Beranda dan sebagai "shuttle" Hero
/// saat transisi ke halaman pencarian).
class SearchBarShell extends StatelessWidget {
  const SearchBarShell({super.key, this.text});

  final String? text;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        height: 54,
        padding: const EdgeInsets.only(left: 16, right: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppColors.softShadow,
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: AppColors.plum),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text ?? 'Cari produk DummyJSON (hp, baju, parfum...)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(14.5, color: text == null ? AppColors.plumMuted : AppColors.plum),
              ),
            ),
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(color: AppColors.pinkDeep, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}
