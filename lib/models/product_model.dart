// Model 100% mapping dari response bawaan https://dummyjson.com/products.
// Semua field selain id punya nilai default, karena endpoint dengan `select=`
// hanya mengirim sebagian field.

double _toDouble(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
int _toInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
String _toStr(dynamic v) => v == null ? '' : v.toString();

class Dimensions {
  final double width;
  final double height;
  final double depth;

  const Dimensions({this.width = 0, this.height = 0, this.depth = 0});

  factory Dimensions.fromJson(Map<String, dynamic> json) => Dimensions(
        width: _toDouble(json['width']),
        height: _toDouble(json['height']),
        depth: _toDouble(json['depth']),
      );

  Map<String, dynamic> toJson() => {'width': width, 'height': height, 'depth': depth};

  bool get isEmpty => width == 0 && height == 0 && depth == 0;
}

class Review {
  final int rating;
  final String comment;
  final String date;
  final String reviewerName;
  final String reviewerEmail;

  const Review({
    this.rating = 0,
    this.comment = '',
    this.date = '',
    this.reviewerName = '',
    this.reviewerEmail = '',
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        rating: _toInt(json['rating']),
        comment: _toStr(json['comment']),
        date: _toStr(json['date']),
        reviewerName: _toStr(json['reviewerName']),
        reviewerEmail: _toStr(json['reviewerEmail']),
      );

  Map<String, dynamic> toJson() => {
        'rating': rating,
        'comment': comment,
        'date': date,
        'reviewerName': reviewerName,
        'reviewerEmail': reviewerEmail,
      };
}

class Meta {
  final String createdAt;
  final String updatedAt;
  final String barcode;
  final String qrCode;

  const Meta({this.createdAt = '', this.updatedAt = '', this.barcode = '', this.qrCode = ''});

  factory Meta.fromJson(Map<String, dynamic> json) => Meta(
        createdAt: _toStr(json['createdAt']),
        updatedAt: _toStr(json['updatedAt']),
        barcode: _toStr(json['barcode']),
        qrCode: _toStr(json['qrCode']),
      );

  Map<String, dynamic> toJson() => {
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'barcode': barcode,
        'qrCode': qrCode,
      };
}

class Product {
  final int id;
  final String title;
  final String description;
  final String category;
  final double price;
  final double discountPercentage;
  final double rating;
  final int stock;
  final List<String> tags;
  final String brand;
  final String sku;
  final double weight;
  final Dimensions dimensions;
  final String warrantyInformation;
  final String shippingInformation;
  final String availabilityStatus;
  final List<Review> reviews;
  final String returnPolicy;
  final int minimumOrderQuantity;
  final Meta meta;
  final String thumbnail;
  final List<String> images;
  final bool isDeleted;
  final String? deletedOn;

  const Product({
    required this.id,
    this.title = '',
    this.description = '',
    this.category = '',
    this.price = 0,
    this.discountPercentage = 0,
    this.rating = 0,
    this.stock = 0,
    this.tags = const [],
    this.brand = '',
    this.sku = '',
    this.weight = 0,
    this.dimensions = const Dimensions(),
    this.warrantyInformation = '',
    this.shippingInformation = '',
    this.availabilityStatus = '',
    this.reviews = const [],
    this.returnPolicy = '',
    this.minimumOrderQuantity = 1,
    this.meta = const Meta(),
    this.thumbnail = '',
    this.images = const [],
    this.isDeleted = false,
    this.deletedOn,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final dims = json['dimensions'];
    final meta = json['meta'];
    final reviews = json['reviews'];
    final tags = json['tags'];
    final images = json['images'];
    return Product(
      id: _toInt(json['id']),
      title: _toStr(json['title']),
      description: _toStr(json['description']),
      category: _toStr(json['category']),
      price: _toDouble(json['price']),
      discountPercentage: _toDouble(json['discountPercentage']),
      rating: _toDouble(json['rating']),
      stock: _toInt(json['stock']),
      tags: tags is List ? tags.map((e) => e.toString()).toList() : const [],
      brand: _toStr(json['brand']),
      sku: _toStr(json['sku']),
      weight: _toDouble(json['weight']),
      dimensions: dims is Map<String, dynamic> ? Dimensions.fromJson(dims) : const Dimensions(),
      warrantyInformation: _toStr(json['warrantyInformation']),
      shippingInformation: _toStr(json['shippingInformation']),
      availabilityStatus: _toStr(json['availabilityStatus']),
      reviews: reviews is List
          ? reviews.whereType<Map<String, dynamic>>().map(Review.fromJson).toList()
          : const [],
      returnPolicy: _toStr(json['returnPolicy']),
      minimumOrderQuantity: json['minimumOrderQuantity'] == null ? 1 : _toInt(json['minimumOrderQuantity']),
      meta: meta is Map<String, dynamic> ? Meta.fromJson(meta) : const Meta(),
      thumbnail: _toStr(json['thumbnail']),
      images: images is List ? images.map((e) => e.toString()).toList() : const [],
      isDeleted: json['isDeleted'] == true,
      deletedOn: json['deletedOn']?.toString(),
    );
  }

  /// JSON lengkap, dipakai untuk menyimpan wishlist/keranjang di shared_preferences.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'price': price,
        'discountPercentage': discountPercentage,
        'rating': rating,
        'stock': stock,
        'tags': tags,
        'brand': brand,
        'sku': sku,
        'weight': weight,
        'dimensions': dimensions.toJson(),
        'warrantyInformation': warrantyInformation,
        'shippingInformation': shippingInformation,
        'availabilityStatus': availabilityStatus,
        'reviews': reviews.map((r) => r.toJson()).toList(),
        'returnPolicy': returnPolicy,
        'minimumOrderQuantity': minimumOrderQuantity,
        'meta': meta.toJson(),
        'thumbnail': thumbnail,
        'images': images,
      };

  /// Body untuk POST /products/add dan PUT /products/{id}.
  Map<String, dynamic> toUpdateJson() => {
        'title': title,
        'description': description,
        'category': category,
        'price': price,
        'discountPercentage': discountPercentage,
        'brand': brand,
        'stock': stock,
        if (thumbnail.isNotEmpty) 'thumbnail': thumbnail,
      };

  Product copyWith({
    int? id,
    String? title,
    String? description,
    String? category,
    double? price,
    double? discountPercentage,
    double? rating,
    int? stock,
    List<String>? tags,
    String? brand,
    String? thumbnail,
    List<String>? images,
    String? availabilityStatus,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      rating: rating ?? this.rating,
      stock: stock ?? this.stock,
      tags: tags ?? this.tags,
      brand: brand ?? this.brand,
      sku: sku,
      weight: weight,
      dimensions: dimensions,
      warrantyInformation: warrantyInformation,
      shippingInformation: shippingInformation,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      reviews: reviews,
      returnPolicy: returnPolicy,
      minimumOrderQuantity: minimumOrderQuantity,
      meta: meta,
      thumbnail: thumbnail ?? this.thumbnail,
      images: images ?? this.images,
      isDeleted: isDeleted,
      deletedOn: deletedOn,
    );
  }

  /// Menggabungkan field dari response API (yang bisa jadi parsial) ke produk ini.
  /// Field kosong di [other] tidak menimpa data lama.
  Product mergeWith(Product other) {
    return Product(
      id: id,
      title: other.title.isNotEmpty ? other.title : title,
      description: other.description.isNotEmpty ? other.description : description,
      category: other.category.isNotEmpty ? other.category : category,
      price: other.price > 0 ? other.price : price,
      discountPercentage: other.discountPercentage,
      rating: other.rating > 0 ? other.rating : rating,
      stock: other.stock,
      tags: other.tags.isNotEmpty ? other.tags : tags,
      brand: other.brand.isNotEmpty ? other.brand : brand,
      sku: other.sku.isNotEmpty ? other.sku : sku,
      weight: other.weight > 0 ? other.weight : weight,
      dimensions: other.dimensions.isEmpty ? dimensions : other.dimensions,
      warrantyInformation:
          other.warrantyInformation.isNotEmpty ? other.warrantyInformation : warrantyInformation,
      shippingInformation:
          other.shippingInformation.isNotEmpty ? other.shippingInformation : shippingInformation,
      availabilityStatus: statusFor(other.stock),
      reviews: other.reviews.isNotEmpty ? other.reviews : reviews,
      returnPolicy: other.returnPolicy.isNotEmpty ? other.returnPolicy : returnPolicy,
      minimumOrderQuantity: minimumOrderQuantity,
      meta: meta,
      thumbnail: other.thumbnail.isNotEmpty ? other.thumbnail : thumbnail,
      images: other.images.isNotEmpty ? other.images : images,
    );
  }

  static String statusFor(int stock) {
    if (stock <= 0) return 'Out of Stock';
    if (stock < 10) return 'Low Stock';
    return 'In Stock';
  }

  // ---- Getter turunan untuk UI ----

  /// Harga sebelum diskon (harga coret).
  double get originalPrice =>
      discountPercentage > 0 && discountPercentage < 100 ? price / (1 - discountPercentage / 100) : price;

  double get savings => originalPrice - price;

  bool get inStock => stock > 0;

  bool get hasDiscount => discountPercentage >= 1;

  /// Status stok yang konsisten walau field availabilityStatus tidak dikirim (select=).
  String get stockStatus => availabilityStatus.isNotEmpty && stock > 0
      ? availabilityStatus
      : statusFor(stock);

  /// Daftar gambar galeri, fallback ke thumbnail.
  List<String> get gallery {
    if (images.isNotEmpty) return images;
    if (thumbnail.isNotEmpty) return [thumbnail];
    return const [];
  }

  /// Distribusi bintang 1-5 dari ulasan (index 0 = bintang 1).
  List<int> get starDistribution {
    final dist = List<int>.filled(5, 0);
    for (final r in reviews) {
      if (r.rating >= 1 && r.rating <= 5) dist[r.rating - 1]++;
    }
    return dist;
  }

  /// Produk hasil POST lokal (id di luar 194 produk bawaan DummyJSON).
  bool get isLocalOnly => id > 194;
}

class ProductsResponse {
  final List<Product> products;
  final int total;
  final int skip;
  final int limit;

  const ProductsResponse({
    required this.products,
    required this.total,
    required this.skip,
    required this.limit,
  });

  factory ProductsResponse.fromJson(Map<String, dynamic> json) {
    final list = json['products'];
    final products = list is List
        ? list.whereType<Map<String, dynamic>>().map(Product.fromJson).toList()
        : <Product>[];
    return ProductsResponse(
      products: products,
      total: json['total'] == null ? products.length : _toInt(json['total']),
      skip: _toInt(json['skip']),
      limit: json['limit'] == null ? products.length : _toInt(json['limit']),
    );
  }
}
