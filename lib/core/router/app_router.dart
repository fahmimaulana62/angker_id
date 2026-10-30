import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../screens/cart/cart_screen.dart';
import '../../screens/category/category_products_screen.dart';
import '../../screens/category/category_screen.dart';
import '../../screens/detail/detail_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/manage/product_form_screen.dart';
import '../../screens/search/search_screen.dart';
import '../../screens/shell/main_shell.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/wishlist/wishlist_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Path helper supaya pemanggilan route konsisten.
class AppRoutes {
  AppRoutes._();
  static const splash = '/splash';
  static const home = '/home';
  static const categories = '/categories';
  static const wishlist = '/wishlist';
  static const cart = '/cart';
  static const search = '/search';
  static const addProduct = '/product/add';

  /// [heroScope] membuat tag Hero unik per halaman asal (home/search/wishlist/...).
  static String detail(int id, {String? heroScope}) =>
      heroScope == null ? '/product/$id' : '/product/$id?hero=$heroScope';
  static String editProduct(int id) => '/edit-product/$id';
  static String category(String slug) => '/category/$slug';
}

GoRouter createRouter() {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const SplashScreen()),
      ),
      StatefulShellRoute(
        // Splash -> Beranda: fade + scale 0.98 -> 1 selama 500 ms.
        pageBuilder: (context, state, navigationShell) => CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          child: MainShell(navigationShell: navigationShell),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = animation.drive(CurveTween(curve: Curves.easeOutCubic));
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: curved.drive(Tween<double>(begin: 0.98, end: 1)),
                child: child,
              ),
            );
          },
        ),
        navigatorContainerBuilder: (context, navigationShell, children) =>
            ShellBranchContainer(currentIndex: navigationShell.currentIndex, children: children),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.home,
              pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const HomeScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.categories,
              pageBuilder: (context, state) =>
                  NoTransitionPage(key: state.pageKey, child: const CategoryScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.wishlist,
              pageBuilder: (context, state) =>
                  NoTransitionPage(key: state.pageKey, child: const WishlistScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.cart,
              pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const CartScreen()),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: AppRoutes.search,
        pageBuilder: (context, state) => _fadeSlidePage(state, const SearchScreen()),
      ),
      // Harus didaftarkan sebelum /product/:id supaya "add" tidak dianggap id.
      GoRoute(
        path: AppRoutes.addProduct,
        pageBuilder: (context, state) => _fadeSlidePage(state, const ProductFormScreen()),
      ),
      GoRoute(
        path: '/product/:id',
        pageBuilder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          final scope = state.uri.queryParameters['hero'];
          return _fadeSlidePage(
            state,
            DetailScreen(productId: id, heroTag: scope == null ? null : '$scope-$id'),
          );
        },
      ),
      GoRoute(
        path: '/edit-product/:id',
        pageBuilder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return _fadeSlidePage(state, ProductFormScreen(editProductId: id));
        },
      ),
      GoRoute(
        path: '/category/:slug',
        pageBuilder: (context, state) =>
            _fadeSlidePage(state, CategoryProductsScreen(slug: state.pathParameters['slug'] ?? '')),
      ),
    ],
  );
}

/// Transisi halaman: fade + slide 6% dari kanan, 320 ms easeOutCubic.
CustomTransitionPage<void> _fadeSlidePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = animation.drive(CurveTween(curve: Curves.easeOutCubic));
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: curved.drive(Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero)),
          child: child,
        ),
      );
    },
  );
}
