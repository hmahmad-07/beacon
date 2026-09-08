import 'package:flutter/material.dart';

import '../../core/extensions/sizer.dart';
import '../../core/resources/app_colors.dart';
import 'app_constants.dart';

/// Shared glass-card tile used by the module grid (site -> module) and the
/// department grid (module -> department). Keeping this in one place means
/// both grids stay visually consistent as more modules are added.
class AnimatedOptionCard extends StatelessWidget {
  const AnimatedOptionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.onTap,
    this.subtitle,
    this.locked = false,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final color = locked ? AppColor.grey : accentColor;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4.5.r),
        boxShadow: AppShadow.soft,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4.5.r),
        child: Material(
          color: AppColor.transparent,
          child: InkWell(
            onTap: locked ? null : onTap,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: AppColor.white),
                  ),
                ),
                Positioned(
                  top: -7.w,
                  right: -6.w,
                  child: _glassOrb(size: 22.w, color: color),
                ),
                Positioned(
                  bottom: -10.w,
                  left: -8.w,
                  child: _glassOrb(size: 25.w, color: color),
                ),
                if (locked)
                  Positioned(
                    top: 2.w,
                    right: 2.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColor.grey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(3.r),
                      ),
                      child: Text(
                        "Soon",
                        style: TextStyle(
                          fontSize: 2.6.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColor.grey,
                        ),
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 2.2.h,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(3.5.w),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                          ),
                          child: Icon(icon, color: AppColor.white, size: 7.w),
                        ),
                        1.5.height,
                        Flexible(
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColor.black,
                              fontSize: 3.sp,
                              height: 1.2,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: AppColor.appDarkColor.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          0.3.height,
                          Flexible(
                            child: Text(
                              subtitle!,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColor.grey,
                                fontSize: 2.3.sp,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ],
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

  Widget _glassOrb({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: AppColor.white.withValues(alpha: 0.12)),
      ),
    );
  }
}
