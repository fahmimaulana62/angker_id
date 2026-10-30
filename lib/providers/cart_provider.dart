import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/product_model.dart';
import '../services/local_storage_service.dart';

enum AddToCartResult { added, increased, limitedByStock, outOfStock }

class Voucher {
  final String code;
  final String description;
  final double percent;
  const Voucher(this.code, this.description, this.percent);
}

/// Keranjang belanja dengan pengatur jumlah (dibatasi stok) dan voucher.
class CartProvider extends ChangeNotifier {
  CartProvider(this._storage) {
    for (final item in _storage.loadCart()) {
      _items[item.product.id] = item;
    }
  }

  final LocalStorageService _storage;
  final Map<int, CartItem> _items = {};
  Voucher? _voucher;

  static const List<Voucher> availableVouchers = [
    Voucher('ANGKERHEMAT', 'Potongan ekstra 10% untuk semua belanjaan kamu!', 10),
    Voucher('HANTULUCU', 'Diskon 5% khusus pecinta barang imut.', 5),
  ];

  List<CartItem> get items => _items.values.toList();
  bool get isEmpty => _items.isEmpty;
  int get lineCount => _items.length;
  Voucher? get voucher => _voucher;

  int quantityOf(int id) => _items[id]?.quantity ?? 0;
  bool contains(int id) => _items.containsKey(id);

  /// Jumlah total barang (pcs).
  int get totalItems => _items.values.fold(0, (sum, i) => sum + i.quantity);

  /// Total harga normal sebelum diskon produk.
  double get originalSubtotal => _items.values.fold(0.0, (sum, i) => sum + i.originalSubtotal);

  /// Total setelah diskon produk.
  double get subtotal => _items.values.fold(0.0, (sum, i) => sum + i.subtotal);

  double get productDiscount => originalSubtotal - subtotal;

  double get voucherDiscount => _voucher == null ? 0 : subtotal * _voucher!.percent / 100;

  double get total => subtotal - voucherDiscount;

  double get totalSavings => productDiscount + voucherDiscount;

  /// Tambah produk. Jumlah tidak pernah melebihi stok.
  AddToCartResult add(Product product, {int quantity = 1}) {
    if (product.stock <= 0) return AddToCartResult.outOfStock;
    final current = _items[product.id];
    final wanted = (current?.quantity ?? 0) + quantity;
    final finalQty = wanted > product.stock ? product.stock : wanted;
    if (current != null && current.quantity >= product.stock) {
      return AddToCartResult.limitedByStock;
    }
    _items[product.id] = CartItem(product: product, quantity: finalQty);
    _persist();
    if (wanted > product.stock) return AddToCartResult.limitedByStock;
    return current == null ? AddToCartResult.added : AddToCartResult.increased;
  }

  /// +1. Mengembalikan false bila sudah mencapai stok maksimal.
  bool increment(int id) {
    final item = _items[id];
    if (item == null) return false;
    if (item.quantity >= item.product.stock) return false;
    _items[id] = item.copyWith(quantity: item.quantity + 1);
    _persist();
    return true;
  }

  /// -1. Tidak pernah di bawah 1 (hapus item memakai [remove]).
  bool decrement(int id) {
    final item = _items[id];
    if (item == null || item.quantity <= 1) return false;
    _items[id] = item.copyWith(quantity: item.quantity - 1);
    _persist();
    return true;
  }

  void setQuantity(int id, int quantity) {
    final item = _items[id];
    if (item == null) return;
    final q = quantity.clamp(1, item.product.stock < 1 ? 1 : item.product.stock);
    _items[id] = item.copyWith(quantity: q);
    _persist();
  }

  /// Hapus item, mengembalikan item yang dihapus (untuk tombol Undo).
  CartItem? remove(int id) {
    final removed = _items.remove(id);
    if (removed != null) _persist();
    return removed;
  }

  /// Kembalikan item yang dihapus (Undo).
  void restore(CartItem item) {
    _items[item.product.id] = item;
    _persist();
  }

  /// Sinkronkan setelah produk diedit (harga/stok berubah).
  void sync(Product product) {
    final item = _items[product.id];
    if (item == null) return;
    if (product.stock <= 0) {
      _items.remove(product.id);
    } else {
      final q = item.quantity > product.stock ? product.stock : item.quantity;
      _items[product.id] = CartItem(product: product, quantity: q);
    }
    _persist();
  }

  /// Terapkan kode voucher. Mengembalikan voucher bila valid.
  Voucher? applyVoucher(String code) {
    final upper = code.trim().toUpperCase();
    for (final v in availableVouchers) {
      if (v.code == upper) {
        _voucher = v;
        notifyListeners();
        return v;
      }
    }
    return null;
  }

  void removeVoucher() {
    _voucher = null;
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _voucher = null;
    _persist();
  }

  void _persist() {
    _storage.saveCart(_items.values);
    notifyListeners();
  }
}
