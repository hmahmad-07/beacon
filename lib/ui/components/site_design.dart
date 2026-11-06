import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../core/extensions/routes.dart';
import '../../core/extensions/sizer.dart';
import '../../core/models/project_model.dart';
import '../../core/resources/app_colors.dart';
import 'site_widgets.dart';

export 'site_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Site design kit
//
// The building blocks of the Home, Site Home and Department screens, shared
// by every module screen so each site looks the same everywhere and uses its
// own colour (Paani blue, Corporate Canteen orange, Al Azeem brown, ...).
//
// A module's first screen wraps itself in [SiteScope]. Every screen opened
// from there with `context.pushSite(...)` keeps the same site colour, and
// Material widgets (buttons, switches, date pickers, loaders, refresh
// spinners) follow it through the scoped theme.
// ─────────────────────────────────────────────────────────────────────────────

/// Lightens (positive [delta]) or darkens (negative) a colour.
Color siteShade(Color color, double delta) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness((hsl.lightness + delta).clamp(0.0, 1.0)).toColor();
}

/// Site colour for a shop ID (POS-0003 → Paani blue). Unknown or empty IDs
/// fall back to the app's navy.
Color siteAccentForShop(String? shopId) {
  final id = (shopId ?? '').trim().toLowerCase();
  if (id.isEmpty) return AppColor.appColor1;
  for (final project in AppProject.all) {
    if (project.id.toLowerCase() == id) return project.accent;
  }
  return AppColor.appColor1;
}

/// Logo asset for a shop ID, when the site is a known project.
String? siteAssetForShop(String? shopId) {
  final id = (shopId ?? '').trim().toLowerCase();
  if (id.isEmpty) return null;
  for (final project in AppProject.all) {
    if (project.id.toLowerCase() == id) return project.asset;
  }
  return null;
}

/// Theme for screens inside one site: the site colour becomes the primary
/// colour, so stock Material widgets pick it up.
ThemeData siteThemeData(ThemeData base, Color accent) {
  final soft = accent.withValues(alpha: 0.14);
  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      primary: accent,
      onPrimary: Colors.white,
      secondary: accent,
      primaryContainer: soft,
      onPrimaryContainer: accent,
      secondaryContainer: soft,
      onSecondaryContainer: accent,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: accent),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: accent,
      selectionColor: accent.withValues(alpha: 0.25),
      selectionHandleColor: accent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accent,
        side: BorderSide(color: accent.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: accent),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accent,
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: accent, width: 1.5),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? accent : AppColor.grey,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? accent.withValues(alpha: 0.35)
            : AppColor.appLightColor,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? accent : null,
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? accent : AppColor.grey,
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      selectedColor: accent,
      checkmarkColor: Colors.white,
    ),
    tabBarTheme: base.tabBarTheme.copyWith(
      labelColor: accent,
      indicatorColor: accent,
    ),
    datePickerTheme: base.datePickerTheme.copyWith(
      headerBackgroundColor: accent,
      headerForegroundColor: Colors.white,
      todayBorder: BorderSide(color: accent),
    ),
  );
}

/// Carries the current site colour down a screen's widget tree.
class SiteScope extends InheritedWidget {
  const SiteScope({super.key, required this.accent, required super.child});

  final Color accent;

  /// The site colour, or the app navy outside a site.
  static Color of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SiteScope>()?.accent ??
      AppColor.appColor1;

  static Color? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SiteScope>()?.accent;

  /// Puts [child] inside the site's colour and theme.
  static Widget wrap({required Color accent, required Widget child}) {
    return SiteScope(
      accent: accent,
      child: Builder(
        builder: (context) =>
            Theme(data: siteThemeData(Theme.of(context), accent), child: child),
      ),
    );
  }

  @override
  bool updateShouldNotify(SiteScope oldWidget) => oldWidget.accent != accent;
}

