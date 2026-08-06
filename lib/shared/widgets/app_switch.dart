import 'package:flutter/material.dart';

class AppSwitch extends StatelessWidget {
  const AppSwitch({
    required this.value,
    required this.onChanged,
    super.key,
    this.semanticLabel,
  });

  static const size = Size(43.105, 23.105);

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;

    return Semantics(
      toggled: value,
      enabled: enabled,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onChanged!(!value) : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.48,
          child: Container(
            width: size.width,
            height: size.height,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: value
                  ? const Color(0xFF4BA3F4)
                  : Colors.white.withAlpha(61),
              borderRadius: BorderRadius.circular(size.height / 2),
              border: Border.all(color: Colors.white.withAlpha(102)),
            ),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: size.height - 4,
              height: size.height - 4,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
