import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
          child: SvgPicture.asset(
            value
                ? 'assets/icons/switch/switch_active.svg'
                : 'assets/icons/switch/switch_inactive.svg',
            width: size.width,
            height: size.height,
            semanticsLabel: semanticLabel,
          ),
        ),
      ),
    );
  }
}
