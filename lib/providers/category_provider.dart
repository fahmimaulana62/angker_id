import 'package:flutter/foundation.dart';

import '../models/category_model.dart';
import '../services/api_service_products.dart';

class CategoryProvider extends ChangeNotifier {
  CategoryProvider(this._api);

  final ApiServiceProducts _api;

  List<ProductCategory> _categories = [];
  List<String> _categoryList = [];
  bool _loadingCategories = false;
  bool _loadingList = false;
  String? _categoriesError;
  String? _listError;

  List<ProductCategory> get categories => _categories;
  List<String> get categoryList => _categoryList;
  bool get loadingCategories => _loadingCategories;
  bool get loadingList => _loadingList;
  String? get categoriesError => _categoriesError;
  String? get listError => _listError;

  /// GET /products/categories -> kartu di tab Kategori.
  Future<void> fetchCategories({bool force = false}) async {
    if (_loadingCategories || (_categories.isNotEmpty && !force)) return;
    _loadingCategories = true;
    _categoriesError = null;
    notifyListeners();
    try {
      _categories = await _api.getCategories();
    } on ApiException catch (e) {
      _categoriesError = e.message;
    } finally {
      _loadingCategories = false;
      notifyListeners();
    }
  }

  /// GET /products/category-list -> chip filter di Beranda & dropdown form.
  Future<void> fetchCategoryList({bool force = false}) async {
    if (_loadingList || (_categoryList.isNotEmpty && !force)) return;
    _loadingList = true;
    _listError = null;
    notifyListeners();
    try {
      _categoryList = await _api.getCategoryList();
    } on ApiException catch (e) {
      _listError = e.message;
    } finally {
      _loadingList = false;
      notifyListeners();
    }
  }

  /// Nama tampilan untuk slug, memakai data /categories bila sudah ada.
  String nameFor(String slug) {
    for (final c in _categories) {
      if (c.slug == slug) return c.name;
    }
    if (slug.isEmpty) return 'Lainnya';
    return slug
        .split('-')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}
