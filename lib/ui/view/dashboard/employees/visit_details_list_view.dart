import 'dart:developer';
import 'package:beacon/core/models/Employees/emp_working_detail_model.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/core/utils/utils.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/ui/components/app_constants.dart';
import 'package:beacon/ui/view/dashboard/employees/order_details_view.dart';
import 'package:beacon/ui/view/dashboard/employees/full_screen_image_viewer.dart';
import 'package:beacon/ui/view/dashboard/employees/visit_navigation_map_view.dart';
import 'package:flutter/material.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../../core/extensions/routes.dart';

class VisitDetailsListView extends StatefulWidget {
  final List<Visit> visits;
  final String dept;
  const VisitDetailsListView({
    super.key,
    required this.visits,
    required this.dept,
  });

  @override
  State<VisitDetailsListView> createState() => _VisitDetailsListViewState();
}

class _VisitDetailsListViewState extends State<VisitDetailsListView> {
  String extractDuration(String remarks) {
    final match = RegExp(r'\((\d+)m(\d+)s\)').firstMatch(remarks);
    if (match != null) {
      final minutes = int.parse(match.group(1)!);
      final seconds = int.parse(match.group(2)!);
      return '$minutes min $seconds Sec';
    }
    return '';
  }

  bool _is24DVisit(String placeName) {
    final name = placeName.toLowerCase();
    return RegExp(r'24[\s\-]*d').hasMatch(name);
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, Visit> uniqueVisits = {};

    for (var visit in widget.visits) {
      if (_is24DVisit(visit.placeName)) {
        continue;
      }

      final dateStr =
          visit.orders.isNotEmpty && visit.orders.first.orderDate.isNotEmpty
          ? visit.orders.first.orderDate
          : visit.createdAt;
      final parsedDate = Utils.parseDateTime(dateStr);
      final key =
          '${parsedDate.year}-${parsedDate.month}-${parsedDate.day}_${visit.placeName.trim().toLowerCase()}';

      if (!uniqueVisits.containsKey(key)) {
        uniqueVisits[key] = visit;
      } else {
        final existingVisit = uniqueVisits[key]!;
        final existingProductive = existingVisit.orders.any(
          (o) => o.isProductive,
        );
        final newProductive = visit.orders.any((o) => o.isProductive);
        if (!existingProductive && newProductive) {
          uniqueVisits[key] = visit;
        }
      }
    }

    final sortedVisits = uniqueVisits.values.toList()
      ..sort((a, b) {
        final dateA = a.orders.isNotEmpty && a.orders.first.orderDate.isNotEmpty
            ? a.orders.first.orderDate
            : a.createdAt;
        final dateB = b.orders.isNotEmpty && b.orders.first.orderDate.isNotEmpty
            ? b.orders.first.orderDate
            : b.createdAt;
        return Utils.parseDateTime(dateA).compareTo(Utils.parseDateTime(dateB));
      });

    log('Dept Visits: ${widget.dept}');

    return Scaffold(
      backgroundColor: AppColor.scaffold,
      appBar: const CustomAppBar(title: 'Field Activity Logs'),
      body: sortedVisits.isEmpty
          ? _buildEmptyState()
          : _buildList(sortedVisits),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 15.w,
            color: AppColor.grey.withValues(alpha: 0.3),
          ),
          2.height,
          Text(
            'No Visits Recorded',
            style: TextStyle(
              fontSize: 4.sp,
              fontWeight: FontWeight.bold,
              color: AppColor.appDarkColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Visit> sortedVisits) {
    log(sortedVisits.first.createdAt);

    return AnimationLimiter(
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        physics: const BouncingScrollPhysics(),
        itemCount: sortedVisits.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 400),
            child: SlideAnimation(
              horizontalOffset: 80.0,
              child: FadeInAnimation(
                child: _buildVisitCard(context, sortedVisits[index]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVisitCard(BuildContext context, Visit visit) {
    bool isProductive = visit.orders.any((o) => o.isProductive);
    String remarks =
        visit.orders.isNotEmpty && visit.orders.first.remarks != null
        ? visit.orders.first.remarks!
        : visit.remarks ?? '';

    String stayTime = extractDuration(remarks);

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(4.r),
        boxShadow: AppShadow.soft,
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(3.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageThumbnail(context, visit.effectivePhotos),
                3.width,
                Container(width: 1.5, height: 15.h, color: AppColor.scaffold),
                3.width,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                textAlign: TextAlign.left,
                                visit.placeName.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 4.2.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColor.appDarkColor,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          if (widget.dept.toLowerCase().contains(
                            "qlty. assurance",
                          )) ...[
                            _actionButton(
                              icon: Icons.map_rounded,
                              label: "Route",
                              color: AppColor.appDarkColor,
                              onTap: () => AppRoutes.push(
                                VisitNavigationMapView(visit: visit),
                              ),
                            ),
                          ],
                        ],
                      ),
                      0.7.height,
                      _detailRow(Icons.person_rounded, visit.ownerName),
                      0.3.height,
                      _detailRow(Icons.category_rounded, visit.channel),
                      0.3.height,
                      _detailRow(
                        Icons.event_note_rounded,
                        visit.orders.isNotEmpty &&
                                visit.orders.first.orderDate.isNotEmpty
                            ? visit.orders.first.orderDate
                            : visit.createdAt,
                      ),
                      0.3.height,
                      _detailRow(Icons.timer_rounded, "Stay Time: $stayTime"),
                      0.7.height,
                      _detailRow(
                        Icons.location_on_rounded,
                        visit.address,
                        isAddress: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!widget.dept.toLowerCase().contains("qlty. assurance"))
            Divider(height: 1, color: AppColor.scaffold, thickness: 1),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (widget.dept.toLowerCase().contains("sales")) ...[
                      _statusBadge(isProductive),
                      const Spacer(),
                    ],
                    if (!widget.dept.toLowerCase().contains(
                      "qlty. assurance",
                    )) ...[
                      _actionButton(
                        icon: Icons.map_rounded,
                        label: "Route",
                        color: AppColor.appDarkColor,
                        onTap: () => AppRoutes.push(
                          VisitNavigationMapView(visit: visit),
                        ),
                      ),
                      3.width,
                      _actionButton(
                        icon: Icons.phone_rounded,
                        label: "Call",
                        color: AppColor.appColor1,
                        onTap: () =>
                            Utils.launchURL("tel:${visit.phoneNumber}"),
                      ),
                    ],
                    if (isProductive) ...[
                      3.width,
                      _actionButton(
                        icon: Icons.shopping_cart_rounded,
                        label: "Order",
                        color: AppColor.green,
                        onTap: () =>
                            AppRoutes.push(OrderDetailsView(visit: visit)),
                      ),
                    ],
                  ],
                ),
                if (!isProductive)
                  Divider(color: AppColor.scaffold, thickness: 1),
                if (!isProductive)
                  if (!isProductive)
                    _detailRow(
                      Icons.note_alt_rounded,
                      "Remarks: ${remarks.split('(').first.trim()}",
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageThumbnail(BuildContext context, List<String> photos) {
    bool hasPhotos = photos.isNotEmpty;
    return GestureDetector(
      onTap: hasPhotos
          ? () => AppRoutes.push(FullScreenImageViewer(images: photos))
          : null,
      child: Container(
        width: 30.w,
        height: 15.h,
        decoration: BoxDecoration(
          color: AppColor.scaffold,
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4.r),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasPhotos)
                CachedNetworkImage(
                  imageUrl: photos[0],
                  fit: BoxFit.cover,
                  errorWidget: (c, u, e) =>
                      Icon(Icons.broken_image, color: AppColor.grey),
                )
              else
                Icon(
                  Icons.image_not_supported_rounded,
                  color: AppColor.grey,
                  size: 8.w,
                ),

              if (photos.length > 1)
                Container(
                  color: Colors.black45,
                  child: Center(
                    child: Text(
                      "+${photos.length - 1}",
                      style: TextStyle(
                        color: AppColor.white,
                        fontSize: 3.5.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text, {bool isAddress = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Icon(icon, size: 2.8.w, color: AppColor.appColor2),
        1.5.width,
        Expanded(
          child: Text(
            text,
            textAlign: TextAlign.left,
            maxLines: isAddress ? 1 : 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 3.sp,
              color: isAddress ? AppColor.grey : AppColor.appDarkColor,
              fontWeight: isAddress ? FontWeight.w500 : FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(bool productive) {
    Color color = productive ? AppColor.green : AppColor.red;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        productive ? "PRODUCTIVE" : "NON-PRODUCTIVE",
        style: TextStyle(
          color: color,
          fontSize: 2.5.sp,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 1.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 4.r, color: color),
            1.5.width,
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 3.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
