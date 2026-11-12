import 'package:beacon/core/constants/constants.dart';
import 'package:beacon/core/controllers/employes_controller.dart';
import 'package:beacon/core/controllers/ui_controller.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/models/site_entry.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/core/utils/day_phase.dart';
import 'package:beacon/core/utils/utils.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/ui/components/site_widgets.dart';
import 'package:beacon/ui/view/dashboard/field_activity_view.dart';
import 'package:beacon/ui/view/dashboard/site_home_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/models/module_model.dart';
import '../privacy/privacy_policy_view.dart';
import '../privacy/terms_conditions_view.dart';
import 'WMS/inventory_hub_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    context.read<UiController>().startClock();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final emp = context.read<EmployesController>();
      if (emp.shops.isEmpty && !emp.isLoading) {
        emp.getSites(context);
      }
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    context.read<UiController>().startClock();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColor.scaffold,
        body: Consumer<EmployesController>(
          builder: (context, emp, _) {
            final sites = SiteEntry.fromShops(emp.shops);
            return Column(
              children: [
                const _Header(),
                Expanded(child: _body(context, emp, sites)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    EmployesController emp,
    List<SiteEntry> sites,
  ) {
    final greeting = Padding(
      padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 0),
      child: const _GreetingCard(),
    );

    final notLoadedYet = emp.sitesDetailModel == null && !emp.sitesLoadFailed;
    if (notLoadedYet || (emp.isLoading && sites.isEmpty)) {
      return Column(children: [greeting]);
    }

    if (sites.isEmpty) {
      return Column(
        children: [
          greeting,
          Expanded(
            child: AppErrorView(
              icon: emp.sitesLoadFailed
                  ? Icons.cloud_off_rounded
                  : Icons.store_mall_directory_outlined,
              message: emp.sitesLoadFailed
                  ? "Could not load your sites. Check your connection and try again."
                  : "No sites are assigned to this account.",
              onRetry: () => emp.getSites(context),
            ),
          ),
        ],
      );
    }

    final salesSites = sites.where((s) => s.hasSales).toList();
    final hrSites = sites.where((s) => s.hasModules).toList();

    final tiles = [
      _ModuleTile(
        module: AppModule.inventory,
        count: sites.length,
        total: sites.length,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const _AllInventoryPage()),
        ),
      ),
      _ModuleTile(
        module: AppModule.sales,
        count: salesSites.length,
        total: sites.length,
        onTap: () =>
            _pickSite(context, module: AppModule.sales, sites: salesSites),
      ),
      _ModuleTile(
        module: AppModule.hr,
        count: hrSites.length,
        total: sites.length,
        onTap: () => _pickSite(context, module: AppModule.hr, sites: hrSites),
      ),
      _ModuleTile(
        module: AppModule.finance,
        count: 0,
        total: sites.length,
        comingSoon: true,
        onTap: () => Utils.showSnackBar(context, "Finance is coming soon."),
      ),
    ];

    return RefreshIndicator(
      color: AppColor.appColor1,
      onRefresh: () => emp.getSites(context),
      child: AnimationLimiter(
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: greeting),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(5.w, 3.h, 5.w, 0),
              sliver: SliverToBoxAdapter(
                child: _ModulesHeader(siteCount: sites.length),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 4.h),
              sliver: SliverGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 3.w,
                crossAxisSpacing: 3.w,
                childAspectRatio: 0.86,
                children: [
                  for (final (i, tile) in tiles.indexed)
                    AnimationConfiguration.staggeredGrid(
                      position: i,
                      columnCount: 2,
                      duration: const Duration(milliseconds: 500),
                      child: ScaleAnimation(
                        scale: 0.9,
                        child: FadeInAnimation(child: tile),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _pickSite(
  BuildContext context, {
  required AppModule module,
  required List<SiteEntry> sites,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColor.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 3.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              module.title,
              style: TextStyle(
                fontSize: 4.8.sp,
                fontWeight: FontWeight.w800,
                color: AppColor.appDarkColor,
              ),
            ),
            0.4.height,
            Text(
              "Choose a site",
              style: TextStyle(fontSize: 3.3.sp, color: AppColor.grey),
            ),
            2.height,
            if (sites.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                child: Text(
                  "No sites are set up for ${module.title} yet.",
                  style: TextStyle(fontSize: 3.4.sp, color: AppColor.grey),
                ),
              )
            else
              for (final site in sites)
                Padding(
                  padding: EdgeInsets.only(bottom: 1.2.h),
                  child: _SitePickTile(
                    site: site,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      openSiteModule(context, site, module);
                    },
                  ),
                ),
          ],
        ),
      ),
    ),
  );
}

