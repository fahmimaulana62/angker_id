import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

/// Stepper jumlah ( − angka + ). Angka berganti dengan animasi slide vertikal.
/// Tombol otomatis nonaktif di batas [min] dan [max].
class QuantityStepper extends StatefulWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.max,
    required this.onChanged,
    this.min = 1,
    this.compact = false,
    this.onMaxReached,
    this.onMinReached,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final bool compact;
  final VoidCallback? onMaxReached;
  final VoidCallback? onMinReached;

  @override
  State<QuantityStepper> createState() => _QuantityStepperState();
}

class _QuantityStepperState extends State<QuantityStepper> {
  bool _increasing = true;

  void _change(int delta) {
    final next = widget.value + delta;
    if (next > widget.max) {
      widget.onMaxReached?.call();
      return;
    }
    if (next < widget.min) {
      widget.onMinReached?.call();
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _increasing = delta > 0);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.compact ? 32.0 : 40.0;
    final canDec = widget.value > widget.min;
    final canInc = widget.value < widget.max;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.pinkTint,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.pinkSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            size: size,
            enabled: canDec || widget.onMinReached != null,
            filled: false,
            dimmed: !canDec,
            onTap: () => _change(-1),
          ),
          SizedBox(
            width: widget.compact ? 34 : 42,
            child: ClipRect(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  final incoming = child.key == ValueKey(widget.value);
                  final dir = _increasing ? 1.0 : -1.0;
                  final begin = Offset(0, incoming ? 0.6 * dir : -0.6 * dir);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: animation.drive(Tween<Offset>(begin: begin, end: Offset.zero)),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  '${widget.value}',
                  key: ValueKey(widget.value),
                  textAlign: TextAlign.center,
                  style: AppText.heading(widget.compact ? 15 : 17, weight: FontWeight.w800),
                ),
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            size: size,
            enabled: true,
            filled: true,
            dimmed: !canInc,
            onTap: () => _change(1),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.size,
    required this.enabled,
    required this.filled,
    required this.dimmed,
    required this.onTap,
  });

  final IconData icon;
  final double size;
  final bool enabled;
  final bool filled;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = filled ? AppColors.pinkDeep : Colors.white;
    final fg = filled ? Colors.white : AppColors.plum;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: dimmed ? 0.4 : 1,
      child: Material(
        color: bg,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: size * 0.5, color: fg),
          ),
        ),
      ),
    );
  }
}
