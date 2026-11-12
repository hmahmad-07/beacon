import 'package:flutter/material.dart';

/// Part of the day, used by the home greeting.
enum DayPhase {
  morning(
    greeting: "Good morning",
    message: "Wishing you a productive day ahead.",
    icon: Icons.wb_sunny_rounded,
  ),
  afternoon(
    greeting: "Good afternoon",
    message: "Hope your day is going well.",
    icon: Icons.light_mode_rounded,
  ),
  evening(
    greeting: "Good evening",
    message: "Here's a quick look before you wrap up.",
    icon: Icons.wb_twilight_rounded,
  ),
  night(
    greeting: "Good night",
    message: "Working late? Here's where things stand.",
    icon: Icons.dark_mode_rounded,
  );

  const DayPhase({
    required this.greeting,
    required this.message,
    required this.icon,
  });

  final String greeting;
  final String message;
  final IconData icon;

  static DayPhase of(DateTime time) {
    final hour = time.hour;
    if (hour >= 5 && hour < 12) return morning;
    if (hour >= 12 && hour < 17) return afternoon;
    if (hour >= 17 && hour < 21) return evening;
    return night;
  }
}
