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
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: _GlassNavSurface(
              radius: 32,
              height: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: _buildNavItem(
                      0,
                      'Home',
                      defaultIconPath:
                          'assets/icons/new_boopi/State=Default, Icon=Home.svg',
                      activeIconPath:
                          'assets/icons/new_boopi/State=Bold, Icon=Home.svg',
                    ),
                  ),
                  Expanded(
                    child: _buildNavItem(
                      1,
                      'Popular',
                      defaultIconPath:
                          'assets/icons/new_boopi/State=Default, Icon=Sparkle.svg',
                      activeIconPath:
                          'assets/icons/new_boopi/State=Bold, Icon=Sparkle.svg',
                    ),
                  ),
                  Expanded(
                    child: _buildNavItem(
                      2,
                      'Soon',
                      defaultIconPath:
                          'assets/icons/new_boopi/State=Default, Icon=Libaray.svg',
                      activeIconPath:
                          'assets/icons/new_boopi/State=Bold, Icon=Libaray.svg',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          _GlassNavSurface(
            width: 64,
            height: 64,
            radius: 32,
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
    final iconPath = isActive ? activeIconPath : defaultIconPath;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: compact ? 64 : double.infinity,
        height: compact ? 64 : 56,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(compact ? 32 : 28),
          border: isActive
              ? Border.all(color: Colors.white.withValues(alpha: 0.24))
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox.square(
              dimension: 22,
              child: SvgPicture.asset(
                iconPath,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
                width: 22,
                height: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                height: 1,
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
    this.width,
  });

  final Widget child;
  final double height;
  final double radius;
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
            color: Colors.black.withValues(alpha: 0.12),
            offset: const Offset(0, 8),
            blurRadius: 18,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: ColoredBox(
            color: Colors.white.withValues(alpha: 0.14),
            child: child,
          ),
        ),
      ),
    );
  }
}
