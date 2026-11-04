import 'package:beacon/ui/components/site_widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/extensions/sizer.dart';
import '../../../../core/models/Sales/sales_common.dart';
import '../../../../core/resources/app_colors.dart';

final NumberFormat salesAmountFormat = NumberFormat('#,##0.00', 'en_US');
final NumberFormat salesQuantityFormat = NumberFormat('#,##0.##', 'en_US');

String salesMoney(double value) => salesAmountFormat.format(value);
String salesQty(double value) => salesQuantityFormat.format(value);

/// Brand accent for a Sales business (CC or Paani).
Color salesAccentFor(SalesBusiness business) =>
    business == SalesBusiness.cc ? AppColor.cc : AppColor.paani;

/// A money figure that scales down to fit its slot instead of overflowing.
class SalesAmount extends StatelessWidget {
  const SalesAmount({
    super.key,
    required this.value,
    required this.color,
    this.fontSize = 3.9,
  });

  final String value;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 42.w),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Text(
          value,
          maxLines: 1,
          style: TextStyle(
            fontSize: fontSize.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// Growth vs the previous period.
class SalesComparisonChip extends StatelessWidget {
  const SalesComparisonChip({super.key, required this.comparison});

  final SalesComparison comparison;

  @override
  Widget build(BuildContext context) {
    final up = comparison.isUp;
    final down = comparison.isDown;
    final color = up
        ? AppColor.green
        : down
        ? AppColor.red
        : AppColor.grey;
    final icon = up
        ? Icons.trending_up_rounded
        : down
        ? Icons.trending_down_rounded
        : Icons.trending_flat_rounded;
    final percent = comparison.growthPercent;
    final text = percent == null
        ? 'No previous period'
        : '${percent >= 0 ? '+' : ''}${percent.toStringAsFixed(1)}%';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(3.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 3.6.w, color: color),
          1.width,
          Text(
            text,
            maxLines: 1,
            style: TextStyle(
              fontSize: 2.8.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// A list card used by the report screens.
class SalesRowCard extends StatelessWidget {
  const SalesRowCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.trailingValue,
    required this.accent,
    this.trailingCaption,
    this.comparison,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String trailingValue;
  final String? trailingCaption;
  final Color accent;
  final SalesComparison? comparison;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColor.white,
      borderRadius: BorderRadius.circular(3.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(3.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
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
                        fontSize: 3.7.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColor.appDarkColor,
                      ),
                    ),
                    0.3.height,
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 2.8.sp, color: AppColor.grey),
                    ),
                    if (comparison != null) ...[
                      0.8.height,
                      SalesComparisonChip(comparison: comparison!),
                    ],
                  ],
                ),
              ),
              2.width,
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SalesAmount(value: trailingValue, color: accent),
                  if (trailingCaption != null)
                    Text(
                      trailingCaption!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 2.5.sp, color: AppColor.grey),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SalesSectionLabel extends StatelessWidget {
  const SalesSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 2.6.sp,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: AppColor.grey,
      ),
    );
  }
}

/// Loader shown while a Sales report loads. Uses the same animated loader as
/// the Inventory and HR screens.
class SalesLoadingState extends StatelessWidget {
  const SalesLoadingState({super.key, this.color, this.label});

  final Color? color;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return AppLoadingView(color: color, label: label);
  }
}

/// Shown above figures that are still on screen when the latest refresh
/// failed, so the user knows the numbers may be out of date.
class SalesErrorBanner extends StatelessWidget {
  const SalesErrorBanner({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
      decoration: BoxDecoration(
        color: AppColor.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3.r),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 4.w, color: AppColor.red),
          2.width,
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 2.9.sp,
                color: AppColor.appDarkColor,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text("Retry")),
        ],
      ),
    );
  }
}

class SalesErrorState extends StatelessWidget {
  const SalesErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 12.w, color: AppColor.grey),
            2.height,
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 3.4.sp, color: AppColor.appDarkColor),
            ),
            2.height,
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("Try again"),
            ),
          ],
        ),
      ),
    );
  }
}

class SalesEmptyState extends StatelessWidget {
  const SalesEmptyState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 3.4.sp, color: AppColor.grey),
        ),
      ),
    );
  }
}

/// Previous / next controls for paginated lists. Icon buttons keep their
/// minimum tap size and the page label takes the remaining width.
class SalesPaginationBar extends StatelessWidget {
  const SalesPaginationBar({
    super.key,
    required this.meta,
    required this.onPage,
  });

  final SalesPageMeta meta;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    if (meta.lastPage <= 1) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: 1.h),
      child: Row(
        children: [
          IconButton(
            tooltip: "Previous page",
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: meta.hasPrevious
                ? () => onPage(meta.currentPage - 1)
                : null,
          ),
          Expanded(
            child: Text(
              "Page ${meta.currentPage} of ${meta.lastPage}",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 2.9.sp, color: AppColor.grey),
            ),
          ),
          IconButton(
            tooltip: "Next page",
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: meta.hasNext ? () => onPage(meta.currentPage + 1) : null,
          ),
        ],
      ),
    );
  }
}
