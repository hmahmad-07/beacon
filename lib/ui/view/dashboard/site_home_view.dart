import 'package:beacon/core/extensions/routes.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/models/module_model.dart';
import 'package:beacon/core/models/site_entry.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/core/utils/utils.dart';
import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:beacon/ui/components/site_widgets.dart';
import 'package:beacon/ui/view/dashboard/al_azeem/checklist_hub_view.dart';
import 'package:beacon/ui/view/dashboard/department_picker_view.dart';
import 'package:beacon/ui/view/dashboard/sales/sales_hub_view.dart';
import 'package:flutter/material.dart';

class SiteHomeView extends StatelessWidget {
  const SiteHomeView({super.key, required this.site});

  final SiteEntry site;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffold,
      appBar: CustomAppBar(title: site.name),
      body: ListView(
        padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 4.h),
        children: [
          _Banner(site: site),
          2.5.height,
          if (site.hasEmployees) ...[
            _sectionTitle("Modules"),
            1.5.height,
            _moduleTile(context, AppModule.employees),
            if (site.hasModules) _moduleTile(context, AppModule.hr),
          ],
          if (site.hasChecklists) ...[
            if (site.hasEmployees) 2.5.height,
            _sectionTitle("Checklists"),
            1.5.height,
            _moduleTile(context, AppModule.checklists),
          ],
          if (site.hasSales) ...[
            if (site.hasEmployees || site.hasChecklists) 2.5.height,
            _sectionTitle("Sales"),
            1.5.height,
            _moduleTile(context, AppModule.sales),
          ],
          if (site.screenModules.isEmpty)
            const _EmptyNote(text: "No modules are set up for this site yet."),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 4.2.sp,
        fontWeight: FontWeight.bold,
        color: AppColor.appDarkColor,
      ),
    );
  }

  Widget _moduleTile(BuildContext context, AppModule module) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.6.h),
      child: AppTile(
        icon: module.icon,
        title: module.title,
        subtitle: module.subtitle,
        accent: site.accent,
        onTap: () => _open(context, module),
      ),
    );
  }

  void _open(BuildContext context, AppModule module) {
    if (!site.supports(module)) {
      Utils.showSnackBar(
        context,
        "${module.title} is not set up for ${site.name}.",
      );
      return;
    }

    if (module.id == AppModule.checklists.id) {
      _openPage(
        context,
        module.title,
        ChecklistHubView(accentColor: site.accent),
      );
      return;
    }

    if (module.id == AppModule.sales.id) {
      final project = site.project;
      if (project == null) return;
      _openPage(context, module.title, SalesHubView(business: project));
      return;
    }

    final shop = site.shop;
    if (shop == null) return;
    _openPage(
      context,
      module.title,
      DepartmentGrid(
        module: module,
        shop: shop,
        accentColor: site.accent,
        siteImage: site.asset,
      ),
    );
  }

  void _openPage(BuildContext context, String title, Widget body) {
    AppRoutes.push(
      Scaffold(
        backgroundColor: AppColor.scaffold,
        appBar: CustomAppBar(title: title),
        body: body,
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.site});

  final SiteEntry site;

  @override
  Widget build(BuildContext context) {
    final count = site.screenModules.length;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.appLightColor),
      ),
      child: Row(
        children: [
          SiteLogo(asset: site.asset, accent: site.accent, size: 16.w),
          4.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  site.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 4.8.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.appDarkColor,
                  ),
                ),
                0.4.height,
                Text(
                  "$count ${count == 1 ? 'module' : 'modules'} available",
                  style: TextStyle(fontSize: 3.2.sp, color: AppColor.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.appLightColor),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 3.4.sp, color: AppColor.grey),
      ),
    );
  }
}
