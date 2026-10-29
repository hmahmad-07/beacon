import 'package:flutter/material.dart';

import 'package:beacon/core/controllers/al_azeem_checklist_controller.dart';
import 'package:beacon/core/controllers/al_azeem_checklist_period_controller.dart';
import 'package:beacon/core/extensions/routes.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/models/AlAzeem/al_azeem_checklist_models.dart';
import 'package:beacon/core/models/Sales/sales_common.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/ui/components/site_widgets.dart';
import 'package:beacon/ui/view/dashboard/al_azeem/checklist_detail_view.dart';
import 'package:beacon/ui/view/dashboard/al_azeem/checklist_widgets.dart';
import 'package:beacon/ui/view/dashboard/sales/sales_ui.dart';
import 'package:beacon/ui/view/dashboard/sales/sales_widgets.dart';

/// Every checklist submission for the period, one page at a time. The period
/// is shared with the dashboard. The role filter belongs to this screen.
class ChecklistSubmissionsScreen extends StatefulWidget {
  const ChecklistSubmissionsScreen({
    super.key,
    required this.period,
    required this.accent,
  });

  final ChecklistPeriodController period;
  final Color accent;

  @override
  State<ChecklistSubmissionsScreen> createState() =>
      _ChecklistSubmissionsScreenState();
}

class _ChecklistSubmissionsScreenState
    extends State<ChecklistSubmissionsScreen> {
  late final AlAzeemChecklistController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AlAzeemChecklistController(period: widget.period)
      ..loadList();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffold,
      appBar: CustomAppBar(title: "Submissions"),
      body: AnimatedBuilder(
        animation: Listenable.merge([widget.period, _controller]),
        builder: (context, _) => _body(context),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final c = _controller;
    final period = widget.period;
    final accent = widget.accent;
    final p = c.page;

    return RefreshIndicator(
      color: accent,
      onRefresh: c.loadList,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 4.h),
        children: [
          Row(
            children: [
              Flexible(
                child: SalesPillButton(
                  icon: Icons.calendar_month_rounded,
                  label: checklistPeriodLabel(period.grain, period.date),
                  accent: accent,
                  onTap: () => showChecklistPeriodSheet(context, period),
                ),
              ),
              2.width,
              Flexible(
                child: SalesPillButton(
                  icon: Icons.badge_rounded,
                  label: c.role == null ? "All roles" : checklistRoleLabel(c.role),
                  accent: accent,
                  onTap: () => showChecklistRolePicker(
                    context,
                    c.role,
                    c.setRole,
                  ),
                ),
              ),
            ],
          ),
          if (p != null) ...[
            1.5.height,
            Text(
              "${p.total} checklists",
              style: TextStyle(fontSize: 3.sp, color: AppColor.grey),
            ),
          ],
          1.5.height,
          ..._rows(context, p),
        ],
      ),
    );
  }

  /// One loader stands in for the list while a page loads. Errors show a
  /// retry instead.
  List<Widget> _rows(BuildContext context, ChecklistPage? p) {
    final c = _controller;
    final accent = widget.accent;

    if (p == null) {
      if (c.listError != null) {
        return [AppErrorView(message: c.listError!, onRetry: c.loadList)];
      }
      return [SizedBox(height: 50.h, child: AppLoadingView(color: accent))];
    }

    if (p.items.isEmpty) {
      return [
        const SalesEmptyState(message: "No checklists for this period."),
      ];
    }

    return [
      for (final item in p.items)
        Padding(
          padding: EdgeInsets.only(bottom: 1.2.h),
          child: SalesRowCard(
            title: item.user.name,
            subtitle:
                "${checklistRoleLabel(item.user.role)} · ${item.checklistName}",
            trailingValue:
                "${item.counts.completedTasks}/${item.counts.totalTasks}",
            trailingCaption: checklistDateText(item.taskDate),
            accent: accent,
            onTap: () => AppRoutes.push(
              ChecklistDetailView(
                submissionId: item.submissionId,
                accentColor: accent,
              ),
            ),
          ),
        ),
      SalesPaginationBar(
        meta: SalesPageMeta(
          currentPage: p.currentPage,
          lastPage: p.lastPage,
          total: p.total,
          perPage: AlAzeemChecklistController.perPage,
        ),
        onPage: c.loadPage,
      ),
    ];
  }
}