class _AllInventoryPage extends StatelessWidget {
  const _AllInventoryPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffold,
      appBar: const CustomAppBar(title: "Inventory"),
      body: InventoryHubView(
        siteName: "All sites",
        accentColor: AppColor.inventory,
      ),
    );
  }
}

void openSiteMenu(BuildContext context) {
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: "Close menu",
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (ctx, animation, secondaryAnimation) =>
        const AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          child: Align(alignment: Alignment.centerLeft, child: _SiteDrawer()),
        ),
    transitionBuilder: (ctx, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: child,
      );
    },
  );
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColor.white,
        border: Border(bottom: BorderSide(color: AppColor.appLightColor)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 2.h),
          child: Row(
            children: [
              IconButton.filled(
                style: ButtonStyle(
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3.r),
                    ),
                  ),
                  backgroundColor: WidgetStatePropertyAll(AppColor.appColor1),
                ),
                tooltip: "Menu",
                icon: Icon(Icons.menu_rounded, color: AppColor.white),
                onPressed: () => openSiteMenu(context),
              ),
              2.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "PARC",
                      style: TextStyle(
                        color: AppColor.appColor2,
                        fontSize: 7.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      'Central Monitoring System',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColor.appColor1,
                        fontSize: 3.5.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SiteDrawer extends StatelessWidget {
  const _SiteDrawer();

  void _openFieldActivity(BuildContext context, List<SiteEntry> sites) {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      MaterialPageRoute<void>(builder: (_) => FieldActivityView(sites: sites)),
    );
  }

  void _openChecklists(BuildContext context, SiteEntry site) {
    final navigator = Navigator.of(context);
    navigator.pop();
    openSiteModule(navigator.context, site, AppModule.checklists);
  }

  void _openPrivacy(BuildContext context) {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      MaterialPageRoute<void>(builder: (_) => const PrivacyPolicyView()),
    );
  }

  void _openTerms(BuildContext context) {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      MaterialPageRoute<void>(builder: (_) => const TermsConditionsView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sites = SiteEntry.allFromShops(
      context.watch<EmployesController>().shops,
    );
    final fieldSites = sites.where((s) => s.hasEmployees).toList();
    final checklistSites = sites.where((s) => s.hasChecklists).toList();

    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.7,
      backgroundColor: AppColor.white,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DrawerHeader(
              name: Constants.name.trim(),
              role: Constants.type.trim(),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: 1.h),
                children: [
                  if (fieldSites.isNotEmpty)
                    _DrawerModuleCard(
                      module: AppModule.employees,
                      color: AppColor.appColor1,
                      subtitle: "Field staff activities",
                      onTap: () => _openFieldActivity(context, fieldSites),
                    ),
                  if (checklistSites.isNotEmpty)
                    _DrawerModuleCard(
                      module: AppModule.checklists,
                      color: checklistSites.first.accent,
                      subtitle: "Al-Azeem Staff Activities",
                      onTap: () =>
                          _openChecklists(context, checklistSites.first),
                    ),
                  _DrawerItem(
                    icon: Icons.privacy_tip_outlined,
                    label: "Privacy policy",
                    subtitle: "How your information is handled",
                    onTap: () => _openPrivacy(context),
                  ),
                  _DrawerItem(
                    icon: Icons.gavel_rounded,
                    label: "Terms & conditions",
                    subtitle: "Rules for using PARC",
                    onTap: () => _openTerms(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _DrawerItem(
              icon: Icons.logout_rounded,
              label: "Logout",
              subtitle: "Sign out of PARC",
              color: AppColor.red,
              onTap: () {
                final navigator = Navigator.of(context);
                navigator.pop();
                confirmLogout(navigator.context);
              },
            ),
            1.height,
          ],
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.name, required this.role});

  final String name;
  final String role;

  @override
  Widget build(BuildContext context) {
    final displayName = name.isEmpty ? "Signed in" : name;
    final initial = name.isEmpty ? "?" : name[0].toUpperCase();
    final displayRole = role.isEmpty
        ? ""
        : role[0].toUpperCase() + role.substring(1);
    final statusBarHeight = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(6.w, statusBarHeight + 3.h, 6.w, 3.5.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColor.appColor1, AppColor.appDarkColor],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "PARC",
            style: TextStyle(
              color: AppColor.appColor2,
              fontSize: 7.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.5,
            ),
          ),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.r),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColor.white.withValues(alpha: 0.12),
                  border: Border.all(color: AppColor.appColor2, width: 2),
                ),
                child: Text(
                  initial,
                  style: TextStyle(
                    color: AppColor.white,
                    fontSize: 6.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              4.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColor.white,
                        fontSize: 5.sp,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    if (displayRole.isNotEmpty) ...[
                      1.height,
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 3.w,
                          vertical: 0.6.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColor.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.badge_outlined,
                              size: 3.6.sp,
                              color: AppColor.appColor2,
                            ),
                            1.5.width,
                            Text(
                              displayRole,
                              style: TextStyle(
                                color: AppColor.white.withValues(alpha: 0.92),
                                fontSize: 3.3.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DrawerModuleCard extends StatelessWidget {
  const _DrawerModuleCard({
    required this.module,
    required this.color,
    required this.subtitle,
    required this.onTap,
  });

  final AppModule module;
  final Color color;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Material(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(3.5.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.6.w),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(module.icon, size: 5.w, color: AppColor.white),
                ),
                3.width,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        module.title,
                        style: TextStyle(
                          fontSize: 4.0.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColor.appDarkColor,
                        ),
                      ),
                      0.3.height,
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 3.0.sp,
                          color: AppColor.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColor.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppColor.appDarkColor;
    final iconColor = color ?? AppColor.grey;

    return Material(
      color: AppColor.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.8.h),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.4.w),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 4.8.w, color: iconColor),
              ),
              3.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 3.8.sp,
                        fontWeight: FontWeight.w600,
                        color: tint,
                      ),
                    ),
                    0.3.height,
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 2.9.sp, color: AppColor.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 4.6.sp,
        fontWeight: FontWeight.w800,
        color: AppColor.appDarkColor,
      ),
    );
  }
}

