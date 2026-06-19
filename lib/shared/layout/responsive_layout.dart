import 'dart:math' as math;

import 'package:flutter/widgets.dart';

const double kFloatingNavigationHeight = 80;
const double kFloatingNavigationHorizontalMargin = 24;
const double kFloatingNavigationBottomGap = 12;

double floatingNavigationBottom(BuildContext context) {
  return math.max(
    kFloatingNavigationBottomGap,
    MediaQuery.viewPaddingOf(context).bottom + kFloatingNavigationBottomGap,
  );
}

double floatingNavigationScrollPadding(BuildContext context) {
  return floatingNavigationBottom(context) + kFloatingNavigationHeight + 24;
}

double pageHorizontalPadding(BuildContext context) {
  return pageHorizontalPaddingForWidth(MediaQuery.sizeOf(context).width);
}

double pageHorizontalPaddingForWidth(double width) {
  if (width < 360) {
    return 18;
  }
  if (width < 390) {
    return 20;
  }
  return 24;
}

double responsiveValue({
  required double width,
  required double compact,
  required double regular,
}) {
  return width < 360 ? compact : regular;
}
