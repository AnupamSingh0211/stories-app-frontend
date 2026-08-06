import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum AppActionIconType { globe, sparks, language, heart, help, share, privacy }

class AppActionIcon extends StatelessWidget {
  const AppActionIcon({required this.type, super.key, this.semanticLabel});

  final AppActionIconType type;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final spec = _AppActionIconSpec.fromType(type);

    return SvgPicture.asset(
      spec.asset,
      width: spec.size.width,
      height: spec.size.height,
      semanticsLabel: semanticLabel,
    );
  }
}

class AppActionIconButton extends StatelessWidget {
  const AppActionIconButton({
    required this.type,
    required this.onPressed,
    super.key,
    this.semanticLabel,
  });

  final AppActionIconType type;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final spec = _AppActionIconSpec.fromType(type);

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
        icon: AppActionIcon(type: type, semanticLabel: semanticLabel),
      ),
    );
  }
}

class _AppActionIconSpec {
  const _AppActionIconSpec({required this.asset, required this.size});

  final String asset;
  final Size size;

  static _AppActionIconSpec fromType(AppActionIconType type) {
    return switch (type) {
      AppActionIconType.globe => const _AppActionIconSpec(
        asset: 'assets/icons/new_boopi/State=Default, Icon=Website.svg',
        size: Size(18.9975, 18.9975),
      ),
      AppActionIconType.sparks => const _AppActionIconSpec(
        asset: 'assets/icons/new_boopi/State=Default, Icon=Sparkle.svg',
        size: Size.square(20),
      ),
      AppActionIconType.language => const _AppActionIconSpec(
        asset: 'assets/icons/new_boopi/State=Default, Icon=Website.svg',
        size: Size.square(20),
      ),
      AppActionIconType.heart => const _AppActionIconSpec(
        asset: 'assets/icons/new_boopi/State=Default, Icon=Heart.svg',
        size: Size.square(20),
      ),
      AppActionIconType.help => const _AppActionIconSpec(
        asset: 'assets/icons/new_boopi/State=Default, Icon=Danger Circle.svg',
        size: Size.square(20),
      ),
      AppActionIconType.share => const _AppActionIconSpec(
        asset: 'assets/icons/new_boopi/clarity_share-line.svg',
        size: Size.square(20),
      ),
      AppActionIconType.privacy => const _AppActionIconSpec(
        asset: 'assets/icons/new_boopi/State=Default, Icon=Shield Done.svg',
        size: Size.square(20),
      ),
    };
  }
}
