import 'package:flutter/material.dart';

import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/models/AlAzeem/al_azeem_checklist_models.dart';
import 'package:beacon/core/network/al_azeem_checklist_api.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/ui/components/site_widgets.dart';
import 'package:beacon/ui/view/dashboard/al_azeem/checklist_widgets.dart';

/// One checklist submission: the employee, progress, photos, and every task
/// grouped by section.
class ChecklistDetailView extends StatefulWidget {
  const ChecklistDetailView({
    super.key,
    required this.submissionId,
    required this.accentColor,
  });

  final int submissionId;
  final Color accentColor;

  @override
  State<ChecklistDetailView> createState() => _ChecklistDetailViewState();
}

class _ChecklistDetailViewState extends State<ChecklistDetailView> {
  late Future<ChecklistDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<ChecklistDetail> _load() =>
      AlAzeemChecklistApi.detail(widget.submissionId);

  void _retry() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffold,
      appBar: CustomAppBar(title: "Checklist"),
      body: FutureBuilder<ChecklistDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return AppLoadingView(color: widget.accentColor);
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            return AppErrorView(
              icon: Icons.cloud_off_rounded,
              message: error is AlAzeemChecklistApiException
                  ? error.message
                  : "Could not load this checklist.",
              onRetry: _retry,
            );
          }
          return _DetailBody(
            detail: snapshot.requireData,
            accent: widget.accentColor,
          );
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail, required this.accent});

  final ChecklistDetail detail;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final d = detail;

    // Tasks keep the server order. Consecutive tasks with the same section
    // form one group.
    final groups = <String, List<ChecklistDetailTask>>{};
    for (final task in d.tasks) {
      groups.putIfAbsent(task.sectionTitle ?? "Tasks", () => []).add(task);
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 4.h),
      children: [
        ChecklistCard(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                d.checklistName,
                style: TextStyle(
                  fontSize: 4.4.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.appDarkColor,
                ),
              ),
              1.2.height,
              Wrap(
                spacing: 2.w,
                runSpacing: 1.h,
                children: [
                  ChecklistPill(
                    label: checklistStatusLabel(d.submissionStatus),
                    color: checklistStatusColor(d.submissionStatus),
                  ),
                  ChecklistPill(
                    label: checklistDateText(d.taskDate),
                    color: AppColor.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
        2.height,
        ChecklistCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeading("Employee"),
              ChecklistInfoRow(label: "Name", value: d.user.name),
              ChecklistInfoRow(
                label: "Employee code",
                value: d.user.employeeCode ?? "—",
              ),
              ChecklistInfoRow(
                label: "Role",
                value: checklistRoleLabel(d.user.role),
              ),
              ChecklistInfoRow(
                label: "Reports to",
                value: d.reportsTo ?? "—",
              ),
            ],
          ),
        ),
        2.height,
        ChecklistCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeading("Progress"),
              Text(
                "${d.counts.completedTasks} of ${d.counts.totalTasks} tasks done",
                style: TextStyle(
                  fontSize: 3.6.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColor.appDarkColor,
                ),
              ),
              1.height,
              ChecklistProgressBar(value: d.counts.progress, color: accent),
              2.height,
              ChecklistInfoRow(
                label: "Submitted",
                value: d.submittedAt == null
                    ? "Not submitted yet"
                    : checklistDateTimeText(d.submittedAt),
              ),
              if (d.staffNote != null)
                ChecklistInfoRow(label: "Staff note", value: d.staffNote!),
              ChecklistInfoRow(
                label: "Work photo",
                value: d.workImagePath == null ? "Not uploaded" : "Uploaded",
              ),
              ChecklistInfoRow(
                label: "Self photo",
                value: d.selfImagePath == null ? "Not uploaded" : "Uploaded",
              ),
            ],
          ),
        ),
        for (final entry in groups.entries) ...[
          2.5.height,
          Padding(
            padding: EdgeInsets.only(left: 1.w, bottom: 1.2.h),
            child: Text(
              entry.key.toUpperCase(),
              style: TextStyle(
                fontSize: 2.8.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: AppColor.grey,
              ),
            ),
          ),
          for (final task in entry.value)
            Padding(
              padding: EdgeInsets.only(bottom: 1.h),
              child: _TaskTile(task: task, accent: accent),
            ),
        ],
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.2.h),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 4.sp,
          fontWeight: FontWeight.bold,
          color: AppColor.appDarkColor,
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task, required this.accent});

  final ChecklistDetailTask task;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ChecklistCard(
      padding: EdgeInsets.all(3.5.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            task.isDone
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: task.isDone ? AppColor.green : AppColor.grey,
            size: 5.5.w,
          ),
          3.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.task,
                  style: TextStyle(
                    fontSize: 3.4.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColor.appDarkColor,
                  ),
                ),
                if (task.timeLabel != null) ...[
                  0.3.height,
                  Text(
                    task.timeLabel!,
                    style: TextStyle(fontSize: 2.8.sp, color: AppColor.grey),
                  ),
                ],
                if (task.isDone && task.completedAt != null) ...[
                  0.3.height,
                  Text(
                    "Done ${checklistDateTimeText(task.completedAt)}",
                    style: TextStyle(fontSize: 2.8.sp, color: AppColor.grey),
                  ),
                ],
                if (task.note != null) ...[
                  0.6.height,
                  Text(
                    "Note: ${task.note}",
                    style: TextStyle(
                      fontSize: 3.sp,
                      color: AppColor.darkGrey,
                    ),
                  ),
                ],
                if (task.evidence.isNotEmpty) ...[
                  0.8.height,
                  Wrap(
                    spacing: 1.5.w,
                    runSpacing: 0.8.h,
                    children: [
                      for (final item in task.evidence)
                        ChecklistPill(
                          label: checklistTitleCase(item),
                          color: accent,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
