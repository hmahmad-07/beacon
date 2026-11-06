// ignore_for_file: use_build_context_synchronously

import 'package:beacon/core/models/Employees/employes_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:beacon/core/controllers/employes_controller.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/ui/components/site_design.dart';
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

/// Employees of one department of one site, in that site's colour.
class EmployeeListView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SiteScope.wrap(
      accent: siteAccentForShop(shopId),
      child: _EmployeeListBody(
        department: department,
        departmentId: departmentId,
        shopId: shopId,
        shopName: shopName,
        siteImage: siteImage ?? siteAssetForShop(shopId),
      ),
    );
  }
}

class _EmployeeListBody extends StatefulWidget {
  final String department;
  final int? departmentId;
  final String? shopId;
  final String? shopName;
  final String? siteImage;

  const _EmployeeListBody({
    required this.department,
    this.departmentId,
    this.shopId,
    this.shopName,
    this.siteImage,
  });

  @override
  State<_EmployeeListBody> createState() => _EmployeeListViewState();
}

class _EmployeeListViewState extends State<_EmployeeListBody> {
  bool get _isSales => widget.department.toLowerCase().contains("sales");

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
                  Icon(Icons.analytics_rounded, color: context.siteAccent),
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
                    backgroundColor: context.siteAccent,
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
                const SiteLoading(label: "Preparing Report..."),

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
                  color: context.siteAccent,
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

      context.pushSite(PdfPreviewView(pdfBytes: bytes, fileName: fileName));
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);

      Utils.showSnackBar(context, "Error generating daily sales report: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.siteAccent;

    return Scaffold(
      backgroundColor: AppColor.scaffold,
      appBar: CustomAppBar(
        title: widget.department,
        actions: [
          if (_isSales)
            IconButton(
              icon: Icon(Icons.assessment_rounded, color: accent),
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
            return const SiteLoading(label: "Loading team…");
          }

          final employees = controller.getEmployeesByDept(
            widget.department,
            shopId: widget.shopId,
          );

          return AnimationLimiter(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: siteStagger(
                    0,
                    SiteHeaderCard(
                      title: widget.department,
                      subtitle: widget.shopName,
                      description: employees.isEmpty
                          ? "No active members"
                          : "Active team members of this department",
                      logoAsset: widget.siteImage,
                      icon: Icons.groups_rounded,
                      badge:
                          "${employees.length} ${employees.length == 1 ? 'member' : 'members'}",
                    ),
                  ),
                ),
                if (_isSales)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 0),
                      child: siteStagger(1, _buildExternalClientsCard(context)),
                    ),
                  ),
                if (employees.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: SiteEmptyState(
                      icon: Icons.person_off_rounded,
                      title: "No members found",
                      message:
                          "There are no active employees in this department yet.",
                    ),
                  )
                else ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(5.w, 2.5.h, 5.w, 0),
                      child: siteStagger(
                        2,
                        SiteSectionTitle(
                          "Team members",
                          count: employees.length,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(5.w, 0, 5.w, 4.h),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 3.5.w,
                        mainAxisSpacing: 3.5.w,
                        childAspectRatio: 0.72,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final user = employees[index];
                        return siteStaggerGrid(
                          index,
                          2,
                          _buildEmployeeCard(context, user),
                        );
                      }, childCount: employees.length),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExternalClientsCard(BuildContext context) {
    return SiteBanner(
      onTap: () => context.pushSite(const ExternalOrdersView()),
      eyebrow: "Order booking",
      title: "External Clients",
      subtitle: "Cross-channel orders & billing details",
      titleSize: 4.8.sp,
      leading: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.storefront_rounded, color: Colors.white, size: 7.w),
      ),
      trailing: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_forward_ios_rounded,
          color: Colors.white,
          size: 3.6.w,
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(BuildContext context, User user) {
    final accent = context.siteAccent;
    final bool hasMobile =
        user.mobile != null && user.mobile!.trim().isNotEmpty;
    final name = user.userName ?? "N/A";
    final gender = user.gender?.trim() ?? "";
    final photo = user.profilePic?.trim() ?? "";

    final fallback = Center(
      child: SiteAvatar(name: name, size: 20.w),
    );

    return SiteCard(
      onTap: () => context.pushSite(EmployeeDetailView(user: user)),
      padding: EdgeInsets.all(2.2.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          accent.withValues(alpha: 0.06),
                          accent.withValues(alpha: 0.14),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: photo.isEmpty
                          ? fallback
                          : CachedNetworkImage(
                              imageUrl: photo,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Center(
                                child: CupertinoActivityIndicator(
                                  radius: 8,
                                  color: accent,
                                ),
                              ),
                              errorWidget: (context, url, error) => fallback,
                            ),
                    ),
                  ),
                ),
                if (gender.isNotEmpty)
                  Positioned(
                    top: 2.w,
                    right: 2.w,
                    child: SitePill(
                      gender == 'M'
                          ? 'Male'
                          : (gender == 'F' ? 'Female' : gender),
                      bg: Colors.white.withValues(alpha: 0.92),
                      fg: accent,
                      fontSize: 2.4.sp,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(1.5.w, 1.2.h, 1.5.w, 0.6.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 3.8.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColor.appDarkColor,
                  ),
                ),
                0.5.height,
                Row(
                  children: [
                    Icon(Icons.work_rounded, size: 3.2.w, color: accent),
                    1.2.width,
                    Expanded(
                      child: Text(
                        user.designation ?? "N/A",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 2.9.sp,
                          color: AppColor.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                0.4.height,
                Row(
                  children: [
                    Icon(
                      Icons.phone_rounded,
                      size: 3.2.w,
                      color: hasMobile ? AppColor.green : AppColor.grey,
                    ),
                    1.2.width,
                    Expanded(
                      child: Text(
                        hasMobile ? user.mobile! : "No number",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 2.8.sp,
                          color: hasMobile ? AppColor.green : AppColor.grey,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
