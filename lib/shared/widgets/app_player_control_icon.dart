import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum AppPlayerControlIconType {
  play,
  playSmall,
  next,
  pause,
  circlePlay,
  replay,
  undo,
  repeat,
  camera,
}

class AppPlayerControlIcon extends StatelessWidget {
  const AppPlayerControlIcon({
    required this.type,
    super.key,
    this.semanticLabel,
  });

  final AppPlayerControlIconType type;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final spec = _AppPlayerControlIconSpec.fromType(type);

    return SvgPicture.asset(
      spec.asset,
      width: spec.size.width,
      height: spec.size.height,
      semanticsLabel: semanticLabel,
    );
  }
}

class AppPlayerControlButton extends StatelessWidget {
  const AppPlayerControlButton({
    required this.type,
    required this.onPressed,
    super.key,
    this.semanticLabel,
  });

  final AppPlayerControlIconType type;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final spec = _AppPlayerControlIconSpec.fromType(type);

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
        icon: AppPlayerControlIcon(type: type, semanticLabel: semanticLabel),
      ),
    );
  }
}

class _AppPlayerControlIconSpec {
  const _AppPlayerControlIconSpec({required this.asset, required this.size});

  final String asset;
  final Size size;

  static _AppPlayerControlIconSpec fromType(AppPlayerControlIconType type) {
    return switch (type) {
      AppPlayerControlIconType.play => const _AppPlayerControlIconSpec(
        asset: 'assets/icons/player/play.svg',
        size: Size.square(32),
      ),
      AppPlayerControlIconType.playSmall => const _AppPlayerControlIconSpec(
        asset: 'assets/icons/player/play_small.svg',
        size: Size.square(24),
      ),
      AppPlayerControlIconType.next => const _AppPlayerControlIconSpec(
        asset: 'assets/icons/player/next.svg',
        size: Size.square(16),
      ),
      AppPlayerControlIconType.pause => const _AppPlayerControlIconSpec(
        asset: 'assets/icons/player/pause.svg',
        size: Size.square(24),
      ),
      AppPlayerControlIconType.circlePlay => const _AppPlayerControlIconSpec(
        asset: 'assets/icons/player/circle_play.svg',
        size: Size.square(24),
      ),
      AppPlayerControlIconType.replay => const _AppPlayerControlIconSpec(
        asset: 'assets/icons/player/replay.svg',
        size: Size.square(24),
      ),
      AppPlayerControlIconType.undo => const _AppPlayerControlIconSpec(
        asset: 'assets/icons/player/undo.svg',
        size: Size.square(24),
      ),
      AppPlayerControlIconType.repeat => const _AppPlayerControlIconSpec(
        asset: 'assets/icons/player/repeat.svg',
        size: Size.square(24),
      ),
      AppPlayerControlIconType.camera => const _AppPlayerControlIconSpec(
        asset: 'assets/icons/player/camera.svg',
        size: Size.square(24),
      ),
    };
  }
}
