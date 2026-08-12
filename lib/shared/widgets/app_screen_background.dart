import 'package:flutter/material.dart';

import '../theme/app_gradients.dart';

abstract final class AppBackgroundAssets {
  static const shiningCover = 'assets/images/backgrounds/shining_cover.png';
}

abstract final class AppBackgroundTokens {
  static const shiningCoverOpacity = 0.6;
}

class AppScreenBackground extends StatelessWidget {
  const AppScreenBackground({super.key, required this.child, this.safeArea});

  final Widget child;
  final bool? safeArea;

  @override
  Widget build(BuildContext context) {
    final content = safeArea == true
        ? SafeArea(bottom: false, child: child)
        : child;

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppGradients.screenBackground),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: AppBackgroundTokens.shiningCoverOpacity,
            child: Image.asset(
              AppBackgroundAssets.shiningCover,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.medium,
            ),
          ),
          content,
        ],
      ),
    );
  }
}
