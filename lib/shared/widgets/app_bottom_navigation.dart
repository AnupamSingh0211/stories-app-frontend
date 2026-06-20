import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class AppBottomNavigationItem {
  const AppBottomNavigationItem({
    required this.label,
    this.icon,
    this.selectedIcon,
    this.iconAsset,
    this.selectedIconAsset,
  });

  final IconData? icon;
  final IconData? selectedIcon;
  final String? iconAsset;
  final String? selectedIconAsset;
  final String label;
}

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
    super.key,
  }) : assert(items.length >= 2, 'At least two navigation items are required'),
       assert(selectedIndex >= 0, 'Selected index cannot be negative'),
       assert(
         selectedIndex < items.length,
         'Selected index must point to an item',
       );

  final List<AppBottomNavigationItem> items;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  @override
  Widget build(BuildContext context) {
    final itemWidths = items.length == 4
        ? const [69.0, 77.0, 76.0, 74.0]
        : List<double>.filled(items.length, 69);
    final totalItemWidth = itemWidths.fold<double>(
      0,
      (total, width) => total + width,
    );
    final totalGapWidth = 18.9 * (items.length - 1);
    final idealContentWidth = totalItemWidth + totalGapWidth;

    return Container(
      width: double.infinity,
      height: 72,
      color: AppColors.surfaceWhite,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth >= 390 ? 17.47 : 8.0;
          final availableContentWidth =
              constraints.maxWidth - (horizontalPadding * 2);
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 12,
              ),
              child: SizedBox(
                width: availableContentWidth,
                height: 48,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: idealContentWidth,
                    height: 48,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (
                          var index = 0;
                          index < items.length;
                          index += 1
                        ) ...[
                          SizedBox(
                            width: itemWidths[index],
                            height: 48,
                            child: _AppBottomNavigationTile(
                              item: items[index],
                              selected: selectedIndex == index,
                              onTap: () => onItemSelected(index),
                            ),
                          ),
                          if (index < items.length - 1)
                            const SizedBox(width: 18.9),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AppBottomNavigationIconSet {
  const AppBottomNavigationIconSet({
    required this.home,
    required this.stories,
    required this.library,
    required this.profile,
  });

  final AppBottomNavigationItem home;
  final AppBottomNavigationItem stories;
  final AppBottomNavigationItem library;
  final AppBottomNavigationItem profile;

  static const material = AppBottomNavigationIconSet(
    home: AppBottomNavigationItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Home',
    ),
    stories: AppBottomNavigationItem(
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book_rounded,
      label: 'Stories',
    ),
    library: AppBottomNavigationItem(
      icon: Icons.video_library_outlined,
      selectedIcon: Icons.video_library_rounded,
      label: 'Library',
    ),
    profile: AppBottomNavigationItem(
      icon: Icons.account_circle_outlined,
      selectedIcon: Icons.account_circle_rounded,
      label: 'Profile',
    ),
  );

  static const figma = AppBottomNavigationIconSet(
    home: AppBottomNavigationItem(
      iconAsset: 'assets/icons/nav/home_inactive.svg',
      selectedIconAsset: 'assets/icons/nav/home_active.svg',
      label: 'Home',
    ),
    stories: AppBottomNavigationItem(
      iconAsset: 'assets/icons/nav/stories_inactive.svg',
      selectedIconAsset: 'assets/icons/nav/stories_active.svg',
      label: 'Stories',
    ),
    library: AppBottomNavigationItem(
      iconAsset: 'assets/icons/nav/library_inactive.svg',
      selectedIconAsset: 'assets/icons/nav/library_active.svg',
      label: 'Library',
    ),
    profile: AppBottomNavigationItem(
      iconAsset: 'assets/icons/nav/profile_inactive.svg',
      selectedIconAsset: 'assets/icons/nav/profile_active.svg',
      label: 'Profile',
    ),
  );

  List<AppBottomNavigationItem> toList() {
    return [home, stories, library, profile];
  }
}

class AppPrimaryBottomNavigation extends StatelessWidget {
  const AppPrimaryBottomNavigation({
    required this.selectedIndex,
    required this.onItemSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  @override
  Widget build(BuildContext context) {
    return AppBottomNavigation(
      items: AppBottomNavigationIconSet.figma.toList(),
      selectedIndex: selectedIndex,
      onItemSelected: onItemSelected,
    );
  }
}

class AppBottomNavigationIcon extends StatelessWidget {
  const AppBottomNavigationIcon({
    required this.selected,
    super.key,
    this.icon,
    this.selectedIcon,
    this.iconAsset,
    this.selectedIconAsset,
  });

  final IconData? icon;
  final IconData? selectedIcon;
  final String? iconAsset;
  final String? selectedIconAsset;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final asset = selected ? selectedIconAsset ?? iconAsset : iconAsset;
    if (asset != null) {
      return SvgPicture.asset(asset, width: 24, height: 24);
    }

    final effectiveIcon = selected ? selectedIcon ?? icon : icon;
    assert(effectiveIcon != null, 'Icon or icon asset is required');

    return Icon(
      effectiveIcon,
      color: selected ? AppColors.blue600 : AppColors.gray500,
      size: 24,
      applyTextScaling: false,
    );
  }
}

class AppBottomNavigationLink extends StatelessWidget {
  const AppBottomNavigationLink({
    required this.item,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final AppBottomNavigationItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _AppBottomNavigationTile(
      item: item,
      selected: selected,
      onTap: onTap,
    );
  }
}

class _AppBottomNavigationTile extends StatelessWidget {
  const _AppBottomNavigationTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AppBottomNavigationItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.blue600 : AppColors.gray500;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkResponse(
        onTap: onTap,
        containedInkWell: true,
        highlightShape: BoxShape.rectangle,
        splashColor: AppColors.blue100,
        highlightColor: AppColors.blue50,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: const ShapeDecoration(shape: StadiumBorder()),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppBottomNavigationIcon(
                icon: item.icon,
                selectedIcon: item.selectedIcon,
                iconAsset: item.iconAsset,
                selectedIconAsset: item.selectedIconAsset,
                selected: selected,
              ),
              SizedBox(
                width: double.infinity,
                height: 16,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.label,
                    textScaler: TextScaler.noScaling,
                    softWrap: false,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    style: AppTypography.bodySmallBold.copyWith(
                      color: color,
                      height: 16 / 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
