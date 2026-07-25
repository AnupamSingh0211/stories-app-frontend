import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class GlassyBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const GlassyBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        21,
        20,
        21,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      child: SizedBox(
        height: 68,
        child: Row(
          children: [
            Expanded(
              child: _GlassNavSurface(
                height: 68,
                radius: 34,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: _buildNavItem(
                          0,
                          'Home',
                          defaultIconPath:
                              'assets/icons/new_boopi/State=Default, Icon=Home.svg',
                          activeIconPath:
                              'assets/icons/new_boopi/State=Bold, Icon=Home.svg',
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: _buildNavItem(
                          1,
                          'Popular',
                          defaultIconPath:
                              'assets/icons/new_boopi/State=Default, Icon=Sparkle.svg',
                          activeIconPath:
                              'assets/icons/new_boopi/State=Bold, Icon=Sparkle.svg',
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: _buildNavItem(
                          2,
                          'Soon',
                          defaultIconPath:
                              'assets/icons/new_boopi/State=Default, Icon=Libaray.svg',
                          activeIconPath:
                              'assets/icons/new_boopi/State=Bold, Icon=Libaray.svg',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            _GlassNavSurface(
              width: 68,
              height: 68,
              radius: 34,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: _buildNavItem(
                3,
                'Profile',
                defaultIconPath:
                    'assets/icons/new_boopi/State=Default, Icon=Profile.svg',
                activeIconPath:
                    'assets/icons/new_boopi/State=Bold, Icon=Profile.svg',
                compact: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    String label, {
    required String defaultIconPath,
    required String activeIconPath,
    bool compact = false,
  }) {
    final isActive = currentIndex == index;
    final showActiveBackground = isActive && !compact;
    final iconPath = isActive ? activeIconPath : defaultIconPath;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: compact ? 44 : 76,
        height: 52,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 0 : 12,
          vertical: compact ? 4 : 8,
        ),
        decoration: BoxDecoration(
          color: showActiveBackground
              ? Colors.white.withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: showActiveBackground
              ? Border.all(color: Colors.white.withValues(alpha: 0.24))
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox.square(
              dimension: 24,
              child: SvgPicture.asset(
                iconPath,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
                width: 24,
                height: 24,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.visible,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                height: 12 / 10,
                letterSpacing: 1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassNavSurface extends StatelessWidget {
  const _GlassNavSurface({
    required this.child,
    required this.height,
    required this.radius,
    this.padding = EdgeInsets.zero,
    this.width,
  });

  final Widget child;
  final double height;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF007AFF).withValues(alpha: 0.1),
            offset: const Offset(0, -4),
            blurRadius: 20,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: ColoredBox(
            color: Colors.white.withValues(alpha: 0.18),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
