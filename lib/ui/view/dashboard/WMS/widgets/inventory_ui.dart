import 'dart:math' as math;

import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/ui/components/site_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Inventory design kit
//
// Inventory shows the stores of every site, so it has a colour of its own
// (royal blue) instead of a site colour. The pieces here sit on top of the site
// design kit, so inventory screens look like the rest of the app.
// ─────────────────────────────────────────────────────────────────────────────

/// Inventory colours.
abstract final class InventoryPalette {
  /// Main inventory colour (same value as [AppColor.inventory]).
  static const accent = Color(0xFF164FA3);

  /// Darker end of the hero gradient, also used for headings on light
  /// panels.
  static const deep = Color(0xFF0E3470);

  /// Lighter start of the hero gradient.
  static const light = Color(0xFF1F68D6);

  /// Very light wash for selected rows and panels.
  static const wash = Color(0xFFEDF3FC);

  /// Chart series: stock received and stock issued.
  static const received = accent;
  static const issued = Color(0xFFEB6834);

  /// Stock in, stock out and warnings (always shown with a sign or icon).
  static Color get stockIn => AppColor.green;
  static Color get stockOut => AppColor.red;
  static const warning = Color(0xFFC77700);

  /// Category colours in a fixed order, checked for colour-blind separation
  /// between neighbours. More categories fold into "Other".
  static const categories = [
    Color(0xFF164FA3),
    Color(0xFF1BAF7A),
    Color(0xFFEB6834),
    Color(0xFF6250D6),
    Color(0xFFEDA100),
  ];

  /// Colour of the "Other" group.
  static const other = Color(0xFF8B93A3);

  /// Chart grid and baseline.
  static const grid = Color(0xFFE7ECF4);
}

// ───────────────────────────── Motion ─────────────────────────────

/// Hero tag of the overview card shared by the inventory home and the
/// dashboard.
const kInventoryHeroTag = 'inventory-hero';

/// Slides in from the right with a fade, one after another by [index].
/// The list must sit inside an `AnimationLimiter`; content plays once, when
/// it first appears after loading.
Widget invEnter(int index, Widget child) =>
    AnimationConfiguration.staggeredList(
      position: index,
      duration: const Duration(milliseconds: 560),
      delay: const Duration(milliseconds: 70),
      child: SlideAnimation(
        horizontalOffset: 34.w,
        curve: Curves.easeOutCubic,
        child: FadeInAnimation(curve: Curves.easeOut, child: child),
      ),
    );

/// Hero transition for small pieces (icons, avatars). The flying copy is
/// scaled to fit, and keeps its text styles while in the air.
Widget invHero(Object tag, Widget child) => Hero(
  tag: tag,
  flightShuttleBuilder: (context, animation, direction, from, to) {
    final target = (to.widget as Hero).child;
    return Material(
      type: MaterialType.transparency,
      child: FittedBox(child: target),
    );
  },
  child: Material(type: MaterialType.transparency, child: child),
);

/// Full-screen loading state: the screen's icon (the Hero target when the
/// screen is opened from a tile), an optional title, and the app's loader.
/// Scrollable, so pull-to-refresh keeps working while it shows.
class InventoryLoadingView extends StatelessWidget {
  const InventoryLoadingView({
    super.key,
    required this.label,
    this.icon,
    this.leading,
    this.heroTag,
    this.title,
  });

  final String label;
  final IconData? icon;
  final Widget? leading;
  final Object? heroTag;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final accent = context.siteAccent;
    Widget? top =
        leading ??
        (icon == null
            ? null
            : SiteIconBadge(icon!, size: 17.w, radius: 22, color: accent));
    if (top != null && heroTag != null) top = invHero(heroTag!, top);