class _ModulesHeader extends StatelessWidget {
  const _ModulesHeader({required this.siteCount});

  final int siteCount;

  @override
  Widget build(BuildContext context) {
    return Row(children: [const _SectionLabel("Modules")]);
  }
}

/// Dark greeting at the top of home: time-of-day wish, user's name, live
/// time and date.
class _GreetingCard extends StatelessWidget {
  const _GreetingCard();

  static final _timeFormat = DateFormat('hh:mm');
  static final _amPmFormat = DateFormat('a');
  static final _dateFormat = DateFormat('EEEE, d MMMM yyyy');

  /// "RAMISH MUNEER" / "ramish muneer" -> "Ramish Muneer".
  static String _displayName() {
    return Constants.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final ui = context.read<UiController>();
    final name = _displayName();

    // Only this card listens to the clock, so a tick rebuilds nothing else.
    return ValueListenableBuilder<DateTime>(
      valueListenable: ui.clock,
      builder: (context, now, _) =>
          _card(now: now, phase: DayPhase.of(now), name: name),
    );
  }

  Widget _card({
    required DateTime now,
    required DayPhase phase,
    required String name,
  }) {
    final gold = AppColor.appColor2;
    final white = AppColor.white;

    final bgStart = AppColor.appColor1;
    final bgEnd = AppColor.appDarkColor;
    final border = white.withValues(alpha: 0.08);
    final shadow = AppColor.appColor1.withValues(alpha: 0.30);
    final primary = white;
    final secondary = white.withValues(alpha: 0.72);
    final divider = white.withValues(alpha: 0.10);
    final decor = white.withValues(alpha: 0.07);
    final chipText = gold;
    final showStars = phase == DayPhase.evening || phase == DayPhase.night;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [bgStart, bgEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(color: shadow, blurRadius: 24, offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Stack(
          children: [
            // Faded sun / moon in the corner.
            Positioned(
              right: -5.w,
              bottom: -7.w,
              child: Icon(phase.icon, size: 34.w, color: decor),
            ),
            // A few small stars in the evening and at night.
            if (showStars) ..._stars(white.withValues(alpha: 0.45)),
            Padding(
              padding: EdgeInsets.fromLTRB(5.w, 2.2.h, 5.w, 2.2.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.8.w,
                          vertical: 0.6.h,
                        ),
                        decoration: BoxDecoration(
                          color: gold.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: gold.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(phase.icon, size: 3.6.sp, color: gold),
                            1.5.width,
                            Text(
                              phase.greeting,
                              style: TextStyle(
                                fontSize: 3.1.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                                color: chipText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            _timeFormat.format(now),
                            style: TextStyle(
                              fontSize: 6.4.sp,
                              fontWeight: FontWeight.w800,
                              height: 1,
                              letterSpacing: 0.5,
                              color: primary,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          1.width,
                          Text(
                            _amPmFormat.format(now),
                            style: TextStyle(
                              fontSize: 3.sp,
                              fontWeight: FontWeight.w800,
                              color: gold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  1.8.height,
                  Text(
                    name.isEmpty ? "Hello there" : "Hello, $name",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 5.8.sp,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      color: primary,
                    ),
                  ),
                  0.5.height,
                  Text(
                    phase.message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 3.3.sp, color: secondary),
                  ),
                  1.8.height,
                  Container(height: 1, color: divider),
                  1.4.height,
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 3.4.sp,
                        color: gold,
                      ),
                      2.width,
                      Expanded(
                        child: Text(
                          _dateFormat.format(now),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 3.3.sp,
                            fontWeight: FontWeight.w600,
                            color: secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _stars(Color color) {
    Widget star(double right, double bottom, double size) => Positioned(
      right: right,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );

    return [
      star(30.w, 9.h, 1.2.w),
      star(22.w, 13.h, 0.8.w),
      star(38.w, 4.h, 0.9.w),
      star(12.w, 17.h, 0.7.w),
    ];
  }
}

class _ModuleTile extends StatefulWidget {
  const _ModuleTile({
    required this.module,
    required this.count,
    required this.total,
    required this.onTap,
    this.comingSoon = false,
  });

  final AppModule module;
  final int count;
  final int total;
  final VoidCallback onTap;
  final bool comingSoon;

  @override
  State<_ModuleTile> createState() => _ModuleTileState();
}

class _ModuleTileState extends State<_ModuleTile> {
  // Pressed flag is held in UiController, keyed by this State.
  late final UiController _ui;

  @override
  void initState() {
    super.initState();
    _ui = context.read<UiController>();
  }

  @override
  void dispose() {
    _ui.forget(this);
    super.dispose();
  }

  void _setPressed(bool value) => _ui.setValue(this, value);

  @override
  Widget build(BuildContext context) {
    final pressed = context.select<UiController, bool>(
      (ui) => ui.valueOf<bool>(this, false),
    );

    final c1 = AppColor.appColor1;
    final gold = AppColor.appColor2;
    final white = AppColor.white;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: c1.withValues(alpha: 0.10),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: c1.withValues(alpha: 0.10)),
                gradient: LinearGradient(
                  colors: [white, Color.lerp(white, c1, 0.05)!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    right: -8.w,
                    top: -8.w,
                    child: Container(
                      width: 24.w,
                      height: 24.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c1.withValues(alpha: 0.04),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 3.w,
                    right: 3.w,
                    child: widget.comingSoon
                        ? Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.5.w,
                              vertical: 0.6.h,
                            ),
                            decoration: BoxDecoration(
                              color: gold,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "SOON",
                              style: TextStyle(
                                fontSize: 2.6.sp,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                                color: c1,
                              ),
                            ),
                          )
                        : Container(
                            padding: EdgeInsets.all(1.6.w),
                            decoration: BoxDecoration(
                              color: c1.withValues(alpha: 0.06),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 3.2.w,
                              color: c1,
                            ),
                          ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(3.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: gold.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: gold.withValues(alpha: 0.45),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            widget.module.icon,
                            size: 10.w,
                            color: gold,
                          ),
                        ),
                        1.8.height,
                        Text(
                          widget.module.title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 4.8.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColor.appDarkColor,
                          ),
                        ),
                        0.3.height,
                        Text(
                          widget.module.subtitle,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 3.sp,
                            height: 1.2,
                            color: AppColor.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Row in the Sales / HR site picker sheet.
class _SitePickTile extends StatelessWidget {
  const _SitePickTile({required this.site, required this.onTap});

  final SiteEntry site;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: site.accent.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Row(
            children: [
              SiteLogo(asset: site.asset, accent: site.accent, size: 12.w),
              3.width,
              Expanded(
                child: Text(
                  site.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 4.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColor.appDarkColor,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 3.6.w,
                color: site.accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
