import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/cart_item.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/animated_entry.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/quantity_stepper.dart';
import '../../widgets/sort_sheet.dart' show SheetContainer;
import '../../widgets/state_views.dart';
import '../shell/main_shell.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Kosongkan keranjang?', style: AppText.heading(18)),
        content: Text('Semua barang di keranjang akan dihapus.', style: AppText.body(14, color: AppColors.plumMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.pinkDeep),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) context.read<CartProvider>().clear();
  }

  Future<void> _checkout(BuildContext context) async {
    final cart = context.read<CartProvider>();
    final summary = (
      items: cart.totalItems,
      total: cart.total,
      savings: cart.totalSavings,
      order: 'ANG-${Random().nextInt(900000) + 100000}',
    );
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CheckoutSuccessSheet(
        items: summary.items,
        total: summary.total,
        savings: summary.savings,
        orderId: summary.order,
      ),
    );
    if (!context.mounted) return;
    cart.clear();
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final items = cart.items;
    final topPad = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: items.isEmpty
            ? Column(
                key: const ValueKey('empty'),
                children: [
                  SizedBox(height: topPad + 16),
                  const _CartHeader(count: 0, onClear: null),
                  Expanded(
                    child: EmptyState(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Keranjangmu masih kosong',
                      message: 'Yuk isi dengan barang-barang imut pilihanmu!',
                      actionLabel: 'Mulai Belanja',
                      onAction: () => context.go(AppRoutes.home),
                    ),
                  ),
                ],
              )
            : CustomScrollView(
                key: const ValueKey('list'),
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: SizedBox(height: topPad + 16)),
                  SliverToBoxAdapter(
                    child: _CartHeader(count: cart.lineCount, onClear: () => _confirmClear(context)),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => AnimatedEntry(
                          key: ValueKey('cart-${items[i].product.id}'),
                          id: 'cart-${items[i].product.id}',
                          index: i,
                          child: _CartTile(item: items[i], index: i),
                        ),
                        childCount: items.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: _VoucherCard()),
                  const SliverToBoxAdapter(child: _SummaryCard()),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: PrimaryButton(
                        label: 'Lanjut ke Pembayaran',
                        icon: Icons.payments_rounded,
                        trailing: _AnimatedPrice(
                          value: cart.total,
                          style: AppText.label(16, color: Colors.white, weight: FontWeight.w800),
                        ),
                        onPressed: () => _checkout(context),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, kNavBarClearance),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text('Simulasi DummyJSON, tidak ada transaksi riil',
                              style: AppText.body(12.5, color: AppColors.plumMuted)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _CartHeader extends StatelessWidget {
  const _CartHeader({required this.count, required this.onClear});
  final int count;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(color: AppColors.pinkTint, shape: BoxShape.circle),
            child: const Icon(Icons.shopping_bag_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text('Keranjang Saya', style: AppText.heading(22, weight: FontWeight.w800))),
                    if (count > 0) ...[
                      const SizedBox(width: 8),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                        child: Container(
                          key: ValueKey(count),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.pinkDeep, borderRadius: BorderRadius.circular(50)),
                          child: Text('$count Barang', style: AppText.label(11, color: Colors.white)),
                        ),
                      ),
                    ],
                  ],
                ),
                Text('Siap di-checkout dengan diskon imut ✨', style: AppText.body(13, color: AppColors.plumMuted)),
              ],
            ),
          ),
          if (onClear != null)
            IconButton(
              tooltip: 'Hapus Semua',
              onPressed: onClear,
              style: IconButton.styleFrom(backgroundColor: AppColors.pinkTint),
              icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.primary),
            ),
        ],
      ),
    );
  }
}

class _CartTile extends StatelessWidget {
  const _CartTile({required this.item, required this.index});
  final CartItem item;
  final int index;

  void _remove(BuildContext context) {
    final cart = context.read<CartProvider>();
    final removed = cart.remove(item.product.id);
    if (removed == null) return;
    showAppSnack(
      context,
      '${item.product.title} dihapus dari keranjang',
      icon: Icons.delete_rounded,
      actionLabel: 'Urungkan',
      onAction: () => cart.restore(removed),
    );
  }