extension SiteContext on BuildContext {
  /// The colour of the site this screen belongs to.
  Color get siteAccent => SiteScope.of(this);

  /// Opens [page] in the same site colour as this screen.
  Future<dynamic>? pushSite(Widget page) {
    final accent = SiteScope.maybeOf(this);
    if (accent == null) return AppRoutes.push(page);
    return AppRoutes.push(SiteScope.wrap(accent: accent, child: page));
  }
}

// ───────────────────────────── Surfaces ─────────────────────────────

/// Shadow used by every white card.
List<BoxShadow> get siteCardShadow => [
  BoxShadow(
    color: Colors.black.withValues(alpha: 0.05),
    blurRadius: 16,
    offset: const Offset(0, 6),
  ),
];

/// Press-to-shrink tap wrapper.
class SitePressable extends StatefulWidget {
  const SitePressable({
    super.key,
    required this.onTap,
    required this.child,
    this.scale = 0.97,
  });

  final VoidCallback? onTap;
  final Widget child;
  final double scale;

  @override
  State<SitePressable> createState() => _SitePressableState();
}

class _SitePressableState extends State<SitePressable> {
  bool _down = false;

  void _set(bool value) {
    if (_down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapCancel: () => _set(false),
      onTapUp: (_) => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// White rounded card with the soft shadow.
class SiteCard extends StatelessWidget {
  const SiteCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.radius = 22,
    this.color,
    this.border,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double radius;
  final Color? color;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      padding: padding ?? EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: color ?? AppColor.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: siteCardShadow,
        border: border,
      ),
      child: child,
    );
    return onTap == null ? card : SitePressable(onTap: onTap, child: card);
  }
}

/// Small rounded label (counts, statuses, chips).
class SitePill extends StatelessWidget {
  const SitePill(
    this.text, {
    super.key,
    required this.bg,
    required this.fg,
    this.icon,
    this.fontSize,
  });

  /// Tinted pill in [color].
  factory SitePill.tint(String text, Color color, {IconData? icon}) =>
      SitePill(text, bg: color.withValues(alpha: 0.12), fg: color, icon: icon);

  /// Solid pill in [color] with white text.
  factory SitePill.solid(String text, Color color, {IconData? icon}) =>
      SitePill(text, bg: color, fg: Colors.white, icon: icon);

  final String text;
  final Color bg, fg;
  final IconData? icon;
  final double? fontSize;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.6.h),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 3.6.w, color: fg),
          SizedBox(width: 1.4.w),
        ],
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: fontSize ?? 3.sp,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Section heading: accent bar, bold title, optional count pill or trailing.
class SiteSectionTitle extends StatelessWidget {
  const SiteSectionTitle(
    this.title, {
    super.key,
    this.count,
    this.trailing,
    this.padding,
  });

  final String title;
  final int? count;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final accent = context.siteAccent;
    return Padding(
      padding: padding ?? EdgeInsets.only(top: 1.h, bottom: 1.6.h),
      child: Row(
        children: [
          Container(
            width: 1.2.w,
            height: 3.h,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          SizedBox(width: 2.5.w),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 4.3.sp,
                fontWeight: FontWeight.w800,
                color: AppColor.appDarkColor,
              ),
            ),
          ),
          if (trailing != null)
            trailing!
          else if (count != null)
            SitePill.tint("$count", accent),
        ],
      ),
    );
  }
}

/// Square icon tile with the site gradient and glow.
class SiteIconBadge extends StatelessWidget {
  const SiteIconBadge(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.radius = 16,
  });

  final IconData icon;
  final double? size;
  final Color? color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final base = color ?? context.siteAccent;
    final box = size ?? 12.w;
    return Container(
      height: box,
      width: box,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          colors: [siteShade(base, 0.14), base],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: base.withValues(alpha: 0.32),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: box * 0.5),
    );
  }
}

/// Small round tinted icon (used inside rows and stat cards).
class SiteIconDot extends StatelessWidget {
  const SiteIconDot(this.icon, {super.key, this.color, this.size});

