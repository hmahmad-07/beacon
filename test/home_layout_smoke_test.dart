import 'dart:developer';
import 'package:beacon/core/controllers/auth_controller.dart';
import 'package:beacon/core/controllers/employes_controller.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/models/employes_model.dart';
import 'package:beacon/core/models/project_model.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/ui/view/dashboard/home_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const departments = [
  'Management',
  'Administration',
  'Human Resource',
  'IT',
  'Internal Audit',
  'Accounts & Finance',
  'Sales & Marketing',
  'Production',
  'Purchase',
  'Supply Chain Management',
  'Main Store',
  'Kitchen',
];

SitesDetailModel _model() => SitesDetailModel(
  error: 0,
  totalShops: 2,
  shops: [
    Shop(
      shopId: "POS-0002",
      shopName: "Corporate Canteen",
      departments: [
        for (int i = 0; i < 6; i++)
          Department(
            departmentId: i + 1,
            departmentName: departments[i],
            employeeCount: 3,
          ),
      ],
    ),
    Shop(
      shopId: "POS-0003",
      shopName: "Paani.",
      departments: [
        for (int i = 6; i < 12; i++)
          Department(
            departmentId: i + 1,
            departmentName: departments[i],
            employeeCount: 3,
          ),
      ],
    ),
  ],
);

void _dumpOverflow(WidgetTester tester) {
  final dump = WidgetsBinding.instance.rootElement!.renderObject!
      .toStringDeep();
  final lines = dump.split('\n');
  final idx = lines.indexWhere((l) => l.contains('OVERFLOWING'));
  if (idx < 0) return;
  for (final line in lines.sublist(idx, (idx + 12).clamp(0, lines.length))) {
    log('>>> ${line.trim()}');
  }
}

void _check(WidgetTester tester, String label) {
  final err = tester.takeException();
  if (err != null) _dumpOverflow(tester);
  expect(err, isNull, reason: label);
}

void _run(String name, Size size) {
  testWidgets('HomeView layout @ $name', (tester) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final controller = EmployesController()..sitesDetailModel = _model();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthController>(
            create: (_) => AuthController(),
          ),
          ChangeNotifierProvider<EmployesController>.value(value: controller),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) {
              SizeConfig.init(context);
              return const HomeView();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    _check(tester, 'initial @ $name');
    expect(find.text('Corporate Canteen'), findsWidgets);

    expect(find.text('Logout'), findsOneWidget);
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();
    _check(tester, 'logout dialog @ $name');
    expect(find.text('CENTREX'), findsWidgets);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });
}

void main() {
  testWidgets('every project image is bundled', (tester) async {
    for (final project in AppProject.all) {
      final data = await rootBundle.load(project.asset);
      expect(data.lengthInBytes, greaterThan(0), reason: project.asset);
    }
  });

  _run('small (360x690)', const Size(360, 690));
  _run('pixel (411x891)', const Size(411, 891));
  _run('tablet (768x1024)', const Size(768, 1024));
}
