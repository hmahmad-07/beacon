import 'package:flutter/material.dart';

import '../resources/app_colors.dart';
import 'Employees/employes_model.dart';
import 'module_model.dart';
import 'project_model.dart';

/// One selectable site. It comes from an API shop and is matched to its
/// known project when possible, which supplies the logo and accent.
class SiteEntry {
  const SiteEntry({
    required this.id,
    required this.name,
    required this.accent,
    this.asset,
    this.shop,
    this.project,
  });

  final String id;
  final String name;
  final Color accent;
  final String? asset;
  final Shop? shop;
  final AppProject? project;

  /// Open sites first. Permanently closed sites come last.
  static List<SiteEntry> fromShops(List<Shop> shops) {
    final all = [
      for (var i = 0; i < shops.length; i++) _fromShop(shops[i], i),
    ];
    return [
      ...all.where((s) => !s.isClosed),
      ...all.where((s) => s.isClosed),
    ];
  }

  static SiteEntry _fromShop(Shop shop, int index) {
    final project = AppProject.matchShop(shop);
    return SiteEntry(
      id: shop.shopId ?? "shop-$index",
      name: project?.shortName ?? shop.shopName ?? "Site",
      accent: project?.accent ?? AppColor.appColor1,
      asset: project?.asset,
      shop: shop,
      project: project,
    );
  }

  /// Snack Shack has closed permanently.
  bool get isClosed => project?.id == AppProject.snackShack.id;

  /// True when the site is a Sales business (Paani or Corporate Canteen).
  bool get hasSales {
    final p = project;
    return p != null && AppProject.salesBusinesses.any((b) => b.id == p.id);
  }

  /// True for Al-Azeem, which has the Checklists module.
  bool get hasChecklists => project?.id == AppProject.alAzeem.id;

  /// True when the site has at least one department set up.
  bool get hasDepartments => shop?.departments?.isNotEmpty ?? false;

  /// Modules listed on this site's screen. Employees is the general module and
  /// is shown for every site. HR needs departments and is in use. Checklists
  /// need Al-Azeem. Sales needs a Sales business. Inventory is in the drawer.
  List<AppModule> get screenModules => [
    if (hasEmployees) AppModule.employees,
    if (hasModules) AppModule.hr,
    if (hasChecklists) AppModule.checklists,
    if (hasSales) AppModule.sales,
  ];

  /// Sites whose HR module is not in use yet. The API still returns
  /// departments for them, so HR is hidden for them explicitly.
  static final Set<String> _noHrIds = {
    AppProject.rabiaTrust.id,
    AppProject.opd.id,
    AppProject.snackShack.id,
  };

  /// True when the site has a shop record, so the general Employees module
  /// can open. Rabia Trust, OPD and Snack Shack are included.
  bool get hasEmployees => shop != null;

  /// True when this site's HR module is in use.
  bool get hasModules => !_noHrIds.contains(project?.id) && hasDepartments;

  /// Whether this site can open [module] at all.
  bool supports(AppModule module) {
    if (module.id == AppModule.sales.id) return hasSales;
    if (module.id == AppModule.checklists.id) return hasChecklists;
    return shop != null;
  }
}
