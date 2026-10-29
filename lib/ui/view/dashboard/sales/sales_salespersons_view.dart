import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/controllers/sales_controller.dart';
import '../../../../core/controllers/sales_period_controller.dart';
import '../../../../core/extensions/routes.dart';
import '../../../../core/extensions/sizer.dart';
import '../../../../core/models/Sales/sales_common.dart';
import '../../../../core/resources/app_colors.dart';
import '../../../components/custom_appbar.dart';
import 'sales_clients_view.dart';
import 'sales_ui.dart';
import 'sales_widgets.dart';

/// Salesperson performance for one business and period. Tapping a
/// salesperson opens the internal clients they supply.
class SalesSalespersonsScreen extends StatelessWidget {
  const SalesSalespersonsScreen({
    super.key,
    required this.business,
    required this.filters,
  });

  final SalesBusiness business;
  final SalesFilters filters;

  @override
  Widget build(BuildContext context) {
    final period = context.read<SalesPeriodController>();
    return ChangeNotifierProvider(
      create: (_) =>
          SalesController(business: business, initialFilters: filters)
            ..bindPeriod(period, (c) => c.loadSalespersons(perPage: 100))
            ..loadSalespersons(perPage: 100),
      child: const _SalespersonsBody(),
    );
  }
}

class _SalespersonsBody extends StatelessWidget {
  const _SalespersonsBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<SalesController>(
      builder: (context, controller, _) {
        final accent = salesAccentFor(controller.business);
        return Scaffold(
          backgroundColor: AppColor.scaffold,
          appBar: CustomAppBar(title: "Salespersons"),
          body: RefreshIndicator(
            onRefresh: () => controller.loadSalespersons(perPage: 100),
            child: ListView(
              padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 4.h),
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: SalesPillButton(
                    icon: Icons.calendar_month_rounded,
                    label: salesPeriodLabel(controller.filters),
                    accent: accent,
                    onTap: () => _changePeriod(context, controller),
                  ),
                ),
                2.height,
                _body(controller, accent),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _changePeriod(
    BuildContext context,
    SalesController controller,
  ) async {
    final next = await showSalesPeriodSheet(context, controller.filters);
    if (next == null || !context.mounted) return;
    context.read<SalesPeriodController>().setPeriod(next);
  }

  Widget _body(SalesController controller, Color accent) {
    final page = controller.salespersons;

    if (controller.salespersonLoading && page == null) {
      return SizedBox(height: 40.h, child: const SalesLoadingState());
    }
    if (controller.salespersonError != null && page == null) {
      return SalesErrorState(
        message: controller.salespersonError!,
        onRetry: () => controller.loadSalespersons(perPage: 100),
      );
    }
    if (page == null || page.items.isEmpty) {
      return const SalesEmptyState(
        message: "No salesperson activity for this period.",
      );
    }

    final people = page.items;
    final sales = people.fold<double>(0, (s, p) => s + p.salesAmount);
    final orders = people.fold<int>(0, (s, p) => s + p.orderCount);
    final active = people.where((p) => p.isActive).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 12.h,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SalesKpi(
                  label: "Net sales",
                  value: salesMoney(sales),
                  caption: "${people.length} salespersons",
                  accent: accent,
                  icon: Icons.payments_rounded,
                ),
              ),
              2.width,
              Expanded(
                child: SalesKpi(
                  label: "Orders",
                  value: "$orders",
                  caption: "$active active",
                  accent: accent,
                  icon: Icons.receipt_long_rounded,
                ),
              ),
            ],
          ),
        ),
        2.5.height,
        const SalesSectionTitle("Salespersons"),
        for (final person in people)
          Padding(
            padding: EdgeInsets.only(bottom: 1.2.h),
            child: SalesRowCard(
              title: person.name,
              subtitle:
                  "${person.employeeCode ?? '-'} · ${person.salesGroup ?? 'No group'} · ${person.isActive ? 'Active' : 'Inactive'}",
              trailingValue: salesMoney(person.salesAmount),
              trailingCaption:
                  "${person.orderCount} orders · ${person.clientCoverage} clients",
              accent: accent,
              comparison: person.comparison,
              onTap: () => AppRoutes.push(
                SalesClientsScreen(
                  business: controller.business,
                  filters: controller.filters,
                  kind: SalesClientKind.internal,
                  initialPickId: '${person.salespersonId}',
                  initialName: person.name,
                ),
              ),
            ),
          ),
        1.height,
        Text(
          "Targets are not set in the system yet, so achievement is not shown.",
          style: TextStyle(fontSize: 2.6.sp, color: AppColor.grey),
        ),
      ],
    );
  }
}
