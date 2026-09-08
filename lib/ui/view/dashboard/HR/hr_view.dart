import 'package:beacon/ui/components/app_constants.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:iconsx_plus/iconsx_plus.dart';
import 'package:beacon/core/extensions/routes.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/ui/view/dashboard/HR/emp_salary_type_view.dart';
import 'package:beacon/ui/view/dashboard/HR/salary_cost_report_view.dart';
import 'package:beacon/ui/view/dashboard/HR/attendance_report_view.dart';
import 'package:beacon/ui/view/dashboard/HR/headcount_report_view.dart';
import 'package:beacon/ui/view/dashboard/HR/monthly_hr_report_view.dart';
import 'package:beacon/ui/view/dashboard/HR/budget_headcount_report_view.dart';

class HumanResourceView extends StatefulWidget {
  final String siteName;
  final String siteID;
  final String deptName;
  final int deptID;
  final Color clr;
  final String? siteImage;
  const HumanResourceView({
    super.key,
    required this.siteName,
    required this.siteID,
    required this.deptName,
    required this.deptID,
    required this.clr,
    this.siteImage,
  });

  @override
  State<HumanResourceView> createState() => _HumanResourceViewState();
}

class _HumanResourceViewState extends State<HumanResourceView> {
  final hrReports = [
    "Employment Type Report",
    "Salary Cost Report",
    "Headcount Report",
    "Attendance Report",
    "Monthly HR Report",
    "Budget vs Actual Headcount",
  ];
  IconData _getReportIcon(String report) {
    final r = report.toLowerCase();
    if (r.contains("employment type")) {
      return BoxIcons.bxs_id_card;
    }
    if (r.contains("salary")) {
      return BoxIcons.bxs_wallet;
    }
    if (r.contains("headcount") && r.contains("budget")) {
      return BoxIcons.bxs_bar_chart_alt_2;
    }
    if (r.contains("headcount")) {
      return BoxIcons.bxs_group;
    }
    if (r.contains("attendance")) {
      return BoxIcons.bxs_calendar_check;
    }
    if (r.contains("monthly")) {
      return BoxIcons.bxs_report;
    }
    return BoxIcons.bx_folder;
  }

  void _onReportTap(String report) {
    final r = report.toLowerCase();
    if (r.contains('employment type')) {
      AppRoutes.push(
        EmpSalaryTypeView(
          siteName: widget.siteName,
          siteID: widget.siteID,
          deptName: widget.deptName,
          deptID: widget.deptID,
          siteImage: widget.siteImage,
        ),
      );
    } else if (r.contains('salary cost')) {
      AppRoutes.push(
        SalaryCostReportView(
          siteName: widget.siteName,
          siteID: widget.siteID,
          deptName: widget.deptName,
          deptID: widget.deptID,
          siteImage: widget.siteImage,
        ),
      );
    } else if (r.contains('attendance')) {
      AppRoutes.push(
        AttendanceReportView(
          siteName: widget.siteName,
          siteID: widget.siteID,
          deptName: widget.deptName,
          deptID: widget.deptID,
          siteImage: widget.siteImage,
        ),
      );
    } else if (r.contains('budget')) {
      AppRoutes.push(
        BudgetHeadcountReportView(
          siteName: widget.siteName,
          siteID: widget.siteID,
          deptName: widget.deptName,
          deptID: widget.deptID,
          siteImage: widget.siteImage,
        ),
      );
    } else if (r.contains('headcount')) {
      AppRoutes.push(
        HeadcountReportView(
          siteName: widget.siteName,
          siteID: widget.siteID,
          deptName: widget.deptName,
          deptID: widget.deptID,
          siteImage: widget.siteImage,
        ),
      );
    } else if (r.contains('monthly')) {
      AppRoutes.push(
        MonthlyHRReportView(
          siteName: widget.siteName,
          siteID: widget.siteID,
          deptName: widget.deptName,
          deptID: widget.deptID,
          siteImage: widget.siteImage,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffold,
      appBar: CustomAppBar(title: widget.deptName),
      body: Column(
        children: [
          _buildSiteHeader(),
          Expanded(
            child: AnimationLimiter(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                itemCount: hrReports.length,
                separatorBuilder: (context, index) => 1.5.height,
                itemBuilder: (context, index) {
                  final report = hrReports[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 500),
                    child: SlideAnimation(
                      horizontalOffset: 80,
                      curve: Curves.easeOutCubic,
                      child: FadeInAnimation(
                        child: _reportTile(
                          report: report,
                          onTap: () => _onReportTap(report),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSiteHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.8.h),
      margin: EdgeInsets.fromLTRB(6.w, 2.h, 6.w, 0.5.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColor.appColor1.withValues(alpha: 0.85),
            AppColor.appDarkColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(3.5.r),
        boxShadow: AppShadow.soft,
      ),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            padding: EdgeInsets.all(1.5.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColor.white,
            ),
            child: widget.siteImage != null && widget.siteImage!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12.w),
                    child: Image.asset(widget.siteImage!, fit: BoxFit.contain),
                  )
                : Icon(BoxIcons.bx_buildings, color: widget.clr, size: 6.w),
          ),
          3.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.siteName,
                  style: TextStyle(
                    color: AppColor.white,
                    fontSize: 4.5.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportTile({required String report, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(3.5.r),
        boxShadow: AppShadow.soft,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3.5.r),
        child: Material(
          color: AppColor.transparent,
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 6.w,
              vertical: 0.6.h,
            ),
            leading: Icon(_getReportIcon(report), color: widget.clr, size: 8.r),
            title: Text(
              report,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 4.5.sp,
                color: AppColor.black,
                shadows: AppShadow.textShadow,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 4.r,
              color: AppColor.grey,
            ),
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}
