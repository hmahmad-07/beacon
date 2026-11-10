import 'package:beacon/core/models/module_model.dart';
import 'package:beacon/core/models/site_entry.dart';
import 'package:beacon/ui/view/dashboard/department_picker_view.dart';
import 'package:beacon/ui/view/dashboard/module_workspace_view.dart';
import 'package:flutter/material.dart';

/// Field Activity across all sites. The left rail lists every site that has
/// employees (first one selected). The right side shows that site's
/// departments. Tapping a department opens the same employee list as before.
class FieldActivityView extends StatelessWidget {
  const FieldActivityView({super.key, required this.sites});

  final List<SiteEntry> sites;

  @override
  Widget build(BuildContext context) {
    final list = sites.where((s) => s.hasEmployees).toList();

    return ModuleWorkspaceView(
      moduleTitle: AppModule.employees.title,
      emptyMessage: "No sites are set up for Field Activity.",
      projects: [
        for (final s in list)
          WorkspaceProject(
            id: s.id,
            label: s.name,
            accent: s.accent,
            asset: s.asset,
          ),
      ],
      bodyBuilder: (context, project) {
        final site = list.firstWhere((s) => s.id == project.id);
        final shop = site.shop;
        if (shop == null) return const SizedBox.shrink();

        return DepartmentGrid(
          module: AppModule.employees,
          shop: shop,
          accentColor: site.accent,
          siteImage: site.asset,
          siteName: site.name,
          description: AppModule.employees.subtitle,
        );
      },
    );
  }
}
