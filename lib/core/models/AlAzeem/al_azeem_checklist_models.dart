import '../Sales/sales_common.dart';

/// Models for the Al-Azeem checklist admin APIs. Read-only.
///
/// Every response uses `{error, error_msg, data, summary?, meta?}`. Counts are
/// computed by the server, so the app only displays them.

/// Task totals for a window, a submission, or a checklist.
class ChecklistCounts {
  const ChecklistCounts({
    this.totalChecklists = 0,
    this.totalTasks = 0,
    this.completedTasks = 0,
    this.pendingTasks = 0,
  });

  final int totalChecklists;
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;

  /// Share of tasks completed, from 0 to 1.
  double get progress => totalTasks == 0 ? 0 : completedTasks / totalTasks;

  factory ChecklistCounts.fromJson(Map<String, dynamic> json) {
    return ChecklistCounts(
      totalChecklists: salesInt(json['total_checklists']),
      totalTasks: salesInt(json['total_tasks']),
      completedTasks: salesInt(json['completed_tasks']),
      pendingTasks: salesInt(json['pending_tasks']),
    );
  }
}

/// The employee a checklist belongs to.
class ChecklistUser {
  const ChecklistUser({
    required this.name,
    this.employeeCode,
    this.role,
  });

  final String name;
  final String? employeeCode;
  final String? role;

  factory ChecklistUser.fromJson(Map<String, dynamic> json) {
    return ChecklistUser(
      name: salesString(json['name']) ?? 'Unknown employee',
      employeeCode: salesString(json['employee_code']),
      role: salesString(json['role']),
    );
  }
}

/// One checklist submission in the listing.
class ChecklistSubmission {
  const ChecklistSubmission({
    required this.submissionId,
    required this.checklistName,
    required this.taskDate,
    required this.user,
    required this.submissionStatus,
    required this.counts,
  });

  final int submissionId;
  final String checklistName;

  /// Task date as `YYYY-MM-DD`.
  final String taskDate;
  final ChecklistUser user;
  final String submissionStatus;
  final ChecklistCounts counts;

  factory ChecklistSubmission.fromJson(Map<String, dynamic> json) {
    return ChecklistSubmission(
      submissionId: salesInt(json['submission_id']),
      checklistName: salesString(json['checklist_name']) ?? 'Checklist',
      taskDate: salesString(json['task_date']) ?? '',
      user: ChecklistUser.fromJson(salesMap(json['user'])),
      submissionStatus: salesString(json['submission_status']) ?? '',
      counts: ChecklistCounts.fromJson(json),
    );
  }
}

/// One page of the submission listing. [summary] covers the whole filtered
/// set, not only this page.
class ChecklistPage {
  const ChecklistPage({
    required this.items,
    required this.summary,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<ChecklistSubmission> items;
  final ChecklistCounts summary;
  final int currentPage;
  final int lastPage;

  /// Number of submissions across all pages.
  final int total;

  bool get hasMore => currentPage < lastPage;

  factory ChecklistPage.fromEnvelope(Map<String, dynamic> body) {
    final rows = body['data'];
    final meta = salesMap(body['meta']);
    final current = salesInt(meta['current_page']);
    final last = salesInt(meta['last_page']);

    return ChecklistPage(
      items: rows is List
          ? [for (final row in rows) ChecklistSubmission.fromJson(salesMap(row))]
          : const [],
      summary: ChecklistCounts.fromJson(salesMap(body['summary'])),
      currentPage: current == 0 ? 1 : current,
      lastPage: last == 0 ? 1 : last,
      total: salesInt(meta['total']),
    );
  }
}

/// One task of a submission, with its section, completion and evidence.
class ChecklistDetailTask {
  const ChecklistDetailTask({
    required this.task,
    required this.isDone,
    this.sectionTitle,
    this.timeLabel,
    this.evidence = const [],
    this.note,
    this.completedAt,
  });

  final String task;
  final bool isDone;
  final String? sectionTitle;
  final String? timeLabel;
  final List<String> evidence;
  final String? note;
  final String? completedAt;

  factory ChecklistDetailTask.fromJson(Map<String, dynamic> json) {
    final section = salesMap(json['section']);
    final rawEvidence = json['evidence'];

    return ChecklistDetailTask(
      task: salesString(json['task']) ?? 'Task',
      isDone: _flag(json['is_done']),
      sectionTitle: salesString(section['title']),
      timeLabel: salesString(json['time_label']),
      evidence: rawEvidence is List
          ? [
              for (final item in rawEvidence)
                if (salesString(item) != null) salesString(item)!,
            ]
          : const [],
      note: salesString(json['note']),
      completedAt: salesString(json['completed_at']),
    );
  }
}

/// A full checklist submission with every task.
class ChecklistDetail {
  const ChecklistDetail({
    required this.checklistName,
    required this.taskDate,
    required this.submissionStatus,
    required this.user,
    required this.counts,
    required this.tasks,
    this.submittedAt,
    this.reportsTo,
    this.staffNote,
    this.workImagePath,
    this.selfImagePath,
  });

  final String checklistName;
  final String taskDate;
  final String submissionStatus;
  final String? submittedAt;
  final ChecklistUser user;
  final String? reportsTo;
  final String? staffNote;

  /// Stored image path. The app shows only whether a photo exists.
  final String? workImagePath;
  final String? selfImagePath;
  final ChecklistCounts counts;
  final List<ChecklistDetailTask> tasks;

  factory ChecklistDetail.fromJson(Map<String, dynamic> json) {
    final rawTasks = json['tasks'];

    return ChecklistDetail(
      checklistName: salesString(json['checklist_name']) ?? 'Checklist',
      taskDate: salesString(json['task_date']) ?? '',
      submissionStatus: salesString(json['submission_status']) ?? '',
      submittedAt: salesString(json['submitted_at']),
      user: ChecklistUser.fromJson(salesMap(json['user'])),
      reportsTo: salesString(json['reports_to']),
      staffNote: salesString(json['staff_note']),
      workImagePath: salesString(json['work_image_path']),
      selfImagePath: salesString(json['self_image_path']),
      counts: ChecklistCounts.fromJson(json),
      tasks: rawTasks is List
          ? [for (final t in rawTasks) ChecklistDetailTask.fromJson(salesMap(t))]
          : const [],
    );
  }
}

/// The API sends booleans as `true`/`false` or as `1`/`0`.
bool _flag(dynamic value) =>
    value == true || value == 1 || value == '1' || value == 'true';
