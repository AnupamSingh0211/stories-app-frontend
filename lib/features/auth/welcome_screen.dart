import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/pill_button.dart';
import 'profile_setup_screen.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          RepaintBoundary(
            child: Stack(
              children: [
                const _BackgroundImage(),
                Container(color: colors.surface.withValues(alpha: 0.6)),
              ],
            ),
          ),
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
                  _AuthButton(
                    text: "Continue with Apple",
                    iconPath: 'assets/icons/ios_icon.png',
                    iconHeight: 20,
                    iconGap: 4,
                    textColor: colors.surface,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileSetupScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _AuthButton(
                    text: "Continue with Google",
                    iconPath: 'assets/icons/google_icon.png',
                    iconHeight: 20,
                    iconGap: 10,
                    textColor: colors.onSurface,
                    border: Border.all(
                      color: colors.outline.withValues(alpha: 0.3),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileSetupScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _AuthButton(
                    text: "Continue with Email",
                    iconPath: 'assets/icons/email_icon.png',
                    iconHeight: 24,
                    iconGap: 10,
                    textColor: colors.onPrimary,
                    fontWeight: FontWeight.w600,
                    gradient: LinearGradient(
                      colors: [colors.primary, colors.secondary],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileSetupScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileSetupScreen(),
                        ),
                      );
                    },
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
}

class _BackgroundImage extends StatelessWidget {
  const _BackgroundImage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width.toInt();

    return SizedBox.expand(
      child: Image.asset(
        'assets/images/welcome_bg.png',
        fit: BoxFit.cover,
        cacheWidth: screenWidth,
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  const _AuthButton({
    required this.text,
    required this.iconPath,
    required this.iconHeight,
    required this.iconGap,
    required this.textColor,
    required this.onTap,
    this.fontWeight,
    this.color,
    this.gradient,
    this.border,
  });

  final String text;
  final String iconPath;
  final double iconHeight;
  final double iconGap;
  final Color textColor;
  final VoidCallback onTap;
  final FontWeight? fontWeight;
  final Color? color;
  final Gradient? gradient;
  final Border? border;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

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
