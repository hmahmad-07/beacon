import 'package:flutter/material.dart';

import '../resources/app_colors.dart';
import 'Employees/employes_model.dart';

class AppProject {
  final String id;
  final String name;
  final String shortName;
  final String asset;
  final Color accent;

  const AppProject({
    required this.id,
    required this.name,
    required this.shortName,
    required this.asset,
    required this.accent,
  });

  static final AppProject snackShack = AppProject(
    id: "POS-0001",
    name: "Snack Shack",
    shortName: "Snack Shack",
    asset: "assets/Snack-Shak.png",
    accent: AppColor.ss,
  );

  static final AppProject corporateCanteen = AppProject(
    id: "POS-0002",
    name: "Corporate Canteen",
    shortName: "Corporate Canteen",
    asset: "assets/corporate-canteen.jpg",
    accent: AppColor.cc,
  );

  static final AppProject paani = AppProject(
    id: "POS-0003",
    name: "Paani.",
    shortName: "Paani.",
    asset: "assets/paani.png",
    accent: AppColor.paani,
  );

  static final AppProject rabiaTrust = AppProject(
    id: "POS-0010",
    name: "Rabia Trust Hospital",
    shortName: "Rabia Trust Hospital",
    asset: "assets/Rabia-Trust.png",
    accent: AppColor.rth,
  );

  static final AppProject alAzeem = AppProject(
    id: "POS-0011",
    name: "Al Azeem Foundation",
    shortName: "Al Azeem Foundation",
    asset: "assets/Al-Azeem.jpeg",
    accent: AppColor.aa,
  );

  static final AppProject opd = AppProject(
    id: "POS-0012",
    name: "OPD",
    shortName: "OPD",
    asset: "assets/Rth-OPD.png",
    accent: AppColor.opd,
  );

  static final AppProject amtax = AppProject(
    id: "POS-0009",
    name: "AMTEX",
    shortName: "AMTEX",
    asset: "assets/amtex.png",
    accent: AppColor.amtax,
  );

  static final List<AppProject> all = [
    snackShack,
    corporateCanteen,
    paani,
    rabiaTrust,
    alAzeem,
    opd,
    amtax,
  ];

  /// Businesses that have a dedicated Sales section (Sales API scope).
  static final List<AppProject> salesBusinesses = [paani, corporateCanteen];

  static String _normalize(String value) =>
      value.toLowerCase().replaceAll(" ", "").replaceAll(".", "");

  /// Matches a shop to its project. The shop ID is authoritative and is
  /// checked first. Name matching is a fallback, and it ignores empty names
  /// so a blank shop name can never match an arbitrary project.
  static AppProject? matchShop(Shop shop) {
    final shopId = (shop.shopId ?? "").trim().toLowerCase();
    if (shopId.isNotEmpty) {
      for (final project in all) {
        if (project.id.toLowerCase() == shopId) return project;
      }
    }

    final name = _normalize(shop.shopName ?? "");
    if (name.isEmpty) return null;

    for (final project in all) {
      final pName = _normalize(project.name);
      final pShort = _normalize(project.shortName);
      if (name == pName || name == pShort) return project;
    }
    for (final project in all) {
      final pName = _normalize(project.name);
      final pShort = _normalize(project.shortName);
      if (name.contains(pName) ||
          pName.contains(name) ||
          name.contains(pShort) ||
          pShort.contains(name)) {
        return project;
      }
    }
    return null;
  }
}