  final IconData icon;
  final Color? color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.siteAccent;
    final s = size ?? 4.6.w;
    return Container(
      padding: EdgeInsets.all(s * 0.45),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: s, color: c),
    );
  }
}

/// Round arrow used at the end of tappable rows.
class SiteArrow extends StatelessWidget {
  const SiteArrow({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.siteAccent;
    return Container(
      padding: EdgeInsets.all(1.8.w),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.arrow_forward_ios_rounded, size: 3.4.w, color: c),
    );
  }
}

// ───────────────────────────── Headers ─────────────────────────────

/// Tinted header card (as on the department screen): logo or icon, title,
/// site line in the site colour, optional description and a solid badge.
class SiteHeaderCard extends StatelessWidget {
  const SiteHeaderCard({
    super.key,
    required this.title,
    this.subtitle,
    this.description,
    this.logoAsset,
    this.icon,
    this.badge,
    this.trailing,
    this.margin,
    this.heroTag,
  });

  final String title;
  final String? subtitle;
  final String? description;
  final String? logoAsset;
  final IconData? icon;
  final String? badge;
  final Widget? trailing;
  final EdgeInsetsGeometry? margin;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final accent = context.siteAccent;

    Widget? lead;
    if (logoAsset != null) {
      lead = SiteLogo(asset: logoAsset, accent: accent, size: 15.w);
      if (heroTag != null) lead = Hero(tag: heroTag!, child: lead);
    } else if (icon != null) {
      lead = SiteIconBadge(icon!, size: 13.w);
    }

    return Container(
      padding: EdgeInsets.all(3.5.w),
      margin: margin ?? EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 0.5.h),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(5.r),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          if (lead != null) ...[lead, SizedBox(width: 3.5.w)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 4.6.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF14151C),
                    height: 1.15,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  SizedBox(height: 0.3.h),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 3.3.sp,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                ],
                if (description != null && description!.isNotEmpty) ...[
                  SizedBox(height: 0.3.h),
                  Text(
                    description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 3.sp,
                      color: AppColor.grey,
                      height: 1.25,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: 2.w),
            trailing!,
          ] else if (badge != null) ...[
            SizedBox(width: 2.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge!,
                style: TextStyle(
                  fontSize: 3.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Gradient banner in the site colour (as on the site screen). Use it for a
/// screen's headline: an eyebrow line, a big title, optional pills and any
/// extra content (figures, chips) under it.
class SiteBanner extends StatelessWidget {
  const SiteBanner({
    super.key,
    this.eyebrow,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.pills = const [],
    this.child,
    this.onTap,
    this.titleSize,
  });

  final String? eyebrow;
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final List<Widget> pills;
  final Widget? child;
  final VoidCallback? onTap;
  final double? titleSize;

  Widget _bubble(
    double size,
    double alpha, {
    double? right,
    double? top,
    double? bottom,
  }) => Positioned(
    right: right,
    top: top,
    bottom: bottom,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final accent = context.siteAccent;

    final banner = Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [accent, siteShade(accent, -0.12)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.32),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          _bubble(32.w, 0.10, right: -8.w, top: -8.w),
          _bubble(22.w, 0.08, right: 14.w, bottom: -12.w),
          Padding(
            padding: EdgeInsets.all(5.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (leading != null) ...[leading!, SizedBox(width: 4.w)],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (eyebrow != null) ...[
                            Text(
                              eyebrow!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 3.sp,
                                color: Colors.white.withValues(alpha: 0.82),
                              ),
                            ),
                            0.3.height,
                          ],
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: titleSize ?? 5.2.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.15,
                            ),
                          ),
                          if (subtitle != null) ...[
                            0.4.height,
                            Text(
                              subtitle!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 3.1.sp,
                                color: Colors.white.withValues(alpha: 0.88),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (trailing != null) ...[SizedBox(width: 2.w), trailing!],
                  ],
                ),
                if (pills.isNotEmpty) ...[
                  1.4.height,
                  Wrap(spacing: 2.w, runSpacing: 1.h, children: pills),
                ],
                if (child != null) ...[1.8.height, child!],
              ],
            ),
          ),
        ],
      ),
    );

    return onTap == null ? banner : SitePressable(onTap: onTap, child: banner);
  }
}

