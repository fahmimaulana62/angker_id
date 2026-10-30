import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/cart_provider.dart';
import 'providers/category_provider.dart';
import 'providers/product_provider.dart';
import 'providers/search_provider.dart';
import 'providers/wishlist_provider.dart';
import 'services/api_service_products.dart';
import 'services/local_storage_service.dart';

class AngkerApp extends StatefulWidget {
  const AngkerApp({super.key, required this.storage});

  final LocalStorageService storage;

  @override
  State<AngkerApp> createState() => _AngkerAppState();
}

class _AngkerAppState extends State<AngkerApp> {
  late final ApiServiceProducts _api = ApiServiceProducts();
  late final GoRouter _router = createRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiServiceProducts>.value(value: _api),
        ChangeNotifierProvider(create: (_) => ProductProvider(_api)),
        ChangeNotifierProvider(create: (_) => CategoryProvider(_api)),
        ChangeNotifierProvider(create: (_) => SearchProvider(_api, widget.storage)),
        ChangeNotifierProvider(create: (_) => WishlistProvider(widget.storage)),
        ChangeNotifierProvider(create: (_) => CartProvider(widget.storage)),
      ],
      child: MaterialApp.router(
        title: 'Angker.id',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}
