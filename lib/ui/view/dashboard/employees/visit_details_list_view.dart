import 'dart:developer';
import 'package:beacon/core/models/Employees/emp_working_detail_model.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/core/utils/utils.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/ui/components/site_design.dart';
import 'package:beacon/ui/view/dashboard/employees/order_details_view.dart';
import 'package:beacon/ui/view/dashboard/employees/full_screen_image_viewer.dart';
import 'package:beacon/ui/view/dashboard/employees/visit_navigation_map_view.dart';
import 'package:flutter/material.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

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

  bool get _isSales => widget.dept.toLowerCase().contains("sales");
  bool get _isQa => widget.dept.toLowerCase().contains("qlty. assurance");

  Widget _buildHeader(List<Visit> visits) {
    final productive = visits
        .where((v) => v.orders.any((o) => o.isProductive))
        .length;
    return SiteHeaderCard(
      margin: EdgeInsets.only(bottom: 1.h),
      icon: Icons.fact_check_rounded,
      title: "Field activity",
      subtitle: widget.dept,
      description: _isSales
          ? "$productive productive · ${visits.length - productive} non-productive"
          : "Customer touchpoints in visit order",
      badge: "${visits.length} ${visits.length == 1 ? 'visit' : 'visits'}",
    );
  }

  Widget _buildEmptyState() {
    return const SiteEmptyState(
      icon: Icons.history_toggle_off_rounded,
      title: "No visits recorded",
      message: "This employee has no customer visits for the selected day.",
    );
  }

  Widget _buildList(List<Visit> sortedVisits) {
    log(sortedVisits.first.createdAt);

    return AnimationLimiter(
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 4.h),
        physics: const BouncingScrollPhysics(),
        itemCount: sortedVisits.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) return siteStagger(0, _buildHeader(sortedVisits));
          return siteStagger(
            index,
            _buildVisitCard(context, sortedVisits[index - 1], index),
          );
        },
      ),
    );
  }

  Widget _buildVisitCard(BuildContext context, Visit visit, int number) {
    final accent = context.siteAccent;
    bool isProductive = visit.orders.any((o) => o.isProductive);
    String remarks =
        visit.orders.isNotEmpty && visit.orders.first.remarks != null
        ? visit.orders.first.remarks!
        : visit.remarks ?? '';

    String stayTime = extractDuration(remarks);
    final when =
        visit.orders.isNotEmpty && visit.orders.first.orderDate.isNotEmpty
        ? visit.orders.first.orderDate
        : visit.createdAt;
    final cleanRemarks = remarks.split('(').first.trim();

    return SiteCard(
      margin: EdgeInsets.only(top: 1.6.h),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(3.2.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageThumbnail(context, visit.effectivePhotos, number),
                3.5.width,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              Utils.capitalize(visit.placeName.toLowerCase()),
                              style: TextStyle(
                                fontSize: 4.1.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColor.appDarkColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_isQa) ...[
                            1.5.width,
                            _actionButton(
                              icon: Icons.map_rounded,
                              label: "Route",
                              color: accent,
                              onTap: () => context.pushSite(
                                VisitNavigationMapView(visit: visit),
                              ),
                            ),
                          ],
                        ],
                      ),
                      0.8.height,
                      _detailRow(Icons.person_rounded, visit.ownerName),
                      _detailRow(Icons.category_rounded, visit.channel),
                      _detailRow(
                        Icons.schedule_rounded,
                        Utils.formatDate(when),
                      ),
                      if (stayTime.isNotEmpty)
                        _detailRow(Icons.timer_rounded, "Stay $stayTime"),
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
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.2.w, vertical: 1.2.h),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.04),
              border: Border(
                top: BorderSide(color: accent.withValues(alpha: 0.08)),
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(22),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (_isSales) _statusBadge(isProductive),
                    const Spacer(),
                    if (!_isQa) ...[
                      _actionButton(
                        icon: Icons.map_rounded,
                        label: "Route",
                        color: accent,
                        onTap: () => context.pushSite(
                          VisitNavigationMapView(visit: visit),
                        ),
                      ),
                      2.width,
                      _actionButton(
                        icon: Icons.phone_rounded,
                        label: "Call",
                        color: accent,
                        onTap: () =>
                            Utils.launchURL("tel:${visit.phoneNumber}"),
                      ),
                    ],
                    if (isProductive) ...[
                      2.width,
                      _actionButton(
                        icon: Icons.shopping_cart_rounded,
                        label: "Order",
                        color: AppColor.green,
                        filled: true,
                        onTap: () =>
                            context.pushSite(OrderDetailsView(visit: visit)),
                      ),
                    ],
                  ],
                ),
                if (!isProductive && cleanRemarks.isNotEmpty) ...[
                  1.height,
                  _detailRow(Icons.note_alt_rounded, "Remarks: $cleanRemarks"),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageThumbnail(
    BuildContext context,
    List<String> photos,
    int number,
  ) {
    final accent = context.siteAccent;
    bool hasPhotos = photos.isNotEmpty;
    return SitePressable(
      onTap: hasPhotos
          ? () => context.pushSite(FullScreenImageViewer(images: photos))
          : null,
      child: Container(
        width: 25.w,
        height: 25.w,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasPhotos)
                CachedNetworkImage(
                  imageUrl: photos[0],
                  fit: BoxFit.cover,
                  errorWidget: (c, u, e) => Icon(
                    Icons.broken_image_rounded,
                    color: accent.withValues(alpha: 0.6),
                  ),
                )
              else
                Icon(
                  Icons.storefront_rounded,
                  color: accent.withValues(alpha: 0.55),
                  size: 9.w,
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
              Positioned(
                left: 1.5.w,
                top: 1.5.w,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 1.8.w,
                    vertical: 0.3.h,
                  ),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "#$number",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 2.4.sp,
                      fontWeight: FontWeight.w800,
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
    return Padding(
      padding: EdgeInsets.only(bottom: 0.45.h),
      child: Row(
        children: [
          Icon(icon, size: 3.2.w, color: context.siteAccent),
          1.6.width,
          Expanded(
            child: Text(
              text.isEmpty ? "—" : text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 3.sp,
                color: isAddress ? AppColor.grey : AppColor.darkGrey,
                fontWeight: isAddress ? FontWeight.w500 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(bool productive) {
    return SitePill.tint(
      productive ? "Productive" : "Non-productive",
      productive ? AppColor.green : AppColor.red,
      icon: productive ? Icons.check_circle_rounded : Icons.block_rounded,
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    return SitePressable(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 2.8.w, vertical: 0.8.h),
        decoration: BoxDecoration(
          color: filled ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 3.6.w, color: filled ? Colors.white : color),
            1.2.width,
            Text(
              label,
              style: TextStyle(
                color: filled ? Colors.white : color,
                fontSize: 2.9.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
