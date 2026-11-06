import 'package:beacon/core/models/Employees/emp_working_detail_model.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/core/utils/utils.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/ui/components/site_design.dart';
import 'package:flutter/material.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class OrderDetailsView extends StatelessWidget {
  final Visit visit;
  const OrderDetailsView({super.key, required this.visit});

  @override
  Widget build(BuildContext context) {
    final accent = context.siteAccent;
    double calculatedSubtotal = 0;
    for (var order in visit.orders) {
      for (var item in order.items) {
        final double rate =
            double.tryParse(item['rate']?.toString() ?? '0') ?? 0;
        final double pcs =
            double.tryParse(item['qty_pcs']?.toString() ?? '0') ?? 0;
        final double box =
            double.tryParse(item['qty_box']?.toString() ?? '0') ?? 0;

        // Exact formula based on your requirement: (Rate * Total Quantity)
        calculatedSubtotal += (pcs + box) * rate;
      }
    }

    final items = [for (final order in visit.orders) ...order.items];
    var i = 0;

    return Scaffold(
      backgroundColor: AppColor.scaffold,
      appBar: const CustomAppBar(title: "Order Details"),
      body: Column(
        children: [
          Expanded(
            child: AnimationLimiter(
              child: ListView(
                padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 3.h),
                physics: const BouncingScrollPhysics(),
                children: [
                  siteStagger(i++, _buildExecutiveHeader(visit)),
                  3.height,
                  siteStagger(
                    i++,
                    SiteSectionTitle("Order items", count: items.length),
                  ),
                  if (items.isEmpty)
                    siteStagger(
                      i++,
                      SiteCard(
                        child: Text(
                          "No items were booked on this visit.",
                          style: TextStyle(
                            fontSize: 3.3.sp,
                            color: AppColor.grey,
                          ),
                        ),
                      ),
                    ),
                  for (final item in items)
                    siteStagger(i++, _buildExecutiveProductRow(item, accent)),
                  2.height,
                  siteStagger(
                    i++,
                    _buildBillingBreakdown(calculatedSubtotal, accent),
                  ),
                ],
              ),
            ),
          ),
          _buildGrandTotalFooter(calculatedSubtotal, accent),
        ],
      ),
    );
  }

  Widget _buildExecutiveHeader(Visit visit) {
    final productive =
        visit.orders.isNotEmpty && visit.orders.first.isProductive;
    return SiteBanner(
      eyebrow: "Order FF-${visit.id.toString().padLeft(6, '0')}",
      title: Utils.capitalize(visit.placeName.toLowerCase()),
      subtitle: visit.ownerName.isEmpty ? null : visit.ownerName,
      leading: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.receipt_long_rounded, color: Colors.white, size: 7.w),
      ),
      pills: [
        _auditStatusBadge(productive),
        SiteBannerPill(
          Utils.formatDate(visit.createdAt),
          icon: Icons.access_time_filled_rounded,
        ),
        const SiteBannerPill("GPS verified", icon: Icons.location_on_rounded),
      ],
      child: _buildAuditStepper(),
    );
  }

  Widget _auditStatusBadge(bool isProductive) {
    final color = isProductive ? AppColor.green : AppColor.red;
    return SitePill(
      isProductive ? "Productive" : "Non-productive",
      bg: Colors.white,
      fg: color,
      icon: isProductive ? Icons.verified_rounded : Icons.block_rounded,
    );
  }

  Widget _buildAuditStepper() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.4.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _stepIndicator("Shop visited", true),
          _stepConnector(true),
          _stepIndicator("Order booked", true),
          _stepConnector(true),
          _stepIndicator("Completed", true),
        ],
      ),
    );
  }

  Widget _stepIndicator(String label, bool done) => Column(
    children: [
      Container(
        width: 5.w,
        height: 5.w,
        decoration: BoxDecoration(
          color: done ? Colors.white : Colors.white.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: done
            ? Icon(Icons.check_rounded, size: 3.4.w, color: AppColor.green)
            : null,
      ),
      0.8.height,
      Text(
        label,
        style: TextStyle(
          fontSize: 2.5.sp,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );

  Widget _stepConnector(bool done) => Expanded(
    child: Container(
      height: 2,
      margin: EdgeInsets.only(bottom: 2.6.h, left: 1.w, right: 1.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: done ? 0.6 : 0.2),
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );

  Widget _buildExecutiveProductRow(Map<String, dynamic> item, Color accent) {
    final double rate = double.tryParse(item['rate']?.toString() ?? '0') ?? 0;
    final double pcs = double.tryParse(item['qty_pcs']?.toString() ?? '0') ?? 0;
    final double box = double.tryParse(item['qty_box']?.toString() ?? '0') ?? 0;
    final double foc = double.tryParse(item['qty_foc']?.toString() ?? '0') ?? 0;

    // LOCAL CALCULATION: (Rate * (Pcs + Box))
    final double itemValuation = (pcs + box) * rate;

    return SiteCard(
      margin: EdgeInsets.only(bottom: 1.4.h),
      padding: EdgeInsets.all(3.6.w),
      child: Row(
        children: [
          SiteIconBadge(Icons.inventory_2_rounded, size: 11.w, color: accent),
          3.5.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['item_name']?.toString() ?? "N/A",
                  style: TextStyle(
                    fontSize: 3.6.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColor.appDarkColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                0.8.height,
                Wrap(
                  spacing: 1.5.w,
                  runSpacing: 0.6.h,
                  children: [
                    _infoSmallChip("Pcs ${pcs.toInt()}", accent),
                    _infoSmallChip("Box ${box.toInt()}", accent),
                    _infoSmallChip("FOC ${foc.toInt()}", AppColor.green),
                    _infoSmallChip("Rate $rate", AppColor.grey),
                  ],
                ),
              ],
            ),
          ),
          2.width,
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "VALUE",
                style: TextStyle(
                  fontSize: 2.2.sp,
                  color: AppColor.grey,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              0.4.height,
              Text(
                "PKR ${itemValuation.toStringAsFixed(0)}",
                style: TextStyle(
                  fontSize: 3.8.sp,
                  fontWeight: FontWeight.w900,
                  color: accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillingBreakdown(double subtotal, Color accent) {
    return SiteCard(
      padding: EdgeInsets.all(4.5.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Financial summary",
            style: TextStyle(
              fontSize: 4.sp,
              fontWeight: FontWeight.w800,
              color: AppColor.appDarkColor,
            ),
          ),
          1.5.height,
          SiteInfoRow(
            icon: Icons.shopping_cart_rounded,
            label: "Cart subtotal",
            value: "PKR ${subtotal.toStringAsFixed(2)}",
          ),
          SiteInfoRow(
            icon: Icons.verified_rounded,
            label: "Verified revenue",
            value: "PKR ${subtotal.toStringAsFixed(2)}",
            color: AppColor.green,
            valueColor: accent,
          ),
        ],
      ),
    );
  }

  Widget _buildGrandTotalFooter(double total, Color accent) {
    return Container(
      padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 2.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, siteShade(accent, -0.12)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: SiteBannerStat(
                label: "Total booked value",
                value: "PKR ${total.toStringAsFixed(2)}",
              ),
            ),
            2.width,
            const SiteBannerPill("Booked", icon: Icons.verified_user_rounded),
          ],
        ),
      ),
    );
  }

  Widget _infoSmallChip(String t, Color c) => Container(
    padding: EdgeInsets.symmetric(horizontal: 2.2.w, vertical: 0.4.h),
    decoration: BoxDecoration(
      color: c.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      t,
      style: TextStyle(color: c, fontSize: 2.5.sp, fontWeight: FontWeight.w700),
    ),
  );
}
