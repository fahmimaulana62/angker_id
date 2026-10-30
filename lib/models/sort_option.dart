/// Pilihan urutan yang dikirim ke endpoint ?sortBy=&order=
enum SortOption {
  none('Paling Relevan', null, null),
  ratingDesc('Rating Tertinggi', 'rating', 'desc'),
  priceAsc('Harga Termurah', 'price', 'asc'),
  priceDesc('Harga Termahal', 'price', 'desc'),
  titleAsc('Nama A-Z', 'title', 'asc'),
  titleDesc('Nama Z-A', 'title', 'desc');

  const SortOption(this.label, this.sortBy, this.order);

  final String label;
  final String? sortBy;
  final String? order;
}
