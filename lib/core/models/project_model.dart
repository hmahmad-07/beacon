import 'package:flutter/material.dart';

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

  static const AppProject corporateCanteen = AppProject(
    id: "corporate_canteen",
    name: "Corporate Canteen",
    shortName: "Corporate Canteen",
    asset: "assets/corporate-canteen.jpg",
    accent: Color(0xFFC0392B),
  );

  static const AppProject paani = AppProject(
    id: "paani",
    name: "Paani.",
    shortName: "Paani.",
    asset: "assets/appIcon.png",
    accent: Color(0xFF1E88E5),
  );

  static const AppProject alAzeem = AppProject(
    id: "al_azeem",
    name: "Al Azeem Foundation",
    shortName: "Al Azeem Foundation",
    asset: "assets/Al-Azeem.jpeg",
    accent: Color(0xFFC9922B),
  );

  static const AppProject rabiaTrust = AppProject(
    id: "rabia_trust",
    name: "Rabia Trust Hospital",
    shortName: "Rabia Trust Hospital",
    asset: "assets/Rabia-Trust.jpg",
    accent: Color(0xFFD81B60),
  );

  static const List<AppProject> all = [
    corporateCanteen,
    paani,
    alAzeem,
    rabiaTrust,
  ];
}
