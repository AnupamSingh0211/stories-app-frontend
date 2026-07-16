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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.white.withValues(alpha: 0.1), // Glassy background
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, 'Home', 'assets/icons/new_boopi/State=Default, Icon=Home.svg'),
                _buildNavItem(1, 'Popular', 'assets/icons/new_boopi/State=Default, Icon=Sparkle.svg'),
                _buildNavItem(2, 'Soon', 'assets/icons/new_boopi/State=Default, Icon=Play.svg'),
                _buildNavItem(3, 'Profile', 'assets/icons/new_boopi/State=Default, Icon=Profile.svg'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String label, String iconPath) {
    final isActive = currentIndex == index;
    
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: isActive ? Border.all(color: Colors.white.withValues(alpha: 0.1)) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              iconPath,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              width: 24,
              height: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
