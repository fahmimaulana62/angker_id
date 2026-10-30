/// Model untuk response GET /products/categories.
/// Contoh: {"slug":"beauty","name":"Beauty","url":"https://dummyjson.com/products/category/beauty"}
class ProductCategory {
  final String slug;
  final String name;
  final String url;

  const ProductCategory({required this.slug, required this.name, this.url = ''});

  factory ProductCategory.fromJson(Map<String, dynamic> json) => ProductCategory(
        slug: (json['slug'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        url: (json['url'] ?? '').toString(),
      );
}
