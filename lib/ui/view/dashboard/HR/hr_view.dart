import 'package:beacon/ui/components/site_design.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:iconsx_plus/iconsx_plus.dart';
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
  String _getReportSubtitle(String report) {
    final r = report.toLowerCase();
    if (r.contains("employment type")) {
      return "Employees and salary by job type";
    }
    if (r.contains("salary cost")) {
      return "Salary cost and paid salary per employee";
    }
    if (r.contains("budget")) {
      return "Approved budget against actual headcount";
    }
    if (r.contains("headcount")) {
      return "Active headcount across departments";
    }
    if (r.contains("attendance")) {
      return "Monthly attendance of every employee";
    }
    if (r.contains("monthly")) {
      return "Headcount, salary, joiners and leavers";
    }
    return "";
  }

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
      pushInSite(
        widget.clr,
        EmpSalaryTypeView(
          siteName: widget.siteName,
          siteID: widget.siteID,
          deptName: widget.deptName,
          deptID: widget.deptID,
          siteImage: widget.siteImage,
        ),
      );
    } else if (r.contains('salary cost')) {
      pushInSite(
        widget.clr,
        SalaryCostReportView(
          siteName: widget.siteName,
          siteID: widget.siteID,
          deptName: widget.deptName,
          deptID: widget.deptID,
          siteImage: widget.siteImage,
        ),
      );
    } else if (r.contains('attendance')) {
      pushInSite(
        widget.clr,
        AttendanceReportView(
          siteName: widget.siteName,
          siteID: widget.siteID,
          deptName: widget.deptName,
          deptID: widget.deptID,
          siteImage: widget.siteImage,
        ),
      );
    } else if (r.contains('budget')) {
      pushInSite(
        widget.clr,
        BudgetHeadcountReportView(
          siteName: widget.siteName,
          siteID: widget.siteID,
          deptName: widget.deptName,
          deptID: widget.deptID,
          siteImage: widget.siteImage,
        ),
      );
    } else if (r.contains('headcount')) {
      pushInSite(
        widget.clr,
        HeadcountReportView(
          siteName: widget.siteName,
          siteID: widget.siteID,
          deptName: widget.deptName,
          deptID: widget.deptID,
          siteImage: widget.siteImage,
        ),
      );
    } else if (r.contains('monthly')) {
      pushInSite(
        widget.clr,
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
    return SiteScope.wrap(
      accent: widget.clr,
      child: Scaffold(
        backgroundColor: AppColor.scaffold,
        appBar: CustomAppBar(title: widget.deptName),
        body: AnimationLimiter(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(bottom: 4.h),
            children: [
              siteStagger(0, _buildSiteHeader()),
              Padding(
                padding: EdgeInsets.fromLTRB(5.w, 2.5.h, 5.w, 0),
                child: Column(
                  children: [
                    siteStagger(
                      1,
                      SiteSectionTitle("Reports", count: hrReports.length),
                    ),
                    for (final (index, report) in hrReports.indexed)
                      siteStagger(
                        index + 2,
                        _reportTile(
                          report: report,
                          onTap: () => _onReportTap(report),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSiteHeader() {
    final image = widget.siteImage;
    return SiteHeaderCard(
      title: widget.deptName,
      subtitle: widget.siteName,
      description: "Human resource reports for this department",
      logoAsset: image != null && image.isNotEmpty ? image : null,
      icon: BoxIcons.bx_buildings,
      badge: "${hrReports.length} reports",
    );
  }

  Widget _reportTile({required String report, required VoidCallback onTap}) {
    return SiteActionTile(
      icon: _getReportIcon(report),
      title: report,
      subtitle: _getReportSubtitle(report),
      onTap: onTap,
    );
  }
}
