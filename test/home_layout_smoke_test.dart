// Layout regression test for HomeView: the project rail must render all four
// projects, the grid must stay scoped to the selected one, and nothing may
// overflow across phone and tablet viewports.
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

EmployesModel _model() => EmployesModel(
  error: 0,
  totalUsers: departments.length * 3,
  users: [
    for (final d in departments)
      for (int i = 0; i < 3; i++)
        User(userId: '$d$i', userName: 'User $i', department: d),
  ],
);

void _dumpOverflow(WidgetTester tester) {
  final dump = WidgetsBinding.instance.rootElement!.renderObject!
      .toStringDeep();
  final lines = dump.split('\n');
  final idx = lines.indexWhere((l) => l.contains('OVERFLOWING'));
  if (idx < 0) return;
  for (final line in lines.sublist(idx, (idx + 12).clamp(0, lines.length))) {
    // ignore: avoid_print
    print('>>> ${line.trim()}');
  }
}

void _check(WidgetTester tester, String label) {
  final err = tester.takeException();
  if (err != null) _dumpOverflow(tester);
  expect(err, isNull, reason: label);
}

/// Scrolls the project rail until [label] is fully on screen, then taps it.
Future<void> _tapProject(WidgetTester tester, String label, String name) async {
  final finder = find.text(label);

  // Rewind the rail to the top so the search below is monotonic — a ListView
  // drops off-screen items, so we cannot rely on the target being built.
  for (int i = 0; i < 4; i++) {
    await tester.drag(find.byType(ListView), const Offset(0, 400));
    await tester.pumpAndSettle();
  }

  for (int attempt = 0; attempt < 12; attempt++) {
    if (finder.evaluate().isNotEmpty) {
      // Bound against the rail's own viewport: the pinned logout sits below
      // it, so "on screen" is not the same as "tappable in the rail".
      final rail = tester.getRect(find.byType(ListView));
      final rect = tester.getRect(finder.first);
      if (rect.top >= rail.top && rect.bottom <= rail.bottom) {
        await tester.tap(finder.first);
        await tester.pumpAndSettle();
        return;
      }
    }
    await tester.drag(find.byType(ListView), const Offset(0, -120));
    await tester.pumpAndSettle();
  }
  fail('could not bring rail item "$label" on screen @ $name');
}

void _run(String name, Size size) {
  testWidgets('HomeView layout @ $name', (tester) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final controller = EmployesController()..employesModel = _model();

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
    // Departments of the first project must be on screen.
    expect(find.byType(GridView), findsOneWidget);

    // Departments are split manually: first half Corporate Canteen, rest
    // Paani. Al Azeem and Rabia Trust have nothing on the API yet.
    final grouped = controller.projectDepartments;
    final flattened = grouped.values.expand((d) => d).toList();
    expect(flattened.toSet(), equals(departments.toSet()));
    expect(flattened.length, departments.length, reason: 'no duplicates');
    expect(grouped[AppProject.corporateCanteen.id], hasLength(6));
    expect(grouped[AppProject.paani.id], hasLength(6));
    expect(grouped[AppProject.alAzeem.id], isEmpty);
    expect(grouped[AppProject.rabiaTrust.id], isEmpty);

    for (final project in AppProject.all) {
      await _tapProject(tester, project.shortName, name);
      _check(tester, '${project.name} @ $name');

      final owned = grouped[project.id]!;
      if (owned.isEmpty) {
        expect(
          find.text('No departments in ${project.name}'),
          findsOneWidget,
          reason: 'empty state for ${project.name} @ $name',
        );
        continue;
      }
      for (final dept in owned) {
        expect(
          find.text(dept),
          findsOneWidget,
          reason: '$dept under ${project.name} @ $name',
        );
      }
      // A department owned by a different project must not leak in.
      final other = AppProject.all.firstWhere(
        (p) => p.id != project.id && grouped[p.id]!.isNotEmpty,
      );
      expect(
        find.text(grouped[other.id]!.first),
        findsNothing,
        reason: 'grid scoped to ${project.name} @ $name',
      );
    }

    // Logout is pinned to the rail and reachable without scrolling.
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