    return LayoutBuilder(
      builder: (context, box) => ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: [
          SizedBox(
            height: box.maxHeight.isFinite ? box.maxHeight * 0.92 : 70.h,
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (top != null) ...[top, 2.2.height],
                    if (title != null)
                      Text(
                        title!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 4.2.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColor.appDarkColor,
                        ),
                      ),
                    AppLoadingView(color: accent, label: label),
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

// ───────────────────────────── Numbers ─────────────────────────────

final _whole = NumberFormat('#,##0', 'en_US');
final _decimal = NumberFormat('#,##0.##', 'en_US');

/// 12,400 or 12,400.5
String invQty(num? value) => _decimal.format(value ?? 0);

/// 12,400 (rounded)
String invWhole(num? value) => _whole.format(value ?? 0);

/// 4.8M, 12.4K or 950
String invCompact(num? value) {
  final v = (value ?? 0).toDouble();
  final abs = v.abs();
  String trim(double x) {
    final s = x.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  if (abs >= 1e9) return '${trim(v / 1e9)}B';
  if (abs >= 1e6) return '${trim(v / 1e6)}M';
  if (abs >= 1e3) return '${trim(v / 1e3)}K';
  return _whole.format(v);
}

/// A round axis step (1, 2, 2.5 or 5 × a power of ten) giving about
/// [ticks] gridlines up to [max].
double invNiceStep(double max, {int ticks = 4}) {
  if (max <= 0) return 1;
  final raw = max / ticks;
  final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
  final norm = raw / mag;
  final step = norm <= 1
      ? 1.0
      : norm <= 2
      ? 2.0
      : norm <= 2.5
      ? 2.5
      : norm <= 5
      ? 5.0
      : 10.0;
  return step * mag;
}

/// Share of [part] in [total] as "38%", with finer steps for small shares.
String invPercent(num part, num total) {
  if (total <= 0) return "0%";
  final pct = part / total * 100;
  if (pct <= 0) return "0%";
  if (pct < 0.1) return "<0.1%";
  if (pct < 10) return "${pct.toStringAsFixed(1)}%";
  return "${pct.round()}%";
}

/// Two-letter initials for a name ("Paani 500ml Bottle" → "PB").
String invInitials(String name) {
  final words = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty && RegExp(r'[A-Za-z]').hasMatch(w[0]))
      .toList();
  if (words.isEmpty) return name.trim().isEmpty ? "?" : name.trim()[0];
  if (words.length == 1) return words.first[0].toUpperCase();
  return (words.first[0] + words.last[0]).toUpperCase();
}

// ───────────────────────────── Hero ─────────────────────────────

/// Gradient header card in the inventory colours.
class InventoryHero extends StatelessWidget {
  const InventoryHero({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.icon,
    this.trailing,
    this.pills = const [],
    this.child,
    this.onTap,
    this.titleSize,
    this.leading,
    this.heroTag,
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final IconData? icon;

  /// Shown in place of the icon box (for example an item's avatar).
  final Widget? leading;

  /// When set, the card flies between screens that use the same tag.
  final Object? heroTag;
  final Widget? trailing;
  final List<Widget> pills;
  final Widget? child;
  final VoidCallback? onTap;
  final double? titleSize;

  @override
  Widget build(BuildContext context) {
    final hero = Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [
            InventoryPalette.light,
            InventoryPalette.accent,
            InventoryPalette.deep,
          ],
          stops: [0, 0.45, 1],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: InventoryPalette.accent.withValues(alpha: 0.34),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Soft rings and a glow give the card depth without noise.
          Positioned(right: -14.w, top: -16.w, child: _ring(44.w, 0.12)),
          Positioned(right: 6.w, top: 4.w, child: _ring(16.w, 0.10)),
          Positioned(
            left: -20.w,
            bottom: -26.w,
            child: Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF8FE3FF).withValues(alpha: 0.22),
                    const Color(0xFF8FE3FF).withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(5.w, 2.4.h, 5.w, 2.4.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (leading != null) ...[
                      leading!,
                      3.5.width,
                    ] else if (icon != null) ...[
                      Container(
                        padding: EdgeInsets.all(2.8.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Icon(icon, color: Colors.white, size: 6.2.w),
                      ),
                      3.5.width,
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (eyebrow != null) ...[
                            Text(
                              eyebrow!.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 2.6.sp,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.78),
                              ),
                            ),
                            0.4.height,
                          ],
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: titleSize ?? 5.4.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.12,
                            ),
                          ),
                          if (subtitle != null) ...[
                            0.5.height,
                            Text(
                              subtitle!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 3.1.sp,
                                height: 1.3,
                                color: Colors.white.withValues(alpha: 0.86),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (trailing != null) ...[2.width, trailing!],
                  ],
                ),
                if (pills.isNotEmpty) ...[
                  1.6.height,
                  Wrap(spacing: 2.w, runSpacing: 1.h, children: pills),
                ],
                if (child != null) ...[2.height, child!],
              ],
            ),
          ),
        ],
      ),
    );
    final card = onTap == null
        ? hero
        : SitePressable(onTap: onTap, child: hero);
    if (heroTag == null) return card;
    return Hero(
      tag: heroTag!,
      // The card's shape morphs between screens; its content appears once
      // it lands, so nothing is squeezed mid-flight.
      flightShuttleBuilder: (context, animation, direction, from, to) =>
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
                colors: [
                  InventoryPalette.light,
                  InventoryPalette.accent,
                  InventoryPalette.deep,
                ],
                stops: [0, 0.45, 1],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
      child: Material(type: MaterialType.transparency, child: card),
    );
  }

  Widget _ring(double size, double alpha) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: Colors.white.withValues(alpha: alpha),
        width: size * 0.12,
      ),
    ),
  );
}

