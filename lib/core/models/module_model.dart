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
    id: "field_activity",
    title: "Field Activity",
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

  static const sales = AppModule(
    id: "sales",
    title: "Sales",
    subtitle: "Paani & CC sales reports",
    icon: BoxIcons.bxs_bar_chart_alt_2,
  );

  static const checklists = AppModule(
    id: "checklists",
    title: "Checklists",
    subtitle: "Daily task checklists & submissions",
    icon: Icons.checklist_rounded,
  );

  static const List<AppModule> all = [employees, hr, inventory, sales];
}
