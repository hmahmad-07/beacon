import 'package:centrex/core/controllers/connectivity_controller.dart';
import 'package:centrex/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/extensions/sizer.dart';
import 'core/extensions/routes.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'core/network/internet_connectivity.dart';
import 'ui/view/splash_view.dart';
import 'package:centrex/core/controllers/auth_controller.dart';
import 'package:centrex/core/controllers/employes_controller.dart';
import 'package:centrex/core/resources/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(Phoenix(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context, debug: true);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeManager()),
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => EmployesController()),
        ChangeNotifierProvider(create: (_) => ConnectivityController()),
      ],
      child: Consumer<ThemeManager>(
        builder: (context, themeManager, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            navigatorKey: AppRoutes.navigatorKey,
            title: 'CENTREX',
            theme: AppTheme.lightTheme.copyWith(
              textTheme: GoogleFonts.interTextTheme(
                AppTheme.lightTheme.textTheme,
              ),
            ),
            home: const SplashView(),
            builder: (context, child) {
              return GestureDetector(
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                behavior: HitTestBehavior.translucent,
                child: Consumer<ConnectivityController>(
                  builder: (context, connectivity, _) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        child ?? const SizedBox.shrink(),
                        if (!connectivity.isOnline)
                          const Positioned.fill(child: NoInternetView()),
                      ],
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
