// ignore_for_file: use_build_context_synchronously

import 'package:centrex/core/extensions/routes.dart';
import 'package:centrex/core/models/employes_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:centrex/core/controllers/employes_controller.dart';
import 'package:centrex/core/extensions/sizer.dart';
import 'package:centrex/core/resources/app_colors.dart';
import 'package:centrex/ui/components/custom_appbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:centrex/core/models/emp_working_detail_model.dart';
import 'package:centrex/core/utils/pdf_report_generator.dart';
import 'package:centrex/core/utils/utils.dart';
import 'package:centrex/ui/components/custom_date_picker.dart';
import 'package:centrex/ui/view/employees/pdf_preview_view.dart';
import 'employee_detail_view.dart';
import 'package:intl/intl.dart';
import 'external_orders_view.dart';

class EmployeeListView extends StatefulWidget {
  final String department;
  const EmployeeListView({super.key, required this.department});

  @override
  State<EmployeeListView> createState() => _EmployeeListViewState();
}

class _EmployeeListViewState extends State<EmployeeListView> {
  DateTime selectedAuditDate = DateTime.now();
  Future<void> _handleGenerateAuditReport(
    BuildContext context,
    EmployesController controller,
    List<User> departmentUsers,
  ) async {
    bool? shouldGenerate = await showDialog<bool>(
      context: context,
      builder: (context) {
        DateTime tempDate = selectedAuditDate;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(Icons.analytics_rounded, color: AppColor.appColor1),
                  2.width,
                  Text(
                    "Sales Report",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 4.5.sp,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Generate a daily performance and activity audit report for the sales team.",
                    style: TextStyle(color: AppColor.grey, fontSize: 3.2.sp),
                  ),
                  2.height,
                  CustomDatePicker(
                    hint: "Select Date",
                    fieldTitle: "Report Date",
                    selectedDate: tempDate,
                    lastDate: DateTime.now(),
                    onDateSelected: (date) {
                      setDialogState(() => tempDate = date);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    "CANCEL",
                    style: TextStyle(
                      color: AppColor.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    selectedAuditDate = tempDate;
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.appColor1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "GENERATE REPORT",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldGenerate != true) return;

    int currentProgress = 0;
    int totalCount = departmentUsers.length;
    StateSetter? updateDialog;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          updateDialog = setDialogState;

          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoActivityIndicator(
                  radius: 7.r,
                  color: AppColor.appColor1,
                ),
                3.height,
                Text(
                  "Preparing Report...",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 4.sp),
                ),

                1.5.height,

                Text(
                  "Collecting attendance, visits, orders and activity logs for $currentProgress / $totalCount sales employees.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColor.grey, fontSize: 3.sp),
                ),

                2.height,

                LinearProgressIndicator(
                  value: totalCount == 0 ? 0 : currentProgress / totalCount,
                  backgroundColor: AppColor.scaffold,
                  color: AppColor.appColor2,
                  borderRadius: BorderRadius.circular(20),
                  minHeight: 7,
                ),
              ],
            ),
          );
        },
      ),
    );

    try {
      final List<EmployesWorkingDetailModel> reports = [];

      for (int i = 0; i < departmentUsers.length; i++) {
        final r = await controller.fetchMasterAuditData(
          context,
          [departmentUsers[i]],
          selectedAuditDate,
          (p, t) {},
        );

        reports.add(r.first);

        if (updateDialog != null) {
          updateDialog!(() {
            currentProgress = i + 1;
          });
        }
      }

      // Fetch External Report for the same date
      await controller.fetchExternalReport(context, date: selectedAuditDate);

      if (Navigator.canPop(context)) Navigator.pop(context);

      final bytes = await PdfReportGenerator.generateDailyMasterReport(
        users: departmentUsers,
        reports: reports,
        date: selectedAuditDate,
        department: widget.department,
        externalReport: controller.externalReport,
      );

      final fileName =
          "Daily_Sales_Audit_${DateFormat('dd_MM_yy').format(selectedAuditDate)}.pdf";

      AppRoutes.push(PdfPreviewView(pdfBytes: bytes, fileName: fileName));
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);

      Utils.showSnackBar(context, "Error generating daily sales report: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffold,
      appBar: CustomAppBar(
        title: widget.department,
        actions: [
          if (widget.department.toLowerCase().contains("sales") ||
              widget.department.toLowerCase().contains("marketing"))
            IconButton(
              icon: Icon(Icons.assessment_rounded, color: AppColor.white),
              tooltip: "Generate Audit Report",
              onPressed: () {
                final controller = Provider.of<EmployesController>(
                  context,
                  listen: false,
                );
                final employees = controller.getEmployeesByDept(
                  widget.department,
                );
                _handleGenerateAuditReport(context, controller, employees);
              },
            ),
          2.width,
        ],
      ),
      body: Consumer<EmployesController>(
        builder: (context, controller, child) {
          final employees = controller.getEmployeesByDept(widget.department);

          if (employees.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_off_rounded,
                    size: 15.w,
                    color: AppColor.grey,
                  ),
                  2.height,
                  Text(
                    "No members found",
                    style: TextStyle(fontSize: 4.5.sp, color: AppColor.grey),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.all(6.w),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 4.w,
                    mainAxisSpacing: 4.w,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final user = employees[index];
                      return _buildEmployeeCard(context, user);
                    },
                    childCount: employees.length,
                  ),
                ),
              ),
              if (widget.department.toLowerCase().contains("sales") ||
                  widget.department.toLowerCase().contains("marketing"))
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(6.w, 0, 6.w, 6.w),
                    child: _buildExternalClientsCard(context),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExternalClientsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColor.appDarkColor, AppColor.appColor1],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColor.appColor1.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => AppRoutes.push(const ExternalOrdersView()),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: EdgeInsets.all(6.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 8.w,
                  ),
                ),
                4.width,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "EXTERNAL CLIENTS",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 4.5.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      0.5.height,
                      Text(
                        "View cross-channel orders & billing details",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 2.8.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white70,
                  size: 5.w,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(BuildContext context, User user) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 1.w, vertical: 2.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => AppRoutes.push(EmployeeDetailView(user: user)),
        borderRadius: BorderRadius.circular(6.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                margin: EdgeInsets.all(2.w),
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: AppColor.appLightColor.withValues(alpha: 0.35),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: CachedNetworkImage(
                    imageUrl: user.profilePic ?? "",
                    fit: BoxFit.fill,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: AppColor.grey.withValues(alpha: 0.15),
                      highlightColor: AppColor.grey.withValues(alpha: 0.05),
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: AppColor.appLightColor,
                      ),
                    ),
                    errorWidget: (context, url, error) => Center(
                      child: Icon(
                        Icons.person_rounded,
                        size: 18.h,
                        color: AppColor.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.userName ?? "N/A",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 3.8.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColor.appDarkColor,
                    ),
                  ),
                  0.6.height,
                  Row(
                    children: [
                      Icon(Icons.work, size: 3.w, color: AppColor.appColor2),
                      1.width,
                      Expanded(
                        child: Text(
                          user.designation ?? "N/A",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 3.sp,
                            color: AppColor.appDarkColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  .5.height,
                  Row(
                    children: [
                      Icon(Icons.badge, size: 3.w, color: AppColor.appColor2),
                      1.width,
                      Text(
                        "Emp Code: ",
                        style: TextStyle(
                          fontSize: 2.6.sp,
                          color: AppColor.grey,
                        ),
                      ),
                      Text(
                        user.empCode ?? "N/A",
                        style: TextStyle(
                          fontSize: 2.6.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColor.appColor1,
                        ),
                      ),
                    ],
                  ),
                  1.height,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
