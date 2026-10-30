/// Helper format tampilan (harga, tanggal, nama kategori).
class Fmt {
  Fmt._();

  static const _bulan = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  /// 1899.9 -> "$1,899.90"
  static String price(double value) {
    final fixed = value.abs().toStringAsFixed(2);
    final parts = fixed.split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]},',
    );
    return '${value < 0 ? '-' : ''}\$$whole.${parts[1]}';
  }

  /// "2024-05-23T08:56:21.618Z" -> "23 Mei 2024"
  static String date(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    final local = d.toLocal();
    return '${local.day.toString().padLeft(2, '0')} ${_bulan[local.month - 1]} ${local.year}';
  }

  /// "womens-dresses" -> "Womens Dresses"
  static String prettyCategory(String slug) {
    if (slug.isEmpty) return 'Lainnya';
    return slug
        .split('-')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  /// "Nadia Sari" -> "NS"
  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  /// Rating ditampilkan 2 desimal seperti data asli (4.94).
  static String rating(double r) => r.toStringAsFixed(r == r.roundToDouble() ? 1 : 2);
}
