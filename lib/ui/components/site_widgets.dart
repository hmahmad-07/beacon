import 'package:beacon/core/controllers/auth_controller.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/ui/components/custom_3d_loader.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Shared widgets for the sites flow. Every screen in the flow uses these, so
/// the look and the loader stay the same everywhere.

/// A site logo inside a rounded box. Falls back to an accent-tinted icon when
/// the asset is missing.
class SiteLogo extends StatelessWidget {
  const SiteLogo({super.key, this.asset, required this.accent, this.size});

  final String? asset;
  final Color accent;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final box = size ?? 14.w;
    final fallback = Container(
      color: accent.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Icon(Icons.apartment_rounded, color: accent, size: box * 0.45),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(3.w),
      child: SizedBox(
        width: box,
        height: box,
        child: asset == null
            ? fallback
            : Image.asset(
                asset!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => fallback,
              ),
      ),
    );
  }
}

/// A full-width tappable row used for modules. Locked rows show a lock icon
/// and grey text, and they still tap so the screen can explain why.
class AppTile extends StatelessWidget {
  const AppTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.accent,
    this.locked = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color accent;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tint = locked ? AppColor.grey : accent;

    return Material(
      color: AppColor.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.2.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColor.appLightColor),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.8.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tint.withValues(alpha: 0.12),
                ),
                child: Icon(icon, size: 5.5.w, color: tint),
              ),
              3.width,
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
                        fontWeight: FontWeight.bold,
                        color: locked ? AppColor.grey : AppColor.appDarkColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      0.4.height,
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 3.sp, color: AppColor.grey),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                locked ? Icons.lock_outline_rounded : Icons.chevron_right_rounded,
                color: AppColor.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The one loader for the app. It wraps Custom3DLoader so every screen uses
/// the same look.
class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key, this.color, this.label});

  final Color? color;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Custom3DLoader(
        color: color ?? AppColor.appColor1,
        label: label ?? "Loading…",
      ),
    );
  }
}

/// Shared empty and error state with an optional retry button.
class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    required this.message,
    this.icon = Icons.error_outline_rounded,
    this.onRetry,
  });

  final String message;
  final IconData icon;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14.w, color: AppColor.grey.withValues(alpha: 0.5)),
            2.height,
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 3.6.sp, color: AppColor.grey),
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

/// Asks for confirmation, then logs out. Used by every screen in the flow.
Future<void> confirmLogout(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        "Log out?",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColor.appDarkColor,
        ),
      ),
      content: Text(
        "You will need to sign in again to open your sites.",
        style: TextStyle(color: AppColor.darkGrey),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text("Cancel", style: TextStyle(color: AppColor.grey)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColor.red),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text("Logout"),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;
  await context.read<AuthController>().logout(context);
}
