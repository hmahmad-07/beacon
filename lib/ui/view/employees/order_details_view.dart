import 'package:centrex/core/models/emp_working_detail_model.dart';
import 'package:centrex/core/resources/app_colors.dart';
import 'package:centrex/ui/components/custom_appbar.dart';
import 'package:centrex/ui/components/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:centrex/core/extensions/sizer.dart';

class OrderDetailsView extends StatelessWidget {
  final Visit visit;
  const OrderDetailsView({super.key, required this.visit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffold,
      appBar: CustomAppBar(title: visit.placeName),
      body: ListView(
        padding: EdgeInsets.all(5.w),
        children: [
          _buildSummaryHeader(),
          2.height,
          ...visit.orders.map((order) => _buildOrderTable(order)),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadow.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: AppColor.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.shopping_cart_checkout_rounded, color: AppColor.green, size: 5.w),
              ),
              3.width,
              Text(
                "Order Context",
                style: TextStyle(fontSize: 3.5.sp, fontWeight: FontWeight.bold, color: AppColor.appDarkColor),
              ),
            ],
          ),
          2.height,
          _metaRow("Visit Time", visit.createdAt),
          _metaRow("Recorded Date", visit.orders.first.orderDate),
          _metaRow("Channel", visit.channel),
          _metaRow("Total Orders", visit.orders.length.toString()),
        ],
      ),
    );
  }

  Widget _metaRow(String l, String v) => Padding(
    padding: EdgeInsets.only(bottom: 0.8.h),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: TextStyle(fontSize: 2.8.sp, color: AppColor.grey, fontWeight: FontWeight.w600)),
        Text(v, style: TextStyle(fontSize: 2.8.sp, color: AppColor.appDarkColor, fontWeight: FontWeight.bold)),
      ],
    ),
  );

  Widget _buildOrderTable(Order order) {
    return Container(
      margin: EdgeInsets.only(bottom: 3.h),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadow.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                Icon(Icons.receipt_long_rounded, size: 4.w, color: AppColor.appColor1),
                2.width,
                Text(
                  "Items breakdown",
                  style: TextStyle(fontSize: 3.2.sp, fontWeight: FontWeight.w900, color: AppColor.appDarkColor),
                ),
              ],
            ),
          ),
          
          // Table Layout
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColor.scaffold.withValues(alpha: 0.5),
            ),
            child: DataTable(
              columnSpacing: 15,
              headingRowHeight: 5.h,
              dataRowMinHeight: 4.h,
              dataRowMaxHeight: 6.h,
              horizontalMargin: 4.w,
              columns: [
                DataColumn(label: Text('Item Name', style: _headerStyle())),
                DataColumn(label: Text('Qty', style: _headerStyle())),
                DataColumn(label: Text('Rate', style: _headerStyle())),
                DataColumn(label: Text('Total', style: _headerStyle())),
              ],
              rows: order.items.map((item) => DataRow(
                cells: [
                  DataCell(SizedBox(
                    width: 30.w,
                    child: Text(item['item_name']?.toString() ?? "N/A", style: _cellStyle(isBold: true)))),
                  DataCell(Text(item['qty']?.toString() ?? '0', style: _cellStyle())),
                  DataCell(Text(item['rate']?.toString() ?? '0', style: _cellStyle())),
                  DataCell(Text(item['total_price']?.toString() ?? '0', style: _cellStyle(color: AppColor.appColor1))),
                ],
              )).toList(),
            ),
          ),

          if (order.remarks != null && order.remarks!.isNotEmpty)
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Text(
                "Feedback: ${order.remarks}",
                style: TextStyle(fontSize: 2.8.sp, color: AppColor.grey, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500),
              ),
            ),
        ],
      ),
    );
  }

  TextStyle _headerStyle() => TextStyle(
    fontSize: 2.5.sp,
    fontWeight: FontWeight.w900,
    color: AppColor.appDarkColor,
    letterSpacing: 0.5,
  );

  TextStyle _cellStyle({bool isBold = false, Color? color}) => TextStyle(
    fontSize: 2.6.sp,
    fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
    color: color ?? AppColor.appDarkColor,
  );
}
