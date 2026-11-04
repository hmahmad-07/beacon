// ignore_for_file: use_build_context_synchronously

import 'package:beacon/core/extensions/routes.dart';
import 'package:beacon/core/models/Employees/employes_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:beacon/core/controllers/employes_controller.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/ui/components/site_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'package:beacon/core/models/Employees/emp_working_detail_model.dart';
import 'package:beacon/core/utils/pdf_report_generator.dart';
import 'package:beacon/core/utils/utils.dart';
import 'package:beacon/ui/components/custom_date_picker.dart';
import 'package:beacon/ui/view/dashboard/employees/pdf_preview_view.dart';
import 'employee_detail_view.dart';
import 'package:intl/intl.dart';
import 'external_orders_view.dart';

class EmployeeListView extends StatefulWidget {
  final String department;
  final int? departmentId;
  final String? shopId;
  final String? shopName;
  final String? siteImage;

  const EmployeeListView({
    super.key,
    required this.department,
    this.departmentId,
    this.shopId,
    this.shopName,
    this.siteImage,
  });

  @override
  State<EmployeeListView> createState() => _EmployeeListViewState();
}

class _EmployeeListViewState extends State<EmployeeListView> {
  DateTime selectedAuditDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<EmployesController>();
      final targetId =
          widget.departmentId ??
          controller.getDepartmentIdByName(widget.department);
      if (targetId != null) {
        controller.fetchDepartmentEmployees(targetId, context, widget.shopId);
      }
    });
  }

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
    bool isFinalizing = false;
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
                const AppLoadingView(label: "Preparing Report..."),

                1.5.height,

                Text(
                  isFinalizing
                      ? "Finalizing report and resolving visit addresses..."
                      : "Collecting attendance, visits, orders and activity logs for $currentProgress / $totalCount sales employees.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColor.grey, fontSize: 3.sp),
                ),

                2.height,

                LinearProgressIndicator(
                  value: isFinalizing
                      ? null
                      : (totalCount == 0 ? 0 : currentProgress / totalCount),
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

      await controller.fetchExternalReport(context, date: selectedAuditDate);

      if (updateDialog != null) {
        updateDialog!(() {
          isFinalizing = true;
        });
      }

      final bytes = await PdfReportGenerator.generateDailyMasterReport(
        users: departmentUsers,
        reports: reports,
        date: selectedAuditDate,
        department: widget.department,
        externalReport: controller.externalReport,
      );

      if (Navigator.canPop(context)) Navigator.pop(context);

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
          if (widget.department.toLowerCase().contains("sales"))
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
                  shopId: widget.shopId,
                );
                _handleGenerateAuditReport(context, controller, employees);
              },
            ),
          2.width,
        ],
      ),
      body: Consumer<EmployesController>(
        builder: (context, controller, child) {
          if (controller.isDeptEmployeesLoading) {
            return const AppLoadingView();
          }

          final employees = controller.getEmployeesByDept(
            widget.department,
            shopId: widget.shopId,
          );

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
              if (widget.department.toLowerCase().contains("sales"))
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(6.w, 4.w, 6.w, 0.w),
                    child: _buildExternalClientsCard(context),
                  ),
                ),
              SliverPadding(
                padding: EdgeInsets.all(6.w),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 4.w,
                    mainAxisSpacing: 4.w,
                    childAspectRatio: 0.58,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final user = employees[index];
                    return AnimationConfiguration.staggeredGrid(
                      position: index,
                      columnCount: 2,
                      duration: const Duration(milliseconds: 400),
                      child: SlideAnimation(
                        verticalOffset: 50,
                        child: FadeInAnimation(
                          child: _buildEmployeeCard(context, user),
                        ),
                      ),
                    );
                  }, childCount: employees.length),
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
                          fontWeight: FontWeight.bold,
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
    final bool hasMobile =
        user.mobile != null && user.mobile!.trim().isNotEmpty;
    final bool hasShop =
        user.shopName != null && user.shopName!.trim().isNotEmpty;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 1.w, vertical: 1.5.w),
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
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    margin: EdgeInsets.all(2.w),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: AppColor.appLightColor.withValues(alpha: 0.35),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: user.profilePic ?? "",
                        fit: BoxFit.fill,
                        placeholder: (context, url) => Center(child: CupertinoActivityIndicator(radius: 8, color: AppColor.grey)),
                        errorWidget: (context, url, error) => Center(
                          child: Icon(
                            Icons.person_rounded,
                            color: AppColor.grey,
                            size: 10.w,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (user.gender != null && user.gender!.trim().isNotEmpty)
                    Positioned(
                      top: 3.w,
                      right: 3.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.5.w,
                        ),
                        decoration: BoxDecoration(
                          color: AppColor.appDarkColor.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          user.gender == 'M'
                              ? 'Male'
                              : (user.gender == 'F' ? 'Female' : user.gender!),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 2.4.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
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
                  0.4.height,
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
                            fontSize: 2.8.sp,
                            color: AppColor.appDarkColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  0.3.height,
                  Row(
                    children: [
                      Icon(Icons.badge, size: 3.w, color: AppColor.appColor2),
                      1.width,
                      Text(
                        "Code: ",
                        style: TextStyle(
                          fontSize: 2.5.sp,
                          color: AppColor.grey,
                        ),
                      ),
                      Text(
                        user.empCode ?? "N/A",
                        style: TextStyle(
                          fontSize: 2.5.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColor.appColor1,
                        ),
                      ),
                    ],
                  ),
                  if (hasShop) ...[
                    0.3.height,
                    Row(
                      children: [
                        Icon(
                          Icons.storefront_rounded,
                          size: 3.w,
                          color: AppColor.appColor2,
                        ),
                        1.width,
                        Expanded(
                          child: Text(
                            user.shopName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 2.5.sp,
                              color: AppColor.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (hasMobile) ...[
                    0.3.height,
                    Row(
                      children: [
                        Icon(
                          Icons.phone_rounded,
                          size: 3.w,
                          color: AppColor.green,
                        ),
                        1.width,
                        Expanded(
                          child: Text(
                            user.mobile!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 2.5.sp,
                              color: AppColor.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  0.5.height,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
