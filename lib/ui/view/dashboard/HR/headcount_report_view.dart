import 'package:beacon/core/controllers/hr_controller.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/models/HR/department_headcount_model.dart';
import 'package:beacon/core/models/HR/employee_salary_type_model.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/ui/components/app_constants.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/ui/components/custom_month_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:beacon/ui/components/site_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:iconsx_plus/iconsx_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class HeadcountReportView extends StatefulWidget {
  const HeadcountReportView({
    super.key,
    required this.siteName,
    required this.siteID,
    required this.deptName,
    required this.deptID,
    this.siteImage,
  });

  final String siteName;
  final String siteID;
  final String deptName;
  final int deptID;
  final String? siteImage;

  @override
  State<HeadcountReportView> createState() => _HeadcountReportViewState();
}

class _HeadcountReportViewState extends State<HeadcountReportView>
    with SingleTickerProviderStateMixin {
  Color get _accent => AppColor.appColor1;

  AnimationController? _chartAnimController;
  Animation<double>? _chartAnim;
  String? _animationKey;

  Animation<double> get _safeChartAnim =>
      _chartAnim ?? const AlwaysStoppedAnimation<double>(1);

  @override
  void initState() {
    super.initState();
    _chartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _chartAnim = CurvedAnimation(
      parent: _chartAnimController!,
      curve: Curves.easeOutCubic,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchReportData());
  }

  @override
  void dispose() {
    _chartAnimController?.dispose();
    super.dispose();
  }

  void _triggerChartAnimation(String key) {
    if (_animationKey == key) return;
    _animationKey = key;
    _chartAnimController?.reset();
    _chartAnimController?.forward();
  }

  void _fetchReportData() {
    _animationKey = null;
    final hrController = context.read<HRController>();
    final month = DateFormat('MM').format(hrController.headcountSelectedDate);
    final year = DateFormat('yyyy').format(hrController.headcountSelectedDate);

    hrController.getHeadcountReport(
      context,
      month: month,
      year: year,
      shopId: widget.siteID,
      deptId: widget.deptID.toString(),
    );
    // Headcount alone doesn't say who makes it up — pull the roster from
    // the Employment Type report so this screen can show it too.
    hrController.getEmpSalaryTypeReport(
      context,
      month: month,
      year: year,
      shopId: widget.siteID,
      deptId: widget.deptID.toString(),
    );
  }

  List<HeadcountTableRow> _rows(DepartmentHeadcountModel? model) {
    return model?.data?.tableData ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffold,
      appBar: CustomAppBar(
        title: "Headcount Report",
        actions: [
          IconButton(
            icon: Icon(BoxIcons.bx_refresh, color: AppColor.white),
            tooltip: "Refresh Data",
            onPressed: _fetchReportData,
          ),
        ],
      ),
      body: Consumer<HRController>(
        builder: (context, controller, child) {
          final model = controller.headcountReportModel;
          final isLoading = controller.isHeadcountReportLoading;
          final rows = _rows(model);
          final employees =
              controller.salaryTypeReportModel?.departmentEmployees ?? [];

          if (!isLoading && rows.isNotEmpty) {
            final key =
                '${controller.headcountSelectedDate.millisecondsSinceEpoch}_'
                '${rows.length}';
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _triggerChartAnimation(key);
            });
          }

          return RefreshIndicator(
            color: _accent,
            onRefresh: () async => _fetchReportData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderBanner(controller),
                  if (isLoading)
                    const AppLoadingView()
                  else if (rows.isEmpty)
                    _buildEmptyState(controller)
                  else ...[
                    _buildMetricsRow(rows, employees.length),
                    if (employees.isNotEmpty) _buildNatureChart(employees),
                    if (employees.isNotEmpty) _buildEmployeeList(employees),
                    4.height,
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderBanner(HRController controller) {
    final formattedMonth = DateFormat(
      'MMMM yyyy',
    ).format(controller.headcountSelectedDate);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 1.5.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColor.appColor1, AppColor.appDarkColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadow.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12.w,
                height: 12.w,
                padding: EdgeInsets.all(1.5.w),
                decoration: BoxDecoration(
                  color: AppColor.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: widget.siteImage != null && widget.siteImage!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12.w),
                        child: Image.asset(
                          widget.siteImage!,
                          fit: BoxFit.contain,
                        ),
                      )
                    : Icon(
                        BoxIcons.bxs_group,
                        color: AppColor.white,
                        size: 6.w,
                      ),
              ),
              3.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.siteName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColor.white,
                        fontSize: 4.5.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    0.4.height,
                    Text(
                      widget.deptName,
                      style: TextStyle(
                        color: AppColor.white.withValues(alpha: 0.85),
                        fontSize: 3.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          2.height,
          InkWell(
            onTap: () async {
              await CustomMonthPicker.showMonthPickerDialog(
                context: context,
                selectedMonth: controller.headcountSelectedDate,
                onMonthSelected: (date) {
                  controller.setHeadcountSelectedDate(date);
                  _fetchReportData();
                },
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.2.h),
              decoration: BoxDecoration(
                color: AppColor.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColor.white.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        BoxIcons.bx_calendar,
                        color: AppColor.white,
                        size: 4.5.w,
                      ),
                      2.width,
                      Text(
                        "Month: $formattedMonth",
                        style: TextStyle(
                          color: AppColor.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 3.5.sp,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.4.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColor.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "CHANGE",
                      style: TextStyle(
                        color: AppColor.appDarkColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 2.6.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(List<HeadcountTableRow> rows, int rosterCount) {
    final activeHeadcount = rows.fold<int>(
      0,
      (sum, r) => sum + (r.headcount ?? 0),
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
      child: Row(
        children: [
          Expanded(
            child: _metricCard(
              "Active Headcount",
              activeHeadcount,
              BoxIcons.bxs_group,
              _accent,
            ),
          ),
          2.5.width,
          Expanded(
            child: _metricCard(
              "Departments",
              rows.length,
              BoxIcons.bxs_buildings,
              const Color(0xFF1F2A37),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(String title, int value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 4.5.w),
          ),
          1.height,
          AnimatedBuilder(
            animation: _safeChartAnim,
            builder: (context, child) {
              final animated = (value * _safeChartAnim.value).round();
              return Text(
                "$animated",
                style: TextStyle(
                  fontSize: 3.8.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.appDarkColor,
                ),
              );
            },
          ),
          0.3.height,
          Text(
            title,
            style: TextStyle(
              fontSize: 2.4.sp,
              color: AppColor.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _colorForJobType(String key) {
    final t = key.toUpperCase();
    if (t.contains("PERMANENT")) return const Color(0xFFB8922A);
    if (t.contains("CONTRACT")) return const Color(0xFF696D75);
    if (t.contains("DAILY") || t.contains("WAGE")) {
      return const Color(0xFF1F2A37);
    }
    if (t.contains("TEMP")) return const Color(0xFFD9B65E);
    return _accent;
  }

  String _formatJobType(String key) {
    if (key.trim().isEmpty) return "Unspecified";
    return key
        .split(RegExp(r'[_\s]+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  // A donut of the roster's employment nature is more useful than a bar
  // of "headcount by department" — the department filter usually narrows
  // this report to a single department anyway, which a bar chart can't
  // say much about.
  // A radar of the roster's employment nature — a chart type not used
  // anywhere else in the app, and a natural fit for "shape" of a handful
  // of comparable counts (unlike a bar chart, which is trivial here since
  // the department filter usually narrows this report to one department).
  Widget _buildNatureChart(List<DepartmentEmployee> employees) {
    final tally = <String, int>{};
    for (final e in employees) {
      final raw = (e.jobType ?? '').trim();
      final key = raw.isEmpty ? 'UNSPECIFIED' : raw.toUpperCase();
      tally[key] = (tally[key] ?? 0) + 1;
    }
    if (tally.isEmpty) return const SizedBox.shrink();
    if (tally.length < 3) {
      // RadarChart needs at least 3 axes to read as a shape; fall back to
      // simple stat rows for 1-2 job types.
      return _buildNatureFallback(tally);
    }

    final entries = tally.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColor.appLightColor.withValues(alpha: 0.7),
        ),
        boxShadow: AppShadow.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(1.8.w),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(BoxIcons.bxs_shapes, color: _accent, size: 4.5.w),
              ),
              2.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Headcount by Employment Nature",
                      style: TextStyle(
                        fontSize: 3.5.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColor.appDarkColor,
                      ),
                    ),
                    Text(
                      "Roster shape for this department",
                      style: TextStyle(fontSize: 2.2.sp, color: AppColor.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          1.5.height,
          SizedBox(
            height: (28.h).clamp(240.0, 300.0),
            child: AnimatedBuilder(
              animation: _safeChartAnim,
              builder: (context, child) {
                final anim = _safeChartAnim.value.clamp(0.0, 1.0);
                // RadarChart auto-scales its axes to the data's own max,
                // so animating the raw values wouldn't visibly grow the
                // shape (the axis would just shrink to match). Grow + fade
                // the whole chart in instead.
                return Opacity(
                  opacity: anim,
                  child: Transform.scale(
                    scale: 0.6 + 0.4 * anim,
                    child: RadarChart(
                      RadarChartData(
                        radarShape: RadarShape.polygon,
                        radarBackgroundColor: _accent.withValues(alpha: 0.06),
                        radarBorderData: BorderSide(
                          color: AppColor.appLightColor,
                        ),
                        gridBorderData: BorderSide(
                          color: AppColor.appLightColor.withValues(alpha: 0.6),
                        ),
                        tickBorderData: const BorderSide(
                          color: Colors.transparent,
                        ),
                        ticksTextStyle: const TextStyle(
                          color: Colors.transparent,
                          fontSize: 0,
                        ),
                        tickCount: 4,
                        titlePositionPercentageOffset: 0.16,
                        getTitle: (index, angle) {
                          if (index < 0 || index >= entries.length) {
                            return const RadarChartTitle(text: '');
                          }
                          return RadarChartTitle(
                            text: _formatJobType(entries[index].key),
                            angle: angle,
                          );
                        },
                        titleTextStyle: TextStyle(
                          fontSize: 2.3.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColor.appDarkColor,
                        ),
                        dataSets: [
                          RadarDataSet(
                            fillColor: _accent.withValues(alpha: 0.25),
                            borderColor: _accent,
                            borderWidth: 2,
                            entryRadius: 3,
                            dataEntries: entries
                                .map(
                                  (e) => RadarEntry(value: e.value.toDouble()),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                      duration: Duration.zero,
                    ),
                  ),
                );
              },
            ),
          ),
          1.height,
          Wrap(
            spacing: 3.w,
            runSpacing: 0.8.h,
            children: entries.map((e) {
              final color = _colorForJobType(e.key);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 2.5.w,
                    height: 2.5.w,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  1.5.width,
                  Text(
                    '${_formatJobType(e.key)} (${e.value})',
                    style: TextStyle(
                      fontSize: 2.4.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColor.appDarkColor,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNatureFallback(Map<String, int> tally) {
    final entries = tally.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColor.appLightColor.withValues(alpha: 0.7),
        ),
        boxShadow: AppShadow.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Headcount by Employment Nature",
            style: TextStyle(
              fontSize: 3.5.sp,
              fontWeight: FontWeight.bold,
              color: AppColor.appDarkColor,
            ),
          ),
          1.height,
          ...entries.map((e) {
            final color = _colorForJobType(e.key);
            return Padding(
              padding: EdgeInsets.only(bottom: 0.8.h),
              child: Row(
                children: [
                  Container(
                    width: 2.5.w,
                    height: 2.5.w,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  2.width,
                  Expanded(
                    child: Text(
                      _formatJobType(e.key),
                      style: TextStyle(
                        fontSize: 2.8.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColor.appDarkColor,
                      ),
                    ),
                  ),
                  Text(
                    '${e.value}',
                    style: TextStyle(
                      fontSize: 2.8.sp,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmployeeList(List<DepartmentEmployee> employees) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 5.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(1.8.w),
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      BoxIcons.bxs_user_detail,
                      color: _accent,
                      size: 4.w,
                    ),
                  ),
                  2.width,
                  Text(
                    "Active Roster",
                    style: TextStyle(
                      fontSize: 4.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColor.appDarkColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 2.5.w,
                  vertical: 0.4.h,
                ),
                decoration: BoxDecoration(
                  color: AppColor.grey.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  "${employees.length} staff",
                  style: TextStyle(
                    fontSize: 2.8.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.appDarkColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        1.5.height,
        AnimationLimiter(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 5.w),
            itemCount: employees.length,
            separatorBuilder: (_, _) => 1.5.height,
            itemBuilder: (context, index) {
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 400),
                child: SlideAnimation(
                  verticalOffset: 40,
                  child: FadeInAnimation(child: _rosterCard(employees[index])),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _rosterCard(DepartmentEmployee emp) {
    final isActive = emp.status?.toUpperCase() == "A";
    final statusColor = isActive ? AppColor.green : AppColor.red;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColor.appLightColor.withValues(alpha: 0.6),
        ),
        boxShadow: AppShadow.soft,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 1.1.w, color: statusColor),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(3.5.w),
                child: Row(
                  children: [
                    Container(
                      width: 12.w,
                      height: 12.w,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            statusColor.withValues(alpha: 0.35),
                            statusColor.withValues(alpha: 0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child:
                            emp.profilePic != null && emp.profilePic!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: emp.profilePic!,
                                fit: BoxFit.cover,
                                placeholder: (c, u) => Center(child: CupertinoActivityIndicator(radius: 8, color: AppColor.grey)),
                                errorWidget: (c, u, e) => _avatarFallback(emp),
                              )
                            : _avatarFallback(emp),
                      ),
                    ),
                    3.width,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            emp.name ?? "Unknown Employee",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 3.6.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColor.appDarkColor,
                            ),
                          ),
                          0.3.height,
                          Text(
                            emp.designation ?? "Employee",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 2.7.sp,
                              color: AppColor.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (emp.jobType != null && emp.jobType!.trim().isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.5.w,
                          vertical: 0.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _accent.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          emp.jobType!,
                          style: TextStyle(
                            fontSize: 2.2.sp,
                            fontWeight: FontWeight.bold,
                            color: _accent,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback(DepartmentEmployee emp) {
    final initials = emp.name != null && emp.name!.trim().isNotEmpty
        ? emp.name!.trim().split(" ").take(2).map((e) => e[0]).join()
        : "?";
    return Container(
      color: _accent.withValues(alpha: 0.1),
      alignment: Alignment.center,
      child: Text(
        initials.toUpperCase(),
        style: TextStyle(
          color: _accent,
          fontWeight: FontWeight.bold,
          fontSize: 3.5.sp,
        ),
      ),
    );
  }

  Widget _buildEmptyState(HRController controller) {
    return Container(
      margin: EdgeInsets.all(5.w),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadow.soft,
      ),
      child: Column(
        children: [
          Icon(BoxIcons.bxs_group, size: 12.w, color: _accent),
          2.height,
          Text(
            "No Headcount Data",
            style: TextStyle(
              fontSize: 4.5.sp,
              fontWeight: FontWeight.bold,
              color: AppColor.appDarkColor,
            ),
          ),
          1.height,
          Text(
            "No headcount found for ${widget.deptName} in ${DateFormat('MMMM yyyy').format(controller.headcountSelectedDate)}.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 3.2.sp, color: AppColor.grey),
          ),
          3.height,
          ElevatedButton.icon(
            onPressed: _fetchReportData,
            icon: Icon(BoxIcons.bx_refresh, color: AppColor.white),
            label: Text(
              "Reload Report",
              style: TextStyle(
                color: AppColor.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.2.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
