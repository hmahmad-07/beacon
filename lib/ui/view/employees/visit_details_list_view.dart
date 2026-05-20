import 'package:centrex/core/models/emp_working_detail_model.dart';
import 'package:centrex/core/resources/app_colors.dart';
import 'package:centrex/ui/components/custom_appbar.dart';
import 'package:centrex/ui/components/app_constants.dart';
import 'package:centrex/ui/view/employees/order_details_view.dart';
import 'package:flutter/material.dart';
import 'package:centrex/core/extensions/sizer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class VisitDetailsListView extends StatelessWidget {
  final List<Visit> visits;
  const VisitDetailsListView({super.key, required this.visits});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffold,
      appBar: const CustomAppBar(title: 'Field Activity Logs'),
      body: visits.isEmpty ? _buildEmptyState() : _buildList(),
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

  Widget _buildList() {
    return ListView.builder(
      padding: EdgeInsets.all(5.w),
      physics: const BouncingScrollPhysics(),
      itemCount: visits.length,
      itemBuilder: (context, index) => _buildVisitCard(context, visits[index]),
    );
  }

  Widget _buildVisitCard(BuildContext context, Visit visit) {
    bool isProductive = visit.orders.any((o) => o.isProductive);

    return GestureDetector(
      onTap: isProductive
          ? () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => OrderDetailsView(visit: visit)),
            )
          : null,
      child: Container(
        margin: EdgeInsets.only(bottom: 2.5.h),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadow.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Header
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          visit.placeName,
                          style: TextStyle(
                            fontSize: 4.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColor.appDarkColor,
                          ),
                        ),
                        0.5.height,
                        Text(
                          "${visit.ownerName} | ${visit.channel}",
                          style: TextStyle(
                            fontSize: 2.8.sp,
                            color: AppColor.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _statusBadge(isProductive),
                ],
              ),
            ),

            // Metadata
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Column(
                children: [
                  _infoRow(Icons.access_time_rounded, visit.createdAt),
                  0.8.height,
                  _infoRow(
                    Icons.location_on_rounded,
                    visit.address,
                    maxLines: 1,
                  ),
                ],
              ),
            ),

            1.5.height,

            // Bottom Action Bar (Productive visits only)
            if (isProductive)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.2.h),
                decoration: BoxDecoration(
                  color: AppColor.appColor1.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Tap to view ${visit.orders.length} order details",
                      style: TextStyle(
                        fontSize: 2.6.sp,
                        color: AppColor.appColor1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 3.5.w,
                      color: AppColor.appColor1,
                    ),
                  ],
                ),
              ),

            // Photos Section (if any)
            if (visit.photos.isNotEmpty) _buildPhotosSection(visit.photos),

            // Remarks (Non-productive only)
            if (!isProductive &&
                visit.remarks != null &&
                visit.remarks!.isNotEmpty)
              _buildNonProductiveRemarks(visit.remarks!),

            if (!isProductive) 2.height,
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(bool productive) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: (productive ? AppColor.green : AppColor.red).withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        productive ? "Productive" : "Non-Productive",
        style: TextStyle(
          color: productive ? AppColor.green : AppColor.red,
          fontSize: 2.2.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String val, {int? maxLines}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 3.5.w,
          color: AppColor.appColor1.withValues(alpha: 0.6),
        ),
        2.width,
        Expanded(
          child: Text(
            val,
            maxLines: maxLines,
            overflow: maxLines != null ? TextOverflow.ellipsis : null,
            style: TextStyle(
              fontSize: 2.8.sp,
              color: AppColor.appDarkColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNonProductiveRemarks(String remarks) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppColor.scaffold,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColor.red.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 3.8.w, color: AppColor.red),
          2.width,
          Expanded(
            child: Text(
              remarks,
              style: TextStyle(
                fontSize: 2.8.sp,
                color: AppColor.appDarkColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosSection(List<String> photos) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.5.h),
      child: SizedBox(
        height: 8.h,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.only(left: 4.w),
          itemCount: photos.length,
          itemBuilder: (context, i) => Container(
            margin: EdgeInsets.only(right: 3.w),
            width: 20.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColor.scaffold),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: photos[i],
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: AppColor.grey.withValues(alpha: .3),
                  highlightColor: AppColor.white.withValues(alpha: 0.6),
                  child: Container(color: AppColor.grey.withValues(alpha: 0.3)),
                ),
                errorWidget: (c, u, e) =>
                    Icon(Icons.broken_image, color: AppColor.grey, size: 5.w),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