/// A row of figures inside an [InventoryHero], split by thin lines.
class InventoryHeroStats extends StatelessWidget {
  const InventoryHeroStats({super.key, required this.stats});

  /// (label, value)
  final List<(String, String)> stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.5.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (final (i, s) in stats.indexed) ...[
              if (i > 0)
                Container(
                  width: 1,
                  margin: EdgeInsets.symmetric(horizontal: 3.w),
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 2.6.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                    0.4.height,
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        s.$2,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 4.4.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// White call-to-action pill on an [InventoryHero].
class InventoryHeroButton extends StatelessWidget {
  const InventoryHeroButton({
    super.key,
    required this.label,
    this.icon = Icons.arrow_forward_rounded,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SitePressable(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.6.w, vertical: 0.9.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 3.sp,
                fontWeight: FontWeight.w800,
                color: InventoryPalette.deep,
              ),
            ),
            1.5.width,
            Icon(icon, size: 3.8.w, color: InventoryPalette.deep),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────── Panels ─────────────────────────────

/// White card with a header (icon, title, subtitle, action) and content.
class InventoryPanel extends StatelessWidget {
  const InventoryPanel({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
    this.trailing,
    this.margin,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final accent = context.siteAccent;
    return SiteCard(
      margin: margin ?? EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 4.6.w, color: accent),
                ),
                3.width,
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 4.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColor.appDarkColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      0.2.height,
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 2.9.sp,
                          color: AppColor.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[2.width, trailing!],
            ],
          ),
          1.8.height,
          child,
        ],
      ),
    );
  }
}

/// "View all →" link in the inventory colour.
class InventoryLink extends StatelessWidget {
  const InventoryLink({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.siteAccent;
    return SitePressable(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.7.h),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 2.9.sp,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
            1.width,
            Icon(Icons.arrow_forward_rounded, size: 3.6.w, color: accent),
          ],
        ),
      ),
    );
  }
}

/// Coloured dot with a label (chart legends).
class InventoryLegendDot extends StatelessWidget {
  const InventoryLegendDot({
    super.key,
    required this.color,
    required this.label,
    this.square = false,
  });

  final Color color;
  final String label;
  final bool square;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 2.6.w,
          height: 2.6.w,
          decoration: BoxDecoration(
            color: color,
            shape: square ? BoxShape.rectangle : BoxShape.circle,
            borderRadius: square ? BorderRadius.circular(3) : null,
          ),
        ),
        1.5.width,
        Text(
          label,
          style: TextStyle(
            fontSize: 2.9.sp,
            fontWeight: FontWeight.w600,
            color: AppColor.darkGrey,
          ),
        ),
      ],
    );
  }
}

