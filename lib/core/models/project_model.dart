import 'package:flutter/material.dart';

import '../resources/app_colors.dart';

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

  static AppProject snackShack = AppProject(
    id: "POS-0001",
    name: "Snack Shack",
    shortName: "Snack Shack",
    asset: "assets/Snack-Shak.png",
    accent: AppColor.ss,
  );

  static AppProject corporateCanteen = AppProject(
    id: "POS-0002",
    name: "Corporate Canteen",
    shortName: "Corporate Canteen",
    asset: "assets/corporate-canteen.jpg",
    accent: AppColor.cc,
  );

  static AppProject paani = AppProject(
    id: "POS-0003",
    name: "Paani.",
    shortName: "Paani.",
    asset: "assets/paani.png",
    accent: AppColor.paani,
  );

  static AppProject rabiaTrust = AppProject(
    id: "POS-0010",
    name: "Rabia Trust Hospital",
    shortName: "Rabia Trust Hospital",
    asset: "assets/Rabia-Trust.png",
    accent: AppColor.rth,
  );

  static AppProject alAzeem = AppProject(
    id: "POS-0011",
    name: "Al Azeem Foundation",
    shortName: "Al Azeem Foundation",
    asset: "assets/Al-Azeem.jpeg",
    accent: AppColor.aa,
  );

  static AppProject opd = AppProject(
    id: "POS-0012",
    name: "OPD",
    shortName: "OPD",
    asset: "assets/Rth-OPD.png",
    accent: AppColor.opd,
  );

  static AppProject amtax = AppProject(
    id: "POS-0009",
    name: "AMTEX",
    shortName: "AMTEX",
    asset: "assets/amtex.png",
    accent: AppColor.amtax,
  );

  static List<AppProject> all = [
    snackShack,
    corporateCanteen,
    paani,
    rabiaTrust,
    alAzeem,
    opd,
    amtax,
  ];
}
