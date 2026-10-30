import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../services/api_service_products.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/state_views.dart';

/// Form Tambah (POST /products/add) dan Edit (PUT /products/{id}).
class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.editProductId});

  /// null = mode tambah.
  final int? editProductId;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _brand = TextEditingController();
  final _price = TextEditingController();
  final _discount = TextEditingController(text: '0');
  final _stock = TextEditingController();
  final _thumbnail = TextEditingController();

  String? _category;
  Product? _original;
  bool _saving = false;
  bool _loadingOriginal = false;
  String? _loadError;

  bool get _isEdit => widget.editProductId != null;

  @override
  void initState() {
    super.initState();
    context.read<CategoryProvider>().fetchCategoryList();
    if (_isEdit) {
      final provider = context.read<ProductProvider>();
      final existing = provider.fullProduct(widget.editProductId!) ?? provider.peek(widget.editProductId!);
      if (existing != null) {
        _fill(existing);
      } else {
        _loadingOriginal = true;
        _loadOriginal(initial: true);
      }
    }
    _thumbnail.addListener(_onThumbChanged);
  }

  Future<void> _loadOriginal({bool initial = false}) async {
    if (!initial) {
      setState(() {
        _loadingOriginal = true;
        _loadError = null;
      });
    }
    try {
      final p = await context.read<ProductProvider>().getProductDetail(widget.editProductId!);
      if (!mounted) return;
      setState(() {
        _fill(p);
        _loadingOriginal = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _loadingOriginal = false;
      });
    }
  }

  void _fill(Product p) {
    _original = p;
    _title.text = p.title;
    _description.text = p.description;
    _brand.text = p.brand;
    _price.text = p.price.toStringAsFixed(2);
    _discount.text = p.discountPercentage.toStringAsFixed(p.discountPercentage == p.discountPercentage.roundToDouble() ? 0 : 2);
    _stock.text = '${p.stock}';
    _thumbnail.text = p.thumbnail;
    _category = p.category.isEmpty ? null : p.category;
  }

  void _onThumbChanged() => setState(() {});

  @override
  void dispose() {
    _thumbnail.removeListener(_onThumbChanged);
    for (final c in [_title, _description, _brand, _price, _discount, _stock, _thumbnail]) {
      c.dispose();
    }
    super.dispose();
  }

  double _parse(String s) => double.tryParse(s.trim().replaceAll(',', '.')) ?? 0;

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final base = _original ?? const Product(id: 0);
    final draft = base.copyWith(
      title: _title.text.trim(),
      description: _description.text.trim(),
      category: _category,
      brand: _brand.text.trim(),
      price: _parse(_price.text),
      discountPercentage: _parse(_discount.text),
      stock: int.tryParse(_stock.text.trim()) ?? 0,
      thumbnail: _thumbnail.text.trim(),
      images: _isEdit && base.thumbnail == _thumbnail.text.trim() ? null : (_thumbnail.text.trim().isEmpty ? const [] : [_thumbnail.text.trim()]),
    );

    setState(() => _saving = true);
    final provider = context.read<ProductProvider>();
    try {
      if (_isEdit) {
        // PUT /products/{id}
        final updated = await provider.updateProduct(draft);
        if (!mounted) return;
        context.read<WishlistProvider>().sync(updated);
        context.read<CartProvider>().sync(updated);
        showAppSnack(context, 'Produk berhasil diperbarui ($kMockNote)', icon: Icons.edit_rounded);
      } else {
        // POST /products/add
        final created = await provider.addProduct(draft);
        if (!mounted) return;
        showAppSnack(
          context,
          '"${created.title}" ditambahkan dengan id ${created.id} ($kMockNote)',
          icon: Icons.add_circle_rounded,
          duration: const Duration(seconds: 3),
        );
      }
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnack(context, e.message, isError: true, icon: Icons.error_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categoryList;
    final items = {...categories, if (_category != null) _category!}.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Produk' : 'Tambah Produk', style: AppText.heading(18)),
      ),
      body: _loadingOriginal
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? ErrorState(message: _loadError!, onRetry: _loadOriginal)
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    children: [
                      _InfoBanner(isEdit: _isEdit, id: widget.editProductId),
                      const SizedBox(height: 16),
                      _Preview(url: _thumbnail.text.trim()),
                      const SizedBox(height: 20),
                      _label('Judul Produk *'),
                      TextFormField(
                        controller: _title,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(hintText: 'contoh: BMW Pencil'),
                        validator: (v) => (v ?? '').trim().isEmpty ? 'Judul wajib diisi' : null,
                      ),
                      const SizedBox(height: 14),
                      _label('Deskripsi'),
                      TextFormField(
                        controller: _description,
                        maxLines: 4,
                        minLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(hintText: 'Ceritakan produk ini...'),
                      ),
                      const SizedBox(height: 14),
                      _label('Kategori *'),
                      DropdownButtonFormField<String>(
                        // ignore: deprecated_member_use
                        value: _category,
                        isExpanded: true,
                        borderRadius: BorderRadius.circular(16),
                        dropdownColor: AppColors.background,
                        hint: Text(categories.isEmpty ? 'Memuat kategori...' : 'Pilih kategori'),
                        items: items
                            .map((c) => DropdownMenuItem(value: c, child: Text(Fmt.prettyCategory(c))))
                            .toList(),
                        onChanged: (v) => setState(() => _category = v),
                        validator: (v) => v == null ? 'Kategori wajib dipilih' : null,
                      ),
                      const SizedBox(height: 14),
                      _label('Brand'),
                      TextFormField(
                        controller: _brand,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(hintText: 'contoh: Essence'),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Harga (USD) *'),
                                TextFormField(
                                  controller: _price,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                                  decoration: const InputDecoration(prefixText: '\$ ', hintText: '9.99'),
                                  validator: (v) {
                                    final n = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
                                    if (n == null) return 'Isi angka';
                                    if (n <= 0) return 'Harus > 0';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Diskon (%)'),
                                TextFormField(
                                  controller: _discount,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                                  decoration: const InputDecoration(suffixText: '%'),
                                  validator: (v) {
                                    final s = (v ?? '').trim();
                                    if (s.isEmpty) return null;
                                    final n = double.tryParse(s.replaceAll(',', '.'));
                                    if (n == null) return 'Isi angka';
                                    if (n < 0 || n >= 100) return '0 - 99';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _label('Stok *'),
                      TextFormField(
                        controller: _stock,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(hintText: 'contoh: 25', suffixText: 'unit'),
                        validator: (v) {
                          final n = int.tryParse((v ?? '').trim());
                          if (n == null) return 'Stok wajib berupa angka';
                          if (n < 0) return 'Stok tidak boleh negatif';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _label('URL Thumbnail (opsional)'),
                      TextFormField(
                        controller: _thumbnail,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          hintText: 'https://cdn.dummyjson.com/...',
                          prefixIcon: Icon(Icons.link_rounded),
                        ),
                        validator: (v) {
                          final s = (v ?? '').trim();
                          if (s.isEmpty) return null;
                          final uri = Uri.tryParse(s);
                          if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
                            return 'URL harus diawali http:// atau https://';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),
                      PrimaryButton(
                        label: _isEdit ? 'Simpan Perubahan (PUT)' : 'Tambah Produk (POST)',
                        icon: _isEdit ? Icons.save_rounded : Icons.add_rounded,
                        loading: _saving,
                        onPressed: _save,
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 4),
        child: Text(text, style: AppText.label(13)),
      );
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.isEdit, required this.id});
  final bool isEdit;
  final int? id;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.onBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isEdit
                  ? 'Mengirim PUT /products/$id. DummyJSON hanya mensimulasikan perubahan, jadi data disimpan di aplikasi selama app berjalan.'
                  : 'Mengirim POST /products/add. DummyJSON hanya mensimulasikan penambahan, jadi produk disimpan di aplikasi selama app berjalan.',
              style: AppText.body(12.5, color: AppColors.onBlue, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    final valid = url.startsWith('http://') || url.startsWith('https://');
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: AppColors.pinkTint,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.pinkSoft, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: valid
              ? AppNetworkImage(key: ValueKey(url), url: url, background: AppColors.pinkTint)
              : Column(
                  key: const ValueKey('placeholder'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_photo_alternate_outlined, size: 40, color: AppColors.pinkDeep),
                    const SizedBox(height: 6),
                    Text('Preview gambar', style: AppText.body(12, color: AppColors.plumMuted)),
                  ],
                ),
        ),
      ),
    );
  }
}