/// White pill for use on a [SiteBanner].
class SiteBannerPill extends StatelessWidget {
  const SiteBannerPill(this.text, {super.key, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => SitePill(
    text,
    bg: Colors.white.withValues(alpha: 0.2),
    fg: Colors.white,
    icon: icon,
  );
}

/// A figure on a [SiteBanner]: small label over a big white value.
class SiteBannerStat extends StatelessWidget {
  const SiteBannerStat({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 2.5.sp,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.78),
        ),
      ),
      0.4.height,
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          value,
          maxLines: 1,
          style: TextStyle(
            fontSize: 5.4.sp,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    ],
  );
}

// ───────────────────────────── Content ─────────────────────────────

/// Figure card: tinted icon, big value and a label.
class SiteStatTile extends StatelessWidget {
  const SiteStatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.caption,
    this.onTap,
    this.dense = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final String? caption;
  final VoidCallback? onTap;

  /// Smaller version for three tiles in a row.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.siteAccent;
    return SiteCard(
      onTap: onTap,
      radius: dense ? 18 : 22,
      padding: dense
          ? EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.6.h)
          : EdgeInsets.all(3.6.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SiteIconDot(icon, color: c, size: dense ? 3.8.w : 4.4.w),
          (dense ? 1.1 : 1.4).height,
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: dense ? 4.4.sp : 5.4.sp,
                fontWeight: FontWeight.w800,
                color: AppColor.appDarkColor,
              ),
            ),
          ),
          0.3.height,
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: dense ? 2.7.sp : 3.sp,
              color: AppColor.grey,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          if (caption != null) ...[
            0.3.height,
            Text(
              caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 2.7.sp, color: c),
            ),
          ],
        ],
      ),
    );
  }
}

/// Grid of [SiteStatTile]s (two per row).
class SiteStatGrid extends StatelessWidget {
  const SiteStatGrid({super.key, required this.children, this.columns = 2});

  final List<Widget> children;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final slice = children.sublist(
        i,
        (i + columns).clamp(0, children.length),
      );
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = 0; j < columns; j++) ...[
                if (j > 0) SizedBox(width: 3.w),
                Expanded(child: j < slice.length ? slice[j] : const SizedBox()),
              ],
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) SizedBox(height: 3.w),
          rows[i],
        ],
      ],
    );
  }
}

/// Full-width tappable row in the module-card style: gradient icon, title,
/// subtitle and the round arrow.
class SiteActionTile extends StatelessWidget {
  const SiteActionTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.color,
    this.margin,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? color;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.siteAccent;
    return Padding(
      padding: margin ?? EdgeInsets.only(bottom: 1.6.h),
      child: SiteCard(
        onTap: onTap,
        padding: EdgeInsets.all(3.6.w),
        child: Row(
          children: [
            SiteIconBadge(icon, size: 12.w, color: c),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 4.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColor.appDarkColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 0.4.h),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 3.1.sp,
                        color: AppColor.grey,
                        height: 1.25,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 2.w),
            trailing ??
                (onTap == null ? const SizedBox() : SiteArrow(color: c)),
          ],
        ),
      ),
    );
  }
}

/// Selectable chip in the site colour (filters, tabs, day pickers).
class SiteChoiceChip extends StatelessWidget {
  const SiteChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final accent = context.siteAccent;
    return SitePressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 3.6.w, vertical: 1.h),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [siteShade(accent, 0.08), accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : AppColor.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: selected ? accent : AppColor.appLightColor),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 3.8.w,
                color: selected ? Colors.white : AppColor.grey,
              ),
              SizedBox(width: 1.5.w),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 3.2.sp,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColor.appDarkColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Label–value row with a small tinted icon.
