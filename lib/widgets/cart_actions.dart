import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/router/app_router.dart';
import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import 'app_snackbar.dart';

/// Tambah ke keranjang + umpan balik SnackBar. Mengembalikan true bila berhasil.
bool addToCartWithFeedback(BuildContext context, Product product, {int quantity = 1}) {
  final cart = context.read<CartProvider>();
  final router = GoRouter.of(context);
  final result = cart.add(product, quantity: quantity);
  switch (result) {
    case AddToCartResult.added:
    case AddToCartResult.increased:
      HapticFeedback.mediumImpact();
      showAppSnack(
        context,
        '${product.title} ditambahkan ($quantity)',
        icon: Icons.shopping_bag_rounded,
        actionLabel: 'Lihat',
        onAction: () => router.go(AppRoutes.cart),
      );
      return true;
    case AddToCartResult.limitedByStock:
      showAppSnack(
        context,
        'Stok hanya tersisa ${product.stock}. Jumlah di keranjang disesuaikan.',
        icon: Icons.inventory_2_rounded,
      );
      return true;
    case AddToCartResult.outOfStock:
      showAppSnack(context, 'Maaf, stok produk ini habis.', icon: Icons.block_rounded, isError: true);
      return false;
  }
}
