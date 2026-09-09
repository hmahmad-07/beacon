import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/extensions/sizer.dart';
import '../../core/resources/app_colors.dart';

/// A compact, reusable loading indicator for anywhere in the app: three
/// glassy spheres bounce with squash-and-stretch (flattening on landing,
/// stretching tall mid-air, per classic animation physics) plus a
/// specular highlight and a ground shadow that shrinks as each sphere
/// lifts -- reading as genuine depth rather than a flat spinner or a
/// shimmer skeleton. Drop it in centered on a screen, inline in a list,
/// or wherever a loading state is needed.
class Custom3DLoader extends StatefulWidget {
  const Custom3DLoader({super.key, this.color, this.size = 3.8, this.label});

  /// Sphere color; defaults to the app's primary brand color.
  final Color? color;

  /// Sphere diameter, in `.w` (screen-width-relative) units.
  final double size;

  /// Optional caption shown below the spheres.
  final String? label;

  @override
  State<Custom3DLoader> createState() => _Custom3DLoaderState();
}

class _Custom3DLoaderState extends State<Custom3DLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColor.appColor1;
    final sphereSize = widget.size.w;
    final liftHeight = sphereSize * 0.9;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                // Stagger each sphere a third of a cycle behind the last.
                final t = (_controller.value + i / 3) % 1.0;
                final bounce = math.sin(t * math.pi); // eases 0 -> 1 -> 0
                final lift = bounce * liftHeight;
                final shadowScale = 1 - (bounce * 0.55);
                final shadowOpacity = 0.32 - (bounce * 0.2);

                // Squash-and-stretch: flattened wide right at landing
                // (t near 0/1, squashT near -1), stretched tall near the
                // peak of the arc (bounce near 1).
                final squashT = math.cos(t * math.pi); // -1..1
                final squashAmount = squashT < 0 ? -squashT : 0.0;
                final scaleX = 1 + squashAmount * 0.22;
                final scaleY = 1 - squashAmount * 0.22 + bounce * 0.12;

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 1.4.w),
                  child: SizedBox(
                    width: sphereSize * 1.3,
                    height: sphereSize + liftHeight + 1.5.w,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Positioned(
                          bottom: 0,
                          child: Transform.scale(
                            scaleX: shadowScale,
                            scaleY: shadowScale * 0.4,
                            child: Container(
                              width: sphereSize,
                              height: sphereSize * 0.4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColor.black.withValues(
                                  alpha: shadowOpacity,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: sphereSize * 0.35 + lift,
                          child: Transform(
                            alignment: Alignment.bottomCenter,
                            transform: Matrix4.diagonal3Values(
                              scaleX,
                              scaleY,
                              1.0,
                            ),
                            child: SizedBox(
                              width: sphereSize,
                              height: sphereSize,
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        center: const Alignment(-0.35, -0.4),
                                        radius: 0.9,
                                        colors: [
                                          Color.lerp(
                                            color,
                                            AppColor.white,
                                            0.6,
                                          )!,
                                          color,
                                          Color.lerp(
                                            color,
                                            AppColor.black,
                                            0.3,
                                          )!,
                                        ],
                                        stops: const [0.0, 0.55, 1.0],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: color.withValues(
                                            alpha: 0.35,
                                          ),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Specular highlight -- the small glossy
                                  // catch-light that sells "sphere" over
                                  // "flat circle."
                                  Positioned(
                                    top: sphereSize * 0.16,
                                    left: sphereSize * 0.2,
                                    child: Container(
                                      width: sphereSize * 0.28,
                                      height: sphereSize * 0.2,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          sphereSize,
                                        ),
                                        color: AppColor.white.withValues(
                                          alpha: 0.75,
                                        ),
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
                  ),
                );
              }),
            );
          },
        ),
        if (widget.label != null) ...[
          1.5.height,
          Text(
            widget.label!,
            style: TextStyle(fontSize: 3.5.sp, color: AppColor.appDarkColor),
          ),
        ],
      ],
    );
  }
}
