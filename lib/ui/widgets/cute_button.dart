import 'package:flutter/material.dart';

import '../../estetica/color.dart';

/// Boton pastel redondeado con sombra suave y efecto de pulsacion.
class CuteButton extends StatefulWidget {
  const CuteButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.gradient,
    this.foregroundColor = CuteTheme.white,
    this.fontSize = 20,
    this.height = 58,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Icono opcional a la izquierda del texto.
  final IconData? icon;

  /// Degradado del boton. Por defecto usa el salmon pastel.
  final Gradient? gradient;

  final Color foregroundColor;
  final double fontSize;
  final double height;

  @override
  State<CuteButton> createState() => _CuteButtonState();
}

class _CuteButtonState extends State<CuteButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onPressed,
        child: Container(
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: 26),
          decoration: BoxDecoration(
            gradient: enabled
                ? (widget.gradient ?? CuteTheme.buttonGradient)
                : null,
            color: enabled ? null : CuteTheme.white.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(widget.height / 2),
            border: Border.all(
              color: CuteTheme.white.withValues(alpha: 0.85),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: CuteTheme.shadow,
                offset: Offset(0, _pressed ? 2 : 6),
                blurRadius: _pressed ? 4 : 12,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  color: enabled
                      ? widget.foregroundColor
                      : CuteTheme.ink.withValues(alpha: 0.5),
                  size: widget.fontSize + 4,
                ),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: CuteTheme.font(
                    size: widget.fontSize,
                    weight: 7,
                    color: enabled
                        ? widget.foregroundColor
                        : CuteTheme.ink.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pastilla pequena para mostrar textos informativos (controles, pistas).
class CuteChip extends StatelessWidget {
  const CuteChip({super.key, required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: CuteTheme.white.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: CuteTheme.lilac, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: CuteTheme.text),
            const SizedBox(width: 6),
          ],
          Text(label, style: CuteTheme.font(size: 13, weight: 6)),
        ],
      ),
    );
  }
}
