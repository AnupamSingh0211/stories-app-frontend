import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final Color contentColor;
  final Color backgroundColor;
  final Color borderColor;
  final TextStyle? inputTextStyle;

  const CustomSearchBar({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText = 'Search stories, characters, type',
    this.onChanged,
    this.contentColor = Colors.white,
    this.backgroundColor = AppColors.backgroundGlass,
    this.borderColor = const Color(0x8CFFFFFF),
    this.inputTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/icons/new_boopi/State=Default, Icon=Search.svg',
            colorFilter: ColorFilter.mode(contentColor, BlendMode.srcIn),
            width: 24,
            height: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              style:
                  inputTextStyle?.copyWith(color: contentColor) ??
                  AppTypography.bodyMediumBold.copyWith(color: contentColor),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: (inputTextStyle ?? AppTypography.bodyMediumBold)
                    .copyWith(color: contentColor.withValues(alpha: 0.86)),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                filled: false,
                fillColor: Colors.transparent,
                hoverColor: Colors.transparent,
                focusColor: Colors.transparent,
                isDense: true,
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
