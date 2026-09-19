import 'package:flutter/material.dart';

/// App-wide responsive breakpoint system, based on Material 3's window
/// size classes (https://m3.material.io/foundations/layout/applying-layout/window-size-classes).
/// This is the single source of truth for breakpoints in this app — every
/// screen should read layout decisions from here instead of hardcoding its
/// own width thresholds, so tablet-range widths get consistent treatment
/// everywhere instead of silently falling into whichever binary mobile/desktop
/// split a given page happened to pick.
enum ScreenSize {
  /// Phones in portrait. < 600dp.
  compact,

  /// Tablets in portrait, large/unfolded foldables. 600–839dp.
  medium,

  /// Tablets in landscape, small laptops. 840–1199dp.
  expanded,

  /// Laptops and desktop monitors. 1200–1599dp.
  large,

  /// Large desktop monitors. >= 1600dp.
  extraLarge,
}

class Responsive {
  Responsive._();

  static const double compactMax = 600;
  static const double mediumMax = 840;
  static const double expandedMax = 1200;
  static const double largeMax = 1600;

  static ScreenSize screenSizeOf(BuildContext context) =>
      screenSizeForWidth(MediaQuery.sizeOf(context).width);

  static ScreenSize screenSizeForWidth(double width) {
    if (width < compactMax) return ScreenSize.compact;
    if (width < mediumMax) return ScreenSize.medium;
    if (width < expandedMax) return ScreenSize.expanded;
    if (width < largeMax) return ScreenSize.large;
    return ScreenSize.extraLarge;
  }

  /// Phone-sized viewport. Single-column, stacked layouts.
  static bool isMobile(BuildContext context) =>
      screenSizeOf(context) == ScreenSize.compact;

  /// Tablet-sized viewport (portrait or landscape) or a small laptop window.
  /// This is the range most apps skip — it exists so pages can give tablets
  /// their own layout instead of inheriting whatever mobile or desktop does.
  static bool isTablet(BuildContext context) {
    final s = screenSizeOf(context);
    return s == ScreenSize.medium || s == ScreenSize.expanded;
  }

  /// Laptop/desktop-sized viewport.
  static bool isDesktop(BuildContext context) {
    final s = screenSizeOf(context);
    return s == ScreenSize.large || s == ScreenSize.extraLarge;
  }

  /// True for `medium` and up — i.e. "not a phone". Useful for the common
  /// case of a page that only needs a two-way split (stacked vs. side-by-side)
  /// rather than the full five-tier scale.
  static bool isAtLeastTablet(BuildContext context) => !isMobile(context);

  /// Picks a value based on the current screen size, falling back to the
  /// next-smaller tier's value if a given tier isn't specified — so callers
  /// only need to specify the tiers where the layout actually changes.
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }

  /// A sensible max content width for forms/wizards so lines of text and
  /// form fields don't stretch edge-to-edge on large screens, while still
  /// using the full width available on phones and tablets.
  static double contentMaxWidth(BuildContext context) => value<double>(
        context,
        mobile: double.infinity,
        tablet: 760,
        desktop: 960,
      );

  /// Standard horizontal page padding, growing slightly on larger screens.
  static EdgeInsets pagePadding(BuildContext context) => EdgeInsets.symmetric(
        horizontal: value<double>(context, mobile: 16, tablet: 24, desktop: 32),
        vertical: value<double>(context, mobile: 16, tablet: 20, desktop: 24),
      );

  /// Column count for a responsive grid of cards (dashboards, catalogs).
  static int gridColumns(BuildContext context) => value<int>(
        context,
        mobile: 1,
        tablet: 2,
        desktop: 3,
      );
}

/// Convenience widget for the common "stack on phone, two-column on tablet+"
/// pattern (e.g. a form's field groups, or a detail page's info cards).
/// On phone: children are stacked vertically with [spacing] between them.
/// On tablet/desktop: children are laid out in a row, each wrapped in
/// [Expanded], with [spacing] between them.
class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;

  const ResponsiveRow({
    super.key,
    required this.children,
    this.spacing = 16,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isMobile(context) || children.length < 2) {
      final items = <Widget>[];
      for (var i = 0; i < children.length; i++) {
        if (i > 0) items.add(SizedBox(height: spacing));
        items.add(children[i]);
      }
      return Column(crossAxisAlignment: crossAxisAlignment, children: items);
    }

    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) items.add(SizedBox(width: spacing));
      items.add(Expanded(child: children[i]));
    }
    return Row(crossAxisAlignment: crossAxisAlignment, children: items);
  }
}
