import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/pill_button.dart';
import 'profile_setup_screen.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          _buildBackgroundImage(),
          Container(color: colors.surface.withValues(alpha: 0.6)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 100),
                  Text(
                    "Welcome to\nBedtime Stories",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 36,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Step into a world of gentle tales \nand quiet nights. Your journey to restful \nsleep starts here.",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const Spacer(),
                  _buildAuthButton(
                    text: "Continue with Apple",
                    iconPath: 'assets/icons/ios_icon.png',
                    iconHeight: 20,
                    iconGap: 4,
                    textColor: colors.surface,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                    onTap: () => _navigateToProfile(context),
                  ),
                  const SizedBox(height: 16),
                  _buildAuthButton(
                    text: "Continue with Google",
                    iconPath: 'assets/icons/google_icon.webp',
                    iconHeight: 20,
                    iconGap: 10,
                    textColor: colors.onSurface,
                    border: Border.all(
                      color: colors.outline.withValues(alpha: 0.3),
                    ),
                    onTap: () => _navigateToProfile(context),
                  ),
                  const SizedBox(height: 16),
                  _buildAuthButton(
                    text: "Continue with Email",
                    iconPath: 'assets/icons/email_icon.webp',
                    iconHeight: 24,
                    iconGap: 10,
                    textColor: colors.onPrimary,
                    fontWeight: FontWeight.w600,
                    gradient: LinearGradient(
                      colors: [colors.primary, colors.secondary],
                    ),
                    onTap: () => _navigateToProfile(context),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => _navigateToProfile(context),
                    child: Text(
                      "Browse as a Guest ->",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundImage() {
    return SizedBox.expand(
      child: Image.asset('assets/images/bedtime_bg.png', fit: BoxFit.cover),
    );
  }

  Widget _buildAuthButton({
    required String text,
    required String iconPath,
    required double iconHeight,
    required double iconGap,
    required Color textColor,
    required VoidCallback onTap,
    FontWeight? fontWeight,
    Color? color,
    Gradient? gradient,
    Border? border,
  }) {
    return PillButton(
      onTap: onTap,
      height: 56,
      color: color,
      gradient: gradient,
      border: border,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(iconPath, height: iconHeight),
          SizedBox(width: iconGap),
          Text(
            text,
            style: TextStyle(color: textColor, fontWeight: fontWeight),
          ),
        ],
      ),
    );
  }
}
