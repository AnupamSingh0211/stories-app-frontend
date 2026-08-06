import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum AppNotificationIconType { off, outline, solid }

class AppNotificationIcon extends StatelessWidget {
  const AppNotificationIcon({
    required this.type,
    super.key,
    this.semanticLabel,
  });

  final AppNotificationIconType type;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final spec = _AppNotificationIconSpec.fromType(type);

    return SvgPicture.asset(
      spec.asset,
      width: spec.size.width,
      height: spec.size.height,
      semanticsLabel: semanticLabel,
    );
  }
}

class AppNotificationIconButton extends StatelessWidget {
  const AppNotificationIconButton({
    required this.type,
    required this.onPressed,
    super.key,
    this.semanticLabel,
  });

  final AppNotificationIconType type;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final spec = _AppNotificationIconSpec.fromType(type);

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: BoxConstraints.tight(spec.size),
        style: const ButtonStyle(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: AppNotificationIcon(type: type, semanticLabel: semanticLabel),
      ),
    );
  }
}

class _AppNotificationIconSpec {
  const _AppNotificationIconSpec({required this.asset, required this.size});

  final String asset;
  final Size size;

  static _AppNotificationIconSpec fromType(AppNotificationIconType type) {
    return switch (type) {
      AppNotificationIconType.off => const _AppNotificationIconSpec(
        asset: 'assets/icons/new_boopi/State=Default, Icon=Notification.svg',
        size: Size.square(24),
      ),
      AppNotificationIconType.outline => const _AppNotificationIconSpec(
        asset: 'assets/icons/new_boopi/State=Default, Icon=Notification.svg',
        size: Size.square(18),
      ),
      AppNotificationIconType.solid => const _AppNotificationIconSpec(
        asset: 'assets/icons/new_boopi/State=Bold, Icon=Notification.svg',
        size: Size.square(18),
      ),
    };
  }
}
