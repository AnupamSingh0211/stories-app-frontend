import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum StatusActionType { active, pending, completed }

class StatusActionIcon extends StatelessWidget {
  final StatusActionType type;
  final double size;

  const StatusActionIcon({
    super.key,
    required this.type,
    this.size = 32.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getBackgroundColor(),
        border: _getBorder(),
      ),
      child: Center(
        child: _buildInnerIcon(),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (type) {
      case StatusActionType.completed:
        return Colors.white;
      case StatusActionType.active:
      case StatusActionType.pending:
        return Colors.transparent;
    }
  }

  Border? _getBorder() {
    switch (type) {
      case StatusActionType.active:
        return Border.all(color: Colors.white, width: 2);
      case StatusActionType.pending:
        return Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2);
      case StatusActionType.completed:
        return null;
    }
  }

  Widget _buildInnerIcon() {
    switch (type) {
      case StatusActionType.active:
        return Container(
          width: size * 0.5,
          height: size * 0.5,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        );
      case StatusActionType.pending:
        return const SizedBox();
      case StatusActionType.completed:
        return SvgPicture.asset(
          'assets/icons/new_boopi/State=Default, Icon=Tick.svg',
          colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
          width: size * 0.6,
          height: size * 0.6,
        );
    }
  }
}
