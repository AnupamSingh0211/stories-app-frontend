import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_typography.dart';

class GlassyBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color contentColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color activeBackgroundColor;
  final Color activeBorderColor;
  final Color selectedIconColor;
  final Color defaultIconColor;
  final Color selectedLabelColor;
  final Color defaultLabelColor;
  final TextStyle? selectedLabelStyle;
  final TextStyle? defaultLabelStyle;

  const GlassyBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.contentColor = Colors.white,
    this.backgroundColor = const Color(0x2EFFFFFF),
    this.borderColor = const Color(0x3DFFFFFF),
    this.activeBackgroundColor = const Color(0x29FFFFFF),
    this.activeBorderColor = const Color(0x3DFFFFFF),
    this.selectedIconColor = Colors.white,
    this.defaultIconColor = Colors.white,
    this.selectedLabelColor = Colors.white,
    this.defaultLabelColor = Colors.white,
    this.selectedLabelStyle,
    this.defaultLabelStyle,
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
                backgroundColor: backgroundColor,
                borderColor: borderColor,
                child: Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: _buildNavItem(
                          0,
                          'Home',
                          defaultIconPath:
                              'assets/icons/new_boopi/home_component.svg',
                          activeIconPath:
                              'assets/icons/new_boopi/home_component.svg',
                          contentColor: contentColor,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: _buildNavItem(
                          1,
                          'Popular',
                          defaultIconPath:
                              'assets/icons/new_boopi/popular_component.svg',
                          activeIconPath:
                              'assets/icons/new_boopi/popular_component.svg',
                          contentColor: contentColor,
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
                              'assets/icons/new_boopi/soonfill_component.svg',
                          contentColor: contentColor,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              backgroundColor: backgroundColor,
              borderColor: borderColor,
              child: _buildNavItem(
                3,
                'Profile',
                defaultIconPath: 'assets/icons/new_boopi/person_component.svg',
                activeIconPath:
                    'assets/icons/new_boopi/State=Bold, Icon=Profile.svg',
                compact: true,
                contentColor: contentColor,
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
    required Color contentColor,
    bool compact = false,
  }) {
    final isActive = currentIndex == index;
    final showActiveBackground = isActive && !compact;
    final iconPath = isActive ? activeIconPath : defaultIconPath;
    final preserveIconColors = iconPath.endsWith('soonfill_component.svg');
    final iconColor = isActive
        ? (selectedIconColor == Colors.white ? contentColor : selectedIconColor)
        : (defaultIconColor == Colors.white ? contentColor : defaultIconColor);
    final labelColor = isActive
        ? (selectedLabelColor == Colors.white
              ? contentColor
              : selectedLabelColor)
        : (defaultLabelColor == Colors.white
              ? contentColor
              : defaultLabelColor);
    final labelStyle = isActive ? selectedLabelStyle : defaultLabelStyle;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: compact ? 44 : 76,
        height: 52,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 0 : 12,
          vertical: compact ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: showActiveBackground
              ? activeBackgroundColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: showActiveBackground
              ? Border.all(color: activeBorderColor)
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
                colorFilter: preserveIconColors
                    ? null
                    : ColorFilter.mode(iconColor, BlendMode.srcIn),
                width: 24,
                height: 24,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.visible,
              textAlign: TextAlign.center,
              style: (labelStyle ?? AppTypography.captionBold).copyWith(
                color: labelColor,
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
    required this.backgroundColor,
    required this.borderColor,
    this.padding = EdgeInsets.zero,
    this.width,
  });

  final Widget child;
  final double height;
  final double radius;
  final Color backgroundColor;
  final Color borderColor;
  final EdgeInsetsGeometry padding;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
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
            color: backgroundColor,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
