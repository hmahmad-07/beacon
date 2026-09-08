import 'package:beacon/core/models/Employees/emp_working_detail_model.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/ui/components/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:beacon/core/extensions/sizer.dart';

class OrderDetailsView extends StatelessWidget {
  final Visit visit;
  const OrderDetailsView({super.key, required this.visit});

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      backgroundColor: AppColor.scaffold,
      appBar: const CustomAppBar(title: "Sales Intelligence"),
      body: Column(
        children: [
          _buildExecutiveHeader(visit, calculatedSubtotal),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
              physics: const BouncingScrollPhysics(),
              children: [
                _sectionHeader("Order Pipeline"),
                2.height,
                ...visit.orders.map((order) => _buildExecutiveOrderCard(order)),
                3.height,
                _buildBillingBreakdown(calculatedSubtotal),
                10.height,
              ],
            ),
          ),
          _buildGrandTotalFooter(calculatedSubtotal),
        ],
      ),
    );
  }

  Widget _buildExecutiveHeader(Visit visit, double total) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColor.white,
        boxShadow: AppShadow.soft,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Icon(
              Icons.receipt_rounded,
              size: 50.w,
              color: AppColor.appColor1.withValues(alpha: 0.02),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(5.w, 3.h, 5.w, 4.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            visit.placeName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 4.5.sp,
                              fontWeight: FontWeight.w900,
                              color: AppColor.appDarkColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                          0.5.height,
                          Text(
                            "ORDER ID: FF-${visit.id.toString().padLeft(6, '0')}",
                            style: TextStyle(
                              fontSize: 3.sp,
                              color: AppColor.grey,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _auditStatusBadge(
                      visit.orders.isNotEmpty &&
                          visit.orders.first.isProductive,
                    ),
                  ],
                ),
                2.height,
                Row(
                  children: [
                    _headerMetaChip(
                      Icons.access_time_filled_rounded,
                      visit.createdAt,
                    ),
                    3.width,
                    _headerMetaChip(Icons.location_on_rounded, "GPS VERIFIED"),
                  ],
                ),
                3.height,
                _buildAuditStepper(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _auditStatusBadge(bool isProductive) => Container(
    padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [AppColor.green, AppColor.green.withValues(alpha: 0.8)],
      ),
      borderRadius: BorderRadius.circular(50),
      boxShadow: [
        BoxShadow(
          color: AppColor.green.withValues(alpha: 0.2),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.verified_rounded, color: AppColor.white, size: 4.w),
        1.5.width,
        Text(
          isProductive ? "PRODUCTIVE" : "NON PRODUCTIVE",
          style: TextStyle(
            color: AppColor.white,
            fontSize: 3.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),
  );

  Widget _headerMetaChip(IconData icon, String t) => Container(
    padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.6.h),
    decoration: BoxDecoration(
      color: AppColor.scaffold,
      borderRadius: BorderRadius.circular(4.r),
    ),
    child: Row(
      children: [
        Icon(icon, size: 2.8.w, color: AppColor.grey),
        1.5.width,
        Text(
          t,
          style: TextStyle(
            fontSize: 2.5.sp,
            color: AppColor.appDarkColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );

  Widget _buildAuditStepper() {
    return Row(
      children: [
        _stepIndicator("Shop Visited", true),
        _stepConnector(true),
        _stepIndicator("Order Booked", true),
        _stepConnector(true),
        _stepIndicator("Visit Completed", true),
      ],
    );
  }

  Widget _stepIndicator(String label, bool done) => Column(
    children: [
      Container(
        width: 3.w,
        height: 3.w,
        decoration: BoxDecoration(
          color: done ? AppColor.green : AppColor.grey.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
      ),
      1.height,
      Text(
        label,
        style: TextStyle(
          fontSize: 2.5.sp,
          color: done ? AppColor.appDarkColor : AppColor.grey,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );

  Widget _stepConnector(bool done) => Expanded(
    child: Container(
      height: 1.5,
      color: done
          ? AppColor.green.withValues(alpha: 0.3)
          : AppColor.grey.withValues(alpha: 0.1),
      margin: EdgeInsets.only(bottom: 2.5.h),
    ),
  );

  Widget _buildExecutiveOrderCard(Order order) {
    return Column(
      children: [
        ...order.items.map((item) => _buildExecutiveProductRow(item)),
        2.height,
      ],
    );
  }

  Widget _buildExecutiveProductRow(Map<String, dynamic> item) {
    final double rate = double.tryParse(item['rate']?.toString() ?? '0') ?? 0;
    final double pcs = double.tryParse(item['qty_pcs']?.toString() ?? '0') ?? 0;
    final double box = double.tryParse(item['qty_box']?.toString() ?? '0') ?? 0;
    final double foc = double.tryParse(item['qty_foc']?.toString() ?? '0') ?? 0;

    // LOCAL CALCULATION: (Rate * (Pcs + Box))
    final double itemValuation = (pcs + box) * rate;

    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(4.r),
        boxShadow: AppShadow.soft,
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 1.5.w,
              decoration: BoxDecoration(
                color: AppColor.appColor1,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4.r),
                  bottomLeft: Radius.circular(4.r),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['item_name']?.toString().toUpperCase() ?? "N/A",
                      style: TextStyle(
                        fontSize: 3.2.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColor.appDarkColor,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    1.height,
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _infoSmallChip(
                            "Pcs: ${pcs.toInt()}",
                            AppColor.appColor1,
                          ),
                          2.width,
                          _infoSmallChip("Box: ${box.toInt()}", AppColor.grey),
                          2.width,
                          _infoSmallChip("FOC: ${foc.toInt()}", AppColor.green),
                          2.width,
                          _infoSmallChip("Rate: $rate", AppColor.grey),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 5.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "ITEM VALUE",
                    style: TextStyle(
                      fontSize: 2.sp,
                      color: AppColor.grey,
                      fontWeight: FontWeight.normal,
                      letterSpacing: 1.2,
                    ),
                  ),
                  0.5.height,
                  Text(
                    "PKR ${itemValuation.toStringAsFixed(0)}",
                    style: TextStyle(
                      fontSize: 3.6.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColor.appDarkColor,
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

  Widget _buildBillingBreakdown(double subtotal) {
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(4.r),
        boxShadow: AppShadow.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader("Financial Summary"),
          3.height,
          _billingRow(
            "Cart Subtotal",
            "PKR ${subtotal.toStringAsFixed(2)}",
            bold: false,
          ),
          1.5.height,
          _billingRow(
            "Verified Revenue",
            "PKR ${subtotal.toStringAsFixed(2)}",
            bold: true,
            color: AppColor.appColor1,
          ),
        ],
      ),
    );
  }

  Widget _billingRow(String l, String v, {bool bold = false, Color? color}) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l,
            style: TextStyle(
              fontSize: 2.8.sp,
              color: AppColor.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            v,
            style: TextStyle(
              fontSize: 3.sp,
              color: color ?? AppColor.appDarkColor,
              fontWeight: bold ? FontWeight.w900 : FontWeight.bold,
            ),
          ),
        ],
      );

  Widget _buildGrandTotalFooter(double total) {
    return Container(
      padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 4.h),
      decoration: BoxDecoration(
        color: AppColor.appDarkColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "TOTAL BOOKED VALUE",
                  style: TextStyle(
                    fontSize: 1.8.sp,
                    color: AppColor.white.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                0.5.height,
                Text(
                  "PKR ${total.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 5.2.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColor.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.2.h),
              decoration: BoxDecoration(
                color: AppColor.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified_user_rounded,
                    color: AppColor.green,
                    size: 4.w,
                  ),
                  2.width,
                  Text(
                    "BOOKED",
                    style: TextStyle(
                      color: AppColor.white,
                      fontSize: 3.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
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

  Widget _infoSmallChip(String t, Color c) => Container(
    padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
    decoration: BoxDecoration(
      color: c.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(4.r),
    ),
    child: Text(
      t,
      style: TextStyle(color: c, fontSize: 2.5.sp, fontWeight: FontWeight.bold),
    ),
  );

  Widget _sectionHeader(String t) => Text(
    t.toUpperCase(),
    style: TextStyle(
      fontSize: 3.sp,
      fontWeight: FontWeight.bold,
      color: AppColor.grey,
      letterSpacing: 1.5,
    ),
  );
}
