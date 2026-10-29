import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/extensions/sizer.dart';
import '../../../core/resources/app_colors.dart';
import '../../components/custom_appbar.dart';

/// One project inside a module (a rail item or a segment).
class WorkspaceProject {
  const WorkspaceProject({
    required this.id,
    required this.label,
    required this.accent,
    this.asset,
  });

  final String id;
  final String label;
  final Color accent;
  final String? asset;
}

/// How a module lists its projects.
///
/// - [rail]: a vertical list on the left, content on the right
///   (Employees and HR).
/// - [segmented]: a segmented control above the content, for a small fixed
///   set of projects (Sales: Corporate Canteen and Paani).
enum WorkspaceLayout { rail, segmented }

/// Shared shell for modules that work per project. Home only lists modules;
/// the project selection happens here, inside the module.
class ModuleWorkspaceView extends StatefulWidget {
  const ModuleWorkspaceView({
    super.key,
    required this.moduleTitle,
    required this.projects,
    required this.bodyBuilder,
    this.layout = WorkspaceLayout.rail,
    this.emptyMessage = "No projects available.",
  });

  final String moduleTitle;
  final List<WorkspaceProject> projects;
  final Widget Function(BuildContext context, WorkspaceProject project)
  bodyBuilder;
  final WorkspaceLayout layout;
  final String emptyMessage;

  @override
  State<ModuleWorkspaceView> createState() => _ModuleWorkspaceViewState();
}

class _ModuleWorkspaceViewState extends State<ModuleWorkspaceView> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final count = widget.projects.length;
    // The project list can shrink between builds; keep the index in range.
    final index = count == 0
        ? 0
        : (_selected >= count ? count - 1 : _selected);

    return Scaffold(
      backgroundColor: AppColor.scaffold,
      appBar: CustomAppBar(title: widget.moduleTitle),
      body: count == 0
          ? _emptyState()
          : widget.layout == WorkspaceLayout.rail
          ? _railLayout(index)
          : _segmentedLayout(index),
    );
  }

  // ============================================================ Rail

  Widget _railLayout(int index) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _rail(index),
        Expanded(child: _content(index)),
      ],
    );
  }

  Widget _rail(int index) {
    return Container(
      width: 24.w,
      decoration: BoxDecoration(
        color: AppColor.white,
        border: Border(right: BorderSide(color: AppColor.appLightColor)),
      ),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 1.h),
        itemCount: widget.projects.length,
        itemBuilder: (context, i) => _railItem(i, i == index),
      ),
    );
  }

  Widget _railItem(int i, bool selected) {
    final project = widget.projects[i];
    final accent = project.accent;

    return Material(
      color: AppColor.transparent,
      child: InkWell(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(8.r)),
        onTap: () {
          if (selected) return;
          setState(() => _selected = i);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          margin: EdgeInsets.only(bottom: 0.8.h, right: 1.5.w),
          padding: EdgeInsets.symmetric(vertical: 1.2.h, horizontal: 1.w),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.1)
                : AppColor.transparent,
            borderRadius: BorderRadius.horizontal(right: Radius.circular(8.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _logo(project, selected, size: 16.w),
              0.6.height,
              Text(
                project.label,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 3.sp,
                  height: 1.2,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: selected ? accent : AppColor.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================ Segmented

  Widget _segmentedLayout(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _segmentBar(index),
        Expanded(child: _content(index)),
      ],
    );
  }

  Widget _segmentBar(int index) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(4.w, 1.5.h, 4.w, 1.5.h),
      decoration: BoxDecoration(
        color: AppColor.white,
        border: Border(bottom: BorderSide(color: AppColor.appLightColor)),
      ),
      child: CupertinoSlidingSegmentedControl<int>(
        groupValue: index,
        backgroundColor: AppColor.appLightColor,
        thumbColor: AppColor.white,
        children: {
          for (var i = 0; i < widget.projects.length; i++)
            i: Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
              child: Text(
                widget.projects[i].label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 3.5.sp,
                  fontWeight: FontWeight.w600,
                  color: i == index
                      ? widget.projects[i].accent
                      : AppColor.grey,
                ),
              ),
            ),
        },
        onValueChanged: (value) {
          if (value == null || value == index) return;
          setState(() => _selected = value);
        },
      ),
    );
  }

  // ============================================================ Shared

  Widget _logo(WorkspaceProject project, bool selected, {required double size}) {
    final accent = project.accent;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.1),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColor.white,
        border: Border.all(
          color: selected ? accent : AppColor.appLightColor,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: project.asset != null
          ? ClipOval(
              child: Image.asset(project.asset!, fit: BoxFit.contain),
            )
          : Icon(
              Icons.storefront_rounded,
              color: selected ? accent : AppColor.grey,
              size: size * 0.6,
            ),
    );
  }

  /// The selected project's module content. Keyed by project so switching
  /// projects starts that project's own state.
  Widget _content(int index) {
    final project = widget.projects[index];
    return KeyedSubtree(
      key: ValueKey(project.id),
      child: widget.bodyBuilder(context, project),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Text(
          widget.emptyMessage,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 3.4.sp, color: AppColor.grey),
        ),
      ),
    );
  }
}
