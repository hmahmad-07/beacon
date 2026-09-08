import 'package:flutter/material.dart';
import 'package:iconsx_plus/iconsx_plus.dart';

/// Best-effort icon lookup by department name. Shared between the module
/// grid and the department-picker grid so a department renders with the
/// same icon everywhere in the app.
IconData departmentIcon(String dept) {
  final d = dept.toLowerCase();
  if (d.contains("kitchen")) return IonIcons.restaurant;
  if (d.contains("internal audit") || d.contains("audit")) {
    return BoxIcons.bx_clipboard;
  }
  if (RegExp(r"\bit\b").hasMatch(d)) return BoxIcons.bx_laptop;
  if (d.contains("sales")) return BoxIcons.bx_bar_chart_alt;
  if (d.contains("admin")) return BoxIcons.bx_shield;
  if (d.contains("hr") || d.contains("human")) return BoxIcons.bx_user;
  if (d.contains("account") || d.contains("finance")) {
    return BoxIcons.bx_wallet;
  }
  if (d.contains("marketing")) return IonIcons.megaphone;
  if (d.contains("operation")) return BoxIcons.bx_cog;
  if (d.contains("production")) return IonIcons.construct;
  if (d.contains("purchase")) return BoxIcons.bx_cart;
  if (d.contains("supply chain")) return BoxIcons.bx_package;
  if (d.contains("store")) return BoxIcons.bx_store;
  return BoxIcons.bx_buildings;
}