class SiteInfoRow extends StatelessWidget {
  const SiteInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.8.h),
      child: Row(
        children: [
          SiteIconDot(icon, color: color, size: 3.8.w),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 3.3.sp, color: AppColor.grey),
            ),
          ),
          SizedBox(width: 2.w),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                value,
                textAlign: TextAlign.end,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 3.4.sp,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? AppColor.appDarkColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Round avatar with a site-coloured ring; shows initials when there is no
/// photo.
class SiteAvatar extends StatelessWidget {
  const SiteAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size,
    this.color,
  });

  final String name;
  final String? imageUrl;
  final double? size;
  final Color? color;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
    if (parts.isEmpty) return '?';
    final list = parts.toList();
    final first = list.first[0];
    final last = list.length > 1 ? list.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.siteAccent;
    final s = size ?? 12.w;
    final fallback = Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [siteShade(c, 0.12), c],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Text(
        _initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: s * 0.34,
        ),
      ),
    );
    final url = imageUrl?.trim() ?? '';
    return Container(
      width: s,
      height: s,
      padding: EdgeInsets.all(s * 0.05),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: c.withValues(alpha: 0.35), width: 1.5),
      ),
      child: ClipOval(
        child: url.isEmpty
            ? fallback
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, _) => fallback,
                errorWidget: (_, _, _) => fallback,
              ),
      ),
    );
  }
}

/// Empty or error state in the site style, with an optional retry.
class SiteEmptyState extends StatelessWidget {
  const SiteEmptyState({
    super.key,
    required this.message,
    this.title,
    this.icon = Icons.inbox_rounded,
    this.onRetry,
  });

