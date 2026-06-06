import 'package:flutter/material.dart';

abstract final class AppBorderRadius {
  static const radiusXs = 8.0;
  static const radiusSm = 12.0;
  static const radiusMd = 16.0;
  static const radiusLg = 20.0;
  static const radiusCard = 22.0;
  static const radiusPanel = 24.0;
  static const radiusButton = 30.0;

  static const card = BorderRadius.all(Radius.circular(radiusCard));
  static const panel = BorderRadius.all(Radius.circular(radiusPanel));
  static const button = BorderRadius.all(Radius.circular(radiusButton));
  static const modal = BorderRadius.all(Radius.circular(radiusPanel));
}