/// Thin rounded bar that grows in to [value] (0–1).
class InventoryMeter extends StatelessWidget {
  const InventoryMeter({
    super.key,
    required this.value,
    required this.color,
    this.height,
    this.track,
  });

  final double value;
  final Color color;
  final double? height;
  final Color? track;

  @override
  Widget build(BuildContext context) {
    final h = height ?? 0.9.h;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Container(
        height: h,
        decoration: BoxDecoration(
          color: track ?? InventoryPalette.grid,
          borderRadius: BorderRadius.circular(h),
        ),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: v,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(h),
            ),
          ),
        ),
      ),
    );
  }
}

/// Two-part bar: received (left) and issued (right) of a total.
class InventorySplitBar extends StatelessWidget {
  const InventorySplitBar({
    super.key,
    required this.first,
    required this.second,
    required this.firstColor,
    required this.secondColor,
    this.height,
  });

  final num first;
  final num second;
  final Color firstColor;
  final Color secondColor;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final h = height ?? 0.9.h;
    final a = first.abs().toDouble();
    final b = second.abs().toDouble();
    final total = a + b;
    if (total <= 0) {
      return InventoryMeter(value: 0, color: firstColor, height: h);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(h),
      child: SizedBox(
        height: h,
        child: Row(
          children: [
            if (a > 0)
              Expanded(
                flex: (a / total * 1000).round().clamp(1, 1000),
                child: ColoredBox(color: firstColor),
              ),
            if (a > 0 && b > 0) const SizedBox(width: 2),
            if (b > 0)
              Expanded(
                flex: (b / total * 1000).round().clamp(1, 1000),
                child: ColoredBox(color: secondColor),
              ),
          ],
        ),
      ),
    );
  }
}

/// Rounded square with a name's initials.
class InventoryAvatar extends StatelessWidget {
  const InventoryAvatar({
    super.key,
    required this.name,
    this.color,
    this.size,
    this.icon,
  });

  final String name;
  final Color? color;
  final double? size;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.siteAccent;
    final s = size ?? 11.w;
    return Container(
      width: s,
      height: s,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(s * 0.32),
      ),
      child: icon != null
          ? Icon(icon, size: s * 0.48, color: c)
          : Text(
              invInitials(name),
              style: TextStyle(
                fontSize: s * 0.34,
                fontWeight: FontWeight.w800,
                color: c,
              ),
            ),
    );
  }
}

/// Small grey tag (class, unit, code).
class InventoryTag extends StatelessWidget {
  const InventoryTag(this.text, {super.key, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
      decoration: BoxDecoration(
        color: AppColor.scaffold,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColor.appLightColor.withValues(alpha: 0.8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 3.w, color: AppColor.grey),
            1.width,
          ],
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 2.6.sp,
              fontWeight: FontWeight.w600,
              color: AppColor.darkGrey,
            ),
          ),
        ],
      ),
    );
  }
}

/// Label above a bold value, used inside cards.
class InventoryFigure extends StatelessWidget {
  const InventoryFigure({
    super.key,
    required this.label,
    required this.value,
    this.color,
    this.icon,
    this.iconColor,
    this.alignEnd = false,
    this.size,
  });

  final String label;
  final String value;
  final Color? color;
  final IconData? icon;
  final Color? iconColor;
  final bool alignEnd;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 3.2.w, color: iconColor ?? AppColor.grey),
              0.8.width,
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 2.6.sp,
                fontWeight: FontWeight.w600,
                color: AppColor.grey,
              ),
            ),
          ],
        ),
        0.3.height,
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: TextStyle(
              fontSize: size ?? 3.5.sp,
              fontWeight: FontWeight.w800,
              color: color ?? AppColor.appDarkColor,
            ),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────────── Lists ─────────────────────────────

/// One-row quick filter: tap a chip to switch.
class InventoryQuickFilter<T> extends StatelessWidget {
  const InventoryQuickFilter({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  /// value → (label, icon)
  final Map<T, (String, IconData)> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final e in options.entries) ...[
            SiteChoiceChip(
              label: e.value.$1,
              icon: e.value.$2,
              selected: e.key == selected,
              onTap: () {
                if (e.key != selected) onChanged(e.key);
              },
            ),
            2.width,
          ],
        ],
      ),
    );
  }
}

