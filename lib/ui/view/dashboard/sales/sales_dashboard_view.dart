import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/controllers/sales_controller.dart';
import '../../../../core/controllers/sales_period_controller.dart';
import '../../../../core/extensions/sizer.dart';
import '../../../../core/models/Sales/sales_common.dart';
import '../../../../core/models/Sales/sales_models.dart';
import '../../../../core/resources/app_colors.dart';
import '../../../components/custom_appbar.dart';
import '../../../components/site_design.dart';
import 'sales_ui.dart';
import 'sales_widgets.dart';

/// Sales dashboard for one business and one period: headline figures,
/// internal versus external split, client activity, trends and top lists.
class SalesDashboardScreen extends StatelessWidget {
  const SalesDashboardScreen({
    super.key,
    required this.business,
    required this.filters,
  });

  final SalesBusiness business;
  final SalesFilters filters;

  @override
  Widget build(BuildContext context) => SiteScope.wrap(
    accent: salesAccentFor(business),
    child: Builder(builder: _build),
  );

  Widget _build(BuildContext context) {
    final period = context.read<SalesPeriodController>();
    return ChangeNotifierProvider(
      create: (_) =>
          SalesController(business: business, initialFilters: filters)
            ..bindPeriod(period, (c) => c.loadDashboard())
            ..loadDashboard(),
      child: const _DashboardBody(),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<SalesController>(
      builder: (context, controller, _) {
        final accent = salesAccentFor(controller.business);
        return Scaffold(
          backgroundColor: AppColor.scaffold,
          appBar: CustomAppBar(title: "Sales Dashboard"),
          body: _body(context, controller, accent),
        );
      },
    );
  }

  Widget _body(BuildContext context, SalesController controller, Color accent) {
    if (controller.dashboardLoading && controller.dashboard == null) {
      return const SalesLoadingState();
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

    return RefreshIndicator(
      onRefresh: controller.loadDashboard,
      child: ListView(
        padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 4.h),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  salesUpdatedLabel(controller.lastUpdated),
                  style: TextStyle(fontSize: 2.8.sp, color: AppColor.grey),
                ),
              ),
              SalesPillButton(
                icon: Icons.calendar_month_rounded,
                label: salesPeriodLabel(controller.filters),
                accent: accent,
                onTap: () => _changePeriod(context, controller),
              ),
            ],
          ),
          2.height,
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
          _kpiGrid(d, accent),
          2.5.height,
          const SalesSectionTitle("Internal vs external"),
          _splitCard(d, accent),
          2.5.height,
          const SalesSectionTitle("Clients"),
          _activityCard(d, accent),
          2.5.height,
          const SalesSectionTitle("Monthly trend · 12 months"),
          SalesCard(
            child: SalesBarChart(
              accent: accent,
              bars: salesBarsFrom(d.monthlyTrend, salesMonthKeyLabel),
            ),
          ),
          2.5.height,
          const SalesSectionTitle("Daily sales · selected period"),
          SalesCard(
            child: SalesBarChart(
              accent: accent,
              bars: salesBarsFrom(d.dailyTrend, salesDayKeyLabel),
            ),
          ),
          2.5.height,
          const SalesSectionTitle("Top salespersons"),
          _ranking(d.topSalespersons, accent),
          2.5.height,
          const SalesSectionTitle("Top clients"),
          _ranking(d.topClients, accent),
          2.5.height,
          const SalesSectionTitle("Top products"),
          _ranking(d.topSkus, accent),
        ],
      ),
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

  Widget _kpiGrid(SalesDashboard d, Color accent) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 2.w,
      crossAxisSpacing: 2.w,
      childAspectRatio: 1.7,
      children: [
        SalesKpi(
          label: "Quantity sold",
          value: salesQty(d.kpis.salesQuantity),
          accent: accent,
          icon: Icons.inventory_2_rounded,
        ),
        SalesKpi(
          label: "Gross sales",
          value: salesMoney(d.kpis.grossSalesAmount),
          caption: "Discount ${salesMoney(d.kpis.discountAmount)}",
          accent: accent,
          icon: Icons.receipt_long_rounded,
        ),
        SalesKpi(
          label: "Sales before returns",
          value: salesMoney(d.kpis.saleAmount),
          accent: accent,
          icon: Icons.point_of_sale_rounded,
        ),
        SalesKpi(
          label: "Returns",
          value: salesMoney(d.kpis.returnAmount),
          accent: accent,
          icon: Icons.undo_rounded,
        ),
      ],
    );
  }

  Widget _splitCard(SalesDashboard d, Color accent) {
    final total = d.internalAmount + d.externalAmount;
    final share = total <= 0
        ? 0.0
        : (d.internalAmount / total).clamp(0.0, 1.0).toDouble();

    return SalesCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _splitRow("Internal", d.internalAmount, d.internalQuantity, accent),
          1.5.height,
          _splitRow(
            "External",
            d.externalAmount,
            d.externalQuantity,
            accent.withValues(alpha: 0.5),
          ),
          2.height,
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: share,
              minHeight: 0.8.h,
              color: accent,
              backgroundColor: accent.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _splitRow(String label, double amount, double qty, Color color) {
    return Row(
      children: [
        Container(
          width: 2.5.w,
          height: 2.5.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        2.width,
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 3.3.sp,
              fontWeight: FontWeight.w600,
              color: AppColor.appDarkColor,
            ),
          ),
        ),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              "${salesMoney(amount)} · ${salesQty(qty)} qty",
              maxLines: 1,
              style: TextStyle(
                fontSize: 3.1.sp,
                fontWeight: FontWeight.bold,
                color: AppColor.appDarkColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _activityCard(SalesDashboard d, Color accent) {
    return SalesCard(
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _countColumn(
                "Internal",
                d.activeInternal,
                d.noSalesInternal,
                accent,
              ),
            ),
            VerticalDivider(
              width: 4.w,
              thickness: 1,
              color: AppColor.appLightColor,
            ),
            Expanded(
              child: _countColumn(
                "External",
                d.activeExternal,
                d.noSalesExternal,
                accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _countColumn(String label, int active, int idle, Color accent) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 3.1.sp,
            fontWeight: FontWeight.w600,
            color: AppColor.grey,
          ),
        ),
        0.6.height,
        Text(
          "$active",
          style: TextStyle(
            fontSize: 5.4.sp,
            fontWeight: FontWeight.bold,
            color: accent,
          ),
        ),
        0.4.height,
        Text(
          "active · $idle with no sales",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 2.5.sp, color: AppColor.grey),
        ),
      ],
    );
  }

  Widget _ranking(List<RankedSalesRow> rows, Color accent) {
    if (rows.isEmpty) {
      return SalesCard(
        child: Text(
          "No data for this period.",
          style: TextStyle(fontSize: 3.1.sp, color: AppColor.grey),
        ),
      );
    }
    final top = rows.take(10).toList();
    final maxValue = top
        .map((r) => r.salesAmount)
        .fold<double>(0, (m, v) => v > m ? v : m);

    return SalesCard(
      child: Column(
        children: [
          for (var i = 0; i < top.length; i++) ...[
            if (i > 0) 1.6.height,
            SalesRankRow(
              rank: i + 1,
              name: top[i].name,
              amount: top[i].salesAmount,
              ratio: maxValue <= 0 ? 0.0 : top[i].salesAmount / maxValue,
              accent: accent,
            ),
          ],
        ],
      ),
    );
  }
}
