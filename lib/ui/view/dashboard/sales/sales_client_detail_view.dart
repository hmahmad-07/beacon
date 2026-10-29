import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/controllers/sales_controller.dart';
import '../../../../core/controllers/sales_period_controller.dart';
import '../../../../core/extensions/sizer.dart';
import '../../../../core/models/Sales/sales_common.dart';
import '../../../../core/models/Sales/sales_ledger_directory.dart';
import '../../../../core/models/Sales/sales_models.dart';
import '../../../../core/resources/app_colors.dart';
import '../../../components/custom_appbar.dart';
import 'sales_ui.dart';
import 'sales_widgets.dart';

/// One client: the period totals, its monthly and daily sales, its monthly
/// ledger (Paani), and the products it bought.
class SalesClientDetailScreen extends StatelessWidget {
  const SalesClientDetailScreen({
    super.key,
    required this.business,
    required this.filters,
    required this.clientId,
    required this.clientName,
    required this.subtitle,
  });

  final SalesBusiness business;
  final SalesFilters filters;
  final String clientId;
  final String clientName;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final period = context.read<SalesPeriodController>();
    return ChangeNotifierProvider(
      create: (_) =>
          SalesController(business: business, initialFilters: filters)
            ..bindPeriod(period, (c) => c.loadClientDetail(clientId: clientId))
            ..loadClientDetail(clientId: clientId),
      child: _ClientDetailBody(
        clientId: clientId,
        clientName: clientName,
        subtitle: subtitle,
      ),
    );
  }
}

class _ClientDetailBody extends StatelessWidget {
  const _ClientDetailBody({
    required this.clientId,
    required this.clientName,
    required this.subtitle,
  });

