import 'package:flutter/material.dart';
import 'package:iconsx_plus/iconsx_plus.dart';

class AppModule {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool comingSoon;

  const AppModule({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.comingSoon = false,
  });

  static const employees = AppModule(
    id: "employees",
    title: "Employees",
    subtitle: "General details, attendance & visits",
    icon: BoxIcons.bxs_id_card,
  );

  static const hr = AppModule(
    id: "hr",
    title: "HR",
    subtitle: "Reports, salary & headcount",
    icon: BoxIcons.bxs_group,
  );

  static const inventory = AppModule(
    id: "inventory",
    title: "Inventory",
    subtitle: "Store stock & WMS reports",
    icon: BoxIcons.bx_package,
  );

  static const List<AppModule> all = [employees, hr, inventory];
}