  final String message;
  final String? title;
  final IconData icon;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final accent = context.siteAccent;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(5.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.08),
              ),
              child: Icon(
                icon,
                size: 11.w,
                color: accent.withValues(alpha: 0.7),
              ),
            ),
            2.height,
            if (title != null) ...[
              Text(
                title!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 4.2.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColor.appDarkColor,
                ),
              ),
              0.8.height,
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 3.4.sp,
                color: AppColor.grey,
                height: 1.35,
              ),
            ),
            if (onRetry != null) ...[
              2.height,
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text("Try again"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Loader in the site colour.
class SiteLoading extends StatelessWidget {
  const SiteLoading({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) =>
      AppLoadingView(label: label, color: context.siteAccent);
}

/// Small spinner in the site colour (inline use).
class SiteSpinner extends StatelessWidget {
  const SiteSpinner({super.key, this.radius = 10});

  final double radius;

  @override
  Widget build(BuildContext context) =>
      CupertinoActivityIndicator(radius: radius, color: context.siteAccent);
}

// ───────────────────────────── Motion ─────────────────────────────

/// Staggered slide-and-fade used by every list (wrap the list in
/// `AnimationLimiter`).
Widget siteStagger(int index, Widget child) =>
    AnimationConfiguration.staggeredList(
      position: index,
      duration: const Duration(milliseconds: 420),
      child: SlideAnimation(
        verticalOffset: 28,
        child: FadeInAnimation(child: child),
      ),
    );

/// Staggered scale-in used by grids.
Widget siteStaggerGrid(int index, int columns, Widget child) =>
    AnimationConfiguration.staggeredGrid(
      position: index,
      columnCount: columns,
      duration: const Duration(milliseconds: 400),
      child: ScaleAnimation(scale: 0.92, child: FadeInAnimation(child: child)),
    );

/// Opens [page] in [accent]'s site colour (for code that has the colour but
/// not a context inside the site).
Future<dynamic>? pushInSite(Color accent, Widget page) =>
    AppRoutes.push(SiteScope.wrap(accent: accent, child: page));

/// Horizontal day picker in the site colour (white bar under the app bar).
class SiteDateStrip extends StatelessWidget {
  const SiteDateStrip({
    super.key,
    required this.dates,
    required this.selected,
    required this.onSelected,
  });

  final List<DateTime> dates;
  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static const _days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  @override
  Widget build(BuildContext context) {
    final accent = context.siteAccent;
    return Container(
      height: 12.5.h,
      padding: EdgeInsets.symmetric(vertical: 1.6.h),
      decoration: BoxDecoration(
        color: AppColor.white,
        border: Border(bottom: BorderSide(color: AppColor.appLightColor)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 5.w),
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = _sameDay(date, selected);
          return SitePressable(
            onTap: () => onSelected(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 13.w,
              margin: EdgeInsets.only(right: 2.6.w),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [siteShade(accent, 0.10), accent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : AppColor.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? accent
                      : AppColor.appLightColor.withValues(alpha: 0.9),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _days[date.weekday - 1],
                    style: TextStyle(
                      fontSize: 2.2.sp,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.85)
                          : AppColor.grey,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  0.5.height,
                  Text(
                    date.day.toString().padLeft(2, '0'),
                    style: TextStyle(
                      fontSize: 4.4.sp,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : AppColor.appDarkColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Report screen header: the site banner with the site logo, the department
/// and a period row with a "Change" button.
class SiteReportHeader extends StatelessWidget {
  const SiteReportHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.logoAsset,
    this.icon = Icons.insights_rounded,
    required this.periodLabel,
    this.onChangePeriod,
    this.pills = const [],
    this.margin,
    this.eyebrow,
    this.leading,
  });

  /// Replaces the logo (for example an employee avatar).
  final Widget? leading;
  final String title;
  final String? subtitle;
  final String? logoAsset;
  final IconData icon;
  final String periodLabel;
  final VoidCallback? onChangePeriod;
  final List<Widget> pills;
  final EdgeInsetsGeometry? margin;
  final String? eyebrow;

  @override
  Widget build(BuildContext context) {
    final accent = context.siteAccent;
    final logo = logoAsset != null && logoAsset!.isNotEmpty
        ? Container(
            padding: EdgeInsets.all(1.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SiteLogo(asset: logoAsset, accent: accent, size: 13.w),
          )
        : Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 7.w),
          );

    return Padding(
      padding: margin ?? EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 1.5.h),
      child: SiteBanner(
        leading: leading ?? logo,
        eyebrow: eyebrow,
        title: title,
        subtitle: subtitle,
        titleSize: 4.8.sp,
        pills: pills,
        child: SitePressable(
          onTap: onChangePeriod,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 3.5.w, vertical: 1.1.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.white,
                  size: 4.6.w,
                ),
                2.5.width,
                Expanded(
                  child: Text(
                    periodLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 3.4.sp,
                    ),
                  ),
                ),
                if (onChangePeriod != null)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Change",
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w800,
                        fontSize: 2.8.sp,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Two-option (or more) segmented switch in the site colour.
class SiteSegmented extends StatelessWidget {
  const SiteSegmented({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.icons,
  });

  final List<String> labels;
  final List<IconData>? icons;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final accent = context.siteAccent;
    return Container(
      padding: EdgeInsets.all(1.w),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: siteCardShadow,
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(vertical: 1.1.h),
                  decoration: BoxDecoration(
                    gradient: i == selected
                        ? LinearGradient(
                            colors: [siteShade(accent, 0.08), accent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icons != null && i < icons!.length) ...[
                        Icon(
                          icons![i],
                          size: 4.w,
                          color: i == selected ? Colors.white : AppColor.grey,
                        ),
                        1.5.width,
                      ],
                      Flexible(
                        child: Text(
                          labels[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 3.1.sp,
                            fontWeight: FontWeight.w700,
                            color: i == selected
                                ? Colors.white
                                : AppColor.darkGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
