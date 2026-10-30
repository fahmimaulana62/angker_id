// Unit test sederhana untuk helper & model (tidak butuh koneksi internet).
import 'package:angker_id/core/utils/formatters.dart';
import 'package:angker_id/models/cart_item.dart';
import 'package:angker_id/models/product_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('format harga memakai pemisah ribuan', () {
    expect(Fmt.price(1899.9), '\$1,899.90');
    expect(Fmt.price(9.99), '\$9.99');
  });

  test('slug kategori menjadi nama tampilan', () {
    expect(Fmt.prettyCategory('womens-dresses'), 'Womens Dresses');
  });

  test('parsing produk parsial dari endpoint select tidak crash', () {
    final p = Product.fromJson({'id': 11, 'title': 'Annibale Colombo Bed', 'price': 1899.99});
    expect(p.id, 11);
    expect(p.stock, 0);
    expect(p.reviews, isEmpty);
    expect(p.inStock, isFalse);
  });

  test('subtotal keranjang = harga x jumlah', () {
    const p = Product(id: 1, title: 'Mascara', price: 9.99, stock: 5);
    const item = CartItem(product: p, quantity: 2);
    expect(item.subtotal, closeTo(19.98, 0.001));
  });
}
