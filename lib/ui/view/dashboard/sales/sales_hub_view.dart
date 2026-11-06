import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/controllers/sales_controller.dart';
import '../../../../core/controllers/sales_period_controller.dart';
import '../../../../core/extensions/sizer.dart';
import '../../../../core/models/Sales/sales_common.dart';
import '../../../../core/models/project_model.dart';
import '../../../../core/resources/app_colors.dart';
import 'sales_clients_view.dart';
import 'sales_dashboard_view.dart';
import 'sales_salespersons_view.dart';
import '../../../components/site_design.dart';
import 'sales_ui.dart';
import 'sales_widgets.dart';

/// Sales overview for one business (Corporate Canteen or Paani). It shows the
/// headline numbers for the period and opens each report on its own screen.
class SalesHubView extends StatelessWidget {
  const SalesHubView({super.key, required this.business});

  final AppProject business;

  static SalesBusiness salesBusinessFor(AppProject project) {
    return project.id == AppProject.corporateCanteen.id
        ? SalesBusiness.cc
        : SalesBusiness.paani;
  }

  @override
  Widget build(BuildContext context) {
    final api = salesBusinessFor(business);
    final period = context.read<SalesPeriodController>();

    return SiteScope.wrap(
      accent: business.accent,
      child: ChangeNotifierProvider(
        create: (_) =>
            SalesController(business: api, initialFilters: period.filters)
              ..bindPeriod(period, (c) => c.loadDashboard())
              ..loadDashboard(),
        child: Consumer<SalesController>(
          builder: (context, controller, _) {
            final accent = business.accent;

            return RefreshIndicator(
              onRefresh: controller.loadDashboard,
              child: ListView(
                padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 4.h),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Overview",
                              style: TextStyle(
                                fontSize: 4.8.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColor.appDarkColor,
                              ),
                            ),
                            if (controller.lastUpdated != null) ...[
                              0.3.height,
                              Text(
                                salesUpdatedLabel(controller.lastUpdated),
                                style: TextStyle(
                                  fontSize: 2.6.sp,
                                  color: AppColor.grey,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      SalesPillButton(
                        icon: Icons.calendar_month_rounded,
                        label: salesPeriodLabel(controller.filters),
                        accent: accent,
                        onTap: () => _changePeriod(context),
                      ),
                    ],
                  ),
                  2.height,
                  _overview(controller, accent),
                  2.5.height,
                  const SalesSectionTitle("Reports"),
                  _reportTile(
                    icon: Icons.dashboard_rounded,
                    title: "Dashboard",
                    subtitle: "KPIs, monthly and daily trends, top lists",
                    accent: accent,
                    onTap: () => pushInSite(
                      accent,
                      SalesDashboardScreen(
                        business: api,
                        filters: controller.filters,
                      ),
                    ),
                  ),
                  _reportTile(
                    icon: Icons.groups_rounded,
                    title: "Clients",
                    subtitle:
                        "Internal clients, and external clients by order booker",
                    accent: accent,
                    onTap: () => pushInSite(
                      accent,
                      SalesClientsScreen(
                        business: api,
                        filters: controller.filters,
                      ),
                    ),
                  ),
                  _reportTile(
                    icon: Icons.badge_rounded,
                    title: "Salespersons",
                    subtitle: "Monthly performance for each salesperson",
                    accent: accent,
                    onTap: () => pushInSite(
                      accent,
                      SalesSalespersonsScreen(
                        business: api,
                        filters: controller.filters,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Picks a period. The choice goes to the shared period, which refreshes
  /// this overview and every Sales screen that is open.
  Future<void> _changePeriod(BuildContext context) async {
    final controller = context.read<SalesController>();
    final next = await showSalesPeriodSheet(context, controller.filters);
    if (next == null || !context.mounted) return;
    context.read<SalesPeriodController>().setPeriod(next);
  }

  Widget _overview(SalesController controller, Color accent) {
    if (controller.dashboardLoading && controller.dashboard == null) {
      return SizedBox(
        height: 30.h,
        child: SalesLoadingState(color: accent),
      );
    }
    if (controller.dashboardError != null && controller.dashboard == null) {
      return SalesErrorState(
        message: controller.dashboardError!,
        onRetry: controller.loadDashboard,
      );
    }
    final d = controller.dashboard;
    if (d == null) {
      return const SalesEmptyState(message: "No sales data for this period.");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (controller.dashboardError != null) ...[
          SalesErrorBanner(
            message: controller.dashboardError!,
            onRetry: controller.loadDashboard,
          ),
          2.height,
        ],
        SalesHero(
          accent: accent,
          title: "Net sales",
          value: salesMoney(d.kpis.salesAmount),
          subtitle:
              "${d.kpis.orderCount} orders · ${salesQty(d.kpis.salesQuantity)} qty",
          comparison: d.comparison,
        ),
        2.height,
        SizedBox(
          height: 12.h,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SalesKpi(
                  label: "Active clients",
                  value: "${d.activeTotal}",
                  caption: "${d.noSalesTotal} with no sales",
                  accent: accent,
                  icon: Icons.groups_rounded,
                ),
              ),
              2.width,
              Expanded(
                child: SalesKpi(
                  label: "Returns",
                  value: salesMoney(d.kpis.returnAmount),
                  accent: accent,
                  icon: Icons.undo_rounded,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reportTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return SiteActionTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      color: accent,
      onTap: onTap,
    );
  }
}
