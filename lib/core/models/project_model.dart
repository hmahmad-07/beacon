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

  static const AppProject snackShack = AppProject(
    id: "snack_shack",
    name: "Snack Shack",
    shortName: "Snack Shack",
    asset: "assets/Snack-Shak.png",
    accent: Color(0xFFF28C28),
  );

  static const AppProject corporateCanteen = AppProject(
    id: "corporate_canteen",
    name: "Corporate Canteen",
    shortName: "Corporate Canteen",
    asset: "assets/corporate-canteen.jpg",
    accent: Color(0xFFAF2F03),
  );

  static const AppProject paani = AppProject(
    id: "paani",
    name: "Paani.",
    shortName: "Paani.",
    asset: "assets/paani.png",
    accent: Color(0xFF3A8C9E),
  );
  static const AppProject rabiaTrust = AppProject(
    id: "rabia_trust",
    name: "Rabia Trust Hospital",
    shortName: "Rabia Trust Hospital",
    asset: "assets/Rabia-Trust.png",
    accent: Color(0xFFD01372),
  );

  static const AppProject alAzeem = AppProject(
    id: "al_azeem",
    name: "Al Azeem Foundation",
    shortName: "Al Azeem Foundation",
    asset: "assets/Al-Azeem.jpeg",
    accent: Color(0xFFC9922B),
  );

  static const List<AppProject> all = [
    snackShack,
    corporateCanteen,
    paani,
    rabiaTrust,
    alAzeem,
  ];
}
