import 'dart:async';

import 'package:flutter/material.dart';

/// Fade + slide naik 16 px saat item pertama kali muncul, dengan jeda bertahap.
/// Item yang sudah pernah dianimasikan (berdasarkan [id]) langsung tampil
/// tanpa animasi lagi, sehingga scroll bolak-balik tetap ringan.
class AnimatedEntry extends StatefulWidget {
  const AnimatedEntry({
    super.key,
    required this.id,
    required this.index,
    required this.child,
    this.staggerMs = 40,
    this.maxDelayMs = 320,
  });

  final Object id;
  final int index;
  final Widget child;
  final int staggerMs;
  final int maxDelayMs;

  static final Set<Object> _seen = <Object>{};

  /// Hapus riwayat animasi (misal setelah refresh supaya batch baru beranimasi lagi).
  static void reset([String? prefix]) {
    if (prefix == null) {
      _seen.clear();
    } else {
      _seen.removeWhere((e) => e.toString().startsWith(prefix));
    }
  }

  @override
  State<AnimatedEntry> createState() => _AnimatedEntryState();
}

class _AnimatedEntryState extends State<AnimatedEntry> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final alreadySeen = AnimatedEntry._seen.contains(widget.id);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      value: alreadySeen ? 1 : 0,
    );
    final curved = _controller.drive(CurveTween(curve: Curves.easeOutCubic));
    _fade = curved;
    _slide = curved.drive(Tween<Offset>(begin: const Offset(0, 16), end: Offset.zero));

    if (!alreadySeen) {
      AnimatedEntry._seen.add(widget.id);
      final delay = (widget.index * widget.staggerMs).clamp(0, widget.maxDelayMs);
      _timer = Timer(Duration(milliseconds: delay), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: AnimatedBuilder(
        animation: _slide,
        builder: (context, child) => Transform.translate(offset: _slide.value, child: child),
        child: widget.child,
      ),
    );
  }
}
