import 'package:flutter/material.dart';

import 'package:beacon/core/controllers/al_azeem_checklist_controller.dart';
import 'package:beacon/core/controllers/al_azeem_checklist_period_controller.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/ui/components/site_design.dart';
import 'package:beacon/ui/view/dashboard/al_azeem/checklist_submissions_view.dart';
import 'package:beacon/ui/view/dashboard/al_azeem/checklist_widgets.dart';
import 'package:beacon/ui/view/dashboard/sales/sales_ui.dart';

/// Al-Azeem checklists: the module's first screen is the dashboard. It shows
/// the figures for the chosen period, and the submission list opens from it.
///
/// This renders the body only. The site screen supplies the app bar.
class ChecklistHubView extends StatefulWidget {
  const ChecklistHubView({super.key, required this.accentColor});

  final Color accentColor;

  @override
  State<ChecklistHubView> createState() => _ChecklistHubViewState();
}

class _ChecklistHubViewState extends State<ChecklistHubView> {
  late final ChecklistPeriodController _period;
  late final AlAzeemChecklistController _controller;

  @override
  void initState() {
    super.initState();
    _period = ChecklistPeriodController();
    _controller = AlAzeemChecklistController(period: _period)..loadDashboard();
  }

  @override
  void dispose() {
    _controller.dispose();
    _period.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SiteScope.wrap(
      accent: widget.accentColor,
      child: Builder(builder: _buildContent),
    );
  }

  Widget _buildContent(BuildContext context) {
    final accent = widget.accentColor;

    return AnimatedBuilder(
      animation: Listenable.merge([_period, _controller]),
      builder: (context, _) {
        return RefreshIndicator(
          color: accent,
          onRefresh: _controller.loadDashboard,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 4.h),
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: SalesPillButton(
                  icon: Icons.calendar_month_rounded,
                  label: checklistPeriodLabel(_period.grain, _period.date),
                  accent: accent,
                  onTap: () => showChecklistPeriodSheet(context, _period),
                ),
              ),
              2.height,
              _figures(),
              2.5.height,
              const SalesSectionTitle("Submissions"),
              _reportTile(
                icon: Icons.checklist_rounded,
                title: "Submission list",
                subtitle: "Every checklist, by employee and role",
                onTap: () => pushInSite(
                  accent,
                  ChecklistSubmissionsScreen(period: _period, accent: accent),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// One loader while the figures load. Errors show a retry, never a second
  /// loader.
  Widget _figures() {
    final c = _controller;
    final s = c.dashboard;
    final accent = widget.accentColor;

    if (s == null) {
      if (c.dashboardError != null) {
        return AppErrorView(
          message: c.dashboardError!,
          onRetry: c.loadDashboard,
        );
      }
      return SizedBox(height: 60.h, child: AppLoadingView(color: accent));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SalesHero(
          accent: accent,
          title: "Task completion",
          value: "${(s.progress * 100).round()}%",
          subtitle: "${s.completedTasks} of ${s.totalTasks} tasks done",
        ),
        2.height,
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 2.w,
          crossAxisSpacing: 2.w,
          childAspectRatio: 1.7,
          children: [
            SalesKpi(
              label: "Checklists",
              value: "${s.totalChecklists}",
              accent: accent,
              icon: Icons.fact_check_rounded,
            ),
            SalesKpi(
              label: "Total tasks",
              value: "${s.totalTasks}",
              accent: accent,
              icon: Icons.format_list_numbered_rounded,
            ),
            SalesKpi(
              label: "Completed",
              value: "${s.completedTasks}",
              accent: accent,
              icon: Icons.check_circle_rounded,
            ),
            SalesKpi(
              label: "Pending",
              value: "${s.pendingTasks}",
              accent: accent,
              icon: Icons.pending_actions_rounded,
            ),
          ],
        ),
        2.5.height,
        const SalesSectionTitle("Completion"),
        SalesCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${s.completedTasks} of ${s.totalTasks} tasks completed",
                style: TextStyle(
                  fontSize: 3.3.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColor.appDarkColor,
                ),
              ),
              1.5.height,
              ChecklistProgressBar(value: s.progress, color: accent),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reportTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return SiteActionTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      color: widget.accentColor,
      onTap: onTap,
    );
  }

}
