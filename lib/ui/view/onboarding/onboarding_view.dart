import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/controllers/onboarding_controller.dart';
import '../../../core/extensions/sizer.dart';
import '../../../core/models/project_model.dart';
import '../../../core/resources/app_colors.dart';
import '../../../core/utils/onboarding_store.dart';
import '../startup_flow.dart';

const _ink = Color(0xFF0B0E14);
const _gold = Color(0xFFE0A447);
const _sapphire = Color(0xFF3B82F6);

/// One site slide: the logo comes from the project, the copy is set here.
class _Site {
  const _Site({
    required this.project,
    required this.logo,
    required this.tagline,
    required this.description,
  });

  final AppProject project;
  final String logo;
  final String tagline;
  final String description;
}

/// First-run introduction to PARC. Shown once, after the splash.
class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView>
    with SingleTickerProviderStateMixin {
  final PageController _pages = PageController();
  late final AnimationController _float;

  static final List<_Site> _sites = [
    _Site(
      project: AppProject.paani,
      logo: "assets/paani.png",
      tagline: "Bottled drinking water",
      description:
          "We deliver clean, consistent bottled drinking water across Faisalabad, from 19-litre dispenser bottles to 500 ml bottles and 200 ml cups. Homes, offices, schools, institutions and distributors are all served, with doorstep delivery for regular and bulk orders. Clean water and prompt service are at the heart of what we do.",
    ),
    _Site(
      project: AppProject.alAzeem,
      logo: "assets/Al-Azeem.jpeg",
      tagline: "Animal welfare foundation",
      description:
          "Al Azeem Foundation rescues, treats and rehabilitates abandoned, injured and vulnerable animals and wildlife. Our work covers medical care, shelter, nutrition and recovery support. Our Shelter House offers supervised pet boarding for families who are travelling. We also support clean water, education, healthcare and emergency aid for communities in need.",
    ),
    _Site(
      project: AppProject.rabiaTrust,
      logo: "assets/Rabia-Trust.png",
      tagline: "Hospital and community health",
      description:
          "Rabia Trust Hospital on Satiana Road, Batala Colony, offers 24/7 emergency care, laboratory and radiology services, a pharmacy, blood bank and dialysis, in a 200-plus-bed facility. Its immunization centre provides EPI, HPV and polio vaccination. The trust also runs free medical camps in rural areas and community health awareness programmes.",
    ),
    _Site(
      project: AppProject.corporateCanteen,
      logo: "assets/corporate-canteen.jpg",
      tagline: "Catering and mess services",
      description:
          "Corporate Canteen provides catering for offices, factories, hospitals, hostels and institutions across Faisalabad. Daily mess services offer weekly or monthly lunch plans on rotating menus, with corporate catering for buffets, boxed lunches and plated meals. Event catering covers live counters and full setups. Quality, hygiene and on-time delivery are the standard.",
    ),
  ];

  /// One page per site.
  int get _pageCount => _sites.length;

  double get _pageValue =>
      _pages.hasClients ? (_pages.page ?? _pages.initialPage.toDouble()) : 0.0;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _float.dispose();
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await OnboardingStore.markDone();
    if (!mounted) return;
    await continueStartup(context);
  }

  void _next(OnboardingController ob) {
    if (ob.isLast) {
      _finish();
      return;
    }
    _pages.nextPage(
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingController(pageCount: _pageCount),
      child: Builder(
        builder: (context) {
          final ob = context.watch<OnboardingController>();
          return Scaffold(
            backgroundColor: _ink,
            body: Stack(
              children: [
                Positioned.fill(child: _Backdrop(float: _float)),
                SafeArea(
                  child: Column(
                    children: [
                      _topBar(ob),
                      Expanded(
                        child: PageView.builder(
                          controller: _pages,
                          itemCount: _pageCount,
                          onPageChanged: (i) =>
                              context.read<OnboardingController>().setPage(i),
                          itemBuilder: (_, i) => _page(i, ob),
                        ),
                      ),
                      _bottomBar(ob),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────── Chrome

  Widget _topBar(OnboardingController ob) {
    return Padding(
      padding: EdgeInsets.fromLTRB(6.w, 1.h, 4.w, 0),
      child: Row(
        children: [
          Text(
            "PARC",
            style: TextStyle(
              color: _gold,
              fontSize: 3.4.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
            ),
          ),
          const Spacer(),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: ob.isLast ? 0 : 1,
            child: IgnorePointer(
              ignoring: ob.isLast,
              child: TextButton(
                onPressed: () => _pages.animateToPage(
                  _pageCount - 1,
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOutCubic,
                ),
                child: Text(
                  "Skip",
                  style: TextStyle(
                    color: AppColor.appLightColor,
                    fontSize: 4.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(OnboardingController ob) {
    final last = ob.isLast;
    return Padding(
      padding: EdgeInsets.fromLTRB(6.w, 1.h, 6.w, 3.h),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                for (var i = 0; i < ob.pageCount; i++) _dot(i == ob.page),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _next(ob),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: last ? 7.w : 6.w,
                vertical: 1.7.h,
              ),
              decoration: BoxDecoration(
                color: _gold,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: _gold.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    last ? "Get started" : "Next",
                    style: TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 4.sp,
                    ),
                  ),
                  1.5.width,
                  Icon(
                    last
                        ? Icons.arrow_forward_rounded
                        : Icons.chevron_right_rounded,
                    color: _ink,
                    size: 5.w,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.only(right: 1.w),
      width: active ? 6.w : 1.6.w,
      height: 0.9.h,
      decoration: BoxDecoration(
        color: active ? _gold : Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  // ─────────────────────────── Pages

  /// Each page fades and scales as it moves away from the centre, and its
  /// content re-plays its entrance when it becomes the active page.
  Widget _page(int i, OnboardingController ob) {
    final active = ob.page == i;
    final token = ob.entrance;

    final Widget content = _sitePage(_sites[i], active, token);

    return AnimatedBuilder(
      animation: _pages,
      child: content,
      builder: (context, child) {
        final d = (_pageValue - i).abs().clamp(0.0, 1.0);
        return Opacity(
          opacity: 1 - 0.55 * d,
          child: Transform.scale(scale: 1 - 0.1 * d, child: child),
        );
      },
    );
  }

  Widget _sitePage(_Site s, bool active, int token) {
    final light =
        Color.lerp(s.project.accent, Colors.white, 0.35) ?? s.project.accent;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 7.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Reveal(
            active: active,
            token: token,
            delay: 0.0,
            offset: 40,
            child: _LogoCard(logo: s.logo, pulse: _float),
          ),
          4.height,
          _Reveal(
            active: active,
            token: token,
            delay: 0.2,
            child: Text(
              s.project.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 6.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          1.height,
          _Reveal(
            active: active,
            token: token,
            delay: 0.28,
            child: Text(
              s.tagline.toUpperCase(),
              style: TextStyle(
                color: light,
                fontSize: 3.2.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ),
          2.5.height,
          _Reveal(
            active: active,
            token: token,
            delay: 0.36,
            child: Text(
              s.description,
              textAlign: TextAlign.center,
              style: _bodyStyle(),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Helpers

  TextStyle _bodyStyle() =>
      TextStyle(color: AppColor.appLightColor, fontSize: 4.sp, height: 1.5);
}

/// Fades and slides its child in when its page becomes active. Each child
/// starts at [delay] (0 to 1) along the entrance, which staggers the page.
class _Reveal extends StatelessWidget {
  const _Reveal({
    required this.active,
    required this.token,
    required this.delay,
    required this.child,
    this.offset = 24,
  });

  final bool active;
  final int token;
  final double delay;
  final double offset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(active ? 'on-$token' : 'off'),
      tween: Tween<double>(begin: active ? 0 : 1, end: 1),
      duration: const Duration(milliseconds: 1100),
      child: child,
      builder: (context, t, child) {
        final a = Interval(delay, 1, curve: Curves.easeOutCubic).transform(t);
        return Opacity(
          opacity: a.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - a) * offset),
            child: child,
          ),
        );
      },
    );
  }
}

/// Floating colour orbs behind every page. They drift on a slow loop.
class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.float});

  final Animation<double> float;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: float,
      builder: (context, _) {
        final t = float.value * 2 * math.pi;
        return Stack(
          children: [
            Positioned(
              top: -12.h + math.sin(t) * 3.h,
              right: -14.w + math.cos(t) * 4.w,
              child: _orb(40.h, _gold, 0.10),
            ),
            Positioned(
              bottom: -16.h + math.cos(t) * 3.h,
              left: -18.w + math.sin(t) * 4.w,
              child: _orb(46.h, _sapphire, 0.09),
            ),
            Positioned(
              top: 40.h + math.sin(t * 2) * 2.h,
              left: 8.w,
              child: _orb(12.h, _gold, 0.06),
            ),
          ],
        );
      },
    );
  }

  Widget _orb(double size, Color color, double alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: alpha),
      ),
    );
  }
}

/// The large logo for a site page. It is shown on its own, with no frame,
/// and breathes gently.
class _LogoCard extends StatelessWidget {
  const _LogoCard({required this.logo, required this.pulse});

  final String logo;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        final s = 1 + 0.02 * math.sin(pulse.value * 2 * math.pi);
        return Transform.scale(scale: s, child: child);
      },
      child: ClipRRect(
        borderRadius: BorderRadiusGeometry.circular(4.r),
        child: Image.asset(logo, fit: BoxFit.contain, width: 75.w),
      ),
    );
  }
}
