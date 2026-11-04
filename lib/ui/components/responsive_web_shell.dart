import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Wraps the app in a centered, phone-width frame when running on the web
/// with a browser window wider than [breakpoint]. The app's UI is built for
/// mobile screens (percentage-based sizing via SizeConfig), so on a wide
/// desktop browser it would otherwise stretch and look broken. Below the
/// breakpoint (mobile browsers) it renders full width, unchanged.
class ResponsiveWebShell extends StatelessWidget {
  const ResponsiveWebShell({super.key, required this.child});

  final Widget child;

  static const double frameWidth = 430;
  static const double breakpoint = 700;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;

    final mediaQuery = MediaQuery.of(context);
    if (mediaQuery.size.width < breakpoint) return child;

    return ColoredBox(
      color: const Color(0xFF111827),
      child: Center(
        child: SizedBox(
          width: frameWidth,
          height: mediaQuery.size.height,
          child: MediaQuery(
            data: mediaQuery.copyWith(size: Size(frameWidth, mediaQuery.size.height)),
            child: PhysicalModel(
              color: Theme.of(context).scaffoldBackgroundColor,
              elevation: 24,
              shadowColor: Colors.black87,
              clipBehavior: Clip.antiAlias,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
