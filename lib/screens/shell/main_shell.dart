import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../widgets/app_snackbar.dart';

/// Jarak bawah agar konten tidak tertutup bottom navigation yang melayang.
const double kNavBarClearance = 110;

/// Kerangka 4 tab: Beranda, Kategori, Wishlist, Keranjang.
class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  DateTime? _lastBackPress;

  void _onTap(int index) {
    HapticFeedback.selectionClick();
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  void _handleBack() {
    if (widget.navigationShell.currentIndex != 0) {
      widget.navigationShell.goBranch(0);
      return;
    }
    final now = DateTime.now();
    if (_lastBackPress != null && now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
      SystemNavigator.pop();
      return;
    }
    _lastBackPress = now;
    showAppSnack(context, 'Tekan sekali lagi untuk keluar', icon: Icons.exit_to_app_rounded);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        extendBody: true,
        body: widget.navigationShell,
        bottomNavigationBar: _FloatingNavBar(
          currentIndex: widget.navigationShell.currentIndex,
          onTap: _onTap,
        ),
      ),
    );
  }
}

/// Container cabang tab: crossfade halus saat pindah tab, dan tab yang tidak
/// aktif dimatikan ticker & Hero-nya supaya tidak membebani / bentrok tag.
class ShellBranchContainer extends StatelessWidget {
  const ShellBranchContainer({super.key, required this.currentIndex, required this.children});

  final int currentIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < children.length; i++)
          IgnorePointer(
            ignoring: i != currentIndex,
            child: ExcludeFocus(
              excluding: i != currentIndex,
              child: AnimatedOpacity(
                opacity: i == currentIndex ? 1 : 0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                child: TickerMode(
                  enabled: i == currentIndex,
                  child: HeroMode(enabled: i == currentIndex, child: children[i]),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItemData(this.icon, this.activeIcon, this.label);
}

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    _NavItemData(Icons.home_outlined, Icons.home_rounded, 'Beranda'),
    _NavItemData(Icons.category_outlined, Icons.category_rounded, 'Kategori'),
    _NavItemData(Icons.favorite_border_rounded, Icons.favorite_rounded, 'Wishlist'),
    _NavItemData(Icons.shopping_bag_outlined, Icons.shopping_bag_rounded, 'Keranjang'),
  ];

  @override
  Widget build(BuildContext context) {
    final wishCount = context.select<WishlistProvider, int>((w) => w.count);
    final cartCount = context.select<CartProvider, int>((c) => c.totalItems);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottomInset),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.plum.withValues(alpha: 0.08),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: AppColors.pinkDeep.withValues(alpha: 0.16),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth / _items.length;
            return Stack(
              children: [
                // Pill aktif yang bergeser halus antar tab.
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  left: itemWidth * currentIndex + 8,
                  top: 8,
                  width: itemWidth - 16,
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.pink.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                ),
                Row(
                  children: List.generate(_items.length, (i) {
                    final badge = i == 2 ? wishCount : (i == 3 ? cartCount : 0);
                    return Expanded(
                      child: _NavItem(
                        data: _items[i],
                        active: i == currentIndex,
                        badge: badge,
                        onTap: () => onTap(i),
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.data, required this.active, required this.badge, required this.onTap});

  final _NavItemData data;
  final bool active;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.plum;
    return Semantics(
      selected: active,
      button: true,
      label: data.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedScale(
                  scale: active ? 1.1 : 1,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutBack,
                  child: Icon(active ? data.activeIcon : data.icon, color: color, size: 24),
                ),
                Positioned(
                  right: -10,
                  top: -6,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                    child: badge == 0
                        ? const SizedBox.shrink(key: ValueKey('none'))
                        : Container(
                            key: ValueKey(badge),
                            constraints: const BoxConstraints(minWidth: 18),
                            height: 18,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: data.label == 'Wishlist' ? AppColors.pinkDeep : AppColors.mintDeep,
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: Text(
                              badge > 99 ? '99+' : '$badge',
                              style: AppText.label(9.5, color: Colors.white, weight: FontWeight.w800),
                            ),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: AppText.label(11, color: color, weight: active ? FontWeight.w800 : FontWeight.w600),
              child: Text(data.label, maxLines: 1),
            ),
          ],
        ),
      ),
    );
  }
}
