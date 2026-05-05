import 'package:flutter/material.dart';
import 'profile_setup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // 🌌 Background Image
          SizedBox.expand(
            child: Image.asset(
              'assets/images/bedtime_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // 🌑 Overlay
          Container(color: colors.surface.withValues(alpha: 0.6)),

          // 📱 Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 100),

                  // Title
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

                  // Subtitle
                  Text(
                    "Step into a world of gentle tales \nand quiet nights. Your journey to restful \nsleep starts here.",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.7),
                    ),
                  ),

                  const Spacer(),

                  // Apple Button
                  _buildPrimaryButton(
                    context,
                    "Continue with Apple",
                    () => _navigateToProfile(context),
                  ),

                  const SizedBox(height: 16),

                  // Google Button
                  _buildOutlineButton(
                    context,
                    "Continue with Google",
                    () => _navigateToProfile(context),
                  ),

                  const SizedBox(height: 16),

                  // Email Button
                  _buildSecondaryButton(
                    context,
                    "Continue with Email",
                    () => _navigateToProfile(context),
                  ),

                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: () => _navigateToProfile(context),
                    child: Text(
                      "Browse as a Guest →",
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

  // 🔘 Primary Button
  Widget _buildPrimaryButton(
    BuildContext context,
    String text,
    VoidCallback onTap,
  ) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: colors.onSurface,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/icons/ios_icon.png', height: 20),
            const SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                color: colors.surface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔘 Outline Button
  Widget _buildOutlineButton(
    BuildContext context,
    String text,
    VoidCallback onTap,
  ) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: colors.outline.withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/icons/google_icon.webp', height: 20),
            const SizedBox(width: 10),
            Text(text, style: TextStyle(color: colors.onSurface)),
          ],
        ),
      ),
    );
  }

  // 🔘 Gradient Button
  Widget _buildSecondaryButton(
    BuildContext context,
    String text,
    VoidCallback onTap,
  ) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(colors: [colors.primary, colors.secondary]),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/icons/email_icon.webp', height: 24),
            const SizedBox(width: 10),
            Text(
              text,
              style: TextStyle(
                color: colors.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
