import 'package:flutter/material.dart';

import '../theme/app_border_radius.dart';

class PillButton extends StatelessWidget {
  const PillButton({
    required this.onTap,
    required this.child,
    super.key,
    this.height = 50,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
    this.borderRadius = AppBorderRadius.radiusButton,
    this.color,
    this.gradient,
    this.border,
    this.boxShadow,
  }) : assert(
         color == null || gradient == null,
         'Cannot provide both color and gradient',
       );

  final VoidCallback? onTap;
  final Widget child;
  final double height;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? color;
  final Gradient? gradient;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: double.infinity,
        padding: padding,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: color,
          gradient: gradient,
          border: border,
          boxShadow: boxShadow,
        ),
        child: child,
      ),
    );
  }
}