  Future<void> _askRemove(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Hapus barang ini?', style: AppText.heading(18)),
        content: Text('Jumlah sudah 1. Hapus "${item.product.title}" dari keranjang?',
            style: AppText.body(14, color: AppColors.plumMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) _remove(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = item.product;
    final cart = context.read<CartProvider>();

    return Dismissible(
      key: ValueKey('dismiss-cart-${p.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _remove(context),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(22)),
        child: const Icon(Icons.delete_rounded, color: AppColors.danger),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppColors.softShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => context.push(AppRoutes.detail(p.id, heroScope: 'cart')),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 92,
                  height: 92,
                  color: index.isEven ? AppColors.pinkTint : AppColors.blue,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'cart-${p.id}',
                        child: AppNetworkImage(url: p.thumbnail, cacheWidth: 250, background: Colors.transparent),
                      ),
                      if (p.hasDiscount)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(50)),
                            child: Text('DISKON', style: AppText.label(9, color: AppColors.onMint, weight: FontWeight.w800)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              Fmt.prettyCategory(p.category).toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.label(10.5, color: index.isEven ? AppColors.primary : AppColors.onBlue),
                            ),
                            Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.heading(15)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _remove(context),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: const BoxDecoration(color: AppColors.dangerSoft, shape: BoxShape.circle),
                          child: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    children: [
                      Text(Fmt.price(p.price), style: AppText.price(16)),
                      if (p.hasDiscount)
                        Text(
                          Fmt.price(p.originalPrice),
                          style: AppText.body(12, color: AppColors.plumMuted).copyWith(decoration: TextDecoration.lineThrough),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      QuantityStepper(
                        compact: true,
                        value: item.quantity,
                        max: p.stock < 1 ? 1 : p.stock,
                        onChanged: (v) => cart.setQuantity(p.id, v),
                        onMinReached: () => _askRemove(context),
                        onMaxReached: () => showAppSnack(
                          context,
                          'Stok hanya tersisa ${p.stock}',
                          icon: Icons.inventory_2_rounded,
                        ),
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Subtotal', style: AppText.body(11, color: AppColors.plumMuted)),
                          FittedBox(
                            child: _AnimatedPrice(value: item.subtotal, style: AppText.price(16)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoucherCard extends StatefulWidget {
  const _VoucherCard();

  @override
  State<_VoucherCard> createState() => _VoucherCardState();
}

class _VoucherCardState extends State<_VoucherCard> {
  final TextEditingController _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _apply([String? code]) {
    final value = code ?? _code.text;
    final v = context.read<CartProvider>().applyVoucher(value);
    FocusScope.of(context).unfocus();
    if (v == null) {
      showAppSnack(context, 'Kode voucher tidak valid', isError: true, icon: Icons.error_rounded);
    } else {
      _code.clear();
      showAppSnack(context, 'Voucher ${v.code} diterapkan! Hemat ${v.percent.round()}%', icon: Icons.local_offer_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final voucher = context.select<CartProvider, Voucher?>((c) => c.voucher);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.pinkTint, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_activity_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text('Voucher & Promo', style: AppText.heading(16))),
              AnimatedOpacity(
                opacity: voucher != null ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(50)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.onMint),
                      const SizedBox(width: 4),
                      Text('Diterapkan', style: AppText.label(11.5, color: AppColors.onMint)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: voucher != null
                ? Container(
                    key: ValueKey(voucher.code),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppColors.softShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(color: AppColors.pinkTint, shape: BoxShape.circle),
                          child: Text('%', style: AppText.heading(16, color: AppColors.primary)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(voucher.code, style: AppText.heading(16, weight: FontWeight.w800, color: AppColors.primary)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(color: AppColors.pink, borderRadius: BorderRadius.circular(50)),
                                    child: Text('${voucher.percent.round()}% OFF', style: AppText.label(10, color: AppColors.primary)),
                                  ),
                                ],
                              ),
                              Text(voucher.description, style: AppText.body(12.5, color: AppColors.plumMuted)),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Hapus voucher',
                          onPressed: context.read<CartProvider>().removeVoucher,
                          icon: const Icon(Icons.close_rounded, color: AppColors.plum),
                        ),
                      ],
                    ),
                  )
                : Column(
                    key: const ValueKey('input'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _code,
                              textCapitalization: TextCapitalization.characters,
                              onSubmitted: (_) => _apply(),
                              decoration: const InputDecoration(
                                hintText: 'Masukkan kode voucher',
                                prefixIcon: Icon(Icons.confirmation_number_outlined),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 50,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: _apply,
                              child: const Text('Pakai'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: CartProvider.availableVouchers
                            .map((v) => ActionChip(
                                  label: Text(v.code, style: AppText.label(11.5, color: AppColors.primary)),
                                  avatar: const Icon(Icons.local_offer_outlined, size: 14, color: AppColors.primary),
                                  backgroundColor: AppColors.surface,
                                  side: const BorderSide(color: AppColors.pinkSoft),
                                  shape: const StadiumBorder(),
                                  onPressed: () => _apply(v.code),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard();

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Ringkasan Pembayaran', style: AppText.heading(17)),
            ],
          ),
          const SizedBox(height: 14),
          _row('Total Barang', Text('${cart.totalItems} pcs', style: AppText.label(14))),
          _row(
            'Subtotal (harga normal)',
            Text(
              Fmt.price(cart.originalSubtotal),
              style: AppText.body(14, color: AppColors.plumMuted).copyWith(
                decoration: cart.productDiscount > 0.004 ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          _row(
            'Hemat Diskon',
            _AnimatedPrice(value: -cart.productDiscount, style: AppText.label(14, color: AppColors.mintDeep)),
            icon: Icons.sell_outlined,
            labelColor: AppColors.mintDeep,
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            child: cart.voucher == null
                ? const SizedBox(width: double.infinity)
                : _row(
                    'Voucher ${cart.voucher!.code}',
                    _AnimatedPrice(value: -cart.voucherDiscount, style: AppText.label(14, color: AppColors.mintDeep)),
                    icon: Icons.local_activity_outlined,
                    labelColor: AppColors.mintDeep,
                  ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: AppColors.pinkSoft, height: 1),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL BAYAR', style: AppText.label(12)),
                    Text('Sudah termasuk PPN', style: AppText.body(12, color: AppColors.primary)),
                  ],
                ),
              ),
              _AnimatedPrice(value: cart.total, style: AppText.price(30)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, Widget value, {IconData? icon, Color labelColor = AppColors.plum}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 17, color: labelColor),
            const SizedBox(width: 6),
          ],
          Expanded(child: Text(label, style: AppText.body(14.5, color: labelColor))),
          value,
        ],
      ),
    );
  }
}

/// Angka harga yang "menghitung" ke nilai baru (count-up 400 ms).
class _AnimatedPrice extends StatelessWidget {
  const _AnimatedPrice({required this.value, required this.style});
  final double value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(Fmt.price(v), style: style),
    );
  }
}

class _CheckoutSuccessSheet extends StatelessWidget {
  const _CheckoutSuccessSheet({
    required this.items,
    required this.total,
    required this.savings,
    required this.orderId,
  });

  final int items;
  final double total;
  final double savings;
  final String orderId;

  @override
  Widget build(BuildContext context) {
    return SheetContainer(
      title: 'Pembayaran',
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (context, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(color: AppColors.mint, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, size: 56, color: AppColors.mintDeep),
            ),
          ),
          const SizedBox(height: 16),
          Text('Pesanan berhasil dibuat! 🎉', style: AppText.heading(20)),
          const SizedBox(height: 4),
          Text('(simulasi, tidak ada transaksi riil)', style: AppText.body(13, color: AppColors.plumMuted)),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.pinkTint, borderRadius: BorderRadius.circular(18)),
            child: Column(
              children: [
                _line('No. Pesanan', orderId),
                _line('Jumlah Barang', '$items pcs'),
                _line('Total Hemat', Fmt.price(savings)),
                const Divider(color: AppColors.pinkSoft),
                _line('Total Bayar', Fmt.price(total), bold: true),
              ],
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Kembali Belanja',
            icon: Icons.storefront_rounded,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _line(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppText.body(14, color: AppColors.plumMuted))),
          Text(value, style: bold ? AppText.price(18) : AppText.label(14)),
        ],
      ),
    );
  }
}
