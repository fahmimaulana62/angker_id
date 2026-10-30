import 'package:flutter/foundation.dart';

import '../models/product_model.dart';
import '../models/sort_option.dart';
import '../services/api_service_products.dart';

/// State utama produk: daftar Beranda, detail, dan operasi CRUD.
///
/// Catatan: POST/PUT/PATCH/DELETE di DummyJSON hanya simulasi (tidak tersimpan
/// di server). Karena itu hasil operasi disimpan di state lokal supaya tampilan
/// tetap konsisten selama aplikasi berjalan.
class ProductProvider extends ChangeNotifier {
  ProductProvider(this._api);

  final ApiServiceProducts _api;
  static const int pageSize = 20;

  // ---- State Beranda ----
  List<Product> _products = [];
  int _total = 0;
  int _serverSkip = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  String? _loadMoreError;
  String? _selectedCategory;
  SortOption _sort = SortOption.none;
  int _requestId = 0;
  bool _initialized = false;

  // ---- State lokal hasil CRUD (simulasi) ----
  final Map<int, Product> _detailCache = {};
  final Map<int, Product> _overrides = {};
  final List<Product> _localAdded = [];
  final Set<int> _deletedIds = {};
  int _nextLocalId = 195;

  List<Product> get products => List.unmodifiable(_products);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  String? get loadMoreError => _loadMoreError;
  String? get selectedCategory => _selectedCategory;
  SortOption get sort => _sort;
  bool get initialized => _initialized;

  /// Masih ada halaman berikutnya? (kategori dimuat sekaligus, tanpa pagination)
  bool get hasMore => _selectedCategory == null && _serverSkip < _total;

  /// Jumlah produk yang ditampilkan di "N produk tersedia".
  int get displayTotal {
    if (_selectedCategory != null) return _products.length;
    final deletedServer = _deletedIds.where((id) => id <= 194).length;
    final value = _total - deletedServer + _localAdded.length;
    return value < _products.length ? _products.length : value;
  }

  /// Produk dengan diskon terbesar dari data yang sudah dimuat (untuk banner promo).
  Product? get bestDeal {
    if (_products.isEmpty) return null;
    return _products.reduce((a, b) => a.discountPercentage >= b.discountPercentage ? a : b);
  }

  // =========================================================================
  // Daftar produk Beranda
  // =========================================================================

