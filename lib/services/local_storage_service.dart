import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart_item.dart';
import '../models/product_model.dart';

/// Penyimpanan lokal untuk wishlist, keranjang, dan riwayat pencarian.
class LocalStorageService {
  LocalStorageService(this._prefs);

  final SharedPreferences _prefs;

  static const _kWishlist = 'angker_wishlist';
  static const _kCart = 'angker_cart';
  static const _kRecent = 'angker_recent_search';

  static Future<LocalStorageService> init() async =>
      LocalStorageService(await SharedPreferences.getInstance());

  // ---- Wishlist ----
  List<Product> loadWishlist() {
    final raw = _prefs.getString(_kWishlist);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => Product.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      debugPrint('Gagal membaca wishlist: $e');
      return [];
    }
  }

  Future<void> saveWishlist(Iterable<Product> items) =>
      _prefs.setString(_kWishlist, jsonEncode(items.map((p) => p.toJson()).toList()));

  // ---- Keranjang ----
  List<CartItem> loadCart() {
    final raw = _prefs.getString(_kCart);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      debugPrint('Gagal membaca keranjang: $e');
      return [];
    }
  }

  Future<void> saveCart(Iterable<CartItem> items) =>
      _prefs.setString(_kCart, jsonEncode(items.map((c) => c.toJson()).toList()));

  // ---- Riwayat pencarian ----
  List<String> loadRecentSearches() => _prefs.getStringList(_kRecent) ?? [];

  Future<void> saveRecentSearches(List<String> items) => _prefs.setStringList(_kRecent, items);
}
