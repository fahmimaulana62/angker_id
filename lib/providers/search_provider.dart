import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/utils/debouncer.dart';
import '../models/product_model.dart';
import '../models/sort_option.dart';
import '../services/api_service_products.dart';
import '../services/local_storage_service.dart';

/// State pencarian: GET /products/search?q= dengan debounce & riwayat.
class SearchProvider extends ChangeNotifier {
  SearchProvider(this._api, this._storage) {
    _recent = _storage.loadRecentSearches();
  }

  final ApiServiceProducts _api;
  final LocalStorageService _storage;
  final Debouncer _debouncer = Debouncer();
  CancelToken? _cancelToken;

  static const int maxRecent = 8;
  static const List<String> suggestions = ['phone', 'laptop', 'perfume', 'watch', 'shoes', 'lipstick'];

  String _query = '';
  List<Product> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _error;
  SortOption _sort = SortOption.none;
  List<String> _recent = [];

  String get query => _query;
  bool get isLoading => _isLoading;
  bool get hasSearched => _hasSearched;
  String? get error => _error;
  SortOption get sort => _sort;
  List<String> get recentSearches => List.unmodifiable(_recent);

  /// Hasil pencarian yang sudah diurutkan di sisi aplikasi.
  List<Product> get results {
    final list = [..._results];
    switch (_sort) {
      case SortOption.priceAsc:
        list.sort((a, b) => a.price.compareTo(b.price));
      case SortOption.priceDesc:
        list.sort((a, b) => b.price.compareTo(a.price));
      case SortOption.ratingDesc:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case SortOption.titleAsc:
        list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case SortOption.titleDesc:
        list.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
      case SortOption.none:
        break;
    }
    return list;
  }

  /// Dipanggil setiap kali teks berubah (debounce 400 ms).
  void onQueryChanged(String value) {
    _query = value;
    final q = value.trim();
    if (q.isEmpty) {
      _debouncer.cancel();
      _cancelToken?.cancel();
      _results = [];
      _isLoading = false;
      _hasSearched = false;
      _error = null;
      notifyListeners();
      return;
    }
    _isLoading = true;
    notifyListeners();
    _debouncer.run(() => _search(q));
  }

  /// Dipanggil saat user menekan enter / tombol cari / chip riwayat.
  Future<void> submit(String value) async {
    final q = value.trim();
    _query = value;
    if (q.isEmpty) return;
    _debouncer.cancel();
    _addRecent(q);
    await _search(q);
  }

  Future<void> retry() => _search(_query.trim());

  Future<void> _search(String q) async {
    if (q.isEmpty) return;
    _cancelToken?.cancel();
    final token = CancelToken();
    _cancelToken = token;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.searchProducts(q, cancelToken: token);
      if (token.isCancelled) return;
      _results = res.products;
      _hasSearched = true;
      _isLoading = false;
      notifyListeners();
    } on DioException catch (e) {
      // Request lama dibatalkan karena user mengetik lagi: abaikan.
      if (CancelToken.isCancel(e)) return;
      _setError('Terjadi kesalahan jaringan.');
    } on ApiException catch (e) {
      if (token.isCancelled) return;
      _setError(e.message);
    }
  }

  void _setError(String message) {
    _error = message;
    _isLoading = false;
    _hasSearched = true;
    notifyListeners();
  }

  void setSort(SortOption sort) {
    if (_sort == sort) return;
    _sort = sort;
    notifyListeners();
  }

  void _addRecent(String q) {
    _recent.removeWhere((e) => e.toLowerCase() == q.toLowerCase());
    _recent.insert(0, q);
    if (_recent.length > maxRecent) _recent = _recent.sublist(0, maxRecent);
    _storage.saveRecentSearches(_recent);
    notifyListeners();
  }

  void removeRecent(String q) {
    _recent.remove(q);
    _storage.saveRecentSearches(_recent);
    notifyListeners();
  }

  void clearRecent() {
    _recent = [];
    _storage.saveRecentSearches(_recent);
    notifyListeners();
  }

  /// Reset saat halaman pencarian ditutup.
  void reset() {
    _debouncer.cancel();
    _cancelToken?.cancel();
    _query = '';
    _results = [];
    _isLoading = false;
    _hasSearched = false;
    _error = null;
    _sort = SortOption.none;
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _cancelToken?.cancel();
    super.dispose();
  }
}