  /// Muat halaman pertama sesuai filter kategori & urutan yang aktif.
  Future<void> fetchInitial() async {
    final reqId = ++_requestId;
    _isLoading = true;
    _error = null;
    _loadMoreError = null;
    notifyListeners();

    try {
      final ProductsResponse res;
      final category = _selectedCategory;
      if (category != null) {
        // GET /products/category/{slug}
        res = await _api.getProductsByCategory(
          category,
          sortBy: _sort.sortBy,
          order: _sort.order,
          select: kHomeSelect,
        );
      } else if (_sort == SortOption.none) {
        // GET /products?limit=&skip=&select=
        res = await _api.getProductsPaginated(limit: pageSize, skip: 0, select: kHomeSelect);
      } else {
        // GET /products?sortBy=&order=&limit=&skip=&select=
        res = await _api.sortProducts(
          _sort.sortBy!,
          _sort.order!,
          limit: pageSize,
          skip: 0,
          select: kHomeSelect,
        );
      }
      if (reqId != _requestId) return;

      _total = res.total;
      _serverSkip = category != null ? res.total : res.products.length;
      _products = applyLocalChanges(
        res.products,
        includeLocal: (p) => category == null || p.category == category,
      );
      _initialized = true;
    } on ApiException catch (e) {
      if (reqId != _requestId) return;
      _error = e.message;
    } finally {
      if (reqId == _requestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Infinite scroll: muat halaman berikutnya memakai limit & skip.
  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !hasMore) return;
    final reqId = _requestId;
    _isLoadingMore = true;
    _loadMoreError = null;
    notifyListeners();

    try {
      final res = _sort == SortOption.none
          ? await _api.getProductsPaginated(limit: pageSize, skip: _serverSkip, select: kHomeSelect)
          : await _api.sortProducts(
              _sort.sortBy!,
              _sort.order!,
              limit: pageSize,
              skip: _serverSkip,
              select: kHomeSelect,
            );
      if (reqId != _requestId) return;

      _total = res.total;
      _serverSkip += res.products.length;
      if (res.products.isEmpty) _total = _serverSkip;
      final existing = _products.map((p) => p.id).toSet();
      _products = [
        ..._products,
        ...applyLocalChanges(res.products, includeLocal: (_) => false)
            .where((p) => !existing.contains(p.id)),
      ];
    } on ApiException catch (e) {
      if (reqId == _requestId) _loadMoreError = e.message;
    } finally {
      if (reqId == _requestId) {
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<void> refresh() => fetchInitial();

  void setSort(SortOption option) {
    if (option == _sort) return;
    _sort = option;
    fetchInitial();
  }

  void filterByCategory(String? slug) {
    if (slug == _selectedCategory) return;
    _selectedCategory = slug;
    fetchInitial();
  }

  /// Produk per kategori untuk halaman kategori (GET /products/category/{slug}).
  Future<List<Product>> fetchCategoryProducts(String slug, SortOption sort) async {
    final res = await _api.getProductsByCategory(slug, sortBy: sort.sortBy, order: sort.order);
    return res.products;
  }

  /// Terapkan hasil CRUD lokal (hapus/edit/tambah) ke daftar dari server.
  List<Product> applyLocalChanges(
    List<Product> fromServer, {
    bool Function(Product p)? includeLocal,
  }) {
    final locals = includeLocal == null
        ? <Product>[]
        : _localAdded.where((p) => !_deletedIds.contains(p.id) && includeLocal(p)).toList();
    final server = fromServer
        .where((p) => !_deletedIds.contains(p.id))
        .map((p) => _overrides[p.id] ?? p)
        .toList();
    return [...locals, ...server];
  }

  // =========================================================================
  // Detail produk
  // =========================================================================

  bool isDeleted(int id) => _deletedIds.contains(id);

  Product? _localById(int id) {
    for (final p in _localAdded) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Data yang sudah ada di memori (untuk ditampilkan instan sebelum detail selesai dimuat).
  Product? peek(int id) {
    final local = _localById(id);
    if (local != null) return local;
    if (_overrides.containsKey(id)) return _overrides[id];
    if (_detailCache.containsKey(id)) return _detailCache[id];
    for (final p in _products) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Produk lengkap (punya deskripsi, ulasan, dll) bila sudah pernah dimuat.
  Product? fullProduct(int id) => _localById(id) ?? _overrides[id] ?? _detailCache[id];

  /// GET /products/{id}. Produk hasil tambah lokal (id > 194) tidak di-request
  /// karena server DummyJSON akan membalas 404.
  Future<Product> getProductDetail(int id, {bool forceRefresh = false}) async {
    final local = _localById(id);
    if (local != null) return local;
    if (_overrides.containsKey(id)) return _overrides[id]!;
    if (!forceRefresh && _detailCache.containsKey(id)) return _detailCache[id]!;
    if (id > 194) throw const ApiException('Produk tidak ditemukan.');

    final product = await _api.getProduct(id);
    _detailCache[id] = product;
    return product;
  }

  // =========================================================================
  // CRUD (simulasi DummyJSON)
  // =========================================================================

  /// POST /products/add
  Future<Product> addProduct(Product draft) async {
    final res = await _api.addProduct(draft.toUpdateJson());
    final id = res.id > 194 && res.id >= _nextLocalId ? res.id : _nextLocalId;
    _nextLocalId = id + 1;

    final product = draft.copyWith(
      id: id,
      images: draft.thumbnail.isNotEmpty ? [draft.thumbnail] : const [],
      availabilityStatus: Product.statusFor(draft.stock),
    );
    _localAdded.insert(0, product);
    if (_selectedCategory == null || _selectedCategory == product.category) {
      _products = [product, ..._products];
    }
    notifyListeners();
    return product;
  }

  /// PUT /products/{id}
  Future<Product> updateProduct(Product updated) async {
    var result = updated.copyWith(availabilityStatus: Product.statusFor(updated.stock));
    if (!updated.isLocalOnly) {
      final res = await _api.updateProduct(updated.id, updated.toUpdateJson());
      result = result.mergeWith(res);
    }
    _store(result);
    return result;
  }

  /// PATCH /products/{id} (update cepat stok/harga)
  Future<Product> patchProduct(int id, {int? stock, double? price}) async {
    final base = peek(id);
    if (base == null) throw const ApiException('Produk tidak ditemukan.');
    final data = <String, dynamic>{
      if (stock != null) 'stock': stock,
      if (price != null) 'price': price,
    };
    if (!base.isLocalOnly) {
      await _api.patchProduct(id, data);
    }
    final newStock = stock ?? base.stock;
    final result = base.copyWith(
      stock: newStock,
      price: price,
      availabilityStatus: Product.statusFor(newStock),
    );
    _store(result);
    return result;
  }

  /// DELETE /products/{id}. Mengembalikan nilai deletedOn dari server.
  Future<String> deleteProduct(int id) async {
    String deletedOn = DateTime.now().toIso8601String();
    final local = _localById(id);
    if (local == null) {
      final res = await _api.deleteProduct(id);
      deletedOn = res.deletedOn ?? deletedOn;
    }
    _deletedIds.add(id);
    _localAdded.removeWhere((p) => p.id == id);
    _overrides.remove(id);
    _detailCache.remove(id);
    _products = _products.where((p) => p.id != id).toList();
    notifyListeners();
    return deletedOn;
  }

  void _store(Product p) {
    final localIndex = _localAdded.indexWhere((e) => e.id == p.id);
    if (localIndex != -1) {
      _localAdded[localIndex] = p;
    } else {
      _overrides[p.id] = p;
    }
    _detailCache[p.id] = p;
    _products = _products.map((e) => e.id == p.id ? p : e).toList();
    notifyListeners();
  }
}
