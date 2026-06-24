import 'package:flutter/material.dart';

class OnboardingProgressHeader extends StatelessWidget {
  const OnboardingProgressHeader({
    super.key,
    required this.activeStep,
    required this.onBack,
    this.stepCount = 3,
  }) : assert(activeStep >= 0),
       assert(stepCount > 0),
       assert(activeStep < stepCount);

  final int activeStep;
  final int stepCount;
  final VoidCallback onBack;

  static const activeColor = Color(0xFF00AEEF);
  static const inactiveColor = Color(0xFFD0D5DD);
  static const _figmaFrameWidth = 390.0;
  static const _figmaHorizontalInset = 16.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding =
            constraints.maxWidth * (_figmaHorizontalInset / _figmaFrameWidth);

        return SizedBox(
          height: 80,
          child: Padding(
            padding: EdgeInsets.fromLTRB(horizontalPadding, 16, 16, 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox.square(
                    dimension: 24,
                    child: IconButton(
                      key: const ValueKey('onboardingBackButton'),
                      onPressed: onBack,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 24,
                        height: 24,
                      ),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Color(0xFF001033),
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    key: const ValueKey('onboardingProgressIndicator'),
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(stepCount, (index) {
                      return Padding(
                        padding: EdgeInsets.only(
                          right: index == stepCount - 1 ? 0 : 8,
                        ),
                        child: DecoratedBox(
                          key: ValueKey(
                            'onboardingStep${index + 1}'
                            '${index == activeStep ? 'Active' : 'Inactive'}',
                          ),
                          decoration: BoxDecoration(
                            color: index == activeStep
                                ? activeColor
                                : inactiveColor,
                            shape: BoxShape.circle,
                          ),
                          child: const SizedBox.square(dimension: 8),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