  final String clientId;
  final String clientName;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Consumer<SalesController>(
      builder: (context, controller, _) {
        final accent = salesAccentFor(controller.business);
        return Scaffold(
          backgroundColor: AppColor.scaffold,
          appBar: CustomAppBar(title: clientName),
          body: RefreshIndicator(
            onRefresh: () => controller.loadClientDetail(clientId: clientId),
            child: ListView(
              padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 4.h),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 3.1.sp,
                          color: AppColor.grey,
                        ),
                      ),
                    ),
                    2.width,
                    SalesPillButton(
                      icon: Icons.calendar_month_rounded,
                      label: salesPeriodLabel(controller.filters),
                      accent: accent,
                      onTap: () => _changePeriod(context, controller),
                    ),
                  ],
                ),
                2.height,
                _content(controller, accent),
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

  Widget _content(SalesController controller, Color accent) {
    final d = controller.clientDashboard;

    if (controller.clientLoading && d == null) {
      return SizedBox(height: 40.h, child: const SalesLoadingState());
    }
    if (controller.clientError != null && d == null) {
      return SalesErrorState(
        message: controller.clientError!,
        onRetry: () => controller.loadClientDetail(clientId: clientId),
      );
    }
    if (d == null) {
      return const SalesEmptyState(
        message: "No sales for this client in this period.",
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SalesHero(
          accent: accent,
          title: "Net sales",
          value: salesMoney(d.kpis.salesAmount),
          subtitle: "${d.kpis.orderCount} orders",
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
                  label: "Quantity sold",
                  value: salesQty(d.kpis.salesQuantity),
                  accent: accent,
                  icon: Icons.inventory_2_rounded,
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
        2.5.height,
        const SalesSectionTitle("Monthly sales · 12 months"),
        SalesCard(
          child: SalesBarChart(
            accent: accent,
            bars: salesBarsFrom(d.monthlyTrend, salesMonthKeyLabel),
          ),
        ),
        ...[
          2.5.height,
          const SalesSectionTitle("Monthly ledger"),
          _ledgerCard(controller, accent),
        ],
        2.5.height,
        const SalesSectionTitle("Daily sales · selected period"),
        _dailyCard(d.dailyTrend, accent),
        2.5.height,
        const SalesSectionTitle("Products"),
        _productsCard(controller, accent),
      ],
    );
  }

  /// Paani ledger from the client ledger endpoint: one row per month with
  /// orders, quantity, returns and net sales. Latest month first.
  Widget _ledgerCard(SalesController controller, Color accent) {
    final error = controller.clientLedgerError;
    if (error != null) {
      return SalesCard(
        child: Text(
          error,
          style: TextStyle(fontSize: 3.1.sp, color: AppColor.grey),
        ),
      );
    }

    final rows = (controller.clientLedger?.rows ?? const <LedgerRow>[])
        .reversed
        .toList();
    if (rows.isEmpty) {
      return const SalesEmptyState(
        message: "No ledger entries for this client in the last 12 months.",
      );
    }

    return SalesCard(
      child: Column(
        children: [
          Row(
            children: [
              _cell("Month", flex: 4, align: TextAlign.left, header: true),
              _cell("Orders", flex: 2, header: true),
              _cell("Qty", flex: 2, header: true),
              _cell("Returns", flex: 3, header: true),
              _cell("Net sales", flex: 4, header: true),
            ],
          ),
          Divider(height: 2.h, thickness: 1, color: AppColor.appLightColor),
          for (final row in rows) ...[
            Padding(
              padding: EdgeInsets.symmetric(vertical: 0.6.h),
              child: Row(
                children: [
                  _cell(salesMonthKeyLabel(row.period), flex: 4, align: TextAlign.left),
                  _cell("${row.orderCount}", flex: 2),
                  _cell(salesQty(row.salesQuantity), flex: 2),
                  _cell(
                    salesMoney(row.returnAmount),
                    flex: 3,
                    color: row.returnAmount < 0 ? AppColor.red : AppColor.grey,
                  ),
                  _cell(
                    salesMoney(row.salesAmount),
                    flex: 4,
                    color: accent,
                    bold: true,
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: AppColor.appLightColor),
          ],
        ],
      ),
    );
  }

  /// One ledger cell. Text scales down rather than overflowing the column.
  Widget _cell(
    String text, {
    required int flex,
    TextAlign align = TextAlign.right,
    bool header = false,
    bool bold = false,
    Color? color,
  }) {
    final style = TextStyle(
      fontSize: header ? 2.6.sp : 3.1.sp,
      fontWeight: header || bold ? FontWeight.bold : FontWeight.w500,
      color: color ?? (header ? AppColor.grey : AppColor.appDarkColor),
    );
    return Expanded(
      flex: flex,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: align == TextAlign.left
            ? Alignment.centerLeft
            : Alignment.centerRight,
        child: Text(text, maxLines: 1, style: style),
      ),
    );
  }

  Widget _dailyCard(List<SalesDayPoint> points, Color accent) {
    if (points.isEmpty) {
      return const SalesEmptyState(message: "No sales in this period.");
    }
    return SalesCard(
      child: Column(
        children: [
          SalesBarChart(
            accent: accent,
            bars: salesBarsFrom(points, salesDayKeyLabel),
          ),
          2.height,
          for (final point in points) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    salesDayKeyFull(point.label),
                    style: TextStyle(
                      fontSize: 3.2.sp,
                      color: AppColor.appDarkColor,
                    ),
                  ),
                ),
                Text(
                  "${salesQty(point.salesQuantity)} qty",
                  style: TextStyle(fontSize: 2.9.sp, color: AppColor.grey),
                ),
                2.width,
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      salesMoney(point.salesAmount),
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 3.2.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColor.appDarkColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Divider(height: 1.6.h, thickness: 1, color: AppColor.appLightColor),
          ],
        ],
      ),
    );
  }

  Widget _productsCard(SalesController controller, Color accent) {
    final products = controller.clientProducts;
    if (products.isEmpty) {
      return const SalesEmptyState(
        message: "No products sold to this client in this period.",
      );
    }
    return Column(
      children: [
        for (final product in products)
          Padding(
            padding: EdgeInsets.only(bottom: 1.2.h),
            child: SalesRowCard(
              title: product.productName,
              subtitle: product.itemType == null
                  ? product.sku
                  : "${product.sku} · ${product.itemType}",
              trailingValue: salesMoney(product.totals.salesAmount),
              trailingCaption: "${salesQty(product.totals.salesQuantity)} qty",
              accent: accent,
              comparison: product.comparison,
            ),
          ),
      ],
    );
  }
}
