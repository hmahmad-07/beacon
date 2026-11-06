import 'package:beacon/core/extensions/routes.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/models/module_model.dart';
import 'package:beacon/core/models/site_entry.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/core/utils/utils.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/ui/components/site_widgets.dart';
import 'package:beacon/ui/view/dashboard/al_azeem/checklist_hub_view.dart';
import 'package:beacon/ui/view/dashboard/department_picker_view.dart';
import 'package:beacon/ui/view/dashboard/sales/sales_hub_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class SiteHomeView extends StatelessWidget {
  const SiteHomeView({super.key, required this.site, required this.clr});

  final SiteEntry site;
  final Color clr;

  String get _heroTag => 'site-logo-${site.name}';

  List<AppModule> get _modules => [
    if (site.hasEmployees) AppModule.employees,
    if (site.hasEmployees && site.hasModules) AppModule.hr,
    if (site.hasChecklists) AppModule.checklists,
    if (site.hasSales) AppModule.sales,
  ];

  @override
  Widget build(BuildContext context) {
    final modules = _modules;

    return Scaffold(
      backgroundColor: AppColor.scaffold,
      appBar: CustomAppBar(title: site.name),
      body: AnimationLimiter(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 4.h),
          children: [
            _anim(0, _Banner(site: site, heroTag: _heroTag)),
            3.height,
            if (modules.isEmpty)
              _Card(
                child: Center(
                  child: Text(
                    "No modules are set up for this site yet.",
                    style: TextStyle(fontSize: 3.4.sp, color: AppColor.grey),
                  ),
                ),
              )
            else ...[
              _anim(1, _SectionTitle("Modules", modules.length, site.accent)),
              1.8.height,
              for (final (i, m) in modules.indexed)
                _anim(
                  i + 2,
                  _ModuleCard(
                    module: m,
                    accent: site.accent,
                    onTap: () => _open(context, m),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _anim(int i, Widget child) => AnimationConfiguration.staggeredList(
    position: i,
    duration: const Duration(milliseconds: 420),
    child: SlideAnimation(
      verticalOffset: 28,
      child: FadeInAnimation(child: child),
    ),
  );

  void _open(BuildContext context, AppModule m) {
    if (!site.supports(m)) {
      Utils.showSnackBar(context, "${m.title} is not set up for ${site.name}.");
      return;
    }

    final shop = site.shop, project = site.project;
    final Widget? body = m.id == AppModule.checklists.id
        ? ChecklistHubView(accentColor: site.accent)
        : m.id == AppModule.sales.id
        ? (project == null ? null : SalesHubView(business: project))
        : (shop == null
              ? null
              : DepartmentGrid(
                  module: m,
                  shop: shop,
                  accentColor: site.accent,
                  siteImage: site.asset,
                  siteName: site.name,
                  description: m.subtitle,
                  heroTag: _heroTag,
                ));
    if (body == null) return;

    AppRoutes.push(
      Scaffold(
        backgroundColor: AppColor.scaffold,
        appBar: CustomAppBar(title: m.title),
        body: body,
      ),
    );
  }
}

// ───────────────────────── Shared helpers ─────────────────────────

Color _shift(Color c, double d) {
  final h = HSLColor.fromColor(c);
  return h.withLightness((h.lightness + d).clamp(0.0, 1.0)).toColor();
}

/// White rounded card with soft shadow.
class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding ?? EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
    decoration: BoxDecoration(
      color: AppColor.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}

/// Press-to-shrink tap wrapper.
class _Pressable extends StatefulWidget {
  const _Pressable({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  void _set(bool v) => setState(() => _down = v);

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTapDown: (_) => _set(true),
    onTapCancel: () => _set(false),
    onTapUp: (_) => _set(false),
    onTap: widget.onTap,
    child: AnimatedScale(
      scale: _down ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: widget.child,
    ),
  );
}

/// Small rounded pill (count badges, chips).
class _Pill extends StatelessWidget {
  const _Pill(this.text, {required this.bg, required this.fg, this.icon});

  final String text;
  final Color bg, fg;
  final IconData? icon;

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
          Icon(icon, size: 3.8.w, color: fg),
          SizedBox(width: 1.5.w),
        ],
        Text(
          text,
          style: TextStyle(
            fontSize: 3.sp,
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      ],
    ),
  );
}

// ───────────────────────── Sections ─────────────────────────

/// Gradient banner with Hero logo, site name and module count.
class _Banner extends StatelessWidget {
  const _Banner({required this.site, required this.heroTag});

  final SiteEntry site;
  final String heroTag;

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
    final n = site.screenModules.length;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [site.accent, _shift(site.accent, -0.12)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: site.accent.withValues(alpha: 0.35),
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
            child: Row(
              children: [
                Hero(
                  tag: heroTag,
                  child: SiteLogo(
                    asset: site.asset,
                    accent: site.accent,
                    size: 18.w,
                  ),
                ),
                4.width,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome to",
                        style: TextStyle(
                          fontSize: 3.sp,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      0.3.height,
                      Text(
                        site.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 5.2.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.15,
                        ),
                      ),
                      1.height,
                      _Pill(
                        "$n ${n == 1 ? 'module' : 'modules'} available",
                        bg: Colors.white.withValues(alpha: 0.2),
                        fg: Colors.white,
                        icon: Icons.apps_rounded,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, this.count, this.accent);

  final String title;
  final int count;
  final Color accent;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 1.2.w,
        height: 3.2.h,
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      SizedBox(width: 2.5.w),
      Text(
        title,
        style: TextStyle(
          fontSize: 4.6.sp,
          fontWeight: FontWeight.w800,
          color: AppColor.appDarkColor,
        ),
      ),
      const Spacer(),
      _Pill("$count", bg: accent.withValues(alpha: 0.12), fg: accent),
    ],
  );
}

/// Module tile: gradient icon, title, subtitle, arrow.
class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.module,
    required this.accent,
    required this.onTap,
  });

  final AppModule module;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: 1.8.h),
    child: _Pressable(
      onTap: onTap,
      child: _Card(
        padding: EdgeInsets.all(3.6.w),
        child: Row(
          children: [
            Container(
              height: 13.w,
              width: 13.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [_shift(accent, 0.14), accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(module.icon, color: Colors.white, size: 6.5.w),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module.title,
                    style: TextStyle(
                      fontSize: 4.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColor.appDarkColor,
                    ),
                  ),
                  SizedBox(height: 0.4.h),
                  Text(
                    module.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 3.1.sp,
                      color: AppColor.grey,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 2.w),
            Container(
              padding: EdgeInsets.all(1.8.w),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 3.6.w,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