/// "6 items" line with an optional note on the right.
class InventoryResultLine extends StatelessWidget {
  const InventoryResultLine({super.key, required this.text, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 1.6.h, bottom: 0.4.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 3.1.sp,
                fontWeight: FontWeight.w700,
                color: AppColor.darkGrey,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Previous / next page control. Hidden when everything fits one page.
class InventoryPager extends StatelessWidget {
  const InventoryPager({
    super.key,
    required this.current,
    required this.last,
    required this.loading,
    required this.onPage,
    this.total,
  });

  final int current;
  final int last;
  final bool loading;
  final ValueChanged<int> onPage;
  final int? total;

  @override
  Widget build(BuildContext context) {
    if (last <= 1) {
      if (total == null || total == 0) return const SizedBox.shrink();
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        child: Center(
          child: Text(
            "All $total shown",
            style: TextStyle(fontSize: 2.9.sp, color: AppColor.grey),
          ),
        ),
      );
    }
    final accent = context.siteAccent;
    Widget button(
      String label,
      IconData icon,
      bool enabled,
      int page, {
      bool trailingIcon = false,
    }) {
      final fg = enabled ? accent : AppColor.grey.withValues(alpha: 0.5);
      return Opacity(
        opacity: enabled ? 1 : 0.6,
        child: SitePressable(
          onTap: enabled ? () => onPage(page) : null,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 3.6.w, vertical: 1.1.h),
            decoration: BoxDecoration(
              color: AppColor.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: enabled ? siteCardShadow : null,
              border: Border.all(
                color: enabled
                    ? accent.withValues(alpha: 0.25)
                    : AppColor.appLightColor,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!trailingIcon) ...[
                  Icon(icon, size: 4.4.w, color: fg),
                  1.width,
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 3.1.sp,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
                if (trailingIcon) ...[
                  1.width,
                  Icon(icon, size: 4.4.w, color: fg),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        children: [
          button(
            "Previous",
            Icons.chevron_left_rounded,
            current > 1 && !loading,
            current - 1,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  "Page $current of $last",
                  style: TextStyle(
                    fontSize: 3.3.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColor.appDarkColor,
                  ),
                ),
                if (total != null)
                  Text(
                    "${invWhole(total)} in total",
                    style: TextStyle(fontSize: 2.7.sp, color: AppColor.grey),
                  ),
              ],
            ),
          ),
          button(
            "Next",
            Icons.chevron_right_rounded,
            current < last && !loading,
            current + 1,
            trailingIcon: true,
          ),
        ],
      ),
    );
  }
}

/// Row in a list of alerts: tinted icon, title, note, count and arrow.
class InventoryAlertTile extends StatelessWidget {
  const InventoryAlertTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.count,
    this.onTap,
    this.heroTag,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? count;
  final VoidCallback? onTap;

  /// Hero tag for the icon, matching the screen this tile opens.
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    return SiteCard(
      onTap: onTap,
      margin: EdgeInsets.only(bottom: 1.4.h),
      padding: EdgeInsets.symmetric(horizontal: 3.6.w, vertical: 1.6.h),
      radius: 20,
      child: Row(
        children: [
          if (heroTag != null)
            invHero(
              heroTag!,
              Container(
                padding: EdgeInsets.all(2.4.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 5.4.w, color: color),
              ),
            )
          else
            Container(
              padding: EdgeInsets.all(2.4.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 5.4.w, color: color),
            ),
          3.5.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 3.6.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColor.appDarkColor,
                  ),
                ),
                0.2.height,
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 2.9.sp, color: AppColor.grey),
                ),
              ],
            ),
          ),
          if (count != null) ...[
            2.width,
            Text(
              count!,
              style: TextStyle(
                fontSize: 5.sp,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
          if (onTap != null) ...[
            2.width,
            Icon(
              Icons.chevron_right_rounded,
              size: 5.5.w,
              color: AppColor.grey,
            ),
          ],
        ],
      ),
    );
  }
}
