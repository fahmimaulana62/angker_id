import 'package:flutter/foundation.dart';

import '../models/product_model.dart';
import '../services/local_storage_service.dart';

/// Wishlist tersimpan permanen di shared_preferences.
class WishlistProvider extends ChangeNotifier {
  WishlistProvider(this._storage) {
    for (final p in _storage.loadWishlist()) {
      _items[p.id] = p;
    }
  }

  final LocalStorageService _storage;
  // Map menjaga urutan sisip; produk terbaru ditaruh di depan saat ditampilkan.
  final Map<int, Product> _items = {};

  List<Product> get items => _items.values.toList().reversed.toList();
  int get count => _items.length;
  bool isWishlisted(int id) => _items.containsKey(id);

  /// Tambah/hapus. Mengembalikan true bila produk sekarang ada di wishlist.
  bool toggle(Product product) {
    final added = !_items.containsKey(product.id);
    if (added) {
      _items[product.id] = product;
    } else {
      _items.remove(product.id);
    }
    _persist();
    return added;
  }

  void remove(int id) {
    if (_items.remove(id) != null) _persist();
  }

  void add(Product product) {
    _items[product.id] = product;
    _persist();
  }

  /// Sinkronkan data produk setelah diedit (PUT/PATCH).
  void sync(Product product) {
    if (!_items.containsKey(product.id)) return;
    _items[product.id] = product;
    _persist();
  }

  void clear() {
    _items.clear();
    _persist();
  }

  void _persist() {
    _storage.saveWishlist(_items.values);
    notifyListeners();
  }
}
