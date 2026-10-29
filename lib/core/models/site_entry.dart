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

  /// Modules listed on this site's screen. Employees and HR need departments.
  /// Checklists need Al-Azeem. Sales needs a Sales business. Inventory is in
  /// the drawer, not here.
  List<AppModule> get screenModules => [
    if (hasModules) AppModule.employees,
    if (hasModules) AppModule.hr,
    if (hasChecklists) AppModule.checklists,
    if (hasSales) AppModule.sales,
  ];

  /// Sites whose modules are not in use yet. The API still returns
  /// departments for them, so they are listed here explicitly.
  static final Set<String> _noModuleIds = {
    AppProject.rabiaTrust.id,
    AppProject.opd.id,
    AppProject.snackShack.id,
  };

  /// True when this site's Employees and HR modules are in use.
  bool get hasModules => !_noModuleIds.contains(project?.id) && hasDepartments;

  /// Whether this site can open [module] at all.
  bool supports(AppModule module) {
    if (module.id == AppModule.sales.id) return hasSales;
    if (module.id == AppModule.checklists.id) return hasChecklists;
    return shop != null;
  }
}
